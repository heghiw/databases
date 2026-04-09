# IS-309 Assignment 3 - Bcycle Storage, Dictionary, and Security

This folder is organized as a self-contained submission bundle for the Bcycle PostgreSQL database.

## Included Files

- `schema.sql` - base schema for the Bcycle database
- `seed.sql` - sample data used for testing and analysis
- `procedures.sql` - assignment 2 procedures, function, and triggers
- `assignment3_analysis.sql` - storage, size, page, data dictionary, and performance queries
- `assignment3_roles.sql` - roles and grants required for assignment 3
- `example_test.sql` - procedure and trigger test calls
- `assignment3_report.md` - polished write-up template aligned to the assignment requirements
- `run_assignment3.sql` - convenience script to load the full assignment bundle
- `CONTRIBUTIONS.md` - contribution statement

## Execution Order

Run the scripts in this order:

```sql
\i './schema.sql'
\i './seed.sql'
\i './procedures.sql'
\i './assignment3_roles.sql'
\i './assignment3_analysis.sql'
```

Or run everything at once:

```sql
\i './run_assignment3.sql'
```

## Notes

- The tables in this schema use the names `program`, `station`, `dock`, `bike`, `bike_status`, `station_status`, `membership_type`, `rider_account`, `membership`, and `trip`.
- The assignment prompt refers to `BC_*` names; in this submission, the equivalent Bcycle tables are the lowercase names above.
- For role part (c), `create_account_sp`, `purchase_membership_sp`, and `start_trip_sp` were defined with `SECURITY DEFINER` and a fixed `search_path` so a restricted account-administrator role can execute them without broad direct table privileges.
- `assignment3_analysis.sql` includes catalog queries and `EXPLAIN` examples. Run it after loading the schema and seed data so the report can be completed with real outputs.

## Suggested Submission Workflow

1. Use a dedicated assignment database.
2. Run `run_assignment3.sql`.
3. Save the outputs from `assignment3_analysis.sql`.
4. Paste the measured values into `assignment3_report.md`.
5. Submit this folder as the final assignment bundle.
