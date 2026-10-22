-- Ticket 02 follow-up: seniority on profiles (DATA_MODEL 4.1, shared with F-015).

create type public.seniority_level as enum ('intern', 'fresher', 'junior', 'middle');

alter table public.profiles
  add column seniority public.seniority_level;

grant usage on type public.seniority_level to authenticated;
grant insert (seniority) on table public.profiles to authenticated;
grant update (seniority) on table public.profiles to authenticated;
