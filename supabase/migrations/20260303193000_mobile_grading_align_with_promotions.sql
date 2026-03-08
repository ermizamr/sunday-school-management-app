-- Mobile grading alignment with Promotions
--
-- 1) Adds student-safe RPCs so the mobile app can use the same grading logic
--    as the Promotions admin panel (DB functions + configured criteria).
-- 2) Restricts SECURITY DEFINER grading functions to prevent computing grades
--    for other students without proper authorization.

create or replace function public._assert_can_view_student(p_student_id uuid)
returns void
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  student_grade_id uuid;
begin
  -- Admin can view anyone.
  if public.current_role() = 'admin' then
    return;
  end if;

  -- Non-admin accounts must be active.
  if not public.is_active_account() then
    raise exception 'Inactive account';
  end if;

  -- Student can only view self.
  if public.current_role() = 'student' then
    if p_student_id <> auth.uid() then
      raise exception 'Not authorized';
    end if;
    return;
  end if;

  -- Servant can view students in their grade.
  if public.current_role() = 'servant' then
    select p.grade_id
    into student_grade_id
    from public.profiles p
    where p.id = p_student_id
      and p.role = 'student';

    if student_grade_id is null then
      raise exception 'Student not found';
    end if;

    if public.current_grade_id() is null or student_grade_id <> public.current_grade_id() then
      raise exception 'Not authorized';
    end if;

    return;
  end if;

  raise exception 'Not authorized';
end;
$$;
-- Redefine grading functions with authorization checks.

create or replace function public.compute_subject_average(
  p_student_id uuid,
  p_subject_id uuid,
  p_academic_year_id uuid
)
returns numeric
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  result numeric;
begin
  perform public._assert_can_view_student(p_student_id);

  with rows as (
    select
      (s.score / a.max_score) * 100.0 as percent,
      a.weight as weight
    from public.assessment_scores s
    join public.assessments a on a.id = s.assessment_id
    where s.student_id = p_student_id
      and a.subject_id = p_subject_id
      and a.academic_year_id = p_academic_year_id
      and a.max_score > 0
      and a.weight > 0
  )
  select
    case
      when coalesce(sum(weight), 0) = 0 then null
      else sum(percent * weight) / sum(weight)
    end
  into result
  from rows;

  return result;
end;
$$;
create or replace function public.compute_overall_average(
  p_student_id uuid,
  p_grade_id uuid,
  p_academic_year_id uuid
)
returns numeric
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  result numeric;
begin
  perform public._assert_can_view_student(p_student_id);

  with per_subject as (
    select
      sub.id as subject_id,
      coalesce(nullif(sub.weight, 0), 1) as subject_weight,
      public.compute_subject_average(p_student_id, sub.id, p_academic_year_id) as subject_avg
    from public.subjects sub
    where sub.grade_id = p_grade_id
      and sub.active = true
  )
  select
    case
      when coalesce(sum(subject_weight) filter (where subject_avg is not null), 0) = 0 then null
      else
        sum(subject_avg * subject_weight) filter (where subject_avg is not null)
        / sum(subject_weight) filter (where subject_avg is not null)
    end
  into result
  from per_subject;

  return result;
end;
$$;
create or replace function public.compute_attendance_percent(
  p_student_id uuid,
  p_academic_year_id uuid
)
returns numeric
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  result numeric;
begin
  perform public._assert_can_view_student(p_student_id);

  with rows as (
    select r.status
    from public.attendance_records r
    join public.attendance_sessions s on s.id = r.session_id
    where r.student_id = p_student_id
      and s.academic_year_id = p_academic_year_id
  )
  select
    case
      when count(*) filter (where status <> 'permission') = 0 then 0
      else
        100.0 * count(*) filter (where status in ('present', 'late'))
        / count(*) filter (where status <> 'permission')
    end
  into result
  from rows;

  return result;
end;
$$;
-- Student-safe wrappers (avoid passing student_id from the client).

