-- Ticket 16 plus a small community and in-app notices.
-- Replaces ai_begin_job so a gap run refuses an empty skill list.
-- Does not store the pasted job text.

create or replace function public.ai_begin_job(p_profile_id uuid, p_kind text)
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
  job_input jsonb;
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

  if p_kind = 'gap_analysis' and not exists (
    select 1 from public.skills where profile_id = p_profile_id
  ) then
    raise exception 'NO_SKILLS' using errcode = 'P0001';
  end if;

  timeout_seconds := public.setting_int('ai_timeout_seconds');
  if p_kind = 'extract_skills' then
    job_input := jsonb_build_object(
      'evidence_ids',
      coalesce((
        select jsonb_agg(id) from public.evidence
        where profile_id = p_profile_id and kind = 'github_repo'
      ), '[]'::jsonb)
    );
  else
    job_input := '{}'::jsonb;
  end if;

  insert into public.ai_jobs (profile_id, kind, status, deadline_at, input)
  values (
    p_profile_id,
    job_kind,
    'queued',
    now() + make_interval(secs => timeout_seconds),
    job_input
  )
  returning id into new_id;
  return jsonb_build_object('job_id', new_id, 'status', 'queued');
end;
$fn$;

create table public.notices (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  kind text not null,
  created_at timestamptz not null default now(),
  seen_at timestamptz,
  constraint notices_kind check (kind in ('gap_ready'))
);

alter table public.notices enable row level security;
revoke all on table public.notices from public, anon, authenticated;
grant select, update (seen_at) on table public.notices to authenticated;

create policy notices_select_own
  on public.notices for select to authenticated
  using (profile_id = auth.uid());

create policy notices_mark_seen
  on public.notices for update to authenticated
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

create table public.posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles (id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now(),
  constraint posts_body_len check (char_length(body) between 1 and 500)
);

create table public.post_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts (id) on delete cascade,
  author_id uuid not null references public.profiles (id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now(),
  constraint post_comments_body_len check (char_length(body) between 1 and 300)
);

create table public.post_likes (
  post_id uuid not null references public.posts (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, profile_id)
);

create table public.post_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid references public.profiles (id) on delete set null,
  post_id uuid not null references public.posts (id) on delete cascade,
  reason text not null,
  created_at timestamptz not null default now(),
  constraint post_reports_reason_len check (char_length(reason) between 1 and 500)
);

alter table public.posts enable row level security;
alter table public.post_comments enable row level security;
alter table public.post_likes enable row level security;
alter table public.post_reports enable row level security;
revoke all on table public.posts from public, anon, authenticated;
revoke all on table public.post_comments from public, anon, authenticated;
revoke all on table public.post_likes from public, anon, authenticated;
revoke all on table public.post_reports from public, anon, authenticated;

create function public.post_visible(p_author uuid, p_viewer uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $fn$
  select p_viewer is not null and (
    p_author = p_viewer
    or (
      exists (
        select 1 from public.profiles
        where id = p_author
          and visibility = 'public'
          and moderation_status = 'active'
      )
      and not exists (
        select 1 from public.blocks
        where (blocker_id = p_viewer and blocked_id = p_author)
          or (blocker_id = p_author and blocked_id = p_viewer)
      )
    )
  );
$fn$;

create function public.list_feed()
returns jsonb
language sql
stable
security definer
set search_path = public
as $fn$
  select coalesce(jsonb_agg(to_jsonb(item) order by item.created_at desc), '[]'::jsonb)
  from (
    select
      posts.id,
      posts.body,
      posts.created_at,
      profiles.display_name as author_name,
      (select count(*) from public.post_likes where post_id = posts.id) as like_count,
      exists (
        select 1 from public.post_likes
        where post_id = posts.id and profile_id = auth.uid()
      ) as liked
    from public.posts
    join public.profiles on profiles.id = posts.author_id
    where public.post_visible(posts.author_id, auth.uid())
    order by posts.created_at desc
    limit 30
  ) item;
$fn$;

create function public.add_post(p_body text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $fn$
declare
  new_id uuid;
  clean text := btrim(coalesce(p_body, ''));
begin
  if auth.uid() is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;
  if char_length(clean) < 1 or char_length(clean) > 500 then
    raise exception 'INPUT_INVALID' using errcode = 'P0001';
  end if;
  insert into public.posts (author_id, body)
  values (auth.uid(), clean)
  returning id into new_id;
  return jsonb_build_object('id', new_id);
end;
$fn$;

create function public.add_comment(p_post_id uuid, p_body text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $fn$
declare
  author uuid;
  new_id uuid;
  clean text := btrim(coalesce(p_body, ''));
begin
  select author_id into author from public.posts where id = p_post_id;
  if author is null or not public.post_visible(author, auth.uid()) then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;
  if char_length(clean) < 1 or char_length(clean) > 300 then
    raise exception 'INPUT_INVALID' using errcode = 'P0001';
  end if;
  insert into public.post_comments (post_id, author_id, body)
  values (p_post_id, auth.uid(), clean)
  returning id into new_id;
  return jsonb_build_object('id', new_id);
end;
$fn$;

create function public.toggle_like(p_post_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $fn$
declare
  author uuid;
begin
  select author_id into author from public.posts where id = p_post_id;
  if author is null or not public.post_visible(author, auth.uid()) then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;
  if exists (
    select 1 from public.post_likes
    where post_id = p_post_id and profile_id = auth.uid()
  ) then
    delete from public.post_likes
    where post_id = p_post_id and profile_id = auth.uid();
    return jsonb_build_object('liked', false);
  end if;
  insert into public.post_likes (post_id, profile_id)
  values (p_post_id, auth.uid());
  return jsonb_build_object('liked', true);
end;
$fn$;

create function public.report_post(p_post_id uuid, p_reason text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $fn$
declare
  author uuid;
  clean text := btrim(coalesce(p_reason, ''));
begin
  select author_id into author from public.posts where id = p_post_id;
  if author is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;
  if author = auth.uid() then
    raise exception 'CANNOT_REPORT_SELF' using errcode = 'P0001';
  end if;
  if char_length(clean) < 1 or char_length(clean) > 500 then
    raise exception 'INPUT_INVALID' using errcode = 'P0001';
  end if;
  insert into public.post_reports (reporter_id, post_id, reason)
  values (auth.uid(), p_post_id, clean);
  return jsonb_build_object('reported', true);
end;
$fn$;

revoke all on function public.post_visible(uuid, uuid) from public, anon, authenticated;
revoke all on function public.list_feed() from public, anon;
revoke all on function public.add_post(text) from public, anon;
revoke all on function public.add_comment(uuid, text) from public, anon;
revoke all on function public.toggle_like(uuid) from public, anon;
revoke all on function public.report_post(uuid, text) from public, anon;
grant execute on function public.list_feed() to authenticated;
grant execute on function public.add_post(text) to authenticated;
grant execute on function public.add_comment(uuid, text) to authenticated;
grant execute on function public.toggle_like(uuid) to authenticated;
grant execute on function public.report_post(uuid, text) to authenticated;
