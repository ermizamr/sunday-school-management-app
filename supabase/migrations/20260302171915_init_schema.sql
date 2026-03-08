-- Initial schema for Sunday School Management System (Supabase/Postgres)

-- Needed for gen_random_uuid()
create extension if not exists pgcrypto;
-- Enums
do $$
begin
	if not exists (select 1 from pg_type where typname = 'user_role') then
		create type public.user_role as enum ('admin', 'student', 'servant');
	end if;

	if not exists (select 1 from pg_type where typname = 'account_status') then
		create type public.account_status as enum ('active', 'inactive_pending_admin');
	end if;

	if not exists (select 1 from pg_type where typname = 'academic_year_status') then
		create type public.academic_year_status as enum ('active', 'ended');
	end if;

	if not exists (select 1 from pg_type where typname = 'academic_year_period') then
		create type public.academic_year_period as enum ('semester1', 'semester2', 'break');
	end if;

	if not exists (select 1 from pg_type where typname = 'attendance_status') then
		create type public.attendance_status as enum ('present', 'late', 'absent', 'permission');
	end if;

	if not exists (select 1 from pg_type where typname = 'promotion_status') then
		create type public.promotion_status as enum ('eligible', 'at_risk', 'not_eligible');
	end if;

	if not exists (select 1 from pg_type where typname = 'complaint_status') then
		create type public.complaint_status as enum ('pending', 'in_review', 'resolved');
	end if;
end $$;
-- Utility: updated_at trigger
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
	new.updated_at = now();
	return new;
end;
$$;
-- Grades (exactly 4 logical grades; seeded separately)
create table if not exists public.grades (
	id uuid primary key default gen_random_uuid(),
	code text not null unique, -- e.g. '1st', '2nd', '3rd', '4th'
	name text not null,
	sort_order int not null unique,
	created_at timestamptz not null default now()
);
-- Academic years
create table if not exists public.academic_years (
	id uuid primary key default gen_random_uuid(),
	name text not null unique,
	start_date date not null,
	end_date date not null,
	status public.academic_year_status not null default 'active',
	current_period public.academic_year_period,
	ended_at timestamptz,
	archived_at timestamptz,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now()
);
create index if not exists academic_years_status_idx on public.academic_years (status);
create unique index if not exists academic_years_single_active_idx
	on public.academic_years (status)
	where status = 'active';
drop trigger if exists academic_years_set_updated_at on public.academic_years;
create trigger academic_years_set_updated_at
before update on public.academic_years
for each row execute function public.set_updated_at();
-- Profiles (ties Supabase Auth users to app roles/grade)
create table if not exists public.profiles (
	id uuid primary key references auth.users(id) on delete cascade,
	role public.user_role not null,
	academic_id text not null unique,
	name text,
	grade_id uuid references public.grades(id),
	account_status public.account_status not null default 'active',
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now()
);
create index if not exists profiles_role_idx on public.profiles (role);
create index if not exists profiles_grade_idx on public.profiles (grade_id);
drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();
-- Subjects belong to a grade
create table if not exists public.subjects (
	id uuid primary key default gen_random_uuid(),
	grade_id uuid not null references public.grades(id) on delete restrict,
	name text not null,
	passing_grade int not null default 70,
	weight int not null default 0,
	active boolean not null default true,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	unique (grade_id, name)
);
create index if not exists subjects_grade_idx on public.subjects (grade_id);
drop trigger if exists subjects_set_updated_at on public.subjects;
create trigger subjects_set_updated_at
before update on public.subjects
for each row execute function public.set_updated_at();
-- Grade assessments (normalized replacement for "GradeEntry.scores map")
create table if not exists public.assessments (
	id uuid primary key default gen_random_uuid(),
	academic_year_id uuid not null references public.academic_years(id) on delete restrict,
	grade_id uuid not null references public.grades(id) on delete restrict,
	subject_id uuid not null references public.subjects(id) on delete restrict,
	grade_type text not null,
	max_score numeric not null check (max_score > 0),
	weight int not null check (weight >= 0),
	assessment_date date not null,
	created_by uuid not null references public.profiles(id) on delete restrict,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now()
);
create index if not exists assessments_lookup_idx
	on public.assessments (academic_year_id, grade_id, subject_id, assessment_date);
drop trigger if exists assessments_set_updated_at on public.assessments;
create trigger assessments_set_updated_at
before update on public.assessments
for each row execute function public.set_updated_at();
create table if not exists public.assessment_scores (
	assessment_id uuid not null references public.assessments(id) on delete cascade,
	student_id uuid not null references public.profiles(id) on delete restrict,
	score numeric not null check (score >= 0),
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	primary key (assessment_id, student_id)
);
create index if not exists assessment_scores_student_idx
	on public.assessment_scores (student_id);
drop trigger if exists assessment_scores_set_updated_at on public.assessment_scores;
create trigger assessment_scores_set_updated_at
before update on public.assessment_scores
for each row execute function public.set_updated_at();
-- Attendance
create table if not exists public.attendance_sessions (
	id uuid primary key default gen_random_uuid(),
	academic_year_id uuid not null references public.academic_years(id) on delete restrict,
	grade_id uuid not null references public.grades(id) on delete restrict,
	subject_id uuid not null references public.subjects(id) on delete restrict,
	session_date date not null,
	created_by uuid not null references public.profiles(id) on delete restrict,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	unique (academic_year_id, subject_id, session_date)
);
create index if not exists attendance_sessions_lookup_idx
	on public.attendance_sessions (academic_year_id, grade_id, subject_id, session_date);
