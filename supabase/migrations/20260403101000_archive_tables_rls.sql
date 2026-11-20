-- Lock down archive tables (created in init schema) with RLS.
-- These tables can contain sensitive historical data and should not be readable
-- by default via the API.

do $$
begin
  -- Enable RLS
  alter table if exists public.archive_assessments enable row level security;
  alter table if exists public.archive_assessment_scores enable row level security;
  alter table if exists public.archive_attendance_sessions enable row level security;
  alter table if exists public.archive_attendance_records enable row level security;
  alter table if exists public.archive_announcements enable row level security;
  alter table if exists public.archive_questions enable row level security;
  alter table if exists public.archive_complaints enable row level security;
  alter table if exists public.archive_promotion_runs enable row level security;
  alter table if exists public.archive_promotion_results enable row level security;
exception
  when undefined_table then
    -- If a table doesn't exist in a given environment, ignore.
    null;
end $$;

-- Admin-only access (covers select/insert/update/delete).

drop policy if exists archive_assessments_admin_only on public.archive_assessments;
create policy archive_assessments_admin_only
on public.archive_assessments
for all
using (public.current_role() = 'admin')
with check (public.current_role() = 'admin');

drop policy if exists archive_assessment_scores_admin_only on public.archive_assessment_scores;
create policy archive_assessment_scores_admin_only
on public.archive_assessment_scores
for all
using (public.current_role() = 'admin')
with check (public.current_role() = 'admin');

drop policy if exists archive_attendance_sessions_admin_only on public.archive_attendance_sessions;
create policy archive_attendance_sessions_admin_only
on public.archive_attendance_sessions
for all
using (public.current_role() = 'admin')
with check (public.current_role() = 'admin');

drop policy if exists archive_attendance_records_admin_only on public.archive_attendance_records;
create policy archive_attendance_records_admin_only
on public.archive_attendance_records
for all
using (public.current_role() = 'admin')
with check (public.current_role() = 'admin');

drop policy if exists archive_announcements_admin_only on public.archive_announcements;
create policy archive_announcements_admin_only
on public.archive_announcements
for all
using (public.current_role() = 'admin')
with check (public.current_role() = 'admin');

drop policy if exists archive_questions_admin_only on public.archive_questions;
create policy archive_questions_admin_only
on public.archive_questions
for all
using (public.current_role() = 'admin')
with check (public.current_role() = 'admin');

drop policy if exists archive_complaints_admin_only on public.archive_complaints;
create policy archive_complaints_admin_only
on public.archive_complaints
for all
using (public.current_role() = 'admin')
with check (public.current_role() = 'admin');

drop policy if exists archive_promotion_runs_admin_only on public.archive_promotion_runs;
create policy archive_promotion_runs_admin_only
on public.archive_promotion_runs
for all
using (public.current_role() = 'admin')
with check (public.current_role() = 'admin');

drop policy if exists archive_promotion_results_admin_only on public.archive_promotion_results;
create policy archive_promotion_results_admin_only
on public.archive_promotion_results
for all
using (public.current_role() = 'admin')
with check (public.current_role() = 'admin');
