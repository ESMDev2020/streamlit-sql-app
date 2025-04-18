USE SIGMATB;

DELETE FROM GLTRANS;

SELECT COUNT(*) FROM GLTRANS;


-- Only needed if your column type blocks conversion
UPDATE GLTRANS
SET GLAMTQ = CAST(GLAMTQ AS DECIMAL(18,2));

-- lets gonna find credit memos
BEGIN
    USE SigmaTB;

    SELECT 
        oddist * 1000000 + odordr AS OrderID,
        OEDETAIL.ODCREF,
              OEDETAIL.ODXSEL,
              OEDETAIL.ODORDR,
        OEDETAIL.ODWCST,
        OEDETAIL.ODCSTX,
        OEDETAIL.ODUCST,
        SALESMAN.SMNAME,
        OEOPNORD.OOTYPE,
        odcdis * 100000 + odcust AS CustomerID,
        ARCUST.CALPHA,
        OEDETAIL.ODITEM,
        OEDETAIL.*,
        OOICC * 1000000 + OOIYY * 10000 + OOIMM * 100 + OOIDD AS OrderDate

    FROM 
        ARCUST ARCUST,
        OEDETAIL OEDETAIL,
        OEOPNORD OEOPNORD,
        SALESMAN SALESMAN
    WHERE 
        OEDETAIL.ODDIST = OEOPNORD.OODIST 
        AND OEDETAIL.ODORDR = OEOPNORD.OOORDR 
        AND OEOPNORD.OOCDIS = ARCUST.CDIST 
        AND OEOPNORD.OOCUST = ARCUST.CCUST 
        AND OEOPNORD.OOISMD = SALESMAN.SMDIST 
        AND OEOPNORD.OOISMN = SALESMAN.SMSMAN 
        AND (
            OEOPNORD.OOTYPE = 'C' 
            --AND OEOPNORD.OORECD = 'W' 
            and ooiyy = 25 AND OOIMM = 2
        );

END

--SALES ANALYSIS

SELECT DISTINCT cdist*100000+ccust, ARCUST.CALPHA, ARCUST.CLIMIT, CISMD1*100+CISLM1, CSMDI1*100+CSLMN1,SALESMAN.SMNAME
FROM ARCUST ARCUST, SALESMAN SALESMAN
WHERE ARCUST.CISMD1 = SALESMAN.SMDIST AND ARCUST.CISLM1 = SALESMAN.SMSMAN
ORDER BY ARCUST.CALPHA

-- SALES BY REP
SELECT DISTINCT smdist*100+smsman, SALESMAN.SMNAME
FROM SALESMAN SALESMAN

-- DETAILED INVENTORY DATA
SELECT * FROM ITEMONHD ITEMONHD

-- SALES ORDERS
SELECT oddist*1000000+odordr, SALESMAN.SMNAME, OEOPNORD.OOTYPE, odcdis*100000+odcust, ARCUST.CALPHA, OOICC*1000000+OOIYY*10000+OOIMM*100+OOIDD, OEDETAIL.ODITEM, OEDETAIL.ODSIZ1, OEDETAIL.ODSIZ2, OEDETAIL.ODSIZ3, OEDETAIL.ODCRTD, SLSDSCOV.DXDSC2, OEDETAIL.ODTFTS, OEDETAIL.ODTLBS, OEDETAIL.ODTPCS, OEDETAIL.ODSLSX, OEDETAIL.ODFRTS, OEDETAIL.ODCSTX, OEDETAIL.ODPRCC, OEDETAIL.ODADCC, OEDETAIL.ODWCCS, ARCUST.CSTAT, ARCUST.CCTRY
FROM ARCUST ARCUST, OEDETAIL OEDETAIL, OEOPNORD OEOPNORD, SALESMAN SALESMAN, SLSDSCOV SLSDSCOV
WHERE OEDETAIL.ODDIST = OEOPNORD.OODIST 
    AND OEDETAIL.ODDIST = SLSDSCOV.DXDIST 
    AND OEDETAIL.ODMLIN = SLSDSCOV.DXMLIN 
    AND OEDETAIL.ODORDR = OEOPNORD.OOORDR 
    AND OEDETAIL.ODORDR = SLSDSCOV.DXORDR 
    AND OEOPNORD.OOCDIS = ARCUST.CDIST 
    AND OEOPNORD.OOCUST = ARCUST.CCUST 
    AND OEOPNORD.OOISMD = SALESMAN.SMDIST 
    AND OEOPNORD.OOISMN = SALESMAN.SMSMAN 
    AND ((OEOPNORD.OOTYPE In ('A','B')) 
    AND (OEOPNORD.OORECD='W') )
    AND ooiyy = 25 and ooimm = 2;
    


