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

    -- [Previous code remains the same until the final SELECT statement]

    -- Final result with requested column order
    SELECT
        ColumnName AS "COLUMN",
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
        DistinctValues AS "Distinct values",
        CASE
            WHEN TopValues IS NOT NULL AND DataType IN ('char', 'nchar', 'varchar', 'nvarchar', 'text', 'ntext') THEN TopValues
            WHEN DataType IN ('decimal', 'numeric', 'money', 'smallmoney', 'int', 'bigint', 'smallint', 'tinyint', 'float', 'real')
                 AND MinValue IS NOT NULL AND DistinctValues > 1 THEN 'Range: [' + ISNULL(MinValue, 'NULL') + '] to [' + ISNULL(MaxValue, 'NULL') + ']'
            WHEN DataType IN ('decimal', 'numeric', 'money', 'smallmoney', 'int', 'bigint', 'smallint', 'tinyint', 'float', 'real')
                 AND DistinctValues = 1 AND MinValue IS NOT NULL THEN 'Single Value: ' + MinValue
            WHEN DistinctValues = 0 AND TotalRows > 0 THEN '(All NULLs)'
            WHEN DataType IN ('char', 'nchar', 'varchar', 'nvarchar', 'text', 'ntext') AND 
                 (TRY_CAST(MinValue AS FLOAT) IS NULL OR TRY_CAST(MaxValue AS FLOAT) IS NULL) THEN 
                 CASE WHEN TopValues IS NOT NULL THEN TopValues ELSE 'Text values' END
            WHEN DataType IN ('char', 'nchar', 'varchar', 'nvarchar', 'text', 'ntext') AND 
                 TRY_CAST(MinValue AS FLOAT) IS NOT NULL AND TRY_CAST(MaxValue AS FLOAT) IS NOT NULL THEN
                 'Numeric Range: [' + ISNULL(MinValue, 'NULL') + '] to [' + ISNULL(MaxValue, 'NULL') + ']'
            ELSE 'N/A'
        END AS "Values Info (Top N / Range / Single)",
        SampleData AS "Sample Data",
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
        IsUnique AS "Is Unique",
        SortOrder
    FROM #ColumnAuditResults
    ORDER BY SortOrder, ColumnName;

    DROP TABLE #ColumnAuditResults;
END;