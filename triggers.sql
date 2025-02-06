--TRIGGERS

-- trigger per eliminare gli account quando elimino un customer

-- trigger per eliminare il personnel quando un operational center viene eliminato ??????

-- trigger che quando inserisci un individual, controlla che sia maggiorenne

-- Trigger that checks that at least one account is provided at the moment of creation of a customer and that the provided account does not belong to another customer
-- FOR BUSINESS
CREATE OR REPLACE TRIGGER check_business_insert
BEFORE
INSERT ON Business
FOR EACH ROW
DECLARE
stolen_accounts_business INTEGER;
stolen_accounts_individual INTEGER;
possessed_accounts INTEGER;
BEGIN
    -- get number of possessed accounts by the inserted customer
    SELECT COUNT(*) INTO possessed_accounts FROM TABLE(:new.accounts);
    
    IF possessed_accounts=0 THEN
        RAISE_APPLICATION_ERROR( -20001, 'Provide at least one account for the insterted customer' );
    END IF;
    
    -- get the number of customers that have the same accounts of the inserted customer
    SELECT COUNT(*) INTO stolen_accounts_business FROM Business b, TABLE(b.accounts) a WHERE DEREF(a.column_value).code in (select DEREF(a1.column_value).code from TABLE(:new.accounts) a1) and b.piva!=:new.piva;
    
    SELECT COUNT(*) INTO stolen_accounts_individual FROM Individual i, TABLE(i.accounts) a WHERE DEREF(a.column_value).code in (select DEREF(a1.column_value).code from TABLE(:new.accounts) a1);
    
    IF stolen_accounts_business >0 OR stolen_accounts_individual>0 THEN
         RAISE_APPLICATION_ERROR( -20001, 'Cannot use an account owned by another customer' );
    END IF;
    
END;
/

-- Trigger that checks that at least one account is provided at the moment of creation of a customer and that the provided account does not belong to another customer
-- FOR INDIVISUALS
CREATE OR REPLACE TRIGGER check_individual_insert
BEFORE
INSERT ON Individual
FOR EACH ROW
DECLARE
stolen_accounts_individual INTEGER;
stolen_accounts_business INTEGER;
possessed_accounts INTEGER;
BEGIN
    -- get number of possessed accounts by the inserted customer
    SELECT COUNT(*) INTO possessed_accounts FROM TABLE(:new.accounts);
    
    IF possessed_accounts=0 THEN
        RAISE_APPLICATION_ERROR( -20001, 'Provide at least one account for the insterted customer' );
    END IF;
    
    -- get the number of customers that have the same accounts of the inserted customer
    SELECT COUNT(*) INTO stolen_accounts_individual FROM Individual i, TABLE(i.accounts) a WHERE DEREF(a.column_value).code in (select deref(a1.column_value).code from TABLE(:new.accounts) a1) and i.fc!=:new.fc;
    
    SELECT COUNT(*) INTO stolen_accounts_business FROM Business b, TABLE(b.accounts) a WHERE DEREF(a.column_value).code in (select DEREF(a1.column_value).code from TABLE(:new.accounts) a1);
    
    IF stolen_accounts_individual>0 OR stolen_accounts_business>0 THEN
         RAISE_APPLICATION_ERROR( -20001, 'Cannot use an account owned by another customer' );
    END IF;
    
END;
/

-- FOR TEAM
-- Trigger that checks that:
-- - members of a team are of the same operational center
-- - a team has at least one member
-- - there are no duplicates in team's members
CREATE OR REPLACE TRIGGER check_team_members
AFTER
UPDATE OF members OR INSERT ON team
FOR EACH ROW
DECLARE
num_op_centers INTEGER;
BEGIN
    -- Check that the team has at least one member
    IF :new.members is null or :new.members.COUNT=0 THEN
        RAISE_APPLICATION_ERROR( -20001, 'Cannot have a team without members' );
    END IF;
    
    -- Get the number of different operational centers for which memebrs of the team works
    SELECT COUNT(*) INTO num_op_centers FROM (SELECT DISTINCT o.code FROM OperationalCenter o, TABLE(o.personnels) p WHERE p.column_value in (SELECT COLUMN_VALUE FROM TABLE(:new.members)));
    
    -- check that all members of the team come from the same operational center    
    IF num_op_centers>1 THEN
        RAISE_APPLICATION_ERROR( -20001, 'Not all members of a team comes from the same operational center' );
    END IF;
    
    -- check that there are no duplicates in the members of the team
    FOR i IN 1..:new.members.COUNT LOOP
        FOR j IN 1..:new.members.COUNT LOOP
            IF :new.members(i)=:new.members(j) AND i!=j THEN
                RAISE_APPLICATION_ERROR( -20001, 'Cannot insert duplicated members in the team' );
            END IF;
        END LOOP;
    END LOOP;
