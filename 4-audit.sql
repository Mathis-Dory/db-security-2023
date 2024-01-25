-- The following script is used to audit the database
-- Run this script from the CDB with the SYS user, you will need to restart the database after running the first part, then run the second part
-- Author: Mathis Dory
-- Date: 2023-12-27
-- Group 510

-- Connect to the Root container (CDB$ROOT)
ALTER SESSION SET CONTAINER = CDB$ROOT;

-- Check if you are connected to the root container
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') FROM DUAL;

-- Set extended auditing in the database
ALTER SYSTEM SET audit_trail=db,extended SCOPE=SPFILE;

-- This part ends here. Restart the database before proceeding.

-- Connect to the PDB
ALTER SESSION SET CONTAINER = orclpdb;

-- OPEN the PDB if closed
ALTER PLUGGABLE DATABASE OPEN;

-- Check if you are connected to the PDB
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') FROM DUAL;

-- Check if the extended auditing is enabled
SELECT name, value FROM v$parameter WHERE name='audit_trail';

--+++++++ Standard audit +++++++--
-- Audit some tables on specific actions
--+++++++ =============== +++++++--

-- Audit when an employee is created, updated or deleted
AUDIT INSERT, UPDATE, DELETE ON APPCAR_HR_MANAGER.EMPLOYEES BY ACCESS;
-- Audit when a vehicle is created or deleted
AUDIT INSERT, DELETE ON APPCAR_FLEET_RESPONSIBLE.VEHICLES BY ACCESS;
-- Audit when a user is deleted
AUDIT DELETE ON APPCAR_ADMIN_APP.USERS BY ACCESS;
-- Audit when a invoice is paid
AUDIT UPDATE ON APPCAR_ADMIN_APP.INVOICES BY ACCESS;
-- Audit on fail on the bookings table
AUDIT SELECT, INSERT, UPDATE, DELETE ON APPCAR_ADMIN_APP.BOOKINGS BY ACCESS WHENEVER NOT SUCCESSFUL;


--+++++++ Trigger audits +++++++--
-- Audit when an employee use the procedure appcar_proc_state to change the state of a vehicle
-- Audit when action are done on the RETURNS table
--+++++++ =============== +++++++--

