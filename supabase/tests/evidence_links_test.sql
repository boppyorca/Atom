begin;
select plan(3);

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

set local role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

select throws_ok(
  $$insert into public.evidence (profile_id, kind, url, title)
    values (auth.uid(), 'article', 'notaurl', 'Notes')$$,
  '23514',
  null,
  'a bad link is rejected'
);

select lives_ok(
  $$insert into public.evidence (profile_id, kind, url, title)
    select auth.uid(), 'article', 'https://example.com/' || n, 'Note'
    from generate_series(1, 10) as n$$,
  'ten article links are allowed'
);

select throws_ok(
  $$insert into public.evidence (profile_id, kind, url, title)
    values (auth.uid(), 'product', 'https://example.com/11', 'Extra')$$,
  'P0001',
  'EVIDENCE_LIMIT',
  'the eleventh link is rejected'
);

select * from finish();
rollback;
