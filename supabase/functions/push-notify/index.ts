import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders, corsPreflightResponse, jsonResponse } from "../_shared/cors.ts";

type EventBody =
  | { event: "announcement_created"; announcementId: string }
  | { event: "feedback_form_created"; formId: string }
  | { event: "question_answered"; questionId: string }
  | { event: "complaint_responded"; complaintId: string }
  ;

type UserRole = "admin" | "servant";

function truncateText(input: string, max: number): string {
  const text = (input ?? "").toString().trim();
  if (text.length <= max) return text;
  return text.slice(0, Math.max(0, max - 3)).trimEnd() + "...";
}

function formatLabel(input: string | null | undefined): string {
  const raw = (input ?? "").toString().trim();
  if (!raw) return "";
  return raw
    .replace(/[_-]+/g, " ")
    .split(/\s+/g)
    .filter(Boolean)
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(" ");
}

type FcmServiceAccount = {
  project_id: string;
  private_key: string;
  client_email: string;
};

function chunk<T>(arr: T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
  return out;
}

function base64UrlEncode(input: Uint8Array): string {
  let str = "";
  for (const b of input) str += String.fromCharCode(b);
  // deno-lint-ignore no-deprecated-deno-api
  return btoa(str).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

function utf8(input: string): Uint8Array {
  return new TextEncoder().encode(input);
}

function pemToDer(pem: string): ArrayBuffer {
  const clean = pem
    .replace(/-----BEGIN [^-]+-----/g, "")
    .replace(/-----END [^-]+-----/g, "")
    .replace(/\s+/g, "");
  // deno-lint-ignore no-deprecated-deno-api
  const raw = atob(clean);
  const out = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i++) out[i] = raw.charCodeAt(i);
  return out.buffer;
}

let cachedAccessToken: string | null = null;
let cachedAccessTokenExpMs = 0;

async function getFcmAccessToken(sa: FcmServiceAccount): Promise<string> {
  const now = Date.now();
  if (cachedAccessToken && now < cachedAccessTokenExpMs - 60_000) {
    return cachedAccessToken;
  }

  const iat = Math.floor(now / 1000);
  const exp = iat + 3600;

  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat,
    exp,
  };

  const encHeader = base64UrlEncode(utf8(JSON.stringify(header)));
  const encPayload = base64UrlEncode(utf8(JSON.stringify(payload)));
  const signingInput = `${encHeader}.${encPayload}`;

  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const sigBuf = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    utf8(signingInput) as unknown as BufferSource,
  );
  const signature = base64UrlEncode(new Uint8Array(sigBuf));
  const jwt = `${signingInput}.${signature}`;

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const tokenJson = await tokenRes.json().catch(() => null);
  if (!tokenRes.ok || !tokenJson?.access_token) {
    throw new Error(
      `Failed to fetch FCM access token: ${tokenRes.status} ${JSON.stringify(tokenJson)}`,
    );
  }

  cachedAccessToken = tokenJson.access_token as string;
  cachedAccessTokenExpMs = now + ((tokenJson.expires_in as number | undefined) ?? 3600) * 1000;
  return cachedAccessToken;
}

function getServiceAccountFromEnv(): FcmServiceAccount | null {
  const raw = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw) as Partial<FcmServiceAccount>;
    if (!parsed.project_id || !parsed.private_key || !parsed.client_email) return null;
    return {
      project_id: parsed.project_id,
      private_key: parsed.private_key,
      client_email: parsed.client_email,
    };
  } catch {
    return null;
  }
}

async function sendFcmLegacy(tokens: string[], title: string, body: string, data: Record<string, string>) {
  const serverKey = Deno.env.get("FCM_SERVER_KEY");
  if (!serverKey) {
    return { ok: false, error: "Missing FCM_SERVER_KEY secret" } as const;
  }

  // Legacy FCM multicast: max 1000 tokens.
  const batches = chunk(tokens, 900);
  let success = 0;
  let failure = 0;
  const errors: unknown[] = [];

  for (const batch of batches) {
    const res = await fetch("https://fcm.googleapis.com/fcm/send", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `key=${serverKey}`,
      },
      body: JSON.stringify({
        registration_ids: batch,
        notification: { title, body },
        data,
        priority: "high",
      }),
    });

    const json = await res.json().catch(() => null);
    if (!res.ok) {
      errors.push({ status: res.status, body: json });
      failure += batch.length;
      continue;
    }

    const batchSuccess = (json?.success ?? 0) as number;
    const batchFailure = (json?.failure ?? 0) as number;
    success += batchSuccess;
    failure += batchFailure;
  }

  return { ok: true, success, failure, errors } as const;
}