-- Create a table to store the audit
CREATE SEQUENCE appcar_audit_seq_1 START WITH 1 INCREMENT BY 1;
CREATE TABLE APPCAR_AUDIT_LOG_PROC_STATES (
    audit_id        NUMBER PRIMARY KEY,
    user_name       VARCHAR2(100),
    vehicle_id      INT,
    new_state_id    INT,
    action_time     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Trigger for Auditing the procedure
CREATE OR REPLACE TRIGGER appcar_audit_trigger_proc_states
AFTER UPDATE ON APPCAR_FLEET_RESPONSIBLE.VEHICLES
FOR EACH ROW
DECLARE
    v_user VARCHAR2(100);
BEGIN
    v_user := USER;
    INSERT INTO APPCAR_AUDIT_LOG_PROC_STATES (audit_id, user_name, vehicle_id, new_state_id, action_time)
    VALUES (appcar_audit_seq_1.NEXTVAL, v_user, :NEW.id, :NEW.id_state, SYSTIMESTAMP);
END appcar_audit_trigger;
/

-- Create a table to store the audit of the RETURNS table
CREATE SEQUENCE appcar_audit_seq_2 START WITH 1 INCREMENT BY 1;
CREATE TABLE APPCAR_AUDIT_LOG_RETURNS (
    id_audit NUMBER PRIMARY KEY,
    action_user VARCHAR2(30),
    action_type VARCHAR2(50),
    action_timestamp TIMESTAMP,
    action_table VARCHAR2(50),
    action_description VARCHAR2(255)
);


-- Trigger for RETURN Table
CREATE OR REPLACE TRIGGER appcar_audit_trigger_returns
AFTER INSERT OR DELETE OR UPDATE ON APPCAR_ADMIN_APP.RETURNS
FOR EACH ROW
DECLARE
    v_action_description VARCHAR2(255);
    v_action_type VARCHAR2(6);
BEGIN
    IF INSERTING THEN
        v_action_description := 'INSERTED ID ' || :NEW.id || ', Date: ' || TO_CHAR(:NEW.return_date, 'YYYY-MM-DD  HH24:MI:SS') || ', Comments: ' || :NEW.comments || ', Booking ID: ' || :NEW.id_booking;
        v_action_type := 'INSERT';
    ELSIF UPDATING THEN
        v_action_description := 'UPDATED ID ' || :OLD.id ||
                                ', from Date: ' ||  TO_CHAR(:OLD.return_date, 'YYYY-MM-DD  HH24:MI:SS') || ' to ' ||TO_CHAR(:NEW.return_date, 'YYYY-MM-DD  HH24:MI:SS') ||
                                ', from Comments: ' || :OLD.comments || ' to ' || :NEW.comments ||
                                ', from Booking ID: ' || :OLD.id_booking || ' to ' || :NEW.id_booking;
        v_action_type := 'UPDATE';
    ELSIF DELETING THEN
        v_action_description := 'DELETED ID ' || :OLD.id || ', Date: ' || TO_CHAR(:OLD.return_date, 'YYYY-MM-DD  HH24:MI:SS') || ', Comments: ' || :OLD.comments || ', Booking ID: ' || :OLD.id_booking;
        v_action_type := 'DELETE';
    END IF;

    INSERT INTO APPCAR_AUDIT_LOG_RETURNS (id_audit, action_user, action_type, action_timestamp, action_table, action_description)
    VALUES (appcar_audit_seq_2.NEXTVAL, USER, v_action_type, SYSDATE, 'RETURNS', v_action_description);
END;
/




--+++++++ Audit policy +++++++--
-- Audit when a check-in is updated on a booking
--+++++++ =============== +++++++--
CREATE OR REPLACE PROCEDURE appcar_proc_audit_policy AS
BEGIN
    DBMS_FGA.ADD_POLICY(
        object_schema   => 'APPCAR_ADMIN_APP',
        object_name     => 'CHECK_IN',
        policy_name     => 'audit_check_in_updates',
        audit_column    => 'comments',
        enable          => TRUE,
        statement_types => 'UPDATE'
    );
END;
/

CALL appcar_proc_audit_policy();
COMMIT;



--+++++++ Test all audits +++++++--
-- Test standard audit, trigger audit and policy audit
--+++++++ =============== +++++++--

----- Test Standard audit -----

-- Example 1 with employee table
-- Create first a test user (Execute it as Admin)
INSERT INTO APPCAR_ADMIN_APP.USERS (id, name, surname, sex, birthdate, password, email) VALUES (5,'ANONYMOUS', 'TEST', 'M', TO_DATE('2001-06-14', 'YYYY-MM-DD'), 'test', 'test@test.ro');
COMMIT;
-- Create an employee and then delete it (Execute it as HR Manager)
INSERT INTO APPCAR_HR_MANAGER.EMPLOYEES (department, id_user) VALUES ('administrative', 5);
COMMIT;
DELETE FROM APPCAR_HR_MANAGER.EMPLOYEES WHERE id_user = 5;
COMMIT;


-- Example 2 with booking table on fail
-- Use the following query with the HR manager user to fail it
SELECT * FROM APPCAR_ADMIN_APP.BOOKINGS WHERE id = 1;


-- Check the standard audit log
SELECT OBJ$NAME, SQLTEXT, NTIMESTAMP# FROM aud$;
-- Delete all logs
-- DELETE FROM aud$;
COMMIT;

----- Test trigger audit -----

-- Execute the procedure (Execute it as employee)
SELECT * FROM APPCAR_FLEET_RESPONSIBLE.VEHICLES WHERE id = 1;
CALL APPCAR_ADMIN_APP.appcar_proc_state(4,1);
COMMIT;
SELECT * FROM APPCAR_FLEET_RESPONSIBLE.VEHICLES WHERE id = 1;
ROLLBACK;
-- Insert a new return (Execute it as employee)
INSERT INTO APPCAR_ADMIN_APP.RETURNS (return_date, comments, id_booking) VALUES (TO_DATE('2024-01-01 18:00:55', 'YYYY-MM-DD  HH24:MI:SS'), 'Returned on time',2);
COMMIT;
-- Update the return (Execute it as employee)
UPDATE APPCAR_ADMIN_APP.RETURNS SET return_date = TO_DATE('2024-01-02 05:30:22', 'YYYY-MM-DD  HH24:MI:SS'), comments = 'Returned late' WHERE id = 99;
COMMIT;
-- Delete the return (Execute it as employee)
DELETE FROM APPCAR_ADMIN_APP.RETURNS WHERE id = 99;
COMMIT;


-- Check the audit triggers
SELECT * FROM APPCAR_AUDIT_LOG_PROC_STATES;
SELECT* FROM APPCAR_AUDIT_LOG_RETURNS;
-- DELETE FROM APPCAR_AUDIT_LOG_PROC_STATES;
-- DELETE FROM APPCAR_AUDIT_LOG_RETURNS;


----- Test audit policy -----

-- Update the check-in table (Execute it as employee)
-- TODO: DEBUG
SELECT * FROM APPCAR_ADMIN_APP.CHECK_IN;
UPDATE APPCAR_ADMIN_APP.CHECK_IN SET comments = 'Trunk is damaged' WHERE id = 1;
COMMIT;
SELECT * FROM APPCAR_ADMIN_APP.CHECK_IN;
SELECT * FROM DBA_FGA_AUDIT_TRAIL;
ROLLBACK;
