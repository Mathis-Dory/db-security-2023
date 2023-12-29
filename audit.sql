

-- Create an triggered audit table to record the check-in and returns events

-- Connect to the PDB
ALTER SESSION SET CONTAINER = CDB$ROOT;

-- Check if you are connected to the root container
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') FROM DUAL;

SELECT name, value FROM v$parameter WHERE name='audit_trail';

ALTER SYSTEM SET audit_trail=db,extended scope=spfile;

-- Restart the database to take effect

--Check if extended auditing is enabled
SELECT name, value FROM v$parameter WHERE name='audit_trail';


-- TODO