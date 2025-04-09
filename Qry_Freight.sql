Use SigmaTB;

SELECT * FROM SalesData;
SELECT count(*) FROM SalesData;

Select * from SalesOrders
select count(*) from SalesOrders
select * from Salesorders where Cast(Invoiced as date) between '01/01/2025' and '12/01/2025'

-- Get the rows
SELECT *
FROM Salesorders
WHERE CONVERT(date, CAST(Invoiced AS CHAR(8)), 112) 
      BETWEEN '2025-01-01' AND '2025-12-01';

-- all sales order detail
SELECT *, CONVERT(date, CAST(Invoiced AS CHAR(8)), 112) AS InvoicedDate
FROM Salesorders
WHERE CONVERT(date, CAST(Invoiced AS CHAR(8)), 112) 
      BETWEEN '2025-02-01' AND '2025-02-28';

--February sales + frt sales total
select sum(sales) + sum([Frt Sales])
FROM Salesorders
WHERE CONVERT(date, CAST(Invoiced AS CHAR(8)), 112) 
      BETWEEN '2025-02-01' AND '2025-02-28';

--February sales total
select sum(sales) as 'Sales', sum(Salesorders.Profit) as 'Gross Profit' 
FROM Salesorders
WHERE CONVERT(date, CAST(Invoiced AS CHAR(8)), 112) 
      BETWEEN '2025-02-01' AND '2025-02-28';




--Lets gonna check if we find the salesorders
-- This is the query from SalesOrder report that populates the salesorder worksheet
SELECT  oddist*1000000+odordr,                      -- Order ID
        SALESMAN.SMNAME,                            -- Sales man name
        OEOPNORD.OOTYPE,                            -- Order type
        odcdis*100000+odcust,                       -- distributor + customer
        ARCUST.CALPHA,                              -- Name of the customer
        OOICC*1000000+OOIYY*10000+OOIMM*100+OOIDD,  -- Cost center + YY, MM, DD
        OEDETAIL.ODITEM,                            -- ITEM
        OEDETAIL.ODSIZ1,                            -- SIZES  
        OEDETAIL.ODSIZ2, 
        OEDETAIL.ODSIZ3, 
        OEDETAIL.ODCRTD,                            -- Order Created Date
        SLSDSCOV.DXDSC2,                            -- Sales Description
        OEDETAIL.ODTFTS,                            -- Feet
        OEDETAIL.ODTLBS,                            -- Pounds
        OEDETAIL.ODTPCS,                            -- Pieces
        OEDETAIL.ODSLSX,                            -- Sales extended???
        OEDETAIL.ODFRTS,                            -- Freight charges   
        OEDETAIL.ODCSTX,                            -- Cost ???
        OEDETAIL.ODPRCC,                            -- Price
        OEDETAIL.ODADCC,                            -- Additional charges
        OEDETAIL.ODWCCS,                            -- Weight cost
        ARCUST.CSTAT,                               -- Customer state
        ARCUST.CCTRY                                -- Customer Country
FROM    S219EAAV.MW4FILE.ARCUST ARCUST,             -- Account Receivable - customer
        S219EAAV.MW4FILE.OEDETAIL OEDETAIL,         -- Order Entry - detail
        S219EAAV.MW4FILE.OEOPNORD OEOPNORD,         -- Order Entry - Order Processing - 
        S219EAAV.MW4FILE.SALESMAN SALESMAN,         -- Salesman
        S219EAAV.MW4FILE.SLSDSCOV SLSDSCOV          -- Distributor
WHERE   OEDETAIL.ODDIST = OEOPNORD.OODIST           
        AND OEDETAIL.ODDIST = SLSDSCOV.DXDIST 
        AND OEDETAIL.ODMLIN = SLSDSCOV.DXMLIN 
        AND OEDETAIL.ODORDR = OEOPNORD.OOORDR 
        AND OEDETAIL.ODORDR = SLSDSCOV.DXORDR 
        AND OEOPNORD.OOCDIS = ARCUST.CDIST 
        AND OEOPNORD.OOCUST = ARCUST.CCUST 
        AND OEOPNORD.OOISMD = SALESMAN.SMDIST 
        AND OEOPNORD.OOISMN = SALESMAN.SMSMAN 
        AND ((OEOPNORD.OOTYPE In ('A','B')) 
        AND (OEOPNORD.OORECD='W') 
        AND (ooicc*10000+ooiyy*100+ooimm Between 20250201 And 20250228))



--Lets gonna try our query in our SQL Server
SELECT top 1
    OEDETAIL.ODDIST * 1000000 + OEDETAIL.ODORDR AS OrderID,
    SALESMAN.SMNAME AS SalesmanName,
    OEOPNORD.OOTYPE AS OrderType,
    OEOPNORD.OOCDIS * 100000 + OEOPNORD.OOCUST AS DistributorCustomer,
    ARCUST.CALPHA AS CustomerName,
    OEOPNORD.OOICC * 1000000 + OEOPNORD.OOIYY * 10000 + OEOPNORD.OOIMM * 100 + OEOPNORD.OOIDD AS OrderDateKey,
    OEDETAIL.ODITEM,
    OEDETAIL.ODSIZ1,
    OEDETAIL.ODSIZ2,
    OEDETAIL.ODSIZ3,
    OEDETAIL.ODCRTD AS OrderCreatedDate,
    SLSDSCOV.DXDSC2 AS SalesDescription,
    OEDETAIL.ODTFTS AS Feet,
    OEDETAIL.ODTLBS AS Pounds,
    OEDETAIL.ODTPCS AS Pieces,
    OEDETAIL.ODSLSX AS ExtendedSales,
    OEDETAIL.ODFRTS AS FreightCharges,
    OEDETAIL.ODCSTX AS Cost,
    OEDETAIL.ODPRCC AS Price,
    OEDETAIL.ODADCC AS AdditionalCharges,
    OEDETAIL.ODWCCS AS WeightCost,
    ARCUST.CSTAT AS CustomerState,
    ARCUST.CCTRY AS CustomerCountry
