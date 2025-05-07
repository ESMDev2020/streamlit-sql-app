USE SigmaTB;
GO

/*
=================================================================
Procedure: mrs.PKIdentificationAndAnalysis
Description: This stored procedure combines primary key identification and 
             range analysis for tables with 'z_' prefix.
             It first identifies potential primary keys by comparing distinct values 
             with row counts, then analyzes the ranges of identified primary keys.
             Table and column codes are extracted either from extended properties
             or by parsing names.

Parameters: 
    @myVarBitDebugMode - 1 for debug mode (prints progress), 0 for silent execution
    @myVarBitUseExtendedProps - 1 to use extended properties for codes, 0 to parse from names
    @myVarIntIdentificationMode - 1 to identify PKs and analyze ranges, 2 to only analyze ranges
    @myVarBitExecuteFromZero - 1 to start fresh (drop and recreate tables), 0 to resume/append

Output:
    Creates/Updates tables: 
    - mrs.PKCheckResults - Table containing identified primary keys
    - mrs.PKRangeResults - Table containing range analysis results

Author: Combined procedures
Version: 3.0
Date: May 04, 2025
=================================================================
*/

CREATE OR ALTER PROCEDURE [mrs].[PKIdentificationAndAnalysis]
    @myVarBitDebugMode BIT = 0,
    @myVarBitUseExtendedProps BIT = 1,
    @myVarIntIdentificationMode INT = 1,
    @myVarBitExecuteFromZero BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    -- Declare all variables at the beginning
    DECLARE @myVarDtStartTime DATETIME = GETDATE();
    DECLARE @myVarDtEndTime DATETIME;
    DECLARE @myVarIntDurationSecs INT;
    DECLARE @myVarNvarTableName NVARCHAR(128);
    DECLARE @myVarNvarSchemaName NVARCHAR(128) = 'mrs'; -- Default schema
    DECLARE @myVarNvarFullTableName NVARCHAR(258); -- Schema.Table
    DECLARE @myVarNvarColumnPK NVARCHAR(128);
    DECLARE @myVarNvarCurrentColumn NVARCHAR(128);
    DECLARE @myVarIntRowCnt INT;
    DECLARE @myVarIntDistinctCount INT;
    DECLARE @myVarNvarComment NVARCHAR(255);
    DECLARE @myVarNvarSQL NVARCHAR(MAX);
    DECLARE @myVarIntCounter INT = 0;
    DECLARE @myVarIntTotalTables INT;
    DECLARE @myVarBitTableExists BIT;
    DECLARE @myVarNvarTableCode NVARCHAR(50);
    DECLARE @myVarNvarColumnCode NVARCHAR(50);
    DECLARE @myVarIntObjectId INT;
    DECLARE @myVarIntColumnId INT;
    DECLARE @myVarBitSkipColumn BIT;
    DECLARE @myVarBitHasPK BIT;
    DECLARE @myVarDtTableStart DATETIME;
    DECLARE @myVarDtColumnStart DATETIME;
    DECLARE @myVarIntProcessedTables INT = 0;
    DECLARE @myVarIntProcessedColumns INT = 0;
    
    -- Print start time if debug mode is on
    IF @myVarBitDebugMode = 1
    BEGIN
        PRINT '=================================================================';
        PRINT 'Starting execution at: ' + CONVERT(VARCHAR(30), @myVarDtStartTime, 121);
        PRINT 'Identification Mode: ' + CASE 
                                         WHEN @myVarIntIdentificationMode = 1 THEN 'Full (Identify PKs and Analyze Ranges)'
                                         WHEN @myVarIntIdentificationMode = 2 THEN 'Range Analysis Only' 
                                         ELSE 'Unknown'
                                       END;
        PRINT 'Using extended properties for codes: ' + CASE WHEN @myVarBitUseExtendedProps = 1 THEN 'Yes' ELSE 'No' END;
        PRINT 'Execute from zero: ' + CASE WHEN @myVarBitExecuteFromZero = 1 THEN 'Yes' ELSE 'No' END;
        PRINT '=================================================================';
    END
    
    BEGIN TRY
        /*
        ======================================================================
        SECTION 1: Primary Key Identification
        This section identifies potential primary keys by checking if the count
        of distinct values equals the row count for each column in each table.
        ======================================================================
        */
        IF @myVarIntIdentificationMode = 1
        BEGIN
            -- Create or reset the PKCheckResults table if executing from zero
            IF @myVarBitExecuteFromZero = 1
            BEGIN
                IF OBJECT_ID('[mrs].[PKCheckResults]') IS NOT NULL
                BEGIN
                    IF @myVarBitDebugMode = 1
                    BEGIN
                        PRINT 'Dropping existing [mrs].[PKCheckResults] table...';
                    END
                    
                    DROP TABLE [mrs].[PKCheckResults];
                END
                
                IF @myVarBitDebugMode = 1
                BEGIN
                    PRINT 'Creating [mrs].[PKCheckResults] table...';
                END
                
                CREATE TABLE [mrs].[PKCheckResults] (
                    [TableName] NVARCHAR(128),
                    [RowCount] INT,
                    [Comment] NVARCHAR(255),
                    [ColumnPK] NVARCHAR(128)
                );
            END
            ELSE IF OBJECT_ID('[mrs].[PKCheckResults]') IS NULL
            BEGIN
                -- Create the table if it doesn't exist and we're not starting from zero
                IF @myVarBitDebugMode = 1
                BEGIN
                    PRINT '[mrs].[PKCheckResults] table does not exist. Creating...';
                END
                
                CREATE TABLE [mrs].[PKCheckResults] (
                    [TableName] NVARCHAR(128),
                    [RowCount] INT,
                    [Comment] NVARCHAR(255),
                    [ColumnPK] NVARCHAR(128)
                );
            END
            
            -- Get tables to process - only those starting with 'z_'
            IF @myVarBitDebugMode = 1
            BEGIN
                PRINT '=================================================================';
                PRINT 'PHASE 1: Primary Key Identification';
                PRINT '=================================================================';
            END
            
            -- Deallocate cursor if it already exists
            IF CURSOR_STATUS('global', 'pk_identification_cursor') >= 0
            BEGIN
                CLOSE pk_identification_cursor;
                DEALLOCATE pk_identification_cursor;
            END
            
            -- Create cursor for tables with 'z_' prefix
            DECLARE pk_identification_cursor CURSOR LOCAL STATIC FOR
            SELECT t.TABLE_NAME
            FROM INFORMATION_SCHEMA.TABLES t
            LEFT JOIN [mrs].[PKCheckResults] r
                ON t.TABLE_NAME = r.TableName
            WHERE t.TABLE_SCHEMA = @myVarNvarSchemaName
                AND t.TABLE_TYPE = 'BASE TABLE'
                AND t.TABLE_NAME LIKE 'z\_%' ESCAPE '\'
                AND (r.TableName IS NULL OR @myVarBitExecuteFromZero = 1);
                
            OPEN pk_identification_cursor;
            FETCH NEXT FROM pk_identification_cursor INTO @myVarNvarTableName;
            
            -- Get total table count for progress reporting
            SELECT @myVarIntTotalTables = COUNT(*) 
            FROM INFORMATION_SCHEMA.TABLES
            WHERE TABLE_SCHEMA = @myVarNvarSchemaName
                AND TABLE_TYPE = 'BASE TABLE'
                AND TABLE_NAME LIKE 'z\_%' ESCAPE '\';
                
            IF @myVarBitDebugMode = 1
            BEGIN
                PRINT 'Found ' + CAST(@myVarIntTotalTables AS VARCHAR(10)) + ' tables with z_ prefix to analyze';
            END
            
            -- Main processing loop for PK identification
            WHILE @@FETCH_STATUS = 0
            BEGIN
                BEGIN TRY
                    BEGIN TRANSACTION;
                    
                    -- Get table row count
                    SET @myVarDtTableStart = GETDATE();
                    SET @myVarNvarFullTableName = QUOTENAME(@myVarNvarSchemaName) + '.' + QUOTENAME(@myVarNvarTableName);
                    SET @myVarNvarSQL = N'SELECT @rc = COUNT(*) FROM ' + @myVarNvarFullTableName;
                    
                    IF @myVarBitDebugMode = 1
                    BEGIN
                        PRINT '--- Counting rows in table: ' + @myVarNvarTableName + ' ---';
                        PRINT 'SQL Query: ' + @myVarNvarSQL;
                    END
                    
                    EXEC sp_executesql @myVarNvarSQL, 
                        N'@rc INT OUTPUT', 
                        @myVarIntRowCnt OUTPUT;
                        
                    -- Debug: Table progress
                    SET @myVarIntProcessedTables += 1;
                    IF @myVarBitDebugMode = 1
                    BEGIN
                        PRINT 'Processing table ' + CAST(@myVarIntProcessedTables AS VARCHAR(10)) + ' of ' + 
                            CAST(@myVarIntTotalTables AS VARCHAR(10)) + ': ' + @myVarNvarTableName + 
                            ' (' + CAST(@myVarIntRowCnt AS VARCHAR(10)) + ' rows)';
                        PRINT 'Time: ' + CAST(DATEDIFF(MILLISECOND, @myVarDtTableStart, GETDATE()) AS VARCHAR(10)) + 'ms';
                    END
                    
                    -- Deallocate cursor if it already exists
                    IF CURSOR_STATUS('global', 'column_cursor') >= 0
                    BEGIN
                        CLOSE column_cursor;
                        DEALLOCATE column_cursor;
                    END
                    
                    -- Column analysis
                    DECLARE column_cursor CURSOR LOCAL FAST_FORWARD FOR
                    SELECT COLUMN_NAME
                    FROM INFORMATION_SCHEMA.COLUMNS
                    WHERE TABLE_SCHEMA = @myVarNvarSchemaName
                        AND TABLE_NAME = @myVarNvarTableName;
                        
                    OPEN column_cursor;
                    FETCH NEXT FROM column_cursor INTO @myVarNvarCurrentColumn;
                    
                    SET @myVarBitHasPK = 0;
                    
                    -- Process columns until we find a PK or run out of columns
                    WHILE @@FETCH_STATUS = 0 AND @myVarBitHasPK = 0
                    BEGIN
                        -- Column exclusion check
                        SET @myVarBitSkipColumn = CASE
                            WHEN RIGHT(@myVarNvarCurrentColumn, 2) IN ('DD','MM','YY','CC') THEN 1
                            WHEN RIGHT(@myVarNvarCurrentColumn, 3) IN ('QTY','UOM') THEN 1
                            ELSE 0
                        END;
                        
                        IF @myVarBitSkipColumn = 0
                        BEGIN
                            -- Distinct count check
                            SET @myVarDtColumnStart = GETDATE();
                            SET @myVarNvarSQL = N'SELECT @dc = COUNT(DISTINCT ' 
                                + QUOTENAME(@myVarNvarCurrentColumn) + ') FROM ' 
                                + @myVarNvarFullTableName;
                                
                            IF @myVarBitDebugMode = 1
                            BEGIN
                                PRINT '--- Checking distinct values for column: ' + @myVarNvarCurrentColumn + ' ---';
                                PRINT 'SQL Query: ' + @myVarNvarSQL;
                            END
                            
                            EXEC sp_executesql @myVarNvarSQL, 
                                N'@dc INT OUTPUT', 
                                @myVarIntDistinctCount OUTPUT;
                                
                            -- Debug: Column analysis
                            IF @myVarBitDebugMode = 1
                            BEGIN
                                PRINT 'Analyzed column: ' + @myVarNvarCurrentColumn + 
                                    ' | Distinct: ' + CAST(@myVarIntDistinctCount AS VARCHAR(10)) + 
                                    ' | Time: ' + 
                                    CAST(DATEDIFF(MILLISECOND, @myVarDtColumnStart, GETDATE()) AS VARCHAR(10)) + 'ms';
                            END
                            
                            -- PK check - distinct count equals row count
                            IF @myVarIntDistinctCount = @myVarIntRowCnt AND @myVarIntRowCnt > 0
                            BEGIN
                                IF @myVarBitDebugMode = 1
                                BEGIN
                                    PRINT 'PK found! Column: ' + @myVarNvarCurrentColumn;
                                END
                                
                                INSERT INTO [mrs].[PKCheckResults] (
                                    [TableName],
                                    [RowCount],
                                    [Comment],
                                    [ColumnPK]
                                ) VALUES (
                                    @myVarNvarTableName,
                                    @myVarIntRowCnt,
                                    'PK found',
                                    @myVarNvarCurrentColumn
                                );
                                
                                SET @myVarBitHasPK = 1;
                            END
                        END
                        
                        FETCH NEXT FROM column_cursor INTO @myVarNvarCurrentColumn;
                    END
                    
                    CLOSE column_cursor;
                    DEALLOCATE column_cursor;
                    
                    -- Handle no PK found
                    IF @myVarBitHasPK = 0
                    BEGIN
                        IF @myVarBitDebugMode = 1
                        BEGIN
                            PRINT 'No PK found for table: ' + @myVarNvarTableName;
                        END
                        
                        INSERT INTO [mrs].[PKCheckResults] (
                            [TableName],
                            [RowCount],
                            [Comment],
                            [ColumnPK]
                        ) VALUES (
                            @myVarNvarTableName,
                            @myVarIntRowCnt,
                            'no PK found',
                            NULL
                        );
                    END
                    
                    COMMIT TRANSACTION;
                    FETCH NEXT FROM pk_identification_cursor INTO @myVarNvarTableName;
                END TRY
                BEGIN CATCH
                    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
                    
                    IF @myVarBitDebugMode = 1
                    BEGIN
                        PRINT 'Error processing table ' + @myVarNvarTableName + ': ' + ERROR_MESSAGE();
                    END
                    
                    -- Record the error in the results
                    INSERT INTO [mrs].[PKCheckResults] (
                        [TableName],
                        [RowCount],
                        [Comment],
                        [ColumnPK]
                    ) VALUES (
                        @myVarNvarTableName,
                        0,
                        'Error: ' + ERROR_MESSAGE(),
                        NULL
                    );
                    
                    -- Continue with next table
                    FETCH NEXT FROM pk_identification_cursor INTO @myVarNvarTableName;
                END CATCH
            END
            
            CLOSE pk_identification_cursor;
            DEALLOCATE pk_identification_cursor;
            
            IF @myVarBitDebugMode = 1
            BEGIN
                SET @myVarDtEndTime = GETDATE();
                SET @myVarIntDurationSecs = DATEDIFF(SECOND, @myVarDtStartTime, @myVarDtEndTime);
                
                PRINT '=================================================================';
                PRINT 'PHASE 1 Complete - Primary Key Identification';
                PRINT 'Duration: ' + CAST(@myVarIntDurationSecs AS VARCHAR(10)) + ' seconds';
                PRINT 'Processed ' + CAST(@myVarIntProcessedTables AS VARCHAR(10)) + ' tables';
                PRINT '=================================================================';
            END
        END
        
        /*
        ======================================================================
        SECTION 2: Primary Key Range Analysis
        This section analyzes the range (min/max values) of the identified 
        primary keys and extracts table/column codes.
        ======================================================================
        */
        
        -- Create/recreate PKRangeResults table
        IF @myVarBitExecuteFromZero = 1 OR OBJECT_ID('[mrs].[PKRangeResults]') IS NULL
        BEGIN
            IF OBJECT_ID('[mrs].[PKRangeResults]') IS NOT NULL
            BEGIN
                IF @myVarBitDebugMode = 1
                BEGIN
                    PRINT 'Dropping existing [mrs].[PKRangeResults] table...';
                END
                
                DROP TABLE [mrs].[PKRangeResults];
            END
            
            IF @myVarBitDebugMode = 1
            BEGIN
                PRINT 'Creating [mrs].[PKRangeResults] table...';
            END
            
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
        END
        
        IF @myVarBitDebugMode = 1
        BEGIN
            SET @myVarDtStartTime = GETDATE(); -- Reset start time for phase 2
            PRINT '=================================================================';
            PRINT 'PHASE 2: Primary Key Range Analysis';
            PRINT '=================================================================';
        END
        
        -- Get total count of tables for progress reporting
        SELECT @myVarIntTotalTables = COUNT(*) 
        FROM [mrs].[PKCheckResults]
        WHERE [Comment] = 'PK found' AND [ColumnPK] IS NOT NULL
        AND [TableName] LIKE 'z\_%' ESCAPE '\';
        
        IF @myVarBitDebugMode = 1
        BEGIN
            PRINT 'Found ' + CAST(@myVarIntTotalTables AS VARCHAR(10)) + ' tables with PKs to analyze';
        END
        
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
            AND [TableName] LIKE 'z\_%' ESCAPE '\';
            
            OPEN pk_cursor;
            FETCH NEXT FROM pk_cursor INTO @myVarNvarTableName, @myVarIntRowCnt, @myVarNvarComment, @myVarNvarColumnPK;
            
            SET @myVarIntCounter = 0; -- Reset counter for phase 2
            
            WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @myVarIntCounter = @myVarIntCounter + 1;
                
                -- Print progress if debug mode is on
                IF @myVarBitDebugMode = 1 
                BEGIN
                    PRINT '--- Processing table ' + CAST(@myVarIntCounter AS VARCHAR(10)) + ' of ' + 
                          CAST(@myVarIntTotalTables AS VARCHAR(10)) + ': ' + @myVarNvarTableName + ' ---';
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
                    PRINT 'Checking if table exists: ' + @myVarNvarSchemaName + '.' + @myVarNvarTableName;
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
                        PRINT 'Checking if column exists: ' + @myVarNvarColumnPK;
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
                            PRINT 'Getting TableCode for ' + @myVarNvarTableName;
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
                                PRINT 'Getting ColumnCode for ' + @myVarNvarColumnPK;
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
                        
                        IF @myVarBitDebugMode = 1
                        BEGIN
                            PRINT 'Parsed TableCode from name: ' + ISNULL(@myVarNvarTableCode, 'NULL');
                        END
                        
                        -- If column exists, parse ColumnCode from ColumnName
                        IF @myVarBitColumnExists = 1
                        BEGIN
                            SET @myVarNvarColumnCode = [mrs].[fun_ExtractCodeFromName](@myVarNvarColumnPK);
                            
                            IF @myVarBitDebugMode = 1
                            BEGIN
                                PRINT 'Parsed ColumnCode from name: ' + ISNULL(@myVarNvarColumnCode, 'NULL');
                            END
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
                        
                        IF @myVarBitDebugMode = 1
                        BEGIN
                            PRINT 'Getting MIN/MAX values for column: ' + @myVarNvarColumnPK;
                            PRINT 'SQL Query: ' + @myVarNvarSQL;
                        END
                        
                        BEGIN TRY
                            EXEC sp_executesql @myVarNvarSQL;
                            
                            IF @myVarBitDebugMode = 1
                            BEGIN
                                PRINT 'Successfully analyzed range for ' + @myVarNvarTableName + '.' + @myVarNvarColumnPK;
                            END
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
                            
                            IF @myVarBitDebugMode = 1
                            BEGIN
                                PRINT 'ERROR: ' + ERROR_MESSAGE();
                            END
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
                SET @myVarDtEndTime = GETDATE();
                SET @myVarIntDurationSecs = DATEDIFF(SECOND, @myVarDtStartTime, @myVarDtEndTime);
                
                PRINT '=================================================================';
                PRINT 'PHASE 2 Complete - Primary Key Range Analysis';
                PRINT 'Duration: ' + CAST(@myVarIntDurationSecs AS VARCHAR(10)) + ' seconds';
                PRINT 'Processed ' + CAST(@myVarIntCounter AS VARCHAR(10)) + ' tables';
                PRINT 'Results stored in table [mrs].[PKRangeResults]';
                PRINT '=================================================================';
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
    END TRY
    BEGIN CATCH
        -- Handle outer error
        IF @myVarBitDebugMode = 1
        BEGIN
            PRINT 'Critical Error:';
            PRINT 'Error message: ' + ERROR_MESSAGE();
            PRINT 'Error number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
            PRINT 'Error severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10));
            PRINT 'Error state: ' + CAST(ERROR_STATE() AS VARCHAR(10));
        END
        
        -- Return error information
        SELECT 
            'CRITICAL ERROR' AS [ExecutionStatus],
            ERROR_MESSAGE() AS [ErrorMessage],
            ERROR_NUMBER() AS [ErrorNumber],
            ERROR_SEVERITY() AS [ErrorSeverity],
            ERROR_STATE() AS [ErrorState];
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
-- Mode 1: Identify PKs and analyze ranges (starting fresh)
EXEC [mrs].[PKIdentificationAndAnalysis] 
    @myVarBitDebugMode = 1, 
    @myVarBitUseExtendedProps = 0, 
    @myVarIntIdentificationMode = 1, 
    @myVarBitExecuteFromZero = 1;

