-- Assignment 3: role creation and privilege grants for the Bcycle database

BEGIN;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'bcycle_reader') THEN
        CREATE ROLE bcycle_reader NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'bcycle_admin') THEN
        CREATE ROLE bcycle_admin NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'bcycle_account_admin') THEN
        CREATE ROLE bcycle_account_admin NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'bcycle_support_staff') THEN
        CREATE ROLE bcycle_support_staff NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'bcycle_ops_manager') THEN
        CREATE ROLE bcycle_ops_manager LOGIN PASSWORD 'uia_assignment000';
    END IF;
END
$$;

REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT CONNECT ON DATABASE is309_assignment1 TO PUBLIC;

GRANT USAGE ON SCHEMA public TO
    bcycle_reader,
    bcycle_admin,
    bcycle_account_admin,
    bcycle_support_staff,
    bcycle_ops_manager;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO bcycle_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO bcycle_reader;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO bcycle_admin;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO bcycle_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO bcycle_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT USAGE, SELECT ON SEQUENCES TO bcycle_admin;

GRANT EXECUTE ON PROCEDURE create_account_sp(text, text) TO bcycle_admin;
GRANT EXECUTE ON PROCEDURE purchase_membership_sp(bigint, smallint) TO bcycle_admin;
GRANT EXECUTE ON PROCEDURE create_station_sp(text, text, text, text, numeric, numeric, integer, text, text, text) TO bcycle_admin;
GRANT EXECUTE ON PROCEDURE create_bicycle_sp(bike_type, text, text, text, text, integer) TO bcycle_admin;
GRANT EXECUTE ON PROCEDURE add_dock_sp(text, integer, boolean) TO bcycle_admin;
GRANT EXECUTE ON PROCEDURE start_trip_sp(bigint, text, text) TO bcycle_admin;
GRANT EXECUTE ON PROCEDURE end_trip_sp(bigint, text, numeric, integer) TO bcycle_admin;
GRANT EXECUTE ON FUNCTION get_rider_statistics_fn(bigint) TO bcycle_admin;

GRANT EXECUTE ON PROCEDURE create_account_sp(text, text) TO bcycle_account_admin;
GRANT EXECUTE ON PROCEDURE purchase_membership_sp(bigint, smallint) TO bcycle_account_admin;
GRANT EXECUTE ON PROCEDURE start_trip_sp(bigint, text, text) TO bcycle_account_admin;

GRANT SELECT ON rider_account, membership, membership_type, trip, station, bike TO bcycle_support_staff;

GRANT bcycle_admin TO bcycle_ops_manager;
GRANT bcycle_reader TO bcycle_ops_manager;

COMMIT;
