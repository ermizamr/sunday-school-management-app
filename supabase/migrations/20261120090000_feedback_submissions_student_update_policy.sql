-- Allow students to update their own feedback submissions for active feedback forms in their grade and academic year.
drop policy if exists feedback_submissions_update_student on public.feedback_submissions;
create policy feedback_submissions_update_student
on public.feedback_submissions
for update
using (
  public.current_role() = 'student'
  and public.is_active_account()
  and student_id = auth.uid()
)
with check (
  public.current_role() = 'student'
  and public.is_active_account()
  and student_id = auth.uid()
  and exists (
    select 1
    from public.feedback_forms f
    where f.id = form_id
    and f.grade_id = public.current_grade_id()
    and f.academic_year_id = public.active_academic_year_id()
  )
);

-- RPC helper for atomic submission / editing of feedback
create or replace function public.submit_feedback_response(
  p_form_id uuid,
  p_answers jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid;
  v_role text;
  v_submission_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  v_role := public.current_role();
  if v_role <> 'student' then
    raise exception 'Only students can submit feedback';
  end if;

  if not public.is_active_account() then
    raise exception 'Account is not active';
  end if;

  if not exists (
    select 1 from public.feedback_forms f
    where f.id = p_form_id
      and f.grade_id = public.current_grade_id()
      and f.academic_year_id = public.active_academic_year_id()
      and f.start_date <= current_date
      and f.end_date >= current_date
  ) then
    raise exception 'Feedback form is not active or not in your grade';
  end if;

  insert into public.feedback_submissions (form_id, student_id, answers, submitted_at)
  values (p_form_id, v_user_id, p_answers, now())
  on conflict (form_id, student_id)
  do update set
    answers = excluded.answers,
    submitted_at = now()
  returning id into v_submission_id;

  return jsonb_build_object('success', true, 'id', v_submission_id);
end;
$$;
