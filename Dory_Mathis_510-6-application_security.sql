-- The following script is used to create security context
-- Run this script from the CDB with the SYS user
-- Author: Mathis Dory
-- Date: 2023-01-27
-- Group 510

alter session set container = ORCLPDB;

--+++++++ Create a context +++++++--
-- The context is used to prevent inserting check in and returns outside 10 am and 8 pm
--+++++++ =============== +++++++--

CREATE CONTEXT appcar_ctx USING appcar_proc_ctx;

-- Create a procedure to set the context to prevent inserting check in and returns outside 10 am and 8 pm
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

CREATE OR REPLACE TRIGGER appcar_login_trigger
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


--+++++++ Create SQLi vulnerable function +++++++--
-- The following function is vulnerable to SQL injection
--+++++++ =============== +++++++--

-- Create a SQL injection vulnerability (Enter the id of the customer to get all his profile, including bookings and invoices)
CREATE OR REPLACE PROCEDURE APPCAR_ADMIN_APP.get_customer_bookings(p_customer_name IN VARCHAR2)
AS
      TYPE booking_record IS RECORD (
        name VARCHAR2(100),
        surname VARCHAR2(100),
        email VARCHAR2(100),
        license VARCHAR2(50),
        booking_id INT,
        starting_date DATE,
        ending_date DATE,
        total_price DECIMAL(10, 2)
    );
    TYPE booking_table IS TABLE OF booking_record;
    v_table booking_table;
BEGIN
    EXECUTE IMMEDIATE
        'SELECT u.name, u.surname, u.email, c.license, b.id AS booking_id, b.starting_date, b.ending_date, i.total_price ' ||
        'FROM APPCAR_ADMIN_APP.BOOKINGS b ' ||
        'JOIN APPCAR_ADMIN_APP.CUSTOMERS c ON c.id = b.id_customer ' ||
        'JOIN APPCAR_ADMIN_APP.USERS u ON u.id = c.id_user ' ||
        'LEFT JOIN APPCAR_ADMIN_APP.INVOICES i ON b.id = i.id_booking ' ||
        'WHERE u.name LIKE ''%' || p_customer_name || '%''' BULK COLLECT INTO v_table;
     FOR i IN 1..v_table.COUNT LOOP
        DBMS_OUTPUT.put_line(  v_table(i).name || ' ' || v_table(i).surname || ' ' || v_table(i).email  || ' ' ||  v_table(i).license || ' - Booking ID: ' || v_table(i).booking_id || ' - Starting date: ' || v_table(i).starting_date || ' - Ending date: ' || v_table(i).ending_date || ' - Total price: ' || v_table(i).total_price);
    END LOOP;
    EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.put_line('Error: ' || SQLERRM);


END get_customer_bookings;


-- The following is the mitigate version of the procedure
CREATE OR REPLACE PROCEDURE APPCAR_ADMIN_APP.get_customer_bookings_mitigate(p_customer_name IN VARCHAR2)
AS
    TYPE booking_record IS RECORD (
        name VARCHAR2(100),
        surname VARCHAR2(100),
        email VARCHAR2(100),
        license VARCHAR2(50),
        booking_id INT,
        starting_date DATE,
        ending_date DATE,
        total_price DECIMAL(10, 2)
    );
    TYPE booking_table IS TABLE OF booking_record;
    v_table booking_table;
BEGIN
    EXECUTE IMMEDIATE
        'SELECT u.name, u.surname, u.email, c.license, b.id AS booking_id, b.starting_date, b.ending_date, i.total_price ' ||
        'FROM APPCAR_ADMIN_APP.BOOKINGS b ' ||
        'JOIN APPCAR_ADMIN_APP.CUSTOMERS c ON c.id = b.id_customer ' ||
        'JOIN APPCAR_ADMIN_APP.USERS u ON u.id = c.id_user ' ||
        'LEFT JOIN APPCAR_ADMIN_APP.INVOICES i ON b.id = i.id_booking ' ||
        'WHERE u.name LIKE :1'
    BULK COLLECT INTO v_table USING '%' || p_customer_name || '%';

    FOR i IN 1..v_table.COUNT LOOP
        DBMS_OUTPUT.put_line(  v_table(i).name || ' ' || v_table(i).surname || ' ' || v_table(i).email  || ' ' ||  v_table(i).license || ' - Booking ID: ' || v_table(i).booking_id || ' - Starting date: ' || v_table(i).starting_date || ' - Ending date: ' || v_table(i).ending_date || ' - Total price: ' || v_table(i).total_price);
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.put_line('Error: ' || SQLERRM);
END get_customer_bookings_mitigate;


--+++++++ Test the context +++++++--
-- Insert a check in row outside 10 am and 8 pm (Should fail)
-- Insert a check in row between 10 am and 8 pm (Should succeed)
--+++++++ =============== +++++++--

-- Test the context (You can edit the appcar_proc_ctx procedure to change the allowed time if needed)
-- Try executing the following statements with another user than SYS
INSERT INTO APPCAR_ADMIN_APP.CHECK_IN(id, check_in_date, comments, id_booking) VALUES (999,CURRENT_TIMESTAMP, 'Test', 2);
COMMIT;
ROLLBACK;

--+++++++ Test the SQL injection +++++++--
-- First, get the information of a customer
-- Second is the SQL injection getting all passwords and emails of all users
-- Third is the mitigate version of the procedure with normal execution
-- Fourth is the mitigate version of the procedure with SQL injection (Should not display anything)
--+++++++ =============== +++++++--

-- Execute the following statements with the appcar_admin_app user
CALL APPCAR_ADMIN_APP.get_customer_bookings('Luck');
CALL APPCAR_ADMIN_APP.get_customer_bookings('Nonexistent'' UNION SELECT ''EMAIL: '', email , ''PASSWORD: '', password, 0, DATE ''1970-01-01'', DATE ''1970-01-01'', 0.0 FROM APPCAR_ADMIN_APP.USERS --');

CALL APPCAR_ADMIN_APP.get_customer_bookings_mitigate('Luck');
CALL APPCAR_ADMIN_APP.get_customer_bookings_mitigate('Nonexistent'' UNION SELECT ''EMAIL: '', email , ''PASSWORD: '', password, 0, DATE ''1970-01-01'', DATE ''1970-01-01'', 0.0 FROM APPCAR_ADMIN_APP.USERS --');
