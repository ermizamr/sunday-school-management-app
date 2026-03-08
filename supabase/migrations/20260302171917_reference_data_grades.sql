-- Reference / bootstrap data
-- These rows are treated as fixed in the app and safe to upsert.

insert into public.grades (code, name, sort_order)
values
  ('1st', '1st Grade', 1),
  ('2nd', '2nd Grade', 2),
  ('3rd', '3rd Grade', 3),
  ('4th', '4th Grade', 4)
on conflict (code)
do update set
  name = excluded.name,
  sort_order = excluded.sort_order;
