-- RLS helper functions and policies (grade isolation)

-- Helper functions
create or replace function public.current_role()
returns public.user_role
language sql
stable
security definer
set search_path = public
as $$
	select p.role from public.profiles p where p.id = auth.uid();
$$;
create or replace function public.current_grade_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
	select p.grade_id from public.profiles p where p.id = auth.uid();
$$;
create or replace function public.is_active_account()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
	select coalesce(p.account_status = 'active', false)
	from public.profiles p
	where p.id = auth.uid();
$$;
create or replace function public.active_academic_year_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
	select ay.id
	from public.academic_years ay
	where ay.status = 'active'
	order by ay.start_date desc
	limit 1;
$$;
-- Enable RLS
alter table public.profiles enable row level security;
alter table public.grades enable row level security;
alter table public.academic_years enable row level security;
alter table public.subjects enable row level security;
alter table public.assessments enable row level security;
alter table public.assessment_scores enable row level security;
alter table public.attendance_sessions enable row level security;
alter table public.attendance_records enable row level security;
alter table public.announcements enable row level security;
alter table public.questions enable row level security;
alter table public.complaints enable row level security;
alter table public.promotion_criteria_sets enable row level security;
alter table public.promotion_criteria_subjects enable row level security;
alter table public.promotion_runs enable row level security;
alter table public.promotion_results enable row level security;
-- Profiles
drop policy if exists profiles_select_self on public.profiles;
create policy profiles_select_self
on public.profiles
for select
using (id = auth.uid());
drop policy if exists profiles_admin_all on public.profiles;
create policy profiles_admin_all
on public.profiles
for all
using (public.current_role() = 'admin')
with check (public.current_role() = 'admin');
-- Grades / Academic years: read for all authenticated users; write only admin
drop policy if exists grades_read_all on public.grades;
create policy grades_read_all
on public.grades
for select
using (auth.role() = 'authenticated');
drop policy if exists grades_admin_write on public.grades;
create policy grades_admin_write
on public.grades
for all
using (public.current_role() = 'admin')
with check (public.current_role() = 'admin');
drop policy if exists academic_years_read_all on public.academic_years;
create policy academic_years_read_all
on public.academic_years
for select
using (auth.role() = 'authenticated');
drop policy if exists academic_years_admin_write on public.academic_years;
create policy academic_years_admin_write
on public.academic_years
for all
using (public.current_role() = 'admin')
with check (public.current_role() = 'admin');
-- Subjects
drop policy if exists subjects_read_grade on public.subjects;
create policy subjects_read_grade
on public.subjects
for select
using (
	public.current_role() = 'admin'
	or (public.current_grade_id() is not null and grade_id = public.current_grade_id())
);
drop policy if exists subjects_admin_write on public.subjects;
create policy subjects_admin_write
on public.subjects
for all
using (public.current_role() = 'admin')
with check (public.current_role() = 'admin');
-- Assessments
drop policy if exists assessments_read_grade on public.assessments;
create policy assessments_read_grade
on public.assessments
for select
using (
	public.current_role() = 'admin'
	or (public.current_grade_id() is not null and grade_id = public.current_grade_id())
);
drop policy if exists assessments_write_grade_servant on public.assessments;
create policy assessments_write_grade_servant
on public.assessments
for insert
with check (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'servant'
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
		and public.current_grade_id() is not null
		and grade_id = public.current_grade_id()
	)
)
with check (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'servant'
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
	or student_id = auth.uid()
	or (
		public.current_role() = 'servant'
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
	or (public.current_grade_id() is not null and grade_id = public.current_grade_id())
);
drop policy if exists attendance_sessions_write_servant on public.attendance_sessions;
create policy attendance_sessions_write_servant
on public.attendance_sessions
for insert
with check (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'servant'
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
		and grade_id = public.current_grade_id()
	)
)
with check (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'servant'
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
	or student_id = auth.uid()
	or (
		public.current_role() = 'servant'
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
		and exists (
			select 1
			from public.attendance_sessions s
			where s.id = session_id
				and s.grade_id = public.current_grade_id()
		)
	)
);
-- Announcements: global or grade-scoped
drop policy if exists announcements_read_scope on public.announcements;
create policy announcements_read_scope
on public.announcements
for select
using (
	public.current_role() = 'admin'
	or (
		public.current_role() <> 'student'
		or public.is_active_account()
	)
	and (
		grade_id is null
		or (public.current_grade_id() is not null and grade_id = public.current_grade_id())
	)
);
drop policy if exists announcements_write_admin on public.announcements;
create policy announcements_write_admin
on public.announcements
for all
using (public.current_role() = 'admin')
with check (public.current_role() = 'admin');
drop policy if exists announcements_write_servant_grade on public.announcements;
create policy announcements_write_servant_grade
on public.announcements
for insert
with check (
	public.current_role() = 'servant'
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
	and grade_id is not null
	and grade_id = public.current_grade_id()
)
with check (
	public.current_role() = 'servant'
	and grade_id is not null
	and grade_id = public.current_grade_id()
);
drop policy if exists announcements_delete_servant_grade on public.announcements;
create policy announcements_delete_servant_grade
on public.announcements
for delete
using (
	public.current_role() = 'servant'
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
	or (public.current_role() = 'servant' and grade_id = public.current_grade_id())
);
drop policy if exists questions_insert_student on public.questions;
create policy questions_insert_student
on public.questions
for insert
with check (
	public.current_role() = 'student'
	and public.is_active_account()
	and student_id = auth.uid()
	and grade_id = public.current_grade_id()
	and academic_year_id = public.active_academic_year_id()
);
drop policy if exists questions_update_servant on public.questions;
create policy questions_update_servant
on public.questions
for update
using (
	public.current_role() = 'admin'
	or (public.current_role() = 'servant' and grade_id = public.current_grade_id())
)
with check (
	public.current_role() = 'admin'
	or (public.current_role() = 'servant' and grade_id = public.current_grade_id())
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
	or (public.current_role() = 'servant' and grade_id = public.current_grade_id())
);
drop policy if exists complaints_insert_student on public.complaints;
create policy complaints_insert_student
on public.complaints
for insert
with check (
	public.current_role() = 'student'
	and public.is_active_account()
	and student_id = auth.uid()
	and grade_id = public.current_grade_id()
	and academic_year_id = public.active_academic_year_id()
);
drop policy if exists complaints_update_servant on public.complaints;
create policy complaints_update_servant
on public.complaints
for update
using (
	public.current_role() = 'admin'
	or (public.current_role() = 'servant' and grade_id = public.current_grade_id())
)
with check (
	public.current_role() = 'admin'
	or (public.current_role() = 'servant' and grade_id = public.current_grade_id())
);
-- Promotion criteria: admin only
drop policy if exists promotion_criteria_admin on public.promotion_criteria_sets;
create policy promotion_criteria_admin
on public.promotion_criteria_sets
for all
using (public.current_role() = 'admin')
with check (public.current_role() = 'admin');
drop policy if exists promotion_criteria_subjects_admin on public.promotion_criteria_subjects;
create policy promotion_criteria_subjects_admin
on public.promotion_criteria_subjects
for all
using (public.current_role() = 'admin')
with check (public.current_role() = 'admin');
-- Promotion runs/results
drop policy if exists promotion_runs_admin_write on public.promotion_runs;
create policy promotion_runs_admin_write
on public.promotion_runs
for all
using (public.current_role() = 'admin')
with check (public.current_role() = 'admin');
drop policy if exists promotion_runs_read_grade on public.promotion_runs;
create policy promotion_runs_read_grade
on public.promotion_runs
for select
using (
	public.current_role() = 'admin'
	or (public.current_role() = 'servant' and grade_id = public.current_grade_id())
);
drop policy if exists promotion_results_read on public.promotion_results;
create policy promotion_results_read
on public.promotion_results
for select
using (
	public.current_role() = 'admin'
	or student_id = auth.uid()
	or (
		public.current_role() = 'servant'
		and exists (
			select 1
			from public.promotion_runs r
			where r.id = run_id
				and r.grade_id = public.current_grade_id()
		)
	)
);
drop policy if exists promotion_results_admin_write on public.promotion_results;
create policy promotion_results_admin_write
on public.promotion_results
for insert
with check (public.current_role() = 'admin');
