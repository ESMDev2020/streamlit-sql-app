 
USE SigmaTB;


-- create ROP data table
CREATE TABLE ROPData (
    [Unnamed: 0] VARCHAR(34),
    [Unnamed: 1] VARCHAR(6),
    [Unnamed: 2] VARCHAR(8),
    [Unnamed: 3] VARCHAR(8),
    [Unnamed: 4] VARCHAR(8),
    [Unnamed: 5] VARCHAR(13),
    [Unnamed: 6] VARCHAR(8),
    [Unnamed: 7] VARCHAR(7),
    [Unnamed: 8] VARCHAR(7),
    [Unnamed: 9] VARCHAR(8),
    [Unnamed: 10] VARCHAR(8),
    [Unnamed: 11] VARCHAR(16),
    [Unnamed: 12] VARCHAR(8),
    [Unnamed: 13] VARCHAR(9),
    [Unnamed: 14] VARCHAR(9),
    [Unnamed: 15] VARCHAR(9),
    [Unnamed: 16] VARCHAR(7),
    [Unnamed: 17] VARCHAR(7),
    [Unnamed: 18] VARCHAR(9),
    [Unnamed: 19] VARCHAR(9),
    [Unnamed: 20] VARCHAR(9),
    [Unnamed: 21] DECIMAL(18,2),
    [Unnamed: 22] DECIMAL(18,2),
    [Unnamed: 23] VARCHAR(7),
    [Unnamed: 24] DECIMAL(18,2),
    [Unnamed: 25] DECIMAL(18,2),
    [Unnamed: 26] DECIMAL(18,2),
    [Unnamed: 27] DECIMAL(18,2),
    [Unnamed: 28] DECIMAL(18,2)
);

--Create BasePrice table
CREATE TABLE BasePrice (
    [IOITEM] INT,
    [IOBPRC] DECIMAL(18,2)
);

--Create SalesData table
CREATE TABLE SalesData (
    [OORECD] VARCHAR(6),
    [ODTYPE] VARCHAR(6),
    [ODITEM] VARCHAR(6),
    [OOCUST] VARCHAR(6),
    [ODTLBS] VARCHAR(8),
    [ ODTFTS ] VARCHAR(11),
    [ ODORDR ] VARCHAR(6),
    [ CALPHA ] VARCHAR(26),
    [ 00009 ] INT,
    [Unnamed: 9] INT,
    [Unnamed: 10] VARCHAR(11),
    [Unnamed: 11] DECIMAL(18,2),
    [ 22,121.244 ] DECIMAL(18,2)
);

--Create UsageData table
CREATE TABLE UsageData (
    [Unnamed: 0] VARCHAR(6),
    [Unnamed: 1] VARCHAR(6),
    [Unnamed: 2] VARCHAR(6),
    [Unnamed: 3] VARCHAR(8),
    [Unnamed: 4] VARCHAR(8),
    [ Start Date ] VARCHAR(9),
    [Unnamed: 6] VARCHAR(8),
    [Unnamed: 7] VARCHAR(8),
    [Unnamed: 8] VARCHAR(8),
    [Unnamed: 9] VARCHAR(8),
    [2024 02 29] VARCHAR(31),
    [ item_XxDocmntVendrCstmrDatedate ] VARCHAR(10),
    [Unnamed: 12] VARCHAR(7),
    [Unnamed: 13] DECIMAL(18,2),
    [Unnamed: 14] VARCHAR(6),
    [Unnamed: 15] VARCHAR(3),
    [Unnamed: 16] DECIMAL(18,2),
    [Unnamed: 17] DECIMAL(18,2),
    [Unnamed: 18] VARCHAR(6),
    [Unnamed: 19] DECIMAL(18,2),
    [Unnamed: 20] DECIMAL(18,2),
    [Unnamed: 21] DECIMAL(18,2),
    [Unnamed: 22] VARCHAR(6),
    [Unnamed: 23] VARCHAR(6),
    [Unnamed: 24] VARCHAR(8),
    [Unnamed: 25] VARCHAR(29),
    [Unnamed: 26] DECIMAL(18,2)
);

