-- Basic SQL DDL generated from Mermaid Diagram
-- NOTE: Data types, column names (beyond keys), and constraints are placeholders or inferred.
--       Refine this schema in your ERD tool (e.g., DbSchema).

-- Sales Module Entities
CREATE TABLE ARCUST (
    CCUST VARCHAR(50) PRIMARY KEY, -- Key from note
    column1 VARCHAR(100) -- Placeholder for other columns
    -- Add other ARCUST columns here
);

CREATE TABLE OEOPNORD (
    OOORDR INT PRIMARY KEY, -- Assumed PK, replace if needed
    OOCUST VARCHAR(50), -- Key from note
    SALESMAN_ID INT, -- Inferred FK from relationship
    entered_by_employee_id INT, -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other OEOPNORD columns here
    FOREIGN KEY (OOCUST) REFERENCES ARCUST(CCUST) -- Constraint from note
    -- FOREIGN KEY (SALESMAN_ID) REFERENCES SALESMAN(salesman_pk), -- Add FK to SALESMAN table
    -- FOREIGN KEY (entered_by_employee_id) REFERENCES EMPLOYE(employee_pk) -- Add FK to EMPLOYE table
);

CREATE TABLE SHIPADR (
    SHIPADR_ID INT PRIMARY KEY, -- Generic PK
    CCUST VARCHAR(50), -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other SHIPADR columns here
    FOREIGN KEY (CCUST) REFERENCES ARCUST(CCUST) -- Inferred FK relationship
);

CREATE TABLE CRHEADER (
    CRHEADER_ID INT PRIMARY KEY, -- Generic PK
    CCUST VARCHAR(50), -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other CRHEADER columns here
    FOREIGN KEY (CCUST) REFERENCES ARCUST(CCUST) -- Inferred FK relationship
);

CREATE TABLE OEDETAIL (
    OEDETAIL_ID INT PRIMARY KEY, -- Generic PK
    OOORDR INT, -- Inferred FK from relationship
    ODITEM VARCHAR(50), -- Key from note (assuming this name)
    SLSDSCOV_ID INT, -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other OEDETAIL columns here
    FOREIGN KEY (OOORDR) REFERENCES OEOPNORD(OOORDR), -- Inferred FK relationship
    FOREIGN KEY (ODITEM) REFERENCES ITEMMAST(IMITEM) -- Constraint from note
    -- FOREIGN KEY (SLSDSCOV_ID) REFERENCES SLSDSCOV(slsdscov_pk) -- Add FK to SLSDSCOV table
);

CREATE TABLE OEPROFIL (
    OEPROFIL_ID INT PRIMARY KEY, -- Generic PK
    OOORDR INT, -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other OEPROFIL columns here
    FOREIGN KEY (OOORDR) REFERENCES OEOPNORD(OOORDR) -- Inferred FK relationship
);

CREATE TABLE SLSDSCOV (
    SLSDSCOV_ID INT PRIMARY KEY -- Generic PK (Referenced by OEDETAIL)
    -- Add other SLSDSCOV columns here
);

CREATE TABLE SALESMAN (
    SALESMAN_ID INT PRIMARY KEY -- Generic PK (Referenced by OEOPNORD)
    -- Add other SALESMAN columns here
);

CREATE TABLE SHIPMAST (
    SHIPMAST_ID INT PRIMARY KEY, -- Generic PK
    OOORDR INT, -- Inferred FK from relationship
    SHIPADR_ID INT, -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other SHIPMAST columns here
    FOREIGN KEY (OOORDR) REFERENCES OEOPNORD(OOORDR), -- Inferred FK relationship
    FOREIGN KEY (SHIPADR_ID) REFERENCES SHIPADR(SHIPADR_ID) -- Inferred FK relationship
);

CREATE TABLE CRDETAIL (
    CRDETAIL_ID INT PRIMARY KEY, -- Generic PK
    CRHEADER_ID INT, -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other CRDETAIL columns here
    FOREIGN KEY (CRHEADER_ID) REFERENCES CRHEADER(CRHEADER_ID) -- Inferred FK relationship
);

CREATE TABLE ORDTRCK (
    ORDTRCK_ID INT PRIMARY KEY, -- Generic PK
    OOORDR INT, -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other ORDTRCK columns here
    FOREIGN KEY (OOORDR) REFERENCES OEOPNORD(OOORDR) -- Inferred FK relationship
);

