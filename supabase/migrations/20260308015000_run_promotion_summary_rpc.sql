-- Add summary RPC for promotions so admin UI gets structured run output.

create or replace function public.run_promotion_with_summary(
  p_academic_year_id uuid,
  p_grade_id uuid,
  p_notes text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_run_id uuid;
  v_total int := 0;
  v_eligible int := 0;
  v_at_risk int := 0;
  v_not_eligible int := 0;
  v_graduated int := 0;
begin
  if public.current_role() <> 'admin' then
    raise exception 'Only admin can run promotion';
  end if;

  v_run_id := public.run_promotion(
    p_academic_year_id,
    p_grade_id,
    p_notes
  );

  select count(*)::int into v_total
  from public.promotion_results pr
  where pr.run_id = v_run_id;

  select count(*)::int into v_eligible
  from public.promotion_results pr
  where pr.run_id = v_run_id
    and pr.status = 'eligible';

  select count(*)::int into v_at_risk
  from public.promotion_results pr
  where pr.run_id = v_run_id
    and pr.status = 'at_risk';

  select count(*)::int into v_not_eligible
  from public.promotion_results pr
  where pr.run_id = v_run_id
    and pr.status = 'not_eligible';

  select count(*)::int into v_graduated
  from public.promotion_results pr
  where pr.run_id = v_run_id
    and coalesce((pr.details ->> 'graduated')::boolean, false) = true;

  return jsonb_build_object(
    'run_id', v_run_id,
    'total_students', v_total,
    'eligible', v_eligible,
    'at_risk', v_at_risk,
    'not_eligible', v_not_eligible,
    'graduated', v_graduated
  );
end;
$$;
grant execute on function public.run_promotion_with_summary(uuid, uuid, text) to authenticated;
