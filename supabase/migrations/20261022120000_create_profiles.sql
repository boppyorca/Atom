-- Ticket 01: profiles row created on signup, owner-only RLS.

create type public.profile_visibility as enum ('private', 'public');
create type public.moderation_status as enum ('active', 'removed');

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null,
  visibility public.profile_visibility not null default 'private',
  moderation_status public.moderation_status not null default 'active',
  avatar_url text,
  first_public_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_display_name_len check (
    char_length(display_name) between 1 and 60
  )
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row
  execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  name text;
begin
  name := coalesce(nullif(left(split_part(new.email, '@', 1), 60), ''), 'User');
  insert into public.profiles (id, display_name)
  values (new.id, name);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();

alter table public.profiles enable row level security;

revoke all on table public.profiles from public, anon, authenticated;
grant usage on type public.profile_visibility to authenticated;
grant usage on type public.moderation_status to authenticated;
grant select on table public.profiles to authenticated;
grant insert (id, display_name, visibility) on table public.profiles to authenticated;
grant update (display_name, visibility) on table public.profiles to authenticated;

create policy profiles_select_own
  on public.profiles
  for select
  to authenticated
  using (id = auth.uid());

create policy profiles_insert_own
  on public.profiles
  for insert
  to authenticated
  with check (id = auth.uid());

create policy profiles_update_own
  on public.profiles
  for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

revoke all on function public.handle_new_user() from public;
revoke all on function public.set_updated_at() from public;