--Create TagData
CREATE TABLE TagData (
    [Item] VARCHAR(6),
    [Tag] VARCHAR(7),
    [Description] VARCHAR(20),
    [Pc Len] VARCHAR(6),
    [Pcs] VARCHAR(6),
    [ Length ] VARCHAR(9),
    [ Heat ] VARCHAR(8),
    [ Lot ] VARCHAR(8),
    [ Loc ] VARCHAR(8),
    [ OnHand ] VARCHAR(9),
    [ Reserved ] VARCHAR(9),
    [ Avail ] VARCHAR(9),
    [Unnamed: 12] VARCHAR(28),
    [ remnants ] VARCHAR(6),
    [Unnamed: 14] DECIMAL(18,2),
    [Unnamed: 15] VARCHAR(7),
    [Unnamed: 16] DECIMAL(18,2)
);

-- Create POData
CREATE TABLE POData (
    [ PO ] VARCHAR(8),
    [ V# ] VARCHAR(8),
    [Vendor] VARCHAR(8),
    [Code] VARCHAR(6),
    [Item] VARCHAR(6),
    [Description] VARCHAR(24),
    [Original] VARCHAR(10),
    [Due Date] VARCHAR(10),
    [Received] VARCHAR(10),
    [ Ordered ] VARCHAR(8),
    [ Received ] VARCHAR(8),
    [UOM] VARCHAR(6),
    [ Due ] VARCHAR(8),
    [Unnamed: 13] DECIMAL(18,2),
    [Unnamed: 14] VARCHAR(8),
    [Unnamed: 15] VARCHAR(7),
    [Unnamed: 16] VARCHAR(20),
    [Unnamed: 17] VARCHAR(6),
    [Unnamed: 18] VARCHAR(6),
    [Unnamed: 19] VARCHAR(32),
    [Unnamed: 20] VARCHAR(10),
    [Unnamed: 21] VARCHAR(10),
    [Unnamed: 22] VARCHAR(10),
    [Unnamed: 23] VARCHAR(8),
    [Unnamed: 24] VARCHAR(9),
    [Unnamed: 25] VARCHAR(6),
    [Unnamed: 26] VARCHAR(8)
);

--Verify that the tables were created
Select TABLE_NAME from INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE';

--check permissions
SELECT SUSER_NAME();



--Enable FileAccess for SQL server
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;

--Get the CSV files into the S3 repository into the RDC environment.. crazy complexity
EXEC msdb.dbo.rds_download_from_s3
    'arn:aws:s3:::esmbucket2/ROPData.csv',  -- S3 file ARN
    'D:\S3\ROPData.csv',  -- Target path in RDS
    1;  -- Overwrite if file exists

--Verify if file was imported
EXEC msdb.dbo.rds_file_list;

--Edition doesnt allow
SELECT SERVERPROPERTY('Edition'), SERVERPROPERTY('EngineEdition');


--Verify the import
SELECT * FROM ROPData;


BULK INSERT BasePrice FROM '/Users/bmate/Downloads/BasePrice.csv'


-- Now, import the data
BULK INSERT BasePrice FROM 'C:\Administrator\Downloads\BasePrice.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', TABLOCK);

BULK INSERT ROPData FROM 'C:\Administrator\Downloads\ROPData.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', TABLOCK);

BULK INSERT SalesData FROM 'C:\Administrator\Downloads\SalesData.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', TABLOCK);

BULK INSERT UsageData FROM 'C:\Administrator\Downloads\UsageData.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', TABLOCK);

BULK INSERT TagData FROM 'C:\Administrator\Downloads\TagData.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', TABLOCK);

BULK INSERT POData FROM 'C:\Administrator\Downloads\POData.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', TABLOCK);


--Delete all tables and start again
DECLARE @sql NVARCHAR(MAX) = N'';

-- Generate DROP TABLE commands for all user tables
SELECT @sql += 'DROP TABLE IF EXISTS ' + QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME) + '; ' + CHAR(13)
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';

-- Execute the generated SQL
EXEC sp_executesql @sql;

-- end deleting tables


--///////////////////////////////////////
--add
ALTER TABLE BasePrice
ADD IOITEM_int INT NULL,
    IOBPRC_num NUMERIC(10, 2) NULL;


--copy
UPDATE BasePrice
SET IOITEM_int = TRY_CAST(CAST(IOITEM AS VARCHAR) AS INT),
    IOBPRC_num = TRY_CAST(CAST(IOBPRC AS VARCHAR) AS NUMERIC(10, 2));

--drop
ALTER TABLE BasePrice
DROP COLUMN IOITEM;

ALTER TABLE BasePrice
DROP COLUMN IOBPRC;

