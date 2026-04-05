import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

import { corsHeaders, corsPreflightResponse, jsonResponse } from "../_shared/cors.ts";
import { requireAdmin } from "../_shared/admin_guard.ts";

type DeleteUserBody = {
  user_id: string;
};

serve(async (req) => {
  if (req.method === "OPTIONS") return corsPreflightResponse();

  const guard = await requireAdmin(req);
  if (!guard.ok) {
    return jsonResponse(guard.body, { status: guard.status, headers: corsHeaders });
  }

  try {
    const body = (await req.json()) as Partial<DeleteUserBody>;
    const userId = (body.user_id ?? "").trim();

    if (!userId) {
      return jsonResponse(
        { error: "Missing required field: user_id." },
        { status: 400 },
      );
    }

    const { data: profile, error: profileError } = await guard.adminClient
      .from("profiles")
      .select("id, role")
      .eq("id", userId)
      .maybeSingle();

    if (profileError) {
      return jsonResponse({ error: profileError.message }, { status: 400 });
    }

    if (!profile?.id) {
      return jsonResponse({ error: "Profile not found." }, { status: 404 });
    }

    if (profile.role !== "servant") {
      return jsonResponse(
        { error: "Only servant accounts can be deleted." },
        { status: 400 },
      );
    }

    // The schema uses RESTRICT for some foreign keys, so we must reassign those
    // rows before deleting the profile (which cascades from auth.users).
    const reassignTo = guard.callerId;

    const updates: Array<Promise<{ error: { message: string } | null }>> = [
      guard.adminClient.from("assessments").update({ created_by: reassignTo }).eq("created_by", userId),
      guard.adminClient.from("attendance_sessions").update({ created_by: reassignTo }).eq("created_by", userId),
      guard.adminClient.from("attendance_records").update({ updated_by: reassignTo }).eq("updated_by", userId),
      guard.adminClient.from("announcements").update({ created_by: reassignTo }).eq("created_by", userId),
      guard.adminClient.from("complaints").update({ responded_by: reassignTo }).eq("responded_by", userId),
      guard.adminClient.from("feedback_forms").update({ created_by: reassignTo }).eq("created_by", userId),
      guard.adminClient.from("promotion_runs").update({ run_by: reassignTo }).eq("run_by", userId),
      guard.adminClient.from("questions").update({ answered_by: reassignTo }).eq("answered_by", userId),
    ];

    for (const p of updates) {
      const { error } = await p;
      if (error) {
        return jsonResponse({ error: error.message }, { status: 400 });
      }
    }

    const { error: deleteError } = await guard.adminClient.auth.admin.deleteUser(userId);

    if (deleteError) {
      return jsonResponse({ error: deleteError.message }, { status: 400 });
    }

    return jsonResponse({ ok: true, user_id: userId });
  } catch (e) {
    return jsonResponse(
      { error: e instanceof Error ? e.message : "Unknown error" },
      { status: 500 },
    );
  }
});
