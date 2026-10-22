begin;
select plan(12);

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at
)
select
  '00000000-0000-0000-0000-000000000000',
  ('00000000-0000-0000-0000-' || lpad(g::text, 12, '0'))::uuid,
  'authenticated',
  'authenticated',
  'salary' || g || '@example.com',
  crypt('password', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{}'::jsonb,
  now(),
  now()
from generate_series(1, 7) as g;

select results_eq(
  $$select code from public.salary_roles order by id$$,
  array[
    'mobile_developer',
    'frontend_developer',
    'backend_developer',
    'fullstack_developer',
    'qa_tester',
    'data_ai',
    'devops',
    'other'
  ],
  'salary roles are the fixed list'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-000000000001","role":"authenticated"}',
  true
);

select throws_ok(
  $$select public.get_salary_aggregate(1, 2, 'fresher'::public.seniority_level)$$,
  'P0001',
  'CONTRIBUTION_REQUIRED',
  'a person who has not contributed cannot see totals'
);

reset role;

insert into public.salary_entries (profile_id, role_id, city_id, seniority, gross_monthly_vnd)
values
  ('00000000-0000-0000-0000-000000000001', 8, 5, 'intern', 5000000);

insert into public.salary_entries (profile_id, role_id, city_id, seniority, gross_monthly_vnd)
select
  ('00000000-0000-0000-0000-' || lpad(g::text, 12, '0'))::uuid,
  1, 2, 'fresher', 10000000
from generate_series(2, 5) as g;

insert into public.salary_entries (profile_id, role_id, city_id, seniority, gross_monthly_vnd)
values
  ('00000000-0000-0000-0000-000000000002', 1, 1, 'junior', 10000000),
  ('00000000-0000-0000-0000-000000000003', 1, 1, 'junior', 12000000),
  ('00000000-0000-0000-0000-000000000004', 1, 1, 'junior', 14000000),
  ('00000000-0000-0000-0000-000000000005', 1, 1, 'junior', 16000000),
  ('00000000-0000-0000-0000-000000000006', 1, 1, 'junior', 18000000),
  ('00000000-0000-0000-0000-000000000002', 2, 2, 'middle', 10000000),
  ('00000000-0000-0000-0000-000000000003', 2, 2, 'middle', 11000000),
  ('00000000-0000-0000-0000-000000000004', 2, 2, 'middle', 12500000),
  ('00000000-0000-0000-0000-000000000005', 2, 2, 'middle', 15000000),
  ('00000000-0000-0000-0000-000000000006', 2, 2, 'middle', 20000000),
  ('00000000-0000-0000-0000-000000000007', 2, 2, 'middle', 30000000),
  ('00000000-0000-0000-0000-000000000002', 3, 3, 'fresher', 10000000),
  ('00000000-0000-0000-0000-000000000003', 3, 3, 'fresher', 10000000),
  ('00000000-0000-0000-0000-000000000004', 3, 3, 'fresher', 10000000),
  ('00000000-0000-0000-0000-000000000005', 3, 3, 'fresher', 10000000),
  ('00000000-0000-0000-0000-000000000006', 3, 3, 'fresher', 10000000);

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-000000000001","role":"authenticated"}',
  true
);

select is(
  public.get_salary_aggregate(1, 2, 'fresher'::public.seniority_level),
  '{"status":"insufficient_data"}'::jsonb,
  'four entries are not enough'
);

select is(
  public.get_salary_aggregate(1, 1, 'junior'::public.seniority_level),
  '{"status":"ok","p25_vnd":12000000,"median_vnd":14000000,"p75_vnd":16000000}'::jsonb,
  'five even salaries match the sample'
);

select ok(
  not (public.get_salary_aggregate(1, 1, 'junior'::public.seniority_level) ? 'n'),
  'the total does not include how many entries were used'
);

select is(
  public.get_salary_aggregate(2, 2, 'middle'::public.seniority_level),
  '{"status":"ok","p25_vnd":11400000,"median_vnd":13800000,"p75_vnd":18800000}'::jsonb,
  'percentiles are rounded to the nearest 100000'
);

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000002', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-000000000002","role":"authenticated"}',
  true
);

select lives_ok(
  $$delete from public.salary_entries
    where profile_id = '00000000-0000-0000-0000-000000000002'
      and role_id = 3$$,
  'a person can delete their own entry'
);

select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-000000000001","role":"authenticated"}',
  true
);

select is(
  public.get_salary_aggregate(3, 3, 'fresher'::public.seniority_level),
  '{"status":"insufficient_data"}'::jsonb,
  'deleting one entry drops the group below five'
);

select is_empty(
  $$select id from public.salary_entries
    where profile_id = '00000000-0000-0000-0000-000000000002'$$,
  'another person cannot read someone else''s entry'
);

select throws_ok(
  $$insert into public.salary_entries (profile_id, role_id, city_id, seniority, gross_monthly_vnd)
    values ('00000000-0000-0000-0000-000000000001', 8, 5, 'intern', 5000000)$$,
  '23505',
  null,
  'the same job cannot be added twice'
);

select throws_ok(
  $$insert into public.salary_entries (profile_id, role_id, city_id, seniority, gross_monthly_vnd)
    values ('00000000-0000-0000-0000-000000000001', 8, 4, 'intern', 100)$$,
  '23514',
  null,
  'a salary outside the allowed range is rejected'
);

set local role anon;
select throws_ok(
  $$select count(*) from public.salary_entries$$,
  '42501',
  null,
  'anon cannot read salaries'
);

select * from finish();
rollback;