END;
/


-- FOR ORDERS
-- trigger that do not let insert a feedback if the order status is not 'arrived'
CREATE OR REPLACE TRIGGER update_order_not_arrived
BEFORE
UPDATE OF feedback ON Orders
FOR EACH ROW
BEGIN
    IF :new.status != 'arrived' THEN
        RAISE_APPLICATION_ERROR( -20001, 'Cannot insert a feedback of a non arrived order' );
    END IF;
END;
/

-- trigger that updates the feedback score of the team when a feedback is inserted into the order
CREATE OR REPLACE TRIGGER update_feedback_score
AFTER
UPDATE OF feedback ON Orders
FOR EACH ROW
DECLARE
new_score DECIMAL(2,1);
current_score DECIMAL(2,1);
BEGIN
    -- get number of feedbacks for orders made by the team of the modified order
    -- SELECT COUNT(*) INTO num_feedbacks_of_team FROM orders o WHERE o.team_ref=:new.team_ref and o.feedback is not null;
    
    -- get current team feedback score
    SELECT t.score.feedback_score INTO current_score FROM team t WHERE REF(t)=:new.team_ref;
    
    IF current_score = 0 THEN
        -- set feedback score to the score of the inserted feedback
        new_score := :new.feedback.score;
    ELSE
        -- new_score := (current_score*num_feedbacks_of_team + :new.feedback.score)/(num_feedbacks_of_team+1);
        new_score := 0.5*:new.feedback.score + 0.5*current_score;
    END IF;
    
    -- update the score
    UPDATE Team t SET t.score.feedback_score = new_score where REF(t)=:new.team_ref;
END;
/


-- trigger that set the state of an order to "shipped" when it is assigned to a team, and set the shipping date to now
-- also do not allow to assign to the order a team that works for an operational center in a province different from the one of the destination address
CREATE OR REPLACE TRIGGER set_order_shipped
BEFORE
INSERT OR UPDATE OF team_ref ON Orders
FOR EACH ROW
DECLARE
operationalCenterProvince VARCHAR(20);
BEGIN
    -- Do not let update the team of an order, if its status is arrived, since it has already an assigned team
    IF :new.status='arrived' THEN
        RAISE_APPLICATION_ERROR( -20001, 'Cannot change the team of an arrived order' );
    END IF;
    
    -- if the new team is not null
    IF :new.team_ref is not null THEN
        
        -- Get the province of the operational center for which the team works
        SELECT DISTINCT o.address.province INTO operationalCenterProvince FROM OperationalCenter o, TABLE(o.personnels) p, team t, TABLE(t.members) m WHERE m.column_value = p.column_value;
        
        -- Check if the team works for an operational center in the same province of the one of the destination address of the order
        IF operationalCenterProvince != :new.destination_address.province THEN
            RAISE_APPLICATION_ERROR( -20001, 'Cannot assign an order to a team that works for an operatioal center in a different province than the province of the destination address of the order' );
        END IF;
        
        -- Update the status of the order to shipped, before the update is performed
        :new.status := 'shipped';
        
        -- Set the shipping date to now
        :new.or_date.shipping_date := SYSDATE;
    END IF;
END;
/

-- trigger that increment the number of orders in the team when an order is assigned to it
-- and derement the number of orders to the team that was previusly assigned to the order (if there is some)
CREATE OR REPLACE TRIGGER update_num_orders_in_team
AFTER
INSERT OR UPDATE OF team_ref ON Orders
FOR EACH ROW
DECLARE
BEGIN
    -- Increment the number of orders in the new team related to the order
    IF :new.team_ref is not null THEN
        UPDATE Team t SET t.num_orders = t.num_orders + 1 WHERE REF(t)=:new.team_ref;
    END IF;
    
    -- Decrement the number of orders in the old team that was related to the order (if there was some)
    IF :old.team_ref is not null THEN
        UPDATE Team t SET t.num_orders = t.num_orders - 1 WHERE REF(t)=:old.team_ref;
    END IF;
