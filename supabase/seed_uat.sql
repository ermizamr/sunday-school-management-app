-- UAT seed data for the Sunday School Management System (hosted project).
--
-- Idempotent: safe to run multiple times. Re-running re-applies the UAT
-- passwords documented in docs/UAT_CHECKLIST.md.
--
-- What it creates:
--   1. Active academic year 2026-2027 (only when none is active)
--   2. Four subjects for each grade (Bible Studies, Christian History,
--      Memory Verses, Activities)
--   3. Login accounts: 2 servants + 3 students (admin already exists)
--   4. Promotion criteria sets per grade (run_promotion raises without them)
--   5. Sample assessments + scores for grades 1st and 2nd
--      (quiz 90% / 63% / 84% -> eligible, not_eligible, at_risk outcomes)
--   6. Attendance sessions + records for four Sundays (grade 1st and 2nd)
--   7. Two announcements, one student question, one complaint
--
-- Run as superuser/service role, e.g. via the Management API:
--   POST https://api.supabase.com/v1/projects/<ref>/database/query

begin;

-- 0. Run the whole seed as the admin for auth-guard purposes.
--    The grading trigger (enforce_assessment_prerequisites) resolves the
--    caller via auth.uid() -> request.jwt.claims. Without a JWT the session
--    looks like an inactive student and inserts are rejected. Setting the
--    admin's UUID transaction-local (is_local = true) makes every guard see
--    an admin; the setting resets automatically at commit/rollback.
do $$
declare
  v_admin_id uuid;
begin
  select id into v_admin_id
  from public.profiles
  where role = 'admin'
  order by created_at
  limit 1;

  if v_admin_id is not null then
    perform set_config(
      'request.jwt.claims',
      json_build_object('sub', v_admin_id, 'role', 'authenticated', 'iss', 'supabase')::text,
      true
    );
  end if;
end $$;

-- 1. Academic year -----------------------------------------------------------
--    Creates the canonical year when none is active. A leftover test year
--    named '2019' (created during API testing, no data attached yet) is
--    normalized instead of duplicated; the name marker keeps the seed from
--    ever touching a real year created later. The second update only fills
--    in missing semester boundaries on the canonical year (idempotent: it
--    stops matching as soon as the boundaries exist).
--
--    Promotion averages the two semesters and returns null when either
--    semester has no assessments, so the boundaries and the semester-2
--    assessment dates below must stay in sync:
--      semester1: 2026-09-11 .. 2026-10-18  (quiz 09-20, exam 10-04)
--      semester2: 2026-10-19 .. 2027-07-04  (quiz 11-01, exam 11-15)
do $$
begin
  if not exists (select 1 from public.academic_years where status = 'active') then
    insert into public.academic_years (
      name, start_date, end_date, status, current_period,
      semester1_end_date, semester2_start_date
    )
    values (
      '2026-2027', date '2026-09-11', date '2027-07-04', 'active', 'semester2',
      date '2026-10-18', date '2026-10-19'
    );
  else
    update public.academic_years
       set name = '2026-2027',
           start_date = date '2026-09-11',
           end_date = date '2027-07-04',
           current_period = 'semester2',
           semester1_end_date = date '2026-10-18',
           semester2_start_date = date '2026-10-19'
     where status = 'active'
       and name = '2019'
       and not exists (
         select 1 from public.assessments a where a.academic_year_id = academic_years.id
       )
       and not exists (
         select 1 from public.attendance_sessions s where s.academic_year_id = academic_years.id
       )
       and not exists (
         select 1 from public.promotion_runs r where r.academic_year_id = academic_years.id
       );

    update public.academic_years
       set semester1_end_date = date '2026-10-18',
           semester2_start_date = date '2026-10-19',
           current_period = 'semester2'
     where status = 'active'
       and name = '2026-2027'
       and (semester1_end_date is null or semester2_start_date is null);
  end if;
end $$;

-- 2. Subjects (4 per grade) --------------------------------------------------
insert into public.subjects (grade_id, name, passing_grade, weight, active)
select g.id, s.name, 70, 0, true
from public.grades g
cross join (values
  ('Bible Studies'),
  ('Christian History'),
  ('Memory Verses'),
  ('Activities')
) as s(name)
on conflict (grade_id, name) do nothing;

