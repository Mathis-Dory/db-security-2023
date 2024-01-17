-- The following script is used to mask the email and driving license of the users
-- Run this script from the CDB with the SYS user
-- Author: Mathis Dory
-- Date: 2023-01-10
-- Group 510

ALTER SESSION SET CONTAINER = orclpdb;

CREATE OR REPLACE PACKAGE appcar_masking_pkg IS
    FUNCTION mask_email(email VARCHAR2) RETURN VARCHAR2;
    FUNCTION mask_license(license VARCHAR2) RETURN VARCHAR2;
END;
/

CREATE OR REPLACE PACKAGE BODY appcar_masking_pkg IS

    -- Masking function for email
     FUNCTION mask_email(email VARCHAR2) RETURN VARCHAR2 IS
        v_masked_email VARCHAR2(100);
    BEGIN
        -- Mask everything except the first two characters of the first part and the domain extension
        v_masked_email := REGEXP_REPLACE(email, '(\w{2})\w*@(\w*)\.(\w+)', '\1**@***.\3');
        RETURN v_masked_email;
    END mask_email;


    -- Masking function for driving license
    FUNCTION mask_license(license VARCHAR2) RETURN VARCHAR2 IS
        v_masked_license VARCHAR2(50);
    BEGIN
        -- Keep the first two characters and mask the rest
        SELECT SUBSTR(license, 1, 2) || RPAD('*', LENGTH(license) - 2, '*')
        INTO v_masked_license
        FROM dual;
        RETURN v_masked_license;
    END mask_license;

END appcar_masking_pkg;
/


CREATE OR REPLACE DIRECTORY direxp_data AS 'C:\Users\mathi\Bureau\masking';
GRANT READ, WRITE ON DIRECTORY direxp_data TO appcar_admin_app;

select appcar_masking_pkg.mask_email('test@test.rom') from dual;
select appcar_masking_pkg.mask_license('FR4578961123') from dual;
-- Run it in regular terminal to export
--expdp appcar_admin_app/admin1234@orclpdb schemas=appcar_admin_app directory=DIREXP_DATA dumpfile=USERS_CUSTOMERS_EXPORT.dmp remap_data=appcar_admin_app.users.email:appcar_masking_pkg.mask_email remap_data=appcar_admin_app.customers.license:appcar_masking_pkg.mask_license
--impdp appcar_admin_app/admin1234@orclpdb directory=DIREXP_DATA dumpfile=USERS_CUSTOMERS_EXPORT.dmp remap_schema=appcar_admin_app:appcar_admin_app_masked
