USE SigmaTB;

/*****************************************
01. We look for exact matches between the columns of GLTRANS and the columns of the other tables
*****************************************/
SELECT 
    'GLTRANS' AS SourceTableCode,
    '[SigmaTB].dbo.[z_General_Ledger_Transaction_File_____GLTRANS]' AS SourceTableName,
    c.name AS SourceColumnCode,
    CASE 
        WHEN CHARINDEX('_____', c.name) > 0 
        THEN SUBSTRING(c.name, CHARINDEX('_____', c.name) + 5, LEN(c.name))
        ELSE c.name
    END AS SourceColumnName,
    NULL AS ForeignTableCode,
    NULL AS ForeignTableName,
    NULL AS ForeignColumnCode,
    NULL AS ForeignColumnName
FROM sys.columns c
WHERE c.object_id = OBJECT_ID('GLTRANS')
AND c.name IN (
    'GLACCT',
    'GLBTCH',
    'GLREF',
    'GLTRNT',
    'GLTRN#',
    'GLAMT',
    'GLAMTQ'
);


/*****************************************
02. We look for similar matches between the columns of GLTRANS and the columns of the other tables
by using wildcards for the first 2 characters of the column name
*****************************************/


USE SigmaTB;

WITH TargetColumns AS (
    SELECT 
        SUBSTRING(column_name, 3, 4) AS column_suffix
    FROM (VALUES 
        ('GLACCT'),
        ('GLBTCH'),
        ('GLREF'),
        ('GLTRNT'),
        ('GLTRN#'),
        ('GLAMT'),
        ('GLAMTQ')
    ) AS cols(column_name)
)
SELECT 
    'GLTRANS' AS SourceTableCode,
    '[SigmaTB].dbo.[z_General_Ledger_Transaction_File_____GLTRANS]' AS SourceTableName,
    c1.name AS SourceColumnCode,
    CASE 
        WHEN CHARINDEX('_____', c1.name) > 0 
        THEN SUBSTRING(c1.name, CHARINDEX('_____', c1.name) + 5, LEN(c1.name))
        ELSE c1.name
    END AS SourceColumnName,
    OBJECT_NAME(c2.object_id) AS ForeignTableCode,
    '[SigmaTB].dbo.[z_' + OBJECT_NAME(c2.object_id) + ']' AS ForeignTableName,
    c2.name AS ForeignColumnCode,
    CASE 
        WHEN CHARINDEX('_____', c2.name) > 0 
        THEN SUBSTRING(c2.name, CHARINDEX('_____', c2.name) + 5, LEN(c2.name))
        ELSE c2.name
    END AS ForeignColumnName
FROM sys.columns c1
CROSS JOIN TargetColumns tc
JOIN sys.columns c2 ON 
    c2.object_id != c1.object_id AND
    c2.name LIKE '%%' + tc.column_suffix
WHERE 
    c1.object_id = OBJECT_ID('GLTRANS')
    AND c1.name IN (
        'GLACCT',
        'GLBTCH',
        'GLREF',
        'GLTRNT',
        'GLTRN#',
        'GLAMT',
        'GLAMTQ'
    )
ORDER BY 
    SourceColumnCode,
    ForeignTableCode,
    ForeignColumnCode;


/*****************************************
03. We look for similar matches between the columns of GLTRANS and the columns of the other tables
by using wildcards for the first 2 characters of the column name
With description of the column name
*****************************************/
USE SigmaTB;