create or replace function public.get_my_grading_snapshot(
  p_grade_id uuid,
  p_academic_year_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  criteria public.promotion_criteria_sets%rowtype;
  overall_avg numeric;
  attendance_pct numeric;
  status public.promotion_status;
  category text;
begin
  -- Ensure caller is an authenticated, active account (admin is allowed).
  perform public._assert_can_view_student(auth.uid());

  select * into criteria
  from public.promotion_criteria_sets pcs
  where pcs.academic_year_id = p_academic_year_id
    and pcs.grade_id = p_grade_id;

  if not found then
    raise exception 'Promotion criteria not configured for year % grade %', p_academic_year_id, p_grade_id;
  end if;

  overall_avg := public.compute_overall_average(auth.uid(), p_grade_id, p_academic_year_id);
  attendance_pct := public.compute_attendance_percent(auth.uid(), p_academic_year_id);
  status := public.determine_promotion_status(auth.uid(), p_grade_id, p_academic_year_id);

  if overall_avg is null then
    category := null;
  elsif overall_avg >= criteria.excellent_lower and overall_avg <= criteria.excellent_upper then
    category := 'excellent';
  elsif overall_avg >= criteria.very_good_lower and overall_avg <= criteria.very_good_upper then
    category := 'very_good';
  elsif overall_avg >= criteria.good_lower and overall_avg <= criteria.good_upper then
    category := 'good';
  elsif overall_avg >= criteria.enough_lower and overall_avg <= criteria.enough_upper then
    category := 'enough';
  elsif overall_avg < criteria.enough_lower then
    category := 'critical';
  else
    category := 'critical';
  end if;

  return jsonb_build_object(
    'overall_average', overall_avg,
    'attendance_percent', attendance_pct,
    'status', status,
    'grade_category', category
  );
end;
$$;
create or replace function public.get_my_subject_averages(
  p_grade_id uuid,
  p_academic_year_id uuid
)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'subject_id', sub.id,
        'subject_average', public.compute_subject_average(auth.uid(), sub.id, p_academic_year_id)
      )
      order by sub.name
    ),
    '[]'::jsonb
  )
  from public.subjects sub
  where sub.grade_id = p_grade_id
    and sub.active = true;
$$;
-- Allow authenticated callers to execute the RPCs.
grant execute on function public.get_my_grading_snapshot(uuid, uuid) to authenticated;
grant execute on function public.get_my_subject_averages(uuid, uuid) to authenticated;
-- Secure promotion status computation (latest prerequisite-only logic).

create or replace function public.determine_promotion_status(
  p_student_id uuid,
  p_grade_id uuid,
  p_academic_year_id uuid
)
returns public.promotion_status
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  criteria public.promotion_criteria_sets%rowtype;
  overall_avg numeric;
  attendance_pct numeric;
  any_prereq_below_min boolean;
begin
  perform public._assert_can_view_student(p_student_id);

  select * into criteria
  from public.promotion_criteria_sets pcs
  where pcs.academic_year_id = p_academic_year_id
    and pcs.grade_id = p_grade_id;

  if not found then
    raise exception 'Promotion criteria not configured for year % grade %', p_academic_year_id, p_grade_id;
  end if;

  overall_avg := public.compute_overall_average(p_student_id, p_grade_id, p_academic_year_id);
  attendance_pct := public.compute_attendance_percent(p_student_id, p_academic_year_id);

  if overall_avg is null then
    return 'not_eligible';
  end if;

  if overall_avg < criteria.minimum_overall_average then
    return 'not_eligible';
  end if;

  select exists (
    select 1
    from public.promotion_criteria_subjects pcs
    join public.subjects sub on sub.id = pcs.subject_id
    where pcs.criteria_set_id = criteria.id
      and pcs.required = true
      and coalesce(
        public.compute_subject_average(p_student_id, sub.id, p_academic_year_id),
        -1
      ) < coalesce(pcs.minimum_grade, criteria.minimum_subject_grade, sub.passing_grade)
  ) into any_prereq_below_min;

  if attendance_pct < criteria.minimum_attendance then
    return 'at_risk';
  end if;

  if any_prereq_below_min then
    return 'at_risk';
  end if;

  return 'eligible';
end;
$$;
