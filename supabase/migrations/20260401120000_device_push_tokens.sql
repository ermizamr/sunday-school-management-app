-- Device push tokens (FCM/APNs) for real push notifications
create table if not exists public.device_push_tokens (
	id uuid primary key default gen_random_uuid(),
	user_id uuid not null references public.profiles(id) on delete cascade,
	fcm_token text not null,
	platform text not null,
	device_id text,
	enabled boolean not null default true,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	last_seen_at timestamptz
);

create unique index if not exists device_push_tokens_fcm_token_uniq
	on public.device_push_tokens (fcm_token);
create index if not exists device_push_tokens_user_idx
	on public.device_push_tokens (user_id);
create index if not exists device_push_tokens_enabled_idx
	on public.device_push_tokens (enabled);

drop trigger if exists device_push_tokens_set_updated_at on public.device_push_tokens;
create trigger device_push_tokens_set_updated_at
before update on public.device_push_tokens
for each row execute function public.set_updated_at();

alter table public.device_push_tokens enable row level security;

-- Users can manage their own tokens.
drop policy if exists device_push_tokens_select_own on public.device_push_tokens;
create policy device_push_tokens_select_own
on public.device_push_tokens
for select
using (user_id = auth.uid());

drop policy if exists device_push_tokens_insert_own on public.device_push_tokens;
create policy device_push_tokens_insert_own
on public.device_push_tokens
for insert
with check (user_id = auth.uid());

drop policy if exists device_push_tokens_update_own on public.device_push_tokens;
create policy device_push_tokens_update_own
on public.device_push_tokens
for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists device_push_tokens_delete_own on public.device_push_tokens;
create policy device_push_tokens_delete_own
on public.device_push_tokens
for delete
using (user_id = auth.uid());