WITH TargetColumns AS (
    SELECT 
        SUBSTRING(column_name, 3, 4) AS column_suffix
    FROM (VALUES 
        ('GLACCT'),
        ('GLBTCH'),
        ('GLREF'),
        ('GLTRNT'),
        ('GLTRN#'),
        ('GLAMT'),
        ('GLAMTQ')
    ) AS cols(column_name)
)
SELECT 
    'GLTRANS' AS SourceTableCode,
    (SELECT value FROM sys.extended_properties      --name
     WHERE major_id = OBJECT_ID('GLTRANS') 
     AND minor_id = 0 
     AND name = 'MS_Description') AS SourceTableName,
    c1.name AS SourceColumnCode,
    (SELECT value FROM sys.extended_properties 
     WHERE major_id = OBJECT_ID('GLTRANS') 
     AND minor_id = c1.column_id 
     AND name = 'MS_Description') AS SourceColumnName,
    OBJECT_NAME(c2.object_id) AS ForeignTableCode,
    (SELECT value FROM sys.extended_properties 
     WHERE major_id = c2.object_id 
     AND minor_id = 0 
     AND name = 'MS_Description') AS ForeignTableName,
    c2.name AS ForeignColumnCode,
    (SELECT value FROM sys.extended_properties 
     WHERE major_id = c2.object_id 
     AND minor_id = c2.column_id 
     AND name = 'MS_Description') AS ForeignColumnName
FROM sys.columns c1
CROSS JOIN TargetColumns tc
JOIN sys.columns c2 ON 
    c2.object_id != c1.object_id AND
    c2.name LIKE '%%' + tc.column_suffix
WHERE 
    c1.object_id = OBJECT_ID('GLTRANS')
    AND c1.name IN (
        'GLACCT',
        'GLBTCH',
        'GLREF',
        'GLTRNT',
        'GLTRN#',
        'GLAMT',
        'GLAMTQ'
    )
ORDER BY 
    SourceColumnCode,
    ForeignTableCode,
    ForeignColumnCode;


/*****************************************
04. We look for similar matches between the columns of GLTRANS and the columns of the other tables
by using wildcards for the first 2 characters of the column name
With description of the column name
Now we group by object level. 
*****************************************/
USE SigmaTB;

WITH TargetColumns AS (
    SELECT 
        SUBSTRING(column_name, 3, 4) AS column_suffix
    FROM (VALUES 
        ('GLACCT'),
        ('GLBTCH'),
        ('GLREF'),
        ('GLTRNT'),
        ('GLTRN#'),
        ('GLAMT'),
        ('GLAMTQ')
    ) AS cols(column_name)
)
SELECT 
    (SELECT value FROM sys.extended_properties 
     WHERE major_id = OBJECT_ID('GLTRANS') 
     AND minor_id = 0 
     AND name = 'MS_Description') AS SourceTableName,
    (SELECT value FROM sys.extended_properties 
     WHERE major_id = c2.object_id 
     AND minor_id = 0 
     AND name = 'MS_Description') AS ForeignTableName,
    (SELECT value FROM sys.extended_properties 
     WHERE major_id = OBJECT_ID('GLTRANS') 
     AND minor_id = c1.column_id 
     AND name = 'MS_Description') AS SourceColumnName,
    (SELECT value FROM sys.extended_properties 
     WHERE major_id = c2.object_id 
     AND minor_id = c2.column_id 
     AND name = 'MS_Description') AS ForeignColumnName,
    'GLTRANS' AS SourceTableCode,
    OBJECT_NAME(c2.object_id) AS ForeignTableCode,
    c1.name AS SourceColumnCode,
    c2.name AS ForeignColumnCode
FROM sys.columns c1
CROSS JOIN TargetColumns tc
JOIN sys.columns c2 ON 
    c2.object_id != c1.object_id AND
    c2.name LIKE '%%' + tc.column_suffix
WHERE 
    c1.object_id = OBJECT_ID('GLTRANS')
    AND c1.name IN (
        'GLACCT',
        'GLBTCH',
        'GLREF',
        'GLTRNT',
        'GLTRN#',
        'GLAMT',
        'GLAMTQ'
    )
ORDER BY 
    SourceColumnCode,
    ForeignTableCode,
    ForeignColumnCode;


