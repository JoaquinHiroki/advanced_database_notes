-- EXERCISE 1 
SELECT object_type, COUNT(*) AS cnt
FROM user_objects
GROUP BY object_type
ORDER BY object_type;

SELECT object_name, object_type, created, last_ddl_time
FROM user_objects
ORDER BY object_type, object_name;

-- EXERCISE 2
BEGIN
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'PRETTY', true);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SQLTERMINATOR', true);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SEGMENT_ATTRIBUTES', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'STORAGE', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'TABLESPACE', false);
END;
/

SET LONG 100000
SET PAGESIZE 0

SELECT DBMS_METADATA.GET_DDL('TABLE', table_name)
FROM user_tables
ORDER BY table_name;

-- EXERCISE 3 
BEGIN
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'EMIT_SCHEMA', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'PRETTY', true);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SQLTERMINATOR', true);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SEGMENT_ATTRIBUTES', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'STORAGE', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'TABLESPACE', false);
END;
/

SELECT DBMS_METADATA.GET_DDL('TABLE', table_name)
FROM user_tables
WHERE ROWNUM = 1;

-- EXERCISE 4   
SELECT DBMS_METADATA.GET_DDL('TABLE', table_name)
FROM user_tables
WHERE table_name = 'ANY_TABLE_WITH_FK';

SELECT constraint_name, table_name, r_constraint_name
FROM user_constraints
WHERE constraint_type = 'R';

-- EXERCISE 5: Dependency order
SELECT referenced_name, referencing_name, referencing_type
FROM user_dependencies
ORDER BY referenced_name;

SELECT referencing_name, referencing_type
FROM user_dependencies
WHERE referenced_name IN (
  SELECT table_name FROM user_tables
)
ORDER BY referencing_type, referencing_name;

SELECT referenced_name, referenced_type
FROM user_dependencies
WHERE referencing_name = 'PROC_NAME';

SELECT referencing_name, referencing_type,
       LISTAGG(referenced_name, ', ') WITHIN GROUP (ORDER BY referenced_name) AS dependencies
FROM user_dependencies
WHERE referencing_type IN ('PACKAGE', 'PROCEDURE', 'FUNCTION')
GROUP BY referencing_name, referencing_type
ORDER BY referencing_type, referencing_name;

-- EXERCISE 6: Backup strategy
SELECT object_type, COUNT(*) FROM user_objects GROUP BY object_type;
SELECT table_name, num_rows FROM user_tables ORDER BY num_rows DESC;

BEGIN
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'PRETTY', true);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SQLTERMINATOR', true);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SEGMENT_ATTRIBUTES', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'STORAGE', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'TABLESPACE', false);
END;
/

SELECT DBMS_METADATA.GET_DDL('TABLE', table_name) FROM user_tables;
SELECT DBMS_METADATA.GET_DDL('INDEX', index_name) FROM user_indexes;
SELECT DBMS_METADATA.GET_DDL('VIEW', view_name) FROM user_views;
SELECT DBMS_METADATA.GET_DDL('SEQUENCE', sequence_name) FROM user_sequences;
SELECT DBMS_METADATA.GET_DDL('CONSTRAINT', constraint_name) FROM user_constraints;
SELECT DBMS_METADATA.GET_DDL('PROCEDURE', object_name) FROM user_objects WHERE object_type = 'PROCEDURE';
SELECT DBMS_METADATA.GET_DDL('FUNCTION', object_name) FROM user_objects WHERE object_type = 'FUNCTION';
SELECT DBMS_METADATA.GET_DDL('PACKAGE', object_name) FROM user_objects WHERE object_type = 'PACKAGE';

SELECT object_type, COUNT(*) FROM user_objects GROUP BY object_type;
SELECT table_name, num_rows FROM user_tables ORDER BY table_name;
SELECT index_name, table_name FROM user_indexes ORDER BY index_name;