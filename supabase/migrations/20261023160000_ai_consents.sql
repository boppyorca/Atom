-- Ticket 14: analysis consent (DATA_MODEL 4.7). No row means not answered.

create table public.ai_consents (
  profile_id uuid primary key references public.profiles (id) on delete cascade,
  granted boolean not null,
  updated_at timestamptz not null default now()
);

alter table public.ai_consents enable row level security;

revoke all on table public.ai_consents from public, anon, authenticated;
grant select, insert, update on table public.ai_consents to authenticated;

create policy ai_consents_own
  on public.ai_consents
  for all
  to authenticated
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

create trigger ai_consents_set_updated_at
  before update on public.ai_consents
  for each row
  execute function public.set_updated_at();
