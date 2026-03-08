-- Feedback RLS policies

-- Forms

drop policy if exists feedback_forms_read on public.feedback_forms;
create policy feedback_forms_read
on public.feedback_forms
for select
using (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'student'
		and public.is_active_account()
		and grade_id = public.current_grade_id()
	)
	or (public.current_role() = 'servant' and grade_id = public.current_grade_id())
);
drop policy if exists feedback_forms_write_servant on public.feedback_forms;
create policy feedback_forms_write_servant
on public.feedback_forms
for insert
with check (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'servant'
		and public.is_active_account()
		and created_by = auth.uid()
		and grade_id = public.current_grade_id()
		and academic_year_id = public.active_academic_year_id()
	)
);
drop policy if exists feedback_forms_update_servant on public.feedback_forms;
create policy feedback_forms_update_servant
on public.feedback_forms
for update
using (
	public.current_role() = 'admin'
	or (public.current_role() = 'servant' and grade_id = public.current_grade_id())
)
with check (
	public.current_role() = 'admin'
	or (public.current_role() = 'servant' and grade_id = public.current_grade_id())
);
drop policy if exists feedback_forms_delete_servant on public.feedback_forms;
create policy feedback_forms_delete_servant
on public.feedback_forms
for delete
using (
	public.current_role() = 'admin'
	or (public.current_role() = 'servant' and grade_id = public.current_grade_id())
);
-- Questions

drop policy if exists feedback_questions_read on public.feedback_questions;
create policy feedback_questions_read
on public.feedback_questions
for select
using (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'student'
		and public.is_active_account()
		and exists (
			select 1 from public.feedback_forms f
			where f.id = form_id and f.grade_id = public.current_grade_id()
		)
	)
	or (
		public.current_role() = 'servant'
		and exists (
			select 1 from public.feedback_forms f
			where f.id = form_id and f.grade_id = public.current_grade_id()
		)
	)
);
drop policy if exists feedback_questions_insert_servant on public.feedback_questions;
create policy feedback_questions_insert_servant
on public.feedback_questions
for insert
with check (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'servant'
		and exists (
			select 1 from public.feedback_forms f
			where f.id = form_id and f.grade_id = public.current_grade_id()
		)
	)
);
drop policy if exists feedback_questions_update_servant on public.feedback_questions;
create policy feedback_questions_update_servant
on public.feedback_questions
for update
using (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'servant'
		and exists (
			select 1 from public.feedback_forms f
			where f.id = form_id and f.grade_id = public.current_grade_id()
		)
	)
)
with check (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'servant'
		and exists (
			select 1 from public.feedback_forms f
			where f.id = form_id and f.grade_id = public.current_grade_id()
		)
	)
);
drop policy if exists feedback_questions_delete_servant on public.feedback_questions;
create policy feedback_questions_delete_servant
on public.feedback_questions
for delete
using (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'servant'
		and exists (
			select 1 from public.feedback_forms f
			where f.id = form_id and f.grade_id = public.current_grade_id()
		)
	)
);
-- Submissions

drop policy if exists feedback_submissions_read on public.feedback_submissions;
create policy feedback_submissions_read
on public.feedback_submissions
for select
using (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'student'
		and public.is_active_account()
		and student_id = auth.uid()
	)
	or (
		public.current_role() = 'servant'
		and exists (
			select 1 from public.feedback_forms f
			where f.id = form_id and f.grade_id = public.current_grade_id()
		)
	)
);
drop policy if exists feedback_submissions_insert_student on public.feedback_submissions;
create policy feedback_submissions_insert_student
on public.feedback_submissions
for insert
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
drop policy if exists feedback_submissions_delete_servant on public.feedback_submissions;
create policy feedback_submissions_delete_servant
on public.feedback_submissions
for delete
using (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'servant'
		and exists (
			select 1 from public.feedback_forms f
			where f.id = form_id and f.grade_id = public.current_grade_id()
		)
	)
);
