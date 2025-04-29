
--Date
SELECT  GETDATE() AS CurrentTime;

--Name
SELECT name FROM sys.databases;
Select 'create database.. muted' --CREATE DATABASE SigmaTB;

--Use the DB
USE SigmaTB;

-- Generate a COUNT(*) query for each table
    DECLARE @sql NVARCHAR(MAX) = N'';   

    -- Generate a COUNT(*) query for each table
    SELECT  @sql += 'SELECT ''' + TABLE_SCHEMA + '.' + TABLE_NAME + ''' AS TableName, COUNT(*) AS RecordCount FROM ' + QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME) + ' UNION ALL '
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE = 'BASE TABLE';

    -- Remove the last "UNION ALL"
    SET @sql = LEFT(@sql, LEN(@sql) - 10);

    -- Execute the generated SQL
    EXEC sp_executesql @sql;

/***************************************/

select * from ROPData
select count(*) from ropdata
select unique

select count(*) from ropdata where Vndr NOT LIKE 'N%';
SELECT * FROM ROPData WHERE Vndr NOT LIKE 'N%' AND OD like '14';
SELECT * FROM ROPData WHERE Vndr NOT LIKE 'N%' AND Vndr like 'HAL';


SELECT Item, Description,[con/wk] FROM ROPDATA WHERE Item = '51503';

SELECT * FROM SalesData WHERE CALPHA LIKE 'AERO%';
sELECT COUNT(*) FROM ROPData;

--let me try to get the MP processing
SELECT * from UsageData where IHITEM = 50002;
SELECT [IHITEM], [IHTRNT],[IHTQTY], [Column2]   from UsageData where IHITEM = 50002;

select '50002IN950654000000075320240503'

SELECT 
    CASE 
        WHEN CHARINDEX('202405', [Column2]) > 0 THEN 'Yes'
        ELSE 'No'
    END AS ContainsText
FROM UsageData;


SELECT [IHITEM], [IHTRNT],[IHTQTY], [Column2] 
FROM UsageData
WHERE CHARINDEX('202405', [Column2]) > 0;


--///////////////////////////////////////////
--Get cost of material processing on 1 item
SELECT 
    SUM(IHTQTY) AS TotalQuantity
FROM 
    UsageData
WHERE 
    [Column2] LIKE '50002MP________________202409__';
--///////////////////////////////////////////
--///////////////////////////////////////////
--///////////////////////////////////////////



SELECT 
    SUM(IHTQTY) AS total_quantity
FROM 
    UsageData
WHERE 
    IHITEM = 50002
    AND CAST(IHTRNT AS VARCHAR(MAX)) = 'MP'
    AND IHTRN# = 402074
    AND IHVNDR = 121
    AND LEFT(CAST(Column1 AS VARCHAR(20)), 6) = '202409';


SELECT 
    IHITEM, IHTRNT, IHTRN#, IHVNDR, Column1, IHTQTY
FROM 
    UsageData
WHERE 
    IHITEM = 50002
    AND CAST(IHTRNT AS VARCHAR(MAX)) = 'MP'
    AND IHTRN# = 402074
    AND IHVNDR = 121
    AND LEFT(CAST(Column1 AS VARCHAR(20)), 6) = '202409';


SELECT * FROM UsageData WHERE IHITEM = '50002';
SELECT DISTINCT IHTRNT FROM UsageData;
SELECT DISTINCT IHTRN# FROM UsageData WHERE IHITEM = 50002;

SELECT DISTINCT Column1 FROM UsageData WHERE IHITEM = 50002;


SELECT TOP 10 IHTRNT 
FROM UsageData 
WHERE CAST(IHTRNT AS VARCHAR(MAX)) LIKE '%MP%';




SELECT 
    IHITEM, IHTRNT, IHTRN#, IHVNDR, IHCUST Column1, IHTQTY
FROM 
    UsageData
WHERE 
    CAST(IHTRNT AS VARCHAR(10)) = 'CR';

SELECT 
    *
FROM 
    UsageData
WHERE 
    CAST(IHTRNT AS VARCHAR(10)) = 'CR';

SELECT 
    u.*, 
    u2.CALPHA AS CustomerName
FROM 
    UsageData u
LEFT JOIN 
    UsageData2 u2 ON u.IHCUST = u2.IHCUST
WHERE 
    CAST(u.IHTRNT AS VARCHAR(10)) = 'CR';


--where is the customer name?
DECLARE @sql NVARCHAR(MAX) = '';

SELECT @sql += 
    'SELECT TOP 1 * FROM ' + 
    QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME) + ';' + CHAR(13)
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';

PRINT @sql;  -- OR SELECT @sql AS SQLText;

SELECT TOP 1 * from [dbo].[BasePrice];
SELECT TOP 1 * from [dbo].[POData];
SELECT TOP 1 * from [dbo].[POIssued];
SELECT TOP 1 * from [dbo].[ROPData]
SELECT TOP 1 * from [dbo].[SalesData];      -- customer
SELECT TOP 1 * from [dbo].[TagData];        -- availability
SELECT TOP 1 * from [dbo].[UsageData];
SELECT TOP 1 * from [dbo].[UsageData2];     -- customer 

--How many transactions are by transaction types?
    
SELECT 
    CAST(IHTRNT AS VARCHAR(10)) AS TransactionType,
    FORMAT(COUNT(*), 'N0') AS TransactionCount,
    FORMAT(SUM(IHTQTY), 'N2') AS TotalQuantity
FROM 
    UsageData
WHERE 
    CAST(IHTRNT AS VARCHAR(10)) IN ('CR', 'IA', 'IN', 'OW', 'OR')
GROUP BY 
    CAST(IHTRNT AS VARCHAR(10))
ORDER BY 
    TransactionType;

-- cool
-- so, lets gonna get the column names with description, and then identifying the customer who did the credit memos

WITH OneCustomerNamePerID AS (
    SELECT 
        IHCUST, 
        MIN(CONVERT(VARCHAR(MAX), CALPHA)) AS CALPHA
    FROM UsageData2
    GROUP BY IHCUST
)
SELECT 
    u.IHITEM AS [IHITEM (item ID)],
    u.IHCUST AS [IHCUST (customer ID)],
    c.CALPHA AS [CustomerName],
    u.IHTRN# AS [IHTRN# (transaction number)],
    u.IHTQTY AS [IHTQTY (quantity)],
    CONVERT(VARCHAR(MAX), u.Column3) AS [Column3 (quantity copy?)],
    CONVERT(VARCHAR(10), u.IHTRNT) AS [IHTRNT (transaction type)],
    CONVERT(VARCHAR(MAX), u.Column1) AS [Column1 (internal ref)],
    u.IHVNDR AS [IHVNDR (vendor)],
    u.IHTRYY AS [IHTRYY (year)],
    u.IHTRMM AS [IHTRMM (month)],
    u.IHTRDD AS [IHTRDD (day)],
    CONVERT(VARCHAR(MAX), u.Column2) AS [Column2 (composite key)],
    CONVERT(VARCHAR(MAX), u.Column4) AS [Column4 (status flag)]
FROM 
    UsageData u
LEFT JOIN 
    OneCustomerNamePerID c ON u.IHCUST = c.IHCUST
WHERE 
    CONVERT(VARCHAR(10), u.IHTRNT) = 'IA';

-- Now we query for more than 1 transaction category 
WITH OneCustomerNamePerID AS (
    SELECT 
        IHCUST, 
        MIN(CONVERT(VARCHAR(MAX), CALPHA)) AS CALPHA
    FROM UsageData2
    GROUP BY IHCUST
)
SELECT 
    u.IHITEM AS [IHITEM (item ID)],
    u.IHCUST AS [IHCUST (customer ID)],
    c.CALPHA AS [CustomerName],
    u.IHTRN# AS [IHTRN# (transaction number)],
    u.IHTQTY AS [IHTQTY (quantity)],
    CONVERT(VARCHAR(MAX), u.Column3) AS [Column3 (quantity copy?)],
    CONVERT(VARCHAR(10), u.IHTRNT) AS [IHTRNT (transaction type)],
    CONVERT(VARCHAR(MAX), u.Column1) AS [Column1 (internal ref)],
    u.IHVNDR AS [IHVNDR (vendor ID)],
    p.Vendor AS [VendorName],  -- 🎯 pulled from POData
    u.IHTRYY AS [IHTRYY (year)],
    u.IHTRMM AS [IHTRMM (month)],
    u.IHTRDD AS [IHTRDD (day)],
    CONVERT(VARCHAR(MAX), u.Column2) AS [Column2 (composite key)],
    CONVERT(VARCHAR(MAX), u.Column4) AS [Column4 (status flag)]
FROM 
    UsageData u
LEFT JOIN 
    OneCustomerNamePerID c ON u.IHCUST = c.IHCUST
LEFT JOIN 
    POData p ON u.IHVNDR = p.[V#]
WHERE 
    CONVERT(VARCHAR(10), u.IHTRNT) IN ('OR', 'OW');


-- PURCHASE ORDERS 
WITH OneCustomerNamePerID AS (
    SELECT 
        IHCUST, 
        MIN(CONVERT(VARCHAR(MAX), CALPHA)) AS CALPHA
    FROM UsageData2
    GROUP BY IHCUST
)
SELECT 
    u.IHITEM AS [IHITEM (item ID)],
    u.IHCUST AS [IHCUST (customer ID)],
    c.CALPHA AS [CustomerName],
    u.IHTRN# AS [IHTRN# (transaction number)],
    u.IHTQTY AS [IHTQTY (quantity)],
    CONVERT(VARCHAR(MAX), u.Column3) AS [Column3 (quantity copy?)],
    CONVERT(VARCHAR(10), u.IHTRNT) AS [IHTRNT (transaction type)],
    CONVERT(VARCHAR(MAX), u.Column1) AS [Column1 (internal ref)],
    u.IHVNDR AS [IHVNDR (vendor ID)],
    p.Vendor AS [VendorName],  -- 🎯 pulled from POData
    u.IHTRYY AS [IHTRYY (year)],
    u.IHTRMM AS [IHTRMM (month)],
    u.IHTRDD AS [IHTRDD (day)],
    CONVERT(VARCHAR(MAX), u.Column2) AS [Column2 (composite key)],
    CONVERT(VARCHAR(MAX), u.Column4) AS [Column4 (status flag)]
FROM 
    UsageData u
LEFT JOIN 
    OneCustomerNamePerID c ON u.IHCUST = c.IHCUST
LEFT JOIN 
    POData p ON u.IHVNDR = p.[V#]
WHERE 
    CONVERT(VARCHAR(10), u.IHTRNT) IN ('PO');


select * from ROPData where CONVERT(varchar(mAX), [Item]) = '50002';
SELECT count(*) from ropdata;

select * from usagedata 
where IHITEM = 50002
AND IHTRYY = 24
AND IHTRMM = 09
AND CONVERT(VARCHAR(MAX), IHTRNT) IN ('OW', 'OR');

--Select MP from Usage Data for a particular Month
select SUM(IHTQTY) from usagedata 
where IHITEM = 50002
AND IHTRYY = 24
AND IHTRMM = 09
AND CONVERT(VARCHAR(MAX), IHTRNT) IN ('OW', 'OR');

--Now lets gonna try by 12 months
SELECT 
    FORMAT(DATEFROMPARTS(2000 + IHTRYY, IHTRMM, 1), 'yyyy-MM') AS [Month],
    SUM(IHTQTY) AS [TotalMaterialProcessed]
FROM 
    UsageData
WHERE 
    CONVERT(VARCHAR(10), IHTRNT) IN ('OW', 'OR')
    AND DATEFROMPARTS(2000 + IHTRYY, IHTRMM, 1) >= DATEADD(MONTH, -13, CAST(GETDATE() AS DATE))  -- last 12 months including current
GROUP BY 
    FORMAT(DATEFROMPARTS(2000 + IHTRYY, IHTRMM, 1), 'yyyy-MM')
ORDER BY 
    [Month];


SELECT 
    FORMAT(DATEFROMPARTS(2000 + IHTRYY, IHTRMM, 1), 'yyyy-MM') AS [Month],
    SUM(IHTQTY) AS [TotalMaterialProcessed]
FROM 
    UsageData
WHERE 
    IHITEM = 50002  -- ✅ Filter to specific item
    AND CONVERT(VARCHAR(10), IHTRNT) IN ('OW', 'OR')
    AND DATEFROMPARTS(2000 + IHTRYY, IHTRMM, 1) >= DATEADD(MONTH, -13, CAST(GETDATE() AS DATE))
GROUP BY 
    FORMAT(DATEFROMPARTS(2000 + IHTRYY, IHTRMM, 1), 'yyyy-MM')
ORDER BY 
    [Month];

--///////////////////////////////////////////////////////////////////
--HERE IS IT... THE TABLE THAT RETURNS MP BY MONTH BY ITEM

-- Step 1: Generate last 13 months
WITH Last13Months AS (
    SELECT FORMAT(DATEADD(MONTH, -n, CAST(GETDATE() AS DATE)), 'yyyy-MM') AS [Month]
    FROM (SELECT TOP 13 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n FROM sys.all_objects) AS x
),
-- Step 2: Aggregate your material processing data
MonthlyProcessing AS (
    SELECT 
        FORMAT(DATEFROMPARTS(2000 + IHTRYY, IHTRMM, 1), 'yyyy-MM') AS [Month],
        SUM(IHTQTY) AS TotalMaterialProcessed
    FROM UsageData
    WHERE 
        IHITEM = 50002
        AND CONVERT(VARCHAR(10), IHTRNT) IN ('OW', 'OR')
        AND DATEFROMPARTS(2000 + IHTRYY, IHTRMM, 1) >= DATEADD(MONTH, -13, CAST(GETDATE() AS DATE))
    GROUP BY 
        FORMAT(DATEFROMPARTS(2000 + IHTRYY, IHTRMM, 1), 'yyyy-MM')
)
-- Step 3: Join and return all months
SELECT 
    l.[Month],
    FORMAT(ISNULL(m.TotalMaterialProcessed, 0), 'N3') AS [TotalMaterialProcessed]
FROM 
    Last13Months l
LEFT JOIN 
    MonthlyProcessing m ON l.Month = m.Month
ORDER BY 
    l.Month;
--///////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////


--NOW, LETS GONNA HAVE THE TABLE WITH IA, MP, SO
WITH Months AS (
    SELECT FORMAT(DATEADD(MONTH, -n, CAST(GETDATE() AS DATE)), 'yyyy-MM') AS Month
    FROM (SELECT TOP 13 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n FROM master.dbo.spt_values) AS x
),
Aggregated AS (
    SELECT
        FORMAT(DATEFROMPARTS(2000 + IHTRYY, IHTRMM, 1), 'yyyy-MM') AS Month,
        CASE 
            WHEN CONVERT(VARCHAR(10), IHTRNT) = 'IA' THEN IHTQTY
            WHEN CONVERT(VARCHAR(10), IHTRNT) IN ('OW', 'OR') THEN IHTQTY
            WHEN CONVERT(VARCHAR(10), IHTRNT) = 'IN' THEN IHTQTY
            ELSE 0
        END AS Qty,
        CONVERT(VARCHAR(10), IHTRNT) AS Type
    FROM UsageData
    WHERE IHITEM = 50002
      AND DATEFROMPARTS(2000 + IHTRYY, IHTRMM, 1) >= DATEADD(MONTH, -13, CAST(GETDATE() AS DATE))
)
SELECT 
    m.Month,
    FORMAT(SUM(CASE WHEN a.Type = 'IA' THEN a.Qty ELSE 0 END), 'N2') AS [IA (Inventory Adjustments)],
    FORMAT(SUM(CASE WHEN a.Type IN ('OW', 'OR') THEN a.Qty ELSE 0 END), 'N2') AS [MP (Material Processed)],
    FORMAT(SUM(CASE WHEN a.Type = 'IN' THEN a.Qty ELSE 0 END), 'N2') AS [SO (Sales Orders)]
FROM Months m
LEFT JOIN Aggregated a ON m.Month = a.Month
GROUP BY m.Month
ORDER BY m.Month;

--////////////////////////////////////////////////////////////
--////////////////////////////////////////////////////////////

--//////////////////////////////////////////////////////////
--////////////////////////////////////////////////////////////
-- Lets gonna describe items

selecT * FROM ROPdata where ITEM

-- they get items from ROPQuery
SELECT ITEMMAST.IMFSP2, ITEMMAST.IMITEM, ITEMMAST.IMSIZ1, 
      ITEMMAST.IMSIZ2, ITEMMAST.IMSIZ3, ITEMMAST.IMDSC2, ITEMMAST.IMWPFT, 
        ITEMONHD.IOACST, ITEMONHD.IOQOH, ITEMONHD.IOQOO, 
        IOQOR+IOQOOR, 
        ITEMMAST.IMDSC1, ITEMMAST.IMWUOM, ITEMMAST.IMCSMO
FROM S219EAAV.MW4FILE.ITEMMAST ITEMMAST, 
    S219EAAV.MW4FILE.ITEMONHD ITEMONHD
WHERE ITEMONHD.IOITEM = ITEMMAST.IMITEM AND ((ITEMMAST.IMRECD='A') AND (ITEMMAST.IMITEM Between '49999' And '90000'))
ORDER BY ITEMMAST.IMFSP2





--since i cannot convert, then i add

ALTER TABLE ROPData
ADD 
    Item_int INT NULL,
    OD_num NUMERIC(10, 2) NULL,
    ID_num NUMERIC(10, 2) NULL,
    Wall_num NUMERIC(10, 2) NULL,
    OnHand_num NUMERIC(10, 2) NULL,
    Rsrv_num NUMERIC(10, 2) NULL,
    FtPerUnit_num NUMERIC(10, 2) NULL,     -- "#/ft"
    PricePerFt_num NUMERIC(10, 2) NULL,   -- "$/ft"
    Index_num NUMERIC(10, 2) NULL,
    Level_num NUMERIC(10, 2) NULL,
    ConPerWk_num NUMERIC(10, 2) NULL,     -- "con/wk"
    TotCons_num NUMERIC(10, 2) NULL,
    Time_num NUMERIC(10, 2) NULL;

--i copy the values
-- Safely copy values to new typed columns
UPDATE ROPData
SET
    Item_int = TRY_CAST(CAST(Item AS VARCHAR(MAX)) AS INT),
    OD_num = TRY_CAST(CAST(OD AS VARCHAR(MAX)) AS NUMERIC(10,2)),
    ID_num = TRY_CAST(CAST(ID AS VARCHAR(MAX)) AS NUMERIC(10,2)),
    Wall_num = TRY_CAST(CAST(Wall AS VARCHAR(MAX)) AS NUMERIC(10,2)),
    OnHand_num = TRY_CAST(CAST([OnHand] AS VARCHAR(MAX)) AS NUMERIC(10,2)),
    Rsrv_num = TRY_CAST(CAST(Rsrv AS VARCHAR(MAX)) AS NUMERIC(10,2)),
    FtPerUnit_num = TRY_CAST(CAST([#/ft] AS VARCHAR(MAX)) AS NUMERIC(10,2)),
    PricePerFt_num = TRY_CAST(CAST([$/ft] AS VARCHAR(MAX)) AS NUMERIC(10,2)),
    Index_num = TRY_CAST(CAST([Index] AS VARCHAR(MAX)) AS NUMERIC(10,2)),
    Level_num = TRY_CAST(CAST([Level] AS VARCHAR(MAX)) AS NUMERIC(10,2)),
    ConPerWk_num = TRY_CAST(CAST([con/wk] AS VARCHAR(MAX)) AS NUMERIC(10,2)),
    TotCons_num = TRY_CAST(CAST([TotCons] AS VARCHAR(MAX)) AS NUMERIC(10,2)),
    Time_num = TRY_CAST(CAST([Time] AS VARCHAR(MAX)) AS NUMERIC(10,2));

-- now we delete the old text columns
ALTER TABLE ROPData
DROP COLUMN 
    Item,
    OD,
    ID,
    Wall,
    OnHand,
    Rsrv,
    [#/ft],
    [$/ft],
    [Index],
    [Level],
    [con/wk],
    TotCons,
    [Time];

--and then we rename the new columns to the original names
EXEC sp_rename 'ROPData.Item_int', 'Item', 'COLUMN';
EXEC sp_rename 'ROPData.OD_num', 'OD', 'COLUMN';
EXEC sp_rename 'ROPData.ID_num', 'ID', 'COLUMN';
EXEC sp_rename 'ROPData.Wall_num', 'Wall', 'COLUMN';
EXEC sp_rename 'ROPData.OnHand_num', 'OnHand', 'COLUMN';
EXEC sp_rename 'ROPData.Rsrv_num', 'Rsrv', 'COLUMN';
EXEC sp_rename 'ROPData.FtPerUnit_num', '#/ft', 'COLUMN';
EXEC sp_rename 'ROPData.PricePerFt_num', '$/ft', 'COLUMN';
EXEC sp_rename 'ROPData.Index_num', 'Index', 'COLUMN';
EXEC sp_rename 'ROPData.Level_num', 'Level', 'COLUMN';
EXEC sp_rename 'ROPData.ConPerWk_num', 'con/wk', 'COLUMN';
EXEC sp_rename 'ROPData.TotCons_num', 'TotCons', 'COLUMN';
EXEC sp_rename 'ROPData.Time_num', 'Time', 'COLUMN';


--GET THE ITEM THAT CHRIS IS REVIEWING
select [Size Text], Description, SMO
from ROPData
WHERE item = 50002;

--////////////////////////////////////////////////////////////////
--////////////////////////////////////////////////////////////////
USE SigmaTB;


-- 1. Item being reviewed
            SELECT [Size Text], Description, SMO
            FROM ROPData
            WHERE Item = 50002;

            -- 2. IA, MP, SO Summary by Month
            WITH Months AS (
                SELECT FORMAT(DATEADD(MONTH, -n, CAST(GETDATE() AS DATE)), 'yyyy-MM') AS Month
                FROM (SELECT TOP 13 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n FROM sys.all_objects) AS x
            ),
            Aggregated AS (
                SELECT
                    FORMAT(DATEFROMPARTS(2000 + IHTRYY, IHTRMM, 1), 'yyyy-MM') AS Month,
                    CASE 
                        WHEN CONVERT(VARCHAR(10), IHTRNT) = 'IA' THEN IHTQTY
                        WHEN CONVERT(VARCHAR(10), IHTRNT) IN ('OW', 'OR') THEN IHTQTY
                        WHEN CONVERT(VARCHAR(10), IHTRNT) = 'IN' THEN IHTQTY
                        ELSE 0
                    END AS Qty,
                    CONVERT(VARCHAR(10), IHTRNT) AS Type
                FROM UsageData
                WHERE IHITEM = 50002
                  AND DATEFROMPARTS(2000 + IHTRYY, IHTRMM, 1) >= DATEADD(MONTH, -13, CAST(GETDATE() AS DATE))
            )
            SELECT 
                m.Month,
                FORMAT(SUM(CASE WHEN a.Type = 'IA' THEN a.Qty ELSE 0 END), 'N2') AS [IA (Inventory Adjustments)],
                FORMAT(SUM(CASE WHEN a.Type IN ('OW', 'OR') THEN a.Qty ELSE 0 END), 'N2') AS [MP (Material Processed)],
                FORMAT(SUM(CASE WHEN a.Type = 'IN' THEN a.Qty ELSE 0 END), 'N2') AS [SO (Sales Orders)]
            FROM Months m
            LEFT JOIN Aggregated a ON m.Month = a.Month
            GROUP BY m.Month
            ORDER BY m.Month;

            -- 3. Inventory Availability
            SELECT [OnHand], [Rsrv], [OnHand] - [Rsrv] AS [Available Inv]
            FROM ROPData
            WHERE Item = 50002;

            -- 4. Usage and Vendor
            SELECT 'Usage and Vendor' AS [Title], [#/ft], [UOM], [$/ft], [con/wk], [Vndr]
            FROM ROPData
            WHERE Item = 50002;

            -- 5. Depletion Forecast
            SELECT 'When and how much purchase' AS [Question],
                [OnHand] - [Rsrv] AS [Available Inv],
                ([#/ft] * ([OnHand] - [Rsrv])) AS [Pounds],
                [$/ft] * ([OnHand] - [Rsrv]) AS [Dollars],
                ([OnHand] - [Rsrv]) / [con/wk] AS [Weeks],
                DATEADD(WEEK, ([OnHand] - [Rsrv]) / [con/wk], CAST(GETDATE() AS DATE)) AS [Expected Depletion Date]
            FROM ROPData
            WHERE Item = 50002;

            --6.- Purchases
            Select ROPDATA.[OnPO],ROP.[Rems], ROP.[Level] from ROPData, ROP WHERE ropdata.Item = 50002 and rop.imitem=50002;
            
            --7.- Max Inventory (Available + rems + PO
            select 
            ((ROPDATA.[#/ft] * (ROPDATA.[OnHand] - ROPDATA.[Rsrv]))  +
            ROP.[Rems] +
            ROPDATA.[Rsrv]) AS [Pounds]
            FROM ROPDATA, ROP
            where ropdata.Item = 50002 and rop.imitem=50002;



           DECLARE @item INT = 50002;
            DECLARE @onHand FLOAT;
            DECLARE @reserved FLOAT;
            DECLARE @rems FLOAT;
            DECLARE @Lb_ft FLOAT;
            DECLARE @quantity FLOAT;
            DECLARE @quantity_LbFt FLOAT;
            DECLARE @quantity_USDFt FLOAT;
            DECLARE @quantity_USD FLOAT;

            -- Get the values once
            SELECT 
                @onHand = ROPDATA.[OnHand],
                @reserved = ROPDATA.[Rsrv],
                @Lb_ft = ROPDATA.[#/ft],
                @quantity_USDFt = ROPDATA.[$/ft]
            FROM ROPDATA
            WHERE ROPDATA.Item = @item;

            -- Get Rems
            SELECT 
                @rems = ROP.[Rems]
            FROM ROP
            WHERE ROP.IMItem = @item;

            -- Do the math
            SET @quantity = ((@onHand - @reserved) + @rems + @reserved);
            SET @quantity_LbFt = (@quantity * @Lb_ft);
            SET @quantity_USD = (@quantity_LbFt * @quantity_USDFt);

            -- Show results
            SELECT 
                @quantity AS Quantity,
                @quantity_LbFt AS Quantity_Lbs,
                @quantity_USDFt AS PricePerFtUSD,
                @quantity_USD AS TotalValueUSD;


--///////////////////////////////////////////////

-- What is the data of ROP?
use Sigmatb;
SELECT DISTINCT CAST(Column3 AS VARCHAR(MAX)) AS Column3
FROM ROP;

--How many types 
SELECT 
    RTRIM(CAST(Column3 AS VARCHAR(MAX))) AS Type,
    COUNT(*) AS Total
FROM ROP
WHERE Column3 IS NOT NULL
GROUP BY RTRIM(CAST(Column3 AS VARCHAR(MAX)))
ORDER BY total DESC;

--how much
select IMITEM, column3, avail, 
from ROP where avail >0
order by avail desc;

-- add icons ⚪⬛,
USE SigmaTB;

SELECT 
  ROP.IMITEM,  ROP.Column3,  ROP.Avail, ROP.[con], ROPData.[con/wk],
  (ROPData.[OnHand] - ROPData.[Rsrv]) / ROPData.[con/wk] AS [Weeks],
    DATEADD(WEEK, (ROPData.[OnHand] - ROPData.[Rsrv]) / ROPData.[con/wk], CAST(GETDATE() AS DATE)) AS [Expected Depletion Date],
  CASE 
    WHEN ROP.IMSIZ2 > 0 THEN 'O'
    ELSE '⬛'
  END AS Icon
FROM ROP, ROPDATA WHERE   ROPDAta.Item = ROP.IMITEM ORDER BY Avail DESC;
ROP.Avail > 0 AND


SELECT 
    ROP.IMITEM,  ROP.Column3,  ROP.Avail,  ROP.[con],  ROPData.[con/wk],
    (ROPData.[OnHand] - ROPData.[Rsrv]) / NULLIF(ROPData.[con/wk], 0)  AS [Weeks],
    DATEADD( WEEK,    (ROPData.[OnHand] - ROPData.[Rsrv]) / NULLIF(ROPData.[con/wk], 0),    CAST(GETDATE() AS DATE)  ) AS [Expected Depletion Date],
    ropdata.[$/ft] * (ropdata.[OnHand] - ropdata.[Rsrv]) AS [Dollars],
  CASE 
    WHEN ROP.IMSIZ2 > 0 THEN 'O'
    ELSE '⬛'
  END AS Icon
FROM ROP 
JOIN ROPDATA ON ROP.IMITEM = ROPDATA.Item
where ROP.Avail > 0
ORDER BY ROP.Avail DESC;

---IMPROVED QUERY TO AVOID MULTIPLE QUERIES FOR CALCULATIONS
SELECT 
    ROP.IMITEM,
    ROP.Column3,
    ROP.Avail,
    ROP.[con],
    ROPData.[con/wk],
    calc.AvailableFeet / NULLIF(ROPData.[con/wk], 0),  AS [Weeks],
    DATEADD(
        WEEK,
        calc.AvailableFeet / NULLIF(ROPData.[con/wk], 0),
        CAST(GETDATE() AS DATE)
    ) AS [Expected Depletion Date],
    ROPData.[$/ft] * calc.AvailableFeet AS [Dollars],
    CASE 
        WHEN ROP.IMSIZ2 > 0 THEN 'O'
        ELSE '⬛'
    END AS Icon
FROM ROP
JOIN ROPDATA ON ROP.IMITEM = ROPDATA.Item
CROSS APPLY (
    SELECT ROPDATA.[OnHand] - ROPDATA.[Rsrv] AS AvailableFeet
) AS calc
WHERE ROP.Avail > 0
ORDER BY ROP.Avail DESC;

CREATE NONCLUSTERED INDEX IX_ROP_IMITEM ON ROP(IMITEM);
CREATE NONCLUSTERED INDEX IX_ROPDATA_ITEM ON ROPDATA(Item);


-- NEW QUERIES

USE SIGMATB;
SELECT * FROM PODATA WHERE ITEM = 50002;

select 'ROP' AS 'TABLE',  * from ROP WHERE dbo.rop.IMITEM IN('50002', '51527');       --ROP has available (onhand-reserve)
select 'ROPData' AS 'TABLE',  * from ROPdata WHERE dbo.ropdata.Item IN (50002,51527);   --ROPData has onhand
select * from UsageData where usagedata.IHITEM = 50002;
select sum   ( usagedata.IHTQTY) from usagedata where usagedata.IHITEM = 50002; --returns 30
select sum   ( usagedata.IHTQTY) from usagedata where usagedata.IHITEM = 50002 AND CAST(usagedata.IHTRNT AS VARCHAR(10)) = 'IN';  -- returns -107
select sum   ( usagedata.IHTQTY) from usagedata where usagedata.IHITEM = 50002 AND CAST(usagedata.Column4 as varchar(10)) <> 'no';  -- returns -84

--safety level
select ropdata.level, ropdata.Vndr, ropdata.comment, time = 26.1428571428571, ropdata.[#/ft]  from ropdata where ropdata.Item = 50002;


--consumption
--select usagedata.column4, usagedata.IHTQTY from usagedata  where usagedata.IHITEM = 50002  and cast(usagedata.column4 as varchar(10)) = '50002';
--select sum( usagedata.IHTQTY) from usagedata  where usagedata.IHITEM = 50002  and cast(usagedata.column4 as varchar(10)) = '50002';

SELECT 
    ropdata.level,
    ropdata.Vndr,
    ropdata.comment,
    26.1428571428571 AS time,
    ropdata.[#/ft],
    (
        SELECT -SUM(usagedata.IHTQTY)
        FROM usagedata
        WHERE usagedata.IHITEM = 50002
          AND CAST(usagedata.column4 AS VARCHAR(10)) = '50002'
    ) AS total_usage,
    ropdata.[#/ft] + (
        SELECT -SUM(usagedata.IHTQTY)
        FROM usagedata
        WHERE usagedata.IHITEM = 50002
          AND CAST(usagedata.column4 AS VARCHAR(10)) = '50002'
    ) AS net_consumption
FROM ropdata
WHERE ropdata.Item = 50002;

--Consumption per week
select ropdata.TotCons, ropdata.time  from ROPData where ropdata.Item = 50002;
select ropdata.TotCons / ropdata.time from ROPData where ropdata.Item = 50002;


--Remnants
select tagdata.remnants from tagdata where tagdata.Item = 50002;    --IMFSP3

--Availability
--Inventory onhand - reserved
select ropdata.OnHand, ropdata.Rsrv, (ropdata.OnHand- ropdata.Rsrv) as 'Available' from ropdata where ropdata.Item = 50002;

--On purchase orders
select ropdata.OnPO from ropdata where ropdata.Item = 50002;

--safety levels
select ropdata.[Level] from ropdata where ropdata.Item = 50002;

--vendor
select ropdata.Vndr from ropdata where ropdata.Item = 50002;

--lead time
select ropdata.time from ropdata where ropdata.Item = 50002;

--Ground zero
--Take everything I have (available + on order), subtract the safety stock and leftovers, divide by how much I consume each week, and subtract the time it takes to get more (lead time)





use sigmatb;

--try lead time
SELECT 
    ISNULL(VL.LeadWeeks, -363) AS Lead
FROM 
    ROP R
LEFT JOIN 
    VendorLead VL
    ON CAST(R.Column3 AS VARCHAR(10)) = VL.Code
WHERE 
    R.IMITEM = '50002';


--Ground zero, but depends on code to update lead time, so we will create another one
SELECT 
    rop.IMITEM,
    rop.Avail,
    ropdata.OnHand,
    ropdata.OnPO,
    rop.Rems,
    rop.[Level],
    ropdata.[con/wk],
    rop.Lead,
    CASE 
        WHEN ropdata.[con/wk] IS NULL OR ropdata.[con/wk] = 0 THEN 363
        ELSE ROUND(
            (
                (rop.Avail + ropdata.OnHand + CAST(CAST(ropdata.OnPO AS VARCHAR(50)) AS FLOAT)) 
                - (rop.Rems + rop.[Level])
            ) / NULLIF(ropdata.[con/wk], 0) - rop.Lead,
        0)
    END AS GroundZeroWeeks
FROM ROP, ROPData
WHERE rop.IMITEM = 50002 AND ropdata.Item = 50002;

-- Ground zero with default lead time if missing
SELECT 
    rop.IMITEM,
    rop.Avail,
    ropdata.OnHand,
    ropdata.OnPO,
    rop.Rems,
    rop.[Level],
    ropdata.[con/wk],
    ISNULL(rop.Lead, -363) AS Lead,
    CASE 
        WHEN ropdata.[con/wk] IS NULL OR ropdata.[con/wk] = 0 THEN 363
        ELSE ROUND(
            (
                (rop.Avail + ropdata.OnHand + CAST(CAST(ropdata.OnPO AS VARCHAR(50)) AS FLOAT)) 
                - (rop.Rems + rop.[Level])
            ) / NULLIF(ropdata.[con/wk], 0) - ISNULL(rop.Lead, -363),
        0)
    END AS GroundZeroWeeks
FROM ROP rop
JOIN ROPData ropdata ON rop.IMITEM = ropdata.Item
WHERE rop.IMITEM = 50002;


/*SELECT 
    rop.IMITEM,
    rop.Avail,
    ropdata.OnHand,
    ropdata.OnPO,
    rop.Rems,
    rop.[Level],
    ropdata.[con/wk],
    rop.Lead,
    -- Ground Zero calculation with proper text-to-float conversion
    CASE 
        WHEN ropdata.[con/wk] IS NULL OR ropdata.[con/wk] = 0 THEN 363
        ELSE 
            ISNULL(ROUND(
                (
                    (rop.Avail + ropdata.OnHand + CAST(CAST(ropdata.OnPO AS VARCHAR(100)) AS FLOAT)) 
                    - (rop.Rems + rop.[Level])
                ) / NULLIF(ropdata.[con/wk], 0) 
                - ISNULL(rop.Lead, 0),
            0), 363)
    END AS GroundZeroWeeks
FROM ROP rop
JOIN ROPData ropdata ON rop.IMITEM = ropdata.Item
WHERE rop.IMITEM = 50002;
*/

select ropdata.comment from ropdata where ropdata.Item = 50002;

--all together
select ropdata.[Level], ropdata.Vndr, ropdata.comment, time = 26.1428571428571,   ropdata.[#/ft],
    (
        SELECT -SUM(usagedata.IHTQTY)
        FROM usagedata
        WHERE usagedata.IHITEM = 50002
          AND CAST(usagedata.column4 AS VARCHAR(10)) = '50002'
    ) AS total_usage,
    ropdata.[#/ft] + (
        SELECT -SUM(usagedata.IHTQTY)
        FROM usagedata
        WHERE usagedata.IHITEM = 50002
          AND CAST(usagedata.column4 AS VARCHAR(10)) = '50002'
    ) AS net_consumption, 
    (ropdata.TotCons / ropdata.time ) as 'wk use', 
    sum(cast(cast(tagdata.remnants as varchar(10)) as float)), (ropdata.OnHand- ropdata.Rsrv) as 'Available', 
    ropdata.OnPO, ropdata.[Level], ropdata.Vndr, ropdata.time
    from ROPData, tagdata
    where ropdata.Item = 50002 and tagdata.Item = 50002;

--HERE WE GO!!!
SELECT 
    ropdata.item, ropdata.[Level],
    ropdata.Vndr,
    CAST(ropdata.comment AS VARCHAR(255)) AS comment,
    time = 26.1428571428571,
    ropdata.[#/ft],

    -- Total usage
    (
        SELECT -SUM(usagedata.IHTQTY)
        FROM usagedata
        WHERE usagedata.IHITEM = 50002
          AND CAST(usagedata.column4 AS VARCHAR(10)) = '50002'
    ) AS total_usage,

    -- Net consumption
    ropdata.[#/ft] + (
        SELECT -SUM(usagedata.IHTQTY)
        FROM usagedata
        WHERE usagedata.IHITEM = 50002
          AND CAST(usagedata.column4 AS VARCHAR(10)) = '50002'
    ) AS net_consumption,

    -- Weekly use
    (ropdata.TotCons / ropdata.time) AS [wk use],

    -- Total remnants from tagdata
    tagdata_sum.total_remnants,

    -- Available inventory
    (ropdata.OnHand - ropdata.Rsrv) AS [Available],
    ropdata.OnPO,
    ropdata.time

FROM 
    ROPData ropdata
CROSS APPLY (
    SELECT 
        SUM(CAST(CAST(remnants AS VARCHAR(100)) AS FLOAT)) AS total_remnants
    FROM tagdata
    WHERE tagdata.Item = 50002
) tagdata_sum
WHERE ropdata.Item = 50002;


----------------------
--HERE WE GO FOR THE FULL FAMILY
--select ropdata.item, ropdata.comment, * from ropdata where ropdata.Item in (50002)



--/////////////////////////////////////
-- 1. Get comment from ROPData
DECLARE @comment NVARCHAR(MAX)

SELECT @comment = CAST(comment AS VARCHAR(MAX))
FROM ROPData
WHERE Item = 50002;

-- 2. Parse bar items (extract after "!" and ignore anything with ":")
WITH RawParts AS (
    SELECT TRIM(value) AS val
    FROM STRING_SPLIT(@comment, '!')
    WHERE value <> ''
),
BarItems AS (
    SELECT TRY_CAST(LEFT(val, CHARINDEX(':', val + ':') - 1) AS INT) AS Item
    FROM RawParts
    WHERE TRY_CAST(LEFT(val, CHARINDEX(':', val + ':') - 1) AS INT) IS NOT NULL
)

-- 3. Final query for each bar item
SELECT 
    ropdata.Item,
    ropdata.[Level],
    ropdata.Vndr,
    CAST(ropdata.comment AS VARCHAR(255)) AS comment,
    time = 26.1428571428571,
    ropdata.[#/ft],

    -- Total usage
    (
        SELECT -SUM(usagedata.IHTQTY)
        FROM usagedata
        WHERE usagedata.IHITEM = ropdata.Item
          AND CAST(usagedata.column4 AS VARCHAR(10)) = CAST(ropdata.Item AS VARCHAR(10))
    ) AS total_usage,

    -- Net consumption
    ropdata.[#/ft] + (
        SELECT -SUM(usagedata.IHTQTY)
        FROM usagedata
        WHERE usagedata.IHITEM = ropdata.Item
          AND CAST(usagedata.column4 AS VARCHAR(10)) = CAST(ropdata.Item AS VARCHAR(10))
    ) AS net_consumption,

    -- Weekly use
    (ropdata.TotCons / ropdata.time) AS [wk use],

    -- Total remnants
    tagdata_sum.total_remnants,

    (ropdata.OnHand - ropdata.Rsrv) AS [Available],
    ropdata.OnPO,
    ropdata.time

FROM 
    BarItems
JOIN ROPData ropdata ON ropdata.Item = BarItems.Item
CROSS APPLY (
    SELECT 
        SUM(CAST(CAST(remnants AS VARCHAR(100)) AS FLOAT)) AS total_remnants
    FROM tagdata
    WHERE tagdata.Item = ropdata.Item
) tagdata_sum;


select * from ropdata where item = 50002;
use sigmatb;
select count(*) from ropdata;


SELECT 
    ropdata.Item,    ropdata.Description,    ropdata.[Size Text],    ropdata.Comment,    ropdata.OnHand,    ropdata.Rsrv,    SUM(TRY_CAST(tagdata.remnants AS FLOAT)) AS total_remnants,
    ropdata.[#/ft],    ropdata.[$/ft],    ropdata.Level,    ropdata.[con/wk],    ropdata.TotCons,    ropdata.OnPO,    ropdata.Vndr FROM ROPData ropdata
JOIN tagdata ON tagdata.Item = ropdata.Item
WHERE ropdata.Item = 50261
GROUP BY 
    ropdata.Item,    ropdata.Description,    ropdata.[Size Text],    ropdata.Comment,    ropdata.OnHand,    ropdata.Rsrv,    ropdata.[#/ft],    ropdata.[$/ft],    ropdata.Level,
    ropdata.[con/wk],    ropdata.TotCons,    ropdata.OnPO,    ropdata.Vndr;

--Purchase orders for an ITEM
select *  from POData where podata.Item = 50261

-- purchase orders useful data for an ITEM
select podata.due, podata.[Due Date], podata.Vendor, podata.PO, podata.Ordered, podata.Received, podata.Ordered  from POData where podata.Item = 50261

 SELECT 
       
    FROM tagdata
    WHERE tagdata.Item


SELECT 
    CAST(CAST(ROPData.[OnPO] AS VARCHAR(50)) AS FLOAT) AS [OnPO],
    tagdata.remnants, 
    ROPData.[Level],
    CAST(CAST(ROPData.[OnPO] AS VARCHAR(50)) AS FLOAT) / NULLIF(CAST(CAST(ROPData.[con/wk] AS VARCHAR(50)) AS FLOAT), 0) AS [PO Weeks],
    DATEADD(
        WEEK, 
        (
            CAST(CAST(ROPData.[OnHand] AS VARCHAR(50)) AS FLOAT)
            - CAST(CAST(ROPData.[Rsrv] AS VARCHAR(50)) AS FLOAT)
            + CAST(CAST(ROPData.[OnPO] AS VARCHAR(50)) AS FLOAT)
        ) / NULLIF(CAST(CAST(ROPData.[con/wk] AS VARCHAR(50)) AS FLOAT), 0),
        GETDATE()
    ) AS [New Depletion Date]
FROM 
    ROPData 
LEFT JOIN 
    tagdata ON ROPData.Item = tagdata.item
WHERE 
    ROPData.Item = 50261;

Use sigmatb;
select count(*) from GLTRANS
select *  from GLTRANS WHERE GLSYY = 25 AND GLSMM = 2 AND GLSDD = 04
    AND GLTRANS.GLDESC LIKE '%FAITH%';

  select max(glsyy) from GLTRANS

SELECT * FROM GLTRANS WHERE GLREF like '%965943%'
SELECT * FROM GLTRANS WHERE GLREF = '965943';

--Query to look like the excel
SELECT
    GLRECD AS Ext,
    FORMAT(GLCOMP, '00') + ' ' + 
    FORMAT(GLDIST, '00') + ' ' + 
    FORMAT(GLCSTC, '00') AS [CO DS CS],
    LEFT(CAST(GLACCT AS VARCHAR), 3) AS FS,
    GLACCT AS Account,
    GLDESC AS Title,
    FORMAT(GLPPYY, '00') + ' ' + FORMAT(GLPERD, '00') AS Period,
    '' AS [Transaction],  -- Not available in GLTRANS
    GLBTCH AS Reference,
    CASE 
        WHEN GLCRDB = 'D' THEN CAST(GLAMT AS decimal(12,2))
        ELSE CAST(-1 * GLAMT AS decimal(12,2))
    END AS Amount,
    GLAPPL AS APP,
    GLPGM AS Prgm,
    GLUSER AS [User],
    GLAPTR AS Related,
    GLTRN# AS [#],
    GLTRNT AS [Tran],
    GLTYPE AS Type,
    GLDIST AS Dist,
    GLREF AS Document,
    TRY_CAST(
        CAST(GLRFYY AS VARCHAR(4)) + '-' + 
        RIGHT('00' + CAST(GLRFMM AS VARCHAR(2)), 2) + '-' + 
        RIGHT('00' + CAST(GLRFDD AS VARCHAR(2)), 2) 
    AS DATE) AS Posting,
    NULL AS System,  -- Placeholder for system date or code
    FORMAT(GLCUST, '00 00000') AS Custmr
FROM GLTRANS
WHERE GLREF LIKE '%965943%'
ORDER BY GLTRN#;


SELECT
    GLRECD AS Ext,
    FORMAT(GLCOMP, '00') + ' ' + 
    FORMAT(GLDIST, '00') + ' ' + 
    FORMAT(GLCSTC, '00') AS [CO DS CS],
    LEFT(CAST(GLACCT AS VARCHAR), 3) AS FS,
    GLACCT AS Account,
    GLDESC AS Title,
    FORMAT(GLPPYY, '00') + ' ' + FORMAT(GLPERD, '00') AS Period,
    '' AS [Transaction],  -- Placeholder
    GLAPPL + RIGHT('00000000' + CAST(GLBTCH AS VARCHAR), 8) + '-0001' AS Reference,
    SUM(CASE 
            WHEN GLCRDB = 'D' THEN CAST(GLAMT AS decimal(12,2))
            ELSE -CAST(GLAMT AS decimal(12,2))
        END) AS NetAmount,
    GLAPPL AS APP,
    GLPGM AS Prgm,
    GLUSER AS [User],
    GLAPTR AS Related,
    GLTRN# AS [#],
    GLTRNT AS [Tran],
    GLTYPE AS Type,
    GLDIST AS Dist,
    GLBTCH AS Document,
    TRY_CAST(
        CAST(GLRFYY AS VARCHAR(4)) + '-' + 
        RIGHT('00' + CAST(GLRFMM AS VARCHAR(2)), 2) + '-' + 
        RIGHT('00' + CAST(GLRFDD AS VARCHAR(2)), 2) 
    AS DATE) AS Posting,
    NULL AS System,
    FORMAT(GLCUST, '00 00000') AS Custmr
FROM GLTRANS
WHERE GLREF LIKE '%965943%'
GROUP BY
    GLRECD,
    GLCOMP,
    GLDIST,
    GLCSTC,
    GLACCT,
    GLDESC,
    GLPPYY,
    GLPERD,
    GLAPPL,
    GLBTCH,
    GLPGM,
    GLUSER,
    GLAPTR,
    GLTRN#,
    GLTRNT,
    GLTYPE,
    GLRFYY,
    GLRFMM,
    GLRFDD,
    GLCUST
ORDER BY GLTRN#;


SELECT
    GLRECD AS Ext,
    FORMAT(GLCOMP, '00') + ' ' + 
    FORMAT(GLDIST, '00') + ' ' + 
    FORMAT(GLCSTC, '00') AS [CO DS CS],
    LEFT(CAST(GLACCT AS VARCHAR), 3) AS FS,
    GLACCT AS GLAccount_GLACCT,

    -- Title: show description only for revenue/cost accounts (e.g., 400s or 600s)
    CASE 
        WHEN LEFT(CAST(GLACCT AS VARCHAR), 1) IN ('4', '6') THEN GLDESC 
        ELSE NULL 
    END AS Title,

    FORMAT(GLPPYY, '00') + ' ' + FORMAT(GLPERD, '00') AS Period,

    -- Transaction: show customer name if account is 1021xxxxx
    CASE 
        WHEN LEFT(CAST(GLACCT AS VARCHAR), 4) = '1021' THEN GLDESC
        ELSE NULL
    END AS [Transaction],

    -- Constructed Reference value (APP + padded GLBTCH)
    GLAPPL + RIGHT('00000000' + CAST(GLBTCH AS VARCHAR), 8) + '-0001' AS Reference,

    SUM(CASE 
            WHEN GLCRDB = 'D' THEN CAST(GLAMT AS decimal(12,2))
            ELSE -CAST(GLAMT AS decimal(12,2))
        END) AS NetAmount,

    GLAPPL AS GRAP,
    GLPGM AS Prgm,
    GLUSER AS [User],
    GLAPTR AS Related,
    GLTRN# AS [#],
    GLTRNT AS [Tran],
    GLTYPE AS Type,
    GLDIST AS Dist,
    GLREF AS Document,

    TRY_CAST(
        CAST(GLRFYY AS VARCHAR(4)) + '-' + 
        RIGHT('00' + CAST(GLRFMM AS VARCHAR(2)), 2) + '-' + 
        RIGHT('00' + CAST(GLRFDD AS VARCHAR(2)), 2) 
    AS DATE) AS Posting,

    NULL AS System,
    FORMAT(GLCUST, '00 00000') AS Custmr

FROM GLTRANS
WHERE GLREF LIKE '%965943%'
GROUP BY
    GLRECD,    GLCOMP,    GLDIST,    GLCSTC,    GLACCT,    GLDESC,    GLPPYY,    GLPERD,    GLAPPL,    GLBTCH,    GLPGM,
    GLUSER,    GLAPTR,    GLTRN#,    GLTRNT,    GLTYPE,    GLREF,    GLRFYY,    GLRFMM,    GLRFDD,    GLCUST
ORDER BY GLTRN#;

/************************************************/
--Lets try to get the MP... this works but i will erase the sum and allow the query by account number
SELECT
    GLRECD AS Ext,
    FORMAT(GLCOMP, '00') + ' ' + 
    FORMAT(GLDIST, '00') + ' ' + 
    FORMAT(GLCSTC, '00') AS [CO DS CS],
    LEFT(CAST(GLACCT AS VARCHAR), 3) AS FS,
    GLACCT AS GLAccount_GLACCT,

    -- Desc, ref
    GLDESC AS Title_GLDESC, 
    [GLREF] as GLREF_Reference,
    
     -- Constructed Reference value (APP + padded GLBTCH)
    GLAPPL + RIGHT('00000000' + CAST(GLBTCH AS VARCHAR), 8) + '-0001' AS Reference,

    --Net amount
    SUM(CASE 
        WHEN GLCRDB = 'D' THEN CAST(GLAMT AS decimal(12,2))
        ELSE -CAST(GLAMT AS decimal(12,2))
    END) AS NetAmount,

    --app
    
    FORMAT(GLPPYY, '00') + ' ' + FORMAT(GLPERD, '00') AS Period,

    -- Transaction: show customer name if account is 1021xxxxx
    GLDESC as Transaction_GLDESC,
    GLAPPL AS GLAPPL_APP,
    GLPGM AS GLPGM_Prgm,
    GLUSER AS GLUSER,
    GLAPTR AS GLAPTR_Related,
    GLTRN# AS [GLTRN#],
    GLTRNT AS [GLTRNT_Tran],
    GLTYPE AS GLTYPE,
    GLDIST AS GLDIST,
    GLREF AS GLREF_Document,

    TRY_CAST(
        CAST(GLRFYY AS VARCHAR(4)) + '-' + 
        RIGHT('00' + CAST(GLRFMM AS VARCHAR(2)), 2) + '-' + 
        RIGHT('00' + CAST(GLRFDD AS VARCHAR(2)), 2) 
    AS DATE) AS Posting,

    NULL AS System,
    FORMAT(GLCUST, '00 00000') AS Custmr

FROM GLTRANS
WHERE GLREF LIKE '%965943%'
GROUP BY
    GLRECD,    GLCOMP,    GLDIST,    GLCSTC,    GLACCT,    GLDESC,    GLPPYY,    GLPERD,    GLAPPL,    GLBTCH,    GLPGM,
    GLUSER,    GLAPTR,    GLTRN#,    GLTRNT,    GLTYPE,    GLREF,    GLRFYY,    GLRFMM,    GLRFDD,    GLCUST
ORDER BY GLTRN#;


















/************************************************/

/************************************************/
--Lets try to get the MP... 
SELECT
    -- Desc, ref
    GLDESC AS Title_GLDESC, 
    --Net amount
    [GLCRDB], [GLAMT],

    GLACCT  AS GLACCT_FS,

    GLRECD AS Ext,
    FORMAT(GLCOMP, '00') + ' ' + 
    FORMAT(GLDIST, '00') + ' ' + 
    FORMAT(GLCSTC, '00') AS [CO DS CS],
    GLACCT AS GLAccount_GLACCT,


    [GLREF] as GLREF_Reference,
    
     -- Constructed Reference value (APP + padded GLBTCH)
    GLAPPL + RIGHT('00000000' + CAST(GLBTCH AS VARCHAR), 8) + '-0001' AS Reference,

    --app
    
    FORMAT(GLPPYY, '00') + ' ' + FORMAT(GLPERD, '00') AS Period,

    -- Transaction: show customer name if account is 1021xxxxx
    GLDESC as Transaction_GLDESC,
    GLAPPL AS GLAPPL_APP,
    GLPGM AS GLPGM_Prgm,
    GLUSER AS GLUSER,
    GLAPTR AS GLAPTR_Related,
    GLTRN# AS [GLTRN#],
    GLTRNT AS [GLTRNT_Tran],
    GLTYPE AS GLTYPE,
    GLDIST AS GLDIST,
    GLREF AS GLREF_Document,

    TRY_CAST(
        CAST(GLRFYY AS VARCHAR(4)) + '-' + 
        RIGHT('00' + CAST(GLRFMM AS VARCHAR(2)), 2) + '-' + 
        RIGHT('00' + CAST(GLRFDD AS VARCHAR(2)), 2) 
    AS DATE) AS Posting,

    NULL AS System,
    FORMAT(GLCUST, '00 00000') AS Custmr

FROM GLTRANS
WHERE GLREF LIKE '%965943%' AND LEFT(CAST(GLACCT AS VARCHAR), 1) IN ('4', '6')
GROUP BY
    GLRECD, GLCOMP, GLDIST, GLCSTC, GLACCT, GLDESC, GLPPYY, GLPERD, GLAPPL, GLBTCH, GLPGM,
    GLUSER, GLAPTR, GLTRN#, GLTRNT, GLTYPE, GLREF, GLRFYY, GLRFMM, GLRFDD, GLCUST,
    GLCRDB, GLAMT

ORDER BY GLTRN#;



















/************************************************/
-- Now I will try to add the description
use sigmatb;

SELECT
    -- Desc, ref
    GLDESC AS Title_GLDESC, 
    GLCRDB, GLAMT,

    GLT.GLACCT AS GLACCT_FS,
    GLRECD AS Ext,
    FORMAT(GLCOMP, '00') + ' ' + FORMAT(GLDIST, '00') + ' ' + FORMAT(GLCSTC, '00') AS [CO DS CS],
    GLT.GLACCT AS GLAccount_GLACCT,

    GLREF AS GLREF_Reference,
    GLAPPL + RIGHT('00000000' + CAST(GLBTCH AS VARCHAR), 8) + '-0001' AS Reference,

    -- Account description from GLACCT
    GLA.GACDES AS AccountDescription,

    FORMAT(GLPPYY, '00') + ' ' + FORMAT(GLPERD, '00') AS Period,

    GLDESC AS Transaction_GLDESC,
    GLAPPL AS GLAPPL_APP,
    GLPGM AS GLPGM_Prgm,
    GLUSER AS GLUSER,
    GLAPTR AS GLAPTR_Related,
    GLTRN# AS [GLTRN#],
    GLTRNT AS [GLTRNT_Tran],
    GLTYPE AS GLTYPE,
    GLDIST AS GLDIST,
    GLREF AS GLREF_Document,

    TRY_CAST(
        CAST(GLRFYY AS VARCHAR(4)) + '-' + 
        RIGHT('00' + CAST(GLRFMM AS VARCHAR(2)), 2) + '-' + 
        RIGHT('00' + CAST(GLRFDD AS VARCHAR(2)), 2) 
    AS DATE) AS Posting,

    NULL AS System,
    FORMAT(GLCUST, '00 00000') AS Custmr

FROM GLTRANS GLT
LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GLACCT

WHERE GLREF LIKE '%965943%' AND LEFT(CAST(GLT.GLACCT AS VARCHAR), 1) IN ('4', '6')

GROUP BY
    GLRECD, GLCOMP, GLDIST, GLCSTC, GLT.GLACCT, GLDESC, GLPPYY, GLPERD, GLAPPL, GLBTCH, GLPGM,
    GLUSER, GLAPTR, GLTRN#, GLTRNT, GLTYPE, GLREF, GLRFYY, GLRFMM, GLRFDD, GLCUST, GLCRDB, GLAMT,
    GLA.GACDES

ORDER BY GLTRN#;



/***************************************************/
use SigmaTB;

select * from GLTRANS WHERE GLTRANS.GLREF LIKE '%965943%'
select GLTRN#, GLREF, GLCUST, * from GLTRANS WHERE gltrn# = 0 AND [GLPYY] = 25 AND [GLPMM] = 2

select * from GLTRANS WHERE [GLAPPL]    LIKE '%IA%' AND GLPYY = 25 AND GLPMM = 2;

select count(*) from gltrans


-------lOOK FOR NULLS
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM GLTRANS 
            WHERE GLTRN# IS NULL
        )
        THEN 'Yes'
        ELSE 'No'
    END AS NullExists;



    select garp3, * from GLACCT


/***********************************************************************
-- This query reproduces the sales and cost analysis per sales order, on the General Ledger
***********************************************************************/
SELECT 
    SUM(CASE WHEN GLA.GARP3 = 30 THEN GLT.GLAMT ELSE 0 END) AS Total_Sales,
    SUM(CASE WHEN GLA.GACDES = 'MATERIAL SALES' THEN GLT.GLAMT ELSE 0 END) AS Material_Sales,
    SUM(CASE WHEN GLA.GACDES = 'OUTSIDE PROCESSING SALES' THEN GLT.GLAMT ELSE 0 END) AS Processing_Sales,
    SUM(CASE WHEN GLA.GARP3 = 50 THEN GLT.GLAMT ELSE 0 END) AS Material_Cost,
    SUM(CASE WHEN GLA.GARP3 = 175 AND GLAPPL NOT IN ('AP') THEN GLT.GLAMT ELSE 0 END) AS Processing_Cost,
    SUM(CASE WHEN gla.gacct = 4103600000 THEN GLT.GLAMT ELSE 0 END) AS PurchasePriceVariance
FROM GLTRANS GLT
LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
WHERE 
    GLT.[GLTRN#] = 965943
    AND GLA.GARP3 IN (30, 50, 500, 530, 600, 610, 175)
    AND GLT.GLAPPL NOT IN ('IU', 'CR');


select * from GLACCT GLA where gla.gacdes like '%COGS - PROCESSING PUR PRICE VARIANC%'
select * from GLACCT GLA where gla.gacct = 4103600000