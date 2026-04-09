# Assignment 3 Report - Bcycle Database

## 1. Physical Storage Structure and Database Size

The Bcycle database is stored in PostgreSQL as tables, indexes, sequences, types, domains, and system metadata. The main tables in this assignment are `program`, `station`, `dock`, `bike`, `bike_status`, `station_status`, `membership_type`, `rider_account`, `membership`, and `trip`.

In PostgreSQL, table rows are stored in heap pages. Indexes are stored separately. The `bigserial` and `smallserial` columns use sequences, and large variable-length values can be moved to TOAST storage if needed.

The measured size of the database was:

- Database name: `is309_assignment1`
- Database size: `9801 kB`
- Database size in bytes: `10035727`

### Size of Each Relation

From PostgreSQL statistics, the following storage estimates were collected:

| Relation | Estimated Rows | Heap Pages | Estimated Rows per Page | Estimated Heap Bytes per Row |
|----------|----------------|------------|--------------------------|-------------------------------|
| bike | 6 | 1 | 6.00 | 1365.33 |
| bike_status | 11 | 1 | 11.00 | 744.73 |
| dock | 20 | 1 | 20.00 | 409.60 |
| membership | 2 | 1 | 2.00 | 4096.00 |
| membership_type | 3 | 1 | 3.00 | 2730.67 |
| program | 2 | 1 | 2.00 | 4096.00 |
| rider_account | 2 | 1 | 2.00 | 4096.00 |
| station | 2 | 1 | 2.00 | 4096.00 |
| station_status | 6 | 1 | 6.00 | 1365.33 |
| trip | 2 | 1 | 2.00 | 4096.00 |

### How Many Pages Each Tuple Is Stored In

In PostgreSQL, a normal tuple is stored on one heap page. A tuple only needs extra storage pages when large variable-length values are moved to TOAST storage. Because of that, the best way to explain physical storage here is by pages per relation, rows per page, and row size.

For this sample dataset:

- all listed relations currently use one heap page each
- normal tuples are stored on one page
- TOAST tables exist for several relations, but this dataset does not show heavy off-page storage

Average row sizes were:

- `program`: `172.00` bytes
- `station`: `152.00` bytes
- `dock`: `71.85` bytes
- `bike`: `71.50` bytes
- `bike_status`: `108.09` bytes
- `station_status`: `89.50` bytes
- `membership_type`: `59.67` bytes
- `rider_account`: `74.50` bytes
- `membership`: `62.50` bytes
- `trip`: `126.50` bytes

## 2. Data Dictionary View

The data dictionary was generated from `information_schema` and `pg_indexes`. It shows:

- column names
- data types
- internal PostgreSQL type names
- nullability
- default values
- primary keys
- foreign keys
- unique and check constraints
- index definitions

The schema can be summarized like this:

- `program` stores bike-share systems or operators
- `station` stores station location and capacity
- `dock` stores dock points inside each station
- `bike` stores the bicycle fleet
- `bike_status` stores bike history over time
- `station_status` stores station availability history
- `membership_type` stores the available products
- `rider_account` stores customer accounts
- `membership` stores purchased memberships
- `trip` stores ride history

### Table Structure Summary

This section gives the same kind of information as a SQL `DESCRIBE` output, but in report form.

#### `program`

Purpose: stores the bike-share system or operating program for a city or region.  
Design and relationships: `program` is a parent table in the location hierarchy. Each `station` belongs to one program, so the database can support multiple bike-share systems in one schema.

| Column | Data Type | Nullable | Notes |
|--------|-----------|----------|-------|
| program_id | text | No | Primary key |
| country | text | No | Uses `country_code2` domain |
| name | text | No | Program name |
| short_name | text | Yes | Short display name |
| location_text | text | Yes | City/location text |
| phone | text | Yes | Uses `phone_text` domain |
| email | text | Yes | Uses `email_text` domain |
| timezone | text | Yes | Program timezone |
| url | text | Yes | Program URL |
| created_at | timestamptz | No | Default `now()` |

#### `station`

Purpose: stores the physical bike pickup and return stations managed by each program.  
Design and relationships: `station` connects to `program`, `dock`, `bike_status`, `station_status`, and `trip`. It is one of the main operational tables because most activity starts or ends at a station.

| Column | Data Type | Nullable | Notes |
|--------|-----------|----------|-------|
| station_id | text | No | Primary key |
| program_id | text | No | Foreign key to `program(program_id)` |
| name | text | No | Station name |
| short_name | text | Yes | Short display name |
| address | text | No | Street address |
| postal_code | text | Yes | Postal code |
| contact_phone | text | Yes | Contact number |
| lat | numeric | No | Latitude |
| lon | numeric | No | Longitude |
| capacity | integer | No | Dock capacity |
| created_at | timestamptz | No | Default `now()` |

#### `dock`

Purpose: stores the individual docking points available at each station.  
Design and relationships: `dock` is a child table of `station`. It is also used by `bike_status` when a bike is parked in a specific dock. The unique constraint on `(station_id, dock_number)` prevents duplicate dock numbers inside the same station.

