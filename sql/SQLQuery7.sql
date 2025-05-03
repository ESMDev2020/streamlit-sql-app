/****************************************************************
ANALYSIS OF TABLES.
This reviews each column and describes the type of information
they store, and if we should keep them on a report

*****************************************************************/
--'[Sigmatb].[mrs].[z_Shipments_File_____SHIPMAST]'

DECLARE @TableName NVARCHAR(261) = '[Sigmatb].[mrs].[z_General_Ledger_Transaction_File_____GLTRANS]'; -- Use schema.table format, e.g., '[dbo].[YourTable]'
DECLARE @SQLAnalyze NVARCHAR(MAX);
DECLARE @SchemaName NVARCHAR(128) = PARSENAME(@TableName, 2);
DECLARE @BaseTableName NVARCHAR(128) = PARSENAME(@TableName, 1);

-- Use default schema if not provided in @TableName
IF @SchemaName IS NULL
BEGIN
    SET @SchemaName = SCHEMA_NAME(); -- Get the default schema for the current user
    SET @TableName = QUOTENAME(@SchemaName) + '.' + QUOTENAME(@BaseTableName); -- Rebuild full name
END
ELSE
BEGIN
     -- Ensure both parts are quoted if schema was provided
     SET @TableName = QUOTENAME(@SchemaName) + '.' + QUOTENAME(@BaseTableName);
END

-- Temp table to hold column metadata and calculated stats
IF OBJECT_ID('tempdb..#ColumnAnalysis') IS NOT NULL DROP TABLE #ColumnAnalysis;
CREATE TABLE #ColumnAnalysis (
    column_name NVARCHAR(128) PRIMARY KEY,
    data_type NVARCHAR(128),
    character_maximum_length INT,
    numeric_precision TINYINT,
    numeric_scale INT,
    distinct_values BIGINT,
    total_rows BIGINT,
    min_value NVARCHAR(MAX),
    max_value NVARCHAR(MAX),
    sample_values NVARCHAR(MAX),
    value_counts NVARCHAR(MAX) -- For columns with <= 10 distinct values
);

-- Cursor to iterate through columns
DECLARE @ColName NVARCHAR(128); -- Stores the QUOTED column name
DECLARE @DataType NVARCHAR(128);
DECLARE @CharMaxLen INT;
DECLARE @NumPrec TINYINT;
DECLARE @NumScale INT;

-- Select columns for the specified table and schema
DECLARE ColCursor CURSOR LOCAL FAST_FORWARD FOR -- Added LOCAL FAST_FORWARD for performance
SELECT QUOTENAME(column_name), data_type, character_maximum_length, numeric_precision, numeric_scale
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = @SchemaName
  AND TABLE_NAME = @BaseTableName;

