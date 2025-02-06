-- PROCEDURES TO POPULATE TABLES
CREATE OR REPLACE TYPE StringList AS VARRAY(10) OF VARCHAR(10);
/

CREATE OR REPLACE TYPE StringListBig AS VARRAY(100) OF VARCHAR(20);
/

CREATE OR REPLACE FUNCTION check_ele_in_varray(arr in StringListBig, ele in VARCHAR)
RETURN Boolean IS
found BOOLEAN;
BEGIN
    found := false;
    FOR i IN 1..arr.COUNT LOOP
        IF arr(i) = ele THEN
            found := true;
        END IF;
    END LOOP;
    RETURN found;
END;
/

create or replace function RandomString(p_Characters varchar2, p_length number)
return varchar2
is
l_res varchar2(256);
begin
select substr(listagg(substr(p_Characters, level, 1)) within group(order by dbms_random.value), 1, p_length)
into l_res
from dual
connect by level <= length(p_Characters);
return l_res;
end;
/

CREATE OR REPLACE FUNCTION GenerateRandomPIVA RETURN VARCHAR2 IS
    random_piva VARCHAR2(11);
BEGIN
    -- Generate a random 11-digit PIVA
    random_piva := LPAD(TRUNC(DBMS_RANDOM.VALUE(0, 99999999999)), 11, '0');
    RETURN random_piva;
END GenerateRandomPIVA;
/

CREATE OR REPLACE FUNCTION GenerateRandomFC 
RETURN VARCHAR IS
    l_random_string VARCHAR(16); -- String to store the generated random string
BEGIN
    -- Use DBMS_RANDOM to generate a random string of the given length
    FOR i IN 1..16 LOOP
        l_random_string := l_random_string || CHR(TRUNC(DBMS_RANDOM.VALUE(65, 91))); -- ASCII values between 65 and 90 (A-Z)
    END LOOP;
    
    RETURN l_random_string;
END GenerateRandomFC;
/

-- Insert customers and accounts
CREATE OR REPLACE PROCEDURE InsertCustomers IS
    first_names StringList := StringList('John', 'Jane', 'Alice', 'Bob', 'Carol', 'David', 'Eva', 'Frank');
    last_names  StringList := StringList('Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis');
    denominations StringList := StringList('ab','aa','bb','ba','ab','cc');
    passwords StringList := StringList('aa','bb','ba','ab');
    random_first_name VARCHAR(100);
    random_last_name VARCHAR(100);
    random_denomination VARCHAR(3);
    random_email VARCHAR(10);
    random_passw VARCHAR(10);
    random_date DATE;
    PIVA VARCHAR(11);
    PIVAS StringListBig := StringListBig();
    FC VARCHAR(16);
    FCS StringListBig := StringListBig();
    random_account REF AccountTY;
    
    BEGIN
    PIVAS.extend(100);
    FCS.extend(100);
    FOR i IN 1..100 LOOP
        -- Select a random first name
        random_first_name := first_names(TRUNC(DBMS_RANDOM.VALUE(1, first_names.COUNT + 1)));
        -- Select a random last name
        random_last_name := last_names(TRUNC(DBMS_RANDOM.VALUE(1, last_names.COUNT + 1)));
        -- Select random denomination
        random_denomination := denominations(TRUNC(DBMS_RANDOM.VALUE(1, denominations.COUNT + 1)));
        -- Select a random PIVA, that has never been met
        PIVA := GenerateRandomPIVA();
        WHILE check_ele_in_varray(PIVAS,PIVA) LOOP
            PIVA := GenerateRandomPIVA();
        END LOOP;
        PIVAS(i) := PIVA;
        -- Select a random FC, tha has neved been met
        FC := GenerateRandomFC();
        WHILE check_ele_in_varray(FCS,FC) LOOP
            FC := GenerateRandomFC();
        END LOOP;
        FCS(i) := FC;
        
        -- Select random email
        random_email := RandomString('abcdefghijklmnopqrstuvwxyz',10);
        --Select random passw
        random_passw := passwords(TRUNC(DBMS_RANDOM.VALUE(1, passwords.COUNT + 1)));
        -- Select random date
        random_date := DATE '1960-01-01' + TRUNC(DBMS_RANDOM.VALUE(0, 16700));
       
        -- Insert an account
        INSERT INTO Accounts VALUES(AccountTY(i, random_date, random_email, random_passw));
        
        -- Get inserted account ref
        SELECT REF(A) INTO random_account FROM Accounts a where code=i;
        
        -- Insert business
        INSERT INTO Business VALUES(
            BusinessTY(random_date,TRUNC(DBMS_RANDOM.VALUE(6000000000, 9999999999)),
                (AccountsNT(
                    random_account
                )),
                PIVA,random_denomination
            )
        );
        
        -- Select random email
        random_email := RandomString('abcdefghijklmnopqrstuvwxyz',10);
        -- Insert an account
        INSERT INTO Accounts VALUES(AccountTY(i+100, random_date, random_email, random_passw));
        -- Get inserted account
        SELECT REF(A) INTO random_account FROM Accounts a where code=i+100;

        -- Insert Individual
        INSERT INTO Individual VALUES(
            IndividualTY(random_date,TRUNC(DBMS_RANDOM.VALUE(6000000000, 9999999999)),
                (AccountsNT(
                    random_account
                )),
                FC,random_first_name,random_last_name
            )
        );
    END LOOP;

    COMMIT;
    
