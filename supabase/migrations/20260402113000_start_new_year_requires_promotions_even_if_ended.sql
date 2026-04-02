-- Enforce strict academic-year rollover:
-- 1) End academic year (separate RPC)
-- 2) Run promotions for ALL grades for the ended year
-- 3) Start a new academic year (this function)

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
  missing_grades text;
begin
  perform public._assert_admin('Only admin can start academic year');

  if exists (
    select 1
    from public.academic_years
    where status = 'active'
  ) then
    raise exception
      'Cannot start new academic year while another year is active. End the current academic year first.';
  end if;

  select id
  into previous_year_id
  from public.academic_years
  where status = 'ended'
  order by end_date desc nulls last, start_date desc
  limit 1;

  if previous_year_id is not null then
    select string_agg(g.name, ', ' order by g.sort_order, g.name)
    into missing_grades
    from public.grades g
    where not exists (
      select 1
      from public.promotion_runs pr
      where pr.academic_year_id = previous_year_id
        and pr.grade_id = g.id
    );

    if missing_grades is not null then
      raise exception
        'Cannot start new academic year. Run promotion for these grades first: %',
        missing_grades;
    end if;
  end if;

  insert into public.academic_years (
    name,
    start_date,
    end_date,
    status,
    current_period
  )
  values (
    p_name,
    p_start_date,
    p_end_date,
    'active',
    'semester1'
  )
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