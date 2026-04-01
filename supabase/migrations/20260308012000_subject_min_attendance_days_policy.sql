-- Promotions policy refinement:
-- - Add per-subject minimum attendance days.
-- - Weighted attendance days per subject: present=1.0, permission=1.0, late=0.5, absent=0.0.
-- - If student is below any configured subject minimum days, promotion status is at_risk and
--   yearly grade calculation is withheld for promotion run output.

alter table public.promotion_criteria_subjects
  add column if not exists minimum_attendance_days numeric;
create or replace function public.compute_attendance_days_for_subject(
  p_student_id uuid,
  p_subject_id uuid,
  p_academic_year_id uuid
)
returns numeric
language sql
stable
security definer
set search_path = public
as $$
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
  from public.attendance_records r
  join public.attendance_sessions s on s.id = r.session_id
  where r.student_id = p_student_id
    and s.subject_id = p_subject_id
    and s.academic_year_id = p_academic_year_id;
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
language sql
stable
security definer
set search_path = public
as $$
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
$$;
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
  yearly_avg numeric;
  attendance_pct numeric;
  has_shortfall boolean;
begin
  perform public._assert_can_view_student(p_student_id);

  select * into criteria
  from public.promotion_criteria_sets pcs
  where pcs.academic_year_id = p_academic_year_id
    and pcs.grade_id = p_grade_id;

  if not found then
    raise exception 'Promotion criteria not configured for year % grade %', p_academic_year_id, p_grade_id;
  end if;

  yearly_avg := public.compute_year_average_from_semesters(p_student_id, p_grade_id, p_academic_year_id);
  attendance_pct := public.compute_attendance_percent(p_student_id, p_academic_year_id);

  select exists (
    select 1
    from public.get_subject_attendance_shortfalls(
      p_student_id,
      criteria.id,
      p_academic_year_id
    ) sf
  ) into has_shortfall;

  if yearly_avg is null then
    return 'not_eligible';
  end if;

  if yearly_avg < criteria.minimum_overall_average then
    return 'not_eligible';
  end if;

  if has_shortfall then
    return 'at_risk';
  end if;

  if attendance_pct < criteria.minimum_attendance then
    return 'at_risk';
  end if;

  return 'eligible';
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
  run_id uuid;
  s record;
  status public.promotion_status;
  overall_avg numeric;
  attendance_pct numeric;
  next_grade uuid;
  criteria public.promotion_criteria_sets%rowtype;
  attendance_shortfalls jsonb;
begin
  if public.current_role() <> 'admin' then
    raise exception 'Only admin can run promotion';
  end if;

  select * into criteria
  from public.promotion_criteria_sets pcs
  where pcs.academic_year_id = p_academic_year_id
    and pcs.grade_id = p_grade_id;

  if not found then
    raise exception 'Promotion criteria not configured for year % grade %', p_academic_year_id, p_grade_id;
  end if;

  insert into public.promotion_runs (academic_year_id, grade_id, run_by, notes)
  values (p_academic_year_id, p_grade_id, auth.uid(), p_notes)
  returning id into run_id;

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
      run_id,
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

  return run_id;
end;
$$;
grant execute on function public.compute_attendance_days_for_subject(uuid, uuid, uuid) to authenticated;
grant execute on function public.get_subject_attendance_shortfalls(uuid, uuid, uuid) to authenticated;