FROM 
    ARCUST
INNER JOIN OEOPNORD ON 
    OEOPNORD.OOCDIS = ARCUST.CDIST AND 
    OEOPNORD.OOCUST = ARCUST.CCUST
INNER JOIN SALESMAN ON 
    OEOPNORD.OOISMD = SALESMAN.SMDIST AND 
    OEOPNORD.OOISMN = SALESMAN.SMSMAN
INNER JOIN OEDETAIL ON 
    OEDETAIL.ODDIST = OEOPNORD.OODIST AND 
    OEDETAIL.ODORDR = OEOPNORD.OOORDR
INNER JOIN SLSDSCOV ON 
    OEDETAIL.ODDIST = SLSDSCOV.DXDIST AND 
    OEDETAIL.ODORDR = SLSDSCOV.DXORDR AND 
    OEDETAIL.ODMLIN = SLSDSCOV.DXMLIN
WHERE 
    OEOPNORD.OOTYPE IN ('A', 'B') AND
    OEOPNORD.OORECD = 'W' AND
    (OEOPNORD.OOIYY = 25 AND OEOPNORD.OOIMM = 2)


--Lets gonna look for OrderID = Document
--Error. Costs are not right
SELECT 
    OEDETAIL.ODDIST * 1000000 + OEDETAIL.ODORDR AS OrderID,
    SALESMAN.SMNAME AS SalesmanName,
    OEOPNORD.OOTYPE AS OrderType,
    OEOPNORD.OOCDIS * 100000 + OEOPNORD.OOCUST AS DistributorCustomer,
    ARCUST.CALPHA AS CustomerName,
    OEOPNORD.OOICC * 1000000 + OEOPNORD.OOIYY * 10000 + OEOPNORD.OOIMM * 100 + OEOPNORD.OOIDD AS OrderDateKey,
    OEDETAIL.ODITEM,
    OEDETAIL.ODSIZ1,
    OEDETAIL.ODSIZ2,
    OEDETAIL.ODSIZ3,
    OEDETAIL.ODCRTD AS [Size],
    SLSDSCOV.DXDSC2 AS [Specification],
    OEDETAIL.ODTFTS AS Feet,
    OEDETAIL.ODTLBS AS Pounds,
    OEDETAIL.ODTPCS AS Pieces,
    OEDETAIL.ODSLSX AS TotalSales,
    OEDETAIL.ODFRTS AS FreightCharges,
    OEDETAIL.ODCSTX AS MaterialCost,
    OEDETAIL.ODPRCC AS UNKNOWNPrice,
    OEDETAIL.ODADCC AS AdditionalCharges,
    OEDETAIL.ODWCCS AS WeightCost,
    ARCUST.CSTAT AS CustomerState,
    ARCUST.CCTRY AS CustomerCountry
FROM 
    ARCUST
INNER JOIN OEOPNORD ON 
    OEOPNORD.OOCDIS = ARCUST.CDIST AND 
    OEOPNORD.OOCUST = ARCUST.CCUST
INNER JOIN SALESMAN ON 
    OEOPNORD.OOISMD = SALESMAN.SMDIST AND 
    OEOPNORD.OOISMN = SALESMAN.SMSMAN
INNER JOIN OEDETAIL ON 
    OEDETAIL.ODDIST = OEOPNORD.OODIST AND 
    OEDETAIL.ODORDR = OEOPNORD.OOORDR
INNER JOIN SLSDSCOV ON 
    OEDETAIL.ODDIST = SLSDSCOV.DXDIST AND 
    OEDETAIL.ODORDR = SLSDSCOV.DXORDR AND 
    OEDETAIL.ODMLIN = SLSDSCOV.DXMLIN
WHERE 
    (OEDETAIL.ODORDR =  965943 )


select * from OEDETAIL WHERE ORDETAIL.OR

