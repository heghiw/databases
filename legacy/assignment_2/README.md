# IS-309 Assignment 2 - Database Programming Documentation

## Overview

This document describes the stored procedures, stored function, and triggers implemented for the Bcycle bike-sharing database system. The code is located in `procedures.sql`.

All procedures include **comprehensive error handling** with custom error codes, detailed messages, and helpful hints.

---

## Table of Contents

1. [Error Handling](#error-handling)
2. [Stored Procedures](#stored-procedures)
   - [CREATE_ACCOUNT_SP](#1-create_account_sp)
   - [PURCHASE_MEMBERSHIP_SP](#2-purchase_membership_sp)
   - [CREATE_STATION_SP](#3-create_station_sp)
   - [CREATE_BICYCLE_SP](#4-create_bicycle_sp)
   - [ADD_DOCK_SP](#5-add_dock_sp)
   - [START_TRIP_SP](#6-start_trip_sp)
   - [END_TRIP_SP](#7-end_trip_sp)
3. [Stored Function](#stored-function)
   - [GET_RIDER_STATISTICS_FN](#get_rider_statistics_fn)
4. [Triggers](#triggers)
   - [Row-Level Trigger: trg_validate_membership_purchase](#row-level-trigger-trg_validate_membership_purchase)
   - [Statement-Level Trigger: trg_log_station_changes](#statement-level-trigger-trg_log_station_changes)
5. [Test Scripts](#test-scripts)
6. [Group Contributions](#group-contributions)

---

## Error Handling

All procedures use a consistent error handling approach with custom error codes:

| Error Code | Category | Description |
|------------|----------|-------------|
| `P0001` | General Error | Unexpected application error |
| `P0002` | Not Found | Entity does not exist (rider, station, bike, etc.) |
| `P0003` | Validation Error | Invalid input (null, wrong format, out of range) |
| `P0004` | Business Rule | Violation of business logic (duplicates, conflicts) |
| `P0005` | Unavailable | Resource not available (bike in use, no docks) |

Each error includes:
- **MESSAGE**: Clear description of what went wrong
- **DETAIL**: Specific values that caused the error
- **HINT**: How to fix the problem

---

## Stored Procedures

### 1. CREATE_ACCOUNT_SP

**Purpose:** Add a new rider account to the `rider_account` table.

**Type:** FUNCTION (returns value)

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `p_email` | text | Yes | Email address of the new rider |
| `p_full_name` | text | No | Full name of the rider |

**Returns:** `bigint` - The `rider_id` of the newly created account

**Example:**
```sql
SELECT create_account_sp('john.doe@example.com', 'John Doe');
-- Returns: 3 (new rider_id)
```

**Logic:**
1. Validate email is not null or empty
2. Validate email format (must contain @)
3. Check email doesn't already exist
4. Insert new row into `rider_account` table
5. Return the new `rider_id`

**Error Handling:**
| Error Code | Condition |
|------------|-----------|
| P0003 | Email is null, empty, or invalid format |
| P0004 | Email already registered |

---

### 2. PURCHASE_MEMBERSHIP_SP

**Purpose:** Add a new membership to the `membership` table for an existing rider.

**Type:** FUNCTION (returns value)

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `p_rider_id` | bigint | Yes | ID of the rider purchasing membership |
| `p_membership_type_id` | smallint | Yes | Type of membership (1=daily, 2=monthly, 3=annual) |

**Returns:** `bigint` - The `membership_id` of the newly created membership

**Example:**
```sql
SELECT purchase_membership_sp(1, 2::smallint);
-- Returns: 5 (new membership_id for monthly pass)
```

**Logic:**
1. Validate inputs are not null
2. Verify rider exists
3. Look up membership duration from `membership_type` table
4. Check for existing active membership of same type
5. Calculate expiration date
6. Insert into `membership` table
7. Return the new `membership_id`

**Error Handling:**
| Error Code | Condition |
|------------|-----------|
| P0003 | Rider ID or membership type is null |
| P0002 | Rider not found |
| P0002 | Membership type not found |
| P0004 | Rider already has active membership of this type |

---

### 3. CREATE_STATION_SP

**Purpose:** Add a new station to the `station` table.

**Type:** PROCEDURE (no return value)

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `p_station_id` | text | Yes | Unique station identifier (e.g., 'bcycle_heartland_1920') |
| `p_program_id` | text | Yes | ID of the program this station belongs to |
| `p_name` | text | Yes | Full name of the station |
| `p_address` | text | Yes | Street address |
| `p_lat` | numeric(9,6) | Yes | Latitude coordinate (-90 to 90) |
| `p_lon` | numeric(9,6) | Yes | Longitude coordinate (-180 to 180) |
| `p_capacity` | integer | Yes | Number of docking points (must be > 0) |
| `p_short_name` | text | No | Abbreviated station name |
| `p_postal_code` | text | No | ZIP/postal code |
| `p_contact_phone` | text | No | Contact phone number |

**Returns:** None

**Example:**
```sql
CALL create_station_sp(
    'bcycle_heartland_1920',
    'bcycle_heartland',
    'Central Park Station',
    '500 Central Park Ave',
    41.260000,
    -96.010000,
    15,
    'Central Park',
    '68102',
    '402-555-0100'
);
```

**Logic:**
1. Validate station_id format (lowercase alphanumeric + underscores)
2. Validate coordinates are within valid ranges
3. Validate capacity is positive
4. Verify program exists
5. Check station doesn't already exist
6. Insert new row into `station` table

**Error Handling:**
| Error Code | Condition |
|------------|-----------|
| P0003 | Station ID null, empty, or invalid format |
| P0003 | Latitude/longitude null or out of range |
| P0003 | Capacity null or <= 0 |
| P0002 | Program not found |
| P0004 | Station already exists |

---

### 4. CREATE_BICYCLE_SP

**Purpose:** Add a new bicycle to the `bike` table.

**Type:** FUNCTION (returns value)

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `p_bike_id` | text | Yes | Unique bike identifier (e.g., 'HB-0401') |
| `p_bike_type` | bike_type | Yes | Type: 'electric', 'smart', 'classic', or 'cargo' |
| `p_make` | text | No | Manufacturer name |
| `p_model` | text | No | Model name |
| `p_color` | text | No | Bike color |
| `p_year_acquired` | integer | No | Year the bike was acquired (1980 to current+1) |

**Returns:** `text` - The `bike_id` of the newly created bicycle

**Example:**
```sql
SELECT create_bicycle_sp('HB-0401', 'electric', 'GCM', 'Bcycle 3.0', 'silver', 2026);
-- Returns: 'HB-0401'
```

**Logic:**
1. Validate bike_id format (alphanumeric + underscores/hyphens)
2. Validate year_acquired if provided (1980 to current year + 1)
3. Check bike doesn't already exist
4. Insert new row into `bike` table
5. Return the `bike_id`

**Error Handling:**
| Error Code | Condition |
|------------|-----------|
| P0003 | Bike ID null, empty, or invalid format |
| P0003 | Year acquired out of valid range |
| P0004 | Bike already exists |

---

### 5. ADD_DOCK_SP

**Purpose:** Add a new dock to the `dock` table. Used when creating a new station or expanding an existing one.

**Type:** FUNCTION (returns value)

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `p_station_id` | text | Yes | ID of the station where dock is located |
| `p_dock_number` | integer | Yes | Dock number within the station (must be > 0) |
| `p_is_active` | boolean | No | Whether dock is active (default: true) |

**Returns:** `bigint` - The `dock_id` of the newly created dock

**Example:**
```sql
SELECT add_dock_sp('bcycle_heartland_1917', 10, true);
-- Returns: 25 (new dock_id)
```

**Logic:**
1. Validate station_id is not null or empty
2. Validate dock_number is positive
3. Verify station exists (get name and capacity)
4. Warn if dock number exceeds station capacity
5. Check dock number doesn't already exist at station
6. Insert new row into `dock` table
7. Return the auto-generated `dock_id`

**Error Handling:**
| Error Code | Condition |
|------------|-----------|
| P0003 | Station ID null or empty |
| P0003 | Dock number null or <= 0 |
| P0002 | Station not found |
| P0004 | Dock number already exists at this station |

---

### 6. START_TRIP_SP

**Purpose:** Start a new trip. Records the bicycle, start station, and rider. Updates bike status and station status to reflect the bike being removed from the dock.

**Type:** FUNCTION (returns value)

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `p_rider_id` | bigint | Yes | ID of the rider starting the trip |
| `p_bike_id` | text | Yes | ID of the bicycle being rented |
| `p_start_station_id` | text | Yes | ID of the station where trip begins |

**Returns:** `bigint` - The `trip_id` of the newly created trip

**Example:**
```sql
SELECT start_trip_sp(1, 'HB-0001', 'bcycle_heartland_1917');
-- Returns: 3 (new trip_id)
```

**Logic:**
1. Validate all inputs are not null/empty
2. Verify rider exists
3. Verify bike exists
4. Verify station exists
5. Check rider has active membership
6. Check rider doesn't have another trip in progress
7. Check bike status (available, not in use/maintenance)
8. Verify bike is at the specified station
9. Find the dock where bike is located
10. Create trip record
11. Update bike status to 'in_use'
12. Update station status (decrement bikes, increment docks)

**Error Handling:**
| Error Code | Condition |
|------------|-----------|
| P0003 | Any input is null or empty |
| P0002 | Rider, bike, or station not found |
| P0004 | Rider has no active membership |
| P0004 | Rider already has trip in progress |
| P0005 | Bike is currently in use |
| P0005 | Bike is not available (maintenance) |
| P0005 | Bike is not at the specified station |

**Tables Modified:**
- `trip` (INSERT)
- `bike_status` (INSERT)
- `station_status` (INSERT)

---

### 7. END_TRIP_SP

**Purpose:** End an existing trip. Records the end time, duration, distance, cost, and end station. Updates bike status and station status to reflect the bike being returned to a dock.

**Type:** PROCEDURE (no return value)

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `p_trip_id` | bigint | Yes | ID of the trip to end |
| `p_end_station_id` | text | Yes | ID of the station where trip ends |
| `p_distance_km` | numeric(9,3) | Yes | Total distance traveled (>= 0) |
| `p_cost_cents` | integer | Yes | Trip cost in cents (>= 0) |

**Returns:** None

**Example:**
```sql
CALL end_trip_sp(3, 'bcycle_heartland_1918', 2.350, 150);
```

**Logic:**
1. Validate all inputs
2. Get trip details (bike_id, started_at)
3. Check trip hasn't already ended
4. Verify end station exists
5. Calculate elapsed time in seconds
6. Warn if duration exceeds 24 hours
7. Find available dock at end station
8. Update trip record with end details
9. Update bike status to 'available' at new dock
10. Update station status (increment bikes, decrement docks)

**Error Handling:**
| Error Code | Condition |
|------------|-----------|
| P0003 | Any input is null or invalid |
| P0003 | Distance or cost is negative |
| P0002 | Trip not found |
| P0004 | Trip has already ended |
| P0002 | End station not found |
| P0005 | No available dock at station |

**Tables Modified:**
- `trip` (UPDATE)
- `bike_status` (INSERT)
- `station_status` (INSERT)

---

## Stored Function

### GET_RIDER_STATISTICS_FN

**Purpose:** Calculate comprehensive trip statistics for a rider.

**Business Justification:**
1. **Loyalty Programs:** Track rider usage to award points, badges, or discounts based on total trips, distance traveled, or time spent riding.
2. **Usage Analytics:** Generate reports for individual riders showing their activity patterns, helping the business understand user engagement.
3. **Rider Dashboard:** Provide data for a mobile app or website where riders can view their personal statistics and achievements.
4. **Customer Service:** Quickly look up a rider's history when handling support requests or disputes.
5. **Environmental Impact:** Calculate carbon savings by showing total distance traveled by bike instead of car.

**Type:** FUNCTION (returns table)

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `p_rider_id` | bigint | Yes | ID of the rider |

**Returns:** Table with columns:

| Column | Type | Description |
|--------|------|-------------|
| `trip_count` | bigint | Total number of completed trips |
| `total_distance_km` | numeric | Sum of all trip distances |
| `total_time_minutes` | numeric | Sum of all trip durations in minutes |
| `avg_trip_distance_km` | numeric | Average distance per trip |
| `avg_trip_duration_minutes` | numeric | Average duration per trip |
| `first_trip_date` | timestamptz | When the rider first used the service |
| `last_trip_date` | timestamptz | When the rider last used the service |
| `favorite_start_station` | text | Station name most frequently used to start trips |
| `favorite_end_station` | text | Station name most frequently used to end trips |

**Example:**
```sql
-- Execute the stored function
SELECT * FROM get_rider_statistics_fn(1);
```

**Expected Result:**
| trip_count | total_distance_km | total_time_minutes | avg_trip_distance_km | avg_trip_duration_minutes | first_trip_date | last_trip_date | favorite_start_station | favorite_end_station |
|------------|-------------------|-------------------|----------------------|--------------------------|-----------------|----------------|----------------------|---------------------|
| 1 | 2.350 | 13.00 | 2.350 | 13.00 | 2026-03-05 08:15:00-06 | 2026-03-05 08:15:00-06 | 67th & Pine | Downtown Library |

**Error Handling:**
| Error Code | Condition |
|------------|-----------|
| P0002 | Rider not found |

---

## Triggers

### Row-Level Trigger: trg_validate_membership_purchase

**Purpose:** Validate membership purchases BEFORE insertion to enforce business rules and data integrity.

**Trigger Type:** `BEFORE INSERT`, `FOR EACH ROW`

**Table:** `membership`

**Why Row-Level?**
Each individual membership record needs to be validated independently. The trigger fires FOR EACH ROW being inserted, allowing us to check the specific values in that row against existing data.

**Validation Rules:**
1. **Rider Existence:** The rider_id must reference a valid account
2. **Duplicate Prevention:** Rider cannot have an active (non-expired) membership of the same type
3. **Date Validation:** Expiration date must be after purchase date

**Logic Flow:**
```
1. Check if NEW.rider_id exists in rider_account table
2. If not found → RAISE EXCEPTION (P0002)
3. Get membership type name for error messages
4. Check if rider has unexpired membership of same type
5. If duplicate found → RAISE EXCEPTION (P0004)
6. Validate expires_at > purchased_at
7. If invalid dates → RAISE EXCEPTION (P0003)
8. All checks pass → RETURN NEW (allow insert)
```

**Trigger Function:** `fn_validate_membership_purchase()`

**Example - Success:**
```sql
INSERT INTO membership (rider_id, membership_type_id, purchased_at, expires_at)
VALUES (1, 2, now(), now() + interval '31 days');
-- NOTICE: [ROW TRIGGER] Membership purchase validated: monthly membership for rider 1
```

**Example - Failure (duplicate):**
```sql
INSERT INTO membership (rider_id, membership_type_id, purchased_at, expires_at)
VALUES (1, 2, now(), now() + interval '31 days');
-- ERROR: Duplicate membership not allowed
-- DETAIL: Rider alex.rider@example.com already has an active monthly membership
-- HINT: Wait for the current membership to expire or choose a different type
```

---

### Statement-Level Trigger: trg_log_station_changes

**Purpose:** Log all station management operations (INSERT/UPDATE/DELETE) to an audit table for monitoring and compliance.

**Trigger Type:** `AFTER INSERT OR UPDATE OR DELETE`, `FOR EACH STATEMENT`

**Table:** `station`

**Why Statement-Level?**
- Fires ONCE per SQL statement, not once per row
- Efficient for bulk operations (inserting 100 stations = 1 log entry)
- Appropriate when we care about "an operation happened" rather than tracking each individual row change
- Reduces audit table growth compared to row-level logging

**Use Cases:**
1. **Audit Trail:** Maintain a record of when stations were added, modified, or removed
2. **Change Tracking:** Understand the history of station network changes over time
3. **Security Monitoring:** Detect unauthorized or suspicious bulk changes
4. **Debugging:** Troubleshoot issues by showing when changes occurred

**Audit Table Structure:** `station_audit_log`

| Column | Type | Description |
|--------|------|-------------|
| `log_id` | bigserial | Primary key |
| `operation` | text | 'INSERT', 'UPDATE', or 'DELETE' |
| `operation_timestamp` | timestamptz | When the operation occurred |
| `user_name` | text | Database user who performed the operation |
| `client_info` | text | Client IP address |
| `message` | text | Description of the operation |

**Trigger Function:** `fn_log_station_changes()`

**Example:**
```sql
-- Create a new station
CALL create_station_sp('bcycle_heartland_test', 'bcycle_heartland', 
                       'Test Station', '100 Test Ave', 41.25, -96.0, 5);
-- NOTICE: [STATEMENT TRIGGER] Station INSERT operation logged | User: postgres | Time: 2026-03-17...

-- View the audit log
SELECT * FROM station_audit_log ORDER BY operation_timestamp DESC;
```

| log_id | operation | operation_timestamp | user_name | message |
|--------|-----------|---------------------|-----------|---------|
| 1 | INSERT | 2026-03-17 10:30:00 | postgres | New station(s) added to the network |

---

## Test Scripts

The following test scripts are included in `procedures.sql`. Run these to test and capture screenshots:

### Test Stored Function
```sql
-- Get rider statistics (CAPTURE SCREENSHOT OF THIS)
SELECT * FROM get_rider_statistics_fn(1);

-- Alternative formatted output
SELECT 
    trip_count AS "Total Trips",
    total_distance_km || ' km' AS "Total Distance",
    total_time_minutes || ' min' AS "Total Time",
    avg_trip_distance_km || ' km' AS "Avg Distance",
    avg_trip_duration_minutes || ' min' AS "Avg Duration",
    TO_CHAR(first_trip_date, 'YYYY-MM-DD HH24:MI') AS "First Trip",
    TO_CHAR(last_trip_date, 'YYYY-MM-DD HH24:MI') AS "Last Trip",
    favorite_start_station AS "Favorite Start",
    favorite_end_station AS "Favorite End"
FROM get_rider_statistics_fn(1);
```

### Test Row-Level Trigger
```sql
-- This will show trigger validation message
INSERT INTO membership (rider_id, membership_type_id, purchased_at, expires_at)
VALUES (1, 3, now(), now() + interval '365 days');

-- This will fail with trigger error (non-existent rider)
INSERT INTO membership (rider_id, membership_type_id, purchased_at, expires_at)
VALUES (9999, 1, now(), now() + interval '1 day');
```

### Test Statement-Level Trigger
```sql
-- Create a station (triggers audit logging)
CALL create_station_sp('bcycle_heartland_test', 'bcycle_heartland', 
                       'Test Station', '100 Test Ave', 41.250000, -96.000000, 5);

-- View audit log (CAPTURE SCREENSHOT OF THIS)
SELECT * FROM station_audit_log ORDER BY operation_timestamp DESC;
```

### Test All Procedures
```sql
-- 1. Create account
SELECT create_account_sp('test@example.com', 'Test User');

-- 2. Purchase membership
SELECT purchase_membership_sp(1, 1::smallint);

-- 3. Create station
CALL create_station_sp('bcycle_heartland_1920', 'bcycle_heartland', 'New Station',
                       '200 New St', 41.260000, -96.010000, 12);

-- 4. Create bicycle
SELECT create_bicycle_sp('HB-0999', 'electric', 'GCM', 'Bcycle 3.0', 'silver', 2026);

-- 5. Add dock
SELECT add_dock_sp('bcycle_heartland_1917', 15);

-- 6. Start trip (requires valid setup - rider with membership, available bike)
SELECT start_trip_sp(1, 'HB-0001', 'bcycle_heartland_1917');

-- 7. End trip
CALL end_trip_sp(1, 'bcycle_heartland_1918', 2.5, 150);
```

---

## Group Contributions

| Member | Procedure(s) Implemented |
|--------|-------------------------|
| Member 1 | create_account_sp, purchase_membership_sp |
| Member 2 | create_station_sp, create_bicycle_sp |
| Member 3 | add_dock_sp, start_trip_sp |
| Member 4 | end_trip_sp, get_rider_statistics_fn, triggers |

---

## Files

| File | Description |
|------|-------------|
| `schema.sql` | Database schema (tables, domains, types) |
| `seed.sql` | Sample data for testing |
| `procedures.sql` | Stored procedures, function, and triggers |
| `readme_ass2.md` | This documentation |
