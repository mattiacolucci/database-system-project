-- TRIGGER CHECKING

-- TRIGGER: check_business_insert / check_individual_insert

-- OPERATION 1 (add a customer)
-- Should fail because no accounts are provided
INSERT INTO Business VALUES(BusinessTY(SYSDATE,98,null,'78787878782','GG'));
/

-- Insert a customer with an new account
-- Should work correctly
DECLARE 
account_ref REF AccountTY;

BEGIN
INSERT INTO Accounts VALUES(AccountTY(400, SYSDATE, 'pp@s.com', 'ppp'));

SELECT REF(a) INTO account_ref FROM Accounts a WHERE code=400;

INSERT INTO Business VALUES(BusinessTY(SYSDATE,0,(AccountsNT(account_ref)),'78787878786','GG')); 
COMMIT;
END;
/

-- Should fail because try to assign an existing account to a customer that is not its owner
DECLARE 
account_ref REF AccountTY;
BEGIN
-- Take the account of the previous inserted customer
SELECT REF(a) INTO account_ref FROM Accounts a WHERE code=400;

-- try to insert a customer with that accout
INSERT INTO Business VALUES(BusinessTY(SYSDATE,0,(AccountsNT(account_ref)),'78787878705','GG')); 
COMMIT;
END;
/

--------------------------------------------------------------------------------------------------------------------

-- OPERATIONS ON TEAM

-- TRIGGER: check_team_members

-- Try insert a team with personnel coming from different operational centers
-- Should fail
DECLARE
personnel_refs PersonnelVA := PersonnelVA();
personnel_r PersonnelTY;
BEGIN
    personnel_refs.extend(8);

    -- Get the refs of the first personnel of 5 distinct operational centers
    FOR i IN 1..5 LOOP
        SELECT p.column_value INTO personnel_refs(i) FROM OperationalCenter o, TABLE(o.personnels) p WHERE o.code=i*5 and ROWNUM = 1;
    END LOOP;
    
    -- Try insert a team with these personnels
    -- Should not works because personnels does not belong to the same operational center
    INSERT INTO Team VALUES(TeamTY(100,'pp',0,(ScoreTY(0,0)),personnel_refs));
    COMMIT;
END;
/

-- try to insert a team with all personnel coming from the same operational center
-- Should work
DECLARE
personnel_refs PersonnelVA := PersonnelVA();
personnel_r PersonnelTY;
BEGIN
    personnel_refs.extend;

    -- Get the refs of the first personnel of one operational center
    SELECT p.column_value INTO personnel_refs(1) FROM OperationalCenter o, TABLE(o.personnels) p WHERE o.code=5 and ROWNUM = 1;
    
    -- Try insert a team with that personnel
    -- Should work because all personnels come from the same operational center
    INSERT INTO Team VALUES(TeamTY(100,'pp',0,(ScoreTY(0,0)),personnel_refs));
    COMMIT;
END;
/

-- try to insert a team with duplicated personnel coming from the same operational center
-- Should fail
DECLARE
personnel_r PersonnelTY;
personnel_refs PersonnelVA := PersonnelVA();
BEGIN
    personnel_refs.extend(8);
    
    -- Get the ref of the first personnel of one operational center and put it in 2 different positions of the array of personnels
    SELECT p.column_value INTO personnel_refs(1) FROM OperationalCenter o, TABLE(o.personnels) p WHERE o.code=5 and ROWNUM = 1;
    personnel_refs(2) := personnel_refs(1);
    
    -- Try insert a team with these personnels
    -- Should not work because have duplicated personnels
    INSERT INTO Team VALUES(TeamTY(101,'pp',0,(ScoreTY(0,0)),personnel_refs));
    COMMIT;
END;
/

-- try to insert a team without members
-- Should fail
INSERT INTO Team VALUES(TeamTY(1000,'pp',0,(ScoreTY(0,0)),(PersonnelVA())));
/


---------------------------------------------------------------------------------------------------------------------


-- OPERATIONS OF ORDERS

-- TRIGGER: update_order_not_arrived

-- Check that I cannot put a feedback on a non arrived order
-- Should fail
UPDATE Orders SET feedback = FeedbackTY(4,'ppp',SYSDATE) where code=1;
/


-- TRIGGER: update_feedback_score