/*****************************************
Check extended properties for 1 table
*****************************************/
SELECT 
    SCHEMA_NAME(t.schema_id) AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ep.name AS property_name,
    ep.value AS property_value
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id
LEFT JOIN sys.extended_properties ep ON 
    ep.major_id = t.object_id 
    AND ep.minor_id = c.column_id
    --AND ep.name = 'MS_Description'
WHERE t.name = 'z_General_Ledger_Transaction_File_____GLTRANS'  -- Replace with your table name
--ORDER BY t.name, c.name;


USE SigmaTB;
EXEC sp_refreshsqlmodule '[dbo].[z_General_Ledger_Transaction_File_____GLTRANS]';

select top(1) * from   [z_General_Ledger_Transaction_File_____GLTRANS]

USE SigmaTB;

-- First, let's list all tables to see the exact name
SELECT 
    SCHEMA_NAME(schema_id) AS schema_name,
    name AS table_name,
    type_desc
FROM sys.tables
WHERE name LIKE '%GLTRANS%';

-- Let's also check if it might be a view instead
SELECT 
    SCHEMA_NAME(schema_id) AS schema_name,
    name AS object_name,
    type_desc
FROM sys.objects
WHERE name LIKE '%GLTRANS%';

-- Let's check permissions
SELECT HAS_PERMS_BY_NAME('dbo.[z_General_Ledger_Transaction_File_____GLTRANS]', 'OBJECT', 'ALTER') AS HasAlterPermission;

/*****************************************
Check extended properties for all tables
*****************************************/
SELECT 
    SCHEMA_NAME(t.schema_id) AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ep.name AS property_name,
    ep.value AS property_value
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id
LEFT JOIN sys.extended_properties ep ON 
    ep.major_id = t.object_id 
    AND ep.minor_id = c.column_id
    AND ep.name = 'MS_Description'
ORDER BY t.name, c.name;


/*****************************************
Check extended properties for all tables
*****************************************/
-- =============================================
-- Script to Add/Update Extended Properties based on Naming Convention
-- Target: Tables starting with 'z_' and their columns
-- Logic:
--   Property Name = Derived Code (part after last '_____')
--   Property Value = Original Full Name (Table or Column)
-- WARNING: Backup database before running.
-- WARNING: Uses non-standard approach of dynamic property names.
-- =============================================
USE SigmaTB; -- <<<<<<<<<<<< CHANGE THIS TO YOUR DATABASE NAME
GO

BEGIN TRANSACTION;

BEGIN TRY

    -- =============================================
    -- 1. Verification / Reporting (Optional)
    --    List tables/columns starting with z_ that currently have NO extended properties at all.
    -- =============================================
    use SigmaTB;
    PRINT N'--- Verification: Tables starting with z_ with NO existing extended properties ---';
    SELECT
        s.name AS SchemaName,
        t.name AS TableName,
        ep.value as ExtendedProperty
    FROM sys.tables t
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    LEFT JOIN sys.extended_properties ep ON 
        ep.major_id = t.object_id 
        AND ep.minor_id = 0  -- Table level property
        AND ep.class = 1     -- Object or column
    WHERE t.name LIKE N'z_%'
    ORDER BY SchemaName, TableName;


/*****************************************
Return tables and columns without extended properties
*****************************************/
    PRINT N'--- Verification: Columns in tables starting with z_ with NO existing extended properties ---';
    SELECT
        s.name AS SchemaName,
        t.name AS TableName,
        c.name AS ColumnName,
        ep.value as ExtendedProperty
    FROM sys.columns c
    INNER JOIN sys.tables t ON c.object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    LEFT JOIN sys.extended_properties ep ON 
        ep.major_id = t.object_id
        AND ep.minor_id = c.column_id  -- Column level property
        AND ep.class = 1               -- Object or column
    WHERE t.name LIKE N'z_%'
        AND ep.value IS NULL          -- This ensures we only get columns without properties
    ORDER BY SchemaName, TableName, ColumnName;

