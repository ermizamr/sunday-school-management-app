-- Fix semester boundary constraint to allow a valid in-between state:
-- semester 1 ended, semester 2 not started yet.

alter table public.academic_years
  drop constraint if exists academic_years_semester_dates_chk;

alter table public.academic_years
  add constraint academic_years_semester_dates_chk
  check (
    (
      semester1_end_date is null
      and semester2_start_date is null
    )
    or (
      semester1_end_date is not null
      and semester2_start_date is null
      and semester1_end_date >= start_date
      and semester1_end_date <= end_date
    )
    or (
      semester1_end_date is not null
      and semester2_start_date is not null
      and semester1_end_date >= start_date
      and semester1_end_date <= end_date
      and semester2_start_date >= start_date
      and semester2_start_date <= end_date
      and semester2_start_date >= semester1_end_date
    )
  );
