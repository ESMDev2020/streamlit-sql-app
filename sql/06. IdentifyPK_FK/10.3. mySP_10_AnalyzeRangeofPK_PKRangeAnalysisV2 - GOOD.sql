/*
=================================================================
Procedure: PKRangeAnalysis
Description: This stored procedure analyzes primary key ranges for all tables
             identified in the mrs.PKCheckResults table. It handles special characters
             in table names and captures errors in a robust way. The procedure also 
             extracts table and column codes either by parsing names or retrieving 
             extended properties.

Parameters: 
    @myVarBitDebugMode - 1 for debug mode (prints progress), 0 for silent execution
    @myVarBitUseExtendedProps - 1 to use extended properties for codes, 0 to parse from names

Output:
    Creates table: mrs.PKRangeResults with analysis results

Author: Modified from original code
Version: 2.0
Date: May 04, 2025
=================================================================
*/

CREATE OR ALTER PROCEDURE [mrs].[PKRangeAnalysis]
    @myVarBitDebugMode BIT = 0,
    @myVarBitUseExtendedProps BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Declare variables
    DECLARE @myVarDtStartTime DATETIME = GETDATE();
    DECLARE @myVarNvarTableName NVARCHAR(128);
    DECLARE @myVarNvarSchemaName NVARCHAR(128);
    DECLARE @myVarNvarFullTableName NVARCHAR(258); -- Schema.Table
    DECLARE @myVarNvarColumnPK NVARCHAR(128);
    DECLARE @myVarIntRowCnt INT;
    DECLARE @myVarNvarComment NVARCHAR(255);
    DECLARE @myVarNvarSQL NVARCHAR(MAX);
    DECLARE @myVarIntCounter INT = 0;
    DECLARE @myVarIntTotalTables INT;
    DECLARE @myVarBitTableExists BIT;
    DECLARE @myVarNvarTableCode NVARCHAR(50);
    DECLARE @myVarNvarColumnCode NVARCHAR(50);
    DECLARE @myVarIntObjectId INT;
    DECLARE @myVarIntColumnId INT;
    
    -- Print start time if debug mode is on
    IF @myVarBitDebugMode = 1
    BEGIN
        PRINT '================================================';
        PRINT 'Starting execution at: ' + CONVERT(VARCHAR(30), @myVarDtStartTime, 121);
        PRINT 'Using extended properties for codes: ' + CASE WHEN @myVarBitUseExtendedProps = 1 THEN 'Yes' ELSE 'No' END;
        PRINT '================================================';
    END
    
    -- Create table to store final results
    IF OBJECT_ID('mrs.PKRangeResults') IS NOT NULL
        DROP TABLE [mrs].[PKRangeResults];
        
    CREATE TABLE [mrs].[PKRangeResults] (
        [TableName] NVARCHAR(128),
        [TableCode] NVARCHAR(50),
        [ColumnPK] NVARCHAR(128),
        [ColumnCode] NVARCHAR(50),
        [TotalRows] INT,
        [Comment] NVARCHAR(255),
        [LowestValue] NVARCHAR(255),
        [HighestValue] NVARCHAR(255),
        [IsError] BIT,
        [ErrorMessage] NVARCHAR(4000) NULL
    );
    
    -- Get total count of tables for progress reporting
    SELECT @myVarIntTotalTables = COUNT(*) 
    FROM [mrs].[PKCheckResults]
    WHERE [Comment] = 'PK found' AND [ColumnPK] IS NOT NULL;
    
    -- Begin transaction
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Deallocate cursor if it already exists
        IF CURSOR_STATUS('global', 'pk_cursor') >= 0
        BEGIN
            CLOSE pk_cursor;
            DEALLOCATE pk_cursor;
        END
        
        -- Cursor to iterate through tables with primary keys
        DECLARE pk_cursor CURSOR FOR
        SELECT [TableName], [RowCount], [Comment], [ColumnPK] 
        FROM [mrs].[PKCheckResults]
        WHERE [Comment] = 'PK found' AND [ColumnPK] IS NOT NULL
        AND [TableName] LIKE 'z\_%' ESCAPE '\'; -- Only include tables with 'z_' prefix
        
        OPEN pk_cursor;
        FETCH NEXT FROM pk_cursor INTO @myVarNvarTableName, @myVarIntRowCnt, @myVarNvarComment, @myVarNvarColumnPK;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @myVarIntCounter = @myVarIntCounter + 1;
            
            -- Print progress if debug mode is on
            IF @myVarBitDebugMode = 1 AND @myVarIntCounter % 10 = 0
            BEGIN
                PRINT 'Processing table ' + CAST(@myVarIntCounter AS VARCHAR(10)) + ' of ' + 
                      CAST(@myVarIntTotalTables AS VARCHAR(10)) + ': ' + @myVarNvarTableName;
            END
            
            -- Parse table name to handle schema properly
            SET @myVarNvarSchemaName = 'mrs'; -- Default schema
            
            -- If the table name includes a schema (contains a period)
            IF CHARINDEX('.', @myVarNvarTableName) > 0
            BEGIN
                SET @myVarNvarSchemaName = PARSENAME(@myVarNvarTableName, 2);
                SET @myVarNvarTableName = PARSENAME(@myVarNvarTableName, 1);
            END
            
            -- Check if table exists using sys.tables - more reliable
            SET @myVarBitTableExists = 0;
            SET @myVarNvarSQL = N'
            SELECT @TableExists = COUNT(*),
                   @ObjectId = OBJECT_ID(@SchemaName + ''.'' + @TableName)
            FROM sys.tables t
            JOIN sys.schemas s ON t.schema_id = s.schema_id
            WHERE s.name = @SchemaName AND t.name = @TableName';
            
            IF @myVarBitDebugMode = 1
            BEGIN
                PRINT '--- Checking if table exists: ' + @myVarNvarSchemaName + '.' + @myVarNvarTableName + ' ---';
                PRINT 'SQL Query: ' + @myVarNvarSQL;
            END
            
            EXEC sp_executesql @myVarNvarSQL, 
                 N'@SchemaName NVARCHAR(128), @TableName NVARCHAR(128), @TableExists BIT OUTPUT, @ObjectId INT OUTPUT', 
                 @myVarNvarSchemaName, @myVarNvarTableName, @myVarBitTableExists OUTPUT, @myVarIntObjectId OUTPUT;
                 
            IF @myVarBitDebugMode = 1
            BEGIN
                PRINT 'Table exists: ' + CAST(@myVarBitTableExists AS NVARCHAR(1));
                PRINT 'ObjectId: ' + ISNULL(CAST(@myVarIntObjectId AS NVARCHAR(50)), 'NULL');
            END
            
            -- Construct fully qualified table name for later use
            SET @myVarNvarFullTableName = QUOTENAME(@myVarNvarSchemaName) + '.' + QUOTENAME(@myVarNvarTableName);
            
            -- Initialize table and column codes
            SET @myVarNvarTableCode = 'UNKNOWN';
            SET @myVarNvarColumnCode = 'UNKNOWN';
            
            IF @myVarBitTableExists = 0
            BEGIN
                -- Table doesn't exist, record this information
                INSERT INTO [mrs].[PKRangeResults] (
                    [TableName], [TableCode], [ColumnPK], [ColumnCode], 
                    [TotalRows], [Comment], [LowestValue], [HighestValue], 
                    [IsError], [ErrorMessage]
                )
                VALUES (
                    @myVarNvarTableName, 
                    @myVarNvarTableCode,
                    @myVarNvarColumnPK, 
                    @myVarNvarColumnCode,
                    @myVarIntRowCnt, 
                    @myVarNvarComment, 
                    'N/A', 
                    'N/A', 
                    1, 
                    'Table does not exist in schema ' + @myVarNvarSchemaName
                );
            END
            ELSE
            BEGIN
                -- Check if column exists in the table
                DECLARE @myVarBitColumnExists BIT = 0;
                
                SET @myVarNvarSQL = N'
                SELECT @ColumnExists = COUNT(*),
                       @ColumnId = MAX(c.column_id)
                FROM sys.columns c
                JOIN sys.tables t ON c.object_id = t.object_id
                JOIN sys.schemas s ON t.schema_id = s.schema_id
                WHERE s.name = @SchemaName AND t.name = @TableName AND c.name = @ColumnName';
                
                IF @myVarBitDebugMode = 1
                BEGIN
                    PRINT '--- Checking if column exists: ' + @myVarNvarColumnPK + ' ---';
                    PRINT 'SQL Query: ' + @myVarNvarSQL;
                END
                
                EXEC sp_executesql @myVarNvarSQL, 
                     N'@SchemaName NVARCHAR(128), @TableName NVARCHAR(128), @ColumnName NVARCHAR(128), @ColumnExists BIT OUTPUT, @ColumnId INT OUTPUT', 
                     @myVarNvarSchemaName, @myVarNvarTableName, @myVarNvarColumnPK, @myVarBitColumnExists OUTPUT, @myVarIntColumnId OUTPUT;
                     
                IF @myVarBitDebugMode = 1
                BEGIN
                    PRINT 'Column exists: ' + CAST(@myVarBitColumnExists AS NVARCHAR(1));
                    PRINT 'ColumnId: ' + ISNULL(CAST(@myVarIntColumnId AS NVARCHAR(50)), 'NULL');
                END
                
                -- Get TableCode and ColumnCode based on the selected method
                IF @myVarBitUseExtendedProps = 1
                BEGIN
                    -- Method 2: Use extended properties
                    -- Get TableCode from extended properties
                    SET @myVarNvarSQL = N'
                    SELECT @TableCode = CONVERT(NVARCHAR(50), value)
                    FROM sys.extended_properties
                    WHERE major_id = @ObjectId
                    AND minor_id = 0
                    AND name = ''Code''';
                    
                    IF @myVarBitDebugMode = 1
                    BEGIN
                        PRINT '--- Getting TableCode for ' + @myVarNvarTableName + ' ---';
                        PRINT 'ObjectId: ' + CAST(@myVarIntObjectId AS NVARCHAR(50));
                        PRINT 'SQL Query: ' + @myVarNvarSQL;
                    END
                    
                    EXEC sp_executesql @myVarNvarSQL, 
                         N'@ObjectId INT, @TableCode NVARCHAR(50) OUTPUT', 
                         @myVarIntObjectId, @myVarNvarTableCode OUTPUT;
                         
                    IF @myVarBitDebugMode = 1
                    BEGIN
                        PRINT 'TableCode result: ' + ISNULL(@myVarNvarTableCode, 'NULL');
                        
                        -- Debug query to verify extended properties
                        DECLARE @myVarNvarDebugSQL NVARCHAR(MAX) = N'
                        SELECT ep.name, ep.value, OBJECT_NAME(ep.major_id) AS [TableName]
                        FROM sys.extended_properties ep
                        WHERE ep.major_id = ' + CAST(@myVarIntObjectId AS NVARCHAR(50)) + '
                        AND ep.minor_id = 0';
                        
                        PRINT 'Debug query to check all extended properties for this table: ';
                        PRINT @myVarNvarDebugSQL;
                    END
                    
                    -- If column exists, get ColumnCode from extended properties
                    IF @myVarBitColumnExists = 1
                    BEGIN
                        SET @myVarNvarSQL = N'
                        SELECT @ColumnCode = CONVERT(NVARCHAR(50), value)
                        FROM sys.extended_properties
                        WHERE major_id = @ObjectId
                        AND minor_id = @ColumnId
                        AND name = ''Code''';
                        
                        IF @myVarBitDebugMode = 1
                        BEGIN
                            PRINT '--- Getting ColumnCode for ' + @myVarNvarColumnPK + ' ---';
                            PRINT 'ObjectId: ' + CAST(@myVarIntObjectId AS NVARCHAR(50));
                            PRINT 'ColumnId: ' + CAST(@myVarIntColumnId AS NVARCHAR(50));
                            PRINT 'SQL Query: ' + @myVarNvarSQL;
                        END
                        
                        EXEC sp_executesql @myVarNvarSQL, 
                             N'@ObjectId INT, @ColumnId INT, @ColumnCode NVARCHAR(50) OUTPUT', 
                             @myVarIntObjectId, @myVarIntColumnId, @myVarNvarColumnCode OUTPUT;
                             
                        IF @myVarBitDebugMode = 1
                        BEGIN
                            PRINT 'ColumnCode result: ' + ISNULL(@myVarNvarColumnCode, 'NULL');
                            
                            -- Debug query to verify extended properties for column
                            DECLARE @myVarNvarDebugColSQL NVARCHAR(MAX) = N'
                            SELECT ep.name, ep.value, c.name AS [ColumnName]
                            FROM sys.extended_properties ep
                            JOIN sys.columns c ON ep.major_id = c.object_id AND ep.minor_id = c.column_id
                            WHERE ep.major_id = ' + CAST(@myVarIntObjectId AS NVARCHAR(50)) + '
                            AND ep.minor_id = ' + CAST(@myVarIntColumnId AS NVARCHAR(50));
                            
                            PRINT 'Debug query to check all extended properties for this column: ';
                            PRINT @myVarNvarDebugColSQL;
                        END
                    END
                END
                ELSE
                BEGIN
                    -- Method 1: Parse from name
                    -- Parse TableCode from TableName
                    SET @myVarNvarTableCode = [mrs].[fun_ExtractCodeFromName](@myVarNvarTableName);
                    
                    -- If column exists, parse ColumnCode from ColumnName
                    IF @myVarBitColumnExists = 1
                    BEGIN
                        SET @myVarNvarColumnCode = [mrs].[fun_ExtractCodeFromName](@myVarNvarColumnPK);
                    END
                END
                
                -- Handle NULL codes
                SET @myVarNvarTableCode = ISNULL(@myVarNvarTableCode, 'UNKNOWN');
                SET @myVarNvarColumnCode = ISNULL(@myVarNvarColumnCode, 'UNKNOWN');
                
                IF @myVarBitColumnExists = 0
                BEGIN
                    -- Column doesn't exist in the table
                    INSERT INTO [mrs].[PKRangeResults] (
                        [TableName], [TableCode], [ColumnPK], [ColumnCode], 
                        [TotalRows], [Comment], [LowestValue], [HighestValue], 
                        [IsError], [ErrorMessage]
                    )
                    VALUES (
                        @myVarNvarTableName, 
                        @myVarNvarTableCode,
                        @myVarNvarColumnPK, 
                        @myVarNvarColumnCode,
                        @myVarIntRowCnt, 
                        @myVarNvarComment, 
                        'N/A', 
                        'N/A', 
                        1, 
                        'Column ' + @myVarNvarColumnPK + ' does not exist in table ' + @myVarNvarFullTableName
                    );
                END
                ELSE
                BEGIN
                    -- If table and column exist, try to get min/max values
                    SET @myVarNvarSQL = N'
                    BEGIN TRY
                        INSERT INTO [mrs].[PKRangeResults] (
                            [TableName], [TableCode], [ColumnPK], [ColumnCode], 
                            [TotalRows], [Comment], [LowestValue], [HighestValue], 
                            [IsError], [ErrorMessage]
                        )
                        SELECT 
                            ''' + REPLACE(@myVarNvarTableName, '''', '''''') + ''' AS [TableName], 
                            ''' + REPLACE(@myVarNvarTableCode, '''', '''''') + ''' AS [TableCode],
                            ''' + REPLACE(@myVarNvarColumnPK, '''', '''''') + ''' AS [ColumnPK],
                            ''' + REPLACE(@myVarNvarColumnCode, '''', '''''') + ''' AS [ColumnCode],
                            ' + CAST(@myVarIntRowCnt AS NVARCHAR(20)) + ' AS [TotalRows], 
                            ''' + REPLACE(@myVarNvarComment, '''', '''''') + ''' AS [Comment], 
                            CONVERT(NVARCHAR(255), MIN(' + QUOTENAME(@myVarNvarColumnPK) + ')) AS [LowestValue],
                            CONVERT(NVARCHAR(255), MAX(' + QUOTENAME(@myVarNvarColumnPK) + ')) AS [HighestValue],
                            0 AS [IsError],
                            NULL AS [ErrorMessage]
                        FROM ' + @myVarNvarFullTableName + '
                        WHERE ' + QUOTENAME(@myVarNvarColumnPK) + ' IS NOT NULL;
                    END TRY
                    BEGIN CATCH
                        INSERT INTO [mrs].[PKRangeResults] (
                            [TableName], [TableCode], [ColumnPK], [ColumnCode], 
                            [TotalRows], [Comment], [LowestValue], [HighestValue], 
                            [IsError], [ErrorMessage]
                        )
                        VALUES (
                            ''' + REPLACE(@myVarNvarTableName, '''', '''''') + ''', 
                            ''' + REPLACE(@myVarNvarTableCode, '''', '''''') + ''',
                            ''' + REPLACE(@myVarNvarColumnPK, '''', '''''') + ''', 
                            ''' + REPLACE(@myVarNvarColumnCode, '''', '''''') + ''',
                            ' + CAST(@myVarIntRowCnt AS NVARCHAR(20)) + ', 
                            ''' + REPLACE(@myVarNvarComment, '''', '''''') + ''', 
                            ''ERROR'', 
                            ''ERROR'', 
                            1, 
                            ERROR_MESSAGE()
                        );
                    END CATCH';
                    
                    BEGIN TRY
                        EXEC sp_executesql @myVarNvarSQL;
                    END TRY
                    BEGIN CATCH
                        -- If the dynamic SQL itself fails, record that error
                        INSERT INTO [mrs].[PKRangeResults] (
                            [TableName], [TableCode], [ColumnPK], [ColumnCode], 
                            [TotalRows], [Comment], [LowestValue], [HighestValue], 
                            [IsError], [ErrorMessage]
                        )
                        VALUES (
                            @myVarNvarTableName, 
                            @myVarNvarTableCode,
                            @myVarNvarColumnPK, 
                            @myVarNvarColumnCode,
                            @myVarIntRowCnt, 
                            @myVarNvarComment, 
                            'ERROR', 
                            'ERROR', 
                            1, 
                            'Execute SQL error: ' + ERROR_MESSAGE()
                        );
                    END CATCH
                END
            END
            
            FETCH NEXT FROM pk_cursor INTO @myVarNvarTableName, @myVarIntRowCnt, @myVarNvarComment, @myVarNvarColumnPK;
        END
        
        CLOSE pk_cursor;
        DEALLOCATE pk_cursor;
        
        COMMIT TRANSACTION;
        
        -- Print completion time if debug mode is on
        IF @myVarBitDebugMode = 1
        BEGIN
            DECLARE @myVarDtEndTime DATETIME = GETDATE();
            DECLARE @myVarIntDurationSecs INT = DATEDIFF(SECOND, @myVarDtStartTime, @myVarDtEndTime);
            
            PRINT 'Execution completed at: ' + CONVERT(VARCHAR(30), @myVarDtEndTime, 121);
            PRINT 'Total duration: ' + CAST(@myVarIntDurationSecs AS VARCHAR(10)) + ' seconds';
            PRINT 'Processed ' + CAST(@myVarIntTotalTables AS VARCHAR(10)) + ' tables';
            PRINT 'Results stored in table [mrs].[PKRangeResults]';
        END
    END TRY
    BEGIN CATCH
        -- Rollback transaction on error
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        -- Ensure cursor is deallocated
        IF CURSOR_STATUS('global', 'pk_cursor') >= 0
        BEGIN
            CLOSE pk_cursor;
            DEALLOCATE pk_cursor;
        END
            
        -- Print error details if debug mode is on
        IF @myVarBitDebugMode = 1
        BEGIN
            PRINT 'Error occurred at table: ' + ISNULL(@myVarNvarTableName, 'N/A');
            PRINT 'Error message: ' + ERROR_MESSAGE();
            PRINT 'Error number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
            PRINT 'Error severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10));
            PRINT 'Error state: ' + CAST(ERROR_STATE() AS VARCHAR(10));
        END
        
        -- Return error information
        SELECT 
            'ERROR' AS [ExecutionStatus],
            ERROR_MESSAGE() AS [ErrorMessage],
            ERROR_NUMBER() AS [ErrorNumber],
            ERROR_SEVERITY() AS [ErrorSeverity],
            ERROR_STATE() AS [ErrorState],
            @myVarNvarTableName AS [TableName],
            @myVarNvarColumnPK AS [ColumnName];
    END CATCH
