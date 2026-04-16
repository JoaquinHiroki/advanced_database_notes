-- Exercise 1
—- Find the slow query
--
-- Run this query. Look at the execution plan.
-- Is Oracle using an index? Should it?
-- ============================================================

-- EXPLAIN PLAN FOR
-- SELECT * FROM patient_visits WHERE site_id = 3;

-- SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Questions:
-- a) What scan type do you see? Why? Full scan because no index exists and Oracle decides scanning all rows is cheaper
-- b) site_id has values 1–5. Is this high or low cardinality? Low, only 5 values
-- c) Would adding an index on site_id help? Why or why not? No, an index on site_id wouldn’t help much because many rows share the same value so Oracle would still read a large portion of the table

-- Exercise 2 — Create an index and see if it helps
--
-- Create an index on visit_date.
-- Then run the range query below and check the plan.
-- Step 1: Create it
CREATE INDEX idx_visit_date ON patient_visits(visit_date);
-- Step 2: Gather stats
-- BEGIN
    --DBMS_STATS.GATHER_TABLE_STATS(USER, 'PATIENT_VISITS', cascade => TRUE);
--END;
--/

-- Step 3: Run the range query and check the plan
-- EXPLAIN PLAN FOR
-- SELECT * FROM patient_visits
-- WHERE visit_date BETWEEN SYSDATE - 30 AND SYSDATE;

-- SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Questions:
-- a) Does Oracle use the index for this range? Yes, Oracle uses the index for that date range.
-- b) Change the range to the last 7 days. Does the plan change? With last 7 days it still uses the index and even more efficiently
-- c) Change to the last 700 days. What happens? With last 700 days Oracle may switch to a full table scan because too many rows are selected
-- d) Why does the range size affect whether Oracle uses the index? Because the larger the range the more rows are returned at some point scanning the whole table is cheaper than using the index

-- Exercise 3 — Composite index
--
-- You often query by both patient_id AND visit_date together:
--   WHERE patient_id = 1234 AND visit_date > SYSDATE - 90
--
-- Two options:
--   Option A: Two separate indexes (one per column)
--   Option B: One composite index (patient_id, visit_date)
--
-- Create the composite index and test the query.
-- ============================================================

-- CREATE INDEX idx_pv_patient_date ON patient_visits(patient_id, visit_date);

-- BEGIN
    --DBMS_STATS.GATHER_TABLE_STATS(USER, 'PATIENT_VISITS', cascade => TRUE);
-- END;
-- /

-- EXPLAIN PLAN FOR
-- SELECT * FROM patient_visits
-- WHERE patient_id = 1234
  --AND visit_date > SYSDATE - 90;

--SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Questions:
-- a) Does the plan use the composite index? Yes, Oracle uses the composite index because the query matches the leading column and then filters by visit_date
-- b) Now try querying ONLY on visit_date (no patient_id). Does the composite index get used? Why not? No, it won’t use the composite index when querying only visit_date because the leading column is missing
-- c) What's the rule about column order in composite indexes? Oracle can only use a composite index starting from the leftmost column, not from the middle or end

-- Bonus test — leading column only:
-- EXPLAIN PLAN FOR
-- SELECT * FROM patient_visits WHERE patient_id = 1234;
-- SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Trailing column only (index cannot be used from the middle):
-- EXPLAIN PLAN FOR
-- SELECT * FROM patient_visits WHERE visit_date > SYSDATE - 90;
-- SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
CREATE INDEX idx_pv_patient_date ON patient_visits(patient_id, visit_date);

-- Exercise 4 — Function that breaks an index
--
-- There IS an index on patient_id (from lesson 03).
-- Predict what happens when you wrap the column in a function.
-- ============================================================

-- This query CAN use the index:
-- EXPLAIN PLAN FOR
-- SELECT * FROM patient_visits WHERE patient_id = 5432;
-- SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- This one cannot — why?
-- EXPLAIN PLAN FOR
-- SELECT * FROM patient_visits WHERE TO_CHAR(patient_id) = '5432';
-- SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Questions:
-- a) What scan type did the second query use? Full table scan
-- b) Why does wrapping a column in a function break index use? Because applying a function changes the column’s value, so the index on the original column can’t be used
-- c) How would you rewrite the second query to allow index use? Rewrite it without the function WHERE patient_id = 5432;

-- Exercise 5 — Discussion: real-world scenarios
--
-- For each scenario below, decide:
--   a) Would you add an index? 
--   b) On which column(s)?
--   c) Any concerns?

-- Scenario A:
-- a) Yes
-- b) On `visit_date`
-- c) Improves range queries low write cost since data loads only once daily

-- Scenario B:
-- a) Yes
-- b) Index on `customer_id` (not on `order_status`)
-- c) High insert rate → indexes slow writes; avoid low-cardinality (`order_status`) index

--Scenario C:
-- a) Yes
-- b) Unique index on `email`
-- c) Best for fast lookups and enforces uniqueness 🚀

-- ============================================================

-- Scenario A:
-- A reporting table gets loaded once per night (batch ETL).
-- During the day, analysts run SELECT queries by date range.
-- The table has 50 million rows.
-- → Index on date? Yes/No, why?

-- Scenario B:
-- An OLTP orders table gets 10,000 inserts per minute.
-- Support staff look up orders by customer_id or order_status.
-- order_status has 4 values: pending, processing, shipped, cancelled.
-- → What indexes would you add?

-- Scenario C:
-- A patient table has an email column (unique per patient).
-- There are 5 million patients.
-- The app frequently does: WHERE email = 'user@example.com'
-- → What kind of index would be best here?

-- ============================================================
-- Cleanup — remove indexes created in these exercises
-- ============================================================
-- DROP INDEX idx_pv_patient_date;
-- If you created an index on visit_date in Exercise 2, drop it here:
-- DROP INDEX idx_pv_visit_date;

