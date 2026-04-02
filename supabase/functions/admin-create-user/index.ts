import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

import { corsHeaders, corsPreflightResponse, jsonResponse } from "../_shared/cors.ts";
import { requireServantOrAdmin } from "../_shared/servant_guard.ts";

type CreateUserBody = {
  email?: string;
  password: string;
  role: string;
  academic_id: string;
  name: string;
  grade_id?: string | null;
};

serve(async (req) => {
  if (req.method === "OPTIONS") return corsPreflightResponse();

  const guard = await requireServantOrAdmin(req);
  if (!guard.ok) {
    return jsonResponse(guard.body, { status: guard.status, headers: corsHeaders });
  }

  function academicIdToEmail(academicId: string) {
    // Academic IDs can contain '/', which may not pass email validation.
    // Map it to a deterministic local address.
    const local = academicId
      .trim()
      .toLowerCase()
      .replace(/[^a-z0-9]/g, "-")
      .replace(/-+/g, "-")
      .replace(/^-+|-+$/g, "");
    return `${local || "student"}@school.local`;
  }

  try {
    const body = (await req.json()) as Partial<CreateUserBody>;

    const password = (body.password ?? "").trim();
    const requestedRole = (body.role ?? "").trim().toLowerCase();
    const academicId = (body.academic_id ?? "").trim();
    const name = (body.name ?? "").trim();
    const allowedRoles = new Set(["student", "servant"]);

    if (!password || !academicId || !name) {
      return jsonResponse(
        {
          error: "Missing required fields: password, academic_id, name.",
        },
        { status: 400 },
      );
    }

    const callerRole = guard.callerRole;

    let role: string;
    if (callerRole === "admin") {
      if (!requestedRole) {
        return jsonResponse(
          { error: "Missing required field: role." },
          { status: 400 },
        );
      }
      role = requestedRole;
    } else {
      // Servants may only create student accounts.
      if (requestedRole && requestedRole !== "student") {
        return jsonResponse(
          { error: "Forbidden: servants can only create students." },
          { status: 403 },
        );
      }
      role = "student";
    }

    if (!allowedRoles.has(role)) {
      return jsonResponse(
        {
          error: "Invalid role. Allowed roles: student, servant.",
        },
        { status: 400 },
      );
    }

    // Student registrations must include a grade.
    if (role === "student") {
      const gradeId = (body.grade_id ?? "").toString().trim();
      if (!gradeId) {
        return jsonResponse(
          { error: "Missing required field: grade_id." },
          { status: 400 },
        );
      }
    }

    const email = (body.email ?? "").trim() || academicIdToEmail(academicId);

    const { data: created, error: createError } =
      await guard.adminClient.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
      });

    if (createError || !created.user) {
      const msg = createError?.message ?? "Failed to create user";
      if (msg.toLowerCase().includes("already registered")) {
        return jsonResponse({ error: msg }, { status: 409 });
      }
      return jsonResponse(
        { error: msg },
        { status: 400 },
      );
    }

    const userId = created.user.id;

    const { error: profileError } = await guard.adminClient
      .from("profiles")
      .upsert({
        id: userId,
        name,
        role,
        academic_id: academicId,
        grade_id: body.grade_id ?? null,
        account_status: "active",
      });

    if (profileError) {
      // Likely academic_id uniqueness.
      // Postgres unique violation code is 23505.
      // @ts-ignore - Postgrest error has code at runtime.
      if ((profileError as any)?.code === "23505") {
        return jsonResponse({ error: profileError.message }, { status: 409 });
      }
      return jsonResponse({ error: profileError.message }, { status: 400 });
    }

    return jsonResponse({ user_id: userId, email, academic_id: academicId });
  } catch (e) {
    return jsonResponse(
      { error: e instanceof Error ? e.message : "Unknown error" },
      { status: 500 },
    );
  }
});