drop trigger if exists attendance_sessions_set_updated_at on public.attendance_sessions;
create trigger attendance_sessions_set_updated_at
before update on public.attendance_sessions
for each row execute function public.set_updated_at();
create table if not exists public.attendance_records (
	session_id uuid not null references public.attendance_sessions(id) on delete cascade,
	student_id uuid not null references public.profiles(id) on delete restrict,
	status public.attendance_status not null,
	updated_by uuid references public.profiles(id) on delete set null,
	updated_at timestamptz not null default now(),
	primary key (session_id, student_id)
);
create index if not exists attendance_records_student_idx
	on public.attendance_records (student_id);
-- Communication
create table if not exists public.announcements (
	id uuid primary key default gen_random_uuid(),
	academic_year_id uuid references public.academic_years(id) on delete set null,
	grade_id uuid references public.grades(id) on delete set null, -- null means global
	title text not null,
	message text not null,
	category text,
	priority text,
	created_by uuid not null references public.profiles(id) on delete restrict,
	created_at timestamptz not null default now(),
	expires_on date,
	active boolean not null default true
);
create index if not exists announcements_scope_idx
	on public.announcements (grade_id, created_at desc);
create table if not exists public.questions (
	id uuid primary key default gen_random_uuid(),
	academic_year_id uuid not null references public.academic_years(id) on delete restrict,
	grade_id uuid not null references public.grades(id) on delete restrict,
	subject_id uuid references public.subjects(id) on delete set null,
	student_id uuid not null references public.profiles(id) on delete restrict,
	question text not null,
	created_at timestamptz not null default now(),
	answered boolean not null default false,
	answer text,
	answered_by uuid references public.profiles(id) on delete set null,
	answered_at timestamptz
);
create index if not exists questions_scope_idx on public.questions (grade_id, created_at desc);
create index if not exists questions_student_idx on public.questions (student_id, created_at desc);
create table if not exists public.complaints (
	id uuid primary key default gen_random_uuid(),
	academic_year_id uuid not null references public.academic_years(id) on delete restrict,
	grade_id uuid not null references public.grades(id) on delete restrict,
	student_id uuid not null references public.profiles(id) on delete restrict,
	category text,
	complaint text not null,
	created_at timestamptz not null default now(),
	status public.complaint_status not null default 'pending',
	response text,
	responded_by uuid references public.profiles(id) on delete set null,
	responded_at timestamptz
);
create index if not exists complaints_scope_idx on public.complaints (grade_id, created_at desc);
create index if not exists complaints_student_idx on public.complaints (student_id, created_at desc);
-- Promotion criteria and results
create table if not exists public.promotion_criteria_sets (
	id uuid primary key default gen_random_uuid(),
	academic_year_id uuid not null references public.academic_years(id) on delete restrict,
	grade_id uuid not null references public.grades(id) on delete restrict,
	minimum_overall_average numeric not null default 70,
	minimum_subject_grade numeric not null default 60,
	minimum_attendance numeric not null default 75,
	created_at timestamptz not null default now(),
	unique (academic_year_id, grade_id)
);
create table if not exists public.promotion_criteria_subjects (
	criteria_set_id uuid not null references public.promotion_criteria_sets(id) on delete cascade,
	subject_id uuid not null references public.subjects(id) on delete restrict,
	required boolean not null default true,
	minimum_grade numeric,
	weight int,
	primary key (criteria_set_id, subject_id)
);
create table if not exists public.promotion_runs (
	id uuid primary key default gen_random_uuid(),
	academic_year_id uuid not null references public.academic_years(id) on delete restrict,
	grade_id uuid not null references public.grades(id) on delete restrict,
	run_by uuid not null references public.profiles(id) on delete restrict,
	run_at timestamptz not null default now(),
	notes text
);
create index if not exists promotion_runs_lookup_idx
	on public.promotion_runs (academic_year_id, grade_id, run_at desc);
create table if not exists public.promotion_results (
	run_id uuid not null references public.promotion_runs(id) on delete cascade,
	student_id uuid not null references public.profiles(id) on delete restrict,
	status public.promotion_status not null,
	overall_average numeric,
	attendance_percent numeric,
	recommended_next_grade_id uuid references public.grades(id) on delete set null,
	computed_at timestamptz not null default now(),
	details jsonb not null default '{}'::jsonb,
	primary key (run_id, student_id)
);
create index if not exists promotion_results_student_idx
	on public.promotion_results (student_id, computed_at desc);
-- Archive tables for storage optimization
-- (No foreign keys; used by archive_academic_year RPC)
create table if not exists public.archive_assessments (like public.assessments including defaults including identity);
create table if not exists public.archive_assessment_scores (like public.assessment_scores including defaults including identity);
create table if not exists public.archive_attendance_sessions (like public.attendance_sessions including defaults including identity);
create table if not exists public.archive_attendance_records (like public.attendance_records including defaults including identity);
create table if not exists public.archive_announcements (like public.announcements including defaults including identity);
create table if not exists public.archive_questions (like public.questions including defaults including identity);
create table if not exists public.archive_complaints (like public.complaints including defaults including identity);
create table if not exists public.archive_promotion_runs (like public.promotion_runs including defaults including identity);
create table if not exists public.archive_promotion_results (like public.promotion_results including defaults including identity);
