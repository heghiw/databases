-- IS-309 Assignment 1 - Sample data
-- Assumes you have already run schema.sql and the tables are empty.

begin;

-- Membership types
insert into membership_type (kind, duration, description) values
  ('daily', interval '24 hours', '24-hour pass'),
  ('monthly', interval '31 days', '31-day pass'),
  ('annual', interval '365 days', '365-day pass')
on conflict (kind) do nothing;

-- Programs
insert into program (program_id, country, name, short_name, location_text, phone, email, timezone, url)
values
  ('bcycle_heartland', 'US', 'Heartland Bcycle', 'Heartland', 'Omaha, NE', '402-957-2453', 'info@heartlandbcycle.com', 'America/Chicago', 'https://heartland.bcycle.com'),
  ('bcycle_trondheim', 'NO', 'Trondheim Bysykkel', 'Trondheim', 'Trondheim', '+47 511 99 900', 'support@example.no', 'Europe/Oslo', 'https://example.no/bike')
on conflict (program_id) do nothing;

-- Stations (Heartland)
insert into station (station_id, program_id, name, short_name, address, postal_code, contact_phone, lat, lon, capacity)
values
  ('bcycle_heartland_1917', 'bcycle_heartland', '67th & Pine', '67th & Pine', '1625 S 67th St', '68106', '402-957-2453', 41.244970, -96.015730, 9),
  ('bcycle_heartland_1918', 'bcycle_heartland', 'Downtown Library', 'Library', '1401 Jones St', '68102', '402-957-2453', 41.256300, -95.934900, 11)
on conflict (station_id) do nothing;

-- Docks (create docking points per station)
insert into dock (station_id, dock_number)
select 'bcycle_heartland_1917', n from generate_series(1, 9) as n
on conflict (station_id, dock_number) do nothing;
insert into dock (station_id, dock_number)
select 'bcycle_heartland_1918', n from generate_series(1, 11) as n
on conflict (station_id, dock_number) do nothing;

-- Bikes
insert into bike (bike_id, bike_type, make, model, color, year_acquired) values
  ('HB-0001', 'electric', 'GCM', 'Bcycle 2.0', 'white', 2023),
  ('HB-0002', 'electric', 'GCM', 'Bcycle 2.0', 'white', 2023),
  ('HB-0101', 'classic', 'GCM', 'Bcycle Classic', 'red', 2022),
  ('HB-0102', 'classic', 'GCM', 'Bcycle Classic', 'red', 2022),
  ('HB-0201', 'smart', 'GCM', 'Bcycle Smart', 'blue', 2021),
  ('HB-0301', 'cargo', 'GCM', 'Bcycle Cargo', 'black', 2024)
on conflict (bike_id) do nothing;

-- Bike status history (multiple rows over time)
with d as (
  select dock_id, station_id, dock_number
  from dock
  where station_id in ('bcycle_heartland_1917', 'bcycle_heartland_1918')
)
insert into bike_status (bike_id, recorded_at, state, station_id, dock_id, lat, lon, battery_pct, remaining_range_km) values
  ('HB-0001', '2026-03-05 08:00:00-06', 'available', 'bcycle_heartland_1917', (select dock_id from d where station_id='bcycle_heartland_1917' and dock_number=1), 41.244970, -96.015730, 92.5, 37.2),
  ('HB-0001', '2026-03-05 08:15:00-06', 'in_use', null, null, 41.246100, -96.010200, 90.1, 36.0),
  ('HB-0001', '2026-03-05 08:28:00-06', 'available', 'bcycle_heartland_1918', (select dock_id from d where station_id='bcycle_heartland_1918' and dock_number=3), 41.256300, -95.934900, 87.4, 34.1),

  ('HB-0002', '2026-03-05 08:00:00-06', 'available', 'bcycle_heartland_1917', (select dock_id from d where station_id='bcycle_heartland_1917' and dock_number=2), 41.244970, -96.015730, 76.0, 28.5),
  ('HB-0002', '2026-03-05 09:00:00-06', 'not_available', 'bcycle_heartland_1917', (select dock_id from d where station_id='bcycle_heartland_1917' and dock_number=2), 41.244970, -96.015730, 74.2, 27.9),

  ('HB-0101', '2026-03-05 08:00:00-06', 'available', 'bcycle_heartland_1918', (select dock_id from d where station_id='bcycle_heartland_1918' and dock_number=1), 41.256300, -95.934900, null, null),
  ('HB-0101', '2026-03-05 08:50:00-06', 'in_use', null, null, 41.254200, -95.946000, null, null),
  ('HB-0101', '2026-03-05 09:12:00-06', 'available', 'bcycle_heartland_1917', (select dock_id from d where station_id='bcycle_heartland_1917' and dock_number=5), 41.244970, -96.015730, null, null),

  ('HB-0102', '2026-03-05 08:00:00-06', 'available', 'bcycle_heartland_1918', (select dock_id from d where station_id='bcycle_heartland_1918' and dock_number=2), 41.256300, -95.934900, null, null),

  ('HB-0201', '2026-03-05 08:00:00-06', 'available', 'bcycle_heartland_1917', (select dock_id from d where station_id='bcycle_heartland_1917' and dock_number=6), 41.244970, -96.015730, null, null),

  ('HB-0301', '2026-03-05 08:00:00-06', 'available', 'bcycle_heartland_1918', (select dock_id from d where station_id='bcycle_heartland_1918' and dock_number=4), 41.256300, -95.934900, null, null)
