-- Ticket 06: connect GitHub and save chosen public repos (DATA_MODEL 4.2, 4.3).
-- Article and product rows use the same evidence table so a later ticket can add them
-- without creating the table twice.

create type public.evidence_kind as enum ('github_repo', 'article', 'product');

create table public.github_connections (
  profile_id uuid primary key references public.profiles (id) on delete cascade,
  github_username text not null,
  connected_at timestamptz not null default now()
);

create table public.evidence (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  kind public.evidence_kind not null,
  url text not null,
  title text,
  github_full_name text,
  is_fork boolean not null default false,
  created_at timestamptz not null default now(),
  constraint evidence_url_format check (
    char_length(url) <= 2048
    and url ~ '^https?://[^\s/$.?#].[^\s]*$'
  ),
  constraint evidence_title_len check (title is null or char_length(title) <= 200),
  constraint evidence_github_name check (
    (kind = 'github_repo') = (github_full_name is not null)
  ),
  unique (profile_id, url),
  unique (profile_id, github_full_name)
);

create index evidence_profile_kind on public.evidence (profile_id, kind);

create table public.skill_evidence (
  skill_id uuid not null references public.skills (id) on delete cascade,
  evidence_id uuid not null references public.evidence (id) on delete cascade,
  primary key (skill_id, evidence_id)
);

alter table public.github_connections enable row level security;
alter table public.evidence enable row level security;
alter table public.skill_evidence enable row level security;

revoke all on table public.github_connections from public, anon, authenticated;
revoke all on table public.evidence from public, anon, authenticated;
revoke all on table public.skill_evidence from public, anon, authenticated;

grant usage on type public.evidence_kind to authenticated;
grant select, delete on table public.github_connections to authenticated;
grant select, delete on table public.evidence to authenticated;
grant insert (profile_id, kind, url, title) on table public.evidence to authenticated;
grant update (url, title) on table public.evidence to authenticated;
grant select, insert, delete on table public.skill_evidence to authenticated;

create policy github_connection_select_own
  on public.github_connections for select to authenticated
  using (profile_id = auth.uid());

create policy github_connection_delete_own
  on public.github_connections for delete to authenticated
  using (profile_id = auth.uid());

create policy evidence_select_own
  on public.evidence for select to authenticated
  using (profile_id = auth.uid());

create policy evidence_insert_link
  on public.evidence for insert to authenticated
  with check (
    profile_id = auth.uid()
    and kind in ('article', 'product')
  );

create policy evidence_update_link
  on public.evidence for update to authenticated
  using (profile_id = auth.uid() and kind in ('article', 'product'))
  with check (profile_id = auth.uid() and kind in ('article', 'product'));

create policy evidence_delete_own
  on public.evidence for delete to authenticated
  using (profile_id = auth.uid());

create policy skill_evidence_select_own
  on public.skill_evidence for select to authenticated
  using (
    exists (
      select 1 from public.skills
      where skills.id = skill_evidence.skill_id
        and skills.profile_id = auth.uid()
    )
  );

create policy skill_evidence_insert_own
  on public.skill_evidence for insert to authenticated
  with check (
    exists (
      select 1
      from public.skills s
      join public.evidence e on e.profile_id = s.profile_id
      where s.id = skill_evidence.skill_id
        and e.id = skill_evidence.evidence_id
        and s.profile_id = auth.uid()
    )
  );

create policy skill_evidence_delete_own
  on public.skill_evidence for delete to authenticated
  using (
    exists (
      select 1 from public.skills
      where skills.id = skill_evidence.skill_id
        and skills.profile_id = auth.uid()
    )
  );

create function public.limit_evidence_rows()
returns trigger
language plpgsql
set search_path = public
as $fn$
begin
  if (
    select count(*)
    from public.evidence
    where profile_id = new.profile_id
      and (
        (new.kind = 'github_repo' and kind = 'github_repo')
        or (new.kind in ('article', 'product') and kind in ('article', 'product'))
      )
  ) >= 10 then
    raise exception 'EVIDENCE_LIMIT' using errcode = 'P0001';
  end if;
  return new;
end;
$fn$;

create trigger evidence_limit
  before insert on public.evidence
  for each row
  execute function public.limit_evidence_rows();

