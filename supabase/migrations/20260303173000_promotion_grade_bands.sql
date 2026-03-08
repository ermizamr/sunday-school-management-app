-- Grade band thresholds for Promotions (stored in promotion_criteria_sets)
-- These defaults are editable from the admin panel.

alter table public.promotion_criteria_sets
	add column if not exists band_a_plus_min numeric not null default 97,
	add column if not exists band_a_min numeric not null default 93,
	add column if not exists band_a_minus_min numeric not null default 90,
	add column if not exists band_b_plus_min numeric not null default 87,
	add column if not exists band_b_min numeric not null default 83;
alter table public.promotion_criteria_sets
	drop constraint if exists promotion_criteria_sets_band_order_chk;
alter table public.promotion_criteria_sets
	add constraint promotion_criteria_sets_band_order_chk
	check (
		band_a_plus_min >= band_a_min
		and band_a_min >= band_a_minus_min
		and band_a_minus_min >= band_b_plus_min
		and band_b_plus_min >= band_b_min
	);
