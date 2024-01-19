-- The following script insert samples data in the tables
-- Run this script FROM the CDB as SYS user
-- Author: Mathis Dory
-- Date: 2023-12-27
-- Group 510

-- Switch to the PDB
ALTER SESSION SET CONTAINER = orclpdb;

INSERT INTO APPCAR_ADMIN_APP.USERS (id, name, surname, sex, birthdate, password, email)
VALUES (1, 'John', 'Doe', 'M', TO_DATE('1980-01-01', 'YYYY-MM-DD'), 'pass123', 'john.doe@example.com');
INSERT INTO APPCAR_ADMIN_APP.USERS (id, name, surname, sex, birthdate, password, email)
VALUES (2, 'Jane', 'Smith', 'F', TO_DATE('1985-02-02', 'YYYY-MM-DD'), 'pass456', 'jane.smith@example.com');
INSERT INTO APPCAR_ADMIN_APP.USERS (id, name, surname, sex, birthdate, password, email)
VALUES (3, 'Luck', 'Cena', 'M', TO_DATE('1966-01-12', 'YYYY-MM-DD'), 'pass789', 'luck123h@example.com');
INSERT INTO APPCAR_ADMIN_APP.USERS (id, name, surname, sex, birthdate, password, email)
VALUES (4, 'Mario', 'Bross', 'M', TO_DATE('1999-12-01', 'YYYY-MM-DD'), 'pass101112', 'mario.bross@example.com');

INSERT INTO APPCAR_ADMIN_APP.CUSTOMERS (id, license, id_user) VALUES (1, 'ABC123', 3);
INSERT INTO APPCAR_ADMIN_APP.CUSTOMERS (id, license, id_user) VALUES (2, 'XYZ456', 4);

INSERT INTO APPCAR_HR_MANAGER.EMPLOYEES (id, department, id_user) VALUES (1, 'hr', 1);
INSERT INTO APPCAR_HR_MANAGER.EMPLOYEES (id, department, id_user) VALUES (2, 'commercial', 2);

INSERT INTO APPCAR_ADMIN_APP.STATES (id, name) VALUES (1, 'Available');
INSERT INTO APPCAR_ADMIN_APP.STATES (id, name) VALUES (2, 'Unavailable');
INSERT INTO APPCAR_ADMIN_APP.STATES (id, name) VALUES (3, 'Damaged');
INSERT INTO APPCAR_ADMIN_APP.STATES (id, name) VALUES (4, 'In maintenance');

INSERT INTO APPCAR_FLEET_RESPONSIBLE.MODELS (id, name, brand, power) VALUES (1, 'Model X', 'Tesla', 1800);
INSERT INTO APPCAR_FLEET_RESPONSIBLE.MODELS (id, name, brand, power) VALUES (2, 'Picasso', 'Citroen', 200);
INSERT INTO APPCAR_FLEET_RESPONSIBLE.MODELS (id, name, brand, power) VALUES (3, 'Porsche', 'Taycan', 1900);
INSERT INTO APPCAR_FLEET_RESPONSIBLE.MODELS (id, name, brand, power) VALUES (4, 'Porsche', 'Macan', 680);
INSERT INTO APPCAR_FLEET_RESPONSIBLE.MODELS (id, name, brand, power) VALUES (5, 'Peugeot', '3008', 300);

INSERT INTO APPCAR_FLEET_RESPONSIBLE.PRICINGS (id, daily_price, kilometer_price, daily_penalty, deposit)
VALUES (1, 550.00, 0.10, 200.00, 3500.00);
INSERT INTO APPCAR_FLEET_RESPONSIBLE.PRICINGS (id, daily_price, kilometer_price, daily_penalty, deposit)
VALUES (2, 400.00, 0.10, 200.00, 2500.00);
INSERT INTO APPCAR_FLEET_RESPONSIBLE.PRICINGS (id, daily_price, kilometer_price, daily_penalty, deposit)
VALUES (3, 100.00, 0.50, 40.00, 300.00);
INSERT INTO APPCAR_FLEET_RESPONSIBLE.PRICINGS (id, daily_price, kilometer_price, daily_penalty, deposit)
VALUES (4, 98.00, 0.50, 40.00, 500.00);

