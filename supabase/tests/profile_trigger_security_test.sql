begin;
select plan(5);

select ok(
  (select prosecdef from pg_proc where oid = 'public.handle_new_user()'::regprocedure),
  'handle_new_user runs as its owner (security definer)'
);

select ok(
  (
    select 'search_path=""' = any(proconfig)
    from pg_proc
    where oid = 'public.handle_new_user()'::regprocedure
  ),
  'handle_new_user pins an empty search_path'
);

select is(
  (
    select pg_get_userbyid(proowner)
    from pg_proc
    where oid = 'public.handle_new_user()'::regprocedure
  ),
  'postgres',
  'handle_new_user is owned by postgres'
);

select ok(
  not has_function_privilege('anon', 'public.handle_new_user()', 'execute')
  and not has_function_privilege('authenticated', 'public.handle_new_user()', 'execute'),
  'app roles cannot execute handle_new_user'
);

select ok(
  not has_function_privilege('anon', 'public.set_updated_at()', 'execute')
  and not has_function_privilege('authenticated', 'public.set_updated_at()', 'execute'),
  'app roles cannot execute set_updated_at'
);

select * from finish();
rollback;
