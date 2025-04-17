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
USE YourDatabaseName; -- <<<<<<<<<<<< CHANGE THIS TO YOUR DATABASE NAME
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


    -- =============================================
    -- 2 & 3. Update/Add Extended Properties
    -- =============================================
    PRINT N'--- Starting Extended Property Updates ---';

    DECLARE @SchemaName SYSNAME;
    DECLARE @TableName SYSNAME;
    DECLARE @ColumnName SYSNAME;
    DECLARE @TableCode NVARCHAR(128); -- Max length for extended property name
    DECLARE @ColumnCode NVARCHAR(128);
    DECLARE @OriginalTableName NVARCHAR(MAX);
    DECLARE @OriginalColumnName NVARCHAR(MAX);
    DECLARE @TableObjectId INT;
    DECLARE @ColumnId INT;
    DECLARE @Separator NVARCHAR(5) = N'_____';
    DECLARE @SeparatorPos INT;

    -- Cursor for tables starting with z_
    DECLARE TableCursor CURSOR FOR
        SELECT s.name, t.name, t.object_id
        FROM sys.tables t
        INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE t.name LIKE N'z_%';

    OPEN TableCursor;
    FETCH NEXT FROM TableCursor INTO @SchemaName, @TableName, @TableObjectId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @OriginalTableName = @TableName;
        SET @TableCode = NULL; -- Reset for each table

        -- Derive Table Code (part after the last separator)
        SET @SeparatorPos = LEN(@OriginalTableName) - CHARINDEX(REVERSE(@Separator), REVERSE(@OriginalTableName)) - LEN(@Separator) + 1;
        IF @SeparatorPos > 0 AND CHARINDEX(@Separator, @OriginalTableName) > 0 -- Check if separator exists
             BEGIN
               SET @TableCode = SUBSTRING(@OriginalTableName, @SeparatorPos + LEN(@Separator), LEN(@OriginalTableName));
             END
        ELSE
            BEGIN
             PRINT N'  WARNING: Separator "' + @Separator + N'" not found in table name "' + @OriginalTableName + N'". Skipping table property update.';
            END


        -- *** Update TABLE Extended Property ***
        IF @TableCode IS NOT NULL AND LEN(LTRIM(RTRIM(@TableCode))) > 0
        BEGIN
            PRINT N' Processing Table: [' + @SchemaName + N'].[' + @TableName + N'] -> Code: [' + @TableCode + N']';

            -- Check if property with this name already exists for the table
            IF EXISTS (SELECT 1 FROM sys.extended_properties ep
                       WHERE ep.major_id = @TableObjectId
                         AND ep.minor_id = 0 -- Table level
                         AND ep.class = 1
                         AND ep.name = @TableCode)
            BEGIN
                -- Update existing property
                EXEC sp_updateextendedproperty
                    @name = @TableCode,
                    @value = @OriginalTableName,
                    @level0type = N'SCHEMA', @level0name = @SchemaName,
                    @level1type = N'TABLE', @level1name = @TableName;
                PRINT N'   Updated TABLE property [' + @TableCode + N']';
            END
            ELSE
            BEGIN
                -- Add new property
                EXEC sp_addextendedproperty
                    @name = @TableCode,
                    @value = @OriginalTableName,
                    @level0type = N'SCHEMA', @level0name = @SchemaName,
                    @level1type = N'TABLE', @level1name = @TableName;
                 PRINT N'   Added TABLE property [' + @TableCode + N']';
            END
        END

        -- *** Update COLUMN Extended Properties for the current table ***
        DECLARE ColumnCursor CURSOR FOR
            SELECT c.name, c.column_id
            FROM sys.columns c
            WHERE c.object_id = @TableObjectId;

        OPEN ColumnCursor;
        FETCH NEXT FROM ColumnCursor INTO @ColumnName, @ColumnId;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @OriginalColumnName = @ColumnName;
            SET @ColumnCode = NULL; -- Reset for each column

             -- Derive Column Code (part after the last separator)
            SET @SeparatorPos = LEN(@OriginalColumnName) - CHARINDEX(REVERSE(@Separator), REVERSE(@OriginalColumnName)) - LEN(@Separator) + 1;
             IF @SeparatorPos > 0 AND CHARINDEX(@Separator, @OriginalColumnName) > 0 -- Check if separator exists
             BEGIN
                 SET @ColumnCode = SUBSTRING(@OriginalColumnName, @SeparatorPos + LEN(@Separator), LEN(@OriginalColumnName));
             END
             ELSE
             BEGIN
                 PRINT N'     WARNING: Separator "' + @Separator + N'" not found in column name "' + @OriginalColumnName + N'" for table [' + @TableName + N']. Skipping column property update.';
             END


             IF @ColumnCode IS NOT NULL AND LEN(LTRIM(RTRIM(@ColumnCode))) > 0
             BEGIN
                 -- Check if property with this name already exists for the column
                 IF EXISTS (SELECT 1 FROM sys.extended_properties ep
                            WHERE ep.major_id = @TableObjectId
                              AND ep.minor_id = @ColumnId -- Column level
                              AND ep.class = 1
                              AND ep.name = @ColumnCode)
                 BEGIN
                     -- Update existing property
                     EXEC sp_updateextendedproperty
                         @name = @ColumnCode,
                         @value = @OriginalColumnName,
                         @level0type = N'SCHEMA', @level0name = @SchemaName,
                         @level1type = N'TABLE', @level1name = @TableName,
                         @level2type = N'COLUMN', @level2name = @ColumnName;
                     PRINT N'   Updated COLUMN property [' + @ColumnCode + N'] for column [' + @OriginalColumnName + N']';

                 END
                 ELSE
                 BEGIN
                     -- Add new property
                     EXEC sp_addextendedproperty
                         @name = @ColumnCode,
                         @value = @OriginalColumnName,
                         @level0type = N'SCHEMA', @level0name = @SchemaName,
                         @level1type = N'TABLE', @level1name = @TableName,
                         @level2type = N'COLUMN', @level2name = @ColumnName;
                     PRINT N'   Added COLUMN property [' + @ColumnCode + N'] for column [' + @OriginalColumnName + N']';
                 END
             END

            FETCH NEXT FROM ColumnCursor INTO @ColumnName, @ColumnId;
        END

        CLOSE ColumnCursor;
        DEALLOCATE ColumnCursor;

        FETCH NEXT FROM TableCursor INTO @SchemaName, @TableName, @TableObjectId;
    END

    CLOSE TableCursor;
    DEALLOCATE TableCursor;

    PRINT N'--- Completed Extended Property Updates ---';

    -- If everything was successful, commit the transaction
    COMMIT TRANSACTION;
    PRINT N'Transaction Committed.';

END TRY
BEGIN CATCH
    -- If any error occurred, rollback the transaction
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT N'An error occurred: ' + ERROR_MESSAGE();
    PRINT N'Transaction Rolled Back.';

    -- Optional: Deallocate cursors if they are still open in case of error
    IF CURSOR_STATUS('global','TableCursor') >= 0 DEALLOCATE TableCursor;
    IF CURSOR_STATUS('global','ColumnCursor') >= 0 DEALLOCATE ColumnCursor;

    -- Re-throw the error
    THROW;
END CATCH
GO