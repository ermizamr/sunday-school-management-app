-- Servant-grade DB-backed grading RPCs
--
-- Enables servant screens (Grades + Analytics) to use the same DB logic as Promotions
-- without re-implementing calculations client-side.

create or replace function public._assert_can_view_grade(p_grade_id uuid)
returns void
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  -- Admin can view any grade.
  if public.current_role() = 'admin' then
    return;
  end if;

  -- Non-admin accounts must be active.
  if not public.is_active_account() then
    raise exception 'Inactive account';
  end if;

  -- Servant can only view their own grade.
  if public.current_role() = 'servant' then
    if public.current_grade_id() is null or public.current_grade_id() <> p_grade_id then
      raise exception 'Not authorized';
    end if;
    return;
  end if;

  raise exception 'Not authorized';
end;
$$;
create or replace function public.get_grade_grading_snapshots(
  p_grade_id uuid,
  p_academic_year_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  criteria public.promotion_criteria_sets%rowtype;
begin
  perform public._assert_can_view_grade(p_grade_id);

  select * into criteria
  from public.promotion_criteria_sets pcs
  where pcs.academic_year_id = p_academic_year_id
    and pcs.grade_id = p_grade_id;

  if not found then
    raise exception 'Promotion criteria not configured for year % grade %', p_academic_year_id, p_grade_id;
  end if;

  return (
    with students as (
      select p.id, p.name
      from public.profiles p
      where p.role = 'student'
        and p.grade_id = p_grade_id
        and p.account_status = 'active'
    ),
    computed as (
      select
        s.id as student_id,
        s.name as student_name,
        public.compute_overall_average(s.id, p_grade_id, p_academic_year_id) as overall_avg,
        public.compute_attendance_percent(s.id, p_academic_year_id) as attendance_pct,
        public.determine_promotion_status(s.id, p_grade_id, p_academic_year_id) as promo_status
      from students s
    )
    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'student_id', c.student_id,
          'overall_average', c.overall_avg,
          'attendance_percent', c.attendance_pct,
          'status', c.promo_status,
          'grade_category',
            case
              when c.overall_avg is null then null
              when c.overall_avg >= criteria.excellent_lower and c.overall_avg <= criteria.excellent_upper then 'excellent'
              when c.overall_avg >= criteria.very_good_lower and c.overall_avg <= criteria.very_good_upper then 'very_good'
              when c.overall_avg >= criteria.good_lower and c.overall_avg <= criteria.good_upper then 'good'
              when c.overall_avg >= criteria.enough_lower and c.overall_avg <= criteria.enough_upper then 'enough'
              when c.overall_avg < criteria.enough_lower then 'critical'
              else 'critical'
            end
        )
        order by c.student_name
      ),
      '[]'::jsonb
    )
    from computed c
  );
end;
$$;
create or replace function public.get_grade_subject_averages(
  p_grade_id uuid,
  p_academic_year_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  perform public._assert_can_view_grade(p_grade_id);

  return (
    with students as (
      select p.id, p.name
      from public.profiles p
      where p.role = 'student'
        and p.grade_id = p_grade_id
        and p.account_status = 'active'
    ),
    subs as (
      select s.id, s.name
      from public.subjects s
      where s.grade_id = p_grade_id
        and s.active = true
    )
    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'student_id', st.id,
          'subject_id', sub.id,
          'subject_average', public.compute_subject_average(st.id, sub.id, p_academic_year_id)
        )
        order by sub.name, st.name
      ),
      '[]'::jsonb
    )
    from students st
    cross join subs sub
  );
end;
$$;
grant execute on function public._assert_can_view_grade(uuid) to authenticated;
grant execute on function public.get_grade_grading_snapshots(uuid, uuid) to authenticated;
grant execute on function public.get_grade_subject_averages(uuid, uuid) to authenticated;
