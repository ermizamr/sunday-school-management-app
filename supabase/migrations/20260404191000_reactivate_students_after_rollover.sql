-- Data repair: reactivate students after rollover
--
-- Some environments ended up with many students set to `inactive_pending_admin`
-- immediately after starting a new academic year.
--
-- The current rollover policy no longer forces non-promoted students inactive.
-- This migration repairs existing data by reactivating student profiles that are
-- currently `inactive_pending_admin`.
--
-- Note: if you intentionally use `inactive_pending_admin` to deactivate specific
-- students, you may need to toggle those few back to inactive after this repair.

update public.profiles
set account_status = 'active'::public.account_status
where role = 'student'
  and account_status = 'inactive_pending_admin'::public.account_status;
