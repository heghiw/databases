# Final deliverables

This folder is intended to be uploaded/submitted as the "final deliverables" bundle.

## Contents
- `er_diagram.drawio` - ER/UML diagram (draw.io / diagrams.net)
- `schema.sql` - PostgreSQL DDL (tables + constraints)
- `seed.sql` - sample inserts (includes multiple time-stamped rows in status tables)
- `export.sql` - exports tables to CSV via `psql \copy` into `export/`
- `CONTRIBUTIONS.md` - contribution statement (single-member team)
- `export/` - where the generated CSV exports go

## Table overview
This schema models a bike-share business where a customer with a valid membership can unlock a bike at a station, ride it, and return it to another station. The system also tracks real-time availability and historical status over time.

Core master data:
- `program`: the operator/program running the service in a city/country (keeps multiple cities/operators separate; stores program-level contact/timezone/URL metadata).
- `station`: physical pick-up/return locations within a program (name, address, GPS); `capacity` represents total docking points at the station.
- `dock`: the individual docking points that make up a station's capacity 
- `bike`: the fleet inventory (each bicycle and its static attributes like type, make/model/color, year acquired).
- `rider_account`: customers/riders (who hold memberships and take trips).
- `membership_type`: the membership products (daily/monthly/annual) and their durations (used to compute membership expiry).

Time-based operational data (history tables):
- `station_status`: periodic station snapshots (bikes available by type + totals, docks available, renting/returns flags, timestamp) for real-time availability and historical reporting.
- `bike_status`: periodic bike snapshots (state, location; optional station/dock when parked; battery/range for electric bikes; timestamp) for fleet tracking, maintenance/out-of-service handling, and auditability over time.

Transactional/usage data:
- `membership`: membership purchases over time (purchase + expiration timestamps) to validate whether a rider can rent at a given moment.
- `trip`: trip summaries (start/end station, start/end timestamps, distance, elapsed time, cost) for usage analytics and downstream billing (the cost calculation itself is out of scope, but the result is stored).

## Constraints and business rules
- Identifiers: `program_id` and `station_id` are stored as text identifiers (e.g., `bcycle_heartland`, `bcycle_heartland_1917`) ; `bike_id` is a unique fleet identifier.
- Time zones: timestamps use `timestamptz` so recorded times are unambiguous; programs also store an optional `timezone` string for UI/reporting.
- Enumerations: bike type is constrained (`electric/smart/classic/cargo`); bike state is constrained (`available/in_use/not_available`); membership kind is constrained (`daily/monthly/annual`).
- Data quality: latitude/longitude ranges are validated; basic formatting checks exist for country codes, emails, and phone numbers.
- Status history tables: `station_status` and `bike_status` store many rows over time, enforced by unique constraints on `(station_id, reported_at)` and `(bike_id, recorded_at)` so the same entity can't have two snapshots at the same timestamp.
- Station status totals: `station_status` enforces that `bikes_available_total` equals the sum of type-specific counts.
- Membership validity: `membership` enforces `expires_at > purchased_at`; membership durations live in `membership_type` so expiry can be computed consistently.
- Referential integrity: foreign keys connect trips/memberships/status to master data; delete rules are chosen to avoid losing business history (e.g., trips restrict deleting referenced bikes/riders/stations).
- Current state reporting: the current station/bike status can be obtained by selecting the latest row per station/bike from `station_status` / `bike_status` (by `reported_at` / `recorded_at`).

## Scope notes
- Payment processing and cost calculation are out of scope; `trip.cost_cents` stores the resulting cost if/when it is computed elsewhere.
- High-frequency operational telemetry (e.g., every 5 seconds during a ride) is out of scope; only trip summaries and status snapshots are stored.

## How to generate the exported data files
From the repo root (so paths like `export/program.csv` resolve):
- `& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -d is309_assignment1 -f .\schema.sql`
- `& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -d is309_assignment1 -f .\seed.sql`
- `& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -d is309_assignment1 -f .\export.sql`

## AI assistance disclosure
AI assistance (Codex/ChatGPT) was used for proofreading/rewriting written text and improving structure/clarity (README), and to assist with SQL comments and the sample data in `seed.sql`.

## Group member contributions
See `CONTRIBUTIONS.md`.