-- rename
EXEC sp_rename 'BasePrice.IOITEM_int', 'IOITEM', 'COLUMN';
EXEC sp_rename 'BasePrice.IOBPRC_num', 'IOBPRC', 'COLUMN';

--///////////////////////////////////////////

--GET THE NAME AND DATATYPE OF FIELDS - INFORMATION SCHEMA
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM 
    INFORMATION_SCHEMA.COLUMNS
WHERE 
    TABLE_NAME = 'ROPData'  -- Replace with your actual table name
    AND TABLE_SCHEMA = 'dbo';


--////////////////////////////////////////////////////////
--GET THE NAME AND DATATYPE FROM SYS.COLUMNS
use sigmatb;

SELECT 
    c.name AS ColumnName,
    t.name AS DataType,
    c.max_length AS MaxLength,
    c.precision,
    c.scale,
    CASE 
        WHEN c.is_nullable = 1 THEN 'YES'
        ELSE 'NO'
    END AS IsNullable
FROM 
    sys.columns c
JOIN 
    sys.types t ON c.user_type_id = t.user_type_id
WHERE 
    c.object_id = OBJECT_ID('dbo.ROPData');  -- Replace with your table name

--///////////////////////////////////////////////////////

USE SigmaTB;

CREATE TABLE VendorLead (
    [Unique] BIT,                -- Whether the row is unique/applicable (converted from TRUE/FALSE)
    Description NVARCHAR(255),   -- Description of the vendor or group
    Notes NVARCHAR(255),         -- Additional notes or alternate name
    Code NVARCHAR(10),           -- Short code for the vendor
    wks INT,                     -- Lead time in weeks (may include -363, for review)
    Used INT,                    -- Number of times used
    Updated DATE,                -- Last update date
    Delivery DATE                -- Optional delivery date (some values may be empty)
);


-- Check if the column exists, then drop it
IF EXISTS (
    SELECT 1 
    FROM sys.columns 
    WHERE Name = N'GLREF_REV' AND Object_ID = Object_ID(N'GLTRANS')
)
BEGIN
    ALTER TABLE GLTRANS DROP COLUMN GLREF_REV;
END

/************************************
Check indexes
***************************************/
SELECT 
    i.name AS IndexName,
    i.type_desc AS IndexType,
    c.name AS ColumnName,
    ic.key_ordinal AS OrdinalPosition
FROM sys.indexes i
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE i.object_id = OBJECT_ID('GLTRANS')
  AND c.name = 'GLREF_REV';


/************************************
***************************************/
use sigmatb;
select top 1 * from gltrans

-- Step 1: Add reverse-computed column
ALTER TABLE GLTRANS
ADD GLREF_REV AS REVERSE(GLREF) PERSISTED;

-- Step 2: Index the computed column
CREATE INDEX IX_GLTRANS_GLREF_REV ON GLTRANS(GLREF_REV);

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


/**************************************************************************
--Get the list, name, rowsize and datatype of the colums
**************************************************************************/
BEGIN
    USE sigmatb;

    -- Temp table to store row counts
    IF OBJECT_ID('tempdb..#TableRowCounts') IS NOT NULL DROP TABLE #TableRowCounts;

    SELECT 
        t.name AS TableName,
        SUM(p.rows) AS myRowCount
    INTO #TableRowCounts
    FROM 
        sys.tables t
        INNER JOIN sys.partitions p ON t.object_id = p.object_id
    WHERE 
        p.index_id IN (0, 1) -- 0 = Heap, 1 = Clustered index
    GROUP BY 
        t.name;

    -- Main query: table name, row count, field name, datatype
    SELECT 
        trc.TableName,
        trc.myRowCount,
        c.name AS FieldName,
        TYPE_NAME(c.user_type_id) AS FieldDataType
    FROM 
        #TableRowCounts trc
        INNER JOIN sys.columns c ON OBJECT_ID(trc.TableName) = c.object_id
    ORDER BY 
        trc.TableName,
        c.column_id;
END


/**************************************************************************
--Download a sample of the data for each table 
**************************************************************************/
--Prepare the list of queries
BEGIN
    USE SigmaTB;

    -- This query generates SELECT statements for each table to pull a sample of 1000 rows
    -- You can then run the output or copy/paste as needed to export each result

    SELECT 
        'SELECT TOP 1000 * FROM [' + s.name + '].[' + t.name + ']' AS SampleQuery,
        s.name AS SchemaName,
        t.name AS TableName
    FROM 
        sys.tables t
        INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    ORDER BY 
        s.name, t.name;
