-- Security hardening (NULL-safe admin checks + secure SECURITY DEFINER helpers)
--
-- Key fixes:
-- - Prevent admin-only RPC bypass when public.current_role() is NULL (missing profile row / anon).
-- - Add authorization checks to SECURITY DEFINER helper functions that accept p_student_id.
-- - Tighten servant grade isolation for attendance + assessment scores.
-- - Align feedback RLS with active-account requirements for servants.

create or replace function public._assert_admin(p_message text default 'Only admin can perform this action')
returns void
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if public.current_role() is distinct from 'admin' then
    raise exception '%', p_message;
  end if;
end;
$$;

-- -----------------------------------------------------------------------------
-- NULL-safe admin-only RPCs

create or replace function public.end_first_semester(
  p_academic_year_id uuid,
  p_semester1_end_date date
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public._assert_admin('Only admin can end first semester');

  update public.academic_years
  set semester1_end_date = p_semester1_end_date,
      current_period = 'break',
      updated_at = now()
  where id = p_academic_year_id
    and status = 'active';
end;
$$;

create or replace function public.start_second_semester(
  p_academic_year_id uuid,
  p_semester2_start_date date
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sem1_end date;
begin
  perform public._assert_admin('Only admin can start second semester');

  select semester1_end_date
    into v_sem1_end
  from public.academic_years
  where id = p_academic_year_id
    and status = 'active';

  if v_sem1_end is null then
    raise exception 'End first semester before starting second semester';
  end if;

  if p_semester2_start_date < v_sem1_end then
    raise exception 'Semester 2 start date cannot be before Semester 1 end date';
  end if;

  update public.academic_years
  set semester2_start_date = p_semester2_start_date,
      current_period = 'semester2',
      updated_at = now()
  where id = p_academic_year_id
    and status = 'active';
end;
$$;

create or replace function public.set_academic_year_period(
  p_academic_year_id uuid,
  p_period public.academic_year_period
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public._assert_admin('Only admin can set academic year period');

  update public.academic_years
  set current_period = p_period,
      updated_at = now()
  where id = p_academic_year_id;
end;
$$;

create or replace function public.archive_academic_year(p_academic_year_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public._assert_admin('Only admin can archive academic year');

  insert into public.archive_assessments select * from public.assessments where academic_year_id = p_academic_year_id;
  insert into public.archive_assessment_scores
    select s.*
    from public.assessment_scores s
    join public.assessments a on a.id = s.assessment_id
    where a.academic_year_id = p_academic_year_id;

  insert into public.archive_attendance_sessions select * from public.attendance_sessions where academic_year_id = p_academic_year_id;
  insert into public.archive_attendance_records
    select r.*
    from public.attendance_records r
    join public.attendance_sessions s on s.id = r.session_id
    where s.academic_year_id = p_academic_year_id;

  insert into public.archive_announcements select * from public.announcements where academic_year_id = p_academic_year_id;
  insert into public.archive_questions select * from public.questions where academic_year_id = p_academic_year_id;
  insert into public.archive_complaints select * from public.complaints where academic_year_id = p_academic_year_id;

  insert into public.archive_promotion_runs select * from public.promotion_runs where academic_year_id = p_academic_year_id;
  insert into public.archive_promotion_results
    select pr.*
    from public.promotion_results pr
    join public.promotion_runs r on r.id = pr.run_id
    where r.academic_year_id = p_academic_year_id;

  delete from public.assessment_scores
  where assessment_id in (select id from public.assessments where academic_year_id = p_academic_year_id);
  delete from public.assessments where academic_year_id = p_academic_year_id;

  delete from public.attendance_records
  where session_id in (select id from public.attendance_sessions where academic_year_id = p_academic_year_id);
  delete from public.attendance_sessions where academic_year_id = p_academic_year_id;

  delete from public.questions where academic_year_id = p_academic_year_id;
  delete from public.complaints where academic_year_id = p_academic_year_id;
  delete from public.announcements where academic_year_id = p_academic_year_id;

  delete from public.promotion_results
  where run_id in (select id from public.promotion_runs where academic_year_id = p_academic_year_id);
  delete from public.promotion_runs where academic_year_id = p_academic_year_id;

  update public.academic_years
  set status = 'archived',
      archived_at = now(),
      updated_at = now()
  where id = p_academic_year_id;
end;
$$;

create or replace function public.end_academic_year(p_academic_year_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public._assert_admin('Only admin can end academic year');

  update public.academic_years
  set status = 'ended',
      current_period = 'break',
      ended_at = now()
  where id = p_academic_year_id;
end;
$$;

create or replace function public.run_promotion(
  p_academic_year_id uuid,
  p_grade_id uuid,
  p_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_run_id uuid;
  s record;
  status public.promotion_status;
  overall_avg numeric;
  attendance_pct numeric;
  next_grade uuid;
  criteria public.promotion_criteria_sets%rowtype;
  attendance_shortfalls jsonb;
begin
  perform public._assert_admin('Only admin can run promotion');

  select * into criteria
  from public.promotion_criteria_sets pcs
  where pcs.academic_year_id = p_academic_year_id
    and pcs.grade_id = p_grade_id;

  if not found then
    raise exception 'Promotion criteria not configured for year % grade %', p_academic_year_id, p_grade_id;
  end if;

  insert into public.promotion_runs (academic_year_id, grade_id, run_by, notes)
  values (p_academic_year_id, p_grade_id, auth.uid(), p_notes)
  returning id into v_run_id;

  for s in
    select p.id
    from public.profiles p
    where p.role = 'student'
      and p.grade_id = p_grade_id
  loop
    status := public.determine_promotion_status(s.id, p_grade_id, p_academic_year_id);
    attendance_pct := public.compute_attendance_percent(s.id, p_academic_year_id);

    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'subject_id', sf.subject_id,
          'required_days', sf.required_days,
          'attended_days', sf.attended_days
        )
      ),
      '[]'::jsonb
    )
    into attendance_shortfalls
    from public.get_subject_attendance_shortfalls(
      s.id,
      criteria.id,
      p_academic_year_id
    ) sf;

    if jsonb_array_length(attendance_shortfalls) > 0 then
      overall_avg := null;
      next_grade := null;
      status := 'at_risk';
    else
      overall_avg := public.compute_year_average_from_semesters(s.id, p_grade_id, p_academic_year_id);
      next_grade := case when status = 'eligible' then public.get_next_grade_id(p_grade_id) else null end;
    end if;

    insert into public.promotion_results (
      run_id,
      student_id,
      status,
      overall_average,
      attendance_percent,
      recommended_next_grade_id,
      details
    )
    values (
      v_run_id,
      s.id,
      status,
      overall_avg,
      attendance_pct,
      next_grade,
      jsonb_build_object(
        'grade_id', p_grade_id,
        'academic_year_id', p_academic_year_id,
        'attendance_shortfalls', attendance_shortfalls,
        'notification', case
          when jsonb_array_length(attendance_shortfalls) > 0
            then 'Minimum attendance days not met for one or more subjects. Please contact servants.'
          else null
        end,
        'graduated', (status = 'eligible' and next_grade is null)
      )
    )
    on conflict (run_id, student_id) do update
      set status = excluded.status,
          overall_average = excluded.overall_average,
          attendance_percent = excluded.attendance_percent,
          recommended_next_grade_id = excluded.recommended_next_grade_id,
          computed_at = now(),
          details = excluded.details;

    if status = 'eligible' and next_grade is null then
      update public.profiles
      set account_status = 'graduated',
          updated_at = now()
      where id = s.id
        and role = 'student';
    end if;
  end loop;

  return v_run_id;
end;
$$;

create or replace function public.run_promotion_with_summary(
  p_academic_year_id uuid,
  p_grade_id uuid,
  p_notes text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_run_id uuid;
  v_total int := 0;
  v_eligible int := 0;
  v_at_risk int := 0;
  v_not_eligible int := 0;
  v_graduated int := 0;
begin
  perform public._assert_admin('Only admin can run promotion');

  v_run_id := public.run_promotion(
    p_academic_year_id,
    p_grade_id,
    p_notes
  );

  select count(*)::int into v_total
  from public.promotion_results pr
  where pr.run_id = v_run_id;

  select count(*)::int into v_eligible
  from public.promotion_results pr
  where pr.run_id = v_run_id
    and pr.status = 'eligible';

  select count(*)::int into v_at_risk
  from public.promotion_results pr
  where pr.run_id = v_run_id
    and pr.status = 'at_risk';

  select count(*)::int into v_not_eligible
  from public.promotion_results pr
  where pr.run_id = v_run_id
    and pr.status = 'not_eligible';

  select count(*)::int into v_graduated
  from public.promotion_results pr
  where pr.run_id = v_run_id
    and coalesce((pr.details ->> 'graduated')::boolean, false) = true;

  return jsonb_build_object(
    'run_id', v_run_id,
    'total_students', v_total,
    'eligible', v_eligible,
    'at_risk', v_at_risk,
    'not_eligible', v_not_eligible,
    'graduated', v_graduated
  );
end;
$$;

create or replace function public.run_promotion_for_all_grades_with_summary(
  p_academic_year_id uuid,
  p_notes text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  g record;
  v_missing_criteria_grades text;
  v_grade_summary jsonb;
  v_grade_summaries jsonb := '[]'::jsonb;
  v_total_grades int := 0;
  v_total_students int := 0;
  v_eligible int := 0;
  v_at_risk int := 0;
  v_not_eligible int := 0;
  v_graduated int := 0;
begin
  perform public._assert_admin('Only admin can run promotion');

  select string_agg(g2.name, ', ' order by g2.sort_order, g2.name)
  into v_missing_criteria_grades
  from public.grades g2
  where not exists (
    select 1
    from public.promotion_criteria_sets pcs
    where pcs.academic_year_id = p_academic_year_id
      and pcs.grade_id = g2.id
  );

  if v_missing_criteria_grades is not null then
    raise exception 'Promotion criteria missing for grades: %', v_missing_criteria_grades;
  end if;

  for g in
    select id, name
    from public.grades
    order by sort_order, name
  loop
    v_grade_summary := public.run_promotion_with_summary(
      p_academic_year_id,
      g.id,
      p_notes
    );

    v_grade_summary := jsonb_build_object(
      'grade_id', g.id,
      'grade_name', g.name
    ) || v_grade_summary;

    v_grade_summaries := v_grade_summaries || jsonb_build_array(v_grade_summary);

    v_total_grades := v_total_grades + 1;
    v_total_students := v_total_students + coalesce((v_grade_summary ->> 'total_students')::int, 0);
    v_eligible := v_eligible + coalesce((v_grade_summary ->> 'eligible')::int, 0);
    v_at_risk := v_at_risk + coalesce((v_grade_summary ->> 'at_risk')::int, 0);
    v_not_eligible := v_not_eligible + coalesce((v_grade_summary ->> 'not_eligible')::int, 0);
    v_graduated := v_graduated + coalesce((v_grade_summary ->> 'graduated')::int, 0);
  end loop;

  return jsonb_build_object(
    'academic_year_id', p_academic_year_id,
    'total_grades', v_total_grades,
    'total_students', v_total_students,
    'eligible', v_eligible,
    'at_risk', v_at_risk,
    'not_eligible', v_not_eligible,
    'graduated', v_graduated,
    'grade_summaries', v_grade_summaries
  );
end;
$$;

create or replace function public.start_new_academic_year(
  p_name text,
  p_start_date date,
  p_end_date date
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  previous_year_id uuid;
  new_year_id uuid;
  missing_grades text;
begin
  perform public._assert_admin('Only admin can start academic year');

  select id into previous_year_id
  from public.academic_years
  where status = 'active'
  order by start_date desc
  limit 1;

  if previous_year_id is not null then
    select string_agg(g.name, ', ' order by g.sort_order, g.name)
    into missing_grades
    from public.grades g
    where not exists (
      select 1
      from public.promotion_runs pr
      where pr.academic_year_id = previous_year_id
        and pr.grade_id = g.id
    );

    if missing_grades is not null then
      raise exception 'Cannot start new academic year. Run promotion for these grades first: %', missing_grades;
    end if;
  end if;

  if previous_year_id is not null then
    perform public.end_academic_year(previous_year_id);
  end if;

  insert into public.academic_years (name, start_date, end_date, status, current_period)
  values (p_name, p_start_date, p_end_date, 'active', 'semester1')
  returning id into new_year_id;

  if previous_year_id is not null then
    with last_runs as (
      select distinct on (r.grade_id)
        r.grade_id,
        r.id as run_id
      from public.promotion_runs r
      where r.academic_year_id = previous_year_id
      order by r.grade_id, r.run_at desc
    ), last_results as (
      select pr.*
      from public.promotion_results pr
      join last_runs lr on lr.run_id = pr.run_id
    )
    update public.profiles p
    set
      grade_id = case
        when lr.status = 'eligible' and lr.recommended_next_grade_id is not null
          then lr.recommended_next_grade_id
        else p.grade_id
      end,
      account_status = case
        when lr.status = 'eligible' and lr.recommended_next_grade_id is not null
          then 'active'
        when lr.status = 'eligible' and lr.recommended_next_grade_id is null
          then 'graduated'
        else 'inactive_pending_admin'
      end,
      updated_at = now()
    from last_results lr
    where p.id = lr.student_id
      and p.role = 'student';
  end if;

  return new_year_id;
end;
$$;

-- -----------------------------------------------------------------------------
-- Secure SECURITY DEFINER helper functions (p_student_id must be authorized)

create or replace function public.compute_subject_average_for_semester(
  p_student_id uuid,
  p_subject_id uuid,
  p_academic_year_id uuid,
  p_semester public.academic_year_period
)
returns numeric
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_from date;
  v_to date;
  result numeric;
begin
  perform public._assert_can_view_student(p_student_id);

  select b.from_date, b.to_date
  into v_from, v_to
  from public.get_semester_date_bounds(p_academic_year_id, p_semester) b
  limit 1;

  if v_from is null or v_to is null then
    return null;
  end if;

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
      and a.assessment_date >= v_from
      and a.assessment_date <= v_to
  )
  select
    case
      when coalesce(sum(weight), 0) = 0 then null
      else round((sum(percent * weight) / sum(weight))::numeric, 2)
    end
  into result
  from rows;

  return result;
end;
$$;

create or replace function public.compute_attendance_percent_for_semester(
  p_student_id uuid,
  p_academic_year_id uuid,
  p_semester public.academic_year_period
)
returns numeric
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_from date;
  v_to date;
  result numeric;
begin
  perform public._assert_can_view_student(p_student_id);

  select b.from_date, b.to_date
  into v_from, v_to
  from public.get_semester_date_bounds(p_academic_year_id, p_semester) b
  limit 1;

  if v_from is null or v_to is null then
    return null;
  end if;

  with rows as (
    select r.status
    from public.attendance_records r
    join public.attendance_sessions s on s.id = r.session_id
    where r.student_id = p_student_id
      and s.academic_year_id = p_academic_year_id
      and s.session_date >= v_from
      and s.session_date <= v_to
  )
  select
    case
      when count(*) filter (where status <> 'permission') = 0 then 0
      else round((100.0 * count(*) filter (where status in ('present', 'late'))
        / count(*) filter (where status <> 'permission'))::numeric, 2)
    end
  into result
  from rows;

  return result;
end;
$$;

create or replace function public.compute_overall_average_for_semester(
  p_student_id uuid,
  p_grade_id uuid,
  p_academic_year_id uuid,
  p_semester public.academic_year_period
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
      public.compute_subject_average_for_semester(
        p_student_id,
        sub.id,
        p_academic_year_id,
        p_semester
      ) as subject_avg
    from public.subjects sub
    where sub.grade_id = p_grade_id
      and sub.active = true
  )
  select
    case
      when coalesce(sum(subject_weight) filter (where subject_avg is not null), 0) = 0 then null
      else round(
        (
          sum(subject_avg * subject_weight) filter (where subject_avg is not null)
          / sum(subject_weight) filter (where subject_avg is not null)
        )::numeric,
        2
      )
    end
  into result
  from per_subject;

  return result;
end;
$$;

create or replace function public.compute_year_average_from_semesters(
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
  sem1 numeric;
  sem2 numeric;
begin
  perform public._assert_can_view_student(p_student_id);

  sem1 := public.compute_overall_average_for_semester(
    p_student_id,
    p_grade_id,
    p_academic_year_id,
    'semester1'
  );

  sem2 := public.compute_overall_average_for_semester(
    p_student_id,
    p_grade_id,
    p_academic_year_id,
    'semester2'
  );

  if sem1 is null or sem2 is null then
    return null;
  end if;

  return round(((sem1 + sem2) / 2.0)::numeric, 2);
end;
$$;

create or replace function public.has_passed_prerequisite_subject(
  p_student_id uuid,
  p_prerequisite_subject_id uuid,
  p_min_score numeric
)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  result boolean;
begin
  perform public._assert_can_view_student(p_student_id);

  with per_year as (
    select
      a.academic_year_id,
      case
        when coalesce(sum(a.weight), 0) = 0 then null
        else sum(((s.score / a.max_score) * 100.0) * a.weight) / sum(a.weight)
      end as subject_avg
    from public.assessment_scores s
    join public.assessments a on a.id = s.assessment_id
    where s.student_id = p_student_id
      and a.subject_id = p_prerequisite_subject_id
      and a.max_score > 0
      and a.weight > 0
    group by a.academic_year_id
  )
  select exists (
    select 1
    from per_year py
    where py.subject_avg is not null
      and py.subject_avg >= p_min_score
  )
  into result;

  return coalesce(result, false);
end;
$$;

create or replace function public.assert_subject_prerequisites(
  p_student_id uuid,
  p_subject_id uuid,
  p_academic_year_id uuid
)
returns void
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  unmet_count int;
begin
  perform public._assert_can_view_student(p_student_id);

  select count(*)
  into unmet_count
  from public.subject_prerequisites sp
  join public.subjects prereq on prereq.id = sp.prerequisite_subject_id
  where sp.subject_id = p_subject_id
    and not public.has_passed_prerequisite_subject(
      p_student_id,
      sp.prerequisite_subject_id,
      coalesce(sp.minimum_score, prereq.passing_grade)
    );

  if unmet_count > 0 then
    raise exception 'Student cannot take this subject before passing prerequisite subjects';
  end if;
end;
$$;

create or replace function public.compute_attendance_days_for_subject(
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

  select round(
    coalesce(
      sum(
        case r.status
          when 'present' then 1.0
          when 'permission' then 1.0
          when 'late' then 0.5
          else 0.0
        end
      ),
      0
    )::numeric,
    2
  )
  into result
  from public.attendance_records r
  join public.attendance_sessions s on s.id = r.session_id
  where r.student_id = p_student_id
    and s.subject_id = p_subject_id
    and s.academic_year_id = p_academic_year_id;

  return coalesce(result, 0);
end;
$$;

create or replace function public.get_subject_attendance_shortfalls(
  p_student_id uuid,
  p_criteria_set_id uuid,
  p_academic_year_id uuid
)
returns table (
  subject_id uuid,
  required_days numeric,
  attended_days numeric
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  perform public._assert_can_view_student(p_student_id);

  return query
  select
    pcs.subject_id,
    pcs.minimum_attendance_days as required_days,
    att.attended_days
  from public.promotion_criteria_subjects pcs
  cross join lateral (
    select public.compute_attendance_days_for_subject(
      p_student_id,
      pcs.subject_id,
      p_academic_year_id
    ) as attended_days
  ) att
  where pcs.criteria_set_id = p_criteria_set_id
    and coalesce(pcs.minimum_attendance_days, 0) > 0
    and att.attended_days < pcs.minimum_attendance_days;
end;
$$;

-- -----------------------------------------------------------------------------
-- Tighten servant grade isolation for score/attendance writes

drop policy if exists assessment_scores_read on public.assessment_scores;
create policy assessment_scores_read
on public.assessment_scores
for select
using (
  public.current_role() = 'admin'
  or (
    public.is_active_account()
    and student_id = auth.uid()
  )
  or (
    public.current_role() = 'servant'
    and public.is_active_account()
    and exists (
      select 1
      from public.assessments a
      where a.id = assessment_id
        and a.grade_id = public.current_grade_id()
    )
    and exists (
      select 1
      from public.profiles p
      where p.id = student_id
        and p.role = 'student'
        and p.grade_id = public.current_grade_id()
    )
  )
);

drop policy if exists assessment_scores_write_servant on public.assessment_scores;
create policy assessment_scores_write_servant
on public.assessment_scores
for insert
with check (
  public.current_role() = 'admin'
  or (
    public.current_role() = 'servant'
    and public.is_active_account()
    and exists (
      select 1
      from public.assessments a
      where a.id = assessment_id
        and a.grade_id = public.current_grade_id()
    )
    and exists (
      select 1
      from public.profiles p
      where p.id = student_id
        and p.role = 'student'
        and p.grade_id = public.current_grade_id()
    )
  )
);

drop policy if exists assessment_scores_update_servant on public.assessment_scores;
create policy assessment_scores_update_servant
on public.assessment_scores
for update
using (
  public.current_role() = 'admin'
  or (
    public.current_role() = 'servant'
    and public.is_active_account()
    and exists (
      select 1
      from public.assessments a
      where a.id = assessment_id
        and a.grade_id = public.current_grade_id()
    )
    and exists (
      select 1
      from public.profiles p
      where p.id = student_id
        and p.role = 'student'
        and p.grade_id = public.current_grade_id()
    )
  )
)
with check (
  public.current_role() = 'admin'
  or (
    public.current_role() = 'servant'
    and public.is_active_account()
    and exists (
      select 1
      from public.assessments a
      where a.id = assessment_id
        and a.grade_id = public.current_grade_id()
    )
    and exists (
      select 1
      from public.profiles p
      where p.id = student_id
        and p.role = 'student'
        and p.grade_id = public.current_grade_id()
    )
  )
);

drop policy if exists assessment_scores_delete_servant on public.assessment_scores;
create policy assessment_scores_delete_servant
on public.assessment_scores
for delete
using (
  public.current_role() = 'admin'
  or (
    public.current_role() = 'servant'
    and public.is_active_account()
    and exists (
      select 1
      from public.assessments a
      where a.id = assessment_id
        and a.grade_id = public.current_grade_id()
    )
    and exists (
      select 1
      from public.profiles p
      where p.id = student_id
        and p.role = 'student'
        and p.grade_id = public.current_grade_id()
    )
  )
);

-- Attendance records

drop policy if exists attendance_records_read on public.attendance_records;
create policy attendance_records_read
on public.attendance_records
for select
using (
  public.current_role() = 'admin'
  or (
    public.is_active_account()
    and student_id = auth.uid()
  )
  or (
    public.current_role() = 'servant'
    and public.is_active_account()
    and exists (
      select 1
      from public.attendance_sessions s
      where s.id = session_id
        and s.grade_id = public.current_grade_id()
    )
    and exists (
      select 1
      from public.profiles p
      where p.id = student_id
        and p.role = 'student'
        and p.grade_id = public.current_grade_id()
    )
  )
);

drop policy if exists attendance_records_update_servant on public.attendance_records;
create policy attendance_records_update_servant
on public.attendance_records
for update
using (
  public.current_role() = 'admin'
  or (
    public.current_role() = 'servant'
    and public.is_active_account()
    and exists (
      select 1
      from public.attendance_sessions s
      where s.id = session_id
        and s.grade_id = public.current_grade_id()
    )
    and exists (
      select 1
      from public.profiles p
      where p.id = student_id
        and p.role = 'student'
        and p.grade_id = public.current_grade_id()
    )
  )
)
with check (
  public.current_role() = 'admin'
  or (
    public.current_role() = 'servant'
    and public.is_active_account()
    and exists (
      select 1
      from public.attendance_sessions s
      where s.id = session_id
        and s.grade_id = public.current_grade_id()
    )
    and exists (
      select 1
      from public.profiles p
      where p.id = student_id
        and p.role = 'student'
        and p.grade_id = public.current_grade_id()
    )
  )
);

drop policy if exists attendance_records_write_servant on public.attendance_records;
create policy attendance_records_write_servant
on public.attendance_records
for insert
with check (
  public.current_role() = 'admin'
  or (
    public.current_role() = 'servant'
    and public.is_active_account()
    and exists (
      select 1
      from public.attendance_sessions s
      where s.id = session_id
        and s.grade_id = public.current_grade_id()
    )
    and exists (
      select 1
      from public.profiles p
      where p.id = student_id
        and p.role = 'student'
        and p.grade_id = public.current_grade_id()
    )
  )
);

-- -----------------------------------------------------------------------------
-- Feedback RLS: servants must be active

-- Forms

drop policy if exists feedback_forms_read on public.feedback_forms;
create policy feedback_forms_read
on public.feedback_forms
for select
using (
  public.current_role() = 'admin'
  or (
    public.current_role() = 'student'
    and public.is_active_account()
    and grade_id = public.current_grade_id()
  )
  or (
    public.current_role() = 'servant'
    and public.is_active_account()
    and grade_id = public.current_grade_id()
  )
);

drop policy if exists feedback_forms_update_servant on public.feedback_forms;
create policy feedback_forms_update_servant
on public.feedback_forms
for update
using (
  public.current_role() = 'admin'
  or (
    public.current_role() = 'servant'
    and public.is_active_account()
    and grade_id = public.current_grade_id()
  )
)
with check (
  public.current_role() = 'admin'
  or (
    public.current_role() = 'servant'
    and public.is_active_account()
    and grade_id = public.current_grade_id()
  )
);

drop policy if exists feedback_forms_delete_servant on public.feedback_forms;
create policy feedback_forms_delete_servant
on public.feedback_forms
for delete
using (
  public.current_role() = 'admin'
  or (
    public.current_role() = 'servant'
    and public.is_active_account()
    and grade_id = public.current_grade_id()
  )
);

-- Questions

drop policy if exists feedback_questions_read on public.feedback_questions;
create policy feedback_questions_read
on public.feedback_questions
for select
using (
  public.current_role() = 'admin'
  or (
    public.current_role() = 'student'
    and public.is_active_account()
    and exists (
      select 1 from public.feedback_forms f
      where f.id = form_id and f.grade_id = public.current_grade_id()
    )
  )
  or (
    public.current_role() = 'servant'
    and public.is_active_account()
    and exists (
      select 1 from public.feedback_forms f
      where f.id = form_id and f.grade_id = public.current_grade_id()
    )
  )
);

drop policy if exists feedback_questions_insert_servant on public.feedback_questions;
create policy feedback_questions_insert_servant
on public.feedback_questions
for insert
with check (
  public.current_role() = 'admin'
  or (
    public.current_role() = 'servant'
    and public.is_active_account()
    and exists (
      select 1 from public.feedback_forms f
      where f.id = form_id and f.grade_id = public.current_grade_id()
    )
  )
);

drop policy if exists feedback_questions_update_servant on public.feedback_questions;
create policy feedback_questions_update_servant
on public.feedback_questions
for update
using (
  public.current_role() = 'admin'
  or (
    public.current_role() = 'servant'
    and public.is_active_account()
    and exists (
      select 1 from public.feedback_forms f
      where f.id = form_id and f.grade_id = public.current_grade_id()
    )
  )
)
with check (
  public.current_role() = 'admin'
  or (
    public.current_role() = 'servant'
    and public.is_active_account()
    and exists (
      select 1 from public.feedback_forms f
      where f.id = form_id and f.grade_id = public.current_grade_id()
    )
  )
);

drop policy if exists feedback_questions_delete_servant on public.feedback_questions;
create policy feedback_questions_delete_servant
on public.feedback_questions
for delete
using (
  public.current_role() = 'admin'
  or (
    public.current_role() = 'servant'
    and public.is_active_account()
    and exists (
      select 1 from public.feedback_forms f
      where f.id = form_id and f.grade_id = public.current_grade_id()
    )
  )
);

-- Submissions

drop policy if exists feedback_submissions_read on public.feedback_submissions;
create policy feedback_submissions_read
on public.feedback_submissions
for select
using (
  public.current_role() = 'admin'
  or (
    public.current_role() = 'student'
    and public.is_active_account()
    and student_id = auth.uid()
  )
  or (
    public.current_role() = 'servant'
    and public.is_active_account()
    and exists (
      select 1 from public.feedback_forms f
      where f.id = form_id and f.grade_id = public.current_grade_id()
    )
  )
);

drop policy if exists feedback_submissions_delete_servant on public.feedback_submissions;
create policy feedback_submissions_delete_servant
on public.feedback_submissions
for delete
using (
  public.current_role() = 'admin'
  or (
    public.current_role() = 'servant'
    and public.is_active_account()
    and exists (
      select 1 from public.feedback_forms f
      where f.id = form_id and f.grade_id = public.current_grade_id()
    )
  )
);
