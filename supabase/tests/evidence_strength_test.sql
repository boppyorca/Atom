begin;
select plan(28);

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

insert into public.skills (id, profile_id, name) values
  ('aaaaaaaa-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'Empty'),
  ('aaaaaaaa-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'Weak'),
  ('aaaaaaaa-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111', 'Few commits'),
  ('aaaaaaaa-0000-0000-0000-000000000004', '11111111-1111-1111-1111-111111111111', 'Few lines'),
  ('aaaaaaaa-0000-0000-0000-000000000005', '11111111-1111-1111-1111-111111111111', 'Short span'),
  ('aaaaaaaa-0000-0000-0000-000000000006', '11111111-1111-1111-1111-111111111111', 'Strong alone'),
  ('aaaaaaaa-0000-0000-0000-000000000007', '11111111-1111-1111-1111-111111111111', 'With manifest'),
  ('aaaaaaaa-0000-0000-0000-000000000008', '11111111-1111-1111-1111-111111111111', 'Manifest elsewhere'),
  ('aaaaaaaa-0000-0000-0000-000000000009', '11111111-1111-1111-1111-111111111111', 'Two repos'),
  ('aaaaaaaa-0000-0000-0000-000000000010', '11111111-1111-1111-1111-111111111111', 'Same repo'),
  ('aaaaaaaa-0000-0000-0000-000000000011', '11111111-1111-1111-1111-111111111111', 'Missing dates'),
  ('aaaaaaaa-0000-0000-0000-000000000012', '11111111-1111-1111-1111-111111111111', 'Other skill'),
  ('aaaaaaaa-0000-0000-0000-000000000013', '22222222-2222-2222-2222-222222222222', 'Other person'),
  ('aaaaaaaa-0000-0000-0000-000000000014', '11111111-1111-1111-1111-111111111111', 'Policy');

insert into public.evidence_signal (
  profile_id, skill_id, repo_ref, signal_type, valid_commit_count, lines_authored,
  first_commit_at, last_commit_at
)
select
  '11111111-1111-1111-1111-111111111111',
  'aaaaaaaa-0000-0000-0000-000000000002',
  'repo-' || n,
  (array['readme_keyword','topic','language_stat','manual_note','article_link'])[((n - 1) % 5) + 1],
  null, null, null, null
from generate_series(1, 20) as n;

insert into public.evidence_signal (
  profile_id, skill_id, repo_ref, signal_type, valid_commit_count, lines_authored,
  first_commit_at, last_commit_at
) values
(
  '11111111-1111-1111-1111-111111111111',
  'aaaaaaaa-0000-0000-0000-000000000003', 'one', 'commit_activity', 4, 200,
  '2026-01-01', '2026-01-15'
),
(
  '11111111-1111-1111-1111-111111111111',
  'aaaaaaaa-0000-0000-0000-000000000004', 'one', 'commit_activity', 5, 199,
  '2026-01-01', '2026-01-15'
),
(
  '11111111-1111-1111-1111-111111111111',
  'aaaaaaaa-0000-0000-0000-000000000005', 'one', 'commit_activity', 5, 200,
  '2026-01-01', '2026-01-14'
),
(
  '11111111-1111-1111-1111-111111111111',
  'aaaaaaaa-0000-0000-0000-000000000006', 'one', 'commit_activity', 5, 200,
  '2026-01-01', '2026-01-15'
),
(
  '11111111-1111-1111-1111-111111111111',
  'aaaaaaaa-0000-0000-0000-000000000007', 'one', 'commit_activity', 5, 200,
  '2026-01-01', '2026-01-15'
),
(
  '11111111-1111-1111-1111-111111111111',
  'aaaaaaaa-0000-0000-0000-000000000007', 'one', 'manifest_dependency', null, null, null, null
),
(
  '11111111-1111-1111-1111-111111111111',
  'aaaaaaaa-0000-0000-0000-000000000008', 'repo-a', 'commit_activity', 5, 200,
  '2026-01-01', '2026-01-15'
),
(
  '11111111-1111-1111-1111-111111111111',
  'aaaaaaaa-0000-0000-0000-000000000008', 'repo-without-commit', 'manifest_dependency', null, null, null, null
),
(
  '11111111-1111-1111-1111-111111111111',
  'aaaaaaaa-0000-0000-0000-000000000009', 'repo-a', 'commit_activity', 5, 200,
  '2026-01-01', '2026-01-15'
),
(
  '11111111-1111-1111-1111-111111111111',
  'aaaaaaaa-0000-0000-0000-000000000009', 'repo-b', 'commit_activity', 5, 200,
  '2026-01-01', '2026-01-15'
),
(
  '11111111-1111-1111-1111-111111111111',
  'aaaaaaaa-0000-0000-0000-000000000010', 'same', 'commit_activity', 5, 200,
  '2026-01-01', '2026-01-15'
),
(
  '11111111-1111-1111-1111-111111111111',
  'aaaaaaaa-0000-0000-0000-000000000010', 'same', 'commit_activity', 5, 200,
  '2026-01-01', '2026-01-15'
),
(
  '11111111-1111-1111-1111-111111111111',
  'aaaaaaaa-0000-0000-0000-000000000011', 'one', 'commit_activity', 5, 200, null, null
),
(
  '22222222-2222-2222-2222-222222222222',
  'aaaaaaaa-0000-0000-0000-000000000013', 'one', 'commit_activity', 9, 900,
  '2026-01-01', '2026-02-01'
),
(
  '11111111-1111-1111-1111-111111111111',
  'aaaaaaaa-0000-0000-0000-000000000014', 'one', 'commit_activity', 5, 200,
  '2026-01-01', '2026-01-15'
),
(
  '11111111-1111-1111-1111-111111111111',
  'aaaaaaaa-0000-0000-0000-000000000014', 'one', 'manifest_dependency', null, null, null, null
);

select is(
  (select reason from public._skill_confidence(
    '11111111-1111-1111-1111-111111111111',
    'aaaaaaaa-0000-0000-0000-000000000001'
  )),
  'no_signals',
  'no signals stay self-claimed'
);

select is(
  (select confidence::text || ':' || reason from public._skill_confidence(
    '11111111-1111-1111-1111-111111111111',
    'aaaaaaaa-0000-0000-0000-000000000002'
  )),
  'self_claimed:weak_only',
  'readme and topic text never become evidenced'
);

select is(
  (select count(*) from (
    select reason from public._skill_confidence(
      '11111111-1111-1111-1111-111111111111',
      'aaaaaaaa-0000-0000-0000-000000000003'
    )
    union all
    select reason from public._skill_confidence(
      '11111111-1111-1111-1111-111111111111',
      'aaaaaaaa-0000-0000-0000-000000000004'
    )
    union all
    select reason from public._skill_confidence(
      '11111111-1111-1111-1111-111111111111',
      'aaaaaaaa-0000-0000-0000-000000000005'
    )
  ) as reasons where reason = 'strong_below_threshold'),
  3::bigint,
  'each threshold misses on its own'
);

insert into public.evidence_signal (
  profile_id, skill_id, repo_ref, signal_type
) values (
  '11111111-1111-1111-1111-111111111111',
  'aaaaaaaa-0000-0000-0000-000000000006',
  'one', 'manifest_dependency'
);

select is(
  (select reason from public._skill_confidence(
    '11111111-1111-1111-1111-111111111111',
    'aaaaaaaa-0000-0000-0000-000000000006'
  )),
  'evidenced',
  'the exact threshold plus an independent signal is evidenced'
);

update public.evidence_signal
set signal_type = 'readme_keyword'
where skill_id = 'aaaaaaaa-0000-0000-0000-000000000006'
  and signal_type = 'manifest_dependency';

select is(
  (select reason from public._skill_confidence(
    '11111111-1111-1111-1111-111111111111',
    'aaaaaaaa-0000-0000-0000-000000000006'
  )),
  'strong_no_independent',
  'a strong signal without an independent signal stays self-claimed'
);

select is(
  (select reason from public._skill_confidence(
    '11111111-1111-1111-1111-111111111111',
    'aaaaaaaa-0000-0000-0000-000000000007'
  )),
  'evidenced',
  'a manifest in a repo with a valid commit is the independent signal'
);

select is(
  (select reason from public._skill_confidence(
    '11111111-1111-1111-1111-111111111111',
    'aaaaaaaa-0000-0000-0000-000000000008'
  )),
  'strong_no_independent',
  'a manifest in a repo with no commit does not count'
);

select is(
  (select reason from public._skill_confidence(
    '11111111-1111-1111-1111-111111111111',
    'aaaaaaaa-0000-0000-0000-000000000009'
  )),
  'evidenced',
  'two different strong repos count as independent'
);

select is(
  (select reason from public._skill_confidence(
    '11111111-1111-1111-1111-111111111111',
    'aaaaaaaa-0000-0000-0000-000000000010'
  )),
  'strong_no_independent',
  'two strong rows in the same repo are not independent'
);

select is(
  (select reason from public._skill_confidence(
    '11111111-1111-1111-1111-111111111111',
    'aaaaaaaa-0000-0000-0000-000000000011'
  )),
  'strong_below_threshold',
  'missing dates do not raise an error'
);

select is(
  (select reason from public._skill_confidence(
    '11111111-1111-1111-1111-111111111111',
    'aaaaaaaa-0000-0000-0000-000000000012'
  )),
  'no_signals',
  'another person or another skill is ignored'
);

update public.evidence_policy set is_active = false where version = 1;
insert into public.evidence_policy (version, min_commits, min_lines, min_span_days, is_active)
values (2, 6, 200, 14, true);

select ok(
  (select reason = 'strong_below_threshold' from public._skill_confidence(
    '11111111-1111-1111-1111-111111111111',
    'aaaaaaaa-0000-0000-0000-000000000014'
  ))
  and (select count(*) = 1 from public.evidence_policy where is_active),
  'a stricter active policy lowers the level and stays unique'
);

update public.evidence_policy set is_active = false where version = 2;
update public.evidence_policy set is_active = true where version = 1;

insert into public.ai_jobs (id, profile_id, kind, status, deadline_at)
values (
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  '11111111-1111-1111-1111-111111111111',
  'extract_skills', 'succeeded', now()
);

insert into public.evidence (id, profile_id, kind, url, title, github_full_name)
values (
  'cccccccc-cccc-cccc-cccc-cccccccccccc',
  '11111111-1111-1111-1111-111111111111',
  'github_repo', 'https://github.com/minh/todo', 'todo', 'minh/todo'
);

insert into public.skill_suggestions (
  id, job_id, profile_id, name, evidence_ids, signals
) values (
  'dddddddd-dddd-dddd-dddd-dddddddddddd',
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  '11111111-1111-1111-1111-111111111111',
  'Readme only',
  array['cccccccc-cccc-cccc-cccc-cccccccccccc']::uuid[],
  array['keyword:flutter']
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

select lives_ok(
  $$select public.review_suggestion('dddddddd-dddd-dddd-dddd-dddddddddddd', true)$$,
  'accept records a weak suggestion'
);

reset role;
select is(
  (select confidence::text from public.skills where name = 'Readme only'),
  'self_claimed',
  'accepting readme text does not set evidenced'
);

insert into public.evidence_signal (
  profile_id, skill_id, repo_ref, signal_type, valid_commit_count, lines_authored,
  first_commit_at, last_commit_at
)
select
  '11111111-1111-1111-1111-111111111111',
  id, 'minh/todo', 'commit_activity', 5, 200, '2026-01-01', '2026-01-15'
from public.skills where name = 'Readme only';

insert into public.evidence_signal (
  profile_id, skill_id, evidence_id, repo_ref, signal_type
)
select
  '11111111-1111-1111-1111-111111111111',
  id, 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'minh/todo', 'manifest_dependency'
from public.skills where name = 'Readme only';

select public.recompute_skill_confidence((select id from public.skills where name = 'Readme only'));

select is(
  (select confidence::text from public.skills where name = 'Readme only'),
  'evidenced',
  'the level follows the signal function after accept'
);

select is(
  (select count(*) from public.skills where name = 'Readme only')
  + (select count(*) from public.skill_evidence where evidence_id = 'cccccccc-cccc-cccc-cccc-cccccccccccc'),
  2::bigint,
  'a second accept does not duplicate the skill or the link'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);
select throws_ok(
  $$select public.review_suggestion('dddddddd-dddd-dddd-dddd-dddddddddddd', true)$$,
  'P0001',
  'ALREADY_REVIEWED',
  'accepting twice is rejected'
);

reset role;
insert into public.skill_suggestions (
  id, job_id, profile_id, name, evidence_ids, signals
) values (
  'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  '11111111-1111-1111-1111-111111111111',
  'Reject me',
  array['cccccccc-cccc-cccc-cccc-cccccccccccc']::uuid[],
  array['keyword:rust']
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);
select lives_ok(
  $$select public.review_suggestion('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', false)$$,
  'reject keeps the previous level'
);

reset role;
select ok(
  (select confidence::text from public.skills where name = 'Readme only') = 'evidenced'
  and (select status::text from public.skill_suggestions where id = 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee') = 'rejected',
  'reject does not change a level and hides the suggestion'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}',
  true
);
select throws_ok(
  $$select public.review_suggestion('dddddddd-dddd-dddd-dddd-dddddddddddd', true)$$,
  'P0001',
  'NOT_FOUND',
  'another person cannot accept the suggestion'
);

select throws_ok(
  $$insert into public.evidence_signal (
    profile_id, skill_id, signal_type, valid_commit_count, lines_authored,
    first_commit_at, last_commit_at
  ) values (
    '22222222-2222-2222-2222-222222222222',
    'aaaaaaaa-0000-0000-0000-000000000013',
    'commit_activity', 99, 9999, now(), now()
  )$$,
  '42501',
  null,
  'a signed-in person cannot insert a signal'
);

select throws_ok(
  $$update public.evidence_signal set valid_commit_count = 99
    where profile_id = '22222222-2222-2222-2222-222222222222'$$,
  '42501',
  null,
  'a signed-in person cannot change signal numbers'
);

select throws_ok(
  $$update public.skills set confidence = 'evidenced'
    where id = 'aaaaaaaa-0000-0000-0000-000000000013'$$,
  '42501',
  null,
  'a signed-in person cannot set the level'
);

select throws_ok(
  $$select public._skill_confidence(
    '11111111-1111-1111-1111-111111111111',
    'aaaaaaaa-0000-0000-0000-000000000001'
  )$$,
  '42501',
  null,
  'the internal function is not callable with another person id'
);

select throws_ok(
  $$update public.evidence_policy set min_commits = 1$$,
  '42501',
  null,
  'a signed-in person cannot change the policy'
);

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);
insert into public.skills (profile_id, name)
values ('11111111-1111-1111-1111-111111111111', 'Blog');
insert into public.evidence (profile_id, kind, url, title)
values (
  '11111111-1111-1111-1111-111111111111',
  'article', 'https://example.com/blog', 'Blog'
);
insert into public.skill_evidence (skill_id, evidence_id)
select skills.id, evidence.id
from public.skills
join public.evidence on evidence.url = 'https://example.com/blog'
where skills.name = 'Blog';
reset role;
select is(
  (select count(*) from public.evidence_signal
    where skill_id = (select id from public.skills where name = 'Blog')
      and strength in ('strong', 'supporting')),
  0::bigint,
  'typed-in evidence never becomes a strong or supporting signal'
);

insert into public.evidence (id, profile_id, kind, url, title, github_full_name)
values (
  'ffffffff-ffff-ffff-ffff-ffffffffffff',
  '11111111-1111-1111-1111-111111111111',
  'github_repo', 'https://github.com/minh/old', 'old', 'minh/old'
);
insert into public.skill_evidence (skill_id, evidence_id)
values (
  'aaaaaaaa-0000-0000-0000-000000000002',
  'ffffffff-ffff-ffff-ffff-ffffffffffff'
);
update public.skills
set confidence = 'evidenced'
where id = 'aaaaaaaa-0000-0000-0000-000000000002';

select public.backfill_evidence_signals();
select is(
  (select confidence::text from public.skills where id = 'aaaaaaaa-0000-0000-0000-000000000002'),
  'self_claimed',
  'old weak evidence is lowered'
);
select public.backfill_evidence_signals();
select is(
  (select confidence::text from public.skills where id = 'aaaaaaaa-0000-0000-0000-000000000002'),
  'self_claimed',
  'running the backfill again stays the same'
);

select * from finish();
rollback;
