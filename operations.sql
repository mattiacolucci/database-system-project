-- OPERATION 1 (insert of new customer)
DECLARE
account_ref REF AccountTY;
last_account_code INTEGER;
last_business_piva VARCHAR(11);
BEGIN
-- Get last account code
SELECT MAX(code) INTO last_account_code FROM Accounts;

-- Get last Business piva
SELECT MAX(piva) INTO last_business_piva FROM Business;

-- Insert a new account
INSERT INTO Accounts VALUES(AccountTY(last_account_code+1, SYSDATE, last_account_code+1, 'ppp'));

-- Get ref to the inserted account
SELECT REF(a) INTO account_ref FROM Accounts a WHERE code=last_account_code+1;

-- Insert a new business
INSERT INTO Business VALUES(BusinessTY(SYSDATE,0,(AccountsNT(account_ref)),TO_NUMBER(last_business_piva)+1,'GG')); 
COMMIT;
END;
/

-- OPERATION 2 (insert of new order)
DECLARE
account_ref REF AccountTY;
last_order_code INTEGER;
BEGIN
    -- Get a random account ref
    SELECT REF(a) INTO account_ref FROM Accounts a WHERE a.code=1;
    
    -- Get last order code
    SELECT MAX(code) INTO last_order_code FROM Orders;
    
    -- Insert a new order made by that account
    INSERT INTO Orders VALUES (OrderTY(last_order_code+1,'bulk','placed','phone',0,(DateTY(SYSDATE,null,null)),(AddressTY('pp','pp','province','ppp')),null,account_ref,null));
    
    COMMIT;
END;
/

-- OPERATION 3 (assign a team to an order)
DECLARE
team_r REF TeamTY;
last_order_code INTEGER;
BEGIN
    -- Get the ref of the team with code 3
    SELECT REF(t) INTO team_r FROM Team t WHERE t.code=3;

    -- Get last order code
    SELECT MAX(code) INTO last_order_code FROM Orders;

    -- Assign the team to the order
    UPDATE Orders o SET o.team_ref = team_r where o.code=last_order_code;
    COMMIT;
END;
/


-- OPERATION 4 (get total number of orders handled by a team)
SELECT num_orders FROM Team WHERE code=3;
/

-- OPERATION 5 (show teams ordered by their score)
SELECT * FROM Team ORDER BY ((score.feedback_score+score.delivery_score)/2) DESC;
/
