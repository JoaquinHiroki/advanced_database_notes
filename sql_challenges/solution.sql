-- Exercise 1
SELECT account_id, owner_name, balance
FROM accounts
ORDER BY account_id;


-- Begin the transaction
BEGIN
    
    UPDATE accounts
    SET balance = balance - 50
    WHERE account_id = 3;

    
    UPDATE accounts
    SET balance = balance + 50
    WHERE account_id = 1;

    COMMIT;
END;
/


SELECT account_id, owner_name, balance
FROM accounts
ORDER BY account_id;


--Exercise 2
SELECT account_id, owner_name, balance
FROM accounts
ORDER BY account_id;

UPDATE accounts
SET balance = balance - 10000
WHERE account_id = 2;  

UPDATE accounts
SET balance = balance + 10000
WHERE account_id = 3;  -- Charlie


SELECT account_id, owner_name, balance
FROM accounts
ORDER BY account_id;


ROLLBACK;
SELECT account_id, owner_name, balance
FROM accounts
ORDER BY account_id;

--Exercise 3
SELECT account_id, owner_name, balance
FROM accounts
ORDER BY account_id;

UPDATE accounts
SET balance = balance + 25
WHERE account_id = 1; 
SAVEPOINT after_alice;

UPDATE accounts
SET balance = balance - 25
WHERE account_id = 3;  

SELECT account_id, owner_name, balance
FROM accounts
ORDER BY account_id;

ROLLBACK TO SAVEPOINT after_alice;

SELECT account_id, owner_name, balance
FROM accounts
ORDER BY account_id;


UPDATE accounts
SET balance = balance - 25
WHERE account_id = 2;  

COMMIT;

SELECT account_id, owner_name, balance
FROM accounts
ORDER BY account_id;

--Exercise 4

CREATE OR REPLACE PROCEDURE deposit_funds (
    p_account_id  IN accounts.account_id%TYPE,
    p_amount      IN accounts.balance%TYPE
)
IS
    v_current_balance  accounts.balance%TYPE;

BEGIN
    IF p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 
            'Deposit amount must be greater than zero. Received: ' || p_amount);
    END IF;

    SELECT balance
    INTO v_current_balance
    FROM accounts
    WHERE account_id = p_account_id;

    UPDATE accounts
    SET balance = balance + p_amount
    WHERE account_id = p_account_id;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Success: Account ' || p_account_id || 
                         ' credited $' || p_amount ||
                         '. New balance: $' || (v_current_balance + p_amount));

EXCEPTION
    -- Handle invalid account
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002,
            'Account ID ' || p_account_id || ' does not exist.');

    WHEN OTHERS THEN
        ROLLBACK;
        RAISE; 

END deposit_funds;
/


SET SERVEROUTPUT ON;

SELECT account_id, owner_name, balance
FROM accounts
ORDER BY account_id;

EXEC deposit_funds(3, 75);

SELECT account_id, owner_name, balance
FROM accounts
ORDER BY account_id;

EXEC deposit_funds(1, 0);

EXEC deposit_funds(1, -100);

EXEC deposit_funds(99, 50);

--Exercise 5 (answers only)
--1. Reserve slot and create appointment go inside the transaction
--1. Send confirmation goes outside after commit
--2. Your commit inside the procedure commits all uncommitted work in the caller's session not just yours
--2. The developer loses the ability to rollback their own changes, data they weren't ready to save gets permanently committed
--3. Calculate_copay() can be used in select because functions return a value and have no side effects
--3. post_payment() cant be used in select because procedures don't return values and Oracle doesn't allow them in SQL statements