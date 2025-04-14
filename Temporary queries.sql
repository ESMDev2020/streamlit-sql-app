SELECT TOP (100) 
IOITEM,
IOQOH,
IOQOO,
IOACST,
IOBPRC
FROM [SigmaTB].[dbo].[ITEMONHD]

UNION ALL

SELECT 
    'Total' AS IOITEM,
    null as IOQOH,
    null as IOQOO,
    null as IOACST,
    CAST(COUNT(*) AS VARCHAR(10)) AS IOBPRC
FROM [SigmaTB].[dbo].[ITEMONHD];


select   top 10
from ITEMHIST
where IHITEM = '50002'

select   top 10 *
from ITEMMAST

select   top 30 *
from MPDETAIL

select   top 30 *
from oedetail

select top 30 * from OEOPNORD;
select top 30 * from PODETAIL;
select top 30 * from itemtag;

select top 30 * from  ARCUST

select top 30 * from  APVEND

select top 30 * from  ITEMHIST

select top 30 * from  ITEMONHD

select top 30 * from OEOPNORD


/****************************************************************************************/
--review... sales totals by customer
/****************************************************************************************/

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


-------------------------------------------
-- Same query but with totals
/*
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

    UNION ALL

    SELECT 
        NULL AS OrderID,
        '🧮 TOTAL' AS SalesmanName,
        NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
        NULL,
        SUM(OEDETAIL.ODTFTS),
        SUM(OEDETAIL.ODTLBS),
        SUM(OEDETAIL.ODTPCS),
        SUM(OEDETAIL.ODSLSX),
        SUM(OEDETAIL.ODFRTS),
        SUM(OEDETAIL.ODCSTX),
        SUM(OEDETAIL.ODPRCC),
        SUM(OEDETAIL.ODADCC),
        SUM(OEDETAIL.ODWCCS),
        NULL, NULL
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

    ORDER BY SalesmanName, OrderID;  */



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




--we check if the index has data
SELECT TOP 10 GLREF, GLREF_REV 
FROM GLTRANS 
WHERE GLREF IS NOT NULL;



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

select count(*) from gltrans


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

