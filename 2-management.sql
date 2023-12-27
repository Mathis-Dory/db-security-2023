-- The following script is the step to manage the users and the resources of the database.
-- First connect as admin_app to the PDB and then execute the following script.
-- Author: Mathis Dory
-- Date: 2023-12-27
-- Group 510


-- Connect to the PDB
ALTER SESSION SET CONTAINER = orclpdb;

-- Check if you are connected to the PDB
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') FROM DUAL;


-- Create the users --

-- Create an account for the responsible of the fleet
CREATE USER appcar_fleet_responsible IDENTIFIED BY test1234 password expire;
GRANT CREATE SESSION TO appcar_fleet_responsible;

-- Create an account for the 5 employees of the commercial department
CREATE USER appcar_employee_1 IDENTIFIED BY test1234 password expire;
GRANT CREATE SESSION TO appcar_employee_1;
CREATE USER appcar_employee_2 IDENTIFIED BY test1234 password expire;
GRANT CREATE SESSION TO appcar_employee_2;
CREATE USER appcar_employee_3 IDENTIFIED BY test1234 password expire;
GRANT CREATE SESSION TO appcar_employee_3;
CREATE USER appcar_employee_4 IDENTIFIED BY test1234 password expire;
GRANT CREATE SESSION TO appcar_employee_4;
CREATE USER appcar_employee_5 IDENTIFIED BY test1234 password expire;
GRANT CREATE SESSION TO appcar_employee_5;

-- Set storage limits for the users --

-- unlimited storage for the admin
alter user appcar_admin_app quota unlimited on users;
-- 20 MB for the fleet responsible
alter user appcar_fleet_responsible quota 20M on users;
-- 10 MB for the employees
alter user appcar_employee_1 quota 10M on users;
alter user appcar_employee_2 quota 10M on users;
alter user appcar_employee_3 quota 10M on users;
alter user appcar_employee_4 quota 10M on users;
alter user appcar_employee_5 quota 10M on users;

-- Check the storage limits
SELECT * FROM dba_ts_quotas WHERE tablespace_name='USERS';