-- 3. Login accounts ----------------------------------------------------------
-- Students follow the app convention: password = academic_id.
-- Servants share one fixed password. Re-running re-applies these passwords.
do $$
declare
  v record;
  v_user_id uuid;
  v_grade_id uuid;
begin
  for v in
    select * from (values
      ('0001-18@school.local', '0001/18', 'servant', 'ኤርምያስ ምስክር', '1st', 'Servant123!'),
      ('0002-18@school.local', '0002/18', 'servant', 'ሳሙኤል ተስፋዬ',     '2nd', 'Servant123!'),
      ('0001-19@school.local', '0001/19', 'student', 'የሙከራ ተማሪ',     '1st', '0001/19'),
      ('0002-19@school.local', '0002/19', 'student', 'ሓና ወልደሚካኤል',   '1st', '0002/19'),
      ('0003-19@school.local', '0003/19', 'student', 'ነታናኤል አበበ',     '2nd', '0003/19')
    ) as t(email, academic_id, role, name, grade_code, password)
  loop
    select id into v_user_id from auth.users where email = v.email;

    if v_user_id is null then
      v_user_id := gen_random_uuid();
      -- Column values mirror what GoTrue's own admin API writes: the token
      -- columns must be '' (not null) or password login fails with
      -- "Database error querying schema".
      insert into auth.users (
        instance_id, id, aud, role, email, encrypted_password,
        email_confirmed_at,
        confirmation_token, recovery_token, email_change, email_change_token_new,
        raw_app_meta_data, raw_user_meta_data,
        created_at, updated_at
      ) values (
        '00000000-0000-0000-0000-000000000000', v_user_id, 'authenticated', 'authenticated',
        v.email, crypt(v.password, gen_salt('bf')), now(),
        '', '', '', '',
        '{"provider":"email","providers":["email"]}'::jsonb,
        jsonb_build_object('email_verified', true),
        now(), now()
      );

      insert into auth.identities (
        provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
      ) values (
        v_user_id::text, v_user_id,
        jsonb_build_object(
          'sub', v_user_id::text, 'email', v.email,
          'email_verified', false, 'phone_verified', false
        ),
        'email', now(), now(), now()
      );
    else
      -- Re-apply the documented UAT password on every run, and normalize any
      -- earlier raw-seeded row to the GoTrue-native shape (login-safe).
      -- (confirmed_at is a generated column derived from email_confirmed_at;
      -- never write it directly.)
      update auth.users
         set encrypted_password = crypt(v.password, gen_salt('bf')),
             email_confirmed_at = coalesce(email_confirmed_at, now()),
             confirmation_token = coalesce(confirmation_token, ''),
             recovery_token = coalesce(recovery_token, ''),
             email_change = coalesce(email_change, ''),
             email_change_token_new = coalesce(email_change_token_new, ''),
             updated_at = now()
       where id = v_user_id;

      update auth.identities i
         set identity_data = jsonb_build_object(
               'sub', i.user_id::text,
               'email', u.email,
               'email_verified', false,
               'phone_verified', false
             ),
             updated_at = now()
        from auth.users u
       where u.id = i.user_id
         and u.id = v_user_id
         and i.identity_data is distinct from jsonb_build_object(
               'sub', i.user_id::text,
               'email', u.email,
               'email_verified', false,
               'phone_verified', false
             );
    end if;

    select id into v_grade_id from public.grades where code = v.grade_code;

    insert into public.profiles (id, role, academic_id, name, grade_id, account_status)
    values (v_user_id, v.role::public.user_role, v.academic_id, v.name, v_grade_id, 'active')
    on conflict (id) do update
      set name = excluded.name,
          role = excluded.role,
          academic_id = excluded.academic_id,
          grade_id = excluded.grade_id,
          account_status = 'active';
  end loop;
end $$;

-- 4. Promotion criteria (run_promotion raises an exception without these) ----
insert into public.promotion_criteria_sets (
  academic_year_id, grade_id, minimum_overall_average, minimum_subject_grade, minimum_attendance
)
select ay.id, g.id, 70, 60, 75
from public.academic_years ay
cross join public.grades g
where ay.status = 'active'
on conflict (academic_year_id, grade_id) do nothing;

