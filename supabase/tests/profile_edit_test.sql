begin;
select plan(20);

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

set local role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

select results_eq(
  $$update public.profiles
    set display_name = 'Minh',
        bio = 'Flutter dev',
        city_id = (select id from public.cities where code = 'hcm'),
        contact_type = 'linkedin',
        contact_value = 'https://www.linkedin.com/in/minh',
        contact_visible = true
    returning display_name, bio, contact_type::text, contact_value, contact_visible$$,
  $$values ('Minh', 'Flutter dev', 'linkedin', 'https://www.linkedin.com/in/minh', true)$$,
  'owner saves name, bio, city and contact'
);

select is(
  (select c.code from public.profiles p join public.cities c on c.id = p.city_id),
  'hcm',
  'saved city points at a seeded city'
);

select lives_ok(
  $$update public.profiles set bio = repeat('a', 300)$$,
  'bio of exactly 300 characters is accepted'
);

select throws_ok(
  $$update public.profiles set bio = repeat('a', 301)$$,
  '23514',
  null,
  'bio over 300 characters is rejected'
);

select throws_ok(
  $$update public.profiles set city_id = 999$$,
  '23503',
  null,
  'city must come from cities'
);

select throws_ok(
  $$update public.profiles set contact_type = 'email', contact_value = null$$,
  '23514',
  null,
  'contact type without a value is rejected'
);

select throws_ok(
  $$update public.profiles set contact_type = null, contact_value = 'minh@example.com'$$,
  '23514',
  null,
  'contact value without a type is rejected'
);

select throws_ok(
  $$update public.profiles set contact_type = 'email', contact_value = 'not-an-email'$$,
  '23514',
  null,
  'email contact must look like an email'
);

select throws_ok(
  $$update public.profiles
    set contact_type = 'linkedin', contact_value = 'https://evil.example.com/in/minh'$$,
  '23514',
  null,
  'linkedin contact must be a linkedin.com link'
);

select lives_ok(
  $$update public.profiles
    set contact_type = 'email', contact_value = 'minh@example.com'$$,
  'valid email contact is accepted'
);

select lives_ok(
  $$update public.profiles set seniority = 'fresher'$$,
  'owner can set seniority'
);

select throws_ok(
  $$update public.profiles set seniority = 'lead'$$,
  '22P02',
  null,
  'seniority outside intern/fresher/junior/middle is rejected'
);

select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}',
  true
);
select is_empty(
  $$update public.profiles
    set seniority = 'junior'
    where id = '11111111-1111-1111-1111-111111111111'
    returning seniority::text$$,
  'another user cannot change the owner seniority'
);
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

select throws_ok(
  $$update public.profiles set moderation_status = 'removed'$$,
  '42501',
  null,
  'owner cannot write moderation_status'
);

select throws_ok(
  $$update public.profiles set avatar_url = 'https://example.com/a.png'$$,
  '42501',
  null,
  'owner cannot write avatar_url'
);

select throws_ok(
  $$update public.profiles set first_public_at = now()$$,
  '42501',
  null,
  'owner cannot write first_public_at'
);

select throws_ok(
  $$insert into public.profiles (id, display_name, avatar_url)
    values ('11111111-1111-1111-1111-111111111111', 'Minh', 'https://example.com/a.png')$$,
  '42501',
  null,
  'owner cannot insert avatar_url'
);

select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}',
  true
);

select is_empty(
  $$select bio, contact_value from public.profiles
    where id = '11111111-1111-1111-1111-111111111111'$$,
  'another user cannot read the private profile fields'
);

select is_empty(
  $$update public.profiles
    set bio = 'Hacked'
    where id = '11111111-1111-1111-1111-111111111111'
    returning bio$$,
  'another user cannot edit the owner bio'
);

reset role;
select is(
  (
    select visibility::text from public.profiles
    where id = '11111111-1111-1111-1111-111111111111'
  ),
  'private',
  'editing the profile keeps it private'
);

select * from finish();
rollback;
