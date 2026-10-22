-- Ticket 13: anonymous salary entries and the aggregate (DATA_MODEL 4.10, 4.11, ALG-07).

create table public.salary_roles (
  id smallint primary key,
  code text unique not null,
  label_vi text not null,
  label_en text not null
);

insert into public.salary_roles (id, code, label_vi, label_en)
values
  (1, 'mobile_developer', 'Mobile developer', 'Mobile developer'),
  (2, 'frontend_developer', 'Frontend developer', 'Frontend developer'),
  (3, 'backend_developer', 'Backend developer', 'Backend developer'),
  (4, 'fullstack_developer', 'Fullstack developer', 'Fullstack developer'),
  (5, 'qa_tester', 'QA/Tester', 'QA/Tester'),
  (6, 'data_ai', 'Data/AI', 'Data/AI'),
  (7, 'devops', 'DevOps', 'DevOps'),
  (8, 'other', 'Khác', 'Other');

alter table public.salary_roles enable row level security;
revoke all on table public.salary_roles from public, anon, authenticated;
grant select on table public.salary_roles to authenticated;

create policy salary_roles_select_all
  on public.salary_roles
  for select
  to authenticated
  using (true);

create table public.salary_entries (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  role_id smallint not null references public.salary_roles (id),
  city_id smallint not null references public.cities (id),
  seniority public.seniority_level not null,
  gross_monthly_vnd bigint not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint salary_amount_range check (
    gross_monthly_vnd between 1000000 and 500000000
  ),
  constraint salary_one_per_job unique (profile_id, role_id, city_id, seniority)
);

create index salary_entries_group
  on public.salary_entries (role_id, city_id, seniority);

alter table public.salary_entries enable row level security;
revoke all on table public.salary_entries from public, anon, authenticated;
grant select, insert, update, delete on table public.salary_entries to authenticated;

create policy salary_entries_own
  on public.salary_entries
  for all
  to authenticated
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

create function public.limit_salary_entries()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if (
    select count(*)
    from public.salary_entries
    where profile_id = new.profile_id
  ) >= 5 then
    raise exception 'SALARY_LIMIT' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

create trigger salary_entries_limit
  before insert on public.salary_entries
  for each row
  execute function public.limit_salary_entries();

revoke all on function public.limit_salary_entries() from public;
revoke execute on function public.limit_salary_entries() from anon, authenticated;

-- Sample size is 5 (D-030). The function reads every row in the group, so it
-- bypasses row security, and it returns only rounded totals.
create function public.get_salary_aggregate(
  p_role_id integer,
  p_city_id integer,
  p_seniority public.seniority_level
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  sample_size int;
  p25 numeric;
  p50 numeric;
  p75 numeric;
begin
  if auth.uid() is null then
    raise exception 'UNAUTHORIZED' using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.salary_entries where profile_id = auth.uid()
  ) then
    raise exception 'CONTRIBUTION_REQUIRED' using errcode = 'P0001';
  end if;

  select
    count(*),
    percentile_cont(0.25) within group (order by gross_monthly_vnd),
    percentile_cont(0.5) within group (order by gross_monthly_vnd),
    percentile_cont(0.75) within group (order by gross_monthly_vnd)
  into sample_size, p25, p50, p75
  from public.salary_entries
  where role_id = p_role_id
    and city_id = p_city_id
    and seniority = p_seniority;

  if sample_size < 5 then
    return jsonb_build_object('status', 'insufficient_data');
  end if;

  return jsonb_build_object(
    'status', 'ok',
    'p25_vnd', (round(p25 / 100000) * 100000)::bigint,
    'median_vnd', (round(p50 / 100000) * 100000)::bigint,
    'p75_vnd', (round(p75 / 100000) * 100000)::bigint
  );
end;
$$;

revoke all on function public.get_salary_aggregate(integer, integer, public.seniority_level) from public;
revoke execute on function public.get_salary_aggregate(integer, integer, public.seniority_level) from anon;
grant execute on function public.get_salary_aggregate(integer, integer, public.seniority_level) to authenticated;
