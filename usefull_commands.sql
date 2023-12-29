-- Show the current container
-- Same result as show con_name but here we use the SYS_CONTEXT function in order to work with Datagrip
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') FROM DUAL;

-- Show all the pluggable databases
-- Same result as show pdbs but here we use a complete query in order to work with Datagrip
SELECT name, open_mode FROM v$pdbs;

-- Set the current container to the pluggable database
ALTER SESSION SET CONTAINER = orclpdb;
-- Set the current container to the root container
ALTER SESSION SET CONTAINER = CDB$ROOT;

-- Open a database
ALTER DATABASE OPEN;
