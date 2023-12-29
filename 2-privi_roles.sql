-- The following script is the roles and privileges script for the application
-- Run this script in the CDB with the System user
-- Author: Mathis Dory
-- Date: 2023-12-27
-- Group 510

-- Switch to the PDB
ALTER SESSION SET CONTAINER = orclpdb;
-- If the DB is not open, open it
-- ALTER DATABASE OPEN;

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

--+++++++ Grant references privileges +++++++--
-- Used for the tables creation that have references to other tables
--+++++++ =========================== +++++++--

-- Grant the privileges to the admin user so he can create the users table with the references to the employees table
GRANT REFERENCES ON APPCAR_HR_MANAGER.EMPLOYEES TO appcar_admin_app;
-- Grant the privileges to the admin user so he can create the bookings table with the references to the vehicles table
GRANT REFERENCES ON APPCAR_FLEET_RESPONSIBLE.VEHICLES TO appcar_admin_app;
-- Grant the privileges to the fleet responsible user so he can create the admin can reference the states table to the vehicles table
GRANT REFERENCES ON APPCAR_ADMIN_APP.STATES TO appcar_fleet_responsible;



--+++++++ Create roles +++++++--
-- TODO: Add the privileges to the roles

CREATE ROLE appcar_employee_role;
CREATE ROLE appcar_fleet_role;
CREATE ROLE appcar_hr_role;
CREATE ROLE appcar_admin_role;

-- Grant the privileges to the roles

-- Grant the privileges to the employee role according to the entity user matrix
GRANT SELECT ON APPCAR_FLEET_RESPONSIBLE.VEHICLES TO appcar_employee_role;
GRANT SELECT ON APPCAR_FLEET_RESPONSIBLE.PRICINGS TO appcar_employee_role;
GRANT SELECT, UPDATE ON APPCAR_ADMIN_APP.BOOKINGS TO appcar_employee_role;
GRANT SELECT, UPDATE, DELETE ON APPCAR_ADMIN_APP.INVOICES TO appcar_employee_role;
GRANT SELECT ON APPCAR_ADMIN_APP.RETURNS TO appcar_employee_role;
GRANT SELECT, INSERT ON APPCAR_ADMIN_APP.CHECK_IN TO appcar_employee_role;
GRANT SELECT, INSERT ON APPCAR_ADMIN_APP.CUSTOMERS TO appcar_employee_role;
-- Create a special view to prevent the employees from seeing the passwords
CREATE OR REPLACE VIEW APPCAR_ADMIN_APP.USERS_MGMT_VIEW AS
    SELECT id, name, surname, sex, birthdate, email, id_customer, id_employee FROM APPCAR_ADMIN_APP.USERS;

GRANT SELECT ON APPCAR_ADMIN_APP.USERS_MGMT_VIEW TO appcar_employee_role;

-- Grant the privileges to the fleet responsible role according to the entity user matrix
GRANT SELECT ON APPCAR_ADMIN_APP.STATES TO appcar_fleet_role;
GRANT SELECT, UPDATE ON APPCAR_ADMIN_APP.BOOKINGS TO appcar_fleet_role;

-- Grant the privileges to the HR role according to the entity user matrix
GRANT SELECT, UPDATE(id, name, surname, sex, birthdate, email, id_customer, id_employee)
    ON APPCAR_ADMIN_APP.USERS_MGMT_VIEW TO appcar_hr_role;
GRANT INSERT, DELETE ON APPCAR_ADMIN_APP.USERS TO appcar_hr_role;




-- Asssign the roles to the users
GRANT appcar_admin_role TO appcar_admin_app;
GRANT appcar_fleet_role TO appcar_fleet_responsible;
GRANT appcar_hr_role TO appcar_hr_manager;
GRANT appcar_employee_role TO appcar_employee_1;
GRANT appcar_employee_role TO appcar_employee_2;
GRANT appcar_employee_role TO appcar_employee_3;
GRANT appcar_employee_role TO appcar_employee_4;
GRANT appcar_employee_role TO appcar_employee_5;


--+++++++ Procedure to allow employees to edit the state of a vehicle +++++++--

CREATE OR REPLACE PROCEDURE PROC_STATE (
    p_state_id INT,
    p_vehicle_id INT
) AUTHID CURRENT_USER AS
    v_rowcount INT;
    v_state_count INT;
BEGIN
    -- First, check if the state_id exists
    SELECT COUNT(*)
    INTO v_state_count
    FROM STATES
    WHERE id = p_state_id;

    IF v_state_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'The provided state ID does not exist.');
    END IF;
    -- Update the state of the vehicle
    UPDATE VEHICLES
    SET id_state = p_state_id
    WHERE id = p_vehicle_id;

    -- Check if the update affected any rows
    v_rowcount := SQL%ROWCOUNT;

    IF v_rowcount = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'No vehicle found with the provided ID.');
    END IF;

    -- Commit the transaction to make the change permanent
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        -- Roll back any changes if an error occurs
        ROLLBACK;
        RAISE;
END PROC_STATE;
/


-- Grant the execute privilege to the employee role
GRANT EXECUTE ON PROC_STATE TO appcar_employee_role;
-- TODO: Test procedure