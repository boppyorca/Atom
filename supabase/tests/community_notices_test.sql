begin;
select plan(7);

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

update public.profiles
set display_name = 'Minh', visibility = 'public'
where id = '11111111-1111-1111-1111-111111111111';

update public.profiles
set display_name = 'Lan', visibility = 'public'
where id = '22222222-2222-2222-2222-222222222222';

insert into public.notices (profile_id, kind)
values ('11111111-1111-1111-1111-111111111111', 'gap_ready');

set local role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

select is(
  (select count(*) from public.notices),
  1::bigint,
  'the owner can read a notice'
);

select lives_ok(
  $$select set_config('test.post_id', (public.add_post('Xin chào')->>'id'), true)$$,
  'a person can publish a post'
);

select throws_ok(
  $$select public.report_post(current_setting('test.post_id')::uuid, 'spam')$$,
  'P0001',
  'CANNOT_REPORT_SELF',
  'a person cannot report their own post'
);

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}',
  true
);

select is(
  (select count(*) from public.notices),
  0::bigint,
  'another person cannot read the notice'
);

select lives_ok(
  $$select public.add_post('Mình là Lan')$$,
  'a second person can publish'
);

select ok(
  (select jsonb_array_length(public.list_feed()) = 2),
  'both public posts are visible before a block'
);

reset role;
insert into public.blocks (blocker_id, blocked_id)
values (
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

select ok(
  (select jsonb_array_length(public.list_feed()) = 1),
  'a blocked person disappears from the feed'
);

select * from finish();
rollback;
