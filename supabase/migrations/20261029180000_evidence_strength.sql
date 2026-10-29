-- Confidence comes from signal strength. Accepting a suggestion no longer
-- raises the level by itself. Old migration files are left unchanged.

create table public.evidence_policy (
  id uuid primary key default gen_random_uuid(),
  version integer not null unique,
  min_commits integer not null,
  min_lines integer not null,
  min_span_days integer not null,
  is_active boolean not null default false,
  created_at timestamptz not null default now()
);

create unique index evidence_policy_one_active
  on public.evidence_policy ((true))
  where is_active;

insert into public.evidence_policy
  (version, min_commits, min_lines, min_span_days, is_active)
values (1, 5, 200, 14, true);

create table public.evidence_signal (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  skill_id uuid not null references public.skills (id) on delete cascade,
  evidence_id uuid references public.evidence (id) on delete cascade,
  repo_ref text,
  signal_type text not null,
  strength text generated always as (
    case signal_type
      when 'commit_activity' then 'strong'
      when 'manifest_dependency' then 'supporting'
      else 'weak'
    end
  ) stored,
  valid_commit_count integer,
  lines_authored integer,
  first_commit_at timestamptz,
  last_commit_at timestamptz,
  computed_at timestamptz not null default now(),
  constraint evidence_signal_type check (signal_type in (
    'commit_activity', 'manifest_dependency', 'readme_keyword',
    'topic', 'language_stat', 'article_link', 'manual_note'
  ))
);

create unique index evidence_signal_once
  on public.evidence_signal (skill_id, evidence_id, signal_type)
  where evidence_id is not null;

alter table public.skill_suggestions
  add column signal_types text[] not null default '{}';

alter table public.evidence_policy enable row level security;
alter table public.evidence_signal enable row level security;
revoke all on table public.evidence_policy from public, anon, authenticated;
revoke all on table public.evidence_signal from public, anon, authenticated;
grant select on table public.evidence_policy to authenticated;
grant select on table public.evidence_signal to authenticated;

create policy evidence_policy_read
  on public.evidence_policy for select to authenticated
  using (true);

create policy evidence_signal_read_own
  on public.evidence_signal for select to authenticated
  using (profile_id = (select auth.uid()));

create function public._skill_confidence(p_profile_id uuid, p_skill_id uuid)
returns table (
  confidence public.skill_confidence,
  qualifying_signal_ids uuid[],
  reason text
)
language plpgsql
stable
security definer
set search_path = ''
as $fn$
declare
  min_commits integer;
  min_lines integer;
  min_span_days integer;
  strong_ids uuid[];
  strong_repos text[];
  support_id uuid;
