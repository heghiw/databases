-- IS-309 Assignment 1 - Bike share database schema (PostgreSQL)

begin;

-- Domain helpers
create domain country_code2 as text
  check (value ~ '^[A-Z]{2}$');

create domain email_text as text
  check (position('@' in value) > 1);

create domain phone_text as text
  check (value ~ '^[0-9+() .-]{7,}$');

create domain latitude as numeric(9, 6)
  check (value >= -90 and value <= 90);

create domain longitude as numeric(9, 6)
  check (value >= -180 and value <= 180);

create type bike_type as enum ('electric', 'smart', 'classic', 'cargo');
create type bike_state as enum ('available', 'in_use', 'not_available');
create type membership_kind as enum ('daily', 'monthly', 'annual');

-- Programs (Bcycle calls them Systems)
create table program (
  program_id text primary key, -- e.g. bcycle_heartland
  country country_code2 not null,
  name text not null,
  short_name text,
  location_text text,
  phone phone_text,
  email email_text,
  timezone text,
  url text,
  created_at timestamptz not null default now(),
  constraint program_id_format check (program_id ~ '^[a-z0-9_]+$')
);

-- Stations (managed by a program)
create table station (
  station_id text primary key, -- e.g. bcycle_heartland_1917
  program_id text not null references program(program_id) on delete restrict,
  name text not null,
  short_name text,
  address text not null,
  postal_code text,
  contact_phone phone_text,
  lat latitude not null,
  lon longitude not null,
  capacity integer not null check (capacity > 0),
  created_at timestamptz not null default now(),
  constraint station_id_format check (station_id ~ '^[a-z0-9_]+$')
);
create index station_program_id_idx on station(program_id);

-- Docking points at a station
create table dock (
  dock_id bigserial primary key,
  station_id text not null references station(station_id) on delete cascade,
  dock_number integer not null check (dock_number > 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (station_id, dock_number)
);
create index dock_station_id_idx on dock(station_id);

-- Bicycles (static attributes)
create table bike (
  bike_id text primary key, -- unique bicycle identifier
  bike_type bike_type not null,
  make text,
  model text,
  color text,
  year_acquired integer check (year_acquired between 1980 and extract(year from now())::int + 1),
  created_at timestamptz not null default now(),
  constraint bike_id_format check (bike_id ~ '^[A-Za-z0-9_-]+$')
);

-- Bike status/location over time (history)
create table bike_status (
  bike_status_id bigserial primary key,
  bike_id text not null references bike(bike_id) on delete cascade,
  recorded_at timestamptz not null,
  state bike_state not null,
  station_id text references station(station_id) on delete set null,
  dock_id bigint references dock(dock_id) on delete set null,
  lat latitude,
  lon longitude,
  battery_pct numeric(5, 2) check (battery_pct >= 0 and battery_pct <= 100),
  remaining_range_km numeric(7, 2) check (remaining_range_km >= 0),
  constraint bike_status_unique_time unique (bike_id, recorded_at),
  constraint bike_status_dock_station_consistency check (
    dock_id is null
    or station_id is not null
  )
);
create index bike_status_bike_time_idx on bike_status(bike_id, recorded_at desc);
create index bike_status_station_time_idx on bike_status(station_id, recorded_at desc);

-- Station status over time (history)
create table station_status (
  station_status_id bigserial primary key,
  station_id text not null references station(station_id) on delete cascade,
  reported_at timestamptz not null,
  bikes_available_electric integer not null default 0 check (bikes_available_electric >= 0),
  bikes_available_smart integer not null default 0 check (bikes_available_smart >= 0),
  bikes_available_classic integer not null default 0 check (bikes_available_classic >= 0),
  bikes_available_cargo integer not null default 0 check (bikes_available_cargo >= 0),
  bikes_available_total integer not null check (bikes_available_total >= 0),
  docks_available_total integer not null check (docks_available_total >= 0),
  is_accepting_returns boolean not null default true,
  is_renting boolean not null default true,
  constraint station_status_unique_time unique (station_id, reported_at),
  constraint station_status_totals_match check (
    bikes_available_total
      = bikes_available_electric
      + bikes_available_smart
      + bikes_available_classic
      + bikes_available_cargo
  )
);
create index station_status_station_time_idx on station_status(station_id, reported_at desc);

-- Membership types (daily/monthly/annual)
create table membership_type (
  membership_type_id smallserial primary key,
  kind membership_kind not null unique,
  duration interval not null,
  description text,
  constraint membership_duration_positive check (duration > interval '0 seconds')
);

-- Rider accounts
create table rider_account (
  rider_id bigserial primary key,
  email email_text not null unique,
  full_name text,
  created_at timestamptz not null default now()
);

-- Purchased memberships (history per rider)
create table membership (
  membership_id bigserial primary key,
  rider_id bigint not null references rider_account(rider_id) on delete cascade,
  membership_type_id smallint not null references membership_type(membership_type_id) on delete restrict,
  purchased_at timestamptz not null,
  expires_at timestamptz not null,
  constraint membership_expiration_after_purchase check (expires_at > purchased_at),
  constraint membership_unique_purchase unique (rider_id, membership_type_id, purchased_at)
);
create index membership_rider_idx on membership(rider_id);

-- Trips (summary data)
create table trip (
  trip_id bigserial primary key,
  rider_id bigint not null references rider_account(rider_id) on delete restrict,
  bike_id text not null references bike(bike_id) on delete restrict,
  start_station_id text not null references station(station_id) on delete restrict,
  end_station_id text references station(station_id) on delete restrict,
  started_at timestamptz not null,
  ended_at timestamptz,
  distance_km numeric(9, 3) check (distance_km >= 0),
  elapsed_seconds integer check (elapsed_seconds >= 0),
  cost_cents integer check (cost_cents >= 0),
  constraint trip_end_after_start check (ended_at is null or ended_at >= started_at),
  constraint trip_unique_bike_start unique (bike_id, started_at)
);
create index trip_rider_time_idx on trip(rider_id, started_at desc);
create index trip_bike_time_idx on trip(bike_id, started_at desc);

commit;