CREATE TABLE OEHISTRY (
    OEHISTRY_ID INT PRIMARY KEY, -- Generic PK
    OOORDR INT, -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other OEHISTRY columns here
    FOREIGN KEY (OOORDR) REFERENCES OEOPNORD(OOORDR) -- Inferred FK relationship
);

CREATE TABLE OEHISTRD (
    OEHISTRD_ID INT PRIMARY KEY, -- Generic PK
    OEHISTRY_ID INT, -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other OEHISTRD columns here
    FOREIGN KEY (OEHISTRY_ID) REFERENCES OEHISTRY(OEHISTRY_ID) -- Inferred FK relationship
);

-- Inventory Module Entities
CREATE TABLE ITEMMAST (
    IMITEM VARCHAR(50) PRIMARY KEY, -- Key from note
    ITEMCLS3_ID INT, -- Inferred FK from relationship
    ITEMBG_ID INT, -- Inferred FK from relationship
    column1 VARCHAR(100) -- Placeholder for other columns
    -- Add other ITEMMAST columns here
    -- FOREIGN KEY (ITEMCLS3_ID) REFERENCES ITEMCLS3(itemcls3_pk), -- Add FK to ITEMCLS3 table
    -- FOREIGN KEY (ITEMBG_ID) REFERENCES ITEMBG(itembg_pk) -- Add FK to ITEMBG table
);

CREATE TABLE ITEMONHD (
    ITEMONHD_ID INT PRIMARY KEY, -- Generic PK
    IMITEM VARCHAR(50), -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other ITEMONHD columns here
    FOREIGN KEY (IMITEM) REFERENCES ITEMMAST(IMITEM) -- Inferred FK relationship
);

CREATE TABLE ITEMTAG (
    ITTAG VARCHAR(50) PRIMARY KEY, -- Key from note
    IMITEM VARCHAR(50), -- Inferred FK from relationship
    LISTHEAT_ID INT, -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other ITEMTAG columns here
    FOREIGN KEY (IMITEM) REFERENCES ITEMMAST(IMITEM) -- Inferred FK relationship
    -- FOREIGN KEY (LISTHEAT_ID) REFERENCES LISTHEAT(listheat_pk) -- Add FK to LISTHEAT table
);

CREATE TABLE ITEMHIST (
    ITEMHIST_ID INT PRIMARY KEY, -- Generic PK
    IMITEM VARCHAR(50), -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other ITEMHIST columns here
    FOREIGN KEY (IMITEM) REFERENCES ITEMMAST(IMITEM) -- Inferred FK relationship
);

CREATE TABLE ITEMCLS3 (
    ITEMCLS3_ID INT PRIMARY KEY -- Generic PK (Referenced by ITEMMAST)
    -- Add other ITEMCLS3 columns here
);

CREATE TABLE LISTHEAT (
    LISTHEAT_ID INT PRIMARY KEY -- Generic PK (Referenced by ITEMTAG)
    -- Add other LISTHEAT columns here
);

CREATE TABLE ITEMTUD (
    ITEMTUD_ID INT PRIMARY KEY, -- Generic PK
    ITTAG VARCHAR(50), -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other ITEMTUD columns here
    FOREIGN KEY (ITTAG) REFERENCES ITEMTAG(ITTAG) -- Inferred FK relationship
);

CREATE TABLE TAGLOCMV (
    TAGLOCMV_ID INT PRIMARY KEY, -- Generic PK
    ITTAG VARCHAR(50), -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other TAGLOCMV columns here
    FOREIGN KEY (ITTAG) REFERENCES ITEMTAG(ITTAG) -- Inferred FK relationship
);

CREATE TABLE ITEMTRIF (
    ITEMTRIF_ID INT PRIMARY KEY, -- Generic PK
    IMITEM VARCHAR(50), -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other ITEMTRIF columns here
    FOREIGN KEY (IMITEM) REFERENCES ITEMMAST(IMITEM) -- Inferred FK relationship
);

CREATE TABLE ITEMONCM (
    ITEMONCM_ID INT PRIMARY KEY, -- Generic PK
    ITEMONHD_ID INT, -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other ITEMONCM columns here
    FOREIGN KEY (ITEMONHD_ID) REFERENCES ITEMONHD(ITEMONHD_ID) -- Inferred FK relationship
);

