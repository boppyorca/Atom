begin;
select plan(6);

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

insert into public.chat_threads (id, profile_id)
values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111');

insert into public.chat_messages (id, thread_id, profile_id, role, body, provider)
values (
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  '11111111-1111-1111-1111-111111111111',
  'assistant',
  'Bạn đã có Flutter.',
  'ollama'
);

insert into public.chat_proposals (id, message_id, profile_id, title, detail)
values
(
  'cccccccc-cccc-cccc-cccc-cccccccccccc',
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  '11111111-1111-1111-1111-111111111111',
  'CI/CD',
  'Thêm một bước.'
),
(
  'dddddddd-dddd-dddd-dddd-dddddddddddd',
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  '11111111-1111-1111-1111-111111111111',
  'Docker',
  'Đóng gói app.'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}',
  true
);

select is(
  (select count(*) from public.chat_messages),
  0::bigint,
  'another person cannot read the chat'
);

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

select lives_ok(
  $$select public.review_chat_proposal('cccccccc-cccc-cccc-cccc-cccccccccccc', false)$$,
  'a rejected suggestion is saved'
);

select is(
  (select count(*) from public.skills
    where profile_id = '11111111-1111-1111-1111-111111111111'
      and name = 'CI/CD'),
  0::bigint,
  'reject does not create a skill'
);

select lives_ok(
  $$select public.review_chat_proposal('dddddddd-dddd-dddd-dddd-dddddddddddd', true)$$,
  'an accepted suggestion is saved'
);

select is(
  (select count(*) from public.skills
    where profile_id = '11111111-1111-1111-1111-111111111111'
      and name = 'Docker'),
  1::bigint,
  'accept adds the skill'
);

select throws_ok(
  $$select public.review_chat_proposal('dddddddd-dddd-dddd-dddd-dddddddddddd', true)$$,
  'P0001',
  'ALREADY_REVIEWED',
  'a suggestion cannot be reviewed twice'
);

select * from finish();
rollback;
