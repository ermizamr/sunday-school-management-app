-- Run promotion for all grades in one action and return aggregated summary.

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
  if public.current_role() <> 'admin' then
    raise exception 'Only admin can run promotion';
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

grant execute on function public.run_promotion_for_all_grades_with_summary(uuid, text) to authenticated;
