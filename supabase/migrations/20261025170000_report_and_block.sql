-- Ticket 11: report a profile, block in both directions, and log removals.

create type public.report_status as enum ('open', 'closed');

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid references public.profiles (id) on delete set null,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  reason text not null,
  status public.report_status not null default 'open',
  created_at timestamptz not null default now(),
  constraint reports_not_self check (reporter_id is distinct from profile_id),
  constraint reports_reason_len check (char_length(reason) between 1 and 500)
);

create index reports_status_created on public.reports (status, created_at);

create table public.blocks (
  blocker_id uuid not null references public.profiles (id) on delete cascade,
  blocked_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint blocks_not_self check (blocker_id <> blocked_id)
);

create index blocks_blocked on public.blocks (blocked_id);

create table public.moderation_log (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references public.profiles (id) on delete set null,
  new_status public.moderation_status not null,
  actor text not null default current_user,
  note text,
  created_at timestamptz not null default now()
);

alter table public.reports enable row level security;
alter table public.blocks enable row level security;
alter table public.moderation_log enable row level security;

revoke all on table public.reports from public, anon, authenticated;
revoke all on table public.blocks from public, anon, authenticated;
revoke all on table public.moderation_log from public, anon, authenticated;

grant insert (reporter_id, profile_id, reason) on table public.reports to authenticated;
grant select, insert, delete on table public.blocks to authenticated;

create policy reports_insert_own
  on public.reports for insert to authenticated
  with check (reporter_id = auth.uid() and reporter_id <> profile_id);

create policy blocks_select_own
  on public.blocks for select to authenticated
  using (blocker_id = auth.uid());

create policy blocks_insert_own
  on public.blocks for insert to authenticated
  with check (blocker_id = auth.uid() and blocker_id <> blocked_id);

create policy blocks_delete_own
  on public.blocks for delete to authenticated
  using (blocker_id = auth.uid());

create function public.log_moderation_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $fn$
begin
  if new.moderation_status is distinct from old.moderation_status then
    insert into public.moderation_log (profile_id, new_status)
    values (new.id, new.moderation_status);
  end if;
  return new;
end;
$fn$;

create trigger profiles_log_moderation
  after update on public.profiles
  for each row
  execute function public.log_moderation_change();

create or replace function public.get_public_profile(p_profile_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $fn$
declare
  found_profile public.profiles%rowtype;
  city jsonb;
  contact jsonb;
  skills jsonb;
  evidence jsonb;
begin
  select * into found_profile from public.profiles where id = p_profile_id;
  if not found
    or found_profile.visibility <> 'public'
    or found_profile.moderation_status <> 'active' then
    return null;
  end if;
  if auth.uid() is not null and exists (
    select 1 from public.blocks
    where (blocker_id = auth.uid() and blocked_id = p_profile_id)
      or (blocker_id = p_profile_id and blocked_id = auth.uid())
  ) then
    return null;
  end if;

  select jsonb_build_object(
    'code', cities.code,
    'label_vi', cities.label_vi,
    'label_en', cities.label_en
  ) into city
  from public.cities
  where id = found_profile.city_id;

  if found_profile.contact_visible and found_profile.contact_value is not null then
    contact := jsonb_build_object(
      'type', found_profile.contact_type,
      'value', found_profile.contact_value
    );
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'id', skills.id,
    'name', skills.name,
    'confidence', skills.confidence,
    'endorsement_count', 0,
    'evidence_ids', coalesce((
      select jsonb_agg(skill_evidence.evidence_id)
      from public.skill_evidence
      where skill_evidence.skill_id = skills.id
    ), '[]'::jsonb),
    'viewer_can_endorse', case when auth.uid() is null then null else to_jsonb(false) end,
    'viewer_endorsement_id', null
  ) order by skills.created_at), '[]'::jsonb)
  into skills
  from public.skills
  where skills.profile_id = found_profile.id;

  select coalesce(jsonb_agg(jsonb_build_object(
    'id', evidence.id,
    'kind', evidence.kind,
    'url', evidence.url,
    'title', evidence.title
  ) order by evidence.created_at), '[]'::jsonb)
  into evidence
  from public.evidence
  where evidence.profile_id = found_profile.id;

  return jsonb_build_object(
    'id', found_profile.id,
    'display_name', found_profile.display_name,
    'bio', found_profile.bio,
    'city', city,
    'seniority', found_profile.seniority,
    'avatar_url', found_profile.avatar_url,
    'contact', contact,
    'skills', skills,
    'evidence', evidence,
    'updated_at', found_profile.updated_at
  );
end;
$fn$;

create function public.search_profiles(
  p_query text,
  p_limit integer default 20,
  p_offset integer default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $fn$
declare
  q text;
  viewer uuid := auth.uid();
begin
  q := lower(regexp_replace(btrim(coalesce(p_query, '')), '\s+', ' ', 'g'));
  q := replace(replace(replace(q, '\', '\\'), '%', '\%'), '_', '\_');
  if char_length(q) < 2 then
    raise exception 'QUERY_TOO_SHORT' using errcode = 'P0001';
  end if;
  return coalesce((
    select jsonb_agg(to_jsonb(matches))
    from (
      select profiles.id as profile_id, profiles.display_name
      from public.profiles
      join public.skills on skills.profile_id = profiles.id
      where profiles.visibility = 'public'
        and profiles.moderation_status = 'active'
        and profiles.id is distinct from viewer
        and skills.name_normalized like q || '%'
        and not exists (
          select 1 from public.blocks
          where (blocker_id = viewer and blocked_id = profiles.id)
            or (blocker_id = profiles.id and blocked_id = viewer)
        )
      group by profiles.id
      order by profiles.updated_at desc, profiles.id
      limit least(coalesce(p_limit, 20), 50)
      offset greatest(coalesce(p_offset, 0), 0)
    ) as matches
  ), '[]'::jsonb);
end;
$fn$;

create function public.endorse_skill(p_skill_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $fn$
declare
  owner uuid;
begin
  select profile_id into owner from public.skills where id = p_skill_id;
  if owner is null or exists (
    select 1 from public.blocks
    where (blocker_id = auth.uid() and blocked_id = owner)
      or (blocker_id = owner and blocked_id = auth.uid())
  ) or exists (
    select 1 from public.profiles
    where id = owner
      and (visibility <> 'public' or moderation_status <> 'active')
  ) then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;
  raise exception 'NOT_ELIGIBLE' using errcode = 'P0001';
end;
$fn$;

revoke all on function public.log_moderation_change() from public, anon;
grant execute on function public.log_moderation_change() to authenticated;
revoke all on function public.search_profiles(text, integer, integer) from public, anon;
grant execute on function public.search_profiles(text, integer, integer) to authenticated;
revoke all on function public.endorse_skill(uuid) from public, anon;
grant execute on function public.endorse_skill(uuid) to authenticated;

create function public.list_blocked()
returns table (id uuid, display_name text)
language sql
stable
security definer
set search_path = public
as $fn$
  select profiles.id, profiles.display_name
  from public.blocks
  join public.profiles on profiles.id = blocks.blocked_id
  where blocks.blocker_id = auth.uid();
$fn$;

revoke all on function public.list_blocked() from public, anon;
grant execute on function public.list_blocked() to authenticated;
