begin;
select plan(4);

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values (
  '00000000-0000-0000-0000-000000000000',
  '11111111-1111-1111-1111-111111111111',
  'authenticated', 'authenticated', 'owner@example.com',
  crypt('password', gen_salt('bf')), now(),
  '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()
);

insert into public.skills (profile_id, name)
values ('11111111-1111-1111-1111-111111111111', 'Flutter');

insert into public.evidence (profile_id, kind, url, title)
values (
  '11111111-1111-1111-1111-111111111111',
  'article',
  'https://example.com/note',
  'Note'
);

insert into public.salary_entries (
  profile_id, role_id, city_id, seniority, gross_monthly_vnd
) values (
  '11111111-1111-1111-1111-111111111111',
  1, 1, 'fresher', 15000000
);

insert into public.ai_consents (profile_id, granted)
values ('11111111-1111-1111-1111-111111111111', true);

delete from auth.users where id = '11111111-1111-1111-1111-111111111111';

select is_empty(
  $$select 1 from public.profiles where id = '11111111-1111-1111-1111-111111111111'$$,
  'the profile is gone'
);
select is_empty(
  $$select 1 from public.skills where profile_id = '11111111-1111-1111-1111-111111111111'$$,
  'skills are gone'
);
select is_empty(
  $$select 1 from public.evidence where profile_id = '11111111-1111-1111-1111-111111111111'$$,
  'evidence is gone'
);
select is_empty(
  $$select 1 from public.salary_entries where profile_id = '11111111-1111-1111-1111-111111111111'$$,
  'the salary entry is gone'
);

select * from finish();
rollback;
