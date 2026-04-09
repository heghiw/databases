-- Kristiansand Bike Share Seed Data
-- PostgreSQL

begin;

-- Membership types
insert into membership_type (kind, duration, description) values
  ('daily', interval '24 hours', '24-hour pass'),
  ('monthly', interval '31 days', '31-day pass'),
  ('annual', interval '365 days', '365-day pass')
on conflict (kind) do nothing;

-- Program
insert into program (program_id, country, name, short_name, location_text, phone, email, timezone, url)
values
  ('bysykkel_krs', 'NO', 'Kristiansand Bysykkel', 'KRS', 'Kristiansand, Norway', '+47 380 00 000', 'info@bysykkel-krs.no', 'Europe/Oslo', 'https://bysykkel-krs.no')
on conflict (program_id) do nothing;

-- Stations
insert into station (station_id, program_id, name, short_name, address, postal_code, contact_phone, lat, lon, capacity)
values
  ('krs_sentrum', 'bysykkel_krs', 'Kristiansand Sentrum', 'Sentrum', 'Tollbodgata 1', '4611', '+47 380 00 001', 58.146000, 8.000000, 12),
  ('krs_bystranda', 'bysykkel_krs', 'Bystranda', 'Bystranda', 'Vestre Strandgate 23', '4610', '+47 380 00 002', 58.140500, 8.001500, 10),
  ('krs_uiagder', 'bysykkel_krs', 'Universitetet i Agder', 'UiA', 'Universitetsveien 25', '4630', '+47 380 00 003', 58.164000, 8.018000, 8),
  ('krs_kvadraturen', 'bysykkel_krs', 'Kvadraturen', 'Kvadraturen', 'Markens gate 30', '4612', '+47 380 00 004', 58.146800, 8.006000, 14)
on conflict (station_id) do nothing;

-- Docks
insert into dock (station_id, dock_number)
select 'krs_sentrum', n from generate_series(1, 12) as n
on conflict (station_id, dock_number) do nothing;
insert into dock (station_id, dock_number)
select 'krs_bystranda', n from generate_series(1, 10) as n
on conflict (station_id, dock_number) do nothing;
insert into dock (station_id, dock_number)
select 'krs_uiagder', n from generate_series(1, 8) as n
on conflict (station_id, dock_number) do nothing;
insert into dock (station_id, dock_number)
select 'krs_kvadraturen', n from generate_series(1, 14) as n
on conflict (station_id, dock_number) do nothing;

-- Bikes
insert into bike (bike_id, bike_type, make, model, color, year_acquired) values
  ('KRS-0001', 'electric', 'Bysykkel', 'KRS E-Bike', 'blue', 2024),
  ('KRS-0002', 'electric', 'Bysykkel', 'KRS E-Bike', 'blue', 2024),
  ('KRS-0101', 'classic', 'Bysykkel', 'KRS Classic', 'red', 2023),
  ('KRS-0201', 'smart', 'Bysykkel', 'KRS Smart', 'green', 2022),
  ('KRS-0301', 'cargo', 'Bysykkel', 'KRS Cargo', 'black', 2025)
on conflict (bike_id) do nothing;

-- Riders
insert into rider_account (email, full_name) values
  ('ola.nordmann@krs.no', 'Ola Nordmann'),
  ('kari.kristiansand@krs.no', 'Kari Kristiansand'),
  ('erik.hansen@krs.no', 'Erik Hansen')
on conflict (email) do nothing;

-- Memberships
insert into membership (rider_id, membership_type_id, purchased_at, expires_at)
select ra.rider_id, mt.membership_type_id, '2026-03-17 08:00:00+01', ('2026-03-17 08:00:00+01'::timestamptz + mt.duration)
from rider_account ra
join membership_type mt on mt.kind = 'monthly'
where ra.email = 'ola.nordmann@krs.no'
on conflict (rider_id, membership_type_id, purchased_at) do nothing;
insert into membership (rider_id, membership_type_id, purchased_at, expires_at)
select ra.rider_id, mt.membership_type_id, '2026-03-01 09:00:00+01', ('2026-03-01 09:00:00+01'::timestamptz + mt.duration)
from rider_account ra
join membership_type mt on mt.kind = 'annual'
where ra.email = 'kari.kristiansand@krs.no'
on conflict (rider_id, membership_type_id, purchased_at) do nothing;

-- Trips
insert into trip (
  rider_id, bike_id, start_station_id, end_station_id,
  started_at, ended_at, distance_km, elapsed_seconds, cost_cents
)
select ra.rider_id, 'KRS-0001', 'krs_sentrum', 'krs_bystranda',
       '2026-03-17 08:15:00+01', '2026-03-17 08:30:00+01',
       2.1, 15 * 60, 0
from rider_account ra
where ra.email = 'ola.nordmann@krs.no'
on conflict (bike_id, started_at) do nothing;
insert into trip (
  rider_id, bike_id, start_station_id, end_station_id,
  started_at, ended_at, distance_km, elapsed_seconds, cost_cents
)
select ra.rider_id, 'KRS-0101', 'krs_uiagder', 'krs_kvadraturen',
       '2026-03-17 09:00:00+01', '2026-03-17 09:25:00+01',
       3.5, 25 * 60, 0
from rider_account ra
where ra.email = 'kari.kristiansand@krs.no'
on conflict (bike_id, started_at) do nothing;

commit;