CREATE TABLE ITEMBG (
    ITEMBG_ID INT PRIMARY KEY -- Generic PK (Referenced by ITEMMAST)
    -- Add other ITEMBG columns here
);


-- Purchasing Module Entities
CREATE TABLE APVEND (
    VVNDR VARCHAR(50) PRIMARY KEY, -- Key from note
    column1 VARCHAR(100) -- Placeholder for other columns
    -- Add other APVEND columns here
);

CREATE TABLE POHEADER (
    POHEADER_ID INT PRIMARY KEY, -- Generic PK
    BDVNDR VARCHAR(50), -- Key from note
    column1 VARCHAR(100), -- Placeholder
    -- Add other POHEADER columns here
    FOREIGN KEY (BDVNDR) REFERENCES APVEND(VVNDR) -- Constraint from note
);

CREATE TABLE VENDSHIP (
    VENDSHIP_ID INT PRIMARY KEY, -- Generic PK
    VVNDR VARCHAR(50), -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other VENDSHIP columns here
    FOREIGN KEY (VVNDR) REFERENCES APVEND(VVNDR) -- Inferred FK relationship
);

CREATE TABLE VENDREMT (
    VENDREMT_ID INT PRIMARY KEY, -- Generic PK
    VVNDR VARCHAR(50), -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other VENDREMT columns here
    FOREIGN KEY (VVNDR) REFERENCES APVEND(VVNDR) -- Inferred FK relationship
);

CREATE TABLE PODETAIL (
    PODETAIL_ID INT PRIMARY KEY, -- Generic PK
    POHEADER_ID INT, -- Inferred FK from relationship
    BDITEM VARCHAR(50), -- Key from note
    column1 VARCHAR(100), -- Placeholder
    -- Add other PODETAIL columns here
    FOREIGN KEY (POHEADER_ID) REFERENCES POHEADER(POHEADER_ID), -- Inferred FK relationship
    FOREIGN KEY (BDITEM) REFERENCES ITEMMAST(IMITEM) -- Constraint from note
);

CREATE TABLE POCHGLOG (
    POCHGLOG_ID INT PRIMARY KEY, -- Generic PK
    POHEADER_ID INT, -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other POCHGLOG columns here
    FOREIGN KEY (POHEADER_ID) REFERENCES POHEADER(POHEADER_ID) -- Inferred FK relationship
);

CREATE TABLE RCPTHIST (
    RCPTHIST_ID INT PRIMARY KEY, -- Generic PK
    PODETAIL_ID INT, -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other RCPTHIST columns here
    FOREIGN KEY (PODETAIL_ID) REFERENCES PODETAIL(PODETAIL_ID) -- Inferred FK relationship
);

CREATE TABLE RCPTCOST (
    RCPTCOST_ID INT PRIMARY KEY, -- Generic PK
    PODETAIL_ID INT, -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other RCPTCOST columns here
    FOREIGN KEY (PODETAIL_ID) REFERENCES PODETAIL(PODETAIL_ID) -- Inferred FK relationship
);

CREATE TABLE APOPEN (
    APOPEN_ID INT PRIMARY KEY, -- Generic PK
    VVNDR VARCHAR(50), -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other APOPEN columns here
    FOREIGN KEY (VVNDR) REFERENCES APVEND(VVNDR) -- Inferred FK relationship
);

CREATE TABLE APHIST (
    APHIST_ID INT PRIMARY KEY, -- Generic PK
    VVNDR VARCHAR(50), -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other APHIST columns here
    FOREIGN KEY (VVNDR) REFERENCES APVEND(VVNDR) -- Inferred FK relationship
);


-- Material Processing Entities
CREATE TABLE MPHDRORD (
    MPHDRORD_ID INT PRIMARY KEY -- Generic PK (Referenced by MPDETAIL)
    -- Add other MPHDRORD columns here
);

