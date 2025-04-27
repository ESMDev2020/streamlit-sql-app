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

    -- === ALL DECLARATIONS MUST BE AT THE TOP ===
    DECLARE @my_var_varchar_procedure_start_message VARCHAR(50);
    DECLARE @my_var_varchar_procedure_end_message VARCHAR(50);
    DECLARE @my_var_varchar_not_found VARCHAR(20);
    DECLARE @my_var_varchar_table VARCHAR(10);
    DECLARE @my_var_varchar_column VARCHAR(10);
    DECLARE @my_var_datetime_start_time DATETIME2;
    DECLARE @my_var_datetime_end_time DATETIME2;
    DECLARE @my_var_int_error_number INT;
    DECLARE @my_var_int_error_severity INT;
    DECLARE @my_var_int_error_state INT;
    DECLARE @my_var_nvarchar_error_procedure NVARCHAR(128);
    DECLARE @my_var_int_error_line INT;
    DECLARE @my_var_nvarchar_error_message NVARCHAR(MAX);
    -- === END OF DECLARATIONS ===

    -- === INITIALIZE VARIABLES using SET ===
    SET @my_var_varchar_procedure_start_message = 'Starting execution';
    SET @my_var_varchar_procedure_end_message = 'Finished execution';
    SET @my_var_varchar_not_found = 'NOT FOUND';
    SET @my_var_varchar_table = 'Table';
    SET @my_var_varchar_column = 'Column';
    -- === END OF INITIALIZATION ===

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

    -- Extract table codes from the query
    DECLARE @TableCodes TABLE (TableCode NVARCHAR(128));
    
    -- Find table codes after FROM and JOIN keywords
    DECLARE @Pos INT = 1;
    DECLARE @FromPos INT;
    DECLARE @JoinPos INT;
    DECLARE @NextSpace INT;
    DECLARE @TableCode NVARCHAR(128);

    WHILE @Pos <= LEN(@InputQuery)
    BEGIN
        SET @FromPos = CHARINDEX('FROM', @InputQuery, @Pos);
        SET @JoinPos = CHARINDEX('JOIN', @InputQuery, @Pos);
        
        IF @FromPos > 0 OR @JoinPos > 0
        BEGIN
            -- Get the position of the next keyword
            DECLARE @KeywordPos INT = CASE 
                WHEN @FromPos > 0 AND (@JoinPos = 0 OR @FromPos < @JoinPos) THEN @FromPos
                ELSE @JoinPos
            END;
            
            -- Find the next space after the keyword
            SET @NextSpace = CHARINDEX(' ', @InputQuery, @KeywordPos + 4);
            IF @NextSpace = 0 SET @NextSpace = LEN(@InputQuery) + 1;
            
            -- Extract the table code
            SET @TableCode = LTRIM(RTRIM(SUBSTRING(@InputQuery, @KeywordPos + 4, @NextSpace - (@KeywordPos + 4))));
            
            -- Remove any trailing characters that aren't part of the table code
            IF CHARINDEX(',', @TableCode) > 0
                SET @TableCode = SUBSTRING(@TableCode, 1, CHARINDEX(',', @TableCode) - 1);
            IF CHARINDEX(' ', @TableCode) > 0
                SET @TableCode = SUBSTRING(@TableCode, 1, CHARINDEX(' ', @TableCode) - 1);
            
            INSERT INTO @TableCodes (TableCode) VALUES (@TableCode);
            
            -- Log found table code
            INSERT INTO #DebugLog (Step, Message)
            VALUES ('TableCode', 'Found table code: ' + @TableCode);
            
            SET @Pos = @NextSpace;
        END
        ELSE
            BREAK;
    END;

    -- Get table and column information
    INSERT INTO #TableColumnMappings
    SELECT 
        ep_t.name AS TableCode,
        t.name AS TableName,
        CONVERT(NVARCHAR(MAX), ep_t.value) AS TableDescription,
        ep_c.name AS ColumnCode,
        c.name AS ColumnName,
        CONVERT(NVARCHAR(MAX), ep_c.value) AS ColumnDescription
    FROM sys.extended_properties AS ep_t
    INNER JOIN sys.tables AS t ON ep_t.major_id = t.object_id
    INNER JOIN sys.columns AS c ON t.object_id = c.object_id
    INNER JOIN sys.extended_properties AS ep_c
        ON ep_c.major_id = c.object_id
        AND ep_c.minor_id = c.column_id
    WHERE ep_t.class = 1
        AND ep_t.minor_id = 0
        AND ep_t.name IN (SELECT TableCode FROM @TableCodes)
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
        VALUES ('Replace', 'Replacing table code: ' + @TableCode + ' with: ' + @TableName);
        
        -- Debug the current state
        INSERT INTO #DebugLog (Step, Message)
        VALUES ('Debug', 'Before replacement - Query: ' + @FormattedQuery);
        
        -- Replace table code with actual name
        SET @FormattedQuery = REPLACE(@FormattedQuery, ' ' + @TableCode + ' ', ' ' + @TableName + ' ');
        SET @FormattedQuery = REPLACE(@FormattedQuery, ' ' + @TableCode + ',', ' ' + @TableName + ',');
        SET @FormattedQuery = REPLACE(@FormattedQuery, ' ' + @TableCode + ';', ' ' + @TableName + ';');
        SET @FormattedQuery = REPLACE(@FormattedQuery, ' ' + @TableCode + CHAR(13), ' ' + @TableName + CHAR(13));
        SET @FormattedQuery = REPLACE(@FormattedQuery, ' ' + @TableCode + CHAR(10), ' ' + @TableName + CHAR(10));
        
        -- Debug the result
        INSERT INTO #DebugLog (Step, Message)
        VALUES ('Debug', 'After replacement - Query: ' + @FormattedQuery);
        
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
        VALUES ('Replace', 'Replacing column code: ' + @ColumnCode + ' with: ' + @ColumnName);
        
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