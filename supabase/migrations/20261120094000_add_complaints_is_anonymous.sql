-- Add is_anonymous to complaints and archive_complaints to support privacy-preserving anonymous complaints.
alter table public.complaints add column if not exists is_anonymous boolean not null default false;
alter table public.archive_complaints add column if not exists is_anonymous boolean not null default false;