CREATE TABLE MPDETAIL (
    MPDETAIL_ID INT PRIMARY KEY, -- Generic PK
    MPHDRORD_ID INT, -- Inferred FK from relationship
    MDTAG VARCHAR(50), -- Key from note (assuming this name)
    IMITEM VARCHAR(50), -- Inferred FK from relationship (produces ITEMMAST)
    column1 VARCHAR(100), -- Placeholder
    -- Add other MPDETAIL columns here
    FOREIGN KEY (MPHDRORD_ID) REFERENCES MPHDRORD(MPHDRORD_ID), -- Inferred FK relationship
    FOREIGN KEY (MDTAG) REFERENCES ITEMTAG(ITTAG), -- Constraint from note
    FOREIGN KEY (IMITEM) REFERENCES ITEMMAST(IMITEM) -- Inferred FK relationship
);

CREATE TABLE MPHSTDET (
    MPHSTDET_ID INT PRIMARY KEY, -- Generic PK
    MPHDRORD_ID INT, -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other MPHSTDET columns here
    FOREIGN KEY (MPHDRORD_ID) REFERENCES MPHDRORD(MPHDRORD_ID) -- Inferred FK relationship
);

CREATE TABLE MPHSTUSE (
    MPHSTUSE_ID INT PRIMARY KEY, -- Generic PK
    MPHDRORD_ID INT, -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other MPHSTUSE columns here
    FOREIGN KEY (MPHDRORD_ID) REFERENCES MPHDRORD(MPHDRORD_ID) -- Inferred FK relationship
);

CREATE TABLE MPHSTRSK (
    MPHSTRSK_ID INT PRIMARY KEY, -- Generic PK
    MPHDRORD_ID INT, -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other MPHSTRSK columns here
    FOREIGN KEY (MPHDRORD_ID) REFERENCES MPHDRORD(MPHDRORD_ID) -- Inferred FK relationship
);

CREATE TABLE MPPROFIL (
    MPPROFIL_ID INT PRIMARY KEY, -- Generic PK
    MPHDRORD_ID INT, -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other MPPROFIL columns here
    FOREIGN KEY (MPHDRORD_ID) REFERENCES MPHDRORD(MPHDRORD_ID) -- Inferred FK relationship
);


-- Financials Entities
CREATE TABLE GLMAST (
    GLMAST_ID INT PRIMARY KEY -- Generic PK
    -- Add other GLMAST columns here
);

CREATE TABLE GLTRANS (
    GLTRANS_ID INT PRIMARY KEY, -- Generic PK
    GLMAST_ID INT, -- Inferred FK from relationship
    OOORDR INT, -- Inferred FK from relationship (Sales Order)
    POHEADER_ID INT, -- Inferred FK from relationship (Purchase Order)
    CALENDAR_DATE DATE, -- Inferred FK from relationship
    POSTPRD_ID INT, -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other GLTRANS columns here
    FOREIGN KEY (GLMAST_ID) REFERENCES GLMAST(GLMAST_ID), -- Inferred FK relationship
    FOREIGN KEY (OOORDR) REFERENCES OEOPNORD(OOORDR), -- Inferred FK relationship
    FOREIGN KEY (POHEADER_ID) REFERENCES POHEADER(POHEADER_ID) -- Inferred FK relationship
    -- FOREIGN KEY (CALENDAR_DATE) REFERENCES CALENDAR(calendar_pk), -- Add FK to CALENDAR table
    -- FOREIGN KEY (POSTPRD_ID) REFERENCES POSTPRD(postprd_pk) -- Add FK to POSTPRD table
);

CREATE TABLE ARDETAL (
    ARDETAL_ID INT PRIMARY KEY, -- Generic PK
    CCUST VARCHAR(50), -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other ARDETAL columns here
    FOREIGN KEY (CCUST) REFERENCES ARCUST(CCUST) -- Inferred FK relationship
);

CREATE TABLE ARCASH (
    ARCASH_ID INT PRIMARY KEY, -- Generic PK
    CCUST VARCHAR(50), -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other ARCASH columns here
    FOREIGN KEY (CCUST) REFERENCES ARCUST(CCUST) -- Inferred FK relationship
);

CREATE TABLE APDIST (
    APDIST_ID INT PRIMARY KEY, -- Generic PK
    VVNDR VARCHAR(50), -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other APDIST columns here
    FOREIGN KEY (VVNDR) REFERENCES APVEND(VVNDR) -- Inferred FK relationship
);