---------------------------------------------------------
USE SigmaTB;
    --Query all
  SELECT GLA.GARP3, GLT.GLCSTC, GLT.GLAPPL, GLT.[GLTRN#], GLA.GACDES, GLT.GLACCT, GLT.GLAMT, GLT.GLAMTQ, GLT.GLCRDB, GLT.GLDESC 
        FROM GLTRANS GLT
        LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
  WHERE 
        GLT.[GLTRN#]   =965943

    -- Query what I want
    -- THIS QUERY IDENTIFIES TOTAL SALES, MATERIAL SALES, PROCESSING SALES, MATERIAL COST, PROCESSING COST
  SELECT GLA.GARP3, GLT.GLCSTC, GLT.GLAPPL, GLT.[GLTRN#], GLA.GACDES, GLT.GLACCT, GLT.GLAMT, GLT.GLAMTQ, GLT.GLCRDB, GLT.GLDESC 
        FROM GLTRANS GLT
        LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
  WHERE 
        GLT.[GLTRN#]   =965943
        AND GLA.GARP3 IN (30, 50, 500, 530, 600, 610, 175)
        AND GLT.GLAPPL NOT IN ('AP', 'IU')
        ORDER BY 
        CASE GARP3
            WHEN 30 THEN 1
            WHEN 500 THEN 2
            WHEN 175 THEN 3
            WHEN 50 THEN 3
            WHEN 600 THEN 3           
            ELSE 999
        END, 
        GACDES;

/**************************************************************************
--FUNCTION TO SELECT TOTAL SALES AND COSTS PER TRANSACTION
**************************************************************************/

    WITH SelectTotalSalesCostsperTransaction as(
        SELECT 
            Metric = 
                CASE 
                    WHEN GLA.GARP3 = 500 THEN 'Total Sales'
                    WHEN GLA.GACCT = 4001100000 THEN 'Material Sales'
                    WHEN GLA.GACCT = 4103200000 OR GLA.GACCT = 4103300000 THEN 'Processing Sales'
                    WHEN GLA.GARP3 = 50 THEN 'Material Cost'
                    WHEN GLA.GARP3 = 175 THEN 'Processing Cost'
                    ELSE 'Other'
                END,
            SUM(CASE 
                    WHEN GLCRDB = 'C' THEN -GLAMT
                    WHEN GLCRDB = 'D' THEN  GLAMT
                    ELSE 0
                END) AS TotalAmount
        FROM GLTRANS GLT
        LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
        WHERE 
            GLT.[GLTRN#] = 965943
            AND GLA.GARP3 IN (30, 50, 500, 530, 600, 610, 175)
            AND GLT.GLAPPL NOT IN ('AP', 'IU')
            AND (
                GLA.GARP3 = 500 
                OR GLA.GARP3 = 50 
                OR GLA.GARP3 = 175
                OR GLA.GACCT IN (4001100000, 4103200000, 4103300000)
            )
        GROUP BY 
            CASE 
                WHEN GLA.GARP3 = 500 THEN 'Total Sales'
                WHEN GLA.GACCT = 4001100000 THEN 'Material Sales'
                WHEN GLA.GACCT = 4103200000 OR GLA.GACCT = 4103300000 THEN 'Processing Sales'
                WHEN GLA.GARP3 = 50 THEN 'Material Cost'
                WHEN GLA.GARP3 = 175 THEN 'Processing Cost'
                ELSE 'Other'
            END
        ORDER BY 
            CASE 
                WHEN 
                    CASE 
                        WHEN GLA.GARP3 = 500 THEN 'Total Sales'
                        WHEN GLA.GACCT = 4001100000 THEN 'Material Sales'
                        WHEN GLA.GACCT = 4103200000 OR GLA.GACCT = 4103300000 THEN 'Processing Sales'
                        WHEN GLA.GARP3 = 50 THEN 'Material Cost'
                        WHEN GLA.GARP3 = 175 THEN 'Processing Cost'
                        ELSE 'Other'
                    END = 'Total Sales' THEN 1
                WHEN 
                    CASE 
                        WHEN GLA.GARP3 = 500 THEN 'Total Sales'
                        WHEN GLA.GACCT = 4001100000 THEN 'Material Sales'
                        WHEN GLA.GACCT = 4103200000 OR GLA.GACCT = 4103300000 THEN 'Processing Sales'
                        WHEN GLA.GARP3 = 50 THEN 'Material Cost'
                        WHEN GLA.GARP3 = 175 THEN 'Processing Cost'
                        ELSE 'Other'
                    END = 'Material Sales' THEN 2
                WHEN 
                    CASE 
                        WHEN GLA.GARP3 = 500 THEN 'Total Sales'
                        WHEN GLA.GACCT = 4001100000 THEN 'Material Sales'
                        WHEN GLA.GACCT = 4103200000 OR GLA.GACCT = 4103300000 THEN 'Processing Sales'
                        WHEN GLA.GARP3 = 50 THEN 'Material Cost'
                        WHEN GLA.GARP3 = 175 THEN 'Processing Cost'
                        ELSE 'Other'
                    END = 'Processing Sales' THEN 3
                WHEN 
                    CASE 
                        WHEN GLA.GARP3 = 500 THEN 'Total Sales'
                        WHEN GLA.GACCT = 4001100000 THEN 'Material Sales'
                        WHEN GLA.GACCT = 4103200000 OR GLA.GACCT = 4103300000 THEN 'Processing Sales'
                        WHEN GLA.GARP3 = 50 THEN 'Material Cost'
                        WHEN GLA.GARP3 = 175 THEN 'Processing Cost'
                        ELSE 'Other'
                    END = 'Material Cost' THEN 4
                WHEN 
                    CASE 
                        WHEN GLA.GARP3 = 500 THEN 'Total Sales'
                        WHEN GLA.GACCT = 4001100000 THEN 'Material Sales'
                        WHEN GLA.GACCT = 4103200000 OR GLA.GACCT = 4103300000 THEN 'Processing Sales'
                        WHEN GLA.GARP3 = 50 THEN 'Material Cost'
                        WHEN GLA.GARP3 = 175 THEN 'Processing Cost'
                        ELSE 'Other'
                    END = 'Processing Cost' THEN 5
                ELSE 999
            END;

    )

-------------------
    -- We get the totals per transaction
    select * from SelectTotalSalesCostsperTransaction
    ORDER BY GARP3;

------------------


SELECT DISTINCT GLAPPL FROM GLTRANS;

SELECT 
    GLAPPL,
    COUNT(*) AS MyRowCount
FROM GLTRANS
WHERE 
    GLPYY = 25 
    AND GLPMM = 2
GROUP BY GLAPPL
ORDER BY MyRowCount DESC;


SELECT 
    CASE 
        WHEN GLACCT IN (4101000000, 4101100000, 4101120000, 4101200000) THEN 'Material Cost'
        WHEN GLACCT IN (2201400000, 2201000000) THEN 'Processing Cost'
        ELSE 'Other'
    END AS CostType,
    SUM(CASE 
            WHEN GLCRDB = 'C' THEN -GLAMT
            WHEN GLCRDB = 'D' THEN  GLAMT
            ELSE 0
        END) AS TotalAmount
FROM GLTRANS
WHERE GLPYY = 25 AND GLPMM = 2
AND GLTRN# = 965943
AND GLACCT IN (4101000000, 4101100000, 4101120000, 4101200000, 2201400000, 2201000000)
GROUP BY 
    CASE 
        WHEN GLACCT IN (4101000000, 4101100000, 4101120000, 4101200000) THEN 'Material Cost'
        WHEN GLACCT IN (2201400000, 2201000000) THEN 'Processing Cost'
        ELSE 'Other'
    END;

USE SIGMATB;

DELETE FROM GLTRANS;

-- Only needed if your column type blocks conversion
ALTER TABLE GLTRANS
ALTER COLUMN GLAMTQ DECIMAL(18, 2);



SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    NUMERIC_PRECISION, 
    NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'GLTRANS' AND COLUMN_NAME = 'GLAMTQ';


--PROVIDES ALL SALES AND COGS. REVIEW MATERIALS
BEGIN
    SELECT
        SUM(CASE WHEN Sub.GARP3 = 500 THEN AdjustedAmount ELSE 0 END) AS TotalSales,
        SUM(CASE WHEN Sub.GARP3 = 530 THEN AdjustedAmount ELSE 0 END) AS ReturnAllow,
        SUM(CASE WHEN Sub.GARP3 = 600 THEN AdjustedAmount ELSE 0 END) AS COGs_Material,
        SUM(CASE WHEN Sub.GARP3 = 610 THEN AdjustedAmount ELSE 0 END) AS COGs_Freight
    FROM (
        SELECT 
            GLAMT * CASE 
                        WHEN GLCRDB = 'C' THEN -1 
                        WHEN GLCRDB = 'D' THEN 1 
                        ELSE 0 
                    END AS AdjustedAmount,
            GLA.GARP3
        FROM GLTRANS GLT
        LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
        WHERE 
            GLA.GARP3 IN (500, 530, 600, 610)
            AND GLTRN# <> '0'
            AND GLAMT <> 0
            AND GLT.GLPYY = 25
            AND GLT.GLPMM = 2
    ) AS Sub;
END

        select * from GLACCT GLA where gla.gacdes like '%COGS - PROCESSING PUR PRICE VARIANC%'
            select * from GLACCT GLA where gla.gacct = 4103600000


SELECT *
FROM OEOPNORD
WHERE OOORDR IN (334622, 335295, 221719, 51257);

SELECT *
FROM ARCUST
WHERE CCUST IN (334622, 335295, 221719, 51257);

SELECT *
FROM ITEMTAG
WHERE ITEMTAG.ITAGN LIKE ('%334622%', '%335295%', '%221719%', '%51257%');

SELECT TOP 1 * FROM GLHIST WHERE GLHISTID = 334622;



 -- lets get the 380k - TOTAL
        SELECT         
            SUM(
                CASE 
                    WHEN GLCRDB = 'C' THEN -GLAMT
                    WHEN GLCRDB = 'D' THEN GLAMT
                    ELSE 0
                END) AS AdjustedAmount 
         
        FROM GLTRANS GLT
        LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
        WHERE GLA.GARP3 IN (500, 530, 600, 610)
        AND GLT.[GLTRN#] = 0
        AND GLT.GLPYY = 25
        AND GLT.GLPMM = 2
        ORDER BY
            GARP3

-- Lets get the 380k by GACDES
        SELECT GLA.GACDES,
            SUM(
                CASE 
                    WHEN GLCRDB = 'C' THEN +GLAMT
                    WHEN GLCRDB = 'D' THEN -GLAMT
                    ELSE 0
                END) AS AdjustedAmount 
        FROM GLTRANS GLT
        LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
        WHERE GLA.GARP3 IN (500, 530, 600, 610)
        AND GLT.[GLTRN#] = 0
        AND GLT.GLPYY = 25
        AND GLT.GLPMM = 2
        GROUP BY GLA.GACDES;
   
-- Lets get the 380k by GLDESC -- all rows
        SELECT GLT.GLDESC,
            SUM(
                CASE 
                    WHEN GLCRDB = 'C' THEN +GLAMT
                    WHEN GLCRDB = 'D' THEN -GLAMT
                    ELSE 0
                END) AS AdjustedAmount 
        FROM GLTRANS GLT
        LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
        WHERE GLA.GARP3 IN (500, 530, 600, 610)
        AND GLT.[GLTRN#] = 0
        AND GLT.GLPYY = 25
        AND GLT.GLPMM = 2
        GROUP BY GLT.GLDESC; -- ORDER BY GARP3


-- Lets get the 380k by GLDESC -- only numeric rows
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





-- no
-- Lets get the 380k by GACDES
        SELECT GLA.GACDES, 
            SUM(glt.GLAMT)
        FROM GLTRANS GLT
        LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
        WHERE GLA.GARP3 IN (500, 530, 600, 610)
        AND GLT.[GLTRN#] = 0
        AND GLT.GLPYY = 25
        AND GLT.GLPMM = 2
        GROUP BY GLA.GACDES; -- ORDER BY GARP3


USE SigmaTB;
SELECT DISTINCT(ITTDES) FROM ITEMTAG;
