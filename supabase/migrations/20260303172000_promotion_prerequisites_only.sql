-- Promotion logic update:
-- Only prerequisite (required) subjects are enforced individually.
-- Non-prerequisite subjects only affect the overall average.

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
