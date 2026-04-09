-- Insert all stations into station_status with default values
INSERT INTO station_status (
    station_id, reported_at, bikes_available_electric, bikes_available_smart, bikes_available_classic, bikes_available_cargo, bikes_available_total, docks_available_total, is_accepting_returns, is_renting
)
SELECT 
    station_id,
    now(),
    0, 0, 0, 0, 0, 0,
    true, true
FROM station;
-- Run this SQL after seeding stations to ensure every station has a status record.
