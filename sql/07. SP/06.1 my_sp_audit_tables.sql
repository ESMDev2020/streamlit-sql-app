/******************************************************
STORED PROCEDURE my_sp_audit_tables
	
PURPOSE
	This stored procedure reviews one table and runs
	through its columns reviewing the type of information it may have

USE
	-- Basic usage (analyze a table with default parameters)
	EXEC my_sp_audit_tables 'YourTableName';

	-- With custom sample size and max codes to show
	EXEC my_sp_audit_tables 'YourTableName', @SampleSize = 3, @MaxCodesToShow = 5;

PARAMETERS
	@SampleSize: Number of sample values to show (default 5)

	@MaxCodesToShow: Maximum code values to display for CODE-type fields (default 10)


********************************************************/


CREATE OR ALTER PROCEDURE mrs.my_sp_audit_tables (
    @SchemaName NVARCHAR(128) = N'dbo', -- Added schema parameter
    @TableName NVARCHAR(128),
    @SampleSize INT = 5,
    @MaxCodesToShow INT = 10
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Input Validation
    IF @SchemaName IS NULL OR @TableName IS NULL OR @SampleSize <= 0 OR @MaxCodesToShow <= 0
    BEGIN
        RAISERROR('Invalid input parameters. Schema, TableName cannot be NULL. SampleSize and MaxCodesToShow must be positive.', 16, 1);
        RETURN;
    END

    -- Check if table exists
    IF NOT EXISTS (SELECT 1
                   FROM INFORMATION_SCHEMA.TABLES
                   WHERE TABLE_SCHEMA = @SchemaName AND TABLE_NAME = @TableName)
    BEGIN
        RAISERROR('Table [%s].[%s] not found.', 16, 1, @SchemaName, @TableName);
        RETURN;
    END

    -- Temporary table to store results for each column
    IF OBJECT_ID('tempdb..#ColumnAuditResults') IS NOT NULL
        DROP TABLE #ColumnAuditResults;

    CREATE TABLE #ColumnAuditResults (
        ColumnName NVARCHAR(128) PRIMARY KEY,
        DataType NVARCHAR(128),
        CharacterMaxLength INT,
        NumericPrecision TINYINT,
        NumericScale INT,
        TotalRows BIGINT,
        DistinctValues BIGINT,
        NullCount BIGINT,
        IsUnique BIT,
        MinValue NVARCHAR(MAX),
        MaxValue NVARCHAR(MAX),
        TopValues NVARCHAR(MAX), -- Stores top N values and counts
        SampleData NVARCHAR(MAX) -- Stores sample values
    );

    -- Variables for the loop
    DECLARE @CurrentColumn NVARCHAR(128);
    DECLARE @CurrentDataType NVARCHAR(128);
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @Params NVARCHAR(MAX);
    DECLARE @TotalRows BIGINT;
    DECLARE @ColumnList CURSOR;

    -- Get total row count once
    SET @SQL = N'SELECT @TotalRowsOUT = COUNT_BIG(*) FROM ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ';';
    SET @Params = N'@TotalRowsOUT BIGINT OUTPUT';
    EXEC sp_executesql @SQL, @Params, @TotalRowsOUT = @TotalRows OUTPUT;

    -- Cursor to iterate through columns
    SET @ColumnList = CURSOR LOCAL FAST_FORWARD FOR
        SELECT COLUMN_NAME, DATA_TYPE
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = @SchemaName AND TABLE_NAME = @TableName
        ORDER BY ORDINAL_POSITION;

    OPEN @ColumnList;
    FETCH NEXT FROM @ColumnList INTO @CurrentColumn, @CurrentDataType;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Variables for dynamic SQL output
        DECLARE @DistinctCount BIGINT;
        DECLARE @NullCount BIGINT;
        DECLARE @IsUnique BIT;
        DECLARE @MinVal NVARCHAR(MAX);
        DECLARE @MaxVal NVARCHAR(MAX);
        DECLARE @TopVals NVARCHAR(MAX) = NULL;
        DECLARE @SampleVals NVARCHAR(MAX) = NULL;

        -- 1. Calculate Distinct Count, Null Count, Min, Max
        -- Using conditional aggregation to get counts in one pass (per column)
        -- Min/Max are handled separately to manage data types
        SET @SQL = N'
            SELECT
                @DistinctCountOUT = COUNT(DISTINCT ' + QUOTENAME(@CurrentColumn) + '),
                @NullCountOUT = SUM(CASE WHEN ' + QUOTENAME(@CurrentColumn) + ' IS NULL THEN 1 ELSE 0 END) -- Use SUM for Null Count
            FROM ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ';

            -- Calculate Min/Max safely, casting to NVARCHAR(MAX) for storage
            -- Avoid MIN/MAX on text, ntext, image types if they exist (though deprecated)
            IF @CurrentDataType NOT IN (''text'', ''ntext'', ''image'', ''xml'', ''geometry'', ''geography'')
            BEGIN
                -- Use subquery to handle potential empty table for MIN/MAX
                SELECT
                    @MinValOUT = (SELECT MIN(CAST(' + QUOTENAME(@CurrentColumn) + ' AS NVARCHAR(MAX))) FROM ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ' WHERE ' + QUOTENAME(@CurrentColumn) + ' IS NOT NULL),
                    @MaxValOUT = (SELECT MAX(CAST(' + QUOTENAME(@CurrentColumn) + ' AS NVARCHAR(MAX))) FROM ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ' WHERE ' + QUOTENAME(@CurrentColumn) + ' IS NOT NULL);
            END
            ELSE
            BEGIN
                 SET @MinValOUT = ''N/A'';
                 SET @MaxValOUT = ''N/A'';
            END';

        SET @Params = N'@DistinctCountOUT BIGINT OUTPUT,
                       @NullCountOUT BIGINT OUTPUT,
                       @MinValOUT NVARCHAR(MAX) OUTPUT,
                       @MaxValOUT NVARCHAR(MAX) OUTPUT,
                       @CurrentDataType NVARCHAR(128)'; -- Pass data type for conditional MIN/MAX

        -- Execute and get results
        EXEC sp_executesql @SQL, @Params,
                           @DistinctCountOUT = @DistinctCount OUTPUT,
                           @NullCountOUT = @NullCount OUTPUT,
                           @MinValOUT = @MinVal OUTPUT,
                           @MaxValOUT = @MaxVal OUTPUT,
                           @CurrentDataType = @CurrentDataType; -- Pass data type value

        -- Determine uniqueness (handle case where TotalRows might be 0)
        SET @IsUnique = CASE WHEN @TotalRows > 0 AND @DistinctCount = @TotalRows - @NullCount AND @NullCount = 0 THEN 1 ELSE 0 END;


        -- 2. Get Top N Value Counts (only if distinct count is reasonably low or it's not unique)
        -- Only run this potentially expensive query if useful
        IF @TotalRows > 0 AND @DistinctCount < @TotalRows * 0.5 AND @DistinctCount > 0 -- Heuristic: run if distinct values are less than 50% of rows
        BEGIN
            SET @SQL = N'
            WITH ValueCounts AS (
                SELECT
                    CAST(' + QUOTENAME(@CurrentColumn) + ' AS NVARCHAR(MAX)) AS Value,
                    COUNT(*) AS Count
                FROM ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + '
                WHERE ' + QUOTENAME(@CurrentColumn) + ' IS NOT NULL
                GROUP BY CAST(' + QUOTENAME(@CurrentColumn) + ' AS NVARCHAR(MAX))
            )
            SELECT @TopValsOUT = STRING_AGG(Value + '' ('' + CAST(Count AS NVARCHAR(20)) + '')'', '', '') WITHIN GROUP (ORDER BY Count DESC, Value ASC) -- Added Value ASC for tie-breaking
            FROM (
                SELECT TOP (@MaxCodesToShow) Value, Count
                FROM ValueCounts
                ORDER BY Count DESC, Value ASC -- Add secondary sort for consistent ordering
            ) AS TopN;';

            SET @Params = N'@MaxCodesToShow INT, @TopValsOUT NVARCHAR(MAX) OUTPUT';
            EXEC sp_executesql @SQL, @Params, @MaxCodesToShow = @MaxCodesToShow, @TopValsOUT = @TopVals OUTPUT;
        END
        ELSE IF @DistinctCount = 0 AND @TotalRows > 0 -- Handle case where column is all NULLs
        BEGIN
             SET @TopVals = '(All NULLs)';
        END

        -- 3. Get Sample Data
        IF @TotalRows > 0
        BEGIN
            SET @SQL = N'
            SELECT @SampleValsOUT = STRING_AGG(
                CASE WHEN Val IS NULL THEN ''NULL''
                     ELSE LEFT(CAST(Val AS NVARCHAR(MAX)), 100) -- Limit length of sample values
                END, '', ''
            ) WITHIN GROUP (ORDER BY SampleKey) -- Order by the NEWID() key for consistency in aggregation
            FROM (
                SELECT TOP (@SampleSize) ' + QUOTENAME(@CurrentColumn) + ' AS Val, NEWID() as SampleKey
                FROM ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + '
                ORDER BY SampleKey -- Use NEWID() for random sampling
            ) AS Samples;';

            SET @Params = N'@SampleSize INT, @SampleValsOUT NVARCHAR(MAX) OUTPUT';
            EXEC sp_executesql @SQL, @Params, @SampleSize = @SampleSize, @SampleValsOUT = @SampleVals OUTPUT;
        END

        -- Insert results for the current column into the temp table
        INSERT INTO #ColumnAuditResults (
            ColumnName, DataType, CharacterMaxLength, NumericPrecision, NumericScale,
            TotalRows, DistinctValues, NullCount, IsUnique, MinValue, MaxValue, TopValues, SampleData
        )
        SELECT
            c.COLUMN_NAME, c.DATA_TYPE, c.CHARACTER_MAXIMUM_LENGTH, c.NUMERIC_PRECISION, c.NUMERIC_SCALE,
            ISNULL(@TotalRows, 0), -- Ensure TotalRows is not NULL
            ISNULL(@DistinctCount, 0), -- Ensure DistinctCount is not NULL
            ISNULL(@NullCount, 0), -- Ensure NullCount is not NULL
            @IsUnique, @MinVal, @MaxVal, @TopVals, @SampleVals
        FROM INFORMATION_SCHEMA.COLUMNS c
        WHERE c.TABLE_SCHEMA = @SchemaName AND c.TABLE_NAME = @TableName AND c.COLUMN_NAME = @CurrentColumn;

        -- Fetch next column
        FETCH NEXT FROM @ColumnList INTO @CurrentColumn, @CurrentDataType;
    END

    CLOSE @ColumnList;
    DEALLOCATE @ColumnList;

    -- Final Select with Classification and Sorting
    SELECT
        r.ColumnName AS "Column",
        -- Enhanced Type Classification Logic
        CASE
            WHEN r.IsUnique = 1 AND (r.ColumnName LIKE '%id' OR r.ColumnName LIKE 'id%') THEN 'PK (Potential)' -- Unique ID-like columns
            WHEN r.ColumnName LIKE '%id' OR r.ColumnName LIKE '%code%' OR r.ColumnName LIKE '%key%' THEN 'FK/Code (Potential)' -- Non-unique ID/Code-like
            WHEN r.DataType IN ('date', 'datetime', 'datetime2', 'smalldatetime', 'time') THEN 'Date/Time'
            WHEN r.DataType IN ('datetimeoffset') THEN 'DateTime Offset'
            WHEN r.ColumnName LIKE '%date%' OR r.ColumnName LIKE '%time%' THEN 'Date/Time (Name Suggests)' -- Name-based hint
            WHEN r.DataType IN ('money', 'smallmoney', 'decimal', 'numeric') THEN 'Money/Numeric'
            WHEN r.ColumnName LIKE '%price%' OR r.ColumnName LIKE '%cost%' OR r.ColumnName LIKE '%amount%'
                 OR r.ColumnName LIKE '%charge%' OR r.ColumnName LIKE '%value%' OR r.ColumnName LIKE '%balance%' THEN 'Money (Name Suggests)'
            WHEN r.DataType IN ('int', 'bigint', 'smallint', 'tinyint') THEN 'Integer'
            WHEN r.ColumnName LIKE '%qty%' OR r.ColumnName LIKE '%quantity%' OR r.ColumnName LIKE '%count%' THEN 'Quantity (Name Suggests)'
            WHEN r.DataType IN ('float', 'real') THEN 'Float'
            WHEN r.DataType IN ('bit') THEN 'Boolean/Bit'
            WHEN r.DistinctValues = 2 AND r.NullCount = 0 THEN 'Boolean (Likely)' -- Two distinct non-null values often indicate boolean
            WHEN r.DistinctValues BETWEEN 1 AND @MaxCodesToShow * 2 THEN 'Category/Code (Low Distinct)' -- Low distinct count suggests codes/categories
            WHEN r.DataType IN ('char', 'nchar', 'varchar', 'nvarchar') AND r.CharacterMaxLength > 255 THEN 'Long Text'
            WHEN r.DataType IN ('char', 'nchar', 'varchar', 'nvarchar') THEN 'Short Text'
            WHEN r.DataType IN ('text', 'ntext') THEN 'Deprecated Text' -- Deprecated types
            WHEN r.DataType IN ('xml') THEN 'XML'
            WHEN r.DataType IN ('varbinary', 'binary', 'image') THEN 'Binary Data'
            WHEN r.DataType IN ('uniqueidentifier') THEN 'GUID'
            WHEN r.DataType IN ('hierarchyid', 'geometry', 'geography') THEN 'Spatial/Hierarchy'
            ELSE 'Other'
        END AS "Type",
        r.DataType AS "DB Data Type",
        CASE
            WHEN r.DataType IN ('decimal', 'numeric') THEN '(' + CAST(r.NumericPrecision AS VARCHAR(5)) + ',' + CAST(r.NumericScale AS VARCHAR(5)) + ')'
            WHEN r.DataType LIKE '%char%' AND r.CharacterMaxLength > 0 THEN '(' + CAST(r.CharacterMaxLength AS VARCHAR(10)) + ')'
            WHEN r.DataType LIKE '%char%' AND r.CharacterMaxLength = -1 THEN '(MAX)'
            ELSE ''
        END AS "DB Type Details",
        r.TotalRows AS "Total Rows",
        r.DistinctValues AS "Distinct Values",
        r.NullCount AS "Null Count", -- Changed from CAST(.. AS BIGINT) as it's already BIGINT
        CASE
            WHEN r.TotalRows > 0 AND r.NullCount > 0 THEN CAST(CAST(r.NullCount * 100.0 / r.TotalRows AS DECIMAL(5, 2)) AS VARCHAR(10)) + '%'
            WHEN r.NullCount = 0 THEN '0.00%'
            ELSE 'N/A' -- Handle case where TotalRows is 0 but NullCount might be > 0 (shouldn't happen but safe)
        END AS "Null Pct",
        r.IsUnique AS "Is Unique",
        CASE
            WHEN r.TopValues IS NOT NULL THEN r.TopValues -- Show top values if calculated
            WHEN r.DataType IN ('decimal', 'numeric', 'money', 'smallmoney', 'int', 'bigint', 'smallint', 'tinyint', 'float', 'real', 'date', 'datetime', 'datetime2', 'smalldatetime', 'time')
                 AND r.MinValue IS NOT NULL AND r.DistinctValues > 1 THEN 'Range: [' + ISNULL(r.MinValue, 'NULL') + '] to [' + ISNULL(r.MaxValue, 'NULL') + ']'
            WHEN r.DistinctValues = 1 AND r.MinValue IS NOT NULL THEN 'Single Value: ' + r.MinValue -- Only one distinct value
            WHEN r.DistinctValues = 0 AND r.TotalRows > 0 THEN '(All NULLs)' -- Indicate all NULLs if applicable
            ELSE 'N/A' -- For text, binary, etc. or empty table
        END AS "Values Info (Top N / Range / Single)",
        r.SampleData AS "Sample Data (Random Sample)", -- CORRECTED ALIAS
        -- Sorting Logic
        CASE
            WHEN r.IsUnique = 1 AND (r.ColumnName LIKE '%id' OR r.ColumnName LIKE 'id%') THEN 0 -- PK
            WHEN r.ColumnName LIKE '%id' OR r.ColumnName LIKE '%code%' OR r.ColumnName LIKE '%key%' THEN 1 -- FK/Code
            WHEN r.DataType IN ('date', 'datetime', 'datetime2', 'smalldatetime', 'time', 'datetimeoffset') THEN 2 -- Date/Time
            WHEN r.DataType IN ('money', 'smallmoney', 'decimal', 'numeric') THEN 3 -- Money/Numeric
            WHEN r.DataType IN ('int', 'bigint', 'smallint', 'tinyint') THEN 4 -- Integer
            WHEN r.DataType IN ('float', 'real') THEN 5 -- Float
            WHEN r.DataType IN ('bit') THEN 6 -- Bit
            WHEN r.DistinctValues BETWEEN 1 AND @MaxCodesToShow * 2 THEN 7 -- Category/Code
            WHEN r.DataType IN ('char', 'nchar', 'varchar', 'nvarchar') THEN 8 -- Text
            WHEN r.DataType IN ('uniqueidentifier') THEN 9 -- GUID
            ELSE 10 -- Other types
        END AS SortOrder
    FROM #ColumnAuditResults r
    ORDER BY SortOrder, r.ColumnName; -- Sort by type category, then alphabetically

    -- Cleanup
    IF OBJECT_ID('tempdb..#ColumnAuditResults') IS NOT NULL
        DROP TABLE #ColumnAuditResults;

END;
GO

-- Example Usage:
-- EXEC dbo.sp_audit_tables @SchemaName = 'Sales', @TableName = 'Orders', @SampleSize = 10, @MaxCodesToShow = 5;
-- EXEC dbo.sp_audit_tables @TableName = 'YourTable'; -- Uses default schema 'dbo' and default sample/code sizes


