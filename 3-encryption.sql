-- The following script is used to encrypt the passwords of the users in the database
-- Run this script from the CDB with the SYS user
-- Author: Mathis Dory
-- Date: 2023-12-27
-- Group 510

-- Connect to the PDB
ALTER SESSION SET CONTAINER = orclpdb;

-- Create the table to store the encryption keys
CREATE TABLE appcar_encryption_keys (
    id_keys     NUMBER PRIMARY KEY,
    key         RAW(16) NOT NULL,
    table_name  VARCHAR2(30) NOT NULL
);

-- Create the procedure to encrypt the passwords
CREATE OR REPLACE PROCEDURE appcar_encrypt_user_passwords AS
  key_encrypt RAW(16);
  operation_mode PLS_INTEGER;
  cursor c is SELECT id, password FROM APPCAR_ADMIN_APP.users;
  encrypted_password RAW(128);
BEGIN
  key_encrypt := dbms_crypto.randombytes(16);
  INSERT INTO appcar_encryption_keys VALUES (1, key_encrypt, 'USERS');
  operation_mode := dbms_crypto.encrypt_aes128 + dbms_crypto.pad_pkcs5 + dbms_crypto.chain_cbc;
  FOR i IN c LOOP
    encrypted_password := dbms_crypto.encrypt(utl_i18n.string_to_raw(i.password, 'AL32UTF8'), operation_mode, key_encrypt);
    UPDATE APPCAR_ADMIN_APP.users SET password = encrypted_password WHERE id = i.id;
  END LOOP;
  COMMIT;
END appcar_encrypt_user_passwords;
/

-- Create the functions to encrypt and decrypt the passwords
CREATE OR REPLACE FUNCTION encrypt_using_aes(
    secret_value IN VARCHAR2,
    encryption_key IN VARCHAR2
) RETURN RAW AS
  encrypted_value RAW(1000);
BEGIN
  encrypted_value := DBMS_CRYPTO.ENCRYPT(
      src => utl_raw.cast_to_raw(secret_value),
      key => utl_raw.cast_to_raw(encryption_key),
      typ => DBMS_CRYPTO.ENCRYPT_AES128 + DBMS_CRYPTO.CHAIN_CBC + DBMS_CRYPTO.PAD_ZERO
  );
  RETURN encrypted_value;
END;
/

CREATE OR REPLACE FUNCTION decrypt_using_aes(
    encrypted_value IN RAW,
    encryption_key IN VARCHAR2
) RETURN VARCHAR2 AS
  secret_value VARCHAR2(255);
BEGIN
  secret_value := DBMS_CRYPTO.DECRYPT(
      src => encrypted_value,
      key => utl_raw.cast_to_raw(encryption_key),
      typ => DBMS_CRYPTO.ENCRYPT_AES128 + DBMS_CRYPTO.CHAIN_CBC + DBMS_CRYPTO.PAD_ZERO
  );
  RETURN UTL_RAW.CAST_TO_VARCHAR2(secret_value);
END;
/

-- Test the encryption
CALL appcar_encrypt_user_passwords();
SELECT * FROM APPCAR_ADMIN_APP.users;


-- Procedure to decrypt the passwords
CREATE OR REPLACE FUNCTION appcar_decrypt_user_password_by_id(p_user_id INT)
RETURN VARCHAR2 AS
  key_decrypt RAW(16);
  operation_mode PLS_INTEGER;
  encrypted_password RAW(128);
  decrypted_password VARCHAR2(100);
BEGIN
  -- Retrieve the encryption key
  SELECT key INTO key_decrypt FROM appcar_encryption_keys WHERE table_name = 'USERS';

  operation_mode := dbms_crypto.encrypt_aes128 + dbms_crypto.pad_pkcs5 + dbms_crypto.chain_cbc;

  -- Retrieve the encrypted password for the specified user
  SELECT password INTO encrypted_password FROM APPCAR_ADMIN_APP.users WHERE id = p_user_id;

  -- Decrypt the password
  IF encrypted_password IS NOT NULL AND LENGTH(encrypted_password) > 0 THEN
    decrypted_password := UTL_RAW.CAST_TO_VARCHAR2(dbms_crypto.decrypt(encrypted_password, operation_mode, key_decrypt));
    RETURN decrypted_password;
  ELSE
    RETURN NULL; -- Return NULL if the password is not set or empty
  END IF;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN NULL; -- Return NULL if the user does not exist
  WHEN OTHERS THEN
    -- Handle other exceptions if necessary
    RAISE;
END appcar_decrypt_user_password_by_id;
/


-- Test the decryption (should return the password of the user with id 1 in clear but the password in the table should still be encrypted)
SELECT appcar_decrypt_user_password_by_id(1) FROM dual;


-- Procedure to encrypt a single password
CREATE OR REPLACE FUNCTION appcar_encrypt_single_password(p_password VARCHAR2)
RETURN RAW AS
  key_encrypt RAW(16);
  operation_mode PLS_INTEGER;
  encrypted_password RAW(128);
BEGIN
  SELECT key INTO key_encrypt FROM appcar_encryption_keys WHERE id_keys = 1;
  operation_mode := dbms_crypto.encrypt_aes128 + dbms_crypto.pad_pkcs5 + dbms_crypto.chain_cbc;
  encrypted_password := dbms_crypto.encrypt(utl_i18n.string_to_raw(p_password, 'AL32UTF8'), operation_mode, key_encrypt);
  RETURN encrypted_password;

END appcar_encrypt_single_password;
/

-- Trigger to encrypt the password before inserting or updating a user
CREATE OR REPLACE TRIGGER appcar_encrypt_user_password_before_insert_or_update
BEFORE INSERT OR UPDATE ON APPCAR_ADMIN_APP.users
FOR EACH ROW
BEGIN
  :NEW.password := appcar_encrypt_single_password(:NEW.password);
END appcar_encrypt_user_password_before_insert_or_update;
/
COMMIT;

-- Test the trigger
INSERT INTO APPCAR_ADMIN_APP.users (id, name, surname, sex, birthdate, password, email, id_customer, id_employee) VALUES (99, 'ENCRYPTION', 'TEST', 'M', TO_DATE('1999-01-01', 'YYYY-MM-DD'), 'encrypt1234', 'trigger@encryption.sql', NULL, NULL);
SELECT * FROM APPCAR_ADMIN_APP.users;
ROLLBACK;

