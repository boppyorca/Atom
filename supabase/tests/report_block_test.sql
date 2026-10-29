begin;
select plan(8);

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
set display_name = 'Lan', visibility = 'public'
where id = '22222222-2222-2222-2222-222222222222';

insert into public.skills (profile_id, name)
values ('22222222-2222-2222-2222-222222222222', 'Flutter');

select set_config(
  'test.skill_id',
  (select id::text from public.skills
    where profile_id = '22222222-2222-2222-2222-222222222222'),
  true
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

select throws_ok(
  $$insert into public.reports (reporter_id, profile_id, reason)
    values (auth.uid(), auth.uid(), 'spam')$$,
  '42501',
  null,
  'a person cannot report themselves'
);

select lives_ok(
  $$insert into public.reports (reporter_id, profile_id, reason)
    values (auth.uid(), '22222222-2222-2222-2222-222222222222', 'spam')$$,
  'a report is saved'
);

select ok(
  (select jsonb_array_length(public.search_profiles('flu')) = 1),
  'a public profile is found before a block'
);

select lives_ok(
  $$insert into public.blocks (blocker_id, blocked_id)
    values (auth.uid(), '22222222-2222-2222-2222-222222222222')$$,
  'a block is saved'
);

select is(
  public.get_public_profile('22222222-2222-2222-2222-222222222222'),
  null,
  'the blocker cannot open the blocked profile'
);

select ok(
  (select jsonb_array_length(public.search_profiles('flu')) = 0),
  'a blocked profile disappears from search'
);

select throws_ok(
  $$select public.endorse_skill(current_setting('test.skill_id')::uuid)$$,
  'P0001',
  'NOT_FOUND',
  'a blocked profile cannot be endorsed'
);

reset role;
update public.profiles
set moderation_status = 'removed'
where id = '22222222-2222-2222-2222-222222222222';

select ok(
  (select count(*) = 1 from public.moderation_log
    where profile_id = '22222222-2222-2222-2222-222222222222'
      and new_status = 'removed'),
  'removing a profile is written to the log'
);

select * from finish();
rollback;
