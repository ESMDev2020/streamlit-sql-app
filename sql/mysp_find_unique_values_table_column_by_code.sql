/*********************************************************
THIS RETURNS THE DISTINCT REGISTERS BY COLUMN BASED ON CODE
*******************************************************/

USE SigmaTB;
GO

CREATE OR ALTER PROCEDURE mysp_find_unique_values_table_column_by_code
    @InputTableCode SYSNAME,
    @InputColumnCode SYSNAME,
    @InputColumnDescription SYSNAME
AS
BEGIN
    SET NOCOUNT ON;

    -- Create a temporary table for debug messages if it doesn't exist
    IF OBJECT_ID('tempdb..#DebugLog') IS NULL
    BEGIN
        CREATE TABLE #DebugLog (
            LogTime DATETIME DEFAULT GETDATE(),
            Message NVARCHAR(MAX)
        );
    END

    -- Log input parameters
    INSERT INTO #DebugLog (Message)
    VALUES ('Starting procedure with parameters: TableCode=' + @InputTableCode + ', ColumnCode=' + @InputColumnCode + ', ColumnDescription=' + @InputColumnDescription);

    DECLARE @TableName NVARCHAR(128);
    DECLARE @ColumnName NVARCHAR(128);
    DECLARE @SchemaName NVARCHAR(128);
    DECLARE @SQL NVARCHAR(MAX);

    -- First, get the actual table and column names
    SELECT TOP 1
        @SchemaName = s.name,
        @TableName = t.name,
        @ColumnName = c.name
    FROM
        SigmaTB.sys.extended_properties AS ep_t
    INNER JOIN
        SigmaTB.sys.tables AS t ON ep_t.major_id = t.object_id
    INNER JOIN
        SigmaTB.sys.schemas AS s ON t.schema_id = s.schema_id
    INNER JOIN
        SigmaTB.sys.columns AS c ON t.object_id = c.object_id
    INNER JOIN
        SigmaTB.sys.extended_properties AS ep_c
        ON ep_c.major_id = c.object_id
        AND ep_c.minor_id = c.column_id
    WHERE
        ep_t.class = 1
        AND ep_t.minor_id = 0
        AND ep_t.name = @InputTableCode
        AND ep_c.class = 1
        AND ep_c.name = @InputColumnCode;

    -- Log found table and column information
    INSERT INTO #DebugLog (Message)
    VALUES ('Found table information: Schema=' + ISNULL(@SchemaName, 'NULL') + 
            ', Table=' + ISNULL(@TableName, 'NULL') + 
            ', Column=' + ISNULL(@ColumnName, 'NULL'));

    -- If we found the table and column, execute the dynamic SQL
    IF @TableName IS NOT NULL AND @ColumnName IS NOT NULL
    BEGIN
        -- First result set: Count of unique values
 /*       SET @SQL = N'
        SELECT 
            COUNT(DISTINCT [' + @ColumnName + ']) AS [' + @InputColumnCode + '_Count]
        FROM 
            SigmaTB.[' + @SchemaName + '].[' + @TableName + ']
        WHERE 
            [' + @ColumnName + '] IS NOT NULL';
            

        INSERT INTO #DebugLog (Message)
        VALUES ('Executing count query: ' + @SQL);

        EXEC sp_executesql @SQL;
*/

        -- Second result set: List of unique values with their counts
        SET @SQL = N'
        SELECT 
            [' + @ColumnName + '] AS [' + @InputColumnCode + '],
            COUNT(*) AS mRowCount,
            ''' + @InputColumnDescription + ''' AS ColumnDescription
        FROM 
            SigmaTB.[' + @SchemaName + '].[' + @TableName + ']
        WHERE 
            [' + @ColumnName + '] IS NOT NULL
        GROUP BY 
            [' + @ColumnName + ']
        ORDER BY 
            [' + @ColumnName + ']';

        INSERT INTO #DebugLog (Message)
        VALUES ('Executing values query: ' + @SQL);

        EXEC sp_executesql @SQL;
    END
    ELSE
    BEGIN
        INSERT INTO #DebugLog (Message)
        VALUES ('ERROR: Table or column not found with the specified codes');
        
        RAISERROR('Table or column not found with the specified codes', 16, 1);
    END

    -- Return debug log as a result set
    --SELECT * FROM #DebugLog ORDER BY LogTime;
END;