-- 5. Assessments -------------------------------------------------------------
-- Two per subject per semester for grades 1st and 2nd (the year average needs
-- both semesters to be non-null). Assessment weight must be > 0 or
-- compute_subject_average returns null (and promotion then says not_eligible).
insert into public.assessments (
  academic_year_id, grade_id, subject_id, grade_type, max_score, weight,
  assessment_date, created_by
)
select ay.id, g.id, s.id, t.grade_type, t.max_score, t.weight, t.assessment_date,
       coalesce(
         (select p.id from public.profiles p
           where p.role = 'servant' and p.grade_id = g.id
           order by p.created_at limit 1),
         (select p.id from public.profiles p
           where p.role = 'admin' order by p.created_at limit 1)
       )
from public.academic_years ay
join public.grades g on g.code in ('1st', '2nd')
join public.subjects s on s.grade_id = g.id
cross join (values
  ('Quiz', 20::numeric, 1, date '2026-09-20'),
  ('Exam', 50::numeric, 2, date '2026-10-04'),
  ('Quiz', 20::numeric, 1, date '2026-11-01'),
  ('Exam', 50::numeric, 2, date '2026-11-15')
) as t(grade_type, max_score, weight, assessment_date)
where ay.status = 'active'
  and not exists (
    select 1 from public.assessments a
    where a.academic_year_id = ay.id
      and a.subject_id = s.id
      and a.grade_type = t.grade_type
      and a.assessment_date = t.assessment_date
  );

-- 5b. Scores -----------------------------------------------------------------
-- 0001/19 -> ~90% (eligible), 0002/19 -> ~63% (below 70: not_eligible),
-- 0003/19 -> ~84% but 50% attendance (at_risk).
do $$
declare
  v record;
begin
  for v in
    select * from (values
      ('1st', '0001/19', 'Quiz', 18::numeric),
      ('1st', '0001/19', 'Exam', 45::numeric),
      ('1st', '0002/19', 'Quiz', 13::numeric),
      ('1st', '0002/19', 'Exam', 31::numeric),
      ('2nd', '0003/19', 'Quiz', 17::numeric),
      ('2nd', '0003/19', 'Exam', 42::numeric)
    ) as t(grade_code, student_academic_id, grade_type, score)
  loop
    insert into public.assessment_scores (assessment_id, student_id, score)
    select a.id, p.id, v.score
    from public.assessments a
    join public.subjects s on s.id = a.subject_id
    join public.grades g on g.id = s.grade_id
    cross join public.academic_years ay
    join public.profiles p on p.academic_id = v.student_academic_id
    where ay.status = 'active'
      and a.academic_year_id = ay.id
      and g.code = v.grade_code
      and a.grade_type = v.grade_type
    on conflict (assessment_id, student_id) do nothing;
  end loop;
end $$;

-- 6. Attendance: four Sundays, grades 1st and 2nd ----------------------------
insert into public.attendance_sessions (
  academic_year_id, grade_id, subject_id, session_date, created_by
)
select ay.id, g.id, s.id, d.session_date,
       coalesce(
         (select p.id from public.profiles p
           where p.role = 'servant' and p.grade_id = g.id
           order by p.created_at limit 1),
         (select p.id from public.profiles p
           where p.role = 'admin' order by p.created_at limit 1)
       )
from public.academic_years ay
join public.grades g on g.code in ('1st', '2nd')
join public.subjects s on s.grade_id = g.id
cross join (values
  (date '2026-09-13'),
  (date '2026-09-20'),
  (date '2026-09-27'),
  (date '2026-10-04')
) as d(session_date)
where ay.status = 'active'
on conflict (academic_year_id, subject_id, session_date) do nothing;