END

--Execute the generated queries to get the sample data
BEGIN
    USE sigma;

    SELECT TOP 1000 * FROM [dbo].[APVEND];
    SELECT TOP 1000 * FROM [dbo].[ARCUST];
    SELECT TOP 1000 * FROM [dbo].[BasePrice];
    SELECT TOP 1000 * FROM [dbo].[CreditMemos];
    SELECT TOP 1000 * FROM [dbo].[CustomerSummary];
    SELECT TOP 1000 * FROM [dbo].[Details];
    SELECT TOP 1000 * FROM [dbo].[GLACCT];
    SELECT TOP 1000 * FROM [dbo].[GLTRANS];
    SELECT TOP 1000 * FROM [dbo].[GLTRANS_BACKUP];
    SELECT TOP 1000 * FROM [dbo].[GLTRANS_Data];
    SELECT TOP 1000 * FROM [dbo].[ITEMHIST];
    SELECT TOP 1000 * FROM [dbo].[ITEMMAST];
    SELECT TOP 1000 * FROM [dbo].[ITEMONHD];
    SELECT TOP 1000 * FROM [dbo].[ITEMTAG];
    SELECT TOP 1000 * FROM [dbo].[MPDETAIL];
    SELECT TOP 1000 * FROM [dbo].[OEDETAIL];
    SELECT TOP 1000 * FROM [dbo].[OEOPNORD];
    SELECT TOP 1000 * FROM [dbo].[POData];
    SELECT TOP 1000 * FROM [dbo].[PODETAIL];
    SELECT TOP 1000 * FROM [dbo].[POIssued];
    SELECT TOP 1000 * FROM [dbo].[Query_GL];
    SELECT TOP 1000 * FROM [dbo].[ROP];
    SELECT TOP 1000 * FROM [dbo].[ROPData];
    SELECT TOP 1000 * FROM [dbo].[SalesData];
    SELECT TOP 1000 * FROM [dbo].[Salesman];
    SELECT TOP 1000 * FROM [dbo].[SalesmanSummary];
    SELECT TOP 1000 * FROM [dbo].[SalesOrders];
    SELECT TOP 1000 * FROM [dbo].[SHIPMAST];
    SELECT TOP 1000 * FROM [dbo].[SHIPMAST_filtered];
    SELECT TOP 1000 * FROM [dbo].[SLSDSCOV];
    SELECT TOP 1000 * FROM [dbo].[SPO];
    SELECT TOP 1000 * FROM [dbo].[TagData];
    SELECT TOP 1000 * FROM [dbo].[UsageData];
    SELECT TOP 1000 * FROM [dbo].[UsageData2];
    SELECT TOP 1000 * FROM [dbo].[VendorLead];

END

USE SigmaTB;

ALTER TABLE [dbo].[SpHeader]
ADD CONSTRAINT DF_SpHeader_BSPFMX DEFAULT ' ' FOR [BSPFMX];