begin
  select policy.min_commits, policy.min_lines, policy.min_span_days
    into min_commits, min_lines, min_span_days
  from public.evidence_policy as policy
  where policy.is_active
  limit 1;

  if not exists (
    select 1 from public.evidence_signal as signal
    where signal.profile_id = p_profile_id
      and signal.skill_id = p_skill_id
  ) then
    return query
      select 'self_claimed'::public.skill_confidence, '{}'::uuid[], 'no_signals'::text;
    return;
  end if;

  if min_commits is null then
    return query
      select 'self_claimed'::public.skill_confidence, '{}'::uuid[], 'strong_below_threshold'::text;
    return;
  end if;

  select
    coalesce(array_agg(signal.id), '{}'::uuid[]),
    coalesce(array_agg(distinct signal.repo_ref) filter (where signal.repo_ref is not null), '{}'::text[])
    into strong_ids, strong_repos
  from public.evidence_signal as signal
  where signal.profile_id = p_profile_id
    and signal.skill_id = p_skill_id
    and signal.signal_type = 'commit_activity'
    and signal.valid_commit_count is not null
    and signal.lines_authored is not null
    and signal.first_commit_at is not null
    and signal.last_commit_at is not null
    and signal.valid_commit_count >= min_commits
    and signal.lines_authored >= min_lines
    and signal.last_commit_at >= signal.first_commit_at + make_interval(days => min_span_days);

  select signal.id into support_id
  from public.evidence_signal as signal
  where signal.profile_id = p_profile_id
    and signal.skill_id = p_skill_id
    and signal.signal_type = 'manifest_dependency'
    and exists (
      select 1 from public.evidence_signal as commit_row
      where commit_row.profile_id = signal.profile_id
        and commit_row.repo_ref = signal.repo_ref
        and commit_row.signal_type = 'commit_activity'
        and commit_row.valid_commit_count >= 1
    )
  limit 1;

  if coalesce(cardinality(strong_ids), 0) >= 1
    and (support_id is not null or coalesce(cardinality(strong_repos), 0) >= 2) then
    return query
      select
        'evidenced'::public.skill_confidence,
        strong_ids || case when support_id is null then '{}'::uuid[] else array[support_id] end,
        'evidenced'::text;
    return;
  end if;

  if coalesce(cardinality(strong_ids), 0) >= 1 then
    return query
      select 'self_claimed'::public.skill_confidence, strong_ids, 'strong_no_independent'::text;
    return;
  end if;

  if exists (
    select 1 from public.evidence_signal as signal
    where signal.profile_id = p_profile_id
      and signal.skill_id = p_skill_id
      and signal.signal_type = 'commit_activity'
  ) then
    return query
      select 'self_claimed'::public.skill_confidence, '{}'::uuid[], 'strong_below_threshold'::text;
    return;
  end if;

  if exists (
    select 1 from public.evidence_signal as signal
    where signal.profile_id = p_profile_id
      and signal.skill_id = p_skill_id
      and signal.signal_type = 'manifest_dependency'
  ) then
    return query
      select 'self_claimed'::public.skill_confidence, '{}'::uuid[], 'supporting_only'::text;
    return;
  end if;

  return query
    select 'self_claimed'::public.skill_confidence, '{}'::uuid[], 'weak_only'::text;
end;
$fn$;

