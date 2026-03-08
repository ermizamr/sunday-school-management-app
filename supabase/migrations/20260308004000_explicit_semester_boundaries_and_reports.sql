-- Explicit semester boundary management + student semester report RPCs

alter table public.academic_years
  add column if not exists semester1_end_date date,
  add column if not exists semester2_start_date date;

alter table public.academic_years
  drop constraint if exists academic_years_semester_dates_chk;

alter table public.academic_years
  add constraint academic_years_semester_dates_chk
  check (
    (
      semester1_end_date is null
      and semester2_start_date is null
    )
    or (
      semester1_end_date is not null
      and semester2_start_date is not null
      and semester1_end_date >= start_date
      and semester1_end_date <= end_date
      and semester2_start_date >= start_date
      and semester2_start_date <= end_date
      and semester2_start_date >= semester1_end_date
    )
  );

create or replace function public.end_first_semester(
  p_academic_year_id uuid,
  p_semester1_end_date date
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.current_role() <> 'admin' then
    raise exception 'Only admin can end first semester';
  end if;

  update public.academic_years
  set semester1_end_date = p_semester1_end_date,
      current_period = 'break',
      updated_at = now()
  where id = p_academic_year_id
    and status = 'active';
end;
$$;

create or replace function public.start_second_semester(
  p_academic_year_id uuid,
  p_semester2_start_date date
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sem1_end date;
begin
  if public.current_role() <> 'admin' then
    raise exception 'Only admin can start second semester';
  end if;

  select semester1_end_date
    into v_sem1_end
  from public.academic_years
  where id = p_academic_year_id
    and status = 'active';

  if v_sem1_end is null then
    raise exception 'End first semester before starting second semester';
  end if;

  if p_semester2_start_date < v_sem1_end then
    raise exception 'Semester 2 start date cannot be before Semester 1 end date';
  end if;

  update public.academic_years
  set semester2_start_date = p_semester2_start_date,
      current_period = 'semester2',
      updated_at = now()
  where id = p_academic_year_id
    and status = 'active';
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
  v_start date;
  v_end date;
  v_sem1_end date;
  v_sem2_start date;
  result numeric;
begin
  select ay.start_date, ay.end_date, ay.semester1_end_date, ay.semester2_start_date
  into v_start, v_end, v_sem1_end, v_sem2_start
  from public.academic_years ay
  where ay.id = p_academic_year_id;

  if v_start is null then
    return null;
  end if;

  if p_semester = 'semester1' then
    v_end := coalesce(v_sem1_end, v_start + ((v_end - v_start) / 2));
  elsif p_semester = 'semester2' then
    v_start := coalesce(v_sem2_start, (v_start + ((v_end - v_start) / 2) + 1));
  else
    return null;
  end if;

  with per_subject as (
    select
      sub.id as subject_id,
      coalesce(nullif(sub.weight, 0), 1) as subject_weight,
      (
        select
          case
            when coalesce(sum(a.weight), 0) = 0 then null
            else sum(((s.score / a.max_score) * 100.0) * a.weight) / sum(a.weight)
          end
        from public.assessment_scores s
        join public.assessments a on a.id = s.assessment_id
        where s.student_id = p_student_id
          and a.subject_id = sub.id
          and a.academic_year_id = p_academic_year_id
          and a.max_score > 0
          and a.weight > 0
          and a.assessment_date >= v_start
          and a.assessment_date <= v_end
      ) as subject_avg
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
  into result
  from per_subject;

  return result;
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

  v_attendance := public.compute_attendance_percent(auth.uid(), p_academic_year_id);

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
            'average', public.compute_subject_average(auth.uid(), sub.id, p_academic_year_id)
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

grant execute on function public.end_first_semester(uuid, date) to authenticated;
grant execute on function public.start_second_semester(uuid, date) to authenticated;
grant execute on function public.get_my_semester_report(uuid, uuid, public.academic_year_period) to authenticated;
grant execute on function public.get_my_academic_assessment(uuid, uuid) to authenticated;
