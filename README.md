# Databases Portfolio

This repository is organized as a course portfolio for the Bcycle database work.

## Structure

- `assignments/assignment_3/` - current final assignment bundle with schema, seed data, procedures, roles, analysis queries, report, and test artifacts
- `legacy/assignment_1/` - assignment 1 database design, schema, seed data, exports, and submitted report files
- `legacy/assignment_2/` - assignment 2 programming work, procedures, setup scripts, and test artifacts
- `submissions/` - submitted archive files

## Notes

- Earlier assignments were moved under `legacy/` to keep the repository root clean.
- Assignment-specific documentation lives inside each assignment folder.

## How to Run

The current runnable submission is in `assignments/assignment_3/`.

### Run the Full Assignment 3 Bundle

Use PostgreSQL `psql` from the repository root and run the files in this order:

```powershell
psql -U postgres -d is309_assignment1 -f .\assignments\assignment_3\schema.sql
psql -U postgres -d is309_assignment1 -f .\assignments\assignment_3\seed.sql
psql -U postgres -d is309_assignment1 -f .\assignments\assignment_3\procedures.sql
psql -U postgres -d is309_assignment1 -f .\assignments\assignment_3\assignment3_roles.sql
psql -U postgres -d is309_assignment1 -f .\assignments\assignment_3\assignment3_analysis.sql
```

If `psql` is not in your `PATH`, use the full path to your local PostgreSQL installation.

### Outputs

- The final report is in `assignments/assignment_3/assignment3_report.md`.
- Assignment-specific instructions are in `assignments/assignment_3/README.md`.
