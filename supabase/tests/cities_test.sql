begin;
select plan(6);

select results_eq(
  $$select code from public.cities order by id$$,
  array['hn', 'hcm', 'dn', 'other', 'remote'],
  'cities are seeded with the fixed list'
);

set local role anon;
select throws_ok(
  $$select count(*) from public.cities$$,
  '42501',
  null,
  'anon cannot read cities'
);
select throws_ok(
  $$insert into public.cities (id, code, label_vi, label_en) values (99, 'x', 'x', 'x')$$,
  '42501',
  null,
  'anon cannot add cities'
);

set local role authenticated;
select results_eq(
  $$select label_vi from public.cities where code = 'hcm'$$,
  array['TP. Hồ Chí Minh'],
  'authenticated reads cities'
);
select throws_ok(
  $$update public.cities set label_en = 'x'$$,
  '42501',
  null,
  'authenticated cannot change cities'
);
select throws_ok(
  $$delete from public.cities$$,
  '42501',
  null,
  'authenticated cannot delete cities'
);

select * from finish();
rollback;
