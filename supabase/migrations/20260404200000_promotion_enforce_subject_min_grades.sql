-- Promotions: enforce per-subject minimum grade requirements
--
-- The Promotions UI stores per-subject minimum grades in `promotion_criteria_subjects.minimum_grade`.
-- A regression in `determine_promotion_status` stopped checking these requirements.
-- This migration restores subject minimum-grade enforcement while keeping:
-- - overall year average policy (average of semester averages)
-- - overall attendance threshold
-- - per-subject minimum attendance days (at_risk)

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
  any_required_subject_below_min boolean;
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

  if yearly_avg is null then
    return 'not_eligible';
  end if;

  if yearly_avg < criteria.minimum_overall_average then
    return 'not_eligible';
  end if;

  select exists (
    select 1
    from public.get_subject_attendance_shortfalls(
      p_student_id,
      criteria.id,
      p_academic_year_id
    ) sf
  ) into has_shortfall;

  if has_shortfall then
    return 'at_risk';
  end if;

  if attendance_pct < criteria.minimum_attendance then
    return 'at_risk';
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
  ) into any_required_subject_below_min;

  if any_required_subject_below_min then
    return 'at_risk';
  end if;

  return 'eligible';
end;
$$;