async function sendFcmV1(tokens: string[], title: string, body: string, data: Record<string, string>) {
  const sa = getServiceAccountFromEnv();
  if (!sa) {
    return { ok: false, error: "Missing/invalid FCM_SERVICE_ACCOUNT_JSON secret" } as const;
  }

  const accessToken = await getFcmAccessToken(sa);
  const url = `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;

  const batches = chunk(tokens, 200);
  let success = 0;
  let failure = 0;
  const errors: unknown[] = [];

  for (const batch of batches) {
    const results = await Promise.all(
      batch.map(async (token) => {
        const res = await fetch(url, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${accessToken}`,
          },
          body: JSON.stringify({
            message: {
              token,
              notification: { title, body },
              data,
              android: {
                priority: "HIGH",
                notification: { channel_id: "communications" },
              },
            },
          }),
        });
        const json = await res.json().catch(() => null);
        return { ok: res.ok, status: res.status, json };
      }),
    );

    for (const r of results) {
      if (r.ok) success += 1;
      else {
        failure += 1;
        if (errors.length < 20) errors.push({ status: r.status, body: r.json });
      }
    }
  }

  return { ok: true, success, failure, errors } as const;
}

async function sendFcm(tokens: string[], title: string, body: string, data: Record<string, string>) {
  // Prefer v1 if configured (works for newer Firebase projects).
  if (Deno.env.get("FCM_SERVICE_ACCOUNT_JSON")) {
    try {
      return await sendFcmV1(tokens, title, body, data);
    } catch (e) {
      return { ok: false, error: (e as Error).message } as const;
    }
  }
  return await sendFcmLegacy(tokens, title, body, data);
}

