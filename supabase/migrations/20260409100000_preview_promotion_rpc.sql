-- Preview promotion results without writing promotion_runs/promotion_results.
--
-- This is intended for admin testing and validation (safe to run multiple times).

create or replace function public.preview_promotion_with_summary(
  p_academic_year_id uuid,
  p_grade_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  s record;
  status public.promotion_status;
  next_grade uuid;
  criteria public.promotion_criteria_sets%rowtype;
  attendance_shortfalls jsonb;
  v_total int := 0;
  v_eligible int := 0;
  v_at_risk int := 0;
  v_not_eligible int := 0;
  v_graduated int := 0;
begin
  perform public._assert_admin('Only admin can preview promotion');

  select * into criteria
  from public.promotion_criteria_sets pcs
  where pcs.academic_year_id = p_academic_year_id
    and pcs.grade_id = p_grade_id;

  if not found then
    raise exception 'Promotion criteria not configured for year % grade %', p_academic_year_id, p_grade_id;
  end if;

  for s in
    select p.id
    from public.profiles p
    where p.role = 'student'
      and p.grade_id = p_grade_id
  loop
    status := public.determine_promotion_status(s.id, p_grade_id, p_academic_year_id);

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
      status := 'at_risk';
      next_grade := null;
    else
      next_grade := case when status = 'eligible' then public.get_next_grade_id(p_grade_id) else null end;
    end if;

    v_total := v_total + 1;

    if status = 'eligible' then
      v_eligible := v_eligible + 1;
    elsif status = 'at_risk' then
      v_at_risk := v_at_risk + 1;
    elsif status = 'not_eligible' then
      v_not_eligible := v_not_eligible + 1;
    end if;

    if status = 'eligible' and next_grade is null then
      v_graduated := v_graduated + 1;
    end if;
  end loop;

  return jsonb_build_object(
    'total_students', v_total,
    'eligible', v_eligible,
    'at_risk', v_at_risk,
    'not_eligible', v_not_eligible,
    'graduated', v_graduated
  );
end;
$$;

create or replace function public.preview_promotion_for_all_grades_with_summary(
  p_academic_year_id uuid
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
  perform public._assert_admin('Only admin can preview promotion');

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
    v_grade_summary := public.preview_promotion_with_summary(
      p_academic_year_id,
      g.id
    );

    v_grade_summary := jsonb_build_object(
      'grade_id', g.id,
      'grade_name', g.name,
      'run_id', null
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

grant execute on function public.preview_promotion_with_summary(uuid, uuid) to authenticated;
grant execute on function public.preview_promotion_for_all_grades_with_summary(uuid) to authenticated;