OPEN ColCursor;
FETCH NEXT FROM ColCursor INTO @ColName, @DataType, @CharMaxLen, @NumPrec, @NumScale;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Build dynamic SQL for *this specific column*
    SET @SQLAnalyze = N'
        DECLARE @distinct BIGINT, @total BIGINT, @min NVARCHAR(MAX), @max NVARCHAR(MAX), @samples NVARCHAR(MAX), @valcounts NVARCHAR(MAX);

        -- Get total rows once (can be slightly inaccurate if rows change during loop, but usually acceptable)
        SELECT @total = COUNT(*) FROM ' + @TableName + ';

        -- Use TRY_CAST for broader compatibility, especially for MIN/MAX on non-numeric types
        SELECT
            @distinct = COUNT(DISTINCT ' + @ColName + '),
            @min = MIN(TRY_CAST(' + @ColName + ' AS NVARCHAR(MAX))),
            @max = MAX(TRY_CAST(' + @ColName + ' AS NVARCHAR(MAX)))
        FROM ' + @TableName + ';

        -- Sample values using FOR XML PATH for comma separation (compatible method)
        SELECT @samples = STUFF(
            (SELECT '', '' + CAST(SampleValue AS NVARCHAR(MAX)) -- Separator prepended
             FROM (
                 SELECT TOP 5 ' + @ColName + ' AS SampleValue
                 FROM ' + @TableName + '
                 WHERE ' + @ColName + ' IS NOT NULL
                 -- ORDER BY 1 -- Optional ordering inside subquery
             ) AS SampleData
             FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)'') -- TYPE handles entities, . gets value
            , 1, 2, ''''); -- Remove leading separator '', ''

        -- Value counts (only if distinct <= 10 and > 0)
        IF @distinct > 0 AND @distinct <= 10
        BEGIN
            SELECT @valcounts = STRING_AGG(CAST(value AS NVARCHAR(MAX)) + '' ('' + CAST(count AS NVARCHAR(10)) + '')'', '', '') -- Assumes STRING_AGG is available (SQL 2017+)
            FROM (
                SELECT TOP 5 -- Show top 5 most frequent values
                    ' + @ColName + ' AS value,
                    COUNT(*) AS count
                FROM ' + @TableName + '
                WHERE ' + @ColName + ' IS NOT NULL
                GROUP BY ' + @ColName + '
                ORDER BY count DESC, value ASC -- Order by count desc, then value asc
            ) AS TopValues;
        END;

        -- Insert results into temp table
        INSERT INTO #ColumnAnalysis (column_name, data_type, character_maximum_length, numeric_precision, numeric_scale, distinct_values, total_rows, min_value, max_value, sample_values, value_counts)
        VALUES (PARSENAME(@ColNameParam, 1), @DataTypeParam, @CharMaxLenParam, @NumPrecParam, @NumScaleParam, @distinct, @total, @min, @max, @samples, @valcounts);';

    -- Execute the dynamic SQL for the current column
    BEGIN TRY
        EXEC sp_executesql @SQLAnalyze,
             N'@ColNameParam NVARCHAR(128), @DataTypeParam NVARCHAR(128), @CharMaxLenParam INT, @NumPrecParam TINYINT, @NumScaleParam INT',
             @ColNameParam = @ColName, -- Pass quoted name
             @DataTypeParam = @DataType,
             @CharMaxLenParam = @CharMaxLen,
             @NumPrecParam = @NumPrec,
             @NumScaleParam = @NumScale;
    END TRY
    BEGIN CATCH
        PRINT N'Error processing column: ' + @ColName;
        PRINT N'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR(20));
        PRINT N'Error Message: ' + ERROR_MESSAGE();
        PRINT N'Dynamic SQL Attempted:';
        PRINT @SQLAnalyze; -- Print the SQL that failed

        -- Optionally decide whether to stop or continue
        -- RAISERROR('Failed to process column analysis.', 16, 1); -- Uncomment to stop execution
        -- GOTO Cleanup; -- Or jump to cleanup if you add a label
    END CATCH

    FETCH NEXT FROM ColCursor INTO @ColName, @DataType, @CharMaxLen, @NumPrec, @NumScale;
END

CLOSE ColCursor;
DEALLOCATE ColCursor;

-- Final SELECT from the temp table, applying the classification logic
SELECT
    ca.column_name AS "Column",
    CASE
        -- Potential Keys (Consider adding check for non-nullability too)
        WHEN ca.column_name LIKE '%id%' OR ca.column_name LIKE '%key%' OR ca.column_name LIKE '%num%' OR ca.column_name LIKE '%#%' THEN
            CASE
                WHEN ca.distinct_values = ca.total_rows AND ca.total_rows > 0 THEN 'PK (Candidate)' -- Indicate it's a candidate
                ELSE 'FK (Potential)' -- Could be FK or just an identifier
            END
        WHEN ca.distinct_values <= 10 AND ca.distinct_values > 0 THEN 'Code/Category' -- Low distinct non-empty values
        WHEN ca.data_type IN ('decimal', 'numeric', 'money', 'float', 'real') THEN 'Numeric/Money' -- Broader numeric
        WHEN ca.data_type IN ('varchar', 'char', 'text', 'nvarchar', 'nchar') AND ca.character_maximum_length > 50 THEN 'Long Text'
        WHEN ca.data_type IN ('varchar', 'char', 'text', 'nvarchar', 'nchar') THEN 'Short Text'
        WHEN ca.data_type IN ('int', 'bigint', 'smallint', 'tinyint') THEN 'Integer'
        WHEN ca.data_type IN ('date', 'datetime', 'datetime2', 'smalldatetime', 'time', 'datetimeoffset') THEN 'Date/Time' -- Broader date/time
        WHEN ca.data_type IN ('bit') THEN 'Boolean'
        WHEN ca.data_type IN ('binary', 'varbinary', 'image') THEN 'Binary Data'
        WHEN ca.data_type IN ('uniqueidentifier') THEN 'GUID'
        WHEN ca.data_type IN ('xml') THEN 'XML Data'
        ELSE 'Other (' + ca.data_type + ')' -- Show the type if Other
    END AS "Inferred Type", -- Renamed column
    ca.data_type AS "DB Data Type",
    CASE
        WHEN ca.distinct_values <= 10 AND ca.distinct_values > 0 THEN COALESCE(ca.value_counts, 'N/A')
        WHEN ca.data_type IN ('decimal', 'numeric', 'money', 'float', 'real', 'int', 'bigint', 'smallint', 'tinyint', 'date', 'datetime', 'datetime2', 'smalldatetime', 'time', 'datetimeoffset') THEN
            'Min: ' + ISNULL(ca.min_value, 'NULL') +
            ', Max: ' + ISNULL(ca.max_value, 'NULL')
        ELSE 'Distinct: ' + CAST(ca.distinct_values AS NVARCHAR(20))
    END AS "Values/Stats",
    ca.sample_values AS "Sample Data"
FROM
    #ColumnAnalysis ca
ORDER BY
    ca.column_name;

-- Cleanup Label (Optional):
-- Cleanup:

-- Clean up temp table
IF OBJECT_ID('tempdb..#ColumnAnalysis') IS NOT NULL DROP TABLE #ColumnAnalysis;