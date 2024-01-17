-- The following script is run by the user appcar_admin_app in the PDB
-- Author: Mathis Dory
-- Date: 2023-12-26
-- Group 510


-- Switch to the PDB
ALTER SESSION SET CONTAINER = orclpdb;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') FROM DUAL;


-- Create tables for the project


 -- ==================== PART 1 ====================

-- Customers table
CREATE TABLE CUSTOMERS
(
    id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    license VARCHAR2(50) NOT NULL UNIQUE
);

-- Employees table
CREATE TABLE APPCAR_HR_MANAGER.EMPLOYEES
(
    id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    department VARCHAR2(100) NOT NULL CHECK (department IN ('hr', 'commercial', 'administrative'))
);


 -- ==================== PART 2 ====================

-- User table
CREATE TABLE USERS
(
    id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    name VARCHAR2(100) NOT NULL,
    surname VARCHAR2(100) NOT NULL,
    sex CHAR(1) NOT NULL CHECK ( sex IN ('M', 'F')),
    birthdate DATE NOT NULL,
    password VARCHAR2(100) NOT NULL,
    email VARCHAR2(100) NOT NULL UNIQUE,
    id_customer INT,
    id_employee INT,
    FOREIGN KEY (id_customer) REFERENCES CUSTOMERS (id),
    FOREIGN KEY (id_employee) REFERENCES APPCAR_HR_MANAGER.EMPLOYEES (id)
);

-- States table
CREATE TABLE STATES
(
    id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    name VARCHAR2(50) NOT NULL UNIQUE
);

-- Models table
CREATE TABLE APPCAR_FLEET_RESPONSIBLE.MODELS
(
    id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    name  VARCHAR2(100) NOT NULL,
    brand VARCHAR2(100) NOT NULL,
    power INT NOT NULL
);

-- Pricings table
CREATE TABLE APPCAR_FLEET_RESPONSIBLE.PRICINGS
(
    id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    daily_price DECIMAL(10, 2) NOT NULL,
    kilometer_price DECIMAL(10, 2) NOT NULL,
    daily_penalty DECIMAL(10, 2) NOT NULL,
    deposit DECIMAL(10, 2) NOT NULL
);

-- Equipments table
CREATE TABLE APPCAR_FLEET_RESPONSIBLE.EQUIPMENTS
(
    id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    name VARCHAR2(100) NOT NULL
);

-- Models_equipments_pricings table
CREATE TABLE APPCAR_FLEET_RESPONSIBLE.MODELS_EQUIPMENTS_PRICINGS
(
    id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    id_equipment INT,
    id_model INT NOT NULL,
    id_pricing INT NOT NULL,
    FOREIGN KEY (id_equipment) REFERENCES APPCAR_FLEET_RESPONSIBLE.EQUIPMENTS (id),
    FOREIGN KEY (id_model) REFERENCES APPCAR_FLEET_RESPONSIBLE.MODELS (id),
    FOREIGN KEY (id_pricing) REFERENCES APPCAR_FLEET_RESPONSIBLE.PRICINGS (id)
);


 -- ==================== PART 3 ====================

-- Vehicles table
CREATE TABLE APPCAR_FLEET_RESPONSIBLE.VEHICLES
(
    id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    purchase_date DATE NOT NULL,
    purchase_price DECIMAL(10, 2) NOT NULL,
    kilometrage INT NOT NULL,
    id_model_equipment INT NOT NULL,
    id_state INT NOT NULL,
    FOREIGN KEY (id_state) REFERENCES APPCAR_ADMIN_APP.STATES (id),
    FOREIGN KEY (id_model_equipment) REFERENCES APPCAR_FLEET_RESPONSIBLE.MODELS_EQUIPMENTS_PRICINGS (id)
);

 -- ==================== PART 4 ====================

-- Bookings table
CREATE TABLE BOOKINGS
(
    id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    starting_date DATE NOT NULL,
    ending_date DATE NOT NULL,
    is_canceled INT NOT NULL CHECK (is_canceled IN ('1', '0')),
    is_running INT NOT NULL CHECK (is_running IN ('1', '0')),
    is_closed INT NOT NULL CHECK (is_closed IN ('1', '0')),
    id_customer INT NOT NULL,
    id_vehicle INT NOT NULL,
    FOREIGN KEY (id_customer) REFERENCES CUSTOMERS (id),
    FOREIGN KEY (id_vehicle) REFERENCES APPCAR_FLEET_RESPONSIBLE.VEHICLES (id)
);

-- Invoices table
CREATE TABLE INVOICES
(
    id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    total_price DECIMAL(10, 2) NOT NULL,
    delay_supplement DECIMAL(10, 2) NOT NULL,
    booking_price DECIMAL(10, 2) NOT NULL,
    distance_price DECIMAL(10, 2) NOT NULL,
    generated_date DATE NOT NULL,
    is_paid INT NOT NULL CHECK (is_paid IN ('1', '0')),
    id_booking INT NOT NULL,
    FOREIGN KEY (id_booking) REFERENCES BOOKINGS (id)
);

-- Check-in table
CREATE TABLE CHECK_IN
(
    id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    check_in_date TIMESTAMP NOT NULL,
    comments VARCHAR2(255),
    id_booking INT NOT NULL,
    FOREIGN KEY (id_booking) REFERENCES BOOKINGS (id)
);

-- Returns table
CREATE TABLE RETURNS
(
    id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    return_date TIMESTAMP NOT NULL,
    comments VARCHAR2(255),
    id_booking INT NOT NULL,
    FOREIGN KEY (id_booking) REFERENCES BOOKINGS (id)
);

COMMIT;