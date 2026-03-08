-- Academic year lifecycle + promotion RPC functions

create or replace function public.compute_subject_average(
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
	from rows;
$$;
create or replace function public.compute_overall_average(
	p_student_id uuid,
	p_grade_id uuid,
	p_academic_year_id uuid
)
returns numeric
language sql
stable
security definer
set search_path = public
as $$
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
	from per_subject;
$$;
create or replace function public.compute_attendance_percent(
	p_student_id uuid,
	p_academic_year_id uuid
)
returns numeric
language sql
stable
security definer
set search_path = public
as $$
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
	from rows;
$$;
create or replace function public.get_next_grade_id(p_grade_id uuid)
returns uuid
language sql
stable
security definer
set search_path = public
as $$
	select g2.id
	from public.grades g1
	join public.grades g2 on g2.sort_order = g1.sort_order + 1
	where g1.id = p_grade_id
	limit 1;
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
	overall_avg numeric;
	attendance_pct numeric;
	any_missing_required boolean;
	any_below_min boolean;
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
			) < coalesce(pcs.minimum_grade, sub.passing_grade)
	) into any_missing_required;

	select exists (
		select 1
		from public.subjects sub
		where sub.grade_id = p_grade_id
			and sub.active = true
			and coalesce(
				public.compute_subject_average(p_student_id, sub.id, p_academic_year_id),
				-1
			) < criteria.minimum_subject_grade
	) into any_below_min;

	if attendance_pct < criteria.minimum_attendance then
		return 'at_risk';
	end if;

	if any_missing_required or any_below_min then
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
begin
	if public.current_role() <> 'admin' then
		raise exception 'Only admin can run promotion';
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
				'academic_year_id', p_academic_year_id
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
create or replace function public.end_academic_year(p_academic_year_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
	if public.current_role() <> 'admin' then
		raise exception 'Only admin can end academic year';
	end if;

	update public.academic_years
	set status = 'ended',
			current_period = 'break',
			ended_at = now()
	where id = p_academic_year_id;
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

	-- At start of new year:
	-- - Eligible students are promoted (if next grade exists) and remain active.
	-- - All others become inactive_pending_admin until admin decides placement.
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
create or replace function public.archive_academic_year(p_academic_year_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
	if public.current_role() <> 'admin' then
		raise exception 'Only admin can archive academic year';
	end if;

	-- Copy to archive tables
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

	-- Delete originals (child tables first)
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
	set archived_at = now(),
			updated_at = now()
	where id = p_academic_year_id;
end;
$$;
