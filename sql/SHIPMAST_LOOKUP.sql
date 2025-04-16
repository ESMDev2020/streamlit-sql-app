/**************************************************************
🧠 SECTION: TABLE DEFINITIONS (Based on your schema)
**************************************************************/

-- SHIPMAST
-- Shipment Master Table
-- Contains shipments made by the company. Key columns:
-- SHITEM = item number
-- SHORDN = order number
-- SHCUST = customer number
-- SHIPYY = shipment year (e.g., 25 for 2025)
-- SHIPMM = shipment month (e.g., 2 for February)

-- MPRECS
-- Material/Part Records
-- Master table for inventory items, including descriptions, sizes, grades.
-- MPITEM = item number
-- MPDESC = item description
-- MPGRADE = material or grade (e.g., 4140, 4130)

-- PARTS
-- Alternative or additional part/item master table
-- PTITEM = item number
-- PTDESC = part description
-- PTTYPE = type of part (e.g., BAR, TUBE)

-- SORDER
-- Sales Order Header Table
-- SOORDN = sales order number
-- SOCUST = customer number
-- SODATE = order date
-- SOTOTAL = total order value

-- ARHIST
-- Accounts Receivable History
-- ARORDN = order number
-- ARDATE = invoice date
-- ARAMT = amount charged

-- INHIST
-- Inventory History (Shipping/Receiving)
-- IHORDN = order number
-- IHDATE = transaction date
-- IHAMT = inventory amount or transaction value

-- ARMAST
-- Accounts Receivable Master (Customer info)
-- ARCUST = customer number
-- ARNAME = customer name
-- ARADDR1 = address line

-- CUSMAST
-- Customer Master Table
-- CUCUST = customer number
-- CUNAME = customer name
-- CUADDR1 = customer address

/**************************************************************
 SECTION 1: SHIPMAST → OTHER TABLES (Feb 2025 Shipments)
**************************************************************/

use SigmaTB;

-- Inventory shipped: SHIPMAST ↔ MPRECS
SELECT 
    SM.SHORDN, SM.SHITEM, SM.SHIPYY, SM.SHIPMM, SM.SHQTY, 
    MP.MPDESC, MP.MPGRADE
FROM 
    SHIPMAST SM
JOIN 
    MPRECS MP ON SM.SHITEM = MP.MPITEM
WHERE 
    SM.SHIPYY = 25 AND SM.SHIPMM = 2;

-- Inventory shipped: SHIPMAST ↔ PARTS
SELECT 
    SM.SHORDN, SM.SHITEM, SM.SHIPYY, SM.SHIPMM, SM.SHQTY, 
    PT.PTDESC, PT.PTTYPE
FROM 
    SHIPMAST SM
JOIN 
    PARTS PT ON SM.SHITEM = PT.PTITEM
WHERE 
    SM.SHIPYY = 25 AND SM.SHIPMM = 2;

-- Sales orders shipped: SHIPMAST ↔ SORDER
SELECT 
    SM.SHORDN, SM.SHITEM, SM.SHIPYY, SM.SHIPMM, SO.SOCUST, SO.SODATE, SO.SOTOTAL
FROM 
    SHIPMAST SM
JOIN 
    SORDER SO ON SM.SHORDN = SO.SOORDN
WHERE 
    SM.SHIPYY = 25 AND SM.SHIPMM = 2;

-- Sales orders shipped: SHIPMAST ↔ ARHIST
SELECT 
    SM.SHORDN, SM.SHITEM, SM.SHIPYY, SM.SHIPMM, AR.ARDATE, AR.ARAMT
FROM 
    SHIPMAST SM
JOIN 
    ARHIST AR ON SM.SHORDN = AR.ARORDN
WHERE 
    SM.SHIPYY = 25 AND SM.SHIPMM = 2;

-- Sales orders shipped: SHIPMAST ↔ INHIST
SELECT 
    SM.SHORDN, SM.SHITEM, SM.SHIPYY, SM.SHIPMM, IH.IHDATE, IH.IHAMT
FROM 
    SHIPMAST SM
JOIN 
    INHIST IH ON SM.SHORDN = IH.IHORDN
WHERE 
    SM.SHIPYY = 25 AND SM.SHIPMM = 2;

-- Shipment to customers: SHIPMAST ↔ ARMAST
SELECT 
    SM.SHORDN, SM.SHITEM, SM.SHIPYY, SM.SHIPMM, SM.SHCUST, 
    AR.ARCUST, AR.ARNAME, AR.ARADDR1
FROM 
    SHIPMAST SM
JOIN 
    ARMAST AR ON SM.SHCUST = AR.ARCUST
WHERE 
    SM.SHIPYY = 25 AND SM.SHIPMM = 2;

-- Shipment to customers: SHIPMAST ↔ CUSMAST
SELECT 
    SM.SHORDN, SM.SHITEM, SM.SHIPYY, SM.SHIPMM, SM.SHCUST, 
    CU.CUCUST, CU.CUNAME, CU.CUADDR1
FROM 
    SHIPMAST SM
JOIN 
    CUSMAST CU ON SM.SHCUST = CU.CUCUST
WHERE 
    SM.SHIPYY = 25 AND SM.SHIPMM = 2;


/**************************************************************
 SECTION 2: FIND FIELDS LIKE %%ORDN ACROSS TABLES
**************************************************************/

-- Metadata query to find all columns that include 'ORDN'
SELECT TABLE_NAME, COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE COLUMN_NAME LIKE '%ORDN%';


/**************************************************************
 SECTION 3: SHIPMAST.SHORDN ↔ OTHER ORDER NUMBERS
**************************************************************/

-- SHORDN found in SORDER
SELECT SHORDN 
FROM SHIPMAST 
WHERE SHORDN IN (SELECT SOORDN FROM SORDER);

-- SHORDN found in ARHIST
SELECT SHORDN 
FROM SHIPMAST 
WHERE SHORDN IN (SELECT ARORDN FROM ARHIST);

-- SHORDN found in INHIST
SELECT SHORDN 
FROM SHIPMAST 
WHERE SHORDN IN (SELECT IHORDN FROM INHIST);

-- SHORDNs not found in SORDER
SELECT SHORDN 
FROM SHIPMAST 
WHERE SHORDN NOT IN (SELECT SOORDN FROM SORDER);



-------------------------------------------
USE sigmatb;
GO

SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ep.value AS ColumnDescription,
    ty.name AS DataType,
    c.precision AS Precision,
    c.scale AS Scale,
    c.max_length AS MaxLength,
    c.is_nullable AS IsNullable
FROM 
    sys.columns c
INNER JOIN 
    sys.tables t ON c.object_id = t.object_id
LEFT JOIN 
    sys.extended_properties ep 
    ON ep.major_id = c.object_id 
    AND ep.minor_id = c.column_id 
    AND ep.name = 'MS_Description'
INNER JOIN 
    sys.types ty ON c.user_type_id = ty.user_type_id
ORDER BY 
    t.name, c.column_id;
