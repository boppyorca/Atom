-- Ticket 04: self-claimed skills (DATA_MODEL 4.4, RLS matrix).

create type public.skill_confidence as enum (
  'self_claimed',
  'evidenced',
  'endorsed'
);

create table public.skills (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  name text not null,
  name_normalized text generated always as (
    lower(regexp_replace(btrim(name), '\s+', ' ', 'g'))
  ) stored,
  confidence public.skill_confidence not null default 'self_claimed',
  created_at timestamptz not null default now(),
  constraint skills_name_length check (char_length(name) between 1 and 50),
  constraint skills_unique_name unique (profile_id, name_normalized)
);

create index skills_name_prefix
  on public.skills (name_normalized text_pattern_ops);

alter table public.skills enable row level security;

create policy skills_select_own
  on public.skills
  for select
  to authenticated
  using (profile_id = auth.uid());

create policy skills_insert_own
  on public.skills
  for insert
  to authenticated
  with check (profile_id = auth.uid());

create policy skills_delete_own
  on public.skills
  for delete
  to authenticated
  using (profile_id = auth.uid());

revoke all on table public.skills from public, anon, authenticated;
grant usage on type public.skill_confidence to authenticated;
grant select, delete on table public.skills to authenticated;
grant insert (profile_id, name) on table public.skills to authenticated;

create function public.limit_skills_per_profile()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if (
    select count(*)
    from public.skills
    where profile_id = new.profile_id
  ) >= 50 then
    raise exception 'SKILL_LIMIT' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

create trigger skills_limit
  before insert on public.skills
  for each row
  execute function public.limit_skills_per_profile();

revoke all on function public.limit_skills_per_profile() from public;
revoke execute on function public.limit_skills_per_profile() from anon, authenticated;
