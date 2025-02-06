-- DEFINE TYPES -------------------------------------------------------------------

-- Define types that have not a table
CREATE OR REPLACE TYPE AddressTY AS OBJECT (
    route VARCHAR2(20),
    city VARCHAR2(20),
    province VARCHAR2(20),
    region VARCHAR(20)
);
/

CREATE OR REPLACE TYPE FeedbackTY AS OBJECT (
    score INTEGER,
    fb_descritpion VARCHAR(50),  --optional
    fb_date TIMESTAMP
);
/

CREATE OR REPLACE TYPE DateTY AS OBJECT (
    placement_date TIMESTAMP,
    shipping_date TIMESTAMP,
    arrival_date TIMESTAMP
);
/

CREATE OR REPLACE TYPE ScoreTY AS OBJECT (
    feedback_score DECIMAL(2,1),
    delivery_score DECIMAL(3,1)
);
/

-- DEFINE TYPES

--ACCOUNT
CREATE OR REPLACE TYPE AccountTY AS OBJECT (
    code INTEGER,
    date_of_creation DATE,
    email VARCHAR(20),
    acc_password VARCHAR(20)
) FINAL;
/

CREATE OR REPLACE TYPE AccountsNT AS TABLE OF REF AccountTY;
/

--CUSTOMER
CREATE OR REPLACE TYPE CustomerTY AS OBJECT (
    date_of_birth DATE,
    phone_number INTEGER,
    accounts AccountsNT  --composition between Account and Customer
) NOT FINAL NOT INSTANTIABLE;   --cannot instantiate a customer. Need to instantiare Business or individual
/

CREATE OR REPLACE TYPE BusinessTY UNDER CustomerTY (
    PIVA VARCHAR(11),
    denomination VARCHAR(20)
) FINAL;
/

CREATE OR REPLACE TYPE IndividualTY UNDER CustomerTY (
    FC VARCHAR(16),
    name VARCHAR2(15),
    surname VARCHAR2(15)
) FINAL;
/

--PERSONNEL
CREATE OR REPLACE TYPE PersonnelTY AS OBJECT (
    ID INTEGER,
    name VARCHAR(15),
    surname VARCHAR(15)
) FINAL;
/

CREATE OR REPLACE TYPE PersonnelNT AS TABLE OF REF PersonnelTY;
/

CREATE OR REPLACE TYPE PersonnelVA AS VARRAY(8) OF REF PersonnelTY;  --using a VARRAY with maximum number equals to 8
--allows us to implicitly implement the constraint that a team can have at most 8 members
/

--OPERATIONAL CENTER
CREATE OR REPLACE TYPE OperationalCenterTY AS OBJECT (
    code INTEGER,
    name VARCHAR(20),
    Address AddressTY,
    personnels PersonnelNT  --composition between Center and Personnel
) FINAL;
/

--TEAM
CREATE OR REPLACE TYPE TeamTY AS OBJECT (
    code INTEGER,
    name VARCHAR(15),
    num_orders INTEGER,
    score ScoreTY,
    members PersonnelVA  --aggregation beetwen Team and Personnel. Maximum 8 members
) FINAL;
/

--ORDER
CREATE OR REPLACE TYPE OrderTY AS OBJECT (
    code INTEGER,
    or_type VARCHAR(10),
    status VARCHAR(10),
    placement_type VARCHAR(10),
    or_cost DECIMAL(4,2),
    or_date DateTY,
    destination_address AddressTY,
    feedback FeedbackTY,
    
    account_ref REF AccountTY ,  --aggregation between Order and Account
    team_ref REF TeamTY  --aggregation between Order and Team
) FINAL;
/



-- DEFINE TABLES --------------------------------------------------------------------------------------------
CREATE TABLE Accounts OF AccountTY(
    date_of_creation DEFAULT TO_DATE(SYSDATE, 'DD-MM-YYYY'),
    email NOT NULL,
    acc_password NOT NULL,
    
    PRIMARY KEY(code),
    UNIQUE(email)
);
/

CREATE TABLE Business OF BusinessTY(
    denomination NOT NULL,
    
    PRIMARY KEY(PIVA)
)NESTED TABLE accounts STORE AS Accounts_business_NT_TAB; 
/

ALTER TABLE Accounts_business_NT_TAB
    ADD SCOPE FOR (COLUMN_VALUE) IS Accounts;
/

CREATE TABLE Individual OF IndividualTY(
    name NOT NULL,
    surname NOT NULL,
    
    PRIMARY KEY(FC)
)NESTED TABLE accounts STORE AS Accounts_individual_NT_TAB;
/

ALTER TABLE Accounts_individual_NT_TAB
    ADD SCOPE FOR (COLUMN_VALUE) IS Accounts;
/

CREATE TABLE Team OF TeamTY(
    num_orders DEFAULT 0,
    score DEFAULT ScoreTY(0,0),
    members NOT NULL,
    
    PRIMARY KEY(code)
);
/

CREATE TABLE Personnel OF PersonnelTY(
    name NOT NULL,
    surname NOT NULL,
    
    PRIMARY KEY(ID)
);
/

CREATE TABLE OperationalCenter OF OperationalCenterTY(
    PRIMARY KEY(code)
)NESTED TABLE personnels STORE AS Personnel_NT; 
/

ALTER TABLE Personnel_NT
    ADD SCOPE FOR (COLUMN_VALUE) IS Personnel;
/

CREATE TABLE Orders OF OrderTY(
    or_type CHECK( or_type IN ('regular','urgent','bulk') ),  --we use the check to implement the enum
    status CHECK( status IN ('placed','shipped','arrived') ),  --we use the check to implement the enum
    placement_type CHECK( placement_type IN ('phone','email','website') ),  --we use the check to implement the enum
    or_cost DEFAULT 0 NOT NULL,
    destination_address NOT NULL,
    feedback  
        DEFAULT FeedbackTY(1,'.',TO_DATE (SYSDATE, 'DD-MM-YYYY'))
        CHECK (feedback.score BETWEEN 1 AND 5),   --check that the score is between 1 and 5
        
    or_date DEFAULT DateTY(TO_DATE (SYSDATE, 'DD-MM-YYYY'),null,null),
         
    account_ref SCOPE IS Accounts NOT NULL,  --aggregation between Order and Account
    team_ref SCOPE IS Team, --aggregation between Order and Team. Can be optional
    
    PRIMARY KEY(code)
);
/