on conflict (bike_id, recorded_at) do nothing;

-- Station status history (multiple rows over time)
insert into station_status (
  station_id,
  reported_at,
  bikes_available_electric,
  bikes_available_smart,
  bikes_available_classic,
  bikes_available_cargo,
  bikes_available_total,
  docks_available_total,
  is_accepting_returns,
  is_renting
) values
  ('bcycle_heartland_1917', '2026-03-05 08:00:00-06', 2, 1, 0, 0, 3, 6, true, true),
  ('bcycle_heartland_1917', '2026-03-05 08:20:00-06', 1, 1, 0, 0, 2, 7, true, true),
  ('bcycle_heartland_1917', '2026-03-05 09:05:00-06', 1, 1, 1, 0, 3, 6, true, true),

  ('bcycle_heartland_1918', '2026-03-05 08:00:00-06', 0, 0, 2, 1, 3, 8, true, true),
  ('bcycle_heartland_1918', '2026-03-05 08:30:00-06', 1, 0, 2, 1, 4, 7, true, true),
  ('bcycle_heartland_1918', '2026-03-05 09:15:00-06', 1, 0, 1, 1, 3, 8, true, true)
on conflict (station_id, reported_at) do nothing;

-- Riders
insert into rider_account (email, full_name) values
  ('alex.rider@example.com', 'Alex Rider'),
  ('sam.chen@example.com', 'Sam Chen')
on conflict (email) do nothing;

-- Memberships (purchased + expiration timestamps)
insert into membership (rider_id, membership_type_id, purchased_at, expires_at)
select ra.rider_id, mt.membership_type_id,
       '2026-03-05 07:50:00-06'::timestamptz,
       ('2026-03-05 07:50:00-06'::timestamptz + mt.duration)
from rider_account ra
join membership_type mt on mt.kind = 'daily'
where ra.email = 'alex.rider@example.com'
on conflict (rider_id, membership_type_id, purchased_at) do nothing;

insert into membership (rider_id, membership_type_id, purchased_at, expires_at)
select ra.rider_id, mt.membership_type_id,
       '2026-03-01 09:00:00-06'::timestamptz,
       ('2026-03-01 09:00:00-06'::timestamptz + mt.duration)
from rider_account ra
join membership_type mt on mt.kind = 'monthly'
where ra.email = 'sam.chen@example.com'
on conflict (rider_id, membership_type_id, purchased_at) do nothing;

-- Trips
insert into trip (
  rider_id, bike_id, start_station_id, end_station_id,
  started_at, ended_at, distance_km, elapsed_seconds, cost_cents
)
select ra.rider_id, 'HB-0001', 'bcycle_heartland_1917', 'bcycle_heartland_1918',
       '2026-03-05 08:15:00-06'::timestamptz, '2026-03-05 08:28:00-06'::timestamptz,
       2.350, 13 * 60, 0
from rider_account ra
where ra.email = 'alex.rider@example.com'
on conflict (bike_id, started_at) do nothing;

insert into trip (
  rider_id, bike_id, start_station_id, end_station_id,
  started_at, ended_at, distance_km, elapsed_seconds, cost_cents
)
select ra.rider_id, 'HB-0101', 'bcycle_heartland_1918', 'bcycle_heartland_1917',
       '2026-03-05 08:50:00-06'::timestamptz, '2026-03-05 09:12:00-06'::timestamptz,
       3.100, 22 * 60, 0
from rider_account ra
where ra.email = 'sam.chen@example.com'
on conflict (bike_id, started_at) do nothing;

commit;