SELECT SHITEM, SHIPMAST.AM

BEGIN
    USE SigmaTB;
    SELECT TOP 100 * FROM GLTRANS;


/*******************************************************************
GLTRANS WITH DESCRIPTION
*********************************************************************/

    SELECT TOP 100 
        GLACCT AS GLACCT_General_Ledger_Account,
        GLAMT AS GLAMT_Transaction_Amount,
        GLDESC AS GLDESC_Description,
        GLBTCH AS GLBTCH_Batch,
        GLREF AS GLREF_Reference,
        GLTRN# AS GLTRN#_Transaction_Number,
        GLCUST AS GLCUST_Customer_ID,
        GLRECD AS GLRECD_Record_Type,   -- here we differenciate important fields from non important fields
        GLCOMP AS GLCOMP_Company_Code,
        GLDIST AS GLDIST_Distribution_Center,
        GLAPPL AS GLAPPL_Application_Source,
        GLPERD AS GLPERD_Posting_Period,
        GLPPYY AS GLPPYY_Posting_Year,
        GLCSTC AS GLCSTC_Cost_Center,
        GLCRDB AS GLCRDB_Credit_Debit,
        GLPCC AS GLPCC_Posting_Century,
        GLPYY AS GLPYY_Posting_Year,
        GLPMM AS GLPMM_Posting_Month,
        GLPDD AS GLPDD_Posting_Day,
        GLSYY AS GLSYY_Source_Year,
        GLSMM AS GLSMM_Source_Month,
        GLSDD AS GLSDD_Source_Day,
        GLBDIS AS GLBDIS_Billing_Distribution_Center,
        GLRPTY AS GLRPTY_Report_Type,
        GLRP# AS GLRP#_Report_Number,
        GLEXDT AS GLEXDT_External_Date,
        GLEXTM AS GLEXTM_External_Time,
        GLPGM AS GLPGM_Program_Code,
        GLDSP AS GLDSP_Distribution_Point,
        GLUSER AS GLUSER_User,
        GLTIME AS GLTIME_Time,
        GLTRNT AS GLTRNT_Transaction_Type,
        GLTYPE AS GLTYPE_TYPE,
        GLTRDS AS GLTRDS_Transaction_Distribution_Sequence,
        GLMLIN AS GLMLIN_Multi_line_Number,
        GLCDIS AS GLCDIS_Customer_Distribution_Code,
        GLAPTR AS GLAPTR_AP_Transaction_Reference,
        GLLOCK AS GLLOCK_Lock_Flag,
        GLRFCC AS GLRFCC_Reference_Century,
        GLRFYY AS GLRFYY_Reference_Year,
        GLRFMM AS GLRFMM_Reference_Month,
        GLRFDD AS GLRFDD_Reference_Day,
        GLAMTQ AS GLAMTQ_Quantified_Amount,
        GLREF_CLEAN AS GLREF_CLEAN_Clean_Reference,
        GLREF_REV AS GLREF_REV_Reversal_Reference
    FROM GLTRANS

END

/*******************************************************************
RELATE SHIPMASTER AND GL
*********************************************************************/


