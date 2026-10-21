begin;
select plan(1);

select is((select 1), 1, 'database responds to a trivial query');

select * from finish();
rollback;
