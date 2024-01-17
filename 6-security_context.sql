alter session set container = orclpdb;

CREATE CONTEXT appcar_ctx USING appcar_proc_ctx;


-- Create a procedure to set the context to prevent employees to insert check in and returns outside 10 am and 8 pm
CREATE OR REPLACE PROCEDURE appcar_proc_ctx IS
    current_hour NUMBER;
BEGIN
    SELECT EXTRACT(HOUR FROM CURRENT_TIMESTAMP) INTO current_hour FROM dual;

    IF current_hour >= 10 AND current_hour < 20 THEN
        -- Allow operations between 10 AM and 8 PM
        DBMS_SESSION.set_context('appcar_ctx', 'allowed_operation', 'YES');
    ELSE
        DBMS_SESSION.set_context('appcar_ctx', 'allowed_operation', 'NO');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER appcar_employee_login_trigger
AFTER LOGON ON DATABASE
BEGIN
    appcar_proc_ctx;
END;
/


-- Create triggers to enforce the context on CHECK_IN and RETURNS tables
CREATE OR REPLACE TRIGGER enforce_check_in_time
BEFORE INSERT OR UPDATE ON APPCAR_ADMIN_APP.CHECK_IN
BEGIN
    IF SYS_CONTEXT('appcar_ctx', 'allowed_operation') = 'NO' THEN
        RAISE_APPLICATION_ERROR(-20001, 'Check-in and return operations are allowed between 10 AM and 8 PM only.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER enforce_return_time
BEFORE INSERT OR UPDATE ON APPCAR_ADMIN_APP.RETURNS
BEGIN
    IF SYS_CONTEXT('appcar_ctx', 'allowed_operation') = 'NO' THEN
        RAISE_APPLICATION_ERROR(-20001, 'Check-in and return operations are allowed between 10 AM and 8 PM only.');
    END IF;
END;
/

-- Test the context (You can edit the appcar_proc_ctx procedure to change the allowed time if needed)
-- Execute the following command as employee
INSERT INTO APPCAR_ADMIN_APP.CHECK_IN (id, check_in_date, comments, id_booking) VALUES (99,CURRENT_TIMESTAMP, 'Test', 1);
COMMIT;
ROLLBACK;

-- Create a SQL injection vulnerability (Enter the id of the customer to get all his profile, including bookings and invoices)
CREATE OR REPLACE PROCEDURE APPCAR_ADMIN_APP.fetch_customer_data(p_customer_id IN INT) AS
    result_set SYS_REFCURSOR;
BEGIN
    -- Constructing a query with direct concatenation, vulnerable to SQL injection
     EXECUTE IMMEDIATE 'SELECT u.*, b.*, i.* ' ||
                 'FROM APPCAR_ADMIN_APP.USERS u ' ||
                 'LEFT JOIN APPCAR_ADMIN_APP.BOOKINGS b ON u.id_customer = b.id_customer ' ||
                 'LEFT JOIN APPCAR_ADMIN_APP.INVOICES i ON b.id = i.id_booking ' ||
                 'WHERE u.id_customer = ''' || TO_CHAR(p_customer_id) || '''' INTO result_set;

    DBMS_OUTPUT.PUT_LINE(result_set);
END;
/


CALL APPCAR_ADMIN_APP.fetch_customer_data(1);
SELECT * FROM USER_ERRORS WHERE NAME = 'APPCAR_ADMIN_APP.fetch_customer_data' ORDER BY SEQUENCE;