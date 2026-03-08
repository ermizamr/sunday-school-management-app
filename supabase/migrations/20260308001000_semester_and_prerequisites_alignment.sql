-- Align academic lifecycle with two-semester rules and hard prerequisite enforcement

-- 1) Ensure status supports archived (idempotent)
do $$
begin
  begin
    alter type public.academic_year_status add value if not exists 'archived';
  exception
    when duplicate_object then null;
  end;
end $$;

-- 2) Subject prerequisites (course-level gating)
create table if not exists public.subject_prerequisites (
  subject_id uuid not null references public.subjects(id) on delete cascade,
  prerequisite_subject_id uuid not null references public.subjects(id) on delete restrict,
  minimum_score numeric,
  created_at timestamptz not null default now(),
  primary key (subject_id, prerequisite_subject_id),
  constraint subject_prerequisites_no_self check (subject_id <> prerequisite_subject_id)
);

create index if not exists subject_prerequisites_subject_idx
  on public.subject_prerequisites(subject_id);

create index if not exists subject_prerequisites_prereq_idx
  on public.subject_prerequisites(prerequisite_subject_id);

-- 3) Semester-aware averages for promotion decisions
create or replace function public.compute_overall_average_for_semester(
  p_student_id uuid,
  p_grade_id uuid,
  p_academic_year_id uuid,
  p_semester public.academic_year_period
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
          and (
            case
              when p_semester = 'semester1' then a.assessment_date <= (
                select ay.start_date + ((ay.end_date - ay.start_date) / 2)
                from public.academic_years ay
                where ay.id = p_academic_year_id
              )
              when p_semester = 'semester2' then a.assessment_date > (
                select ay.start_date + ((ay.end_date - ay.start_date) / 2)
                from public.academic_years ay
                where ay.id = p_academic_year_id
              )
              else false
            end
          )
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
  from per_subject;
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

  return (sem1 + sem2) / 2.0;
end;
$$;

-- 4) Promotion status must be based on average of semester averages
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
  any_prereq_below_min boolean;
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

-- 5) Course enrollment/assessment gating by prerequisites
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
    and coalesce(
      public.compute_subject_average(p_student_id, sp.prerequisite_subject_id, p_academic_year_id),
      -1
    ) < coalesce(sp.minimum_score, prereq.passing_grade);

  if unmet_count > 0 then
    raise exception 'Student cannot take this subject before passing prerequisite subjects';
  end if;
end;
$$;

create or replace function public.enforce_assessment_prerequisites()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_subject_id uuid;
  v_academic_year_id uuid;
begin
  select a.subject_id, a.academic_year_id
    into v_subject_id, v_academic_year_id
  from public.assessments a
  where a.id = new.assessment_id;

  if v_subject_id is null or v_academic_year_id is null then
    return new;
  end if;

  perform public.assert_subject_prerequisites(new.student_id, v_subject_id, v_academic_year_id);
  return new;
end;
$$;

drop trigger if exists assessment_scores_enforce_prerequisites on public.assessment_scores;
create trigger assessment_scores_enforce_prerequisites
before insert or update on public.assessment_scores
for each row
execute function public.enforce_assessment_prerequisites();

-- 6) Explicit period control (semester flow does not block by averages)
create or replace function public.set_academic_year_period(
  p_academic_year_id uuid,
  p_period public.academic_year_period
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.current_role() <> 'admin' then
    raise exception 'Only admin can set academic year period';
  end if;

  update public.academic_years
  set current_period = p_period,
      updated_at = now()
  where id = p_academic_year_id;
end;
$$;

-- 7) Ensure archived action updates status as well
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
  set status = 'archived',
      archived_at = now(),
      updated_at = now()
  where id = p_academic_year_id;
end;
$$;

grant execute on function public.compute_overall_average_for_semester(uuid, uuid, uuid, public.academic_year_period) to authenticated;
grant execute on function public.compute_year_average_from_semesters(uuid, uuid, uuid) to authenticated;
grant execute on function public.set_academic_year_period(uuid, public.academic_year_period) to authenticated;
grant execute on function public.assert_subject_prerequisites(uuid, uuid, uuid) to authenticated;
