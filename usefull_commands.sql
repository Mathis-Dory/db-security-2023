-- The following script contains some helpful commands to work with Oracle 21c and any IDE
-- Author: Mathis Dory
-- Date: 2023-12-27
-- Group 510


-- Show the current container
-- Same result as show con_name but here we use the SYS_CONTEXT function in order to work with Datagrip
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') FROM DUAL;

-- Show all the pluggable databases
-- Same result as show pdbs but here we use a complete query in order to work with Datagrip
SELECT name, open_mode FROM v$pdbs;

-- Set the current container to the pluggable database
ALTER SESSION SET CONTAINER = ORCLPDB;
-- Set the current container to the root container
ALTER SESSION SET CONTAINER = CDB$ROOT;

-- Open a database
ALTER DATABASE OPEN;

-- Check errors in a procedure
SELECT * FROM USER_ERRORS WHERE NAME = 'NAME PROCEDURE' ORDER BY SEQUENCE;