| Column | Data Type | Nullable | Notes |
|--------|-----------|----------|-------|
| dock_id | bigint | No | Primary key |
| station_id | text | No | Foreign key to `station(station_id)` |
| dock_number | integer | No | Unique per station |
| is_active | boolean | No | Default `true` |
| created_at | timestamptz | No | Default `now()` |

#### `bike`

Purpose: stores the bicycle fleet and the static details of each bike.  
Design and relationships: `bike` is referenced by `bike_status` and `trip`. Static bike information is kept here so it does not need to be repeated in every status or trip record.

| Column | Data Type | Nullable | Notes |
|--------|-----------|----------|-------|
| bike_id | text | No | Primary key |
| bike_type | bike_type | No | Enum type |
| make | text | Yes | Manufacturer |
| model | text | Yes | Model |
| color | text | Yes | Color |
| year_acquired | integer | Yes | Acquisition year |
| created_at | timestamptz | No | Default `now()` |

#### `bike_status`

Purpose: stores historical status and location snapshots for each bicycle.  
Design and relationships: `bike_status` is a time-based history table connected to `bike`, and optionally to `station` and `dock`. It supports both current-state reporting and historical tracking.

| Column | Data Type | Nullable | Notes |
|--------|-----------|----------|-------|
| bike_status_id | bigint | No | Primary key |
| bike_id | text | No | Foreign key to `bike(bike_id)` |
| recorded_at | timestamptz | No | Status timestamp |
| state | bike_state | No | Enum type |
| station_id | text | Yes | Foreign key to `station(station_id)` |
| dock_id | bigint | Yes | Foreign key to `dock(dock_id)` |
| lat | numeric | Yes | Latitude |
| lon | numeric | Yes | Longitude |
| battery_pct | numeric | Yes | Battery percentage |
| remaining_range_km | numeric | Yes | Remaining range |

#### `station_status`

Purpose: stores historical operational snapshots for each station.  
Design and relationships: `station_status` is a time-based table at the station level. It stores bike counts, dock counts, and rental/return flags, which is useful for dashboards and reporting.

| Column | Data Type | Nullable | Notes |
|--------|-----------|----------|-------|
| station_status_id | bigint | No | Primary key |
| station_id | text | No | Foreign key to `station(station_id)` |
| reported_at | timestamptz | No | Status timestamp |
| bikes_available_electric | integer | No | Default `0` |
| bikes_available_smart | integer | No | Default `0` |
| bikes_available_classic | integer | No | Default `0` |
| bikes_available_cargo | integer | No | Default `0` |
| bikes_available_total | integer | No | Total available bikes |
| docks_available_total | integer | No | Total available docks |
| is_accepting_returns | boolean | No | Default `true` |
| is_renting | boolean | No | Default `true` |

#### `membership_type`

Purpose: stores the membership products offered by the system.  
Design and relationships: `membership_type` defines products such as daily, monthly, and annual plans. It is referenced by `membership`, which stores actual rider purchases. This avoids repeating the same product rules many times.

| Column | Data Type | Nullable | Notes |
|--------|-----------|----------|-------|
| membership_type_id | smallint | No | Primary key |
| kind | membership_kind | No | Enum type, unique |
| duration | interval | No | Membership duration |
| description | text | Yes | Description |

#### `rider_account`

Purpose: stores customer accounts for riders.  
Design and relationships: `rider_account` is referenced by `membership` and `trip`, linking customer identity to both memberships and ride history.

| Column | Data Type | Nullable | Notes |
|--------|-----------|----------|-------|
| rider_id | bigint | No | Primary key |
| email | text | No | Unique |
| full_name | text | Yes | Rider name |
| created_at | timestamptz | No | Default `now()` |

#### `membership`

Purpose: stores purchased memberships for riders, including start and expiry information.  
Design and relationships: `membership` links `rider_account` and `membership_type`. It stores purchase history over time and makes it possible to check whether a rider had a valid membership at the time of a trip.

| Column | Data Type | Nullable | Notes |
|--------|-----------|----------|-------|
| membership_id | bigint | No | Primary key |
| rider_id | bigint | No | Foreign key to `rider_account(rider_id)` |
| membership_type_id | smallint | No | Foreign key to `membership_type(membership_type_id)` |
| purchased_at | timestamptz | No | Purchase timestamp |
| expires_at | timestamptz | No | Expiration timestamp |

#### `trip`

Purpose: stores completed or active rides, including start, end, duration, and cost.  
Design and relationships: `trip` links a rider, a bike, and the start and end stations. It is the main transaction table for ride history and works together with `bike_status` and `station_status`, which store snapshots rather than trip summaries.

| Column | Data Type | Nullable | Notes |
|--------|-----------|----------|-------|
| trip_id | bigint | No | Primary key |
| rider_id | bigint | No | Foreign key to `rider_account(rider_id)` |
| bike_id | text | No | Foreign key to `bike(bike_id)` |
| start_station_id | text | No | Foreign key to `station(station_id)` |
| end_station_id | text | Yes | Foreign key to `station(station_id)` |
| started_at | timestamptz | No | Trip start |
| ended_at | timestamptz | Yes | Trip end |
| distance_km | numeric | Yes | Distance traveled |
| elapsed_seconds | integer | Yes | Trip duration |
| cost_cents | integer | Yes | Trip cost |

