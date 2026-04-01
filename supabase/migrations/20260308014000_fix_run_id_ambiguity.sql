-- Fix ambiguous run_id references during promotion execution.
-- 1) Qualify promotion_results.run_id in SELECT policy.
-- 2) Rename run_promotion local variable run_id -> v_run_id.

drop policy if exists promotion_results_read on public.promotion_results;
create policy promotion_results_read
on public.promotion_results
for select
using (
	public.current_role() = 'admin'
	or (
		public.is_active_account()
		and student_id = auth.uid()
	)
	or (
		public.current_role() = 'servant'
		and public.is_active_account()
		and exists (
			select 1
			from public.promotion_runs r
			where r.id = public.promotion_results.run_id
				and r.grade_id = public.current_grade_id()
		)
	)
);

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
  v_run_id uuid;
  s record;
  status public.promotion_status;
  overall_avg numeric;
  attendance_pct numeric;
  next_grade uuid;
  criteria public.promotion_criteria_sets%rowtype;
  attendance_shortfalls jsonb;
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
  returning id into v_run_id;

  for s in
    select p.id
    from public.profiles p
    where p.role = 'student'
      and p.grade_id = p_grade_id
  loop
    status := public.determine_promotion_status(s.id, p_grade_id, p_academic_year_id);
    attendance_pct := public.compute_attendance_percent(s.id, p_academic_year_id);

    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'subject_id', sf.subject_id,
          'required_days', sf.required_days,
          'attended_days', sf.attended_days
        )
      ),
      '[]'::jsonb
    )
    into attendance_shortfalls
    from public.get_subject_attendance_shortfalls(
      s.id,
      criteria.id,
      p_academic_year_id
    ) sf;

    if jsonb_array_length(attendance_shortfalls) > 0 then
      overall_avg := null;
      next_grade := null;
      status := 'at_risk';
    else
      overall_avg := public.compute_year_average_from_semesters(s.id, p_grade_id, p_academic_year_id);
      next_grade := case when status = 'eligible' then public.get_next_grade_id(p_grade_id) else null end;
    end if;

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
      v_run_id,
      s.id,
      status,
      overall_avg,
      attendance_pct,
      next_grade,
      jsonb_build_object(
        'grade_id', p_grade_id,
        'academic_year_id', p_academic_year_id,
        'attendance_shortfalls', attendance_shortfalls,
        'notification', case
          when jsonb_array_length(attendance_shortfalls) > 0
            then 'Minimum attendance days not met for one or more subjects. Please contact servants.'
          else null
        end,
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

  return v_run_id;
end;
$$;