create function public.recompute_skill_confidence(p_skill_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $fn$
declare
  has_evidence boolean;
begin
  if not exists (select 1 from public.skills where id = p_skill_id) then
    return;
  end if;
  select exists (
    select 1 from public.skill_evidence where skill_id = p_skill_id
  ) into has_evidence;
  update public.skills
  set confidence = case
    when has_evidence then 'evidenced'::public.skill_confidence
    else 'self_claimed'::public.skill_confidence
  end
  where id = p_skill_id
    and confidence is distinct from case
      when has_evidence then 'evidenced'::public.skill_confidence
      else 'self_claimed'::public.skill_confidence
    end;
end;
$fn$;

create function public.skill_evidence_changed()
returns trigger
language plpgsql
security definer
set search_path = public
as $fn$
begin
  if tg_op = 'DELETE' then
    perform public.recompute_skill_confidence(old.skill_id);
  else
    perform public.recompute_skill_confidence(new.skill_id);
  end if;
  return null;
end;
$fn$;

create trigger skill_evidence_recompute
  after insert or delete on public.skill_evidence
  for each row
  execute function public.skill_evidence_changed();

create function public.github_disconnected()
returns trigger
language plpgsql
security definer
set search_path = public
as $fn$
begin
  delete from public.evidence
  where profile_id = old.profile_id
    and kind = 'github_repo';
  return old;
end;
$fn$;

create trigger github_disconnect_removes_repos
  after delete on public.github_connections
  for each row
  execute function public.github_disconnected();

create function public.connect_github()
returns jsonb
language plpgsql
security definer
set search_path = public
as $fn$
declare
  uid uuid := auth.uid();
  username text;
begin
  if uid is null then
    raise exception 'GITHUB_IDENTITY_MISSING' using errcode = 'P0001';
  end if;
  select coalesce(
    nullif(identity_data->>'user_name', ''),
    nullif(identity_data->>'preferred_username', ''),
    nullif(identity_data->>'login', '')
  )
  into username
  from auth.identities
  where user_id = uid
    and provider = 'github'
  order by created_at desc nulls last
  limit 1;
  if username is null or username = '' then
    raise exception 'GITHUB_IDENTITY_MISSING' using errcode = 'P0001';
  end if;
  insert into public.github_connections (profile_id, github_username)
  values (uid, username)
  on conflict (profile_id) do update
    set github_username = excluded.github_username;
  return jsonb_build_object('github_username', username);
end;
$fn$;

create function public.save_github_repos(p_profile_id uuid, p_repos jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $fn$
declare
  username text;
  repo jsonb;
  full_name text;
  saved_count int := coalesce(jsonb_array_length(p_repos), 0);
begin
  if saved_count > 10 then
    raise exception 'TOO_MANY_REPOS' using errcode = 'P0001';
  end if;
  select github_username into username
  from public.github_connections
  where profile_id = p_profile_id;
  if username is null then
    raise exception 'GITHUB_NOT_CONNECTED' using errcode = 'P0001';
  end if;
  for repo in select value from jsonb_array_elements(coalesce(p_repos, '[]'::jsonb))
  loop
    full_name := repo->>'full_name';
    if full_name is null
      or full_name !~ ('^' || username || '/[^/]+$')
      or coalesce(repo->>'url', '') <> 'https://github.com/' || full_name then
      raise exception 'REPO_NOT_PUBLIC' using errcode = 'P0001';
    end if;
  end loop;
  delete from public.evidence as existing
  where existing.profile_id = p_profile_id
    and existing.kind = 'github_repo'
    and not exists (
      select 1
      from jsonb_array_elements(coalesce(p_repos, '[]'::jsonb)) as wanted
      where wanted->>'full_name' = existing.github_full_name
    );
  insert into public.evidence (
    profile_id, kind, url, title, github_full_name, is_fork
  )
  select
    p_profile_id,
    'github_repo',
    wanted->>'url',
    nullif(left(wanted->>'title', 200), ''),
    wanted->>'full_name',
    coalesce((wanted->>'is_fork')::boolean, false)
  from jsonb_array_elements(coalesce(p_repos, '[]'::jsonb)) as wanted
  where not exists (
    select 1
    from public.evidence as existing
    where existing.profile_id = p_profile_id
      and existing.github_full_name = wanted->>'full_name'
  );
  return jsonb_build_object('saved', saved_count);
end;
$fn$;

revoke all on function public.limit_evidence_rows() from public;
revoke all on function public.recompute_skill_confidence(uuid) from public;
revoke all on function public.skill_evidence_changed() from public;
revoke all on function public.github_disconnected() from public;
revoke all on function public.connect_github() from public;
revoke all on function public.save_github_repos(uuid, jsonb) from public;
revoke execute on function public.limit_evidence_rows() from anon, authenticated;
revoke execute on function public.recompute_skill_confidence(uuid) from anon, authenticated;
revoke execute on function public.skill_evidence_changed() from anon, authenticated;
revoke execute on function public.github_disconnected() from anon, authenticated;
revoke execute on function public.connect_github() from anon;
revoke execute on function public.save_github_repos(uuid, jsonb) from anon, authenticated;
grant execute on function public.connect_github() to authenticated;
grant execute on function public.save_github_repos(uuid, jsonb) to service_role;
