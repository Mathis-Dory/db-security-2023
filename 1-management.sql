-- The following script is the users and resources management script for the application
-- Run this script from the CDB with the SYS user
-- Author: Mathis Dory
-- Date: 2023-12-27
-- Group 510

-- Connect to the PDB
ALTER SESSION SET CONTAINER = ORCLPDB;
-- If db is not opened
ALTER DATABASE OPEN;

-- Check if you are connected to the PDB
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') FROM DUAL;

--+++++++ Create the users +++++++--

-- Create the admin user of the application, the password expire is used to force the user to change the password at the first login
-- This admin is a local user for the pluggable database orclpdb
CREATE USER appcar_admin_app IDENTIFIED BY admin1234 password expire;


-- Create an account for the responsible of the fleet
CREATE USER appcar_fleet_responsible IDENTIFIED BY test1234 password expire;

-- Create an account for the HR responsible
CREATE USER appcar_hr_manager IDENTIFIED BY test1234 password expire;

-- Create an account for the 5 employees of the commercial department
CREATE USER appcar_employee_1 IDENTIFIED BY test1234 password expire;
CREATE USER appcar_employee_2 IDENTIFIED BY test1234 password expire;
CREATE USER appcar_employee_3 IDENTIFIED BY test1234 password expire;
CREATE USER appcar_employee_4 IDENTIFIED BY test1234 password expire;
CREATE USER appcar_employee_5 IDENTIFIED BY test1234 password expire;


SELECT username, AUTHENTICATION_TYPE, ACCOUNT_STATUS, to_char(EXPIRY_DATE, 'dd/mm/yyyy hh24:mi:ss') AS expiry_date_time,
       to_char(CREATED, 'dd/mm/yyyy hh24:mi:ss') created_date_time,PROFILE FROM dba_users
WHERE lower(username) LIKE 'appcar%';


--+++++++ Set storage limit for users +++++++--

-- unlimited storage for the admin
alter user appcar_admin_app quota unlimited on users;
-- 20 MB for the fleet responsible
alter user appcar_fleet_responsible quota 20M on users;
-- 10 MB for the HR manager
alter user appcar_hr_manager quota 10M on users;
-- 3 MB storage for the employees
alter user appcar_employee_1 quota 3M on users;
alter user appcar_employee_2 quota 3M on users;
alter user appcar_employee_3 quota 3M on users;
alter user appcar_employee_4 quota 3M on users;
alter user appcar_employee_5 quota 3M on users;

-- Check the storage limits
SELECT * FROM dba_ts_quotas WHERE tablespace_name LIKE 'USERS';


--+++++++ Create profiles +++++++--

-- Create the profile for all employees
CREATE PROFILE appcar_profile_employee LIMIT
    SESSIONS_PER_USER 3 -- 3 sessions
    CPU_PER_CALL 3000 -- 30 seconds threshold for the CPU
    IDLE_TIME 5 -- 5 minutes
    CONNECT_TIME 30 -- 30 minutes
    PASSWORD_LIFE_TIME 90 -- 3 months
    PASSWORD_REUSE_TIME UNLIMITED -- no reuse of the password
    PASSWORD_LOCK_TIME 1/24 -- 1 hour
    FAILED_LOGIN_ATTEMPTS 5; -- 5 attempts

-- Set the profile for the users
ALTER USER appcar_employee_1 profile appcar_profile_employee;
ALTER USER appcar_employee_2 profile appcar_profile_employee;
ALTER USER appcar_employee_3 profile appcar_profile_employee;
ALTER USER appcar_employee_4 profile appcar_profile_employee;
ALTER USER appcar_employee_5 profile appcar_profile_employee;
ALTER USER appcar_fleet_responsible profile appcar_profile_employee;
ALTER USER appcar_hr_manager profile appcar_profile_employee;

-- Create the profile for the admin
CREATE PROFILE appcar_profile_admin LIMIT
    SESSIONS_PER_USER 3 -- 3 sessions
    CPU_PER_CALL 500 -- 5 seconds trheshold for the CPU
    IDLE_TIME 3 -- 3 minutes
    CONNECT_TIME 30 -- 30 minutes
    PASSWORD_LIFE_TIME 30 -- 1 months
    PASSWORD_REUSE_TIME UNLIMITED -- no reuse of the password
    PASSWORD_LOCK_TIME 1 -- 1 day
    FAILED_LOGIN_ATTEMPTS 3; -- 3 attempts

-- Set the profile for the admin
ALTER USER appcar_admin_app profile appcar_profile_admin;

-- Check the profiles
SELECT * FROM dba_profiles WHERE lower(profile) LIKE 'appcar%' ORDER BY profile;