--Let's find the order from the Financial Statements
USE SigmaTB;
SELECT * from [dbo].[Query_GL] where [Query_GL].[GLTRN#]= 965481;
select top 1000 * from query_gl

GLRECD,[CO DS CS] [GARP3][GLACCT][GACDES][Period][GLDESC][GLREF][GLAMTQ][GLAPPL][GLPGM][GLUSER][GLRPTY][GLRP#][GLTRNT][GLTYPE][GLTRDS][GLTRN#][Posting]


/**********************************************************************************/
--LETS GET THE MP
/**********************************************************************************/

USE SigmaTB;

DECLARE @RefFilter VARCHAR(20);
SET @RefFilter = '%965943%';    --965943

SELECT
    -- Desc, ref
    GLDESC AS Title_GLDESC, 
    GLAMT,
    GLA.GARP3 as GARP3_FS,
    GLAPPL AS GLAPPL_APP,

    -- Account description from GLACCT
    GLA.GACDES AS GACDES_AccountDescription,
   
    FORMAT(GLCOMP, '00') + ' ' + FORMAT(GLDIST, '00') + ' ' + FORMAT(GLCSTC, '00') AS [CO DS CS],
    GLT.GLACCT AS GLAccount_GLACCT,

    GLREF AS GLREF_Reference,
    GLAPPL + RIGHT('00000000' + CAST(GLBTCH AS VARCHAR), 8) + '-0001' AS Reference,

    FORMAT(GLPPYY, '00') + ' ' + FORMAT(GLPERD, '00') AS Period,

    GLDESC AS Transaction_GLDESC,
    GLPGM AS GLPGM_Prgm,
    GLUSER AS GLUSER,
    GLAPTR AS GLAPTR_Related,
    GLTRN# AS [GLTRN#],
    GLTRNT AS [GLTRNT_Tran],
    GLTYPE AS GLTYPE,
    GLDIST AS GLDIST,
    GLREF AS GLREF_Document,
    GLCRDB,
    GLT.GLACCT AS GLACCT_FS,
    GLRECD AS Ext,

    TRY_CAST(
        CAST(GLRFYY AS VARCHAR(4)) + '-' + 
        RIGHT('00' + CAST(GLRFMM AS VARCHAR(2)), 2) + '-' + 
        RIGHT('00' + CAST(GLRFDD AS VARCHAR(2)), 2) 
    AS DATE) AS Posting,

    NULL AS System,
    FORMAT(GLCUST, '00 00000') AS Custmr

FROM GLTRANS GLT
LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT

--WHERE GLREF LIKE '%965943%' AND LEFT(CAST(GLT.GLACCT AS VARCHAR), 1) IN ('4', '6')
WHERE GLREF LIKE @RefFilter AND GLA.GARP3 in (500,600)

GROUP BY
    GLRECD, GLCOMP, GLDIST, GLCSTC, GLT.GLACCT, GLDESC, GLPPYY, GLPERD, GLAPPL, GLBTCH, GLPGM,
    GLUSER, GLAPTR, GLTRN#, GLTRNT, GLTYPE, GLREF, GLRFYY, GLRFMM, GLRFDD, GLCUST, GLCRDB, GLAMT,
    GLA.GACDES, GLA.GARP3

ORDER BY GLTRN#;

/**********************************************************************************/
/**********************************************************************************/

select count(*) from gltrans

/**********************************************************************************/
--Lets find Cash Receipts for 25k for Feb, 2025
/**********************************************************************************/

USE SigmaTB;

DECLARE @RefFilter VARCHAR(15);
SET @RefFilter = '%965943%';    --965943

SELECT
    -- Desc, ref
    GLDESC AS Title_GLDESC, 
    GLAMT,
    GLA.GARP3 as GARP3_FS,      -- Financial Statement account
    GLAPPL AS GLAPPL_APP,       -- Accounts payable (IN, CR, PO)

    -- Account description from GLACCT
    GLA.GACDES AS GACDES_AccountDescription,    --Description of the transaction
   
    FORMAT(GLCOMP, '00') + ' ' + FORMAT(GLDIST, '00') + ' ' + FORMAT(GLCSTC, '00') AS [CO DS CS],
    GLT.GLACCT AS GLAccount_GLACCT,

    GLREF AS GLREF_Reference,
    GLAPPL + RIGHT('00000000' + CAST(GLBTCH AS VARCHAR), 8) + '-0001' AS Reference,

    FORMAT(GLPPYY, '00') + ' ' + FORMAT(GLPERD, '00') AS Period,

    GLDESC AS Transaction_GLDESC,
    GLPGM AS GLPGM_Prgm,
    GLUSER AS GLUSER,
    GLAPTR AS GLAPTR_Related,
    GLTRN# AS [GLTRN#],
    GLTRNT AS [GLTRNT_Tran],
    GLTYPE AS GLTYPE,
    GLDIST AS GLDIST,
    GLREF AS GLREF_Document,
    GLCRDB,
    GLT.GLACCT AS GLACCT_FS,
    GLRECD AS Ext,

    TRY_CAST(
        CAST(GLRFYY AS VARCHAR(4)) + '-' + 
        RIGHT('00' + CAST(GLRFMM AS VARCHAR(2)), 2) + '-' + 
        RIGHT('00' + CAST(GLRFDD AS VARCHAR(2)), 2) 
    AS DATE) AS Posting,

    NULL AS System,
    FORMAT(GLCUST, '00 00000') AS Custmr

FROM GLTRANS GLT
LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT

--WHERE GLREF LIKE '%965943%' AND LEFT(CAST(GLT.GLACCT AS VARCHAR), 1) IN ('4', '6')
WHERE RTRIM(GLREF) like @RefFilter AND GLA.GARP3 in (500,600)


GROUP BY
    GLRECD, GLCOMP, GLDIST, GLCSTC, GLT.GLACCT, GLDESC, GLPPYY, GLPERD, GLAPPL, GLBTCH, GLPGM,
    GLUSER, GLAPTR, GLTRN#, GLTRNT, GLTYPE, GLREF, GLRFYY, GLRFMM, GLRFDD, GLCUST, GLCRDB, GLAMT,
    GLA.GACDES, GLA.GARP3

ORDER BY GLTRN#;



select GLREF from GLTRANS;

ALTER TABLE GLTRANS
ADD GLREF_CLEAN AS RTRIM(GLREF) PERSISTED;

CREATE INDEX IX_GLREF_CLEAN ON GLTRANS(GLREF_CLEAN);
/**********************/

SELECT TOP 100
    GLREF, 
    LEN(GLREF) AS Length,
    '[' + GLREF + ']' AS VisibleWithBrackets
FROM GLTRANS
ORDER BY LEN(GLREF) DESC;

-- We check the index
select TOP 10000 
    GLREF_REV
FROM GLTRANS

/***************/

--we check if the index has data
SELECT TOP 10 GLREF, GLREF_REV 
FROM GLTRANS 
WHERE GLREF IS NOT NULL;



-- List all columns in GLTRANS
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    CHARACTER_MAXIMUM_LENGTH, 
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'GLTRANS';

-- Get the index info
SELECT 
    i.name AS IndexName,
    i.type_desc AS IndexType,
    c.name AS ColumnName,
    ic.key_ordinal AS OrdinalPosition,
    ic.is_descending_key AS IsDescending
FROM sys.indexes i
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE i.object_id = OBJECT_ID('GLTRANS')
ORDER BY i.name, ic.key_ordinal;



--QUERY USING THE FAST INDEXES
USE SigmaTB;

DECLARE @RefFilter VARCHAR(15);
SET @RefFilter = '965943';  -- without %!

SELECT
    -- Desc, ref
    GLDESC AS Title_GLDESC, 
    GLAMT,
    GLA.GARP3 as GARP3_FS,      
    GLAPPL AS GLAPPL_APP,       

    -- Account description from GLACCT
    GLA.GACDES AS GACDES_AccountDescription,
   
    FORMAT(GLCOMP, '00') + ' ' + FORMAT(GLDIST, '00') + ' ' + FORMAT(GLCSTC, '00') AS [CO DS CS],
    GLT.GLACCT AS GLAccount_GLACCT,

    GLREF AS GLREF_Reference,
    GLAPPL + RIGHT('00000000' + CAST(GLBTCH AS VARCHAR), 8) + '-0001' AS Reference,

    FORMAT(GLPPYY, '00') + ' ' + FORMAT(GLPERD, '00') AS Period,

    GLDESC AS Transaction_GLDESC,
    GLPGM AS GLPGM_Prgm,
    GLUSER AS GLUSER,
    GLAPTR AS GLAPTR_Related,
    GLTRN# AS [GLTRN#],
    GLTRNT AS [GLTRNT_Tran],
    GLTYPE AS GLTYPE,
    GLDIST AS GLDIST,
    GLREF AS GLREF_Document,
    GLCRDB,
    GLT.GLACCT AS GLACCT_FS,
    GLRECD AS Ext,

    TRY_CAST(
        CAST(GLRFYY AS VARCHAR(4)) + '-' + 
        RIGHT('00' + CAST(GLRFMM AS VARCHAR(2)), 2) + '-' + 
        RIGHT('00' + CAST(GLRFDD AS VARCHAR(2)), 2) 
    AS DATE) AS Posting,

    NULL AS System,
    FORMAT(GLCUST, '00 00000') AS Custmr

FROM GLTRANS GLT
LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT

-- ✅ Optimized filtering using index on GLREF_REV
WHERE GLREF_REV LIKE REVERSE(@RefFilter) + '%' 
  AND GLA.GARP3 IN (500, 600)

GROUP BY
    GLRECD, GLCOMP, GLDIST, GLCSTC, GLT.GLACCT, GLDESC, GLPPYY, GLPERD, GLAPPL, GLBTCH, GLPGM,
    GLUSER, GLAPTR, GLTRN#, GLTRNT, GLTYPE, GLREF, GLRFYY, GLRFMM, GLRFDD, GLCUST, GLCRDB, GLAMT,
    GLA.GACDES, GLA.GARP3

ORDER BY GLTRN#;


--Lets confirm if we have the index working
SELECT TOP 20 GLREF, GLREF_REV FROM GLTRANS
WHERE GLREF IS NOT NULL AND GLREF_REV IS NULL;

--Diagnose
SELECT TOP 20 GLREF, GLREF_REV 
FROM GLTRANS 
WHERE GLREF_REV LIKE '%34969%'  -- reverse of 965943

--Lets check the standardized version
SELECT *
FROM GLTRANS
WHERE GLREF_REV = REVERSE('0E01896943–0001')


--Lets try the performance
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT *
FROM GLTRANS
WHERE GLREF_REV = REVERSE('965943')

/************************************************/
--FINANCIAL QUERIES
/************************************************/

--Identify total sales 
select SUM(GLT.[GLAMT]) as SalesfromFS
FROM GLTRANS GLT
LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
WHERE GLT.GLAPPL in ('IN') AND GLA.GARP3 IN (500, 530) and [GLPYY] = 25 AND [GLPMM]=2
    

--Identify total sales 
select SUM(GLT.[GLAMT]) as SalesfromFS
FROM GLTRANS GLT
LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
WHERE GLT.GLAPPL in ('IN') AND GLA.GARP3 IN (500, 530) and [GLPYY] = 25 AND [GLPMM]=2

-- Februay Sales Detail
    SELECT 
        OEDETAIL.ODDIST * 1000000 + OEDETAIL.ODORDR AS OrderID,                                     -- ORDER ID
        SALESMAN.SMNAME AS SalesmanName,                                                            -- SALESMAN
        OEOPNORD.OOTYPE AS OrderType,                                                               -- Order type
        OEOPNORD.OOCDIS * 100000 + OEOPNORD.OOCUST AS DistributorCustomer,                          -- Customer
        ARCUST.CALPHA AS CustomerName,                                                              -- Customer name
        OEOPNORD.OOICC * 1000000 + OEOPNORD.OOIYY * 10000 + OEOPNORD.OOIMM * 100 + OEOPNORD.OOIDD AS OrderDateKey,  -- Order date
        OEDETAIL.ODITEM,                                                                            -- ITEM
        OEDETAIL.ODSIZ1,        
        OEDETAIL.ODSIZ2,        
        OEDETAIL.ODSIZ3,        
        OEDETAIL.ODCRTD AS [Size],                                                                  -- Size
        SLSDSCOV.DXDSC2 AS [Specification],                                                         -- Specification
        OEDETAIL.ODTFTS AS Feet,                                                            
        OEDETAIL.ODTLBS AS Pounds,
        OEDETAIL.ODTPCS AS Pieces,
        OEDETAIL.ODSLSX AS TotalSales,
        OEDETAIL.ODFRTS AS FreightCharges,
        OEDETAIL.ODCSTX AS MaterialCost,
        OEDETAIL.ODPRCC AS ProcessingCost,
        OEDETAIL.ODADCC AS AdditionalCharges,
        OEDETAIL.ODWCCS AS WeightCost,
        ARCUST.CSTAT AS CustomerState,
        ARCUST.CCTRY AS CustomerCountry
    FROM 
        ARCUST                                                                                      
    INNER JOIN OEOPNORD ON                                                          
        OEOPNORD.OOCDIS = ARCUST.CDIST AND                                                          
        OEOPNORD.OOCUST = ARCUST.CCUST                                                          
    INNER JOIN SALESMAN ON 
        OEOPNORD.OOISMD = SALESMAN.SMDIST AND 
        OEOPNORD.OOISMN = SALESMAN.SMSMAN
    INNER JOIN OEDETAIL ON 
        OEDETAIL.ODDIST = OEOPNORD.OODIST AND 
        OEDETAIL.ODORDR = OEOPNORD.OOORDR
    INNER JOIN SLSDSCOV ON 
        OEDETAIL.ODDIST = SLSDSCOV.DXDIST AND 
        OEDETAIL.ODORDR = SLSDSCOV.DXORDR AND 
        OEDETAIL.ODMLIN = SLSDSCOV.DXMLIN
    WHERE 
        OEOPNORD.OOIYY = 25 AND OEOPNORD.OOIMM = 2
        --OEDETAIL.ODORDR = {order_number}                                                            

/**************************************************************************************/
-- Februay Sales Total from Sales Report
/**************************************************************************************/
    SELECT 
        SUM(OEDETAIL.ODSLSX) AS TotalSales,                                                              -- Total Sales
        SUM(OEDETAIL.ODFRTS) AS TotalFreightCharges,                                                          -- Total Freight
        SUM(OEDETAIL.ODCSTX) AS TotalMaterialCost,                                                            -- Total material cost
        SUM(OEDETAIL.ODPRCC) AS TotalProcessingPrice,                                                            -- Unknown  
        SUM(OEDETAIL.ODADCC) AS TotalAdditionalCharges,                                                       -- Additional
        SUM(OEDETAIL.ODWCCS) AS TotalWeightCost                                                               -- Weight
    FROM 
        ARCUST                                                                                      
    INNER JOIN OEOPNORD ON                                                          
        OEOPNORD.OOCDIS = ARCUST.CDIST AND                                                          
        OEOPNORD.OOCUST = ARCUST.CCUST                                                          
    INNER JOIN SALESMAN ON 
        OEOPNORD.OOISMD = SALESMAN.SMDIST AND 
        OEOPNORD.OOISMN = SALESMAN.SMSMAN
    INNER JOIN OEDETAIL ON 
        OEDETAIL.ODDIST = OEOPNORD.OODIST AND 
        OEDETAIL.ODORDR = OEOPNORD.OOORDR
    INNER JOIN SLSDSCOV ON 
        OEDETAIL.ODDIST = SLSDSCOV.DXDIST AND 
        OEDETAIL.ODORDR = SLSDSCOV.DXORDR AND 
        OEDETAIL.ODMLIN = SLSDSCOV.DXMLIN
    WHERE 
        OEOPNORD.OOIYY = 25 AND OEOPNORD.OOIMM = 2
        --OEDETAIL.ODORDR = {order_number}     

/**************************************************************************************/
-- Februay Sales Total from General Ledger
/**************************************************************************************/
    SELECT
        CAST(GARP3 AS VARCHAR(10)) AS GARP3,
        CAST(GA.GACCT AS VARCHAR(20)) AS GACCT,
        GA.GACDES AS AccountDescription,
        SUM(GL.GLAMTQ) AS TotalAmount
    FROM GLTRANS GL
    LEFT JOIN GLACCT GA ON GL.GLACCT = GA.GACCT
    WHERE [GLPYY] = 25 AND [GLPMM] = 2
    AND GARP3 IN (600, 610, 0)
    GROUP BY GARP3, GA.GACCT, GA.GACDES

    UNION ALL

    SELECT
        'TOTAL' AS GARP3,
        'TOTAL' AS GACCT,
        '🧮 Total' AS AccountDescription,
        SUM(GL.GLAMTQ) AS TotalAmount
    FROM GLTRANS GL
    LEFT JOIN GLACCT GA ON GL.GLACCT = GA.GACCT
    WHERE [GLPYY] = 25 AND [GLPMM] = 2
    AND GARP3 IN (600, 610, 0)

    ORDER BY GACCT;

--------------
-- lets find out what to select
    SELECT
        CAST(GARP3 AS VARCHAR(10)) AS GARP3,
        CAST(GA.GACCT AS VARCHAR(20)) AS GACCT,
        GA.GACDES AS AccountDescription,
        SUM(GL.GLAMTQ) AS TotalAmount
    FROM GLTRANS GL
    LEFT JOIN GLACCT GA ON GL.GLACCT = GA.GACCT
    WHERE [GLPYY] = 25 AND [GLPMM] = 2
    AND GARP3 IN (600, 610, 0)
    AND [GLREF] LIKE '%965943%'
    GROUP BY GARP3, GA.GACCT, GA.GACDES

    UNION ALL

    SELECT
        'TOTAL' AS GARP3,
        'TOTAL' AS GACCT,
        '🧮 Total' AS AccountDescription,
        SUM(GL.GLAMTQ) AS TotalAmount
    FROM GLTRANS GL
    LEFT JOIN GLACCT GA ON GL.GLACCT = GA.GACCT
    WHERE [GLPYY] = 25 AND [GLPMM] = 2
    AND GARP3 IN (600, 610, 0)

    ORDER BY GACCT;




/**************************************************************************************/
-- 
/**************************************************************************************/
--We identify the credits
select SUM(GLT.[GLAMT])
FROM GLTRANS GLT
LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
WHERE GLT.GLAPPL in ('CR') AND GLA.GARP3 IN (500, 600) and [GLPYY] = 25 AND [GLPMM]=2

--We identify the COGS
select SUM(GLT.[GLAMT])
FROM GLTRANS GLT
LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
WHERE [GLPYY] = 25 AND [GLPMM]=2 AND   GLA.GARP3 IN (600, 610) 


select GARP3, GACDES, (GLT.[GLAMT]), GLREF, GLTRNT, GLAMTQ, GACCT,   GAAR3
FROM GLTRANS GLT
LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
WHERE [GLPYY] = 25 AND [GLPMM]=2 AND   GLA.GARP3 IN (600, 610) 

--Lets identify transactions without document
select GARP3, GACDES, (GLT.[GLAMT]), GLREF, [GLTRN#]
FROM GLTRANS GLT
LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
WHERE [GLPYY] = 25 AND [GLPMM]=2 AND  (GLT.GLTRN# IS NULL OR GLT.GLTRN# = 0);

select GLT.GLAPPL, SUM( (GLT.[GLAMT]))
FROM GLTRANS GLT
LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
WHERE [GLPYY] = 25 AND [GLPMM]=2 AND  (GLT.GLTRN# IS NULL OR GLT.GLTRN# = 0) AND   GLA.GARP3 IN (600, 610) 
GROUP BY GLT.GLAPPL;




-----------------------------------------------
--ACCOUNTS PER GL
SELECT  GARP3, GACDES, GACCT FROM GLACCT
-----------------------------------------------

select TOP 100 * -- (GLT.[GLAMT])
FROM GLTRANS GLT
LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
WHERE [GLPYY] = 25 AND [GLPMM]=2 AND   GLA.GARP3 IN (600, 610) 


AND GLT.GLAPPL in ('CR', 'IN')

--Table structure
select top 1 *
from GLTRANS GLT
LEFT JOIN GLACCT GLA 
    ON GLT.GLACCT = GLA.GACCT
WHERE GLT.GLAPPL in ('CR') AND GLA.GARP3 IN (500, 600) and [GLPYY] = 25 AND [GLPMM]=2

--Group reason (Write off). 
select [GLCUST], gldesc, SUM(GLT.[GLAMT])
FROM GLTRANS GLT
LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
WHERE GLT.GLAPPL in ('CR') AND GLA.GARP3 IN (500, 600) and [GLPYY] = 25 AND [GLPMM]=2
GROUP BY [GLCUST], GLDESC;            --Group by customer


/*+++++++++++++++++++++++++++++++++++++++++++++++++
--How are distributed the credits, by customer, and by order
***************************************************/

SELECT 
    ARCUST.CALPHA AS CustomerName,
    COUNT(DISTINCT GLT.GLTRN#) AS CreditOrderCount,
    SUM(GLT.GLAMT) AS TotalCredits,
    ISNULL(Sales.TotalSales, 0) AS TotalSales,
    CASE 
        WHEN ISNULL(Sales.TotalSales, 0) = 0 THEN NULL
        ELSE ROUND(SUM(GLT.GLAMT) * 1.0 / Sales.TotalSales, 2)
    END AS CreditRatio
FROM GLTRANS GLT
LEFT JOIN GLACCT GLA 
    ON GLT.GLACCT = GLA.GACCT
LEFT JOIN ARCUST 
    ON GLT.GLCUST = ARCUST.CCUST
-- Join to pull in total sales per customer
LEFT JOIN (
    SELECT 
        GLCUST,
        SUM(GLAMT) AS TotalSales
    FROM GLTRANS
    LEFT JOIN GLACCT ON GLTRANS.GLACCT = GLACCT.GACCT
    WHERE 
        GLAPPL IN ('IN') 
        AND GARP3 BETWEEN 500 AND 599
        AND GLPYY = 25 AND GLPMM = 2
    GROUP BY GLCUST
) AS Sales ON GLT.GLCUST = Sales.GLCUST
WHERE 
    GLT.GLAPPL IN ('CR') 
    AND GLA.GARP3 IN (500, 600) 
    AND GLT.GLPYY = 25 
    AND GLT.GLPMM = 2
GROUP BY 
    ARCUST.CALPHA, Sales.TotalSales
ORDER BY 
    TotalCredits DESC;

/*SELECT 
    ARCUST.CALPHA AS CustomerName,
    COUNT(DISTINCT GLT.GLTRN#) AS OrderCount,
    SUM(GLT.GLAMT) AS TotalCredits
FROM GLTRANS GLT
LEFT JOIN GLACCT GLA 
    ON GLT.GLACCT = GLA.GACCT
LEFT JOIN ARCUST 
    ON GLT.GLCUST = ARCUST.CCUST
WHERE 
    GLT.GLAPPL IN ('CR') 
    AND GLA.GARP3 IN (500, 600) 
    AND GLT.GLPYY = 25 
    AND GLT.GLPMM = 2
GROUP BY 
    ARCUST.CALPHA
ORDER BY 
    TotalCredits DESC;*/

--I want to know what customer and what salesman does the most credits. 
--BAD QUERY
/*SELECT 
    SM.SMNAME AS SalesmanName,
    SUM(GLT.GLAMT) AS TotalCredits
FROM GLTRANS GLT
LEFT JOIN GLACCT GLA 
    ON GLT.GLACCT = GLA.GACCT
LEFT JOIN ARCUST 
    ON GLT.GLCUST = ARCUST.CCUST
LEFT JOIN SALESMAN SM 
    ON ARCUST.CDIST = SM.SMDIST
WHERE 
    GLT.GLAPPL = 'CR' 
    AND GLA.GARP3 IN (500, 600)
    AND GLT.GLPYY = 25 
    AND GLT.GLPMM = 2
GROUP BY 
    SM.SMNAME
ORDER BY 
    TotalCredits DESC;*/





--Total sales by customer
SELECT 
    ARCUST.CALPHA AS CustomerName,
    SUM(GLT.GLAMT) AS TotalSales
FROM GLTRANS GLT
LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
LEFT JOIN ARCUST ON GLT.GLCUST = ARCUST.CCUST
WHERE 
    GLT.GLAPPL IN ('IN')     -- Invoice-type transactions
    AND GLA.GARP3 BETWEEN 500 AND 599
    AND GLT.GLPYY = 25 
    AND GLT.GLPMM = 2
GROUP BY ARCUST.CALPHA
ORDER BY TotalSales DESC;


--We may identify which credits were done to any sales order


--First, we will identify what sales orders were done in february
select SUM(GLT.[GLAMT])
FROM GLTRANS GLT
LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
WHERE GLT.GLAPPL in ('IN') AND GLA.GARP3 IN (500) and [GLPYY] = 25 AND [GLPMM]=2

/************************************************/
--WORKING QUERY SALES AND COST BY ORDER NUMBER
/************************************************/

USE SigmaTB;

DECLARE @RefFilter VARCHAR(20);
SET @RefFilter = '%967137%'; --965835-----965943

SELECT
    GLTRN# as GLTRN#TransNum,                   -- Transaction number                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
    GLDESC AS Title_GLDESC,                     -- Customer name
    GLT.GLACCT AS GLACCT_FS,                    -- FS Account
    GLA.GARP3 AS GARP3_FS,                      -- General Ledger account
    GLAMT,                                      -- Amount       
    GLA.GACDES AS GACDES_AccountDescription,    -- Transaction description  
    GLREF AS Type_Dist_GLREF_Document,          -- Transaction number

                                                                                                                                                            
    GLCRDB,
    GLAPPL AS GLAPPL_APP,                       -- Type of transaction
    GLPGM,                                      -- Transaction number

    GLT.GLACCT AS GLAccount_GLACCT,             
    GLREF AS GLREF_Reference,
    GLCOMP, GLDIST, GLCSTC,                     -- Company, distribution center, customer

    GLTYPE, GLDIST, 
    GLAPPL, GLBTCH,                                 -- For future formatting in Python
    GLPPYY, GLPERD, 
    GLDESC AS Transaction_GLDESC,
    GLUSER, GLAPTR,  GLTRNT,
 
    GLA.GARP3, GLAMT,
    GLRECD, 
    GLRFYY, GLRFMM, GLRFDD,
    GLCUST

FROM GLTRANS GLT
LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
WHERE GLREF LIKE @RefFilter
  AND GLA.GARP3 IN (500, 530 ,600, 610) -- sales, allowances, cogs, cogs freight

ORDER BY GLTRN#;



---------
USE SigmaTB;

-- TOTALS BY TRANSACTION
DECLARE @RefFilter VARCHAR(20);
SET @RefFilter = '%967137%%'; --965835-----965943

SELECT
    GLTRN# AS GLTRN#TransNum,
    GLDESC AS Title_GLDESC,
    GLCUST AS GLCUST_ID,
    SUM(CASE WHEN GLA.GARP3 = 500 THEN GLAMT ELSE 0 END) AS TotalSales,
    SUM(CASE WHEN GLA.GARP3 = 530 THEN GLAMT ELSE 0 END) AS ReturnAllow,
    SUM(CASE WHEN GLA.GARP3 = 600 THEN GLAMT ELSE 0 END) AS COGs_Material,
    SUM(CASE WHEN GLA.GARP3 = 610 THEN GLAMT ELSE 0 END) AS COGs_Freight
FROM GLTRANS GLT
LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
WHERE GLREF LIKE @RefFilter
  AND GLA.GARP3 IN (500, 530, 600, 610)
  GROUP BY GLTRN#, GLDESC, GLCUST;



-- SELECT ALL THE TOTALS
SELECT
    SUM(CASE WHEN GLA.GARP3 = 500 THEN GLAMT ELSE 0 END) AS TotalSales,
    SUM(CASE WHEN GLA.GARP3 = 530 THEN GLAMT ELSE 0 END) AS ReturnAllow,
    SUM(CASE WHEN GLA.GARP3 = 600 THEN GLAMT ELSE 0 END) AS COGs_Material,
    SUM(CASE WHEN GLA.GARP3 = 610 THEN GLAMT ELSE 0 END) AS COGs_Freight
FROM GLTRANS GLT
LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
WHERE 
    GLA.GARP3 IN (500, 530, 600, 610)
    AND GLTRN# <> '0'
    AND GLAMT <> 0
    AND GLT.GLPYY = 25        -- Year 2025
    AND GLT.GLPMM = 2        -- February

-- AUDIT COGS
SELECT
    GLREF,
    GLDESC,
    GLA.GACCT,
    GLA.GACDES,
    GLAMT,
    GLCRDB,
    GLPGM,
    GLAPPL,
    GLBTCH,
    GLUSER,
    *
FROM GLTRANS GLT
LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
WHERE 
    GLA.GARP3 IN (600, 610)
    AND GLTRN# <> '0'
    AND GLAMT <> 0
    AND GLPYY = 25
    AND GLPMM = 2
ORDER BY GLT.GLREF;


--BAD QUERY
SELECT
    SUM(CASE WHEN GLA.GARP3 = 500 THEN GLAMT ELSE 0 END) AS TotalSales,
    SUM(CASE WHEN GLA.GARP3 = 530 THEN GLAMT ELSE 0 END) AS ReturnAllow,
    SUM(CASE 
        WHEN GLA.GARP3 = 600 AND GLA.GACDES LIKE '%COST OF GOODS SOLD%' 
            AND GLA.GACDES NOT LIKE '%VARIANCE%' 
        THEN GLAMT ELSE 0 
    END) AS COGs_Material,
    SUM(CASE WHEN GLA.GARP3 = 610 THEN GLAMT ELSE 0 END) AS COGs_Freight
FROM GLTRANS GLT
LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
WHERE GLA.GARP3 IN (500, 530, 600, 610)
  AND GLTRN# <> '0'
  AND GLAMT <> 0
  AND GLT.GLPYY = 25
  AND GLT.GLPMM = 2;

SELECT
    SUM(CASE WHEN GLA.GARP3 = 500 THEN GLAMT ELSE 0 END) AS TotalSales,
    SUM(CASE WHEN GLA.GARP3 = 530 THEN GLAMT ELSE 0 END) AS ReturnAllow,
    SUM(CASE 
        WHEN GLA.GARP3 = 600 AND GLA.GACDES LIKE '%COST OF GOODS SOLD%' 
            AND GLA.GACDES NOT LIKE '%VARIANCE%' 
        THEN GLAMT ELSE 0 
    END) AS COGs_Material,
    SUM(CASE WHEN GLA.GARP3 = 610 THEN GLAMT ELSE 0 END) AS COGs_Freight
FROM GLTRANS GLT
LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
WHERE GLA.GARP3 IN (500, 530, 600, 610)
  AND GLTRN# <> '0'
  AND GLAMT <> 0
  AND GLT.GLPYY = 25
  AND GLT.GLPMM = 2;


--AUDIT THE BUYOUT
SELECT 
    GLTRN#,
    GLDESC,
    GLREF,
    GLT.GLACCT,
    GLA.GARP3,
    GLA.GACDES,
    GLAMT
FROM GLTRANS GLT
LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
WHERE GLA.GARP3 = 600
  AND GLA.GACDES LIKE '%BUYOUT%'
  AND GLT.GLPYY = 25
  AND GLT.GLPMM = 2
ORDER BY GLTRN#;


USE SigmaTB;

--try with the buyout
USE SigmaTB;

SELECT
    -- Revenue and Returns
    SUM(CASE WHEN GLA.GARP3 = 500 THEN GLAMT ELSE 0 END) AS TotalSales,
    SUM(CASE WHEN GLA.GARP3 = 530 THEN GLAMT ELSE 0 END) AS ReturnAllow,

    -- Direct COGS
    SUM(CASE WHEN GLA.GACCT = '4101100000' THEN GLAMT ELSE 0 END) AS COGS_Material,
    SUM(CASE WHEN GLA.GACCT = '4203900000' THEN GLAMT ELSE 0 END) AS COGS_Freight,

    -- Buyout components
    SUM(CASE WHEN GLA.GACCT = '4101120000' THEN GLAMT ELSE 0 END) AS COGS_Buyout,
    SUM(CASE WHEN GLA.GACCT = '4101200000' THEN GLAMT ELSE 0 END) AS COGS_PPV,

    -- Net = Buyout minus PPV (if PPV is negative, subtracting will correct it)
    SUM(CASE WHEN GLA.GACCT = '4101120000' THEN GLAMT ELSE 0 END) -
    SUM(CASE WHEN GLA.GACCT = '4101200000' THEN GLAMT ELSE 0 END) AS NetBuyoutCOGS

FROM GLTRANS GLT
LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT

WHERE GLA.GARP3 IN (500, 530, 600, 610)
  AND GLT.GLTRN# <> '0'
  AND GLAMT <> 0
  AND GLT.GLPYY = 25
  AND GLT.GLPMM = 2;

---------------------------------
/**********************************************************/
--FIND Sales by account
/**********************************************************/
    SELECT
        GACCT, GLA.GACDES,  SUM(GLAMT), GLCRDB
    FROM GLTRANS GLT
    LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
    WHERE GLA.GARP3 IN (500, 530, 600, 610)
    AND GLTRN# <> '0'
    AND GLAMT <> 0
    AND GLT.GLPYY = 25
    AND GLT.GLPMM = 2
    GROUP BY GACCT, GLCRDB, GLA.GACDES;


/**********************************************************/
/**********************************************************/

        SUM(CASE WHEN GLA.GARP3 = 500 THEN GLAMT ELSE 0 END) AS TotalSales,
        SUM(CASE WHEN GLA.GARP3 = 530 THEN GLAMT ELSE 0 END) AS ReturnAllow,
        SUM(CASE 
            WHEN GLA.GARP3 = 600 AND GLA.GACDES LIKE '%COST OF GOODS SOLD%' 
                AND GLA.GACDES NOT LIKE '%VARIANCE%' 
            THEN GLAMT ELSE 0 
        END) AS COGs_Material,
        SUM(CASE WHEN GLA.GARP3 = 610 THEN GLAMT ELSE 0 END) AS COGs_Freight
    FROM GLTRANS GLT
    LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
    WHERE GLA.GARP3 IN (500, 530, 600, 610)
    AND GLTRN# <> '0'
    AND GLAMT <> 0
    AND GLT.GLPYY = 25
    AND GLT.GLPMM = 2;

    SELECT
        SUM(CASE WHEN GLA.GARP3 = 500 THEN GLAMT ELSE 0 END) AS TotalSales,
        SUM(CASE WHEN GLA.GARP3 = 530 THEN GLAMT ELSE 0 END) AS ReturnAllow,
        SUM(CASE 
            WHEN GLA.GARP3 = 600 AND GLA.GACDES LIKE '%COST OF GOODS SOLD%' 
                AND GLA.GACDES NOT LIKE '%VARIANCE%' 
            THEN GLAMT ELSE 0 
        END) AS COGs_Material,
        SUM(CASE WHEN GLA.GARP3 = 610 THEN GLAMT ELSE 0 END) AS COGs_Freight
    FROM GLTRANS GLT
    LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
    WHERE GLA.GARP3 IN (500, 530, 600, 610)
    AND GLTRN# <> '0'
    AND GLAMT <> 0
    AND GLT.GLPYY = 25
    AND GLT.GLPMM = 2;

---------------------------------


--Query to create totals for 1 transaction
SELECT
    SUM(CASE WHEN GLA.GARP3 = 500 THEN GLAMT ELSE 0 END) AS TotalSales,
    SUM(CASE WHEN GLA.GARP3 = 530 THEN GLAMT ELSE 0 END) AS ReturnAllow,
    SUM(CASE WHEN GLA.GARP3 = 600 THEN GLAMT ELSE 0 END) AS COGs_Material,
    SUM(CASE WHEN GLA.GARP3 = 610 THEN GLAMT ELSE 0 END) AS COGs_Freight
FROM GLTRANS GLT
LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
WHERE GLREF LIKE '%965835%'
  AND GLA.GARP3 IN (500, 530, 600, 610)
  AND GLTRN# <> '0'
  AND GLAMT <> 0


SELECT
    GLTRN# AS GLTRN#TransNum,
    GLDESC AS Title_GLDESC,
    GLCUST AS GLCUST_ID,
    SUM(CASE WHEN GLA.GARP3 = 500 THEN GLAMT ELSE 0 END) AS TotalSales,
    SUM(CASE WHEN GLA.GARP3 = 530 THEN GLAMT ELSE 0 END) AS ReturnAllow,
    SUM(CASE WHEN GLA.GARP3 = 600 THEN GLAMT ELSE 0 END) AS COGs_Material,
    SUM(CASE WHEN GLA.GARP3 = 610 THEN GLAMT ELSE 0 END) AS COGs_Freight
FROM GLTRANS GLT
LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
WHERE  GLT.GLPYY = 25     AND GLT.GLPMM = 2  AND GLTRN#<>'0'
  AND GLA.GARP3 IN (500, 530, 600, 610)
  GROUP BY GLTRN#, GLDESC, GLCUST;