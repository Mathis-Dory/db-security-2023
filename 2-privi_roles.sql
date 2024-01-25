-- The following script is the roles and privileges script for the application
-- Run this script from CDB with the SYS user
-- Author: Mathis Dory
-- Date: 2023-12-27
-- Group 510

-- Switch to the PDB
ALTER SESSION SET CONTAINER = orclpdb;
-- If the DB is not open, open it
 ALTER DATABASE OPEN;

-- Then grant connection access to the users we created before
GRANT CREATE SESSION TO appcar_admin_app;
GRANT CREATE SESSION TO appcar_fleet_responsible;
GRANT CREATE SESSION TO appcar_hr_manager;
GRANT CREATE SESSION TO appcar_employee_1;
GRANT CREATE SESSION TO appcar_employee_2;
GRANT CREATE SESSION TO appcar_employee_3;
GRANT CREATE SESSION TO appcar_employee_4;
GRANT CREATE SESSION TO appcar_employee_5;

--+++++++ Grant privileges to the admin +++++++--
-- Grant the privileges to the admin user so he can create the tables in any schema
--+++++++ =========================== +++++++--

GRANT CREATE ANY TABLE TO appcar_admin_app;
GRANT CREATE ANY INDEX TO appcar_admin_app;
GRANT CREATE ANY SEQUENCE TO appcar_admin_app;
GRANT SELECT ANY SEQUENCE TO appcar_admin_app;

-- Check the privileges
SELECT * FROM DBA_SYS_PRIVS WHERE GRANTEE = 'APPCAR_ADMIN_APP';


--+++++++ Grant references privileges +++++++--
-- Used for the tables creation that have references to other tables
--+++++++ =========================== +++++++--


-- Grant the privileges to the admin user so he can create the users table with the references to the employees table
GRANT REFERENCES ON APPCAR_ADMIN_APP.USERS TO APPCAR_HR_MANAGER; -- CREATE THE TABLE FIRST IN THE TABLES SCRIPT (PART 1)
-- Grant the privileges to the fleet responsible user so he can create the admin can reference the states table to the vehicles table
GRANT REFERENCES ON APPCAR_ADMIN_APP.STATES TO appcar_fleet_responsible; -- CREATE THE TABLE FIRST IN THE TABLES SCRIPT (PART 2)
-- Grant the privileges to the admin user so he can create the bookings table with the references to the vehicles table
GRANT REFERENCES ON APPCAR_FLEET_RESPONSIBLE.VEHICLES TO appcar_admin_app; -- CREATE THE TABLE FIRST IN THE TABLES SCRIPT (PART 3)
-- Run the PART 4 of the tables script to create the invoices table and bookings table

-- Check the tables
SELECT owner, table_name FROM all_tables WHERE OWNER LIKE 'APPCAR%' ORDER BY owner, table_name;


--+++++++ Create roles +++++++--

CREATE ROLE appcar_employee_role;
CREATE ROLE appcar_fleet_role;
CREATE ROLE appcar_hr_role;
CREATE ROLE appcar_admin_role;

-- Grant the privileges to the roles

-- Grant the privileges to the employee role according to the entity user matrix
GRANT SELECT, UPDATE ON APPCAR_FLEET_RESPONSIBLE.VEHICLES TO appcar_employee_role;
GRANT SELECT ON APPCAR_FLEET_RESPONSIBLE.PRICINGS TO appcar_employee_role;
GRANT SELECT, UPDATE ON APPCAR_ADMIN_APP.BOOKINGS TO appcar_employee_role;
GRANT SELECT, UPDATE, DELETE ON APPCAR_ADMIN_APP.INVOICES TO appcar_employee_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON APPCAR_ADMIN_APP.RETURNS TO appcar_employee_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON APPCAR_ADMIN_APP.CHECK_IN TO appcar_employee_role;
GRANT SELECT, INSERT ON APPCAR_ADMIN_APP.CUSTOMERS TO appcar_employee_role;
-- Create a special view to prevent the employees from seeing the passwords
CREATE OR REPLACE VIEW APPCAR_ADMIN_APP.USERS_MGMT_VIEW AS
    SELECT id, name, surname, sex, birthdate, email FROM APPCAR_ADMIN_APP.USERS;
