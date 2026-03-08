-- Grade classification bounds (lower/upper) stored in promotion_criteria_sets
-- Categories:
-- - Excellent (A/A+)
-- - Very good (A-)
-- - Good (B+)
-- - Enough (B)
-- - Critical (below B)

alter table public.promotion_criteria_sets
	add column if not exists excellent_lower numeric not null default 93,
	add column if not exists excellent_upper numeric not null default 100,
	add column if not exists very_good_lower numeric not null default 90,
	add column if not exists very_good_upper numeric not null default 92.99,
	add column if not exists good_lower numeric not null default 87,
	add column if not exists good_upper numeric not null default 89.99,
	add column if not exists enough_lower numeric not null default 83,
	add column if not exists enough_upper numeric not null default 86.99;
alter table public.promotion_criteria_sets
	drop constraint if exists promotion_criteria_sets_category_bounds_chk;
alter table public.promotion_criteria_sets
	add constraint promotion_criteria_sets_category_bounds_chk
	check (
		excellent_lower >= 0 and excellent_upper <= 100 and excellent_lower <= excellent_upper
		and very_good_lower >= 0 and very_good_upper <= 100 and very_good_lower <= very_good_upper
		and good_lower >= 0 and good_upper <= 100 and good_lower <= good_upper
		and enough_lower >= 0 and enough_upper <= 100 and enough_lower <= enough_upper
		-- Non-overlapping descending bands (critical is anything below enough_lower)
		and excellent_lower > very_good_upper
		and very_good_lower > good_upper
		and good_lower > enough_upper
	);
