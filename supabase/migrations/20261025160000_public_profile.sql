-- Ticket 08: first time a profile is made public, and a public read for the link.

create function public.stamp_first_public_at()
returns trigger
language plpgsql
set search_path = public
as $fn$
begin
  if new.visibility = 'public'
    and old.visibility is distinct from 'public'
    and new.first_public_at is null then
    new.first_public_at = now();
  end if;
  return new;
end;
$fn$;

create trigger profiles_stamp_first_public
  before update on public.profiles
  for each row
  execute function public.stamp_first_public_at();

create function public.get_public_profile(p_profile_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $fn$
declare
  found_profile public.profiles%rowtype;
  city jsonb;
  contact jsonb;
  skills jsonb;
  evidence jsonb;
begin
  select * into found_profile from public.profiles where id = p_profile_id;
  if not found
    or found_profile.visibility <> 'public'
    or found_profile.moderation_status <> 'active' then
    return null;
  end if;

  select jsonb_build_object(
    'code', cities.code,
    'label_vi', cities.label_vi,
    'label_en', cities.label_en
  ) into city
  from public.cities
  where id = found_profile.city_id;

  if found_profile.contact_visible and found_profile.contact_value is not null then
    contact := jsonb_build_object(
      'type', found_profile.contact_type,
      'value', found_profile.contact_value
    );
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'id', skills.id,
    'name', skills.name,
    'confidence', skills.confidence,
    'endorsement_count', 0,
    'evidence_ids', coalesce((
      select jsonb_agg(skill_evidence.evidence_id)
      from public.skill_evidence
      where skill_evidence.skill_id = skills.id
    ), '[]'::jsonb),
    'viewer_can_endorse', case when auth.uid() is null then null else to_jsonb(false) end,
    'viewer_endorsement_id', null
  ) order by skills.created_at), '[]'::jsonb)
  into skills
  from public.skills
  where skills.profile_id = found_profile.id;

  select coalesce(jsonb_agg(jsonb_build_object(
    'id', evidence.id,
    'kind', evidence.kind,
    'url', evidence.url,
    'title', evidence.title
  ) order by evidence.created_at), '[]'::jsonb)
  into evidence
  from public.evidence
  where evidence.profile_id = found_profile.id;

  return jsonb_build_object(
    'id', found_profile.id,
    'display_name', found_profile.display_name,
    'bio', found_profile.bio,
    'city', city,
    'seniority', found_profile.seniority,
    'avatar_url', found_profile.avatar_url,
    'contact', contact,
    'skills', skills,
    'evidence', evidence,
    'updated_at', found_profile.updated_at
  );
end;
$fn$;

revoke all on function public.stamp_first_public_at() from public, anon;
grant execute on function public.stamp_first_public_at() to authenticated;
revoke all on function public.get_public_profile(uuid) from public;
grant execute on function public.get_public_profile(uuid) to anon, authenticated;
