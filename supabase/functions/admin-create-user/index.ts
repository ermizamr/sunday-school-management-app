import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

import { corsHeaders, corsPreflightResponse, jsonResponse } from "../_shared/cors.ts";
import { requireServantOrAdmin } from "../_shared/servant_guard.ts";

type CreateUserBody = {
  email?: string;
  password?: string;
  role: string;
  academic_id?: string;
  name: string;
  grade_id?: string | null;
};

function pad2(n: number) {
  return n.toString().padStart(2, "0");
}

function isGregorianLeapYear(year: number) {
  return year % 4 === 0 && (year % 100 !== 0 || year % 400 === 0);
}

function addisAbabaGregorianYmd(date: Date) {
  try {
    const parts = new Intl.DateTimeFormat("en-US", {
      timeZone: "Africa/Addis_Ababa",
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
    }).formatToParts(date);

    const get = (type: string) => parts.find((p) => p.type === type)?.value;
    const year = Number(get("year"));
    const month = Number(get("month"));
    const day = Number(get("day"));

    if (Number.isFinite(year) && Number.isFinite(month) && Number.isFinite(day)) {
      return { year, month, day };
    }
  } catch (_) {
    // Fall back below.
  }

  // Fallback: approximate Addis Ababa time as UTC+3.
  const shifted = new Date(date.getTime() + 3 * 60 * 60 * 1000);
  return {
    year: shifted.getUTCFullYear(),
    month: shifted.getUTCMonth() + 1,
    day: shifted.getUTCDate(),
  };
}

function ethiopianYearFromGregorianDate(date: Date): number {
  const { year, month, day } = addisAbabaGregorianYmd(date);
  // Ethiopian new year is Sep 11 (or Sep 12 in the year before a Gregorian leap year).
  const newYearDay = isGregorianLeapYear(year + 1) ? 12 : 11;
  const isOnOrAfterNewYear = month > 9 || (month === 9 && day >= newYearDay);
  return isOnOrAfterNewYear ? year - 7 : year - 8;
}

function parseAcademicIdPrefix(academicId: string) {
  const m = academicId.match(/^(\d{4})\/(\d{2})$/);
  if (!m) return null;
  const prefix = Number(m[1]);
  const yy = m[2];
  if (!Number.isFinite(prefix) || prefix < 1 || prefix > 9999) return null;
  return { prefix, yy };
}