-- Check the users and their profiles
SELECT username, profile FROM dba_users WHERE lower(username) LIKE 'appcar%' ;


--+++++++ Create resources procedure +++++++--

ALTER SYSTEM SET resource_limit=true;

CREATE OR REPLACE PROCEDURE appcar_resource_plan AS
    n NUMBER := 0;
BEGIN
    DBMS_RESOURCE_MANAGER.CLEAR_PENDING_AREA;
    DBMS_RESOURCE_MANAGER.create_pending_area();
    DBMS_RESOURCE_MANAGER.create_plan(plan =>'APPCAR_PLAN1', comment =>'This is a plan for the rental car application');

    --consumer groups
    DBMS_RESOURCE_MANAGER.create_consumer_group(consumer_group => 'mgmt',
                            comment => 'Groups of sessions of the HR manager and the fleet responsible');
    DBMS_RESOURCE_MANAGER.create_consumer_group(consumer_group =>'admin', comment => 'Groups of sessions of the admin');
    DBMS_RESOURCE_MANAGER.create_consumer_group(consumer_group =>'employee', comment => 'Groups of sessions of the employees');

    -- for the (improbable) case when the OTHER_GROUPS does not exist:
    SELECT count(*) INTO n FROM dba_rsrc_consumer_groups WHERE consumer_group = 'OTHER_GROUPS';


    IF n = 0 THEN
        DBMS_RESOURCE_MANAGER.create_consumer_group(consumer_group => 'OTHER_GROUPS',
                             comment => 'This is the group for the rest of the users');
    END IF ;

    -- static mappings of the users to the consumers groups
    -- Note: the users cannot be mapped to the group OTHERS_GROUPS
    DBMS_RESOURCE_MANAGER.set_consumer_group_mapping(DBMS_RESOURCE_MANAGER.oracle_user, 'appcar_admin_app', 'admin');
    DBMS_RESOURCE_MANAGER.set_consumer_group_mapping(DBMS_RESOURCE_MANAGER.oracle_user, 'appcar_hr_manager', 'mgmt');
    DBMS_RESOURCE_MANAGER.set_consumer_group_mapping(DBMS_RESOURCE_MANAGER.oracle_user, 'appcar_fleet_responsible', 'mgmt');
    DBMS_RESOURCE_MANAGER.set_consumer_group_mapping(DBMS_RESOURCE_MANAGER.oracle_user, 'appcar_employee_1', 'employee');
    DBMS_RESOURCE_MANAGER.set_consumer_group_mapping(DBMS_RESOURCE_MANAGER.oracle_user, 'appcar_employee_2', 'employee');
    DBMS_RESOURCE_MANAGER.set_consumer_group_mapping(DBMS_RESOURCE_MANAGER.oracle_user, 'appcar_employee_3', 'employee');
    DBMS_RESOURCE_MANAGER.set_consumer_group_mapping(DBMS_RESOURCE_MANAGER.oracle_user, 'appcar_employee_4', 'employee');
    DBMS_RESOURCE_MANAGER.set_consumer_group_mapping(DBMS_RESOURCE_MANAGER.oracle_user, 'appcar_employee_5', 'employee');


    --plan directives for each consumer group
     DBMS_RESOURCE_MANAGER.create_plan_directive(plan => 'APPCAR_PLAN1', GROUP_OR_SUBPLAN => 'mgmt',
                                                comment => 'Plan directive for the vehicles and employees management', MGMT_P1 =>30);
     DBMS_RESOURCE_MANAGER.create_plan_directive(plan => 'APPCAR_PLAN1', GROUP_OR_SUBPLAN => 'admin',
                                                comment => 'Plan directive for the admin group', MGMT_P1 =>25);
     DBMS_RESOURCE_MANAGER.create_plan_directive(plan => 'APPCAR_PLAN1', GROUP_OR_SUBPLAN => 'employee',
                                                comment => 'Plan directive for the employees', MGMT_P1 =>35);
     DBMS_RESOURCE_MANAGER.create_plan_directive(plan => 'APPCAR_PLAN1', GROUP_OR_SUBPLAN => 'OTHER_GROUPS',
                                                comment => 'Plan directive for the others group', MGMT_P1 =>10);

     DBMS_RESOURCE_MANAGER.validate_pending_area();
     DBMS_RESOURCE_MANAGER.submit_pending_area();
END;

SELECT * FROM dba_rsrc_consumer_groups WHERE CATEGORY = 'OTHER';

CALL appcar_resource_plan();

-- Check the plan if there is an error
SELECT * FROM user_errors WHERE name = 'APPCAR_RESOURCE_PLAN';

COMMIT;


