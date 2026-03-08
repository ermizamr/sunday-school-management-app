-- Enforce that attendance_sessions.grade_id always matches subjects.grade_id for its subject_id.
-- This prevents data drift/inconsistency while keeping the existing schema (Option B).

create or replace function public.attendance_sessions_enforce_grade_id()
returns trigger
language plpgsql
as $$
declare
  subject_grade_id uuid;
begin
  select s.grade_id
    into subject_grade_id
  from public.subjects s
  where s.id = new.subject_id;

  if subject_grade_id is null then
    raise exception 'Invalid subject_id: %', new.subject_id;
  end if;

  -- grade_id is NOT NULL on the table today, so this is mainly a validation.
  -- If you ever relax the column to allow nulls, this also self-heals.
  if new.grade_id is null then
    new.grade_id := subject_grade_id;
  elsif new.grade_id <> subject_grade_id then
    raise exception 'attendance_sessions.grade_id (%) does not match subjects.grade_id (%) for subject_id (%)',
      new.grade_id, subject_grade_id, new.subject_id;
  end if;

  return new;
end;
$$;
drop trigger if exists attendance_sessions_enforce_grade_id on public.attendance_sessions;
create trigger attendance_sessions_enforce_grade_id
before insert or update of subject_id, grade_id
on public.attendance_sessions
for each row
execute function public.attendance_sessions_enforce_grade_id();