CREATE TABLE [dbo].[SpHeader] (
    [BSRECD] CHAR(1) NOT NULL,
    [BSTRNT] CHAR(2) NOT NULL,
    [BSCOMP] NUMERIC(2,0) NOT NULL,
    [BSDIST] NUMERIC(2,0) NOT NULL,
    [BSORDR] NUMERIC(6,0) NOT NULL,
    [BSVNDR] NUMERIC(7,0) NOT NULL,
    [BSSVEN] NUMERIC(7,0) NOT NULL,
    [BSSHIP] NUMERIC(2,0) NOT NULL,
    [BSMAIL] NUMERIC(2,0) NOT NULL,
    [BSDUCC] NUMERIC(2,0) NOT NULL,
    [BSDUYY] NUMERIC(2,0) NOT NULL,
    [BSDUMM] NUMERIC(2,0) NOT NULL,
    [BSDUDD] NUMERIC(2,0) NOT NULL,
    [BSCONF] CHAR(20) NOT NULL,
    [BSCOCC] NUMERIC(2,0) NOT NULL,
    [BSCOYY] NUMERIC(2,0) NOT NULL,
    [BSCOMM] NUMERIC(2,0) NOT NULL,
    [BSCODD] NUMERIC(2,0) NOT NULL,
    [BSBILL] CHAR(1) NOT NULL,
    [BSSVIA] NUMERIC(2,0) NOT NULL,
    [BSSVDS] CHAR(20) NOT NULL,
    [BSFRCD] NUMERIC(2,0) NOT NULL,
    [BSTERM] NUMERIC(2,0) NOT NULL,
    [BSFOB] NUMERIC(2,0) NOT NULL,
    [BSPOCC] NUMERIC(2,0) NOT NULL,
    [BSPOYY] NUMERIC(2,0) NOT NULL,
    [BSPOMM] NUMERIC(2,0) NOT NULL,
    [BSPODD] NUMERIC(2,0) NOT NULL,
    [BSSMD#] NUMERIC(2,0) NOT NULL,
    [BSSMN#] DECIMAL NOT NULL,
    [BSCUD#] NUMERIC(2,0) NOT NULL,
    [BSCUS#] NUMERIC(5,0) NOT NULL,
    [BSSHCC] NUMERIC(2,0) NOT NULL,
    [BSSHYY] NUMERIC(2,0) NOT NULL,
    [BSSHMM] NUMERIC(2,0) NOT NULL,
    [BSSHDD] NUMERIC(2,0) NOT NULL,
    [BSRPRT] CHAR(1) NOT NULL,
    [BSPRNT] CHAR(1) NOT NULL,
    [BSPFMX] CHAR(1) NOT NULL,
    [BSLANG] CHAR(3) NOT NULL,
    [BSFDTX] CHAR(1) NOT NULL,
    [BSPVTX] CHAR(1) NOT NULL,
    [BSSHTO] NUMERIC(3,0) NOT NULL,
    [BSDCP] CHAR(1) NOT NULL,
    [BSMOVP] CHAR(1) NOT NULL,
    [BSSPS#] NUMERIC(2,0) NOT NULL,
    [BSMOWO] DECIMAL NOT NULL,
    [BSTRAK] CHAR(4) NOT NULL,
    [BSPWS#] NUMERIC(2,0) NOT NULL,
    [BSIND] DECIMAL NOT NULL,
    [BSOUTD] DECIMAL NOT NULL,
    [BSWALL] DECIMAL NOT NULL,
    [BSDENF] DECIMAL NOT NULL,
    [BSWGTF] DECIMAL NOT NULL,
    [BSDESC] CHAR(35) NOT NULL,
    [BSIQTY] DECIMAL NOT NULL,
    [BSIUOM] CHAR(3) NOT NULL,
    [BSWDTH] DECIMAL NOT NULL,
    [BSLENG] DECIMAL NOT NULL,
    [BSCRTM] CHAR(1) NOT NULL,
    [BSMDST] NUMERIC(2,0) NOT NULL,
    [BSMORD] NUMERIC(6,0) NOT NULL,
    [BSTHIK] DECIMAL NOT NULL,
    [BSDES2] CHAR(35) NOT NULL,
    [BSMDSB] NUMERIC(2,0) NOT NULL,
    [BSMORB] NUMERIC(6,0) NOT NULL,
    [BSSWGT] CHAR(1) NOT NULL,
    [BSPQTY] DECIMAL NOT NULL,
    [BSPDSC] CHAR(35) NOT NULL,
    [BSPDS2] CHAR(35) NOT NULL,
    [BSOEIN] CHAR(1) NOT NULL
);


/**************************************************
**************************************************/
-- Delete all MS_Description properties from columns
USE SigmaTB;

DECLARE @sql NVARCHAR(MAX) = '';

SELECT @sql += '
EXEC sp_dropextendedproperty 
    @name = N''MS_Description'', 
    @level0type = N''SCHEMA'', @level0name = ''' + s.name + ''',
    @level1type = N''TABLE'',  @level1name = ''' + t.name + ''',
    @level2type = N''COLUMN'', @level2name = ''' + c.name + ''';'
FROM sys.extended_properties ep
JOIN sys.tables t ON ep.major_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.columns c ON ep.major_id = c.object_id AND ep.minor_id = c.column_id
WHERE ep.name = 'MS_Description';

-- Print or execute the generated SQL
-- PRINT @sql; -- for preview
EXEC sp_executesql @sql;


/**************************************************
Verify that we have comments in the tables
**************************************************/
    SELECT 
        t.name AS TableName,
        c.name AS ColumnName,
        ep.value AS ColumnDescription
    FROM 
        sys.extended_properties ep
    JOIN 
        sys.columns c ON ep.major_id = c.object_id AND ep.minor_id = c.column_id
    JOIN 
        sys.tables t ON c.object_id = t.object_id
    WHERE 
        ep.name = 'MS_Description'
    ORDER BY 
        t.name, c.column_id;


/**************************************************
Count the number of tables that start with z_
**************************************************/
    USE SigmaTB;

    SELECT 
        count(t.name) AS TableCount
    FROM
        sys.tables t 
    WHERE 
        t.name like 'z_%';

/**************************************************
--Number of columns in each table
**************************************************/

--Number of rows in each table
SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'SHIPMAST'

-- List all the objects
SELECT type_desc as ObjectType, name as ObjectName, SCHEMA_NAME(schema_id) as schema_name, * from sys.all_objects ORDER BY SCHEMA_ID('SYS'), type_desc, name;

-- List all the columns in sys.tables where the schema is 'dbo'
BEGIN 
    SELECT
        mytable.name, mycolumn.NAME, column_id, * --myColumn.name --AS column_name
    FROM
        sys.tables AS myTable
    INNER JOIN
        sys.columns AS myColumn ON myTable.object_id = myColumn.object_id       -- table and column
    INNER JOIN
        sys.schemas AS mySchema ON myTable.schema_id = mySchema.schema_id       -- table and schema
    WHERE
        mySchema.name = 'dbo';
END


-- Comments are Extended Properties

BEGIN 
    USE SigmaTB;

    SELECT
            major_id,       --name, value
            minor_id,
            class,
            class_desc,
            name,
            value
        FROM
            sys.extended_properties;

END

-- list al the columns and descriptions
BEGIN  

    -- List all the rows
     DECLARE @table_name NVARCHAR(255) = 'APVEND';

    SELECT mycolumn.name as "ColumnName", myExtendedProperties.VALUE as "Description"
        FROM sys.tables AS myTable,
            sys.columns AS myColumn,
            sys.extended_properties AS myExtendedProperties
        WHERE
            myTable.object_id = myColumn.object_id
            AND myExtendedProperties.major_id = myTable.object_id
            AND myExtendedProperties.minor_id = myColumn.column_id
            AND myTable.name = @table_name;

    -- List all the rows
    PRINT 'Number or columns' 
    SELECT  count(mycolumn.name)  AS "Number of columns"
    FROM sys.tables AS myTable,
        sys.columns AS myColumn,
        sys.extended_properties AS myExtendedProperties
    WHERE
        myTable.object_id = myColumn.object_id
        AND myExtendedProperties.major_id = myTable.object_id
        AND myExtendedProperties.minor_id = myColumn.column_id
        AND myTable.name = @table_name;
   


    SELECT myTable.name AS myTableName, myColumn.name as myColumnName, myExtendedProperties.VALUE as myExtPropValue
    FROM sys.tables AS myTable,
        sys.columns AS myColumn,
        sys.extended_properties AS myExtendedProperties
    WHERE
        myTable.object_id = myColumn.object_id
        AND myExtendedProperties.major_id = myTable.object_id
        AND myExtendedProperties.minor_id = myColumn.column_id
        AND myTable.name = @table_name
        ORDER BY VALUE ASC;
END





select name, * from sys.tables where SCHEMA_NAME(schema_id) = 'dbo' and name = 'SHIPMAST';


-- List all the columns in sys
select * from SYS

-- Retrieve all the table names and their respective column counts
-- SCHEMA_NAME is a function that returns the name of the schema
-- schema_id is a column in sys.tables that identifies the schema of the table
-- sys.tables contains a row for each table object
-- sys.columns contains a row for each column of an object that has columns
-- sys.types contains a row for each system and user-defined data type
-- sys.objects contains a row for each object that is created within a database
-- sys.schemas contains a row for each schema in the database
-- schema is a container for database objects
-- Namespace is a containers for whatever object
BEGIN
    SELECT 
        SCHEMA_NAME(schema_id) AS schema_name,
        t.name AS table_name,
        c.name AS column_name,
        t1.name AS data_type
    FROM 
        sys.columns c
    JOIN 
        sys.tables t ON c.object_id = t.object_id
    JOIN 
        sys.types t1 ON c.user_type_id = t1.user_type_id
    ORDER BY 
        schema_name, table_name, column_id;
END