## 3. Impact of Data Types on Storage and Query Performance

The schema uses several datatype choices that affect both storage and query behavior.

The identifiers `program_id`, `station_id`, and `bike_id` are stored as `text` instead of integer keys. This makes the values easier to read and closer to real business identifiers, but it also increases table and index size compared with integers.

The schema uses enums for `bike.bike_type`, `bike_status.state`, and `membership_type.kind`. Enums are safer than free-text categories because they allow only valid values and avoid repeated long strings.

Coordinates, battery percentage, remaining range, and trip distance use `numeric` types. This gives better precision and validation, which is useful for geographic and billing-related values, but it usually uses more storage and CPU than floating-point types.

The use of `timestamptz` in `bike_status`, `station_status`, `membership`, and `trip` is also important. It uses more storage than a simple date field, but it keeps time values unambiguous across time zones.

Overall, the datatype choices in this database favor correctness, readability, and data quality over the smallest possible storage size.

## 4. Impact of Indexes on Storage and Query Performance

Indexes improve query speed, but they also take extra storage space and add work during inserts and updates. This can be seen in the relation-size results, where total relation size is larger than heap size.

The main indexes in this schema are:

- `station_program_id_idx`
- `dock_station_id_idx`
- `bike_status_bike_time_idx`
- `bike_status_station_time_idx`
- `station_status_station_time_idx`
- `membership_rider_idx`
- `trip_rider_time_idx`
- `trip_bike_time_idx`

The execution plans showed that index usage depends on table size.

The rider-history query on `trip` did not use `trip_rider_time_idx` in the final rerunnable test. PostgreSQL chose a sequential scan because the `trip` table has only two rows in the minimal sample dataset, so scanning the whole table was cheaper.

The `bike_status` query on `HB-0001` also used a sequential scan and then sorted the three matching rows. Again, the table is so small that a full scan costs less than using the index.

The `station` query with `capacity >= 15` also used a sequential scan for the same reason.

This shows an important point: having an index does not mean PostgreSQL will always use it. PostgreSQL chooses the cheapest plan based on table size, row estimates, and total cost. In this small sample dataset, sequential scans were cheaper. As the database grows, the indexes should become more useful.

## 5. Roles and Privileges

The required roles created for the Bcycle database are `bcycle_reader`, `bcycle_admin`, and `bcycle_account_admin`.

### `bcycle_reader`

This is the least-privileged role. It has `CONNECT` on the database, `USAGE` on the `public` schema, and `SELECT` on all tables in the schema. It cannot create new objects. This role is useful for users who only need to read data, such as report viewers or auditors.

### `bcycle_admin`

This is the main administrative role. It can execute all procedures and functions created in assignment 2. It was also given the table and sequence privileges needed by procedures that are not defined with `SECURITY DEFINER`. This role is appropriate for a system administrator or database operator who manages the Bcycle system.

### `bcycle_account_admin`

This is a limited administrator role. It can execute only the procedures needed to create a new account, purchase a membership, and start a trip. These procedures were defined with `SECURITY DEFINER` and a fixed `search_path`, so the role can perform the intended business actions without broad direct table access. This role fits an account-management job where the user should not have full administrative power.

### `bcycle_support_staff`

This is a group role created for customer support staff. It has read access to rider, membership, trip, station, and bike data. This role is useful for support workers who need to answer customer questions, check memberships, and review trip history, but who should not change database objects or perform administrative actions.

### `bcycle_ops_manager`

This is an individual login role. It inherits both `bcycle_admin` and `bcycle_reader`. This makes it suitable for an operations manager who needs both administrative procedure access and full read access for reporting and oversight.

### Privilege for All Users

One privilege that is important to grant to all users is `CONNECT` on the database. Without `CONNECT`, no user can access the system.

## 6. Difficulty in Part (c)

Part (c) was harder than parts (a) and (b) because granting `EXECUTE` on a procedure is not always enough in PostgreSQL. By default, procedures run with the privileges of the calling user. That means a restricted role may still need direct `INSERT`, `SELECT`, `UPDATE`, or sequence privileges on the underlying tables.

This was solved by defining the sensitive procedures `create_account_sp`, `purchase_membership_sp`, and `start_trip_sp` with:

- `SECURITY DEFINER`
- `SET search_path = public, pg_temp`

With this approach, the procedures run with the owner's privileges instead of the caller's privileges, while the fixed `search_path` reduces security risk. This makes it possible to keep the account-administrator role limited while still letting it perform the needed actions.

## 7. Execution Note

The analysis was performed on the Bcycle database using the minimal sample data loaded by the submission schema and seed scripts.

## 8. Conclusion

The Bcycle schema shows how storage, datatypes, indexing, and role-based security work together in PostgreSQL. Text business identifiers and `numeric` types improve readability and precision, while indexes support common lookup and history queries. The role design also shows the difference between direct table privileges and controlled procedure-based access.

## 9. AI Use

AI was used to generate tests, seed data, and code comments.
