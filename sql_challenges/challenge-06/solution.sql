-- Creates the PET_CARE_LOG table 
CREATE TABLE PET_CARE_LOG (
    PRODUCT_ID        NUMBER(10)    NOT NULL,
    LOG_DATETIME      DATE          NOT NULL,
    CREATED_BY_USER   VARCHAR2(30),
    LOG_TEXT          VARCHAR2(500),
    UPDATE_DATE       TIMESTAMP,
    UPDATED_BY_USER   VARCHAR2(30),
    CONSTRAINT pk_pet_care_log PRIMARY KEY (PRODUCT_ID, LOG_DATETIME)
);

-- TRIGGER 1: fires before inserting a row
CREATE OR REPLACE TRIGGER trg_pet_care_log_insert
BEFORE INSERT ON PET_CARE_LOG
FOR EACH ROW
BEGIN
    :NEW.UPDATE_DATE := SYSTIMESTAMP;
    :NEW.UPDATED_BY_USER := USER;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'Something went wrong while inserting the record: ' || SQLERRM);
END;

-- TRIGGER 2: fires before updating a row
CREATE OR REPLACE TRIGGER trg_pet_care_log_update
BEFORE UPDATE ON PET_CARE_LOG
FOR EACH ROW
BEGIN
    IF USER != :OLD.UPDATED_BY_USER THEN
        RAISE_APPLICATION_ERROR(-20002, 'You are not allowed to update this record because you did not created it');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'Something went wrong while updating the record' || SQLERRM);
END;

-- TRIGGER 3: fires before deleting a row
CREATE OR REPLACE TRIGGER trg_pet_care_log_delete
BEFORE DELETE ON PET_CARE_LOG
FOR EACH ROW
BEGIN
    IF USER != 'JOEMANAGER' THEN
        RAISE_APPLICATION_ERROR(-20003, 'only the manager is allowed to delete records from the pet care log');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20003, 'Something went wrong while deleting the record' || SQLERRM);
END;