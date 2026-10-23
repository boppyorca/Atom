begin;
select plan(7);

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
  $$insert into public.ai_consents (profile_id, granted)
    values (auth.uid(), true)
    returning granted$$,
  $$values (true)$$,
  'the owner records consent'
);

select results_eq(
  $$update public.ai_consents set granted = false returning granted$$,
  $$values (false)$$,
  'the owner can withdraw consent'
);

select throws_ok(
  $$delete from public.ai_consents$$,
  '42501',
  null,
  'the owner cannot delete the consent row'
);

select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}',
  true
);

select is_empty(
  $$select granted from public.ai_consents$$,
  'another person cannot read the consent'
);

select throws_ok(
  $$insert into public.ai_consents (profile_id, granted)
    values ('11111111-1111-1111-1111-111111111111', true)$$,
  '42501',
  null,
  'another person cannot write this consent'
);

select is_empty(
  $$update public.ai_consents set granted = true returning profile_id$$,
  'another person cannot change this consent'
);

set local role anon;
select throws_ok(
  $$select count(*) from public.ai_consents$$,
  '42501',
  null,
  'anon cannot read consent'
);

select * from finish();
rollback;
