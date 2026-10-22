begin;
select plan(10);

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at
)
values
  (
    '00000000-0000-0000-0000-000000000000',
    '11111111-1111-1111-1111-111111111111',
    'authenticated', 'authenticated', 'owner@example.com',
    crypt('password', gen_salt('bf')), now(),
    '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb,
    now(), now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '22222222-2222-2222-2222-222222222222',
    'authenticated', 'authenticated', 'other@example.com',
    crypt('password', gen_salt('bf')), now(),
    '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb,
    now(), now()
  );

set local role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

select results_eq(
  $$insert into public.skills (profile_id, name)
    values (auth.uid(), 'Flutter')
    returning confidence::text$$,
  $$values ('self_claimed')$$,
  'a new skill is self-claimed'
);

select throws_ok(
  $$insert into public.skills (profile_id, name) values (auth.uid(), ' flutter ')$$,
  '23505',
  null,
  'the same name on one profile is rejected'
);

select throws_ok(
  $$insert into public.skills (profile_id, name, confidence)
    values (auth.uid(), 'Dart', 'endorsed')$$,
  '42501',
  null,
  'the user cannot set confidence'
);

select throws_ok(
  $$update public.skills set confidence = 'endorsed'$$,
  '42501',
  null,
  'the user cannot change confidence'
);

select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}',
  true
);

select is_empty(
  $$select id from public.skills$$,
  'another user cannot read the skill'
);

select is_empty(
  $$delete from public.skills
    where profile_id = '11111111-1111-1111-1111-111111111111'
    returning id$$,
  'another user cannot delete the skill'
);

select throws_ok(
  $$insert into public.skills (profile_id, name)
    values ('11111111-1111-1111-1111-111111111111', 'Sneaky')$$,
  '42501',
  null,
  'another user cannot add a skill to this profile'
);

set local role anon;
select throws_ok(
  $$select count(*) from public.skills$$,
  '42501',
  null,
  'anon cannot read skills'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

select results_eq(
  $$delete from public.skills where name = 'Flutter' returning name$$,
  $$values ('Flutter')$$,
  'the owner can delete their skill'
);

select throws_ok(
  $fn$
    insert into public.skills (profile_id, name)
    select auth.uid(), 'Skill ' || g
    from generate_series(1, 51) as g
  $fn$,
  'P0001',
  null,
  'a profile cannot have more than 50 skills'
);

select * from finish();
rollback;
