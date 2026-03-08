-- Allow servants to create subjects for their own grade.
-- This is needed for the Servant Grades "+ New Subject" workflow.

begin;
drop policy if exists subjects_insert_grade_servant on public.subjects;
create policy subjects_insert_grade_servant
on public.subjects
for insert
with check (
  public.current_role() = 'servant'
  and public.current_grade_id() is not null
  and grade_id = public.current_grade_id()
);
commit;
