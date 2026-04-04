-- Data repair (reverse prior reactivation):
--
-- Re-apply the rollover status rules for the most recently ended academic year,
-- based on the latest promotion run per grade.
--
-- This is useful if students were temporarily reactivated but should be
-- `inactive_pending_admin` when they are not eligible.

do $$
declare
  v_previous_year_id uuid;
begin
  select id
    into v_previous_year_id
  from public.academic_years
  where status = 'ended'
  order by end_date desc nulls last, start_date desc
  limit 1;

  if v_previous_year_id is null then
    return;
  end if;

  with last_runs as (
    select distinct on (r.grade_id)
      r.grade_id,
      r.id as run_id
    from public.promotion_runs r
    where r.academic_year_id = v_previous_year_id
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
        then 'active'::public.account_status
      when lr.status = 'eligible' and lr.recommended_next_grade_id is null
        then 'graduated'::public.account_status
      else 'inactive_pending_admin'::public.account_status
    end,
    updated_at = now()
  from last_results lr
  where p.id = lr.student_id
    and p.role = 'student';
end;
$$;