serve(async (req: Request) => {
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

    const requestedPassword = (body.password ?? "").trim();
    const requestedRole = (body.role ?? "").trim().toLowerCase();
    const requestedAcademicId = (body.academic_id ?? "").trim();
    const name = (body.name ?? "").trim();
    const allowedRoles = new Set(["student", "servant"]);

    if (!name) {
      return jsonResponse(
        {
          error: "Missing required field: name.",
        },
        { status: 400 },
      );
    }

    const callerRole = guard.callerRole;
    const callerGradeId = guard.callerGradeId;

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

    // Registrations must include a valid grade.
    const gradeId = (body.grade_id ?? "").toString().trim();
    if (!gradeId) {
      return jsonResponse(
        { error: "Missing required field: grade_id." },
        { status: 400 },
      );
    }

    // Servants may only create students in their own grade.
    if (callerRole === "servant" && gradeId !== callerGradeId) {
      return jsonResponse(
        { error: "Forbidden: you can only create students in your grade." },
        { status: 403 },
      );
    }

    // Validate grade exists (avoid creating orphan auth users).
    const { data: gradeRow, error: gradeError } = await guard.adminClient
      .from("grades")
      .select("id")
      .eq("id", gradeId)
      .maybeSingle();

    if (gradeError) {
      return jsonResponse({ error: gradeError.message }, { status: 400 });
    }

    if (!gradeRow) {
      return jsonResponse({ error: "Unknown grade_id." }, { status: 400 });
    }

    // If academic_id is omitted for student creation, auto-allocate the next
    // available number for the current Ethiopian year: 0001/yy, 0002/yy, ...
    const ethYear = ethiopianYearFromGregorianDate(new Date());
    const yy = pad2(ethYear % 100);

    const parseRequested = requestedAcademicId ? parseAcademicIdPrefix(requestedAcademicId) : null;
    if (requestedAcademicId && !parseRequested) {
      return jsonResponse(
        { error: "Invalid academic_id format. Expected xxxx/xx." },
        { status: 400 },
      );
    }

    if (!requestedAcademicId && role !== "student") {
      return jsonResponse(
        { error: "Missing required field: academic_id." },
        { status: 400 },
      );
    }

    // If caller provides a password, use it. Otherwise default to academic_id.
    // For student auto-allocation, password becomes the assigned academic_id.
    const isAutoAcademicId = !requestedAcademicId && role === "student";

    const usedPrefixes = new Set<number>();
    let nextPrefix = 1;

    if (isAutoAcademicId) {
      const { data: existingRows, error: existingRowsError } = await guard.adminClient
        .from("profiles")
        .select("academic_id")
        // Match only the expected format: dddd/yy
        .like("academic_id", `____/${yy}`)
        .range(0, 9998);

      if (existingRowsError) {
        return jsonResponse({ error: existingRowsError.message }, { status: 400 });
      }

      for (const row of (existingRows ?? []) as Array<{ academic_id: string | null }>) {
        const aid = (row.academic_id ?? "").toString().trim();
        const parsed = parseAcademicIdPrefix(aid);
        if (parsed && parsed.yy === yy) {
          usedPrefixes.add(parsed.prefix);
        }
      }

      while (usedPrefixes.has(nextPrefix) && nextPrefix <= 9999) nextPrefix++;
    }

    const makeAcademicId = (prefix: number) => `${prefix.toString().padStart(4, "0")}/${yy}`;

    let lastErrorMsg: string | null = null;
    for (let attempt = 0; attempt < 25; attempt++) {
      const academicId = isAutoAcademicId ? makeAcademicId(nextPrefix) : requestedAcademicId;
      if (!academicId) {
        return jsonResponse({ error: "Missing required field: academic_id." }, { status: 400 });
      }

      // Best-effort academic_id uniqueness check.
      const { data: existingProfile, error: existingError } = await guard.adminClient
        .from("profiles")
        .select("id")
        .eq("academic_id", academicId)
        .maybeSingle();

      if (existingError) {
        return jsonResponse({ error: existingError.message }, { status: 400 });
      }

      if (existingProfile?.id) {
        if (!isAutoAcademicId) {
          return jsonResponse({ error: "academic_id already exists." }, { status: 409 });
        }
        usedPrefixes.add(nextPrefix);
        while (usedPrefixes.has(nextPrefix) && nextPrefix <= 9999) nextPrefix++;
        if (nextPrefix > 9999) {
          return jsonResponse({ error: "No available academic_id remaining." }, { status: 500 });
        }
        continue;
      }

      const password = requestedPassword || academicId;
      if (!password) {
        return jsonResponse(
          { error: "Missing required field: password." },
          { status: 400 },
        );
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
        lastErrorMsg = msg;
        const lower = msg.toLowerCase();
        const isConflict = lower.includes("already registered") || lower.includes("duplicate");
        if (isAutoAcademicId && isConflict) {
          usedPrefixes.add(nextPrefix);
          while (usedPrefixes.has(nextPrefix) && nextPrefix <= 9999) nextPrefix++;
          if (nextPrefix > 9999) {
            return jsonResponse({ error: "No available academic_id remaining." }, { status: 500 });
          }
          continue;
        }
        return jsonResponse({ error: msg }, { status: isConflict ? 409 : 400 });
      }

      const userId = created.user.id;

      const { error: profileError } = await guard.adminClient
        .from("profiles")
        .upsert({
          id: userId,
          name,
          role,
          academic_id: academicId,
          grade_id: gradeId,
          account_status: "active",
        });

      if (profileError) {
        // Delete auth user to avoid orphaned accounts.
        try {
          await guard.adminClient.auth.admin.deleteUser(userId);
        } catch (_) {
          // Ignore cleanup failures.
        }

        // Likely academic_id uniqueness.
        // Postgres unique violation code is 23505.
        // @ts-ignore - Postgrest error has code at runtime.
        if ((profileError as any)?.code === "23505") {
          lastErrorMsg = profileError.message;
          if (isAutoAcademicId) {
            usedPrefixes.add(nextPrefix);
            while (usedPrefixes.has(nextPrefix) && nextPrefix <= 9999) nextPrefix++;
            if (nextPrefix > 9999) {
              return jsonResponse({ error: "No available academic_id remaining." }, { status: 500 });
            }
            continue;
          }
          return jsonResponse({ error: profileError.message }, { status: 409 });
        }
        return jsonResponse({ error: profileError.message }, { status: 400 });
      }

      return jsonResponse({ user_id: userId, email, academic_id: academicId });
    }

    return jsonResponse(
      { error: lastErrorMsg ?? "Unable to allocate a unique academic_id." },
      { status: 500 },
    );
  } catch (e) {
    return jsonResponse(
      { error: e instanceof Error ? e.message : "Unknown error" },
      { status: 500 },
    );
  }
});