SELECT 
    g.GLREF AS GL_Reference,
    g.GLDESC AS GL_Description,
    g.GLAMT AS GL_Amount,
    g.GLCUST AS GL_Customer,
    g.GLCSTC AS GL_Cost_Center,
    g.GLACCT AS GL_Account,
    s.SHORDN AS Sales_Order,
    s.SHCUST,
    s.SHITEM,
    s.SHTPCS,
    s.SHTLBS,
    s.SHTFTS,
    s.SHIPYY,
    s.SHIPMM,
    s.SHIPDD,
    s.SHFRGH
FROM 
    GLTRANS g
JOIN 
    ShipMast s
    ON g.GLREF = s.SHORDN
WHERE 
    g.GLAMT IS NOT NULL
    AND s.SHTPCS > 0
ORDER BY 
    g.GLREF;


select GLTRANS.GLAMT, SHIPMAST.SHMSLS
FROM
    GLTRANS, SHIPMAST
    WHERE
    GLTRANS.GLPYY = 25 AND GLTRANS.GLPMM = 2 
    AND SHIPMAST.SHIVYY = 25 AND SHIPMAST.SHIVMM = 2 


USE SIGMATB;    
Select count(*) from [z_A/P_History_____APHIST];

USE SIGMATB;    
select TOP(100) * FROM [z_General_Ledger_Transaction_File_____GLTRANS]


/******************************************
create a SCHEMA TO DIFFERENCIATE THE RENAMED TABLES
********************************************/
USE SigmaTB;
GO
CREATE SCHEMA myRenamedSchema;


/******************************************
Verify tables to move
********************************************/

SELECT COUNT(*)
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME LIKE 'z_%';


/******************************************
MOve from schema to schema
********************************************/
    USE SigmaTB;
    GO

    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Create the new schema if it doesn't exist
        IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'myRenamedSchema')
        BEGIN
            EXEC('CREATE SCHEMA myRenamedSchema');
            PRINT 'Schema myRenamedSchema created successfully';
        END

        -- Create a temporary table to store the tables to be moved
        CREATE TABLE #TablesToMove (
            TableName NVARCHAR(128),
            OldSchema NVARCHAR(128),
            NewSchema NVARCHAR(128)
        );

        -- Insert tables that start with 'z_' into the temporary table
        INSERT INTO #TablesToMove (TableName, OldSchema, NewSchema)
        SELECT 
            t.name AS TableName,
            s.name AS OldSchema,
            'myRenamedSchema' AS NewSchema
        FROM sys.tables t
        INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE t.name LIKE 'z_%'
        AND s.name = 'dbo';

        -- Declare variables for cursor
        DECLARE @TableName NVARCHAR(128);
        DECLARE @OldSchema NVARCHAR(128);
        DECLARE @NewSchema NVARCHAR(128);
        DECLARE @SQL NVARCHAR(MAX);

        -- Create cursor to iterate through tables
        DECLARE table_cursor CURSOR FOR
        SELECT TableName, OldSchema, NewSchema
        FROM #TablesToMove;

        OPEN table_cursor;
        FETCH NEXT FROM table_cursor INTO @TableName, @OldSchema, @NewSchema;

        -- Move each table
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @SQL = 'ALTER SCHEMA ' + QUOTENAME(@NewSchema) + ' TRANSFER ' + QUOTENAME(@OldSchema) + '.' + QUOTENAME(@TableName);
            EXEC sp_executesql @SQL;
            PRINT 'Moved table ' + @TableName + ' from ' + @OldSchema + ' to ' + @NewSchema;

            FETCH NEXT FROM table_cursor INTO @TableName, @OldSchema, @NewSchema;
        END;

        CLOSE table_cursor;
        DEALLOCATE table_cursor;

        -- Drop temporary table
        DROP TABLE #TablesToMove;

        -- If we get here, everything worked
        COMMIT TRANSACTION;
        PRINT 'All tables moved successfully';
    END TRY
    BEGIN CATCH
        -- If there's an error, roll back the transaction
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Print error information
        PRINT 'Error occurred:';
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10));
    END CATCH;

    