-- Check if when we set a feedback, the team's feedback score is updated automatically
UPDATE Orders SET feedback = FeedbackTY(4,'ppp',SYSDATE), status = 'arrived' where code=2;  -- order 2 is already assigned to a team
-- we set also status to arrived because otherwise we cannot insert the feedback
/
-- The feedback score should of the team be updated
SELECT t.score.feedback_score FROM team t where REF(t) = (SELECT team_ref FROM Orders WHERE code=2);
/



-- TRIGGER: set_order_shipped / update_num_orders_in_team / set_order_date

-- OPERATION 3 (assign a team to an order)
-- Check if when an order is assigned to a team, its status become "shipped" and the number of orders in the updated team is updated
-- Should work (note that operational center province and destionation address province are in this case equals to 'province')

-- Get the current number of orders of team with code 3
SELECT num_orders FROM Team WHERE code=3;
/

DECLARE
team_r REF TeamTY;
BEGIN
-- Get the ref of the team with code 3
SELECT REF(t) INTO team_r FROM Team t WHERE t.code=3;

-- Assign the team to the order
UPDATE Orders o SET o.team_ref = team_r where o.code=1;
COMMIT;
END;
/

-- The status should be updated to 'shipped', the order should be assigned to the team and its shipping date should be set
SELECT * FROM Orders WHERE code=1;
/
-- Check that the number of orders in the assigned team has been incremented
SELECT num_orders FROM Team WHERE code=3;
/




-- Try to assign to an order a team that works for an operational center of which province is different from the one of the destination address of the order
-- Should fail
DECLARE
personnels_va PersonnelVA := PersonnelVA();
account_ref REF AccountTY;
team_r REF TeamTY;
BEGIN
personnels_va.extend;

-- Get a personnel ref, that works for the province 'province'
SELECT p.column_value INTO personnels_va(1) FROM OperationalCenter o, TABLE(o.personnels) p WHERE o.address.province = 'province' and ROWNUM = 1;

-- Create a team with that personnel as member
INSERT INTO Team VALUES(TeamTY(110,'pp',0,(ScoreTY(0,0)),personnels_va));

-- Get the team ref and a ref of a random account
SELECT REF(t) INTO team_r FROM Team t WHERE t.code=110;
SELECT REF(a) INTO account_ref FROM Accounts a WHERE a.code=1;

-- Create an order with destination address in province 'Taranto'
INSERT INTO Orders VALUES (OrderTY(1000,'bulk','placed','phone',0,(DateTY(SYSDATE,null,null)),(AddressTY('pp','pp','Taranto','ppp')),null,account_ref,null));

-- Assign the team to the order
-- Should fail
UPDATE Orders o SET o.team_ref = team_r WHERE o.code=1000;

COMMIT;
END;
/


-- TRIGGER: update_delivery_score / set_order_date

-- Check if when we set an order to arrived, the delivery score of the team is updated and its arrival date is set
-- Disable the trigger termporarly to allow the modification of the date
ALTER TRIGGER prevent_order_date_update DISABLE;
/

DECLARE
acc_ref REF AccountTY;
team_r REF TeamTY;
BEGIN
-- Update shipping date of an order to an old date
UPDATE Orders o SET o.or_date.shipping_date = TO_DATE('10-GEN-2025') WHERE code=1;

-- Update the state of the order to 'arrived'
UPDATE Orders SET status = 'arrived' where code=1;
END;
/

-- The delivery score should be updated
SELECT t.score.delivery_score FROM team t where code=3;
/

-- The arrival date should be set
SELECT o.or_date.arrival_date FROM Orders o WHERE o.code=1;
/

-- Enable again the trigger
ALTER TRIGGER prevent_order_date_update ENABLE;
/



-- TRIGGER: update_num_orders_on_delete

-- Check if when an order is deleted, then the number of orders into its team (if there is one) is decremented
DELETE FROM Orders o WHERE o.code=1;
/

-- The number of orders of the team whould be decremented
SELECT num_orders FROM Team WHERE code=3;
/



-- TRIGGER: prevent_order_date_update

-- Check that is not possible to update the arrival date of an order that is not in 'arrived' status
-- Should not work
UPDATE Orders o SET o.or_date.shipping_date = SYSDATE WHERE o.code=2;
/

-- Should not work
UPDATE Orders o SET o.or_date.arrival_date = SYSDATE WHERE o.code=2;
/




commit work;
/