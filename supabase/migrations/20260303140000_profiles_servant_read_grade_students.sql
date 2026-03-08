-- Allow servants to read the student roster for their grade.
-- This is needed for Attendance/Grades rosters while preserving grade isolation.

drop policy if exists profiles_select_servant_grade_students on public.profiles;
create policy profiles_select_servant_grade_students
on public.profiles
for select
using (
	public.current_role() = 'admin'
	or (
		public.current_role() = 'servant'
		and role = 'student'
		and grade_id = public.current_grade_id()
	)
);
