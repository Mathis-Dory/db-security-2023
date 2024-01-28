-- The following script is used to mask the email and driving license of the users
-- Run this script from the CDB with the SYS user
-- Author: Mathis Dory
-- Date: 2023-01-10
-- Group 510

ALTER SESSION SET CONTAINER = ORCLPDB;

CREATE OR REPLACE PACKAGE APPCAR_ADMIN_APP.appcar_masking_pkg IS
    FUNCTION mask_email(email VARCHAR2) RETURN VARCHAR2;
    FUNCTION mask_license(license VARCHAR2) RETURN VARCHAR2;
END;
/

CREATE OR REPLACE PACKAGE BODY APPCAR_ADMIN_APP.appcar_masking_pkg IS

    -- Masking function for email
 FUNCTION mask_email(email VARCHAR2) RETURN VARCHAR2 IS
        v_username_part VARCHAR2(100);
        v_domain_part VARCHAR2(100);
        v_masked_username VARCHAR2(100);
        v_masked_domain VARCHAR2(100);
        v_tld VARCHAR2(10);
    BEGIN
        -- Extract the first two characters of the username part
        v_username_part := REGEXP_SUBSTR(email, '([^\@]{2})');

        -- Extract the domain part without TLD
        v_domain_part := REGEXP_SUBSTR(email, '@([^\.\@]+)\.', 1, 1, NULL, 1);

        -- Extract the TLD
        v_tld := REGEXP_SUBSTR(email, '(\.\w+)$');

        -- Mask the username part, preserving the first two characters
        v_masked_username := v_username_part || RPAD('*', LENGTH(email) - LENGTH(v_domain_part) - LENGTH(v_tld) - 3, '*');

        -- Mask the domain part dynamically
        v_masked_domain := RPAD('*', LENGTH(v_domain_part), '*') || v_tld;

        -- Concatenate the masked parts
        RETURN v_masked_username || '@' || v_masked_domain;
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


-- Set the directory for the export & grant permissions
CREATE OR REPLACE DIRECTORY direxp_data AS 'C:\Users\Public\dbsec\masking';
GRANT READ, WRITE ON DIRECTORY direxp_data TO appcar_admin_app;

--+++++++ Test masking +++++++--
-- Call the function to mask the email
-- Call the function to mask the driving license
-- Export and Import masked data
--+++++++ =============== +++++++--

SELECT
    APPCAR_ADMIN_APP.appcar_masking_pkg.mask_email('testtes123t@gmail.ro') AS masked_email,
    APPCAR_ADMIN_APP.appcar_masking_pkg.mask_license('FR4578961123') AS masked_license
FROM dual;

-- Run it in regular terminal to export
-- expdp appcar_admin_app/admin1234@ORCLPDB schemas=appcar_admin_app directory=direxp_data dumpfile=USERS_CUSTOMERS_EXPORT.dmp remap_data=appcar_admin_app.users.email:appcar_masking_pkg.mask_email remap_data=appcar_admin_app.customers.license:appcar_masking_pkg.mask_license

-- Import
-- impdp appcar_admin_app/admin1234@ORCLPDB directory=direxp_data dumpfile=USERS_CUSTOMERS_EXPORT.dmp remap_schema=appcar_admin_app:appcar_admin_app_masked