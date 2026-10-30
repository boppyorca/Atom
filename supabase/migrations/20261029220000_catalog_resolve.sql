-- Resolve suggestions by catalog id, and record whether a skill can be checked from code.

alter table public.skill_catalog
  add column verifiability text not null default 'unverifiable'
    check (verifiability in ('file', 'package', 'unverifiable'));

update public.skill_catalog
set verifiability = 'file'
where cardinality(extensions) > 0;

update public.skill_catalog
set verifiability = 'package'
where id in ('provider', 'react');

update public.skill_catalog
set verifiability = 'file'
where id in ('flutter', 'docker');

alter table public.skill_suggestions
  add column catalog_id text references public.skill_catalog (id);

create or replace function public.catalog_name_key(raw text)
returns text
language sql
immutable
set search_path = ''
as $$
  select pg_catalog.lower(
    pg_catalog.regexp_replace(pg_catalog.btrim(coalesce(raw, ''::text)), '\s+', ' ', 'g')
  )
$$;

create table public.skill_catalog_key (
  name_key text primary key,
  catalog_id text not null references public.skill_catalog (id) on delete cascade
);

alter table public.skill_catalog_key enable row level security;
revoke all on table public.skill_catalog_key from public, anon, authenticated;
revoke all on function public.catalog_name_key(text) from public, anon, authenticated;

insert into public.skill_catalog_key (name_key, catalog_id)
select distinct public.catalog_name_key(key_text), id
from public.skill_catalog,
  unnest(array[name] || aliases) as key_text
where public.catalog_name_key(key_text) <> '';

create or replace function public.sync_skill_catalog_key()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' or tg_op = 'DELETE' then
    delete from public.skill_catalog_key where catalog_id = old.id;
  end if;
  if tg_op = 'DELETE' then
    return old;
  end if;
  insert into public.skill_catalog_key (name_key, catalog_id)
  select distinct public.catalog_name_key(key_text), new.id
  from unnest(array[new.name] || coalesce(new.aliases, '{}')) as key_text
  where public.catalog_name_key(key_text) <> '';
  return new;
end;
$$;

revoke all on function public.sync_skill_catalog_key() from public, anon, authenticated;

create trigger skill_catalog_sync_keys
  after insert or update or delete on public.skill_catalog
  for each row execute function public.sync_skill_catalog_key();

update public.skill_suggestions as suggestion
set catalog_id = catalog_key.catalog_id
from public.skill_catalog_key as catalog_key
where suggestion.catalog_id is null
  and public.catalog_name_key(suggestion.name) = catalog_key.name_key;