END
GO

/*
=================================================================
Function: fun_ExtractCodeFromName
Description: This function extracts a code from a name by taking characters
             from right to left until finding the "_____" string.
Parameters:
    @myVarNvarName - The name to extract the code from
Returns:
    NVARCHAR(50) - The extracted code or NULL if not found
=================================================================
*/
CREATE OR ALTER FUNCTION [mrs].[fun_ExtractCodeFromName]
(
    @myVarNvarName NVARCHAR(128)
)
RETURNS NVARCHAR(50)
AS
BEGIN
    -- Declare variables
    DECLARE @myVarNvarCode NVARCHAR(50) = NULL;
    DECLARE @myVarIntPos INT;
    
    -- Find the position of "_____" (5 underscores)
    SET @myVarIntPos = CHARINDEX('_____', @myVarNvarName);
    
    -- If "_____" is found, extract the code from the part after it
    IF @myVarIntPos > 0
    BEGIN
        SET @myVarNvarCode = SUBSTRING(@myVarNvarName, @myVarIntPos + 5, LEN(@myVarNvarName) - @myVarIntPos - 5 + 1);
    END
    
    RETURN @myVarNvarCode;
END
GO

/*
Example usage:
-- Execute in debug mode 
	with extended properties for codes
	EXEC [mrs].[PKRangeAnalysis] @myVarBitDebugMode = 1, @myVarBitUseExtendedProps = 1;

	-- Execute in debug mode with name parsing for codes
	EXEC [mrs].[PKRangeAnalysis] @myVarBitDebugMode = 1, @myVarBitUseExtendedProps = 0;

-- Execute in silent mode 
	with extended properties for codes (default)
	EXEC [mrs].[PKRangeAnalysis] @myVarBitDebugMode = 0, @myVarBitUseExtendedProps = 1;

	-- Execute in silent mode with name parsing for codes
	EXEC [mrs].[PKRangeAnalysis] @myVarBitDebugMode = 0, @myVarBitUseExtendedProps = 0;

-- View results
SELECT * FROM [mrs].[PKRangeResults] ORDER BY [TableName];

-- View only errors
SELECT * FROM [mrs].[PKRangeResults] WHERE [IsError] = 1 ORDER BY [TableName];

-- View successful analyses
SELECT * FROM [mrs].[PKRangeResults] WHERE [IsError] = 0 ORDER BY [TableName];

-- Example resultset:
-- TableName | TableCode | ColumnPK | ColumnCode | TotalRows | Comment | LowestValue | HighestValue | IsError | ErrorMessage
-- ----------------------------------------------------------------------------------------------------------------------------------------
-- Account   | ACC       | AcctNo   | ACCTNO     | 1000      | PK found | 10000       | 99999        | 0       | NULL
-- Customer  | CUST      | CustID   | ID         | 5000      | PK found | 1           | 5000         | 0       | NULL
-- InventoryItem | INV   | ItemNo   | ITEMNO     | 2500      | PK found | IT001       | IT999        | 0       | NULL
-- MissingTable | UNKNOWN| PK       | UNKNOWN    | 0         | PK found | N/A         | N/A          | 1       | Table does not exist in schema mrs
*/