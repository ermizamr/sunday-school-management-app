-- Enforce account_status globally via RLS
-- Goal: when admin deactivates a servant/student, they lose access across the app.

-- Subjects read should require an active account for non-admins

drop policy if exists subjects_read_grade on public.subjects;
create policy subjects_read_grade
on public.subjects
for select
using (
	public.current_role() = 'admin'
	or (
		public.is_active_account()
		and public.current_grade_id() is not null
		and grade_id = public.current_grade_id()
	)
);
-- Allow servants to create subjects for their own grade (active accounts only)

drop policy if exists subjects_insert_grade_servant on public.subjects;
create policy subjects_insert_grade_servant
on public.subjects
for insert
with check (
	public.current_role() = 'servant'
	and public.is_active_account()
	and public.current_grade_id() is not null
	and grade_id = public.current_grade_id()
);
-- Assessments

drop policy if exists assessments_read_grade on public.assessments;
create policy assessments_read_grade
on public.assessments
for select
using (
	public.current_role() = 'admin'
	or (
		public.is_active_account()
		and public.current_grade_id() is not null
		and grade_id = public.current_grade_id()
	)
);
drop policy if exists assessments_write_grade_servant on public.assessments;
create policy assessments_write_grade_servant
on public.assessments
for insert
with check (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'servant'
		and public.is_active_account()
		and public.current_grade_id() is not null
		and grade_id = public.current_grade_id()
		and created_by = auth.uid()
	)
);
drop policy if exists assessments_update_grade_servant on public.assessments;
create policy assessments_update_grade_servant
on public.assessments
for update
using (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'servant'
		and public.is_active_account()
		and public.current_grade_id() is not null
		and grade_id = public.current_grade_id()
	)
)
with check (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'servant'
		and public.is_active_account()
		and public.current_grade_id() is not null
		and grade_id = public.current_grade_id()
	)
);
drop policy if exists assessments_delete_grade_servant on public.assessments;
create policy assessments_delete_grade_servant
on public.assessments
for delete
using (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'servant'
		and public.is_active_account()
		and public.current_grade_id() is not null
		and grade_id = public.current_grade_id()
	)
);
-- Assessment scores

drop policy if exists assessment_scores_read on public.assessment_scores;
create policy assessment_scores_read
on public.assessment_scores
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
			from public.assessments a
			where a.id = assessment_id
				and a.grade_id = public.current_grade_id()
		)
	)
);
drop policy if exists assessment_scores_write_servant on public.assessment_scores;
create policy assessment_scores_write_servant
on public.assessment_scores
for insert
with check (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'servant'
		and public.is_active_account()
		and exists (
			select 1
			from public.assessments a
			where a.id = assessment_id
				and a.grade_id = public.current_grade_id()
		)
	)
);
drop policy if exists assessment_scores_update_servant on public.assessment_scores;
create policy assessment_scores_update_servant
on public.assessment_scores
for update
using (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'servant'
		and public.is_active_account()
		and exists (
			select 1
			from public.assessments a
			where a.id = assessment_id
				and a.grade_id = public.current_grade_id()
		)
	)
)
with check (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'servant'
		and public.is_active_account()
		and exists (
			select 1
			from public.assessments a
			where a.id = assessment_id
				and a.grade_id = public.current_grade_id()
		)
	)
);
drop policy if exists assessment_scores_delete_servant on public.assessment_scores;
create policy assessment_scores_delete_servant
on public.assessment_scores
for delete
using (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'servant'
		and public.is_active_account()
		and exists (
			select 1
			from public.assessments a
			where a.id = assessment_id
				and a.grade_id = public.current_grade_id()
		)
	)
);
-- Attendance sessions

drop policy if exists attendance_sessions_read_grade on public.attendance_sessions;
create policy attendance_sessions_read_grade
on public.attendance_sessions
for select
using (
	public.current_role() = 'admin'
	or (
		public.is_active_account()
		and public.current_grade_id() is not null
		and grade_id = public.current_grade_id()
	)
);
drop policy if exists attendance_sessions_write_servant on public.attendance_sessions;
create policy attendance_sessions_write_servant
on public.attendance_sessions
for insert
with check (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'servant'
		and public.is_active_account()
		and grade_id = public.current_grade_id()
		and created_by = auth.uid()
	)
);
drop policy if exists attendance_sessions_update_servant on public.attendance_sessions;
create policy attendance_sessions_update_servant
on public.attendance_sessions
for update
using (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'servant'
		and public.is_active_account()
		and grade_id = public.current_grade_id()
	)
)
with check (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'servant'
		and public.is_active_account()
		and grade_id = public.current_grade_id()
	)
);
drop policy if exists attendance_sessions_delete_servant on public.attendance_sessions;
create policy attendance_sessions_delete_servant
on public.attendance_sessions
for delete
using (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'servant'
		and public.is_active_account()
		and grade_id = public.current_grade_id()
	)
);
-- Attendance records

