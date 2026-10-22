begin;
select plan(10);

insert into auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
)
values
  (
    '00000000-0000-0000-0000-000000000000',
    '11111111-1111-1111-1111-111111111111',
    'authenticated',
    'authenticated',
    'owner@example.com',
    crypt('password', gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{}'::jsonb,
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '22222222-2222-2222-2222-222222222222',
    'authenticated',
    'authenticated',
    'other@example.com',
    crypt('password', gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{}'::jsonb,
    now(),
    now()
  );

select is(
  (
    select display_name from public.profiles
    where id = '11111111-1111-1111-1111-111111111111'
  ),
  'owner',
  'signup trigger creates a private profile named from the email'
);

select is(
  (
    select visibility::text from public.profiles
    where id = '11111111-1111-1111-1111-111111111111'
  ),
  'private',
  'new profile is private'
);

set local role anon;
select throws_ok(
  $$select * from public.profiles$$,
  '42501',
  null,
  'anon cannot read profiles'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

select results_eq(
  $$select display_name from public.profiles$$,
  array['owner'],
  'owner reads their own profile'
);

select results_eq(
  $$update public.profiles set display_name = 'Minh' returning display_name$$,
  array['Minh'],
  'owner updates display_name'
);

select throws_ok(
  $$update public.profiles set moderation_status = 'removed'$$,
  '42501',
  null,
  'owner cannot write moderation_status'
);

select throws_ok(
  $$delete from public.profiles$$,
  '42501',
  null,
  'owner cannot delete their profile'
);

select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}',
  true
);

select is_empty(
  $$select * from public.profiles
    where id = '11111111-1111-1111-1111-111111111111'$$,
  'another user cannot read the owner profile'
);

select is_empty(
  $$update public.profiles
    set display_name = 'Hacked'
    where id = '11111111-1111-1111-1111-111111111111'
    returning display_name$$,
  'another user cannot update the owner profile'
);

reset role;
select results_eq(
  $$select display_name from public.profiles
    where id = '11111111-1111-1111-1111-111111111111'$$,
  array['Minh'],
  'denied writes left the owner row intact'
);

select * from finish();
rollback;