INSERT INTO APPCAR_FLEET_RESPONSIBLE.EQUIPMENTS (id, name) VALUES (1, 'GPS Navigation');
INSERT INTO APPCAR_FLEET_RESPONSIBLE.EQUIPMENTS (id, name) VALUES (2, 'Child Seat');
INSERT INTO APPCAR_FLEET_RESPONSIBLE.EQUIPMENTS (id, name) VALUES (3, 'Extra Luggage');
INSERT INTO APPCAR_FLEET_RESPONSIBLE.EQUIPMENTS (id, name) VALUES (4, 'Insurance Package');
INSERT INTO APPCAR_FLEET_RESPONSIBLE.EQUIPMENTS (id, name) VALUES (5, 'Roof Box');

INSERT INTO APPCAR_FLEET_RESPONSIBLE.MODELS_EQUIPMENTS_PRICINGS (id, id_equipment, id_model, id_pricing) VALUES (1, 1, 1, 1);
INSERT INTO APPCAR_FLEET_RESPONSIBLE.MODELS_EQUIPMENTS_PRICINGS (id, id_equipment, id_model, id_pricing) VALUES (2, 2, 2, 2);
INSERT INTO APPCAR_FLEET_RESPONSIBLE.MODELS_EQUIPMENTS_PRICINGS (id, id_equipment, id_model, id_pricing) VALUES (3, 3, 3, 3);
INSERT INTO APPCAR_FLEET_RESPONSIBLE.MODELS_EQUIPMENTS_PRICINGS (id, id_equipment, id_model, id_pricing) VALUES (4, 4, 4, 4);


INSERT INTO APPCAR_FLEET_RESPONSIBLE.VEHICLES (id, purchase_date, purchase_price, kilometrage, id_model_equipment, id_state)
VALUES (1, TO_DATE('2020-01-01', 'YYYY-MM-DD'), 40000.00, 10000, 1, 1);
INSERT INTO APPCAR_FLEET_RESPONSIBLE.VEHICLES (id, purchase_date, purchase_price, kilometrage, id_model_equipment, id_state)
VALUES (2, TO_DATE('2019-05-01', 'YYYY-MM-DD'), 35000.00, 15000, 2, 2);


INSERT INTO APPCAR_ADMIN_APP.BOOKINGS (id, starting_date, ending_date, is_canceled, is_running, is_closed, id_customer, id_vehicle)
VALUES (1, TO_DATE('2023-07-01', 'YYYY-MM-DD'), TO_DATE('2023-07-10', 'YYYY-MM-DD'), 0, 0, 1, 1, 1);
INSERT INTO APPCAR_ADMIN_APP.BOOKINGS (id, starting_date, ending_date, is_canceled, is_running, is_closed, id_customer, id_vehicle)
VALUES (2, TO_DATE('2023-07-02', 'YYYY-MM-DD'), TO_DATE('2023-07-11', 'YYYY-MM-DD'), 0, 0, 1, 2, 2);

INSERT INTO APPCAR_ADMIN_APP.INVOICES (id, total_price, delay_supplement, booking_price, distance_price, generated_date, is_paid, id_booking)
VALUES (1, 5500.00, 0.00, 5000.00, 500.00, TO_DATE('2023-07-10', 'YYYY-MM-DD'), 1, 1);


INSERT INTO APPCAR_ADMIN_APP.CHECK_IN (id, check_in_date, comments, id_booking) VALUES (1, TO_DATE('2023-07-01', 'YYYY-MM-DD'), 'No issues', 1);
INSERT INTO APPCAR_ADMIN_APP.CHECK_IN (id, check_in_date, comments, id_booking) VALUES (2, TO_DATE('2023-07-02', 'YYYY-MM-DD'), 'Scratch on left door',2);


INSERT INTO APPCAR_ADMIN_APP.RETURNS (id, return_date, comments, id_booking) VALUES (1, TO_DATE('2023-07-10', 'YYYY-MM-DD'), 'Returned on time',1);
INSERT INTO APPCAR_ADMIN_APP.RETURNS (id, return_date, comments, id_booking) VALUES (2, TO_DATE('2023-07-11', 'YYYY-MM-DD'), 'Delayed return for one day',2);

COMMIT;