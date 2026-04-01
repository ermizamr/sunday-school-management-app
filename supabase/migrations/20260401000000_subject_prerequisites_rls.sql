-- Enable RLS + policies for subject prerequisites

-- This table is used by the admin panel (and by prerequisite enforcement functions).
-- Without RLS, any granted privileges could allow unintended reads/writes.

alter table if exists public.subject_prerequisites enable row level security;
-- Read: allow any authenticated user to read prerequisite mappings.
drop policy if exists subject_prerequisites_read_all on public.subject_prerequisites;
create policy subject_prerequisites_read_all
on public.subject_prerequisites
for select
using (auth.role() = 'authenticated');
-- Write: admin only.
drop policy if exists subject_prerequisites_admin_write on public.subject_prerequisites;
create policy subject_prerequisites_admin_write
on public.subject_prerequisites
for insert
with check (public.current_role() = 'admin');
drop policy if exists subject_prerequisites_admin_update on public.subject_prerequisites;
create policy subject_prerequisites_admin_update
on public.subject_prerequisites
for update
using (public.current_role() = 'admin')
with check (public.current_role() = 'admin');
drop policy if exists subject_prerequisites_admin_delete on public.subject_prerequisites;
create policy subject_prerequisites_admin_delete
on public.subject_prerequisites
for delete
using (public.current_role() = 'admin');
