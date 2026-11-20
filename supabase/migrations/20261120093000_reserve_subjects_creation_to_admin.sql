-- Reserve course/subject creation strictly to admins (ንዑስ).
-- Servants must not be allowed to insert or manage courses/subjects.
drop policy if exists subjects_insert_grade_servant on public.subjects;
