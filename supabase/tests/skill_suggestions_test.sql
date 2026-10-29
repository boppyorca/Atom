begin;
select plan(12);

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values (
  '00000000-0000-0000-0000-000000000000',
  '11111111-1111-1111-1111-111111111111',
  'authenticated', 'authenticated', 'owner@example.com',
  crypt('password', gen_salt('bf')), now(),
  '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()
), (
  '00000000-0000-0000-0000-000000000000',
  '22222222-2222-2222-2222-222222222222',
  'authenticated', 'authenticated', 'other@example.com',
  crypt('password', gen_salt('bf')), now(),
  '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()
);

insert into public.evidence (id, profile_id, kind, url, title, github_full_name)
values (
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  '11111111-1111-1111-1111-111111111111',
  'github_repo',
  'https://github.com/minh-dev/todo',
  'todo',
  'minh-dev/todo'
);

select throws_ok(
  $$select public.ai_begin_job('11111111-1111-1111-1111-111111111111', 'extract_skills')$$,
  'P0001',
  'CONSENT_REQUIRED',
  'analysis does not start before consent'
);

insert into public.ai_consents (profile_id, granted)
values ('11111111-1111-1111-1111-111111111111', true);

insert into public.ai_jobs (profile_id, kind, status, deadline_at, created_at)
values
  ('11111111-1111-1111-1111-111111111111', 'extract_skills', 'succeeded', now() + interval '1 minute', now()),
  ('11111111-1111-1111-1111-111111111111', 'extract_skills', 'succeeded', now() + interval '1 minute', now()),
  ('11111111-1111-1111-1111-111111111111', 'extract_skills', 'failed', now() + interval '1 minute', now());

select lives_ok(
  $$select public.ai_begin_job('11111111-1111-1111-1111-111111111111', 'extract_skills')$$,
  'a failed run does not use up the monthly limit'
);

update public.ai_jobs set status = 'succeeded'
where status = 'queued' and profile_id = '11111111-1111-1111-1111-111111111111';

select throws_ok(
  $$select public.ai_begin_job('11111111-1111-1111-1111-111111111111', 'extract_skills')$$,
  'P0001',
  'QUOTA_EXCEEDED',
  'the third successful run blocks the next one'
);

update public.app_settings set value = '4'::jsonb where key = 'ai_quota_extract_per_month';

select lives_ok(
  $$select public.ai_begin_job('11111111-1111-1111-1111-111111111111', 'extract_skills')$$,
  'raising the limit takes effect without an app release'
);

update public.ai_jobs
set status = 'running', deadline_at = now() - interval '1 second'
where status = 'queued' and profile_id = '11111111-1111-1111-1111-111111111111';

select lives_ok(
  $$select public.ai_begin_job('11111111-1111-1111-1111-111111111111', 'extract_skills')$$,
  'a new run closes an expired running job'
);

select results_eq(
  $$select status::text from public.ai_jobs
    where profile_id = '11111111-1111-1111-1111-111111111111'
      and error_code = 'TIMEOUT'$$,
  $$values ('timed_out')$$,
  'the expired job is marked timed out'
);

update public.ai_jobs
set status = 'running', deadline_at = now() + interval '1 minute', error_code = null
where id = (
  select id from public.ai_jobs
  where profile_id = '11111111-1111-1111-1111-111111111111'
    and status = 'queued'
  order by created_at desc limit 1
);

select throws_ok(
  $$select public.ai_begin_job('11111111-1111-1111-1111-111111111111', 'extract_skills')$$,
  'P0001',
  'JOB_ALREADY_RUNNING',
  'a second run waits until the current one finishes'
);

insert into public.ai_jobs (id, profile_id, kind, status, deadline_at)
values (
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  '11111111-1111-1111-1111-111111111111',
  'extract_skills', 'succeeded', now()
);

insert into public.skill_suggestions (id, job_id, profile_id, name, evidence_ids, signals)
values (
  'cccccccc-cccc-cccc-cccc-cccccccccccc',
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  '11111111-1111-1111-1111-111111111111',
  'Dart',
  array['aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa']::uuid[],
  array['language:Dart']
), (
  'dddddddd-dddd-dddd-dddd-dddddddddddd',
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  '11111111-1111-1111-1111-111111111111',
  'Flutter',
  array['aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa']::uuid[],
  array['dependency:pub:flutter']
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

select lives_ok(
  $$select public.review_suggestion('cccccccc-cccc-cccc-cccc-cccccccccccc', true)$$,
  'accepting a suggestion records it'
);

reset role;
-- Changed on purpose: accepting a language signal is weak, so the level stays
-- self_claimed. evidenced now requires a strong commit signal plus an
-- independent signal. See evidence_strength_test.sql.
select results_eq(
  $$select confidence::text from public.skills where name = 'Dart'$$,
  $$values ('self_claimed')$$,
  'an accepted language suggestion stays self-claimed'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}',
  true
);

select throws_ok(
  $$select public.review_suggestion('dddddddd-dddd-dddd-dddd-dddddddddddd', false)$$,
  'P0001',
  'NOT_FOUND',
  'someone else cannot review the suggestion'
);

select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

select lives_ok(
  $$select public.review_suggestion('dddddddd-dddd-dddd-dddd-dddddddddddd', false)$$,
  'rejecting a suggestion does not add a skill'
);

select throws_ok(
  $$select public.review_suggestion('cccccccc-cccc-cccc-cccc-cccccccccccc', true)$$,
  'P0001',
  'ALREADY_REVIEWED',
  'a suggestion cannot be reviewed twice'
);

select * from finish();
rollback;
