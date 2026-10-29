begin;
select plan(6);

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values (
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
);

insert into auth.identities (
  provider_id, user_id, identity_data, provider, created_at, updated_at
)
values (
  'gh-1',
  '11111111-1111-1111-1111-111111111111',
  '{"user_name":"minh-dev"}'::jsonb,
  'github',
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
  $$select public.connect_github()->>'github_username'$$,
  $$values ('minh-dev')$$,
  'connect_github reads the GitHub user name from the identity'
);

select throws_ok(
  $$insert into public.evidence (profile_id, kind, url, github_full_name)
    values (auth.uid(), 'github_repo', 'https://github.com/minh-dev/todo', 'minh-dev/todo')$$,
  '42501',
  null,
  'the signed-in person cannot insert a repo row directly'
);

reset role;
select public.save_github_repos(
  '11111111-1111-1111-1111-111111111111',
  '[{"full_name":"minh-dev/todo","url":"https://github.com/minh-dev/todo","title":"todo","is_fork":false}]'::jsonb
);

insert into public.skills (profile_id, name)
values ('11111111-1111-1111-1111-111111111111', 'Flutter');

insert into public.skill_evidence (skill_id, evidence_id)
select skills.id, evidence.id
from public.skills
join public.evidence on evidence.profile_id = skills.profile_id
where skills.name = 'Flutter';

-- Changed on purpose: linking a repo without commit statistics only stores a
-- weak signal, so the level stays self_claimed.
select results_eq(
  $$select confidence::text from public.skills where name = 'Flutter'$$,
  $$values ('self_claimed')$$,
  'attaching a repo without commit statistics stays self-claimed'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

select lives_ok(
  $$delete from public.github_connections where profile_id = auth.uid()$$,
  'the owner can disconnect GitHub'
);

reset role;
select is_empty(
  $$select 1 from public.evidence where kind = 'github_repo'$$,
  'disconnecting removes the saved repos'
);

select results_eq(
  $$select confidence::text from public.skills where name = 'Flutter'$$,
  $$values ('self_claimed')$$,
  'removing the repo returns the skill to self-claimed'
);

select * from finish();
rollback;