CREATE TABLE APCHKH (
    APCHKH_ID INT PRIMARY KEY, -- Generic PK
    VVNDR VARCHAR(50), -- Inferred FK from relationship
    IMAGEPDF_ID INT, -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other APCHKH columns here
    FOREIGN KEY (VVNDR) REFERENCES APVEND(VVNDR) -- Inferred FK relationship
    -- FOREIGN KEY (IMAGEPDF_ID) REFERENCES IMAGEPDF(imagepdf_pk) -- Add FK to IMAGEPDF table
);

CREATE TABLE GLJRHD (
    GLJRHD_ID INT PRIMARY KEY, -- Generic PK
    GLMAST_ID INT, -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other GLJRHD columns here
    FOREIGN KEY (GLMAST_ID) REFERENCES GLMAST(GLMAST_ID) -- Inferred FK relationship
);

CREATE TABLE GLJRDT (
    GLJRDT_ID INT PRIMARY KEY, -- Generic PK
    GLJRHD_ID INT, -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other GLJRDT columns here
    FOREIGN KEY (GLJRHD_ID) REFERENCES GLJRHD(GLJRHD_ID) -- Inferred FK relationship
);


-- Shipping/Logistics Entities
-- SHIPMAST already created in Sales section
-- SHIPADR already created in Sales section

CREATE TABLE SHSUMM (
    SHSUMM_ID INT PRIMARY KEY, -- Generic PK
    SHIPMAST_ID INT, -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other SHSUMM columns here
    FOREIGN KEY (SHIPMAST_ID) REFERENCES SHIPMAST(SHIPMAST_ID) -- Inferred FK relationship
);

CREATE TABLE DELTRACK (
    DELTRACK_ID INT PRIMARY KEY, -- Generic PK
    SHIPMAST_ID INT, -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other DELTRACK columns here
    FOREIGN KEY (SHIPMAST_ID) REFERENCES SHIPMAST(SHIPMAST_ID) -- Inferred FK relationship
);

CREATE TABLE MNFEST (
    MNFEST_ID INT PRIMARY KEY, -- Generic PK
    SHIPMAST_ID INT, -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other MNFEST columns here
    FOREIGN KEY (SHIPMAST_ID) REFERENCES SHIPMAST(SHIPMAST_ID) -- Inferred FK relationship
);

CREATE TABLE PRCHCHRG (
    PRCHCHRG_ID INT PRIMARY KEY, -- Generic PK
    SHIPMAST_ID INT, -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other PRCHCHRG columns here
    FOREIGN KEY (SHIPMAST_ID) REFERENCES SHIPMAST(SHIPMAST_ID) -- Inferred FK relationship
);

-- System Tables
CREATE TABLE EMPLOYE (
    EMPLOYE_ID INT PRIMARY KEY -- Generic PK (Referenced by OEOPNORD)
    -- Add other EMPLOYE columns here
);

CREATE TABLE COUNTRY (
    COUNTRY_CODE VARCHAR(10) PRIMARY KEY, -- Generic PK
    CCUST VARCHAR(50), -- Inferred FK from relationship
    column1 VARCHAR(100) -- Placeholder
    -- Add other COUNTRY columns here
    -- FOREIGN KEY (CCUST) REFERENCES ARCUST(CCUST) -- This relationship seems reversed in diagram? Usually Customer has a Country Code.
);

CREATE TABLE CALENDAR (
    CALENDAR_DATE DATE PRIMARY KEY -- Generic PK (Referenced by GLTRANS)
    -- Add other CALENDAR columns here
);

CREATE TABLE IMAGEPDF (
    IMAGEPDF_ID INT PRIMARY KEY -- Generic PK (Referenced by APCHKH)
    -- Add other IMAGEPDF columns here
);

CREATE TABLE POSTPRD (
    POSTPRD_ID INT PRIMARY KEY -- Generic PK (Referenced by GLTRANS)
    -- Add other POSTPRD columns here
);

CREATE TABLE SLMNRCAP (
    SLMNRCAP_ID INT PRIMARY KEY, -- Generic PK
    SALESMAN_ID INT, -- Inferred FK from relationship
    column1 VARCHAR(100), -- Placeholder
    -- Add other SLMNRCAP columns here
    FOREIGN KEY (SALESMAN_ID) REFERENCES SALESMAN(SALESMAN_ID) -- Inferred FK relationship
);

-- Add any missing tables here... check all entity names from Mermaid diagram.