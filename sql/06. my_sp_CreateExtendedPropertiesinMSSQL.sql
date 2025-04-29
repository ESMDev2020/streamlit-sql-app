/***********************************************************
STORED PROCEDURE TO CREATE THE EXTENDED PROPERTIES IN MSSQL
************************************************************/



CREATE OR ALTER PROCEDURE dbo.UpdateExtendedPropertiesForZTables
    @Separator NVARCHAR(10) = '_____',
    @SchemaName NVARCHAR(128) = 'mrs',
    @TableNamePattern NVARCHAR(128) = 'z_%',
    @DebugMode BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME = GETDATE();
    DECLARE @TableCount INT = 0;
    DECLARE @ColumnCount INT = 0;
    DECLARE @TablesProcessed INT = 0;
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @CurrentTable NVARCHAR(256);
    DECLARE @CurrentSchema NVARCHAR(128);
    DECLARE @CurrentColumn NVARCHAR(128);
    DECLARE @DerivedCode NVARCHAR(128);
    DECLARE @Message NVARCHAR(MAX);
    
    -- Logging table to track progress
    IF OBJECT_ID('tempdb..#Log') IS NOT NULL
        DROP TABLE #Log;
        
    CREATE TABLE #Log (
        LogTime DATETIME DEFAULT GETDATE(),
        Message NVARCHAR(MAX),
        Severity NVARCHAR(20)
    );
    
    -- Function to add log messages
    DECLARE @AddLogMessage NVARCHAR(MAX) = N'
    INSERT INTO #Log (Message, Severity)
    VALUES (@MsgParam, @SeverityParam);
    
    IF @DebugParam = 1 OR @SeverityParam IN (''ERROR'', ''WARNING'')
        PRINT CONVERT(VARCHAR(23), GETDATE(), 121) + '' - '' + @SeverityParam + '' - '' + @MsgParam;';
    
    -- Get count of tables to process
    SELECT @TableCount = COUNT(*)
    FROM sys.tables t
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.name LIKE @TableNamePattern
    AND s.name = @SchemaName;
    
    -- Get count of columns to process (using a separate query)
    SELECT @ColumnCount = COUNT(*)
    FROM sys.columns c
    INNER JOIN sys.tables t ON c.object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.name LIKE @TableNamePattern
    AND s.name = @SchemaName;
    
    SET @Message = 'Starting extended properties update';
    EXEC sp_executesql @AddLogMessage, 
        N'@MsgParam NVARCHAR(MAX), @SeverityParam NVARCHAR(20), @DebugParam BIT',
        @Message, 'INFO', @DebugMode;
    
    SET @Message = 'Total tables to process: ' + CAST(@TableCount AS NVARCHAR(10));
    EXEC sp_executesql @AddLogMessage, 
        N'@MsgParam NVARCHAR(MAX), @SeverityParam NVARCHAR(20), @DebugParam BIT',
        @Message, 'INFO', @DebugMode;
    
    SET @Message = 'Total columns to process: ' + CAST(@ColumnCount AS NVARCHAR(10));
    EXEC sp_executesql @AddLogMessage, 
        N'@MsgParam NVARCHAR(MAX), @SeverityParam NVARCHAR(20), @DebugParam BIT',
        @Message, 'INFO', @DebugMode;
    
    -- First, delete all existing extended properties for target tables
    BEGIN TRY
        -- Delete table level properties
        SET @SQL = N'
        DECLARE @sql NVARCHAR(MAX) = '''';
        SELECT @sql = @sql + 
            ''EXEC sp_dropextendedproperty @name = '''''' + ep.name + '''''', '' +
            ''@level0type = N''''SCHEMA'''', @level0name = '''''' + SCHEMA_NAME(t.schema_id) + '''''', '' +
            ''@level1type = N''''TABLE'''', @level1name = '''''' + t.name + ''''''; ''
        FROM sys.extended_properties ep
        JOIN sys.tables t ON ep.major_id = t.object_id
        WHERE t.name LIKE @TablePattern
        AND ep.minor_id = 0;
        
        EXEC sp_executesql @sql;';
        
        EXEC sp_executesql @SQL, N'@TablePattern NVARCHAR(128)', @TableNamePattern;
        
        SET @Message = 'Successfully deleted table level properties';
        EXEC sp_executesql @AddLogMessage, 
            N'@MsgParam NVARCHAR(MAX), @SeverityParam NVARCHAR(20), @DebugParam BIT',
            @Message, 'INFO', @DebugMode;
        
        -- Delete column level properties
        SET @SQL = N'
        DECLARE @sql NVARCHAR(MAX) = '''';
        SELECT @sql = @sql + 
            ''EXEC sp_dropextendedproperty @name = '''''' + ep.name + '''''', '' +
            ''@level0type = N''''SCHEMA'''', @level0name = '''''' + SCHEMA_NAME(t.schema_id) + '''''', '' +
            ''@level1type = N''''TABLE'''', @level1name = '''''' + t.name + '''''', '' +
            ''@level2type = N''''COLUMN'''', @level2name = '''''' + c.name + ''''''; ''
        FROM sys.extended_properties ep
        JOIN sys.tables t ON ep.major_id = t.object_id
        JOIN sys.columns c ON t.object_id = c.object_id AND ep.minor_id = c.column_id
        WHERE t.name LIKE @TablePattern;
        
        EXEC sp_executesql @sql;';
        
        EXEC sp_executesql @SQL, N'@TablePattern NVARCHAR(128)', @TableNamePattern;
        
        SET @Message = 'Successfully deleted column level properties';
        EXEC sp_executesql @AddLogMessage, 
            N'@MsgParam NVARCHAR(MAX), @SeverityParam NVARCHAR(20), @DebugParam BIT',
            @Message, 'INFO', @DebugMode;
    END TRY
    BEGIN CATCH
        SET @Message = 'Error deleting extended properties: ' + ERROR_MESSAGE();
        EXEC sp_executesql @AddLogMessage, 
            N'@MsgParam NVARCHAR(MAX), @SeverityParam NVARCHAR(20), @DebugParam BIT',
            @Message, 'ERROR', @DebugMode;
        RETURN;
    END CATCH
    
    -- Process each table
    DECLARE TableCursor CURSOR FOR
    SELECT s.name, t.name
    FROM sys.tables t
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.name LIKE @TableNamePattern
    AND s.name = @SchemaName
    ORDER BY s.name, t.name;
    
    OPEN TableCursor;
    FETCH NEXT FROM TableCursor INTO @CurrentSchema, @CurrentTable;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @TablesProcessed = @TablesProcessed + 1;
        
        SET @Message = '(Table ' + CAST(@TablesProcessed AS NVARCHAR(10)) + ' of ' + CAST(@TableCount AS NVARCHAR(10)) + 
            ') - Processing table: [' + @CurrentSchema + '].[' + @CurrentTable + ']';
        EXEC sp_executesql @AddLogMessage, 
            N'@MsgParam NVARCHAR(MAX), @SeverityParam NVARCHAR(20), @DebugParam BIT',
            @Message, 'INFO', @DebugMode;
        
        BEGIN TRY
            -- Get derived code for table
            IF CHARINDEX(@Separator, @CurrentTable) > 0
            BEGIN
                SET @DerivedCode = PARSENAME(REPLACE(@CurrentTable, @Separator, '.'), 1);
                
                -- Add table extended property
                EXEC sp_addextendedproperty 
                    @name = @DerivedCode,
                    @value = @CurrentTable,
                    @level0type = N'SCHEMA',
                    @level0name = @CurrentSchema,
                    @level1type = N'TABLE',
                    @level1name = @CurrentTable;
                
                SET @Message = 'Added table property: ' + @DerivedCode;
                EXEC sp_executesql @AddLogMessage, 
                    N'@MsgParam NVARCHAR(MAX), @SeverityParam NVARCHAR(20), @DebugParam BIT',
                    @Message, 'INFO', @DebugMode;
            END
            ELSE
            BEGIN
                SET @Message = 'No separator found in table name: ' + @CurrentTable;
                EXEC sp_executesql @AddLogMessage, 
                    N'@MsgParam NVARCHAR(MAX), @SeverityParam NVARCHAR(20), @DebugParam BIT',
                    @Message, 'WARNING', @DebugMode;
            END
            
            -- Process columns
            DECLARE ColumnCursor CURSOR FOR
            SELECT c.name
            FROM sys.columns c
            WHERE c.object_id = OBJECT_ID(QUOTENAME(@CurrentSchema) + '.' + QUOTENAME(@CurrentTable))
            ORDER BY c.column_id;
            
            OPEN ColumnCursor;
            FETCH NEXT FROM ColumnCursor INTO @CurrentColumn;
            
            WHILE @@FETCH_STATUS = 0
            BEGIN
                -- Get derived code for column
                IF CHARINDEX(@Separator, @CurrentColumn) > 0
                BEGIN
                    SET @DerivedCode = PARSENAME(REPLACE(@CurrentColumn, @Separator, '.'), 1);
                    
                    -- Add column extended property
                    EXEC sp_addextendedproperty 
                        @name = @DerivedCode,
                        @value = @CurrentColumn,
                        @level0type = N'SCHEMA',
                        @level0name = @CurrentSchema,
                        @level1type = N'TABLE',
                        @level1name = @CurrentTable,
                        @level2type = N'COLUMN',
                        @level2name = @CurrentColumn;
                END
                ELSE
                BEGIN
                    SET @Message = 'No separator found in column name: ' + @CurrentColumn;
                    EXEC sp_executesql @AddLogMessage, 
                        N'@MsgParam NVARCHAR(MAX), @SeverityParam NVARCHAR(20), @DebugParam BIT',
                        @Message, 'DEBUG', @DebugMode;
                END
                
                FETCH NEXT FROM ColumnCursor INTO @CurrentColumn;
            END
            
            CLOSE ColumnCursor;
            DEALLOCATE ColumnCursor;
            
            SET @Message = 'Completed table [' + @CurrentSchema + '].[' + @CurrentTable + ']';
            EXEC sp_executesql @AddLogMessage, 
                N'@MsgParam NVARCHAR(MAX), @SeverityParam NVARCHAR(20), @DebugParam BIT',
                @Message, 'INFO', @DebugMode;
        END TRY
        BEGIN CATCH
            SET @Message = 'Error processing table [' + @CurrentSchema + '].[' + @CurrentTable + ']: ' + ERROR_MESSAGE();
            EXEC sp_executesql @AddLogMessage, 
                N'@MsgParam NVARCHAR(MAX), @SeverityParam NVARCHAR(20), @DebugParam BIT',
                @Message, 'ERROR', @DebugMode;
        END CATCH
        
        FETCH NEXT FROM TableCursor INTO @CurrentSchema, @CurrentTable;
    END
    
    CLOSE TableCursor;
    DEALLOCATE TableCursor;
    
    -- Completion message
    DECLARE @DurationSeconds DECIMAL(10,3) = DATEDIFF(MILLISECOND, @StartTime, GETDATE()) / 1000.0;
    
    SET @Message = 'Processing completed';
    EXEC sp_executesql @AddLogMessage, 
        N'@MsgParam NVARCHAR(MAX), @SeverityParam NVARCHAR(20), @DebugParam BIT',
        @Message, 'INFO', @DebugMode;
    
    SET @Message = 'Total Duration: ' + CAST(@DurationSeconds AS NVARCHAR(20)) + ' seconds';
    EXEC sp_executesql @AddLogMessage, 
        N'@MsgParam NVARCHAR(MAX), @SeverityParam NVARCHAR(20), @DebugParam BIT',
        @Message, 'INFO', @DebugMode;
    
    SET @Message = 'Processed ' + CAST(@TablesProcessed AS NVARCHAR(10)) + ' tables';
    EXEC sp_executesql @AddLogMessage, 
        N'@MsgParam NVARCHAR(MAX), @SeverityParam NVARCHAR(20), @DebugParam BIT',
        @Message, 'INFO', @DebugMode;
    
    -- Return log results
    IF @DebugMode = 1
        SELECT * FROM #Log ORDER BY LogTime;
    
    DROP TABLE #Log;
END