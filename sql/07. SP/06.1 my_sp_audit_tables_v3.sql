/******************************************************
STORED PROCEDURE my_sp_audit_tables

VERSION
	3
	
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
    @SchemaName NVARCHAR(128) = N'dbo',
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

    -- Temporary table to store results
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
        TopValues NVARCHAR(MAX),
        SampleData NVARCHAR(MAX),
        SortOrder INT
    );

    -- Get total row count
    DECLARE @TotalRows BIGINT;
    DECLARE @SQL NVARCHAR(MAX) = N'SELECT @TotalRowsOUT = COUNT_BIG(*) FROM ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ';';
    EXEC sp_executesql @SQL, N'@TotalRowsOUT BIGINT OUTPUT', @TotalRowsOUT = @TotalRows OUTPUT;

    -- Process each column
    DECLARE @ColumnList CURSOR;
    SET @ColumnList = CURSOR LOCAL FAST_FORWARD FOR
        SELECT COLUMN_NAME, DATA_TYPE
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = @SchemaName AND TABLE_NAME = @TableName
        ORDER BY ORDINAL_POSITION;

    DECLARE @CurrentColumn NVARCHAR(128), @CurrentDataType NVARCHAR(128);
    OPEN @ColumnList;
    FETCH NEXT FROM @ColumnList INTO @CurrentColumn, @CurrentDataType;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @DistinctCount BIGINT, @NullCount BIGINT, @IsUnique BIT;
        DECLARE @MinVal NVARCHAR(MAX), @MaxVal NVARCHAR(MAX), @TopVals NVARCHAR(MAX), @SampleVals NVARCHAR(MAX);
        DECLARE @SortOrder INT;

        -- Get basic column stats
        SET @SQL = N'
        SELECT
            @DistinctCountOUT = COUNT(DISTINCT ' + QUOTENAME(@CurrentColumn) + '),
            @NullCountOUT = SUM(CASE WHEN ' + QUOTENAME(@CurrentColumn) + ' IS NULL THEN 1 ELSE 0 END)
        FROM ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ';';
        
        EXEC sp_executesql @SQL, 
            N'@DistinctCountOUT BIGINT OUTPUT, @NullCountOUT BIGINT OUTPUT',
            @DistinctCountOUT = @DistinctCount OUTPUT, 
            @NullCountOUT = @NullCount OUTPUT;

        -- Check uniqueness
        SET @IsUnique = CASE WHEN @TotalRows > 0 AND @DistinctCount = @TotalRows - @NullCount AND @NullCount = 0 THEN 1 ELSE 0 END;

        -- Get min/max for numeric/date types
        IF @CurrentDataType NOT IN ('text', 'ntext', 'image', 'xml', 'geometry', 'geography')
        BEGIN
            SET @SQL = N'
            SELECT
                @MinValOUT = (SELECT MIN(CAST(' + QUOTENAME(@CurrentColumn) + ' AS NVARCHAR(MAX))) FROM ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ' WHERE ' + QUOTENAME(@CurrentColumn) + ' IS NOT NULL),
                @MaxValOUT = (SELECT MAX(CAST(' + QUOTENAME(@CurrentColumn) + ' AS NVARCHAR(MAX))) FROM ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ' WHERE ' + QUOTENAME(@CurrentColumn) + ' IS NOT NULL);';
            
            EXEC sp_executesql @SQL, 
                N'@MinValOUT NVARCHAR(MAX) OUTPUT, @MaxValOUT NVARCHAR(MAX) OUTPUT',
                @MinValOUT = @MinVal OUTPUT, 
                @MaxValOUT = @MaxVal OUTPUT;
        END
        ELSE
        BEGIN
            SET @MinVal = 'N/A';
            SET @MaxVal = 'N/A';
        END

        -- Get top values for low-cardinality columns
        IF @DistinctCount > 0 AND @DistinctCount <= @MaxCodesToShow * 2
        BEGIN
            SET @SQL = N'
            WITH ValueCounts AS (
                SELECT TOP (@MaxCodesToShow)
                    CAST(' + QUOTENAME(@CurrentColumn) + ' AS NVARCHAR(MAX)) AS Value,
                    COUNT(*) AS Count
                FROM ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + '
                WHERE ' + QUOTENAME(@CurrentColumn) + ' IS NOT NULL
                GROUP BY CAST(' + QUOTENAME(@CurrentColumn) + ' AS NVARCHAR(MAX))
                ORDER BY Count DESC
            )
            SELECT @TopValsOUT = STRING_AGG(Value + '' ('' + CAST(Count AS NVARCHAR(20)) + '')'', '', '')
            FROM ValueCounts;';
            
            EXEC sp_executesql @SQL, 
                N'@MaxCodesToShow INT, @TopValsOUT NVARCHAR(MAX) OUTPUT',
                @MaxCodesToShow = @MaxCodesToShow, 
                @TopValsOUT = @TopVals OUTPUT;
        END

        -- Get sample data
        SET @SQL = N'
        SELECT @SampleValsOUT = STRING_AGG(
            CASE WHEN Val IS NULL THEN ''NULL''
                 ELSE LEFT(CAST(Val AS NVARCHAR(MAX)), 100)
            END, '', ''
        ) WITHIN GROUP (ORDER BY SampleKey)
        FROM (
            SELECT TOP (@SampleSize) ' + QUOTENAME(@CurrentColumn) + ' AS Val, NEWID() as SampleKey
            FROM ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + '
            ORDER BY SampleKey
        ) AS Samples;';
        
        EXEC sp_executesql @SQL, 
            N'@SampleSize INT, @SampleValsOUT NVARCHAR(MAX) OUTPUT',
            @SampleSize = @SampleSize, 
            @SampleValsOUT = @SampleVals OUTPUT;

        -- Determine sort order
        SET @SortOrder = CASE
            WHEN @IsUnique = 1 AND (@CurrentColumn LIKE '%id' OR @CurrentColumn LIKE 'id%') THEN 0 -- PK
            WHEN @CurrentDataType IN ('uniqueidentifier') THEN 1 -- GUID
            WHEN @CurrentColumn LIKE '%id' OR @CurrentColumn LIKE '%code%' OR @CurrentColumn LIKE '%key%' THEN 2 -- FK/Code
            WHEN @CurrentDataType IN ('money', 'smallmoney', 'decimal', 'numeric') THEN 3 -- Money/Numeric
            WHEN @CurrentDataType IN ('int', 'bigint', 'smallint', 'tinyint') THEN 4 -- Integer
            WHEN @CurrentDataType IN ('float', 'real') THEN 5 -- Float
            WHEN @CurrentDataType IN ('bit') THEN 6 -- Bit
            WHEN @DistinctCount BETWEEN 1 AND @MaxCodesToShow * 2 THEN 7 -- Category/Code
            WHEN @CurrentDataType IN ('char', 'nchar', 'varchar', 'nvarchar') THEN 8 -- Text
            WHEN @CurrentDataType IN ('date', 'datetime', 'datetime2', 'smalldatetime', 'time', 'datetimeoffset') THEN 9 -- Date/Time
            ELSE 10 -- Other types
        END;

        -- Insert results
        INSERT INTO #ColumnAuditResults (
            ColumnName, DataType, CharacterMaxLength, NumericPrecision, NumericScale,
            TotalRows, DistinctValues, NullCount, IsUnique, MinValue, MaxValue, 
            TopValues, SampleData, SortOrder
        )
        SELECT
            c.COLUMN_NAME, c.DATA_TYPE, c.CHARACTER_MAXIMUM_LENGTH, 
            c.NUMERIC_PRECISION, c.NUMERIC_SCALE,
            @TotalRows, @DistinctCount, @NullCount, @IsUnique, 
            @MinVal, @MaxVal, @TopVals, @SampleVals, @SortOrder
        FROM INFORMATION_SCHEMA.COLUMNS c
        WHERE c.TABLE_SCHEMA = @SchemaName 
          AND c.TABLE_NAME = @TableName 
          AND c.COLUMN_NAME = @CurrentColumn;

        FETCH NEXT FROM @ColumnList INTO @CurrentColumn, @CurrentDataType;
    END

    CLOSE @ColumnList;
    DEALLOCATE @ColumnList;

    -- Final result with requested column order
    SELECT
        ColumnName AS "COLUMN",
        IsUnique AS "Is Unique",
        DistinctValues AS "Distinct values",
        CASE
            WHEN TopValues IS NOT NULL THEN TopValues
            WHEN DataType IN ('decimal', 'numeric', 'money', 'smallmoney', 'int', 'bigint', 'smallint', 'tinyint', 'float', 'real')
                 AND MinValue IS NOT NULL AND DistinctValues > 1 THEN 'Range: [' + ISNULL(MinValue, 'NULL') + '] to [' + ISNULL(MaxValue, 'NULL') + ']'
            WHEN DistinctValues = 1 AND MinValue IS NOT NULL THEN 'Single Value: ' + MinValue
            WHEN DistinctValues = 0 AND TotalRows > 0 THEN '(All NULLs)'
            ELSE 'N/A'
        END AS "Values Info (Top N / Range / Single)",
        SampleData AS "Sample Data",
        CASE
            WHEN IsUnique = 1 AND (ColumnName LIKE '%id' OR ColumnName LIKE 'id%') THEN 'PK'
            WHEN DataType IN ('uniqueidentifier') THEN 'GUID'
            WHEN ColumnName LIKE '%id' OR ColumnName LIKE '%code%' OR ColumnName LIKE '%key%' THEN 'FK/Code'
            WHEN DataType IN ('money', 'smallmoney', 'decimal', 'numeric') THEN 'Money/Numeric'
            WHEN DataType IN ('int', 'bigint', 'smallint', 'tinyint') THEN 'Integer'
            WHEN DataType IN ('float', 'real') THEN 'Float'
            WHEN DataType IN ('bit') THEN 'Bit'
            WHEN DistinctValues BETWEEN 1 AND @MaxCodesToShow * 2 THEN 'Category/Code'
            WHEN DataType IN ('char', 'nchar', 'varchar', 'nvarchar') THEN 'Text'
            WHEN DataType IN ('date', 'datetime', 'datetime2', 'smalldatetime', 'time', 'datetimeoffset') THEN 'Date/Time'
            ELSE 'Other'
        END AS "TYPE",
        DataType AS "DB DATA TYPE",
        CASE
            WHEN DataType IN ('decimal', 'numeric') THEN '(' + CAST(NumericPrecision AS VARCHAR(5)) + ',' + CAST(NumericScale AS VARCHAR(5)) + ')'
            WHEN DataType LIKE '%char%' AND CharacterMaxLength > 0 THEN '(' + CAST(CharacterMaxLength AS VARCHAR(10)) + ')'
            WHEN DataType LIKE '%char%' AND CharacterMaxLength = -1 THEN '(MAX)'
            ELSE ''
        END AS "DB TYPE details",
        TotalRows AS "Total rows",
        NullCount AS "Null count",
        CASE
            WHEN TotalRows > 0 AND NullCount > 0 THEN CAST(CAST(NullCount * 100.0 / TotalRows AS DECIMAL(5, 2)) AS VARCHAR(10)) + '%'
            WHEN NullCount = 0 THEN '0.00%'
            ELSE 'N/A'
        END AS "Null Pct",
        SortOrder
    FROM #ColumnAuditResults
    ORDER BY IsUnique DESC, SortOrder ASC, DistinctValues DESC, ColumnName;

    DROP TABLE #ColumnAuditResults;
END;