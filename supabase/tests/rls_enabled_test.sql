begin;
select plan(1);

select ok(
  (
    select coalesce(bool_and(c.relrowsecurity), false)
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relkind = 'r'
  ),
  'every public table has row level security enabled'
);

select * from finish();
rollback;
