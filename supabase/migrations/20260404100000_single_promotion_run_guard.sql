-- Prevent running promotions more than once per academic year.
--
-- We guard:
-- - public.run_promotion: at most one run per (academic_year_id, grade_id)
-- - public.run_promotion_for_all_grades_with_summary: at most one "batch" promotion per academic year

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

  if exists (
    select 1
    from public.promotion_runs pr
    where pr.academic_year_id = p_academic_year_id
      and pr.grade_id = p_grade_id
  ) then
    raise exception 'Promotion already executed for this academic year and grade';
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

  if exists (
    select 1
    from public.promotion_runs pr
    where pr.academic_year_id = p_academic_year_id
  ) then
    raise exception 'Promotion already executed for this academic year';
  end if;

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
