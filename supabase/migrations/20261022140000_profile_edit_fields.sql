-- Ticket 02: editable profile fields and the fixed city list (DATA_MODEL 4.1, 4.10).

create table public.cities (
  id smallint primary key,
  code text unique not null,
  label_vi text not null,
  label_en text not null
);

insert into public.cities (id, code, label_vi, label_en)
values
  (1, 'hn', 'Hà Nội', 'Hanoi'),
  (2, 'hcm', 'TP. Hồ Chí Minh', 'Ho Chi Minh City'),
  (3, 'dn', 'Đà Nẵng', 'Da Nang'),
  (4, 'other', 'Thành phố khác', 'Other city'),
  (5, 'remote', 'Làm từ xa', 'Remote');

alter table public.cities enable row level security;

revoke all on table public.cities from public, anon, authenticated;
grant select on table public.cities to authenticated;

create policy cities_select_all
  on public.cities
  for select
  to authenticated
  using (true);

create type public.contact_type as enum ('email', 'linkedin');

alter table public.profiles
  add column bio text,
  add column city_id smallint references public.cities (id),
  add column contact_type public.contact_type,
  add column contact_value text,
  add column contact_visible boolean not null default false,
  add constraint profiles_bio_len check (char_length(bio) <= 300),
  add constraint profiles_contact_pair check (
    (contact_type is null) = (contact_value is null)
  ),
  add constraint profiles_contact_format check (
    contact_type is null
    or (contact_type = 'email' and contact_value ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$')
    or (
      contact_type = 'linkedin'
      and contact_value ~ '^https://(www\.)?linkedin\.com/'
    )
  );

grant usage on type public.contact_type to authenticated;
-- seniority is in the DATA_MODEL grant list but its column does not exist yet.
grant insert (bio, city_id, contact_type, contact_value, contact_visible)
  on table public.profiles to authenticated;
grant update (bio, city_id, contact_type, contact_value, contact_visible)
  on table public.profiles to authenticated;
