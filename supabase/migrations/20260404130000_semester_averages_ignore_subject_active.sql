-- Semester offerings support
--
-- When subjects are toggled active/inactive across semesters, historical semester/year
-- averages must remain stable. These helpers should not filter by subjects.active.

create or replace function public.compute_overall_average(
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
  result numeric;
begin
  perform public._assert_can_view_student(p_student_id);

  with per_subject as (
    select
      sub.id as subject_id,
      coalesce(nullif(sub.weight, 0), 1) as subject_weight,
      public.compute_subject_average(p_student_id, sub.id, p_academic_year_id) as subject_avg
    from public.subjects sub
    where sub.grade_id = p_grade_id
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

create or replace function public.get_my_subject_averages(
  p_grade_id uuid,
  p_academic_year_id uuid
)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'subject_id', sub.id,
        'subject_average', public.compute_subject_average(auth.uid(), sub.id, p_academic_year_id)
      )
      order by sub.name
    ),
    '[]'::jsonb
  )
  from public.subjects sub
  where sub.grade_id = p_grade_id;
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
  perform public._assert_can_view_student(p_student_id);

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
    )
  );
end;
$$;
