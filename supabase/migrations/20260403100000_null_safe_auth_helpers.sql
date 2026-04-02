-- Make auth helper functions NULL-safe.
--
-- Some SECURITY DEFINER functions historically used checks like:
--   if public.current_role() <> 'admin' then raise ...
-- If current_role() returned NULL (missing profile row), the condition becomes NULL
-- and the IF does not run, potentially bypassing authorization.
--
-- This migration ensures helpers always return safe defaults:
-- - current_role(): defaults to 'student' (least privilege)
-- - is_active_account(): defaults to false

create or replace function public.current_role()
returns public.user_role
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select p.role from public.profiles p where p.id = auth.uid()),
    'student'::public.user_role
  );
$$;

create or replace function public.is_active_account()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select (p.account_status = 'active') from public.profiles p where p.id = auth.uid()),
    false
  );
$$;

create or replace function public.current_grade_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select (
    select p.grade_id
    from public.profiles p
    where p.id = auth.uid()
  );
$$;
