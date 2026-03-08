-- Feedback forms/questions/submissions (scoped by grade + academic year)

do $$
begin
	if not exists (select 1 from pg_type where typname = 'feedback_question_type') then
		create type public.feedback_question_type as enum ('rating', 'text', 'multiple_choice');
	end if;
end $$;
create table if not exists public.feedback_forms (
	id uuid primary key default gen_random_uuid(),
	academic_year_id uuid not null references public.academic_years(id) on delete restrict,
	grade_id uuid not null references public.grades(id) on delete restrict,
	created_by uuid not null references public.profiles(id) on delete restrict,
	type_label text not null,
	title text not null,
	description text not null,
	start_date date not null,
	end_date date not null,
	created_at timestamptz not null default now()
);
create index if not exists feedback_forms_scope_idx
	on public.feedback_forms (grade_id, created_at desc);
create table if not exists public.feedback_questions (
	id uuid primary key default gen_random_uuid(),
	form_id uuid not null references public.feedback_forms(id) on delete cascade,
	position int not null,
	type public.feedback_question_type not null,
	question text not null,
	required boolean not null default true,
	options jsonb
);
create index if not exists feedback_questions_form_idx
	on public.feedback_questions (form_id, position);
create table if not exists public.feedback_submissions (
	id uuid primary key default gen_random_uuid(),
	form_id uuid not null references public.feedback_forms(id) on delete cascade,
	student_id uuid not null references public.profiles(id) on delete restrict,
	submitted_at timestamptz not null default now(),
	answers jsonb not null
);
create unique index if not exists feedback_submissions_unique
	on public.feedback_submissions (form_id, student_id);
create index if not exists feedback_submissions_form_idx
	on public.feedback_submissions (form_id, submitted_at desc);
alter table public.feedback_forms enable row level security;
alter table public.feedback_questions enable row level security;
alter table public.feedback_submissions enable row level security;
