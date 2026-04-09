-- 1. Create rider
CALL create_account_sp('nn@uia.no', 'Javo Lando');

-- 2. Get rider_id
-- SELECT rider_id FROM rider_account WHERE email = 'nn@uia.no';

-- 3. Get membership_type_id for 'annual'
-- SELECT membership_type_id FROM membership_type WHERE kind = 'annual';

-- 4. Purchase membership
CALL purchase_membership_sp(10, 3);

-- 5. Create bike
CALL create_bicycle_sp('KRS-5555', 'smart', 'Bysykkel', 'KRS Smart', 'green', 2026);

-- 6. Add dock
CALL add_dock_sp('krs_uiagder', 18, true);

-- 7. Start trip
CALL start_trip_sp(10, 'KRS-5555', 'krs_uiagder');

-- 8. Get trip_id
-- SELECT trip_id FROM trip WHERE rider_id = 10 AND ended_at IS NULL;

-- 9. End trip
-- Replace 3 with actual trip_id
CALL end_trip_sp(3, 'krs_sentrum', 4.1, 0);

-- 10. Check rider statistics
SELECT * FROM get_rider_statistics_fn(10);

-- 11. Check audit log (trigger)
SELECT * FROM trip_audit WHERE trip_id = 3;

 
-- STATION_STATUS_UPDATE_TRG
 
-- 1. Check bikes_available_total before ending a trip
SELECT * FROM station_status WHERE station_id = 'krs_sentrum';

-- 2. End a trip (this should trigger station_status_update_trg)
-- Replace 3 with a valid trip_id and 'krs_sentrum' with a valid station_id
CALL end_trip_sp(3, 'krs_sentrum', 4.1, 0);

-- 3. Check bikes_available_total after ending the trip
SELECT * FROM station_status WHERE station_id = 'krs_sentrum';

 