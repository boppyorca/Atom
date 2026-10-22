-- Supabase default privileges grant EXECUTE to anon/authenticated directly,
-- so the earlier "revoke ... from public" did not remove it (TECH_DESIGN 5.2).

revoke execute on function public.handle_new_user() from anon, authenticated;
revoke execute on function public.set_updated_at() from anon, authenticated;