async function requireCaller(req: Request) {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return {
      ok: false,
      status: 500,
      body: {
        error: "Missing SUPABASE_URL, SUPABASE_ANON_KEY, or SUPABASE_SERVICE_ROLE_KEY.",
      },
    } as const;
  }

  const authHeader = req.headers.get("Authorization") ?? "";

  const callerClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: userData, error: userError } = await callerClient.auth.getUser();
  if (userError || !userData.user) {
    return { ok: false, status: 401, body: { error: "Unauthorized" } } as const;
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey);
  const { data: profile, error: profileError } = await adminClient
    .from("profiles")
    .select("role")
    .eq("id", userData.user.id)
    .maybeSingle();

  if (profileError) {
    return { ok: false, status: 500, body: { error: profileError.message } } as const;
  }

  const role = (profile?.role ?? null) as UserRole | null;
  if (role !== "admin" && role !== "servant") {
    return { ok: false, status: 403, body: { error: "Forbidden" } } as const;
  }

  return { ok: true, adminClient, callerId: userData.user.id, callerRole: role } as const;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") return corsPreflightResponse();
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, { status: 405, headers: corsHeaders });
  }

  const guard = await requireCaller(req);
  if (!guard.ok) {
    return jsonResponse(guard.body, { status: guard.status, headers: corsHeaders });
  }

  let payload: EventBody;
  try {
    payload = (await req.json()) as EventBody;
  } catch {
    return jsonResponse({ error: "Invalid JSON" }, { status: 400, headers: corsHeaders });
  }

  const db = guard.adminClient;

  if (payload.event === "announcement_created") {
    const { data: ann, error: annError } = await db
      .from("announcements")
      .select("id, title, message, category, grade_id, created_by")
      .eq("id", payload.announcementId)
      .maybeSingle();

    if (annError) return jsonResponse({ error: annError.message }, { status: 500, headers: corsHeaders });
    if (!ann) return jsonResponse({ error: "Announcement not found" }, { status: 404, headers: corsHeaders });

    if (guard.callerRole !== "admin" && ann.created_by !== guard.callerId) {
      return jsonResponse({ error: "Forbidden" }, { status: 403, headers: corsHeaders });
    }

    let profilesQuery = db
      .from("profiles")
      .select("id")
      .in("role", ["student", "servant"])
      .eq("account_status", "active");

    if (ann.grade_id) {
      profilesQuery = profilesQuery.eq("grade_id", ann.grade_id);
    }

    const { data: profiles, error: profilesError } = await profilesQuery;
    if (profilesError) return jsonResponse({ error: profilesError.message }, { status: 500, headers: corsHeaders });

    const recipientUserIds = (profiles ?? []).map((p: any) => p.id as string);
    if (recipientUserIds.length === 0) {
      return jsonResponse(
        { ok: true, sent: 0, reason: "no_recipients", recipients: 0, tokens: 0 },
        { status: 200, headers: corsHeaders },
      );
    }

    const { data: tokensRows, error: tokensError } = await db
      .from("device_push_tokens")
      .select("fcm_token")
      .in("user_id", recipientUserIds)
      .eq("enabled", true);

    if (tokensError) return jsonResponse({ error: tokensError.message }, { status: 500, headers: corsHeaders });

    const tokens = (tokensRows ?? []).map((r: any) => r.fcm_token as string).filter(Boolean);
    if (tokens.length === 0) {
      return jsonResponse(
        { ok: true, sent: 0, reason: "no_tokens", recipients: recipientUserIds.length, tokens: 0 },
        { status: 200, headers: corsHeaders },
      );
    }

    const categoryLabel = formatLabel(ann.category ?? "general") || "General";
    const title = `Announcement \u2022 ${categoryLabel}`;
    const body = `${truncateText(ann.title ?? "", 80)}${ann.message ? ` \u2014 ${truncateText(ann.message, 120)}` : ""}`;

    const res = await sendFcm(tokens, title, body, {
      type: "announcement",
      id: ann.id,
      event: payload.event,
      category: (ann.category ?? "general").toString(),
    });

    const fcmRejectedAll = "success" in res && res.success === 0 && res.failure > 0;
    const reason = fcmRejectedAll ? "fcm_rejected" : undefined;

    return jsonResponse(
      { ...res, reason, recipients: recipientUserIds.length, tokens: tokens.length },
      { status: 200, headers: corsHeaders },
    );
  }

  if (payload.event === "feedback_form_created") {
    const { data: form, error: formError } = await db
      .from("feedback_forms")
      .select("id, title, description, type_label, grade_id, created_by")
      .eq("id", payload.formId)
      .maybeSingle();

    if (formError) return jsonResponse({ error: formError.message }, { status: 500, headers: corsHeaders });
    if (!form) return jsonResponse({ error: "Feedback form not found" }, { status: 404, headers: corsHeaders });

    if (guard.callerRole !== "admin" && guard.callerRole !== "servant") {
      return jsonResponse({ error: "Forbidden" }, { status: 403, headers: corsHeaders });
    }
    if (guard.callerRole === "servant" && form.created_by !== guard.callerId) {
      return jsonResponse({ error: "Forbidden" }, { status: 403, headers: corsHeaders });
    }

    const { data: profiles, error: profilesError } = await db
      .from("profiles")
      .select("id")
      .eq("role", "student")
      .eq("account_status", "active")
      .eq("grade_id", form.grade_id);

    if (profilesError) return jsonResponse({ error: profilesError.message }, { status: 500, headers: corsHeaders });

    const recipientUserIds = (profiles ?? []).map((p: any) => p.id as string);
    if (recipientUserIds.length === 0) {
      return jsonResponse(
        { ok: true, sent: 0, reason: "no_recipients", recipients: 0, tokens: 0 },
        { status: 200, headers: corsHeaders },
      );
    }

    const { data: tokensRows, error: tokensError } = await db
      .from("device_push_tokens")
      .select("fcm_token")
      .in("user_id", recipientUserIds)
      .eq("enabled", true);

    if (tokensError) return jsonResponse({ error: tokensError.message }, { status: 500, headers: corsHeaders });

    const tokens = (tokensRows ?? []).map((r: any) => r.fcm_token as string).filter(Boolean);
    if (tokens.length === 0) {
      return jsonResponse(
        { ok: true, sent: 0, reason: "no_tokens", recipients: recipientUserIds.length, tokens: 0 },
        { status: 200, headers: corsHeaders },
      );
    }

    const typeLabel = formatLabel(form.type_label) || "Feedback";
    const title = `Feedback \u2022 ${typeLabel}`;
    const body = `${truncateText(form.title ?? "", 90)}${form.description ? ` \u2014 ${truncateText(form.description, 120)}` : ""}`;

    const res = await sendFcm(tokens, title, body, {
      type: "feedback_form_created",
      id: form.id,
      event: payload.event,
      category: (form.type_label ?? "").toString(),
    });

    const fcmRejectedAll = "success" in res && res.success === 0 && res.failure > 0;
    const reason = fcmRejectedAll ? "fcm_rejected" : undefined;

    return jsonResponse(
      { ...res, reason, recipients: recipientUserIds.length, tokens: tokens.length },
      { status: 200, headers: corsHeaders },
    );
  }

  if (payload.event === "question_answered") {
    const { data: q, error } = await db
      .from("questions")
      .select("id, student_id, answer, answered_by")
      .eq("id", payload.questionId)
      .maybeSingle();

    if (error) return jsonResponse({ error: error.message }, { status: 500, headers: corsHeaders });
    if (!q) return jsonResponse({ error: "Question not found" }, { status: 404, headers: corsHeaders });

    if (guard.callerRole !== "admin" && q.answered_by !== guard.callerId) {
      return jsonResponse({ error: "Forbidden" }, { status: 403, headers: corsHeaders });
    }

    const { data: tokensRows, error: tokensError } = await db
      .from("device_push_tokens")
      .select("fcm_token")
      .eq("user_id", q.student_id)
      .eq("enabled", true);

    if (tokensError) return jsonResponse({ error: tokensError.message }, { status: 500, headers: corsHeaders });

    const tokens = (tokensRows ?? []).map((r: any) => r.fcm_token as string).filter(Boolean);
    if (tokens.length === 0) {
      return jsonResponse(
        { ok: true, sent: 0, reason: "no_tokens", recipients: 1, tokens: 0 },
        { status: 200, headers: corsHeaders },
      );
    }

    const title = "Answer to your question";
    const body = truncateText((q.answer ?? "").toString(), 120);

    const res = await sendFcm(tokens, title, body.length > 120 ? body.slice(0, 117) + "..." : body, {
      type: "question_answered",
      id: q.id,
      event: payload.event,
    });

    const fcmRejectedAll = "success" in res && res.success === 0 && res.failure > 0;
    const reason = fcmRejectedAll ? "fcm_rejected" : undefined;

    if (!res.ok) {
      return jsonResponse(
        { ...res, reason, recipients: 1, tokens: tokens.length },
        { status: 200, headers: corsHeaders },
      );
    }

    return jsonResponse(
      { ...res, reason, recipients: 1, tokens: tokens.length },
      { status: 200, headers: corsHeaders },
    );
  }

  if (payload.event === "complaint_responded") {
    const { data: c, error } = await db
      .from("complaints")
      .select("id, student_id, response, responded_by")
      .eq("id", payload.complaintId)
      .maybeSingle();

    if (error) return jsonResponse({ error: error.message }, { status: 500, headers: corsHeaders });
    if (!c) return jsonResponse({ error: "Complaint not found" }, { status: 404, headers: corsHeaders });

    if (guard.callerRole !== "admin" && c.responded_by !== guard.callerId) {
      return jsonResponse({ error: "Forbidden" }, { status: 403, headers: corsHeaders });
    }

    const { data: tokensRows, error: tokensError } = await db
      .from("device_push_tokens")
      .select("fcm_token")
      .eq("user_id", c.student_id)
      .eq("enabled", true);

    if (tokensError) return jsonResponse({ error: tokensError.message }, { status: 500, headers: corsHeaders });

    const tokens = (tokensRows ?? []).map((r: any) => r.fcm_token as string).filter(Boolean);
    if (tokens.length === 0) {
      return jsonResponse(
        { ok: true, sent: 0, reason: "no_tokens", recipients: 1, tokens: 0 },
        { status: 200, headers: corsHeaders },
      );
    }

    const title = "Response to your complaint";
    const body = truncateText((c.response ?? "").toString(), 120);

    const res = await sendFcm(tokens, title, body.length > 120 ? body.slice(0, 117) + "..." : body, {
      type: "complaint_responded",
      id: c.id,
      event: payload.event,
    });

    const fcmRejectedAll = "success" in res && res.success === 0 && res.failure > 0;
    const reason = fcmRejectedAll ? "fcm_rejected" : undefined;

    if (!res.ok) {
      return jsonResponse(
        { ...res, reason, recipients: 1, tokens: tokens.length },
        { status: 200, headers: corsHeaders },
      );
    }

    return jsonResponse(
      { ...res, reason, recipients: 1, tokens: tokens.length },
      { status: 200, headers: corsHeaders },
    );
  }

  return jsonResponse({ error: "Unsupported event" }, { status: 400, headers: corsHeaders });
});
