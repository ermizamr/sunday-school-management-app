-- Allow servants to delete complaints in their grade (and admins globally).
-- This matches the existing app UX (delete icon on complaint cards).

drop policy if exists complaints_delete_servant on public.complaints;
create policy complaints_delete_servant
on public.complaints
for delete
using (
  public.current_role() = 'admin'
  or (public.current_role() = 'servant' and grade_id = public.current_grade_id())
);
