-- Store grade category classification in promotion_results.details
-- Uses promotion_criteria_sets category bounds.

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
	category text;
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
		overall_avg := public.compute_overall_average(s.id, p_grade_id, p_academic_year_id);
		attendance_pct := public.compute_attendance_percent(s.id, p_academic_year_id);
		next_grade := case when status = 'eligible' then public.get_next_grade_id(p_grade_id) else null end;

		category := case
			when overall_avg is null then null
			when overall_avg between criteria.excellent_lower and criteria.excellent_upper then 'excellent'
			when overall_avg between criteria.very_good_lower and criteria.very_good_upper then 'very_good'
			when overall_avg between criteria.good_lower and criteria.good_upper then 'good'
			when overall_avg between criteria.enough_lower and criteria.enough_upper then 'enough'
			when overall_avg < criteria.enough_lower then 'critical'
			else 'critical'
		end;

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
				'grade_category', category
			)
		)
		on conflict (run_id, student_id) do update
			set status = excluded.status,
				overall_average = excluded.overall_average,
				attendance_percent = excluded.attendance_percent,
				recommended_next_grade_id = excluded.recommended_next_grade_id,
				computed_at = now(),
				details = excluded.details;
	end loop;

	return run_id;
end;
$$;
