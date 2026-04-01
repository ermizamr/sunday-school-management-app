-- Promote eligible last-grade students to graduated status.

-- 1) Extend account status enum safely.
do $$
begin
  begin
    alter type public.account_status add value if not exists 'graduated';
  exception
    when duplicate_object then null;
  end;
end $$;

-- 2) Mark eligible students as graduated when there is no next grade.
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
				'grade_category', category,
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

-- 3) Preserve graduated status on new-year rollover.
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
begin
	if public.current_role() <> 'admin' then
		raise exception 'Only admin can start academic year';
	end if;

	select id into previous_year_id
	from public.academic_years
	where status = 'active'
	order by start_date desc
	limit 1;

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
