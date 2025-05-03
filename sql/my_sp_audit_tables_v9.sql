/******************************************************
STORED PROCEDURE my_sp_audit_tables

VERSION
	9.14 (Prioritize Date Suffix check over Single/Flag(2) checks)

PURPOSE
	This stored procedure reviews one table and runs
	through its columns reviewing the type of information it may have

USE
	-- Run with debug mode to see what's happening
	EXEC mrs.my_sp_audit_tables
		@SchemaName = 'dbo',
		@TableName = 'YourTableName',
		@DebugMode = 1;

	-- Basic usage (analyze a table with default parameters)
	EXEC mrs.my_sp_audit_tables @TableName = 'YourTableName'; -- Use default schema 'dbo'

	-- With custom schema, sample size and max codes to show
	EXEC mrs.my_sp_audit_tables @SchemaName = 'YourSchema', @TableName = 'YourTableName', @SampleSize = 3, @MaxCodesToShow = 5;

PARAMETERS
    @SchemaName: Schema of the table to analyze (default 'dbo')
    @TableName: Name of the table to analyze
	@SampleSize: Number of sample values to show (default 5)
	@MaxCodesToShow: Maximum code values to display for CODE-type fields (default 10)
    @DebugMode: Set to 1 to print debug messages and intermediate results (default 0)

********************************************************/
CREATE OR ALTER PROCEDURE mrs.my_sp_audit_tables (
    @SchemaName NVARCHAR(128) = N'dbo',
    @TableName NVARCHAR(128),
    @SampleSize INT = 5,
    @MaxCodesToShow INT = 10,
    @DebugMode BIT = 0 -- New parameter for debugging
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Input Validation with better messages
    IF @SchemaName IS NULL OR @TableName IS NULL OR @SampleSize <= 0 OR @MaxCodesToShow <= 0
    BEGIN
        DECLARE @SchemaNameStr NVARCHAR(128) = ISNULL(@SchemaName, 'NULL');
        DECLARE @TableNameStr NVARCHAR(128) = ISNULL(@TableName, 'NULL');
        RAISERROR('Invalid parameters: Schema=%s, Table=%s, SampleSize=%d, MaxCodes=%d',
                  16, 1, @SchemaNameStr, @TableNameStr, @SampleSize, @MaxCodesToShow);
        RETURN;
    END

    -- Check if table exists with more detailed error
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES
                   WHERE TABLE_SCHEMA = @SchemaName AND TABLE_NAME = @TableName)
    BEGIN
        RAISERROR('Table [%s].[%s] not found. Check spelling and permissions.',
                  16, 1, @SchemaName, @TableName);

        IF @DebugMode = 1
        BEGIN
            PRINT 'Available tables in the current database:';
            SELECT TABLE_SCHEMA, TABLE_NAME
            FROM INFORMATION_SCHEMA.TABLES
            WHERE TABLE_TYPE = 'BASE TABLE'
            ORDER BY TABLE_SCHEMA, TABLE_NAME;
        END
        RETURN;
    END

    -- Create temporary table with proper error handling
    BEGIN TRY
        IF OBJECT_ID('tempdb..#ColumnAuditResults') IS NOT NULL
            DROP TABLE #ColumnAuditResults;

        CREATE TABLE #ColumnAuditResults (
            ColumnName NVARCHAR(128) PRIMARY KEY,
            DataType NVARCHAR(128),
            CharacterMaxLength INT,
            NumericPrecision TINYINT,
            NumericScale INT,
            TotalRows BIGINT,
            DistinctValues BIGINT, -- Count excluding whitespace-only strings
            NullCount BIGINT,
            WhitespaceCount BIGINT,
            IsUniqueFlag NVARCHAR(20), -- Changed from BIT to store 'Flag' or '0'/'1'
            MinValue NVARCHAR(MAX),
            MaxValue NVARCHAR(MAX),
            TopValues NVARCHAR(MAX), -- Excluding whitespace-only strings
            SampleData NVARCHAR(MAX),
            SortOrder INT
        );
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage_TempTable NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Error creating temp table: %s', 16, 1, @ErrorMessage_TempTable);
        RETURN;
    END CATCH

    -- Get total row count with error handling
    DECLARE @TotalRows BIGINT = 0;
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @Params NVARCHAR(500);

    BEGIN TRY
        SET @SQL = N'SELECT @TotalRowsOUT = COUNT_BIG(*) FROM ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ' WITH (NOLOCK);';
        SET @Params = N'@TotalRowsOUT BIGINT OUTPUT';
        EXEC sp_executesql @SQL, @Params, @TotalRowsOUT = @TotalRows OUTPUT;

        IF @DebugMode = 1
            PRINT 'Total rows in table: ' + CAST(@TotalRows AS NVARCHAR(20));
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage_RowCount NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Error getting row count: %s', 16, 1, @ErrorMessage_RowCount);
        RETURN;
    END CATCH

    -- Process each column with detailed error handling
    DECLARE @ColumnList CURSOR;
    DECLARE @CurrentColumn NVARCHAR(128), @CurrentDataType NVARCHAR(128);
    DECLARE @ColumnsProcessed INT = 0;

    BEGIN TRY
        SET @ColumnList = CURSOR LOCAL FAST_FORWARD FOR
            SELECT COLUMN_NAME, DATA_TYPE
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = @SchemaName AND TABLE_NAME = @TableName
            ORDER BY ORDINAL_POSITION;

        OPEN @ColumnList;
        FETCH NEXT FROM @ColumnList INTO @CurrentColumn, @CurrentDataType;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF @DebugMode = 1
                PRINT 'Processing column: ' + QUOTENAME(@CurrentColumn);

            DECLARE @DistinctCount BIGINT = 0, @NullCount BIGINT = 0, @WhitespaceCount BIGINT = 0, @IsUnique BIT = 0;
            DECLARE @MinVal NVARCHAR(MAX) = NULL, @MaxVal NVARCHAR(MAX) = NULL;
            DECLARE @TopVals NVARCHAR(MAX) = NULL, @SampleVals NVARCHAR(MAX) = NULL;
            DECLARE @SortOrder INT = 16; -- Default to "Other"
            DECLARE @IsUniqueFlagValue NVARCHAR(20); -- To store 'Flag' or bit value

            -- Wrap column processing in its own TRY...CATCH
            BEGIN TRY
                -- Get basic column stats (including whitespace count)
                SET @SQL = N'
                ;WITH TrimmedData AS (
                    SELECT ' + QUOTENAME(@CurrentColumn) + ' AS OriginalValue,
                           LTRIM(RTRIM(CAST(' + QUOTENAME(@CurrentColumn) + ' AS NVARCHAR(MAX)))) AS TrimmedValue
                    FROM ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ' WITH (NOLOCK)
                )
                SELECT
                    @DistinctCountOUT = COUNT(DISTINCT CASE WHEN TD.TrimmedValue <> '''' THEN TD.OriginalValue ELSE NULL END),
                    @NullCountOUT = SUM(CASE WHEN TD.OriginalValue IS NULL THEN 1 ELSE 0 END),
                    @WhitespaceCountOUT = SUM(CASE WHEN TD.OriginalValue IS NOT NULL AND TD.TrimmedValue = '''' THEN 1 ELSE 0 END)
                FROM TrimmedData TD;';

                SET @Params = N'@DistinctCountOUT BIGINT OUTPUT, @NullCountOUT BIGINT OUTPUT, @WhitespaceCountOUT BIGINT OUTPUT';
                EXEC sp_executesql @SQL, @Params,
                                   @DistinctCountOUT = @DistinctCount OUTPUT,
                                   @NullCountOUT = @NullCount OUTPUT,
                                   @WhitespaceCountOUT = @WhitespaceCount OUTPUT;

                SET @NullCount = ISNULL(@NullCount, 0);
                SET @DistinctCount = ISNULL(@DistinctCount, 0);
                SET @WhitespaceCount = ISNULL(@WhitespaceCount, 0);

                -- Check uniqueness (considering only non-null, non-whitespace values)
                SET @IsUnique = CASE WHEN @TotalRows > 0 AND @DistinctCount = (@TotalRows - @NullCount - @WhitespaceCount) AND (@NullCount + @WhitespaceCount = 0) THEN 1 ELSE 0 END;

                -- Determine IsUniqueFlag value (Flag or Bit) - Default to bit, override later if needed
                SET @IsUniqueFlagValue = CAST(@IsUnique AS NVARCHAR(5));

                -- Get min/max for compatible types (excluding whitespace-only strings)
                IF @CurrentDataType NOT IN ('text', 'ntext', 'image', 'xml', 'geometry', 'geography', 'sql_variant', 'hierarchyid')
                BEGIN
                    SET @SQL = N'
                    SELECT
                        @MinValOUT = (SELECT MIN(CAST(' + QUOTENAME(@CurrentColumn) + ' AS NVARCHAR(MAX)))
                                      FROM ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ' WITH (NOLOCK)
                                      WHERE ' + QUOTENAME(@CurrentColumn) + ' IS NOT NULL AND LTRIM(RTRIM(CAST(' + QUOTENAME(@CurrentColumn) + ' AS NVARCHAR(MAX)))) <> ''''),
                        @MaxValOUT = (SELECT MAX(CAST(' + QUOTENAME(@CurrentColumn) + ' AS NVARCHAR(MAX)))
                                      FROM ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ' WITH (NOLOCK)
                                      WHERE ' + QUOTENAME(@CurrentColumn) + ' IS NOT NULL AND LTRIM(RTRIM(CAST(' + QUOTENAME(@CurrentColumn) + ' AS NVARCHAR(MAX)))) <> '''');';

                    SET @Params = N'@MinValOUT NVARCHAR(MAX) OUTPUT, @MaxValOUT NVARCHAR(MAX) OUTPUT';
                    EXEC sp_executesql @SQL, @Params, @MinValOUT = @MinVal OUTPUT, @MaxValOUT = @MaxVal OUTPUT;
                END
                ELSE
                BEGIN
                    SET @MinVal = 'N/A (Type)'; SET @MaxVal = 'N/A (Type)';
                END

                -- Get top values for low-cardinality columns (excluding whitespace-only strings)
                IF @DistinctCount >= 1 AND @DistinctCount <= (@MaxCodesToShow * 2)
                BEGIN
                    SET @SQL = N'
                    ;WITH ValueCounts AS (
                        SELECT TOP (@MaxCodesToShow)
                            CAST(' + QUOTENAME(@CurrentColumn) + ' AS NVARCHAR(MAX)) AS Value, COUNT(*) AS Count
                        FROM ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ' WITH (NOLOCK)
                        WHERE ' + QUOTENAME(@CurrentColumn) + ' IS NOT NULL AND LTRIM(RTRIM(CAST(' + QUOTENAME(@CurrentColumn) + ' AS NVARCHAR(MAX)))) <> ''''
                        GROUP BY CAST(' + QUOTENAME(@CurrentColumn) + ' AS NVARCHAR(MAX))
                        ORDER BY Count DESC, Value ASC
                    )
                    SELECT @TopValsOUT = STRING_AGG(Value + '' ('' + CAST(Count AS NVARCHAR(20)) + '')'', '', '')
                    FROM ValueCounts;';

                    SET @Params = N'@MaxCodesToShow INT, @TopValsOUT NVARCHAR(MAX) OUTPUT';
                    EXEC sp_executesql @SQL, @Params, @MaxCodesToShow = @MaxCodesToShow, @TopValsOUT = @TopVals OUTPUT;
                END

                -- Get sample data
                IF @TotalRows > 0
                BEGIN
                    SET @SQL = N'
                    SELECT @SampleValsOUT = STRING_AGG(
                        CASE WHEN Val IS NULL THEN ''NULL'' ELSE LEFT(CAST(Val AS NVARCHAR(MAX)), 100) END, '', ''
                    ) WITHIN GROUP (ORDER BY SampleKey)
                    FROM (
                        SELECT TOP (@SampleSize) ' + QUOTENAME(@CurrentColumn) + ' AS Val, NEWID() as SampleKey
                        FROM ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ' WITH (NOLOCK) ORDER BY SampleKey
                    ) AS Samples;';
                    SET @Params = N'@SampleSize INT, @SampleValsOUT NVARCHAR(MAX) OUTPUT';
                    EXEC sp_executesql @SQL, @Params, @SampleSize = @SampleSize, @SampleValsOUT = @SampleVals OUTPUT;
                 END
                 ELSE SET @SampleVals = '(No rows in table)';

                -- Determine sort order (Revised v6.14 - Prioritize Date Suffix)
                SET @SortOrder = CASE
                    -- Priority 1: Keys & Unique Identifiers
                    WHEN @IsUnique = 1 AND (@CurrentColumn LIKE '%id' OR @CurrentColumn LIKE 'id%') THEN 0 -- PK (ID)
                    WHEN @IsUnique = 1 AND (@CurrentColumn LIKE '%number%' OR @CurrentColumn LIKE '%num%' OR @CurrentColumn LIKE '%key%' OR @CurrentColumn LIKE '%no') THEN 1 -- PK (Name)
                    WHEN @CurrentDataType IN ('uniqueidentifier') THEN 14 -- GUID

                    -- Priority 2: Name Patterns (Date Suffix, FK/Code - if not caught above)
                    WHEN (@CurrentColumn LIKE '%CC' OR @CurrentColumn LIKE '%DD' OR @CurrentColumn LIKE '%MM' OR @CurrentColumn LIKE '%YY') THEN 11 -- Date Suffix <<< MOVED UP
                    WHEN (@CurrentColumn LIKE '%id' OR @CurrentColumn LIKE '%code%' OR @CurrentColumn LIKE '%key%') THEN 2 -- FK/Code (Potential)

                    -- Priority 3: Data Content Characteristics (Single Value, Flag(%RECD), Flag(2), Whitespace)
                    WHEN @DistinctCount = 1 THEN 7 -- Single Value
                    WHEN @CurrentColumn LIKE '%RECD' THEN 8 -- Flag (%RECD)
                    WHEN @DistinctCount = 2 THEN 10 -- Flag (2 Values)
                    WHEN @DistinctCount = 0 AND @WhitespaceCount > 0 THEN 12 -- All Whitespace

                    -- Priority 4: Data Types & Low Cardinality (if not caught above)
                    WHEN @DistinctCount > 2 AND @DistinctCount <= @MaxCodesToShow * 2 THEN 3 -- Category/Code (Low Distinct > 2)
                    WHEN @CurrentDataType IN ('char', 'nchar', 'varchar', 'nvarchar', 'text', 'ntext') THEN 4 -- Text
                    WHEN @CurrentDataType IN ('money', 'smallmoney', 'decimal', 'numeric') THEN 5 -- Money/Numeric
                    WHEN @CurrentDataType IN ('int', 'bigint', 'smallint', 'tinyint') THEN 6 -- Integer
                    WHEN @CurrentDataType IN ('float', 'real') THEN 9 -- Float
                    WHEN @CurrentDataType IN ('bit') THEN 13 -- Bit
                    WHEN @CurrentDataType IN ('date', 'datetime', 'datetime2', 'smalldatetime', 'time', 'datetimeoffset') THEN 15 -- Date/Time

                    -- Default
                    ELSE 16 -- Other types
                END;


                -- Insert results into temp table
                DECLARE @CharMaxLen INT, @NumPrecision TINYINT, @NumScale INT;
                SELECT @CharMaxLen = CHARACTER_MAXIMUM_LENGTH, @NumPrecision = NUMERIC_PRECISION, @NumScale = NUMERIC_SCALE
                FROM INFORMATION_SCHEMA.COLUMNS c
                WHERE c.TABLE_SCHEMA = @SchemaName AND c.TABLE_NAME = @TableName AND c.COLUMN_NAME = @CurrentColumn;

                -- Override IsUniqueFlag if SortOrder indicates a Flag type (8 or 10)
                IF @SortOrder IN (8, 10) SET @IsUniqueFlagValue = 'Flag';

                INSERT INTO #ColumnAuditResults (
                    ColumnName, DataType, CharacterMaxLength, NumericPrecision, NumericScale,
                    TotalRows, DistinctValues, NullCount, WhitespaceCount, IsUniqueFlag, MinValue, MaxValue,
                    TopValues, SampleData, SortOrder
                )
                VALUES (
                    @CurrentColumn, @CurrentDataType, @CharMaxLen, @NumPrecision, @NumScale,
                    @TotalRows, @DistinctCount, @NullCount, @WhitespaceCount, @IsUniqueFlagValue, @MinVal, @MaxVal,
                    @TopVals, @SampleVals, @SortOrder
                );

                SET @ColumnsProcessed = @ColumnsProcessed + 1;

            END TRY
            BEGIN CATCH
                DECLARE @ErrorMsg_Column NVARCHAR(4000) = 'Error processing column ' + QUOTENAME(@CurrentColumn) + ': ' + ERROR_MESSAGE();
                IF @DebugMode = 1 PRINT @ErrorMsg_Column; ELSE RAISERROR(@ErrorMsg_Column, 10, 1);
                INSERT INTO #ColumnAuditResults (ColumnName, DataType, SampleData, SortOrder, DistinctValues, NullCount, WhitespaceCount, IsUniqueFlag)
                VALUES (@CurrentColumn, @CurrentDataType, 'ERROR: ' + @ErrorMsg_Column, 99, 0, 0, 0, 'Error');
            END CATCH

            FETCH NEXT FROM @ColumnList INTO @CurrentColumn, @CurrentDataType;
        END -- End WHILE loop

        CLOSE @ColumnList; DEALLOCATE @ColumnList;
        IF @DebugMode = 1 PRINT 'Total columns processed successfully: ' + CAST(@ColumnsProcessed AS NVARCHAR(10));

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage_Cursor NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Error in cursor processing: %s', 16, 1, @ErrorMessage_Cursor);
        IF CURSOR_STATUS('local', 'ColumnList') >= 0 BEGIN IF CURSOR_STATUS('local', 'ColumnList') = 1 CLOSE @ColumnList; DEALLOCATE @ColumnList; END
        IF OBJECT_ID('tempdb..#ColumnAuditResults') IS NOT NULL DROP TABLE #ColumnAuditResults;
        RETURN;
    END CATCH

    -- Final result selection with error handling
    BEGIN TRY
        IF @DebugMode = 1 AND EXISTS (SELECT 1 FROM #ColumnAuditResults) BEGIN PRINT '--- Debug: Contents of #ColumnAuditResults ---'; SELECT * FROM #ColumnAuditResults ORDER BY SortOrder, ColumnName; PRINT '--- End Debug ---'; END
        IF NOT EXISTS (SELECT 1 FROM #ColumnAuditResults) BEGIN IF @DebugMode = 1 PRINT 'No results generated.'; SELECT 'No results generated.' AS Status; RETURN; END

        SELECT
            ColumnName AS "COLUMN",
            -- Updated TYPE classification based on new SortOrder
            CASE
                WHEN SortOrder = 0 THEN 'PK (Potential - ID)'
                WHEN SortOrder = 1 THEN 'PK (Potential - Name)'
                WHEN SortOrder = 2 THEN 'FK/Code (Potential)'
                WHEN SortOrder = 3 THEN 'Category/Code (Low Distinct)'
                WHEN SortOrder = 4 THEN 'Text'
                WHEN SortOrder = 5 THEN 'Money/Numeric'
                WHEN SortOrder = 6 THEN 'Integer'
                WHEN SortOrder = 7 THEN 'Single Value'
                WHEN SortOrder = 8 THEN 'Flag (%RECD)'
                WHEN SortOrder = 9 THEN 'Float'
                WHEN SortOrder = 10 THEN 'Flag (2 Values)'
                WHEN SortOrder = 11 THEN 'Date (Suffix)' -- Corrected Order
                WHEN SortOrder = 12 THEN 'All Whitespace'
                WHEN SortOrder = 13 THEN 'Boolean/Bit'
                WHEN SortOrder = 14 THEN 'GUID'
                WHEN SortOrder = 15 THEN 'Date/Time'
                WHEN SortOrder = 99 THEN 'ERROR PROCESSING'
                ELSE 'Other' -- Renumbered (now 16)
            END AS "TYPE",
            DistinctValues AS "Distinct (Non-Blank) Values",
            -- Enhanced Values Info logic
            CASE
                WHEN SortOrder = 99 THEN SampleData -- Show error message here
                WHEN TopValues IS NOT NULL THEN TopValues -- Show top non-blank values if calculated (Distinct >= 1)
                WHEN DataType IN ('decimal', 'numeric', 'money', 'smallmoney', 'int', 'bigint', 'smallint', 'tinyint', 'float', 'real', 'date', 'datetime', 'datetime2', 'smalldatetime', 'time', 'datetimeoffset')
                     AND MinValue IS NOT NULL AND MinValue NOT LIKE 'N/A%' AND DistinctValues > 2 THEN 'Range: [' + ISNULL(MinValue, 'NULL') + '] to [' + ISNULL(MaxValue, 'NULL') + ']' -- Show range only if Distinct > 2
                WHEN SortOrder = 12 THEN '(All Whitespace)' -- Explicitly show for SortOrder 12
                WHEN DistinctValues = 0 AND NullCount > 0 AND WhitespaceCount = 0 AND TotalRows > 0 THEN '(All NULLs)' -- Only NULLs (Distinct=0, Whitespace=0)
                WHEN DistinctValues = 0 AND NullCount > 0 AND WhitespaceCount > 0 AND TotalRows > 0 THEN '(All NULLs or Whitespace)' -- Mixed NULLs/Whitespace (Distinct=0, Whitespace>0)
                WHEN MinValue LIKE 'N/A%' THEN MinValue -- Show N/A (Type)
                WHEN TopValues IS NULL AND DistinctValues > 0 THEN 'Distinct: ' + CAST(DistinctValues AS VARCHAR(20)) -- Fallback if TopValues wasn't calculated but distinct exist
                ELSE 'N/A' -- Default
            END AS "Values Info (Top N / Range / Single)",
            CASE WHEN SortOrder = 99 THEN NULL ELSE SampleData END AS "Sample Data",
            DataType AS "DB DATA TYPE",
            CASE
                WHEN DataType IN ('decimal', 'numeric') THEN '(' + CAST(NumericPrecision AS VARCHAR(5)) + ',' + CAST(NumericScale AS VARCHAR(5)) + ')'
                WHEN DataType LIKE '%char%' AND CharacterMaxLength > 0 THEN '(' + CAST(CharacterMaxLength AS VARCHAR(10)) + ')'
                WHEN DataType LIKE '%char%' AND CharacterMaxLength = -1 THEN '(MAX)'
                ELSE ''
            END AS "DB TYPE details",
            TotalRows AS "Total rows",
            NullCount AS "Null count",
            WhitespaceCount AS "Whitespace-only count",
            CASE WHEN TotalRows > 0 THEN CAST(CAST(ISNULL(NullCount, 0) * 100.0 / TotalRows AS DECIMAL(5, 2)) AS VARCHAR(10)) + '%' ELSE 'N/A' END AS "Null Pct",
            CASE WHEN TotalRows > 0 THEN CAST(CAST(ISNULL(WhitespaceCount, 0) * 100.0 / TotalRows AS DECIMAL(5, 2)) AS VARCHAR(10)) + '%' ELSE 'N/A' END AS "Whitespace Pct",
            IsUniqueFlag AS "Is Unique / Flag",
            SortOrder -- Keep for ordering, can be removed from final SELECT if desired
        FROM #ColumnAuditResults
        ORDER BY SortOrder, ColumnName;

        IF @@ROWCOUNT = 0 AND @DebugMode = 1 BEGIN PRINT 'Warning: Final SELECT returned no rows...'; END

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage_FinalSelect NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Error in final result selection: %s', 16, 1, @ErrorMessage_FinalSelect);
    END CATCH

    -- Cleanup
    IF OBJECT_ID('tempdb..#ColumnAuditResults') IS NOT NULL
        DROP TABLE #ColumnAuditResults;
END;
GO