create function public.skill_confidence(p_skill_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $fn$
declare
  uid uuid := auth.uid();
  found_confidence public.skill_confidence;
  found_ids uuid[];
  found_reason text;
begin
  if uid is null or not exists (
    select 1 from public.skills
    where id = p_skill_id and profile_id = uid
  ) then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;
  select detail.confidence, detail.qualifying_signal_ids, detail.reason
    into found_confidence, found_ids, found_reason
  from public._skill_confidence(uid, p_skill_id) as detail;
  return jsonb_build_object(
    'confidence', found_confidence,
    'qualifying_signal_ids', found_ids,
    'reason', found_reason
  );
end;
$fn$;

create or replace function public.recompute_skill_confidence(p_skill_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $fn$
declare
  owner uuid;
  current_level public.skill_confidence;
  next_level public.skill_confidence;
begin
  select profile_id, confidence into owner, current_level
  from public.skills where id = p_skill_id;
  if not found or current_level = 'endorsed' then
    return;
  end if;
  select detail.confidence into next_level
  from public._skill_confidence(owner, p_skill_id) as detail;
  update public.skills
  set confidence = next_level
  where id = p_skill_id
    and confidence is distinct from next_level;
end;
$fn$;

create function public.classify_linked_evidence(p_skill_id uuid, p_evidence_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $fn$
declare
  owner uuid;
  kind public.evidence_kind;
  repo text;
  stored_type text;
begin
  select skills.profile_id, evidence.kind, evidence.github_full_name
    into owner, kind, repo
  from public.skills
  join public.evidence on evidence.profile_id = skills.profile_id
  where skills.id = p_skill_id and evidence.id = p_evidence_id;
  if not found then
    return;
  end if;
  stored_type := case
    when kind in ('article', 'product') then 'article_link'
    else 'readme_keyword'
  end;
  insert into public.evidence_signal (
    profile_id, skill_id, evidence_id, repo_ref, signal_type
  ) values (owner, p_skill_id, p_evidence_id, repo, stored_type)
  on conflict do nothing;
end;
$fn$;

create or replace function public.skill_evidence_changed()
returns trigger
language plpgsql
security definer
set search_path = ''
as $fn$
begin
  if tg_op = 'DELETE' then
    perform public.recompute_skill_confidence(old.skill_id);
  else
    perform public.classify_linked_evidence(new.skill_id, new.evidence_id);
    perform public.recompute_skill_confidence(new.skill_id);
  end if;
  return null;
end;
$fn$;

create function public.protect_skill_confidence()
returns trigger
language plpgsql
set search_path = ''
as $fn$
begin
  if tg_op = 'INSERT'
    and new.confidence is distinct from 'self_claimed'
    and current_user in ('authenticated', 'anon') then
    raise exception 'CONFIDENCE_LOCKED' using errcode = '42501';
  end if;
  if tg_op = 'UPDATE'
    and new.confidence is distinct from old.confidence
    and current_user in ('authenticated', 'anon') then
    raise exception 'CONFIDENCE_LOCKED' using errcode = '42501';
  end if;
  return new;
end;
$fn$;

create trigger skills_protect_confidence
  before insert or update on public.skills
  for each row
  execute function public.protect_skill_confidence();

create or replace function public.review_suggestion(p_suggestion_id uuid, p_accept boolean)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $fn$
declare
  uid uuid := auth.uid();
  suggestion public.skill_suggestions%rowtype;
  skill uuid;
  evidence_id uuid;
  signal text;
  stored_type text;
  repo text;
  found_confidence public.skill_confidence;
  found_reason text;
begin
  select * into suggestion
  from public.skill_suggestions
  where id = p_suggestion_id
  for update;
  if not found or suggestion.profile_id is distinct from uid then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;
  if suggestion.status <> 'pending' then
    raise exception 'ALREADY_REVIEWED' using errcode = 'P0001';
  end if;
  if not p_accept then
    update public.skill_suggestions
    set status = 'rejected', reviewed_at = now()
    where id = suggestion.id;
    return jsonb_build_object('skill_id', null, 'confidence', null, 'reason', null);
  end if;
  select id into skill
  from public.skills
  where profile_id = uid
    and name_normalized = lower(regexp_replace(btrim(suggestion.name), '\s+', ' ', 'g'));
  if skill is null then
    insert into public.skills (profile_id, name)
    values (uid, suggestion.name)
    returning id into skill;
  end if;
  foreach evidence_id in array suggestion.evidence_ids loop
    if exists (
      select 1 from public.evidence
      where id = evidence_id and profile_id = uid
    ) then
      insert into public.skill_evidence (skill_id, evidence_id)
      values (skill, evidence_id)
      on conflict do nothing;
      select github_full_name into repo
      from public.evidence where id = evidence_id;
      foreach signal in array suggestion.signals loop
        stored_type := case split_part(signal, ':', 1)
          when 'language' then 'language_stat'
          when 'topic' then 'topic'
          when 'keyword' then 'readme_keyword'
          when 'dependency' then 'manifest_dependency'
          when 'file' then 'manifest_dependency'
          else 'readme_keyword'
        end;
        insert into public.evidence_signal (
          profile_id, skill_id, evidence_id, repo_ref, signal_type
        ) values (uid, skill, evidence_id, repo, stored_type)
        on conflict do nothing;
      end loop;
    end if;
  end loop;
  perform public.recompute_skill_confidence(skill);
  select detail.confidence, detail.reason
    into found_confidence, found_reason
  from public._skill_confidence(uid, skill) as detail;
  update public.skill_suggestions
  set status = 'accepted', reviewed_at = now()
  where id = suggestion.id;
  return jsonb_build_object(
    'skill_id', skill,
    'confidence', found_confidence,
    'reason', found_reason
  );
end;
$fn$;

create function public.backfill_evidence_signals()
returns void
language plpgsql
security definer
set search_path = ''
as $fn$
declare
  link record;
begin
  for link in
    select skill_evidence.skill_id, skill_evidence.evidence_id
    from public.skill_evidence
  loop
    perform public.classify_linked_evidence(link.skill_id, link.evidence_id);
    perform public.recompute_skill_confidence(link.skill_id);
  end loop;
end;
$fn$;

revoke all on function public._skill_confidence(uuid, uuid) from public, anon, authenticated;
revoke all on function public.skill_confidence(uuid) from public, anon;
grant execute on function public.skill_confidence(uuid) to authenticated;
revoke all on function public.classify_linked_evidence(uuid, uuid) from public, anon, authenticated;
revoke all on function public.backfill_evidence_signals() from public, anon, authenticated;
grant execute on function public.backfill_evidence_signals() to service_role;
revoke all on function public.protect_skill_confidence() from public, anon, authenticated;
