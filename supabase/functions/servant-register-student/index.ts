import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

import {
  corsHeaders,
  corsPreflightResponse,
  jsonResponse,
} from "../_shared/cors.ts";
import { requireServantOrAdmin } from "../_shared/servant_guard.ts";

type RegisterStudentBody = {
  name: string;
  grade_id: string;
  academic_id?: string;
};

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

function generateAcademicId(): string {
  const ethYear = ethiopianYearFromGregorianDate(new Date());
  const yy = pad2(ethYear % 100);

  const bytes = new Uint8Array(2);
  crypto.getRandomValues(bytes);
  const raw = (bytes[0] << 8) + bytes[1];
  const fourDigits = (raw % 9000) + 1000;

  return `${fourDigits}/${yy}`;
}

function isUniqueViolation(message: string) {
  const msg = message.toLowerCase();
  return msg.includes("duplicate") || msg.includes("already") || msg.includes("unique");
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") return corsPreflightResponse();

  const guard = await requireServantOrAdmin(req);
  if (!guard.ok) {
    return jsonResponse(guard.body, { status: guard.status, headers: corsHeaders });
  }

  try {
    const body = (await req.json()) as Partial<RegisterStudentBody>;

    const name = (body.name ?? "").trim();
    const requestedGradeId = (body.grade_id ?? "").trim();
    const requestedAcademicId = (body.academic_id ?? "").trim();

    const gradeId = guard.callerRole === "servant"
      ? (guard.callerGradeId ?? "")
      : requestedGradeId;

    if (!name || !gradeId) {
      return jsonResponse(
        { error: "Missing required fields: name, grade_id." },
        { status: 400 },
      );
    }

    if (guard.callerRole === "servant" && requestedGradeId && requestedGradeId !== gradeId) {
      return jsonResponse(
        { error: "Forbidden: you can only register students in your grade." },
        { status: 403 },
      );
    }

    if (requestedAcademicId && !/^\d{4}\/\d{2}$/.test(requestedAcademicId)) {
      return jsonResponse(
        { error: "Invalid academic_id format. Expected xxxx/xx." },
        { status: 400 },
      );
    }

    // Validate grade exists.
    const { data: gradeRow, error: gradeError } = await guard.adminClient
      .from("grades")
      .select("id")
      .eq("id", gradeId)
      .maybeSingle();

    if (gradeError) {
      return jsonResponse({ error: gradeError.message }, { status: 400 });
    }

    if (!gradeRow) {
      return jsonResponse(
        { error: "Unknown grade_id." },
        { status: 400 },
      );
    }

    const tryCreate = async (academicId: string) => {
      const email = academicIdToEmail(academicId);

      const { data: created, error: createError } =
        await guard.adminClient.auth.admin.createUser({
          email,
          password: academicId,
          email_confirm: true,
        });

      if (createError || !created.user) {
        return {
          ok: false as const,
          status: isUniqueViolation(createError?.message ?? "") ? 409 : 400,
          error: createError?.message ?? "Failed to create user",
        };
      }

      const userId = created.user.id;

      const { error: profileError } = await guard.adminClient
        .from("profiles")
        .upsert({
          id: userId,
          name,
          role: "student",
          academic_id: academicId,
          grade_id: gradeId,
          account_status: "active",
        });

      if (profileError) {
        // If profile insert fails, delete the auth user to avoid orphaned accounts.
        try {
          await guard.adminClient.auth.admin.deleteUser(userId);
        } catch (_) {}

        return {
          ok: false as const,
          status: isUniqueViolation(profileError.message) ? 409 : 400,
          error: profileError.message,
        };
      }

      return {
        ok: true as const,
        user_id: userId,
        email,
        academic_id: academicId,
      };
    };

    if (requestedAcademicId) {
      const created = await tryCreate(requestedAcademicId);
      if (!created.ok) {
        return jsonResponse({ error: created.error }, { status: created.status });
      }
      return jsonResponse(created);
    }

    for (let i = 0; i < 10; i++) {
      const academicId = generateAcademicId();
      const created = await tryCreate(academicId);
      if (created.ok) return jsonResponse(created);
      if (created.status !== 409) {
        return jsonResponse({ error: created.error }, { status: created.status });
      }
    }

    return jsonResponse(
      { error: "Unable to generate a unique academic ID." },
      { status: 500 },
    );
  } catch (e) {
    return jsonResponse(
      { error: e instanceof Error ? e.message : "Unknown error" },
      { status: 500 },
    );
  }
});
