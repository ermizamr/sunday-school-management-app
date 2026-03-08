import { createClient } from "@supabase/supabase-js";

function fail(message) {
  console.error(`❌ ${message}`);
  process.exit(1);
}

function assert(condition, message) {
  if (!condition) fail(message);
}

function getEnv(name) {
  const value = process.env[name];
  if (!value) fail(`Missing env var: ${name}`);
  return value;
}

function formatDate(date) {
  return date.toISOString().slice(0, 10);
}

function clampDateBetween(start, end) {
  const now = new Date();
  if (now < start) return new Date(start);
  if (now > end) return new Date(end);
  return now;
}

async function main() {
  const apply = process.argv.includes("--apply");

  const supabaseUrl = getEnv("VITE_SUPABASE_URL");
  const supabaseAnonKey = getEnv("VITE_SUPABASE_ANON_KEY");
  const adminEmail = getEnv("E2E_ADMIN_EMAIL");
  const adminPassword = getEnv("E2E_ADMIN_PASSWORD");
  const studentEmail = getEnv("E2E_STUDENT_EMAIL");
  const studentPassword = getEnv("E2E_STUDENT_PASSWORD");

  const adminClient = createClient(supabaseUrl, supabaseAnonKey);

  const adminSignIn = await adminClient.auth.signInWithPassword({
    email: adminEmail,
    password: adminPassword,
  });

  if (adminSignIn.error) {
    fail(`Admin login failed: ${adminSignIn.error.message}`);
  }

  const { data: activeYear, error: yearError } = await adminClient
    .from("academic_years")
    .select("id, name, status, start_date, end_date, current_period, semester1_end_date, semester2_start_date")
    .eq("status", "active")
    .single();

  if (yearError) fail(`Failed loading active academic year: ${yearError.message}`);
  assert(activeYear, "No active academic year found.");

  const start = new Date(activeYear.start_date);
  const end = new Date(activeYear.end_date);
  const sem1EndBase = clampDateBetween(start, end);
  const sem1End = formatDate(sem1EndBase);

  const sem2StartDate = new Date(sem1EndBase);
  sem2StartDate.setDate(sem2StartDate.getDate() + 1);
  if (sem2StartDate > end) sem2StartDate.setTime(end.getTime());
  const sem2Start = formatDate(sem2StartDate);

  console.log("🔎 Active year loaded:", {
    id: activeYear.id,
    name: activeYear.name,
    current_period: activeYear.current_period,
    start_date: activeYear.start_date,
    end_date: activeYear.end_date,
  });

  console.log("🧪 Planned semester boundary actions:", {
    end_first_semester: sem1End,
    start_second_semester: sem2Start,
    mode: apply ? "APPLY" : "DRY_RUN",
  });

  if (apply) {
    const endSem1 = await adminClient.rpc("end_first_semester", {
      p_academic_year_id: activeYear.id,
      p_semester1_end_date: sem1End,
    });

    if (endSem1.error) fail(`end_first_semester failed: ${endSem1.error.message}`);

    const startSem2 = await adminClient.rpc("start_second_semester", {
      p_academic_year_id: activeYear.id,
      p_semester2_start_date: sem2Start,
    });

    if (startSem2.error) fail(`start_second_semester failed: ${startSem2.error.message}`);

    const { data: afterYear, error: afterYearError } = await adminClient
      .from("academic_years")
      .select("id, current_period, semester1_end_date, semester2_start_date")
      .eq("id", activeYear.id)
      .single();

    if (afterYearError) fail(`Failed reloading year after updates: ${afterYearError.message}`);

    assert(afterYear.current_period === "semester2", "Expected current_period to be semester2 after start_second_semester.");
    assert(afterYear.semester1_end_date === sem1End, "Semester 1 end date not persisted as expected.");
    assert(afterYear.semester2_start_date === sem2Start, "Semester 2 start date not persisted as expected.");

    console.log("✅ Admin semester transition assertions passed.");
  } else {
    console.log("ℹ️ Dry run mode: no DB writes performed. Re-run with --apply to execute transitions.");
  }

  const studentClient = createClient(supabaseUrl, supabaseAnonKey);

  const studentSignIn = await studentClient.auth.signInWithPassword({
    email: studentEmail,
    password: studentPassword,
  });

  if (studentSignIn.error) {
    fail(`Student login failed: ${studentSignIn.error.message}`);
  }

  const studentId = studentSignIn.data.user?.id;
  assert(studentId, "Student auth user id is missing.");

  const { data: studentProfile, error: profileError } = await studentClient
    .from("profiles")
    .select("id, grade_id, role, account_status")
    .eq("id", studentId)
    .single();

  if (profileError) fail(`Failed loading student profile: ${profileError.message}`);
  assert(studentProfile.role === "student", "Provided student credentials are not a student account.");
  assert(studentProfile.grade_id, "Student has no grade_id; cannot run semester reports.");

  const { data: criteriaRow, error: criteriaLoadError } = await adminClient
    .from("promotion_criteria_sets")
    .select("id")
    .eq("academic_year_id", activeYear.id)
    .eq("grade_id", studentProfile.grade_id)
    .maybeSingle();

  if (criteriaLoadError) {
    fail(`Failed loading promotion criteria: ${criteriaLoadError.message}`);
  }

  if (!criteriaRow) {
    const { error: criteriaCreateError } = await adminClient
      .from("promotion_criteria_sets")
      .upsert(
        {
          academic_year_id: activeYear.id,
          grade_id: studentProfile.grade_id,
        },
        { onConflict: "academic_year_id,grade_id" },
      );

    if (criteriaCreateError) {
      fail(`Failed creating default promotion criteria: ${criteriaCreateError.message}`);
    }

    console.log("ℹ️ Auto-created default promotion criteria for active year + student grade.");
  }

  const sem1Report = await studentClient.rpc("get_my_semester_report", {
    p_academic_year_id: activeYear.id,
    p_grade_id: studentProfile.grade_id,
    p_semester: "semester1",
  });

  if (sem1Report.error) fail(`get_my_semester_report(semester1) failed: ${sem1Report.error.message}`);

  const sem2Report = await studentClient.rpc("get_my_semester_report", {
    p_academic_year_id: activeYear.id,
    p_grade_id: studentProfile.grade_id,
    p_semester: "semester2",
  });

  if (sem2Report.error) fail(`get_my_semester_report(semester2) failed: ${sem2Report.error.message}`);

  const assessment = await studentClient.rpc("get_my_academic_assessment", {
    p_academic_year_id: activeYear.id,
    p_grade_id: studentProfile.grade_id,
  });

  if (assessment.error) fail(`get_my_academic_assessment failed: ${assessment.error.message}`);

  assert(sem1Report.data && typeof sem1Report.data === "object", "Semester 1 report payload missing.");
  assert(sem2Report.data && typeof sem2Report.data === "object", "Semester 2 report payload missing.");
  assert(assessment.data && typeof assessment.data === "object", "Academic assessment payload missing.");

  console.log("✅ Student report RPC assertions passed.");
  console.log("🎉 E2E semester flow test completed successfully.");
}

main().catch((error) => {
  fail(error?.message ?? String(error));
});