END;
/

-- trigger that set the arrival date when its status changes to arrived and set the shipping date when teh status changes to shipped
CREATE OR REPLACE TRIGGER set_order_date
BEFORE
UPDATE OF status ON Orders
FOR EACH ROW
BEGIN
    IF :new.status='placed' and :old.status!='placed' THEN
        RAISE_APPLICATION_ERROR( -20001, 'Cannot change the status of an order again to placed' );
    END IF;
    
    IF :new.status='shipped' THEN
        -- Set the shipping date to now
        :new.or_date.shipping_date := SYSDATE;
    END IF;
    
    IF :new.status='arrived' THEN
        -- Set the arrival date to now
        :new.or_date.arrival_date := SYSDATE;
    END IF;
END;
/

-- trigger to update the delivery score of a team, when an order related to it turns to status of arrive
CREATE OR REPLACE TRIGGER update_delivery_score
AFTER
UPDATE OF status ON Orders
FOR EACH ROW
DECLARE
new_score DECIMAL(3,1);
current_score DECIMAL(3,1);
delivery_time DECIMAL(3,1);
BEGIN
    -- If the status has changed to arrived, update the score of the team
    IF :new.status = 'arrived' and :old.status = 'shipped' THEN
        -- get current team delivery score
        SELECT t.score.delivery_score INTO current_score FROM team t WHERE REF(t)=:new.team_ref;
        
        -- calculate the delivery time of the order as difference between arrival and shipping date in days
        delivery_time := TRUNC(:new.or_date.arrival_date) - TRUNC(:new.or_date.shipping_date);
        
        -- if the score is 0, the new score is the delivery time of the order
        IF current_score = 0 THEN
            -- set delivery score to the delivery time
            new_score := delivery_time;
        ELSE
            -- new_score := (current_score*num_feedbacks_of_team + :new.feedback.score)/(num_feedbacks_of_team+1);
            new_score := 0.5*delivery_time + 0.5*current_score;
        END IF;
        
        -- update the score
        UPDATE Team t SET t.score.delivery_score = new_score where REF(t)=:new.team_ref;
    END IF;
END;
/


-- trigger that does not allows to update placement, shipping and arrival date
CREATE OR REPLACE TRIGGER prevent_order_date_update
BEFORE
UPDATE OF or_date ON Orders
FOR EACH ROW
BEGIN
    -- If placement date is going to be modified, do not allow the modification
    IF :new.or_date.placement_date != :old.or_date.placement_date THEN
        RAISE_APPLICATION_ERROR( -20001, 'Cannot change the placement date' );
    END IF;
    
    -- If shipping date is going to be modified, do not allow the modification, also
    -- Do not allow modification of shipping data if it is not in shipped status
    IF (:new.or_date.shipping_date != :old.or_date.shipping_date or (:new.or_date.shipping_date is not null and :old.or_date.shipping_date is null)) and (:new.status!='shipped' or :old.or_date.shipping_date is not null) THEN
        RAISE_APPLICATION_ERROR( -20001, 'Cannot change the shipping date' );
    END IF;
    
    -- If arrival date is going to be modified, do not allow the modification, also
     -- Do not allow modification of arrival data if it is not in arrived status
    IF (:new.or_date.arrival_date != :old.or_date.arrival_date) and (:new.status!='arrived' or :old.or_date.arrival_date is not null) THEN
        RAISE_APPLICATION_ERROR( -20001, 'Cannot change the arrival date' );
    END IF;
END;
/



-- DELETE TRIGGERS

-- trigger to decrement the number of orders to the team assigned to an order that has been deleted
CREATE OR REPLACE TRIGGER update_num_orders_on_delete
AFTER
DELETE ON Orders
FOR EACH ROW
BEGIN
    IF :old.team_ref is not null THEN
        -- Decrement the number of orders of the team of the deleted order
        UPDATE Team t SET t.num_orders = t.num_orders - 1 WHERE REF(t)=:old.team_ref;
    END IF;
END;
/