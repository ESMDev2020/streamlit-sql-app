-- Stored procedure: sp_format_query_with_descriptions
-- Description: This procedure takes a SQL query with table and column codes,
-- and returns the query with actual table/column names and descriptions as comments.

USE SigmaTB;
GO

CREATE OR ALTER PROCEDURE sp_format_query_with_descriptions
    @InputQuery NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    -- Create debug log table
    CREATE TABLE #DebugLog (
        LogTime DATETIME DEFAULT GETDATE(),
        Step NVARCHAR(50),
        Message NVARCHAR(MAX)
    );

    -- Log input query
    INSERT INTO #DebugLog (Step, Message)
    VALUES ('Input', 'Original query: ' + @InputQuery);

    -- Create a temporary table to store table and column mappings
    CREATE TABLE #TableColumnMappings (
        TableCode NVARCHAR(128),
        TableName NVARCHAR(128),
        TableDescription NVARCHAR(MAX),
        ColumnCode NVARCHAR(128),
        ColumnName NVARCHAR(128),
        ColumnDescription NVARCHAR(MAX)
    );

    -- Get table and column information
    INSERT INTO #TableColumnMappings
    SELECT
        CONVERT(NVARCHAR(128), ep_t.name) AS TableCode,
        CONVERT(NVARCHAR(128), t.name) AS TableName,
        CONVERT(NVARCHAR(MAX), ep_t.value) AS TableDescription,
        CONVERT(NVARCHAR(128), ep_c.name) AS ColumnCode,
        CONVERT(NVARCHAR(128), c.name) AS ColumnName,
        CONVERT(NVARCHAR(MAX), ep_c.value) AS ColumnDescription
    FROM sys.extended_properties AS ep_t
    INNER JOIN sys.tables AS t ON ep_t.major_id = t.object_id
    INNER JOIN sys.columns AS c ON t.object_id = c.object_id
    INNER JOIN sys.extended_properties AS ep_c
        ON ep_c.major_id = c.object_id
        AND ep_c.minor_id = c.column_id
    WHERE ep_t.class = 1
        AND ep_t.minor_id = 0
        AND ep_c.class = 1;

    -- Log mappings
    INSERT INTO #DebugLog (Step, Message)
    SELECT 'Mapping',
           'Table: ' + TableCode + ' -> ' + TableName +
           ', Column: ' + ColumnCode + ' -> ' + ColumnName
    FROM #TableColumnMappings;

    -- Start building the formatted query
    DECLARE @FormattedQuery NVARCHAR(MAX) = @InputQuery;

    -- Replace table codes with actual names and add descriptions
    DECLARE @TableCode NVARCHAR(128);
    DECLARE @TableName NVARCHAR(128);
    DECLARE @TableDescription NVARCHAR(MAX);

    DECLARE table_cursor CURSOR FOR
    SELECT DISTINCT TableCode, TableName, TableDescription
    FROM #TableColumnMappings;

    OPEN table_cursor;
    FETCH NEXT FROM table_cursor INTO @TableCode, @TableName, @TableDescription;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Log replacement
        INSERT INTO #DebugLog (Step, Message)
        VALUES ('Replace', 'Replacing table code: ''' + @TableCode + ''' with: ''' + @TableName + '''');

        -- Replace table code with actual name
        SET @FormattedQuery = REPLACE(@FormattedQuery, @TableCode, @TableName);

        -- Add table description as comment
        IF @TableDescription IS NOT NULL
        BEGIN
            SET @FormattedQuery = '-- Table: ' + @TableName + ' - ' + @TableDescription + CHAR(13) + CHAR(10) + @FormattedQuery;
        END

        FETCH NEXT FROM table_cursor INTO @TableCode, @TableName, @TableDescription;
    END;

    CLOSE table_cursor;
    DEALLOCATE table_cursor;

    -- Replace column codes with actual names and add descriptions
    DECLARE @ColumnCode NVARCHAR(128);
    DECLARE @ColumnName NVARCHAR(128);
    DECLARE @ColumnDescription NVARCHAR(MAX);

    DECLARE column_cursor CURSOR FOR
    SELECT ColumnCode, ColumnName, ColumnDescription
    FROM #TableColumnMappings;

    OPEN column_cursor;
    FETCH NEXT FROM column_cursor INTO @ColumnCode, @ColumnName, @ColumnDescription;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Log replacement
        INSERT INTO #DebugLog (Step, Message)
        VALUES ('Replace', 'Replacing column code: ''' + @ColumnCode + ''' with: ''' + @ColumnName + '''');

        -- Replace column code with actual name
        SET @FormattedQuery = REPLACE(@FormattedQuery, @ColumnCode, @ColumnName);

        -- Add column description as comment
        IF @ColumnDescription IS NOT NULL
        BEGIN
            SET @FormattedQuery = '-- Column: ' + @ColumnName + ' - ' + @ColumnDescription + CHAR(13) + CHAR(10) + @FormattedQuery;
        END

        FETCH NEXT FROM column_cursor INTO @ColumnCode, @ColumnName, @ColumnDescription;
    END;

    CLOSE column_cursor;
    DEALLOCATE column_cursor;

    -- Log final query
    INSERT INTO #DebugLog (Step, Message)
    VALUES ('Output', 'Final formatted query: ' + @FormattedQuery);

    -- Return both the formatted query and debug log
    SELECT @FormattedQuery AS FormattedQuery;
    SELECT * FROM #DebugLog ORDER BY LogTime;

    -- Clean up
    DROP TABLE #TableColumnMappings;
    DROP TABLE #DebugLog;
END;
GO