drop policy if exists attendance_records_read on public.attendance_records;
create policy attendance_records_read
on public.attendance_records
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
			from public.attendance_sessions s
			where s.id = session_id
				and s.grade_id = public.current_grade_id()
		)
	)
);
drop policy if exists attendance_records_update_servant on public.attendance_records;
create policy attendance_records_update_servant
on public.attendance_records
for update
using (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'servant'
		and public.is_active_account()
		and exists (
			select 1
			from public.attendance_sessions s
			where s.id = session_id
				and s.grade_id = public.current_grade_id()
		)
	)
)
with check (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'servant'
		and public.is_active_account()
		and exists (
			select 1
			from public.attendance_sessions s
			where s.id = session_id
				and s.grade_id = public.current_grade_id()
		)
	)
);
drop policy if exists attendance_records_write_servant on public.attendance_records;
create policy attendance_records_write_servant
on public.attendance_records
for insert
with check (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'servant'
		and public.is_active_account()
		and exists (
			select 1
			from public.attendance_sessions s
			where s.id = session_id
				and s.grade_id = public.current_grade_id()
		)
	)
);
-- Announcements

drop policy if exists announcements_read_scope on public.announcements;
create policy announcements_read_scope
on public.announcements
for select
using (
	public.current_role() = 'admin'
	or (
		public.is_active_account()
		and (
			grade_id is null
			or (public.current_grade_id() is not null and grade_id = public.current_grade_id())
		)
	)
);
drop policy if exists announcements_write_servant_grade on public.announcements;
create policy announcements_write_servant_grade
on public.announcements
for insert
with check (
	public.current_role() = 'servant'
	and public.is_active_account()
	and grade_id is not null
	and grade_id = public.current_grade_id()
	and created_by = auth.uid()
);
drop policy if exists announcements_update_servant_grade on public.announcements;
create policy announcements_update_servant_grade
on public.announcements
for update
using (
	public.current_role() = 'servant'
	and public.is_active_account()
	and grade_id is not null
	and grade_id = public.current_grade_id()
)
with check (
	public.current_role() = 'servant'
	and public.is_active_account()
	and grade_id is not null
	and grade_id = public.current_grade_id()
);
drop policy if exists announcements_delete_servant_grade on public.announcements;
create policy announcements_delete_servant_grade
on public.announcements
for delete
using (
	public.current_role() = 'servant'
	and public.is_active_account()
	and grade_id is not null
	and grade_id = public.current_grade_id()
);
-- Questions

drop policy if exists questions_read on public.questions;
create policy questions_read
on public.questions
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
		and public.is_active_account()
		and grade_id = public.current_grade_id()
	)
);
drop policy if exists questions_update_servant on public.questions;
create policy questions_update_servant
on public.questions
for update
using (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'servant'
		and public.is_active_account()
		and grade_id = public.current_grade_id()
	)
)
with check (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'servant'
		and public.is_active_account()
		and grade_id = public.current_grade_id()
	)
);
-- Complaints

drop policy if exists complaints_read on public.complaints;
create policy complaints_read
on public.complaints
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
		and public.is_active_account()
		and grade_id = public.current_grade_id()
	)
);
drop policy if exists complaints_update_servant on public.complaints;
create policy complaints_update_servant
on public.complaints
for update
using (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'servant'
		and public.is_active_account()
		and grade_id = public.current_grade_id()
	)
)
with check (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'servant'
		and public.is_active_account()
		and grade_id = public.current_grade_id()
	)
);
-- Complaints delete (matches UI)

drop policy if exists complaints_delete_servant on public.complaints;
create policy complaints_delete_servant
on public.complaints
for delete
using (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'servant'
		and public.is_active_account()
		and grade_id = public.current_grade_id()
	)
);
-- Profiles: allow servants to read the student roster for their grade (active servants only)

drop policy if exists profiles_select_servant_grade_students on public.profiles;
create policy profiles_select_servant_grade_students
on public.profiles
for select
using (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'servant'
		and public.is_active_account()
		and role = 'student'
		and grade_id = public.current_grade_id()
	)
);
-- Promotion runs/results

drop policy if exists promotion_runs_read_grade on public.promotion_runs;
create policy promotion_runs_read_grade
on public.promotion_runs
for select
using (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'servant'
		and public.is_active_account()
		and grade_id = public.current_grade_id()
	)
);
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
			where r.id = run_id
				and r.grade_id = public.current_grade_id()
		)
	)
);
