-- Refinements:
-- 1) Semester reports use semester-specific subject + attendance calculations.
-- 2) Promotion category uses year-average-from-semesters (consistent with promotion decision basis).
-- 3) Prerequisite scope uses transcript history (any academic year), not only current year.
-- 4) Prerequisite failures DO NOT block grade promotion; they only gate course access.
-- 5) Numeric outputs are rounded to 2 decimals.

create or replace function public.get_semester_date_bounds(
  p_academic_year_id uuid,
  p_semester public.academic_year_period
)
returns table (from_date date, to_date date)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_start date;
  v_end date;
  v_sem1_end date;
  v_sem2_start date;
  v_midpoint date;
begin
  select ay.start_date, ay.end_date, ay.semester1_end_date, ay.semester2_start_date
  into v_start, v_end, v_sem1_end, v_sem2_start
  from public.academic_years ay
  where ay.id = p_academic_year_id;

  if v_start is null or v_end is null then
    return;
  end if;

  v_midpoint := v_start + ((v_end - v_start) / 2);

  if p_semester = 'semester1' then
    from_date := v_start;
    to_date := coalesce(v_sem1_end, v_midpoint);
    return next;
    return;
  end if;

  if p_semester = 'semester2' then
    from_date := coalesce(v_sem2_start, (v_midpoint + 1));
    to_date := v_end;
    return next;
    return;
  end if;

  return;
end;
$$;

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

-- Prerequisite scope policy: transcript-history based (any academic year).
create or replace function public.has_passed_prerequisite_subject(
  p_student_id uuid,
  p_prerequisite_subject_id uuid,
  p_min_score numeric
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
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
  );
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

-- Promotion policy update: prerequisites do not block grade promotion anymore.
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

  if attendance_pct < criteria.minimum_attendance then
    return 'at_risk';
  end if;

  return 'eligible';
end;
$$;

-- Keep promotion output aligned with semester-year average.
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
		overall_avg := public.compute_year_average_from_semesters(s.id, p_grade_id, p_academic_year_id);
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

create or replace function public.get_my_semester_report(
  p_academic_year_id uuid,
  p_grade_id uuid,
  p_semester public.academic_year_period
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_overall numeric;
  v_attendance numeric;
begin
  perform public._assert_can_view_student(auth.uid());

  if p_semester not in ('semester1', 'semester2') then
    raise exception 'Semester report supports semester1 or semester2 only';
  end if;

  v_overall := public.compute_overall_average_for_semester(
    auth.uid(),
    p_grade_id,
    p_academic_year_id,
    p_semester
  );

  v_attendance := public.compute_attendance_percent_for_semester(auth.uid(), p_academic_year_id, p_semester);

  return jsonb_build_object(
    'semester', p_semester,
    'overall_average', v_overall,
    'attendance_percent', v_attendance,
    'subject_averages', (
      select coalesce(
        jsonb_agg(
          jsonb_build_object(
            'subject_id', sub.id,
            'subject_name', sub.name,
            'average', public.compute_subject_average_for_semester(auth.uid(), sub.id, p_academic_year_id, p_semester)
          )
          order by sub.name
        ),
        '[]'::jsonb
      )
      from public.subjects sub
      where sub.grade_id = p_grade_id
        and sub.active = true
    )
  );
end;
$$;

create or replace function public.get_my_academic_assessment(
  p_academic_year_id uuid,
  p_grade_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  sem1 numeric;
  sem2 numeric;
  yearly numeric;
begin
  perform public._assert_can_view_student(auth.uid());

  sem1 := public.compute_overall_average_for_semester(auth.uid(), p_grade_id, p_academic_year_id, 'semester1');
  sem2 := public.compute_overall_average_for_semester(auth.uid(), p_grade_id, p_academic_year_id, 'semester2');
  yearly := public.compute_year_average_from_semesters(auth.uid(), p_grade_id, p_academic_year_id);

  return jsonb_build_object(
    'semester1_average', sem1,
    'semester2_average', sem2,
    'year_average', yearly,
    'promotion_status', public.determine_promotion_status(auth.uid(), p_grade_id, p_academic_year_id)
  );
end;
$$;

grant execute on function public.get_semester_date_bounds(uuid, public.academic_year_period) to authenticated;
grant execute on function public.compute_subject_average_for_semester(uuid, uuid, uuid, public.academic_year_period) to authenticated;
grant execute on function public.compute_attendance_percent_for_semester(uuid, uuid, public.academic_year_period) to authenticated;
grant execute on function public.has_passed_prerequisite_subject(uuid, uuid, numeric) to authenticated;