-- 6b. Records: 0001/19 = 100%, 0002/19 = 75%, 0003/19 = 50% attendance -----
insert into public.attendance_records (session_id, student_id, status, updated_by)
select ses.id, p.id, t.status::public.attendance_status, ses.created_by
from (values
  ('0001/19', date '2026-09-13', 'present'),
  ('0001/19', date '2026-09-20', 'present'),
  ('0001/19', date '2026-09-27', 'present'),
  ('0001/19', date '2026-10-04', 'present'),
  ('0002/19', date '2026-09-13', 'present'),
  ('0002/19', date '2026-09-20', 'present'),
  ('0002/19', date '2026-09-27', 'absent'),
  ('0002/19', date '2026-10-04', 'present'),
  ('0003/19', date '2026-09-13', 'present'),
  ('0003/19', date '2026-09-20', 'absent'),
  ('0003/19', date '2026-09-27', 'absent'),
  ('0003/19', date '2026-10-04', 'present')
) as t(academic_id, session_date, status)
join public.profiles p on p.academic_id = t.academic_id
join public.attendance_sessions ses
  on ses.session_date = t.session_date
 and ses.grade_id = p.grade_id
join public.academic_years ay
  on ay.id = ses.academic_year_id and ay.status = 'active'
on conflict (session_id, student_id) do nothing;

-- 7. Announcements -----------------------------------------------------------
insert into public.announcements (
  academic_year_id, grade_id, title, message, category, priority, created_by, active
)
select ay.id, null,
       'የእሁድ ትምህርት ሰዓት ተረጋግጧል',
       'ክብዬ ተማሪዎች፣ ከወራት በኋላ ትምህርታችን በጠዋት 6:00 ሆነው ይጀምራል። በሰዓቱ ውስጥ ይድረሱ።',
       'event', 'high',
       (select p.id from public.profiles p where p.role = 'admin' order by p.created_at limit 1),
       true
from public.academic_years ay
where ay.status = 'active'
  and not exists (
    select 1 from public.announcements a
    where a.title = 'የእሁድ ትምህርት ሰዓት ተረጋግጧል'
  );

insert into public.announcements (
  academic_year_id, grade_id, title, message, category, priority, created_by, active
)
select ay.id, g.id,
       'የመጀመሪያ ክፍል ግምገማ ተጀምሯል',
       'የመጀመሪያ ክፍል ተማሪዎች፣ የወራት ግምገማ ከዛሬ ጀምሮ ተጀምሯል። መልሶቻችሁን በሰዓቱ ውስጥ ያስገቡ።',
       'grades', 'high',
       (select p.id from public.profiles p
         where p.role = 'servant' and p.grade_id = g.id
         order by p.created_at limit 1),
       true
from public.academic_years ay
join public.grades g on g.code = '1st'
where ay.status = 'active'
  and not exists (
    select 1 from public.announcements a
    where a.title = 'የመጀመሪያ ክፍል ግምገማ ተጀምሯል'
  );

-- 8. One open question (grade 1st student) -----------------------------------
insert into public.questions (
  academic_year_id, grade_id, subject_id, student_id, question, answered
)
select ay.id, g.id, s.id, p.id,
       'መጀመሪያ ስብከቱ ጥቅስ 3 ትርጉሙን ልረዳ?',
       false
from public.academic_years ay
join public.grades g on g.code = '1st'
join public.subjects s on s.grade_id = g.id and s.name = 'Bible Studies'
join public.profiles p on p.academic_id = '0001/19'
where ay.status = 'active'
  and not exists (
    select 1 from public.questions q
    where q.student_id = p.id
      and q.question = 'መጀመሪያ ስብከቱ ጥቅስ 3 ትርጉሙን ልረዳ?'
  );

-- 9. One pending complaint (grade 1st student) -------------------------------
insert into public.complaints (
  academic_year_id, grade_id, student_id, category, complaint, status
)
select ay.id, g.id, p.id,
       'course',
       'ጥያቄዬ ለብዙ ጊዜ መልስ አልተቀበለም።',
       'pending'
from public.academic_years ay
join public.grades g on g.code = '1st'
join public.profiles p on p.academic_id = '0002/19'
where ay.status = 'active'
  and not exists (
    select 1 from public.complaints c
    where c.student_id = p.id
      and c.complaint = 'ጥያቄዬ ለብዙ ጊዜ መልስ አልተቀበለም።'
  );

commit;
