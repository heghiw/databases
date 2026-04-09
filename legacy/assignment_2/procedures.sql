
-- 1. CREATE_ACCOUNT_SP
 
CREATE OR REPLACE PROCEDURE create_account_sp(
    p_email text,
    p_full_name text DEFAULT NULL
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_rider_id bigint;
BEGIN
    IF p_email IS NULL OR TRIM(p_email) = '' THEN
        RAISE EXCEPTION 'Email address cannot be null or empty';
    END IF;
    IF POSITION('@' IN p_email) < 2 THEN
        RAISE EXCEPTION 'Invalid email format: %', p_email;
    END IF;
    IF EXISTS (SELECT 1 FROM rider_account WHERE email = p_email) THEN
        RAISE EXCEPTION 'Email address already registered: %', p_email;
    END IF;
    INSERT INTO rider_account (email, full_name)
    VALUES (p_email, p_full_name)
    RETURNING rider_id INTO v_rider_id;
    RAISE NOTICE 'Created account with rider_id: %', v_rider_id;
END;
$$;

 
-- 2. PURCHASE_MEMBERSHIP_SP
 
CREATE OR REPLACE PROCEDURE purchase_membership_sp(
    p_rider_id bigint,
    p_membership_type_id smallint
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_membership_id bigint;
    v_duration interval;
    v_purchased_at timestamptz;
    v_expires_at timestamptz;
BEGIN
    SELECT duration INTO v_duration FROM membership_type WHERE membership_type_id = p_membership_type_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Membership type not found: %', p_membership_type_id;
    END IF;
    v_purchased_at := now();
    v_expires_at := v_purchased_at + v_duration;
    INSERT INTO membership (rider_id, membership_type_id, purchased_at, expires_at)
    VALUES (p_rider_id, p_membership_type_id, v_purchased_at, v_expires_at)
    RETURNING membership_id INTO v_membership_id;
    RAISE NOTICE 'Purchased membership with id: %', v_membership_id;
END;
$$;

 
-- 3. CREATE_STATION_SP
 
CREATE OR REPLACE PROCEDURE create_station_sp(
    p_station_id text,
    p_program_id text,
    p_name text,
    p_address text,
    p_lat numeric(9,6),
    p_lon numeric(9,6),
    p_capacity integer,
    p_short_name text DEFAULT NULL,
    p_postal_code text DEFAULT NULL,
    p_contact_phone text DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_station_id IS NULL OR TRIM(p_station_id) = '' THEN
        RAISE EXCEPTION 'Station ID cannot be null or empty';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM program WHERE program_id = p_program_id) THEN
        RAISE EXCEPTION 'Program not found: %', p_program_id;
    END IF;
    INSERT INTO station (
        station_id, program_id, name, short_name, address, postal_code, contact_phone, lat, lon, capacity
    ) VALUES (
        p_station_id, p_program_id, p_name, p_short_name, p_address, p_postal_code, p_contact_phone, p_lat, p_lon, p_capacity
    );
    RAISE NOTICE 'Created station %', p_station_id;
END;
$$;

 
-- 4. CREATE_BICYCLE_SP
 
CREATE OR REPLACE PROCEDURE create_bicycle_sp(
    p_bike_id text,
    p_bike_type bike_type,
    p_make text DEFAULT NULL,
    p_model text DEFAULT NULL,
    p_color text DEFAULT NULL,
    p_year_acquired integer DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_bike_id IS NULL OR TRIM(p_bike_id) = '' THEN
        RAISE EXCEPTION 'Bike ID cannot be null or empty';
    END IF;
    IF EXISTS (SELECT 1 FROM bike WHERE bike_id = p_bike_id) THEN
        RAISE EXCEPTION 'Bike already exists: %', p_bike_id;
    END IF;
    INSERT INTO bike (bike_id, bike_type, make, model, color, year_acquired)
    VALUES (p_bike_id, p_bike_type, p_make, p_model, p_color, p_year_acquired);
    RAISE NOTICE 'Created bike %', p_bike_id;
END;
$$;

 
-- 5. ADD_DOCK_SP
 
CREATE OR REPLACE PROCEDURE add_dock_sp(
    p_station_id text,
    p_dock_number integer,
    p_is_active boolean DEFAULT true
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM station WHERE station_id = p_station_id) THEN
        RAISE EXCEPTION 'Station not found: %', p_station_id;
    END IF;
    INSERT INTO dock (station_id, dock_number, is_active)
    VALUES (p_station_id, p_dock_number, p_is_active);
    RAISE NOTICE 'Created dock % at station %', p_dock_number, p_station_id;
END;
$$;

 
-- 6. START_TRIP_SP
 
CREATE OR REPLACE PROCEDURE start_trip_sp(
    p_rider_id bigint,
    p_bike_id text,
    p_start_station_id text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_trip_id bigint;
    v_started_at timestamptz;
BEGIN
    v_started_at := now();
    INSERT INTO trip (rider_id, bike_id, start_station_id, started_at)
    VALUES (p_rider_id, p_bike_id, p_start_station_id, v_started_at)
    RETURNING trip_id INTO v_trip_id;
    RAISE NOTICE 'Started trip %', v_trip_id;
END;
$$;

 
-- 7. END_TRIP_SP
 
CREATE OR REPLACE PROCEDURE end_trip_sp(
    p_trip_id bigint,
    p_end_station_id text,
    p_distance_km numeric(9,3),
    p_cost_cents integer
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_ended_at timestamptz;
BEGIN
    v_ended_at := now();
    UPDATE trip
    SET end_station_id = p_end_station_id,
        ended_at = v_ended_at,
        distance_km = p_distance_km,
        cost_cents = p_cost_cents
    WHERE trip_id = p_trip_id;
    RAISE NOTICE 'Ended trip %', p_trip_id;
END;
$$;

 
-- STORED FUNCTION
 
CREATE OR REPLACE FUNCTION get_rider_statistics_fn(p_rider_id bigint)
RETURNS TABLE (
    trip_count bigint,
    total_distance_km numeric,
    total_time_minutes numeric
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT COUNT(*), COALESCE(SUM(distance_km),0), COALESCE(SUM(elapsed_seconds)/60.0,0)
    FROM trip WHERE rider_id = p_rider_id AND ended_at IS NOT NULL;
END;
$$;
-- Example usage:
-- SELECT * FROM get_rider_statistics_fn(1);

 
-- TRIGGERS
 
-- Row-level trigger: Audit log for trip insert
CREATE TABLE trip_audit (
    audit_id bigserial PRIMARY KEY,
    trip_id bigint,
    action text,
    changed_at timestamptz
);

CREATE OR REPLACE FUNCTION trip_insert_audit_fn()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO trip_audit (trip_id, action, changed_at)
    VALUES (NEW.trip_id, 'INSERT', now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trip_insert_audit_trg
AFTER INSERT ON trip
FOR EACH ROW
EXECUTE FUNCTION trip_insert_audit_fn();

-- Statement-level trigger: Station status update after trip end
CREATE OR REPLACE FUNCTION station_status_update_fn()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE station_status
    SET bikes_available_total = bikes_available_total + 1
    WHERE station_id = NEW.end_station_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER station_status_update_trg
AFTER UPDATE OF ended_at ON trip
FOR EACH STATEMENT
EXECUTE FUNCTION station_status_update_fn();

