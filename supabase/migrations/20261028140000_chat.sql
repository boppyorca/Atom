-- Ticket F-025: chat with a local model first, then free Groq, then free Z.ai.
-- Accept and reject stay on this machine so Ollama can learn them.

insert into public.app_settings (key, value)
values ('chat_quota_per_month', '30')
on conflict (key) do nothing;

create table public.chat_threads (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.chat_threads (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  role text not null,
  body text not null,
  provider text,
  created_at timestamptz not null default now(),
  constraint chat_messages_role check (role in ('user', 'assistant')),
  constraint chat_messages_body_len check (char_length(body) between 1 and 4000),
  constraint chat_messages_provider check (
    provider is null or provider in ('ollama', 'groq', 'zai')
  )
);

create table public.chat_proposals (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.chat_messages (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  detail text not null default '',
  status public.suggestion_status not null default 'pending',
  reviewed_at timestamptz,
  constraint chat_proposals_title_len check (char_length(title) between 1 and 50),
  constraint chat_proposals_detail_len check (char_length(detail) <= 500)
);

create index chat_messages_profile_created
  on public.chat_messages (profile_id, created_at);

alter table public.chat_threads enable row level security;
alter table public.chat_messages enable row level security;
alter table public.chat_proposals enable row level security;

revoke all on table public.chat_threads from public, anon, authenticated;
revoke all on table public.chat_messages from public, anon, authenticated;
revoke all on table public.chat_proposals from public, anon, authenticated;
grant select on table public.chat_threads to authenticated;
grant select on table public.chat_messages to authenticated;
grant select on table public.chat_proposals to authenticated;

create policy chat_threads_select_own
  on public.chat_threads for select to authenticated
  using (profile_id = auth.uid());

create policy chat_messages_select_own
  on public.chat_messages for select to authenticated
  using (profile_id = auth.uid());

create policy chat_proposals_select_own
  on public.chat_proposals for select to authenticated
  using (profile_id = auth.uid());

create function public.chat_gate(p_profile_id uuid, p_text text)
returns void
language plpgsql
security definer
set search_path = public
as $fn$
declare
  clean text := btrim(coalesce(p_text, ''));
  used integer;
  quota integer;
begin
  if char_length(clean) < 1 or char_length(clean) > 4000 then
    raise exception 'INPUT_INVALID' using errcode = 'P0001';
  end if;
  if not exists (
    select 1 from public.ai_consents
    where profile_id = p_profile_id and granted
  ) then
    raise exception 'CONSENT_REQUIRED' using errcode = 'P0001';
  end if;
  quota := public.setting_int('chat_quota_per_month');
  select count(*) into used
  from public.chat_messages
  where profile_id = p_profile_id
    and role = 'user'
    and created_at >= public.ai_month_start();
  if used >= quota then
    raise exception 'QUOTA_EXCEEDED' using errcode = 'P0001';
  end if;
end;
$fn$;

create function public.review_chat_proposal(p_id uuid, p_accept boolean)
returns jsonb
language plpgsql
security definer
set search_path = public
as $fn$
declare
  uid uuid := auth.uid();
  proposal public.chat_proposals%rowtype;
begin
  select * into proposal
  from public.chat_proposals
  where id = p_id
  for update;
  if not found or proposal.profile_id is distinct from uid then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;
  if proposal.status <> 'pending' then
    raise exception 'ALREADY_REVIEWED' using errcode = 'P0001';
  end if;
  if p_accept and not exists (
    select 1 from public.skills
    where profile_id = uid
      and name_normalized = lower(regexp_replace(btrim(proposal.title), '\s+', ' ', 'g'))
  ) then
    insert into public.skills (profile_id, name)
    values (uid, proposal.title);
  end if;
  update public.chat_proposals
  set status = case when p_accept then 'accepted'::public.suggestion_status else 'rejected'::public.suggestion_status end,
      reviewed_at = now()
  where id = proposal.id;
  return jsonb_build_object('status', case when p_accept then 'accepted' else 'rejected' end);
end;
$fn$;

revoke all on function public.chat_gate(uuid, text) from public, anon, authenticated;
grant execute on function public.chat_gate(uuid, text) to service_role;
revoke all on function public.review_chat_proposal(uuid, boolean) from public, anon;
grant execute on function public.review_chat_proposal(uuid, boolean) to authenticated;
