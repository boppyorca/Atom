-- Ticket 15: suggest skills from chosen repos, then the person accepts or rejects.

create type public.ai_job_kind as enum ('extract_skills', 'gap_analysis');
create type public.ai_job_status as enum ('queued', 'running', 'succeeded', 'failed', 'timed_out');
create type public.suggestion_status as enum ('pending', 'accepted', 'rejected');

create table public.app_settings (
  key text primary key,
  value jsonb not null
);

insert into public.app_settings (key, value) values
  ('ai_quota_extract_per_month', '3'),
  ('ai_quota_gap_per_month', '10'),
  ('ai_timeout_seconds', '120'),
  ('endorsements_per_month', '10'),
  ('salary_min_sample_size', '5');

create table public.ai_jobs (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  kind public.ai_job_kind not null,
  status public.ai_job_status not null default 'queued',
  input jsonb,
  result jsonb,
  error_code text,
  deadline_at timestamptz not null,
  seen_at timestamptz,
  created_at timestamptz not null default now(),
  finished_at timestamptz
);

create index ai_jobs_profile_kind_created
  on public.ai_jobs (profile_id, kind, created_at desc);

create unique index ai_jobs_one_active
  on public.ai_jobs (profile_id, kind)
  where status in ('queued', 'running');

create table public.skill_suggestions (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.ai_jobs (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  name text not null,
  evidence_ids uuid[] not null,
  signals text[] not null,
  status public.suggestion_status not null default 'pending',
  reviewed_at timestamptz,
  constraint suggestion_name_len check (char_length(name) between 1 and 50),
  constraint suggestion_has_evidence check (cardinality(evidence_ids) >= 1),
  constraint suggestion_has_signal check (cardinality(signals) >= 1)
);

create index skill_suggestions_profile_status
  on public.skill_suggestions (profile_id, status);

alter table public.app_settings enable row level security;
alter table public.ai_jobs enable row level security;
alter table public.skill_suggestions enable row level security;

revoke all on table public.app_settings from public, anon, authenticated;
revoke all on table public.ai_jobs from public, anon, authenticated;
revoke all on table public.skill_suggestions from public, anon, authenticated;

grant select on table public.ai_jobs to authenticated;
grant update (seen_at) on table public.ai_jobs to authenticated;
grant select on table public.skill_suggestions to authenticated;

create policy ai_jobs_select_own
  on public.ai_jobs for select to authenticated
  using (profile_id = auth.uid());

create policy ai_jobs_mark_seen
  on public.ai_jobs for update to authenticated
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

create policy skill_suggestions_select_own
  on public.skill_suggestions for select to authenticated
  using (profile_id = auth.uid());

create function public.setting_int(p_key text)
returns integer
language sql
stable
set search_path = public
as $fn$
  select (value #>> '{}')::integer from public.app_settings where key = p_key;
$fn$;

create function public.ai_month_start()
returns timestamptz
language sql
stable
as $fn$
  select date_trunc('month', now() at time zone 'Asia/Ho_Chi_Minh')
    at time zone 'Asia/Ho_Chi_Minh';
$fn$;

create function public.ai_begin_job(p_profile_id uuid, p_kind text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $fn$
declare
  job_kind public.ai_job_kind := p_kind::public.ai_job_kind;
  quota integer;
  used integer;
  timeout_seconds integer;
  new_id uuid;
begin
  if not exists (
    select 1 from public.ai_consents
    where profile_id = p_profile_id and granted
  ) then
    raise exception 'CONSENT_REQUIRED' using errcode = 'P0001';
  end if;

  update public.ai_jobs
  set status = 'timed_out', error_code = 'TIMEOUT', finished_at = now()
  where profile_id = p_profile_id
    and kind = job_kind
    and status in ('queued', 'running')
    and deadline_at < now();

  perform pg_advisory_xact_lock(hashtext('ai:' || p_profile_id::text || p_kind));

  if exists (
    select 1 from public.ai_jobs
    where profile_id = p_profile_id
      and kind = job_kind
      and status in ('queued', 'running')
  ) then
    raise exception 'JOB_ALREADY_RUNNING' using errcode = 'P0001';
  end if;

  quota := public.setting_int(case p_kind
    when 'extract_skills' then 'ai_quota_extract_per_month'
    else 'ai_quota_gap_per_month'
  end);
  select count(*) into used
  from public.ai_jobs
  where profile_id = p_profile_id
    and kind = job_kind
    and created_at >= public.ai_month_start()
    and status in ('queued', 'running', 'succeeded');
  if used >= quota then
    raise exception 'QUOTA_EXCEEDED' using errcode = 'P0001';
  end if;

  if p_kind = 'extract_skills' and not exists (
    select 1 from public.evidence
    where profile_id = p_profile_id and kind = 'github_repo'
  ) then
    raise exception 'NO_SOURCES' using errcode = 'P0001';
  end if;

  timeout_seconds := public.setting_int('ai_timeout_seconds');
  insert into public.ai_jobs (profile_id, kind, status, deadline_at, input)
  values (
    p_profile_id,
    job_kind,
    'queued',
    now() + make_interval(secs => timeout_seconds),
    jsonb_build_object(
      'evidence_ids',
      coalesce((
        select jsonb_agg(id) from public.evidence
        where profile_id = p_profile_id and kind = 'github_repo'
      ), '[]'::jsonb)
    )
  )
  returning id into new_id;
  return jsonb_build_object('job_id', new_id, 'status', 'queued');
end;
$fn$;

create function public.review_suggestion(p_suggestion_id uuid, p_accept boolean)
returns jsonb
language plpgsql
security definer
set search_path = public
as $fn$
declare
  uid uuid := auth.uid();
  suggestion public.skill_suggestions%rowtype;
  skill uuid;
  evidence_id uuid;
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
    return jsonb_build_object('skill_id', null);
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
    end if;
  end loop;
  update public.skill_suggestions
  set status = 'accepted', reviewed_at = now()
  where id = suggestion.id;
  return jsonb_build_object('skill_id', skill);
end;
$fn$;

create function public.get_ai_quota()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $fn$
declare
  uid uuid := auth.uid();
  month_start timestamptz := public.ai_month_start();
begin
  return jsonb_build_object(
    'extract_skills', jsonb_build_object(
      'used', (
        select count(*) from public.ai_jobs
        where profile_id = uid and kind = 'extract_skills'
          and created_at >= month_start
          and status in ('queued', 'running', 'succeeded')
      ),
      'limit', public.setting_int('ai_quota_extract_per_month')
    ),
    'gap_analysis', jsonb_build_object(
      'used', (
        select count(*) from public.ai_jobs
        where profile_id = uid and kind = 'gap_analysis'
          and created_at >= month_start
          and status in ('queued', 'running', 'succeeded')
      ),
      'limit', public.setting_int('ai_quota_gap_per_month')
    ),
    'resets_at', month_start + interval '1 month'
  );
end;
$fn$;

revoke all on function public.setting_int(text) from public, anon, authenticated;
revoke all on function public.ai_month_start() from public, anon, authenticated;
revoke all on function public.ai_begin_job(uuid, text) from public, anon, authenticated;
revoke all on function public.review_suggestion(uuid, boolean) from public, anon;
revoke all on function public.get_ai_quota() from public, anon;
grant execute on function public.ai_begin_job(uuid, text) to service_role;
grant execute on function public.review_suggestion(uuid, boolean) to authenticated;
grant execute on function public.get_ai_quota() to authenticated;
