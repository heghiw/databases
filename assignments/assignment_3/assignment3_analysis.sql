-- Assignment 3: storage, size, physical structure, and data dictionary queries
-- Run after schema.sql, seed.sql, and procedures.sql.

\pset pager off

ANALYZE;

SELECT current_database() AS database_name,
       pg_size_pretty(pg_database_size(current_database())) AS database_size_pretty,
       pg_database_size(current_database()) AS database_size_bytes;

WITH target_tables AS (
    SELECT unnest(ARRAY[
        'program',
        'station',
        'dock',
        'bike',
        'bike_status',
        'station_status',
        'membership_type',
        'rider_account',
        'membership',
        'trip'
    ]) AS table_name
)
SELECT c.relname AS relation_name,
       c.reltuples::bigint AS estimated_rows,
       c.relpages AS heap_pages,
       pg_size_pretty(pg_relation_size(c.oid)) AS heap_size,
       pg_size_pretty(pg_indexes_size(c.oid)) AS indexes_size,
       pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size,
       pg_relation_size(c.oid) AS heap_size_bytes,
       pg_indexes_size(c.oid) AS indexes_size_bytes,
       pg_total_relation_size(c.oid) AS total_size_bytes
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
JOIN target_tables t ON t.table_name = c.relname
WHERE n.nspname = 'public'
ORDER BY pg_total_relation_size(c.oid) DESC, c.relname;

WITH rel_stats AS (
    SELECT c.oid,
           c.relname,
           GREATEST(c.reltuples, 0)::numeric AS estimated_rows,
           GREATEST(c.relpages, 0) AS heap_pages,
           pg_relation_size(c.oid) AS heap_size_bytes
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname IN (
          'program',
          'station',
          'dock',
          'bike',
          'bike_status',
          'station_status',
          'membership_type',
          'rider_account',
          'membership',
          'trip'
      )
)
SELECT relname AS relation_name,
       estimated_rows::bigint,
       heap_pages,
       CASE WHEN heap_pages > 0 THEN ROUND(estimated_rows / heap_pages, 2) END AS estimated_rows_per_page,
       CASE WHEN estimated_rows > 0 THEN ROUND(heap_size_bytes::numeric / estimated_rows, 2) END AS estimated_heap_bytes_per_row,
       CASE
           WHEN heap_size_bytes > 0 THEN 'Regular heap tuples stay on one page unless large values are TOASTed.'
           ELSE 'No heap storage yet.'
       END AS tuple_page_note
FROM rel_stats
ORDER BY relation_name;

SELECT c.relname AS table_name,
       CASE WHEN c.reltoastrelid = 0 THEN 'no' ELSE 'yes' END AS has_toast_table,
       CASE
           WHEN c.reltoastrelid = 0 THEN NULL
           ELSE pg_size_pretty(pg_total_relation_size(c.reltoastrelid))
       END AS toast_total_size
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname IN (
      'program',
      'station',
      'dock',
      'bike',
      'bike_status',
      'station_status',
      'membership_type',
      'rider_account',
      'membership',
      'trip'
  )
ORDER BY c.relname;

SELECT 'program' AS table_name, AVG(pg_column_size(t))::numeric(10,2) AS avg_row_bytes FROM program t
UNION ALL
SELECT 'station', AVG(pg_column_size(t))::numeric(10,2) FROM station t
UNION ALL
SELECT 'dock', AVG(pg_column_size(t))::numeric(10,2) FROM dock t
UNION ALL
SELECT 'bike', AVG(pg_column_size(t))::numeric(10,2) FROM bike t
UNION ALL
SELECT 'bike_status', AVG(pg_column_size(t))::numeric(10,2) FROM bike_status t
UNION ALL
SELECT 'station_status', AVG(pg_column_size(t))::numeric(10,2) FROM station_status t
UNION ALL
SELECT 'membership_type', AVG(pg_column_size(t))::numeric(10,2) FROM membership_type t
UNION ALL
SELECT 'rider_account', AVG(pg_column_size(t))::numeric(10,2) FROM rider_account t
UNION ALL
SELECT 'membership', AVG(pg_column_size(t))::numeric(10,2) FROM membership t
UNION ALL
SELECT 'trip', AVG(pg_column_size(t))::numeric(10,2) FROM trip t
ORDER BY table_name;

SELECT c.table_name,
       c.ordinal_position,
       c.column_name,
       c.data_type,
       c.udt_name,
       c.is_nullable,
       c.column_default
FROM information_schema.columns c
WHERE c.table_schema = 'public'
  AND c.table_name IN (
      'program',
      'station',
      'dock',
      'bike',
      'bike_status',
      'station_status',
      'membership_type',
      'rider_account',
      'membership',
      'trip'
  )
ORDER BY c.table_name, c.ordinal_position;

SELECT tc.table_name,
       tc.constraint_name,
       tc.constraint_type,
       string_agg(kcu.column_name, ', ' ORDER BY kcu.ordinal_position) AS columns
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
 AND tc.table_schema = kcu.table_schema
 AND tc.table_name = kcu.table_name
WHERE tc.table_schema = 'public'
  AND tc.table_name IN (
      'program',
      'station',
      'dock',
      'bike',
      'bike_status',
      'station_status',
      'membership_type',
      'rider_account',
      'membership',
      'trip'
  )
GROUP BY tc.table_name, tc.constraint_name, tc.constraint_type
ORDER BY tc.table_name, tc.constraint_type, tc.constraint_name;

SELECT tc.table_name,
       tc.constraint_name,
       kcu.column_name,
       ccu.table_name AS referenced_table,
       ccu.column_name AS referenced_column
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
 AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage ccu
  ON tc.constraint_name = ccu.constraint_name
 AND tc.table_schema = ccu.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
  AND tc.table_name IN (
      'program',
      'station',
      'dock',
      'bike',
      'bike_status',
      'station_status',
      'membership_type',
      'rider_account',
      'membership',
      'trip'
  )
ORDER BY tc.table_name, tc.constraint_name, kcu.ordinal_position;

SELECT tablename AS table_name,
       indexname AS index_name,
       indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN (
      'program',
      'station',
      'dock',
      'bike',
      'bike_status',
      'station_status',
      'membership_type',
      'rider_account',
      'membership',
      'trip'
  )
ORDER BY tablename, indexname;

EXPLAIN (ANALYZE, BUFFERS)
SELECT trip_id, bike_id, started_at, ended_at
FROM trip
WHERE rider_id = 1
ORDER BY started_at DESC;

EXPLAIN (ANALYZE, BUFFERS)
SELECT bike_id, recorded_at, state, station_id
FROM bike_status
WHERE bike_id = 'HB-0001'
ORDER BY recorded_at DESC
LIMIT 5;

EXPLAIN (ANALYZE, BUFFERS)
SELECT station_id, name, capacity
FROM station
WHERE capacity >= 15;