-- Mode 1: Identify PKs and analyze ranges (resume/append)
EXEC [mrs].[PKIdentificationAndAnalysis] 
    @myVarBitDebugMode = 1, 
    @myVarBitUseExtendedProps = 0, 
    @myVarIntIdentificationMode = 1, 
    @myVarBitExecuteFromZero = 0;

-- Mode 2: Only analyze ranges (using existing PKCheckResults)
EXEC [mrs].[PKIdentificationAndAnalysis] 
    @myVarBitDebugMode = 1, 
    @myVarBitUseExtendedProps = 0, 
    @myVarIntIdentificationMode = 2, 
    @myVarBitExecuteFromZero = 1;

-- Silent execution with extended properties
EXEC [mrs].[PKIdentificationAndAnalysis] 
    @myVarBitDebugMode = 0, 
    @myVarBitUseExtendedProps = 1, 
    @myVarIntIdentificationMode = 1, 
    @myVarBitExecuteFromZero = 1;

-- View all PK identification results
SELECT * FROM [mrs].[PKCheckResults] ORDER BY [TableName];

-- View all range analysis results
SELECT * FROM [mrs].[PKRangeResults] ORDER BY [TableName];

-- View only successful range analyses
SELECT * FROM [mrs].[PKRangeResults] WHERE [IsError] = 0 ORDER BY [TableName];

-- View only errors
SELECT * FROM [mrs].[PKRangeResults] WHERE [IsError] = 1 ORDER BY [TableName];

-- Example resultset from PKCheckResults:
-- TableName                  | RowCount | Comment   | ColumnPK
-- ----------------------------------------------------------
-- z_Customer_Master_File     | 5000     | PK found  | CUSTOMER_NUMBER_____CCUST
-- z_General_Ledger_File      | 10000    | PK found  | GL_ACCOUNT_____ACCT
-- z_Product_Master_File      | 2500     | no PK found | NULL

-- Example resultset from PKRangeResults:
-- TableName | TableCode | ColumnPK | ColumnCode | TotalRows | Comment | LowestValue | HighestValue | IsError | ErrorMessage
-- ----------------------------------------------------------------------------------------------------------------------------------------
-- z_Customer_Master_File | ARCUST | CUSTOMER_NUMBER_____CCUST | CCUST | 5000 | PK found | 10000 | 99999 | 0 | NULL
-- z_General_Ledger_File  | GLTRANS | GL_ACCOUNT_____ACCT | ACCT | 10000 | PK found | 100-1000 | 999-9999 | 0 | NULL
*/