GRANT SELECT ON APPCAR_ADMIN_APP.USERS_MGMT_VIEW TO appcar_employee_role;
GRANT SELECT ON APPCAR_ADMIN_APP.STATES TO appcar_employee_role;

-- Grant the privileges to the fleet responsible role according to the entity user matrix
GRANT SELECT ON APPCAR_ADMIN_APP.STATES TO appcar_fleet_role;
GRANT SELECT, UPDATE ON APPCAR_ADMIN_APP.BOOKINGS TO appcar_fleet_role;

-- Grant the privileges to the HR role according to the entity user matrix
GRANT SELECT, UPDATE(id, name, surname, sex, birthdate, email)
    ON APPCAR_ADMIN_APP.USERS_MGMT_VIEW TO appcar_hr_role;
GRANT INSERT, DELETE ON APPCAR_ADMIN_APP.USERS TO appcar_hr_role;

GRANT SELECT, UPDATE ON APPCAR_FLEET_RESPONSIBLE.VEHICLES TO appcar_admin_role;


-- Asssign the roles to the users
GRANT appcar_admin_role TO appcar_admin_app;
GRANT appcar_fleet_role TO appcar_fleet_responsible;
GRANT appcar_hr_role TO appcar_hr_manager;
GRANT appcar_employee_role TO appcar_employee_1;
GRANT appcar_employee_role TO appcar_employee_2;
GRANT appcar_employee_role TO appcar_employee_3;
GRANT appcar_employee_role TO appcar_employee_4;
GRANT appcar_employee_role TO appcar_employee_5;

-- Check the roles
SELECT grantee AS username, granted_role FROM dba_role_privs WHERE grantee LIKE 'APPCAR%' ORDER BY grantee, granted_role;



--+++++++ Procedure to allow employees to edit the state of a vehicle +++++++--

CREATE OR REPLACE PROCEDURE APPCAR_ADMIN_APP.appcar_proc_state(
    p_state_id INT,
    p_vehicle_id INT
) AUTHID DEFINER AS
    v_rowcount INT;
    v_state_count INT;
BEGIN
    -- First, check if the state_id exists
    SELECT COUNT(*)
    INTO v_state_count
    FROM APPCAR_ADMIN_APP.STATES
    WHERE id = p_state_id;

    IF v_state_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'The provided state ID does not exist.');
    END IF;
    -- Update the state of the vehicle
    UPDATE APPCAR_FLEET_RESPONSIBLE.VEHICLES
    SET id_state = p_state_id
    WHERE id = p_vehicle_id;

    -- Check if the update affected any rows
    v_rowcount := SQL%ROWCOUNT;
    IF v_rowcount = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'No vehicle found with the provided ID.');
    END IF;
END;
/


-- Grant the execute privilege to the employee role
GRANT EXECUTE ON APPCAR_ADMIN_APP.appcar_proc_state TO appcar_employee_role;
-- Grant the privileges to the admin user so he can SELECT and UPDATE the vehicles table because he is the owner of the procedure
GRANT SELECT, UPDATE ON APPCAR_FLEET_RESPONSIBLE.VEHICLES TO APPCAR_ADMIN_APP;

COMMIT;
-- Test the procedure using a console within the employee_1 user (Use the insert sample data script first)
CALL APPCAR_ADMIN_APP.appcar_proc_state(3,1);
SELECT * FROM APPCAR_FLEET_RESPONSIBLE.VEHICLES WHERE id = 1;
ROLLBACK;
SELECT * FROM APPCAR_FLEET_RESPONSIBLE.VEHICLES WHERE id = 1;