END InsertCustomers;
/

-- Insert operational centers
CREATE OR REPLACE PROCEDURE InsertOperationalCenters IS
    first_names StringList := StringList('John', 'Jane', 'Alice', 'Bob', 'Carol', 'David', 'Eva', 'Frank');
    last_names  StringList := StringList('Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis');
    denominations StringList := StringList('ab','aa','bb','ba','ab','cc');
    random_denomination VARCHAR(3);
    random_personnel REF PersonnelTY;
    random_personnels PersonnelVA := PersonnelVA();
    random_first_name VARCHAR(10);
    random_last_name VARCHAR(10);
    random_province VARCHAR(10) := 'province';
    
    i INTEGER := 0;
    
    BEGIN
    
    random_personnels.extend(5);
    
    WHILE i<100 LOOP
        -- Select a random first name
        random_first_name := first_names(TRUNC(DBMS_RANDOM.VALUE(1, first_names.COUNT + 1)));
        -- Select a random last name
        random_last_name := last_names(TRUNC(DBMS_RANDOM.VALUE(1, last_names.COUNT + 1)));
        -- Select random denomination
        random_denomination := denominations(TRUNC(DBMS_RANDOM.VALUE(1, denominations.COUNT + 1)));
       
        FOR k IN 1..5 LOOP
            -- Insert a personnel
            INSERT INTO Personnel VALUES(PersonnelTY(i+k, random_first_name, random_last_name));
            
            -- Get inserted personnel ref
            SELECT REF(p) INTO random_personnel FROM Personnel p where id=i+k;
            
            random_personnels(k) := random_personnel;
        END LOOP;
            
        -- Insert Operational center
        INSERT INTO OperationalCenter VALUES(
            OperationalCenterTY(i,random_denomination,(AddressTY(random_denomination,random_denomination,random_province,random_denomination)),
                (PersonnelNT(
                    random_personnel
                ))
            )
        );
        
        i := i+5;
        
    END LOOP;

    COMMIT;
    
END InsertOperationalCenters;
/

-- Insert teams
CREATE OR REPLACE PROCEDURE InsertTeams IS
    denominations StringList := StringList('ab','aa','bb','ba','ab','cc');
    random_denomination VARCHAR(3);
    personnels PersonnelVA := PersonnelVA();
    personnel_single REF PersonnelTY;
    
    i INTEGER := 0;
    
    BEGIN
    
    personnels.extend(8);
    
    WHILE i<50 LOOP
        -- Select random denomination
        random_denomination := denominations(TRUNC(DBMS_RANDOM.VALUE(1, denominations.COUNT + 1)));
        
        -- Get 5 personnels
        FOR k IN 1..5 LOOP
            SELECT REF(p) into personnel_single FROM Personnel p where p.id=i+k;
            
            personnels(k) := personnel_single;
        END LOOP;
        
        -- Insert Team
        INSERT INTO Team VALUES(
            TeamTY(i,random_denomination,0,(ScoreTY(0,0)),personnels)
        );
        
        i := i+1;
        
    END LOOP;

    COMMIT;
    
END InsertTeams;
/

-- Insert orders
CREATE OR REPLACE PROCEDURE InsertOrders IS
    or_type StringList := StringList('bulk','urgent','regular');
    or_status VARCHAR(10) := 'placed';
    placement StringList := StringList('phone','email','website');
    random_type VARCHAR(10);
    random_status VARCHAR(10);
    random_placement VARCHAR(10);
    random_cost DECIMAL(4,2);
    random_date DATE;
    random_address AddressTY;
    random_feedback FeedbackTY;
    random_account REF AccountTY;
    random_team REF TeamTY;
    random_province VARCHAR(20) := 'province';
    
    BEGIN
    
    FOR i IN 1..500 LOOP
        random_type := or_type(TRUNC(DBMS_RANDOM.VALUE(1, or_type.COUNT + 1)));
        random_placement := placement(TRUNC(DBMS_RANDOM.VALUE(1, placement.COUNT + 1)));
        random_cost := TRUNC(DBMS_RANDOM.VALUE(1, 100));
        random_date := DATE '1960-01-01' + TRUNC(DBMS_RANDOM.VALUE(0, 16700));
        random_address := AddressTY(random_type,random_type,random_province,random_type);
        random_feedback := null;
        
        SELECT REF(a) INTO random_account FROM Accounts a WHERE a.code=TRUNC(DBMS_RANDOM.VALUE(1, 200));
        SELECT REF(t) INTO random_team FROM Team t WHERE t.code=TRUNC(DBMS_RANDOM.VALUE(1, 50));
        
        -- Set team to null if i is odd
        IF Mod(i,2)!=0 THEN
            random_team := null;
        END IF;
        
        -- Insert Order
        INSERT INTO Orders VALUES(
            OrderTY(i,random_type,or_status,random_placement,random_cost,(DateTY(random_date,null,null)),random_address,random_feedback,random_account,random_team)
        );
        
    END LOOP;

    COMMIT;
    
END InsertOrders;
/

--Insert all tuples
execute InsertCustomers;
/

execute InsertOperationalCenters;
/

execute InsertTeams;
/

execute InsertOrders;
/