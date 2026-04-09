## Group member contributions

One team member completed all parts of the assignment deliverables

## Procedures
- **create_account_sp**: Registers a new rider. Validates email and uniqueness.
- **purchase_membership_sp**: Purchases membership for a rider. Checks membership type and sets expiry.
- **create_station_sp**: Adds a station. Validates program and station ID.
- **create_bicycle_sp**: Adds a bike. Ensures unique bike ID.
- **add_dock_sp**: Adds a dock to a station. Validates station existence.
- **start_trip_sp**: Starts a trip for a rider and bike. Records start time.
- **end_trip_sp**: Ends a trip. Updates trip details and records end time.

## Function
- **get_rider_statistics_fn**: Returns trip count, total distance, and total time for a rider.

### Triggers
- **trip_insert_audit_trg**: Logs every new trip to trip_audit for auditing.
- **station_status_update_trg**: Updates station_status after a trip ends.

## Design 
- All procedures validate input and ensure referential integrity
- Triggers  to automate audit logging and station status updates
- Minimal error handling

## Testing
Test sequences for all procedures, function, and triggers are included in example_tests.sql. See tests.png for visual test results.

![Test Results](tests.png)

## AI
Ai was used to generate tests and comments. 
