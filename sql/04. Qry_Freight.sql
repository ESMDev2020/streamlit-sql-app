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

    BEGIN
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

        ORDER BY GLTRN#;}
    END


/**********************************************************************************/
/**********************************************************************************/


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














/************************************************/
--FINANCIAL QUERIES
/************************************************/



/**************************************************************************************/
-- Februay Sales detail from order, customer, salesman from Sales Report
/**************************************************************************************/
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
            SUM(OEDETAIL.ODPRCC) AS TotalProcessingPrice,                                                            -- Processing Price  
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
-- Februay Sales Detail per account from General Ledger
/**************************************************************************************/
    SELECT
        CAST(GARP3 AS VARCHAR(10)) AS GARP3,
        CAST(GA.GACCT AS VARCHAR(20)) AS GACCT,
        GA.GACDES AS AccountDescription,
        SUM(CASE 
            WHEN GLCRDB = 'C' THEN -GLAMT
            WHEN GLCRDB = 'D' THEN  GLAMT
            ELSE 0
        END) AS TotalAmount,
        CAST(GARP3 AS INT) AS SortKey
    FROM GLTRANS GL
    LEFT JOIN GLACCT GA ON GL.GLACCT = GA.GACCT
    WHERE GLPYY = 25 AND GLPMM = 2
    AND GARP3 IN (500, 530, 600, 610)
    GROUP BY GARP3, GA.GACCT, GA.GACDES

    UNION ALL

    SELECT
        'TOTAL' AS GARP3,
        'TOTAL' AS GACCT,
        '🧮 Total' AS AccountDescription,
        SUM(CASE 
            WHEN GLCRDB = 'C' THEN -GLAMT
            WHEN GLCRDB = 'D' THEN  GLAMT
            ELSE 0
        END) AS TotalAmount,
        999 AS SortKey

    FROM GLTRANS GL
    LEFT JOIN GLACCT GA ON GL.GLACCT = GA.GACCT
    WHERE GLPYY = 25 AND GLPMM = 2
    AND GARP3 IN (500, 530, 600, 610)

    ORDER BY SortKey ASC;


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





/************************************************/
--Identify total sales 
/************************************************/
    BEGIN
        SELECT
            GLA.GARP3,
            SUM(CASE 
                WHEN GLCRDB = 'C' THEN -GLAMT
                WHEN GLCRDB = 'D' THEN GLAMT
                ELSE 0
            END) AS AdjustedAmount
        FROM GLTRANS GLT
        LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
        WHERE GLA.GARP3 IN (500, 530)
        AND GLA.GARP3 IS NOT NULL
        AND GLT.GLPYY = 25
        AND GLT.GLPMM = 2
        GROUP BY GLA.GARP3;
    END    

   

/************************************************/
-- Cost per transaction 

/************************************************/
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








/*+++++++++++++++++++++++++++++++++++++++++++++++++
--ACCOUNTS PER GL
***************************************************/
    BEGIN
        SELECT  GARP3, GACDES, GACCT FROM GLACCT
    END



/*+++++++++++++++++++++++++++++++++++++++++++++++++
--How are distributed the credits, by customer, and by order
***************************************************/
    BEGIN
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

    END






/************************************************/
--TOTAL SALES BY CUSTOMER
/************************************************/

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
    BEGIN
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
    END


---------
USE SigmaTB;

/**************************************************************************************/
--  Sales and costs per transaction number
/**************************************************************************************/
    BEGIN
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
    END

/**************************************************************************************/
-- GOOD QUERY FOR TOTALS OF FINANCIAL STATEMENTS
/**************************************************************************************/
BEGIN
    SELECT
        GLA.GARP3,
        CASE GLA.GARP3
            WHEN 500 THEN 'Sales'
            WHEN 530 THEN 'Sales Returns'
            WHEN 600 THEN 'Cost of Goods Sold'
            WHEN 610 THEN 'Freight (COGS)'
            ELSE 'Other'
        END AS GARP3_Name,
        SUM(CASE 
            WHEN GLCRDB = 'C' THEN -GLAMT
            WHEN GLCRDB = 'D' THEN GLAMT
            ELSE 0
        END) AS AdjustedAmount
    FROM GLTRANS GLT
    LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
    WHERE GLA.GARP3 IN (500, 530, 600, 610)
    AND GLT.GLPYY = 25 AND GLT.GLPMM = 2                --FEBRUARY
    GROUP BY GLA.GARP3,
            CASE GLA.GARP3
                WHEN 500 THEN 'Sales'
                WHEN 530 THEN 'Sales Returns'
                WHEN 600 THEN 'Cost of Goods Sold'
                WHEN 610 THEN 'Freight (COGS)'
                ELSE 'Other'
            END
    ORDER BY GARP3 ASC;
