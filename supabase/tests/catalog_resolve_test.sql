begin;
select plan(13);

select results_eq(
  $$select id from public.skill_catalog
    where id in (
      'ci-cd','dart','docker','flutter','go','kotlin','postgresql',
      'provider','python','react','rest-api','swift','typescript'
    )
    order by 1$$,
  $$values
    ('ci-cd'),('dart'),('docker'),('flutter'),('go'),('kotlin'),('postgresql'),
    ('provider'),('python'),('react'),('rest-api'),('swift'),('typescript')$$,
  'all 13 rules resolve by id'
);

select is(
  (select catalog_id from public.skill_catalog_key where name_key = 'java'),
  'java',
  'java keeps its own key'
);
select is(
  (select catalog_id from public.skill_catalog_key where name_key = 'javascript'),
  'javascript',
  'javascript keeps its own key'
);
select is(
  (select catalog_id from public.skill_catalog_key where name_key = 'react'),
  'react',
  'react keeps its own key'
);
select is(
  (select catalog_id from public.skill_catalog_key where name_key = 'react native'),
  'react-native',
  'react native stays apart from react'
);
select is(
  (select catalog_id from public.skill_catalog_key where name_key = 'go'),
  'go',
  'go is one skill'
);
select is(
  (select catalog_id from public.skill_catalog_key where name_key = 'c'),
  'c',
  'c is one skill'
);
select is(
  (select catalog_id from public.skill_catalog_key where name_key = 'r'),
  'r',
  'r is one skill'
);
select is(
  (select verifiability from public.skill_catalog where id = 'dart'),
  'file',
  'dart can be checked from a source file'
);
select is(
  (select verifiability from public.skill_catalog where id = 'react'),
  'package',
  'react can be checked from a declared package'
);
select is(
  (select verifiability from public.skill_catalog where id = 'postgresql'),
  'unverifiable',
  'postgresql cannot be checked from source'
);
select cmp_ok(
  (select count(*) from public.skill_catalog where verifiability = 'unverifiable'),
  '>',
  100::bigint,
  'most catalog names cannot be checked from source'
);
select throws_ok(
  $$insert into public.skill_catalog (id, name, aliases, extensions)
    values ('go-extra', 'Golang', array['go'], '{}')$$,
  '23505',
  'duplicate key value violates unique constraint "skill_catalog_key_pkey"',
  'a repeated normalized alias is rejected'
);

select * from finish();
rollback;
