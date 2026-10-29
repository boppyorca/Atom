begin;
select plan(4);

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
(
  '00000000-0000-0000-0000-000000000000',
  '11111111-1111-1111-1111-111111111111',
  'authenticated', 'authenticated', 'a@example.com',
  crypt('password', gen_salt('bf')), now(),
  '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()
),
(
  '00000000-0000-0000-0000-000000000000',
  '22222222-2222-2222-2222-222222222222',
  'authenticated', 'authenticated', 'b@example.com',
  crypt('password', gen_salt('bf')), now(),
  '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()
);

insert into public.ai_consents (profile_id, granted)
values ('11111111-1111-1111-1111-111111111111', true);

select throws_ok(
  $$select public.ai_begin_job('11111111-1111-1111-1111-111111111111', 'gap_analysis')$$,
  'P0001',
  'NO_SKILLS',
  'gap analysis refuses a profile with no skills'
);

insert into public.skills (profile_id, name)
values ('11111111-1111-1111-1111-111111111111', 'Flutter');

select lives_ok(
  $$select public.ai_begin_job('11111111-1111-1111-1111-111111111111', 'gap_analysis')$$,
  'gap analysis starts after the person has a skill'
);

select is(
  (select input from public.ai_jobs
    where profile_id = '11111111-1111-1111-1111-111111111111'
      and kind = 'gap_analysis'),
  '{}'::jsonb,
  'the pasted job text is not stored'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}',
  true
);

select is(
  (select count(*) from public.ai_jobs),
  0::bigint,
  'another person cannot read the gap result'
);

select * from finish();
rollback;
