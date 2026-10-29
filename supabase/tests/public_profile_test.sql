begin;
select plan(6);

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

select is(
  public.get_public_profile('11111111-1111-1111-1111-111111111111'),
  null,
  'a private profile is not visible'
);

update public.profiles
set visibility = 'public',
  contact_type = 'email',
  contact_value = 'secret@example.com',
  contact_visible = false
where id = '11111111-1111-1111-1111-111111111111';

select ok(
  (select first_public_at is not null from public.profiles
    where id = '11111111-1111-1111-1111-111111111111'),
  'the first time a profile is public, the time is recorded'
);

set local role anon;
select ok(
  (select public.get_public_profile('11111111-1111-1111-1111-111111111111') ->> 'display_name') is not null,
  'a signed-out visitor can read a public profile'
);
select ok(
  (select public.get_public_profile('11111111-1111-1111-1111-111111111111') -> 'contact') = 'null'::jsonb,
  'contact stays hidden until the owner shows it'
);
select throws_ok(
  $$select public.get_ai_quota()$$,
  '42501',
  null,
  'a signed-out visitor cannot call a private function'
);

reset role;
update public.profiles
set moderation_status = 'removed'
where id = '11111111-1111-1111-1111-111111111111';

select is(
  public.get_public_profile('11111111-1111-1111-1111-111111111111'),
  null,
  'a removed profile looks the same as a missing one'
);

select * from finish();
rollback;