END

/**************************************************************************************/
--  Sales, returns, COGS, from General Ledger  (review material)
/**************************************************************************************/
/***********************************************************************
-- This query reproduces the sales and cost analysis per sales order, on the General Ledger
***********************************************************************/
    WITH SelectSalesGOGSfromGLperTransaction AS (
        
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
                AND GLT.GLAPPL NOT IN ('IU', 'CR')
    ),

     --This provides the TOTAL Sales and cost per total of rows using parameters for transaction
    SelectSalesGOGSfromGLTotalNoTransaction AS (
    
        --This query groups the totals per category
        SELECT
            GLA.GARP3,
            CASE GLA.GARP3
                WHEN 500 THEN 'Sales'
                WHEN 530 THEN 'Sales Returns'
                WHEN 600 THEN 'Cost of Goods Sold'
                WHEN 610 THEN 'Freight (COGS)'
                ELSE 'Other'
            END AS GARP3_Name,
            SUM(
                CASE 
                    WHEN GLCRDB = 'C' THEN -GLAMT
                    WHEN GLCRDB = 'D' THEN GLAMT
                    ELSE 0
                END) AS AdjustedAmount
            --GLAMTQ)--GLAMT)
        FROM GLTRANS GLT
        LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
        WHERE GLA.GARP3 IN (500, 530, 600, 610)
        AND GLT.[GLTRN#] = 0
        AND GLT.GLPYY = 25
        AND GLT.GLPMM = 2
        GROUP BY GLA.GARP3,
                CASE GLA.GARP3
                    WHEN 500 THEN 'Sales'
                    WHEN 530 THEN 'Sales Returns'
                    WHEN 600 THEN 'Cost of Goods Sold'
                    WHEN 610 THEN 'Freight (COGS)'
                    ELSE 'Other'
                END
        ORDER BY 
            CASE GARP3
                WHEN 500 THEN 1
                WHEN 530 THEN 2
                WHEN 600 THEN 3
                WHEN 610 THEN 4
                ELSE 5
            END ASC;
    )

    -- This provides the DETAIL of Sales and Cost that have no transaction assigned
    SelectSalesGOGSfromGL_DETAIL_NoTransaction AS (
    
        --This query groups the totals per category
        SELECT
            GLA.GARP3, GLT.GLAPPL, GLT.GLTRN#, GLA.GACDES,gla.gacct, GLT.GLAMT, GLT.GLCRDB, GLT.GLDESC, GLT.GLREF, GLT.GLCUST, GLT.GLPGM, GLT.GLDSP, GLT.GLUSER,
            '---' as mySeparator, GLACCT, GLAMT, GLSMM, GLDESC, GLBDIS, GLBTCH, GLREF, GLRP#, GLDSP, GLTRNT, GLTYPE, GLTRDS, GLTRN#, GLMLIN, GLCDIS, GLCUST, GLAPTR, GLLOCK, GLRFCC, GLAMTQ,
            [GLPYY], [GLPMM], [GLPDD]
  
        FROM GLTRANS GLT
        LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
        WHERE GLA.GARP3 IN (500, 530, 600, 610)
        AND GLT.[GLTRN#] = 0
        AND GLT.GLPYY = 25
        AND GLT.GLPMM = 2
        ORDER BY
            GARP3

-- Enhaced query
-- GOOD BUT WHAT IS THIS????
-- I think it is the 380k
SELECT
    GLA.GACDES AS GACDES_Account_Description,
    GLT.GLAMT AS GLAMT_Amount,
    GLAMTQ AS GLAMTQ_Quantity_or_Secondary_Amount,
    GLT.GLDESC AS GLDESC_Transaction_Description,
    GLREF AS GLREF_Reference,
    GLBTCH AS GLBTCH_Batch_Number,
    GLT.GLTRN# AS GLTRN_Transaction_Number,
    GLA.GACCT AS GACCT_GL_Account,
    GLA.GARP3 AS GARP3_Account_Group,
    '---' AS mySeparator,
    GLT.GLAPPL AS GLAPPL_Application_Code,
    GLT.GLCRDB AS GLCRDB_Credit_or_Debit_Flag,
    GLT.GLCUST AS GLCUST_Customer_ID,
    GLT.GLPGM AS GLPGM_Program_Name,
    GLT.GLDSP AS GLDSP_Disposition_Code,
    GLT.GLUSER AS GLUSER_Entered_By,
    GLSMM AS GLSMM_Summary_Code,
    GLBDIS AS GLBDIS_District,
    GLRP# AS GLRP_Report_Number,
    GLDSP AS GLDSP_Disposition,
    GLTRNT AS GLTRNT_Transaction_Type,
    GLTYPE AS GLTYPE_Type,
    GLTRDS AS GLTRDS_Description,
    GLTRN# AS GLTRN_Transaction_Number,
    GLMLIN AS GLMLIN_Line_Number,
    GLCDIS AS GLCDIS_District,
    GLCUST AS GLCUST_Customer,
    GLAPTR AS GLAPTR_Applied_Transaction,
    GLLOCK AS GLLOCK_Lock_Flag,
    GLRFCC AS GLRFCC_Reversal_Code,

    [GLPYY] AS GLPYY_Posting_Year,
    [GLPMM] AS GLPMM_Posting_Month,
    [GLPDD] AS GLPDD_Posting_Day

FROM GLTRANS GLT
LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
WHERE GLA.GARP3 IN (500, 530, 600, 610)
  AND GLT.[GLTRN#] = 0
  AND GLT.GLPYY = 25
  AND GLT.GLPMM = 2
ORDER BY GARP3;


/***********************************************************************
-- This query get the 380k by GLDESC -- only numeric rows
***********************************************************************/
BEGIN
    USE SigmaTB;
    SELECT 
        LTRIM(RTRIM(GLT.GLDESC)) AS GLDESC,
        GLA.GACDES,
        SUM(
            CASE 
                WHEN GLCRDB = 'C' THEN +GLAMT
                WHEN GLCRDB = 'D' THEN -GLAMT
                ELSE 0
            END
        ) AS AdjustedAmount 
    FROM 
        GLTRANS GLT
    LEFT JOIN 
        GLACCT GLA ON GLT.GLACCT = GLA.GACCT
    WHERE 
        GLA.GARP3 IN (500, 530, 600, 610)
        AND GLT.[GLTRN#] = 0
        AND GLT.GLPYY = 25
        AND GLT.GLPMM = 2
        AND LEN(LTRIM(RTRIM(GLT.GLDESC))) <> 6  -- Exclude exactly 6-character trimmed values
    GROUP BY 
        LTRIM(RTRIM(GLT.GLDESC)), GLA.GACDES;
    
END




    SELECT 
        GLAPPL, 
        COUNT(*) AS MyRowCount,
        SUM(
                CASE 
                    WHEN GLCRDB = 'C' THEN -GLAMT
                    WHEN GLCRDB = 'D' THEN GLAMT
                    ELSE 0
                END) AS AdjustedAmount 
    FROM 
        GLTRANS GLT
    WHERE 
        GLT.GLPYY = 25
        AND GLT.GLPMM = 2
        and GLT.GLTRN# = 0
    GROUP BY 
        GLAPPL
    ORDER BY 
        MyRowCount DESC;

    SELECT 
        GLAPPL,
                CASE 
                    WHEN GLCRDB = 'C' THEN -GLAMT
                    WHEN GLCRDB = 'D' THEN GLAMT
                    ELSE 0
                END AS AdjustedAmount 
    FROM 
        GLTRANS GLT
    WHERE 
        GLT.GLPYY = 25
        AND GLT.GLPMM = 2
        and GLT.GLTRN# = 0
    ORDER BY 
        GLAPPL DESC;


        --gldesc, glref, GLCUST, 

     /*   ORDER BY 
            CASE GARP3
                WHEN 500 THEN 1
                WHEN 530 THEN 2
                WHEN 600 THEN 3
                WHEN 610 THEN 4
                ELSE 5
            END ASC; */
    )

    -- THIS DOES NOT WORK
    SelectSalesGOGSfromGLTotal_splitMP AS (
    
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
            --GLT.[GLTRN#] = 965943
            GLT.GLPYY = 25 AND GLT.GLPMM = 2                --FEBRUARY
            AND GLA.GARP3 IN (30, 50, 500, 530, 600, 610, 175)
            AND GLT.GLAPPL NOT IN ('IU', 'CR', 'AP')
    ), 

    --This provides the Sales and cost per total of rows
    SelectSalesGOGSfromGLTotal AS (
    
        --This query groups the totals per category
        SELECT
            GLA.GARP3,
            CASE GLA.GARP3
                WHEN 500 THEN 'Sales'
                WHEN 530 THEN 'Sales Returns'
                WHEN 600 THEN 'Cost of Goods Sold'
                WHEN 610 THEN 'Freight (COGS)'
                ELSE 'Other'
            END AS GARP3_Name,
            SUM(
                CASE 
                    WHEN GLCRDB = 'C' THEN -GLAMT
                    WHEN GLCRDB = 'D' THEN GLAMT
                    ELSE 0
                END) AS AdjustedAmount
            --GLAMTQ)--GLAMT)
        FROM GLTRANS GLT
        LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
        WHERE GLA.GARP3 IN (500, 530, 600, 610)
        AND GLT.GLPYY = 25
        AND GLT.GLPMM = 2
        GROUP BY GLA.GARP3,
                CASE GLA.GARP3
                    WHEN 500 THEN 'Sales'
                    WHEN 530 THEN 'Sales Returns'
                    WHEN 600 THEN 'Cost of Goods Sold'
                    WHEN 610 THEN 'Freight (COGS)'
                    ELSE 'Other'
                END
        ORDER BY 
            CASE GARP3
                WHEN 500 THEN 1
                WHEN 530 THEN 2
                WHEN 600 THEN 3
                WHEN 610 THEN 4
                ELSE 5
            END ASC;
    ),



--Good
--SELECT * FROM SelectSalesGOGSfromGL_DETAIL_NoTransaction
select * from SelectSalesGOGSfromGLTotalNoTransaction
SELECT * FROM SelectSalesGOGSfromGLperTransaction
Select * FROM SelectSalesGOGSfromGLTotal


/***********************************************************************
-- This query Provides Sales Cost report from General Ledger for the report chart
***********************************************************************/
    USE SigmaTB;
    SELECT
            GLA.GARP3,
            SUM(
                CASE 
                    WHEN GLCRDB = 'C' THEN +GLAMT
                    WHEN GLCRDB = 'D' THEN -GLAMT
                    ELSE 0
                END) AS AdjustedAmount
        FROM GLTRANS GLT
        LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
        WHERE 
            GLA.GARP3 IN (500, 530, 600, 610)
            AND GLT.GLPYY = 25
            AND GLT.GLPMM = 2
        GROUP BY 
            GLA.GARP3,
            CASE GLA.GARP3
                WHEN 500 THEN 'Sales'
                WHEN 530 THEN 'Sales Returns'
                WHEN 600 THEN 'Cost of Goods Sold'
                WHEN 610 THEN 'Freight (COGS)'
                ELSE 'Other'
            END

            

            SELECT
    GLA.GARP3,





    

---------------------------------
/**********************************************************/
--FIND Sales by Financial account
/**********************************************************/
    SELECT
            GARP3,
            GACCT,
            GLA.GACDES,
            SUM(CASE 
                    WHEN GLCRDB = 'C' THEN -GLAMT
                    WHEN GLCRDB = 'D' THEN GLAMT
                    ELSE 0
                END) AS AdjustedAmount
        FROM GLTRANS GLT
        LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
        WHERE GLA.GARP3 IN (500, 530, 600, 610)
        --AND GLTRN# <> '0'
        --AND GLAMT <> 0
        AND GLT.GLPYY = 25
        AND GLT.GLPMM = 2
        GROUP BY GARP3, GACCT, GLA.GACDES 
        Order by GARP3 asc;


/**********************************************************/
/**********************************************************/

---------------------------------





/**********************************************************/
--SALES TOTAL BY CUSTOMER, SALESMAN, FROM SALES REPORT - USED FOR THE CHART
/**********************************************************/

        SELECT 
            ARCUST.CALPHA AS CustomerName,
            SALESMAN.SMNAME AS SalesmanName,
            SUM(OEDETAIL.ODSLSX) AS TotalSales,
            SUM(OEDETAIL.ODFRTS) AS TotalFreightCharges,
            SUM(OEDETAIL.ODCSTX) AS TotalMaterialCost,
            SUM(OEDETAIL.ODPRCC) AS TotalProcessingPrice,
            SUM(OEDETAIL.ODADCC) AS TotalAdditionalCharges,
            SUM(OEDETAIL.ODWCCS) AS TotalWeightCost
        FROM ARCUST
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
        GROUP BY ARCUST.CALPHA, SALESMAN.SMNAME


