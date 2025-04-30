USE SigmaTB; -- Ensure this is the correct database context
GO

/***********************************************************
STORED PROCEDURE TO CREATE THE EXTENDED PROPERTIES IN MSSQL
works

************************************************************/
CREATE OR ALTER PROCEDURE mrs.UpdateExtendedPropertiesForZTables
    @Separator NVARCHAR(10) = '_____',       -- Separator used in table/column names
    @SchemaName NVARCHAR(128) = 'mrs',       -- Target schema
    @TableNamePattern NVARCHAR(128) = 'z_%', -- Pattern for tables to process (e.g., 'z_%')
    @DebugMode BIT = 0                       -- Set to 1 to print debug messages and return log table
AS
BEGIN
    SET NOCOUNT ON;

    -- Variables for timing and counts
    DECLARE @StartTime DATETIME = GETDATE();
    DECLARE @TableCount INT = 0;
    DECLARE @ColumnCount INT = 0;
    DECLARE @TablesProcessed INT = 0;
    DECLARE @PropertiesAdded INT = 0;
    DECLARE @PropertiesFailed INT = 0;

    -- Variables for processing
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @CurrentTable NVARCHAR(256);
    DECLARE @CurrentSchema NVARCHAR(128);
    DECLARE @CurrentColumn NVARCHAR(128);
    DECLARE @AS400Name NVARCHAR(128); -- Name for the extended property (part after separator)
    DECLARE @MSSQLName NVARCHAR(256); -- Value for the extended property (part before separator for columns, full name for tables)
    DECLARE @ObjectNameForParse NVARCHAR(514); -- Temp variable for PARSENAME logic
    DECLARE @Message NVARCHAR(MAX);
    DECLARE @Severity NVARCHAR(20);
    DECLARE @SeparatorPosition INT; -- To find separator index

    -- Temporary Logging table
    IF OBJECT_ID('tempdb..#Log') IS NOT NULL
        DROP TABLE #Log;

    CREATE TABLE #Log (
        LogID INT IDENTITY(1,1) PRIMARY KEY,
        LogTime DATETIME DEFAULT GETDATE(),
        SchemaName NVARCHAR(128) NULL,
        TableName NVARCHAR(256) NULL,
        ColumnName NVARCHAR(128) NULL,
        PropertyName NVARCHAR(128) NULL,
        PropertyValue NVARCHAR(MAX) NULL,
        Severity NVARCHAR(20) NOT NULL,
        Message NVARCHAR(MAX) NOT NULL
    );

    -- Internal procedure/helper SQL for logging
    DECLARE @AddLogMessageProc NVARCHAR(MAX) = N'
    BEGIN TRY
        INSERT INTO #Log (SchemaName, TableName, ColumnName, PropertyName, PropertyValue, Severity, Message)
        VALUES (@SchemaParam, @TableParam, @ColumnParam, @PropNameParam, @PropValueParam, @SeverityParam, @MsgParam);

        -- Optionally print if Debug mode is on or if it''s a significant message
        IF @DebugParam = 1 OR @SeverityParam IN (''ERROR'', ''WARNING'', ''INFO'')
        BEGIN
            DECLARE @PrintMsg NVARCHAR(MAX) = CONVERT(VARCHAR(23), GETDATE(), 121) + '' - '' + @SeverityParam;
            IF @SchemaParam IS NOT NULL SET @PrintMsg += '' ['' + @SchemaParam + '']'';
            IF @TableParam IS NOT NULL SET @PrintMsg += ''.['' + @TableParam + '']'';
            IF @ColumnParam IS NOT NULL SET @PrintMsg += ''.['' + @ColumnParam + '']'';
            SET @PrintMsg += '' - '' + @MsgParam;
            PRINT @PrintMsg;
        END
    END TRY
    BEGIN CATCH
        PRINT ''CRITICAL LOGGING ERROR: '' + ERROR_MESSAGE();
    END CATCH';

    -- Parameter definition for the logging procedure SQL
    DECLARE @LogParams NVARCHAR(MAX) = N'@SchemaParam NVARCHAR(128), @TableParam NVARCHAR(256), @ColumnParam NVARCHAR(128), @PropNameParam NVARCHAR(128), @PropValueParam NVARCHAR(MAX), @SeverityParam NVARCHAR(20), @MsgParam NVARCHAR(MAX), @DebugParam BIT';


    -- Initial Log Message
    SET @Message = 'Starting extended properties update process.';
    EXEC sp_executesql @AddLogMessageProc, @LogParams,
        @SchemaParam = NULL, @TableParam = NULL, @ColumnParam = NULL, @PropNameParam = NULL, @PropValueParam = NULL, @SeverityParam = 'INFO', @MsgParam = @Message, @DebugParam = @DebugMode;

    -- Get counts
    SELECT @TableCount = COUNT(DISTINCT t.object_id)
    FROM sys.tables t
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.name LIKE @TableNamePattern AND s.name = @SchemaName;

    SELECT @ColumnCount = COUNT(c.column_id)
    FROM sys.columns c
    INNER JOIN sys.tables t ON c.object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.name LIKE @TableNamePattern AND s.name = @SchemaName;

    SET @Message = 'Target Schema: [' + @SchemaName + '], Table Pattern: ''' + @TableNamePattern + ''', Separator: ''' + @Separator + '''';
    EXEC sp_executesql @AddLogMessageProc, @LogParams,
        @SchemaParam = NULL, @TableParam = NULL, @ColumnParam = NULL, @PropNameParam = NULL, @PropValueParam = NULL, @SeverityParam = 'INFO', @MsgParam = @Message, @DebugParam = @DebugMode;
    SET @Message = 'Found ' + CAST(@TableCount AS NVARCHAR(10)) + ' tables and ' + CAST(@ColumnCount AS NVARCHAR(10)) + ' columns matching criteria.';
    EXEC sp_executesql @AddLogMessageProc, @LogParams,
        @SchemaParam = NULL, @TableParam = NULL, @ColumnParam = NULL, @PropNameParam = NULL, @PropValueParam = NULL, @SeverityParam = 'INFO', @MsgParam = @Message, @DebugParam = @DebugMode;

    -- Optional Deletion Block (Commented out by default)
    /*
    ... [Deletion logic remains the same, using sp_executesql for logging] ...
    */

    -- Main processing loop for tables
    DECLARE TableCursor CURSOR LOCAL FAST_FORWARD FOR
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
        SET @Message = '(Table ' + CAST(@TablesProcessed AS NVARCHAR(10)) + '/' + CAST(@TableCount AS NVARCHAR(10)) + ') Processing';
        EXEC sp_executesql @AddLogMessageProc, @LogParams,
            @SchemaParam = @CurrentSchema, @TableParam = @CurrentTable, @ColumnParam = NULL, @PropNameParam = NULL, @PropValueParam = NULL, @SeverityParam = 'INFO', @MsgParam = @Message, @DebugParam = @DebugMode;

        BEGIN TRY
            -- Reset derived names for the current table
            SET @AS400Name = NULL;
            SET @MSSQLName = NULL; -- This will be set differently for tables vs columns

            -- **************************************************
            -- ** TABLE PARSING LOGIC **
            -- **************************************************
            SET @SeparatorPosition = CHARINDEX(@Separator, @CurrentTable); -- Find the start of the defined separator

            IF @SeparatorPosition > 0
            BEGIN
                -- Tentatively get the part AFTER the defined separator
                SET @AS400Name = SUBSTRING(@CurrentTable, @SeparatorPosition + LEN(@Separator), LEN(@CurrentTable));

                -- **FIX:** Trim leading underscores specifically from the derived name
                WHILE LEFT(@AS400Name, 1) = '_' AND LEN(@AS400Name) > 1 -- Avoid infinite loop if name is just "_"
                BEGIN
                    SET @AS400Name = SUBSTRING(@AS400Name, 2, LEN(@AS400Name));
                END
                -- Handle case where the name was just "_"
                IF @AS400Name = '_' SET @AS400Name = '';


                -- Set MSSQLName (the property VALUE) to the FULL original table name
                SET @MSSQLName = @CurrentTable;

                -- Validate derived name (@AS400Name cannot be empty AFTER trimming)
                IF @AS400Name IS NOT NULL AND @AS400Name <> ''
                BEGIN
                    -- Add/Update table extended property within its own TRY/CATCH
                    BEGIN TRY
                        IF @DebugMode = 1
                        BEGIN
                            SET @Message = 'DEBUG: Would add/update TABLE property Name=[' + @AS400Name + '], Value=[' + @MSSQLName + ']';
                            EXEC sp_executesql @AddLogMessageProc, @LogParams,
                                @SchemaParam = @CurrentSchema, @TableParam = @CurrentTable, @ColumnParam = NULL, @PropNameParam = @AS400Name, @PropValueParam = @MSSQLName, @SeverityParam = 'DEBUG', @MsgParam = @Message, @DebugParam = @DebugMode;
                        END
                        ELSE
                        BEGIN
                            -- Check if property exists
                            IF NOT EXISTS (
                                SELECT 1
                                FROM sys.extended_properties ep
                                JOIN sys.tables t ON ep.major_id = t.object_id
                                JOIN sys.schemas s ON t.schema_id = s.schema_id
                                WHERE s.name = @CurrentSchema
                                  AND t.name = @CurrentTable
                                  AND ep.class = 1 -- Object or column
                                  AND ep.minor_id = 0 -- Table level
                                  AND ep.name = @AS400Name
                            )
                            BEGIN
                                -- Add the property if it doesn't exist
                                EXEC sp_addextendedproperty
                                    @name = @AS400Name,
                                    @value = @MSSQLName, -- Use full table name as value
                                    @level0type = N'SCHEMA', @level0name = @CurrentSchema,
                                    @level1type = N'TABLE',  @level1name = @CurrentTable;
                                SET @PropertiesAdded = @PropertiesAdded + 1;
                                SET @Message = 'ADDED Table Property.';
                                EXEC sp_executesql @AddLogMessageProc, @LogParams,
                                    @SchemaParam = @CurrentSchema, @TableParam = @CurrentTable, @ColumnParam = NULL, @PropNameParam = @AS400Name, @PropValueParam = @MSSQLName, @SeverityParam = 'INFO', @MsgParam = @Message, @DebugParam = @DebugMode;
                            END
                            ELSE
                            BEGIN
                                -- Update the property if it exists
                                EXEC sp_updateextendedproperty
                                    @name = @AS400Name,
                                    @value = @MSSQLName, -- Use full table name as value
                                    @level0type = N'SCHEMA', @level0name = @CurrentSchema,
                                    @level1type = N'TABLE',  @level1name = @CurrentTable;
                                SET @Message = 'UPDATED Table Property.';
                                EXEC sp_executesql @AddLogMessageProc, @LogParams,
                                    @SchemaParam = @CurrentSchema, @TableParam = @CurrentTable, @ColumnParam = NULL, @PropNameParam = @AS400Name, @PropValueParam = @MSSQLName, @SeverityParam = 'INFO', @MsgParam = @Message, @DebugParam = @DebugMode;
                            END
                        END -- End Non-Debug execution
                    END TRY
                    BEGIN CATCH
                        SET @PropertiesFailed = @PropertiesFailed + 1;
                        SET @Message = 'FAILED adding/updating TABLE property: ' + ERROR_MESSAGE();
                        EXEC sp_executesql @AddLogMessageProc, @LogParams,
                            @SchemaParam = @CurrentSchema, @TableParam = @CurrentTable, @ColumnParam = NULL, @PropNameParam = @AS400Name, @PropValueParam = @MSSQLName, @SeverityParam = 'ERROR', @MsgParam = @Message, @DebugParam = @DebugMode;
                    END CATCH
                END
                ELSE
                BEGIN
                    SET @Message = 'Skipping table property - Derived AS400Name was empty after separator/trimming.';
                    EXEC sp_executesql @AddLogMessageProc, @LogParams,
                        @SchemaParam = @CurrentSchema, @TableParam = @CurrentTable, @ColumnParam = NULL, @PropNameParam = @AS400Name, @PropValueParam = @MSSQLName, @SeverityParam = 'WARNING', @MsgParam = @Message, @DebugParam = @DebugMode;
                END
            END
            ELSE
            BEGIN
                SET @Message = 'No separator found in table name - skipping table property.';
                EXEC sp_executesql @AddLogMessageProc, @LogParams,
                    @SchemaParam = @CurrentSchema, @TableParam = @CurrentTable, @ColumnParam = NULL, @PropNameParam = NULL, @PropValueParam = NULL, @SeverityParam = 'WARNING', @MsgParam = @Message, @DebugParam = @DebugMode;
            END
            -- **************************************************
            -- ** END TABLE PARSING LOGIC **
            -- **************************************************


-- Process columns for the current table
            DECLARE ColumnCursor CURSOR LOCAL FAST_FORWARD FOR
                SELECT c.name
                FROM sys.columns c
                WHERE c.object_id = OBJECT_ID(QUOTENAME(@CurrentSchema) + '.' + QUOTENAME(@CurrentTable))
                ORDER BY c.column_id;

            OPEN ColumnCursor;
            FETCH NEXT FROM ColumnCursor INTO @CurrentColumn;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                -- Reset derived names for column
                SET @AS400Name = NULL;
                -- SET @MSSQLName = NULL; -- No longer needed for the value, but still derived for validation below

                -- **************************************************
                -- ** COLUMN PARSING LOGIC (Deriving Property Name) **
                -- **************************************************
                SET @SeparatorPosition = CHARINDEX(@Separator, @CurrentColumn);
                IF @SeparatorPosition > 0
                BEGIN
                    -- Attempt PARSENAME first to get the part AFTER the separator
                    SET @ObjectNameForParse = REPLACE(@CurrentColumn, @Separator, '.');
                    IF LEN(@ObjectNameForParse) - LEN(REPLACE(@ObjectNameForParse, '.', '')) = 1 AND LEFT(@ObjectNameForParse, 1) <> '.' AND RIGHT(@ObjectNameForParse, 1) <> '.'
                    BEGIN
                        SET @AS400Name = PARSENAME(@ObjectNameForParse, 1); -- Part after separator (Property Name)
                        -- @MSSQLName = PARSENAME(@ObjectNameForParse, 2); -- Part before separator (Not used for value anymore)
                    END
                    ELSE
                    BEGIN
                        -- Fallback parsing using SUBSTRING
                        SET @AS400Name = SUBSTRING(@CurrentColumn, @SeparatorPosition + LEN(@Separator), LEN(@CurrentColumn)); -- Part after separator (Property Name)
                        -- @MSSQLName = LEFT(@CurrentColumn, @SeparatorPosition - 1); -- Part before separator (Not used for value anymore)
                         SET @Message = 'Used fallback parsing for column name to derive Property Name.';
                        EXEC sp_executesql @AddLogMessageProc, @LogParams,
                            @SchemaParam = @CurrentSchema, @TableParam = @CurrentTable, @ColumnParam = @CurrentColumn, @PropNameParam = NULL, @PropValueParam = NULL, @SeverityParam = 'DEBUG', @MsgParam = @Message, @DebugParam = @DebugMode;
                    END

                    -- **FIX (Columns):** Trim leading underscores specifically from the derived Property Name
                    WHILE LEFT(@AS400Name, 1) = '_' AND LEN(@AS400Name) > 1
                    BEGIN
                        SET @AS400Name = SUBSTRING(@AS400Name, 2, LEN(@AS400Name));
                    END
                    IF @AS400Name = '_' SET @AS400Name = '';

                    -- Validate derived Property Name is not empty
                    -- The Property VALUE will be the full @CurrentColumn name.
                    IF @AS400Name IS NOT NULL AND @AS400Name <> ''
                    BEGIN
                        -- Add/Update column extended property within its own TRY/CATCH
                        BEGIN TRY
                            IF @DebugMode = 1
                            BEGIN
                                -- **MODIFIED DEBUG MESSAGE** to reflect @CurrentColumn as the value
                                SET @Message = 'DEBUG: Would add/update COLUMN property Name=[' + @AS400Name + '], Value=[' + @CurrentColumn + ']';
                                EXEC sp_executesql @AddLogMessageProc, @LogParams,
                                    @SchemaParam = @CurrentSchema, @TableParam = @CurrentTable, @ColumnParam = @CurrentColumn, @PropNameParam = @AS400Name, @PropValueParam = @CurrentColumn, @SeverityParam = 'DEBUG', @MsgParam = @Message, @DebugParam = @DebugMode;
                            END
                            ELSE
                            BEGIN
                                -- Check if property exists
                                IF NOT EXISTS (
                                    SELECT 1
                                    FROM sys.extended_properties ep
                                    JOIN sys.tables t ON ep.major_id = t.object_id
                                    JOIN sys.columns c ON ep.major_id = c.object_id AND ep.minor_id = c.column_id
                                    JOIN sys.schemas s ON t.schema_id = s.schema_id
                                    WHERE s.name = @CurrentSchema
                                      AND t.name = @CurrentTable
                                      AND c.name = @CurrentColumn
                                      AND ep.class = 1 -- Object or column
                                      AND ep.name = @AS400Name
                                )
                                BEGIN
                                    -- Add the property
                                    EXEC sp_addextendedproperty
                                        @name = @AS400Name,
                                        @value = @CurrentColumn, -- **MODIFIED: Use full column name as value**
                                        @level0type = N'SCHEMA', @level0name = @CurrentSchema,
                                        @level1type = N'TABLE',  @level1name = @CurrentTable,
                                        @level2type = N'COLUMN', @level2name = @CurrentColumn;
                                    SET @PropertiesAdded = @PropertiesAdded + 1;
                                    SET @Message = 'ADDED Column Property.';
                                    EXEC sp_executesql @AddLogMessageProc, @LogParams,
                                        @SchemaParam = @CurrentSchema, @TableParam = @CurrentTable, @ColumnParam = @CurrentColumn, @PropNameParam = @AS400Name, @PropValueParam = @CurrentColumn, @SeverityParam = 'INFO', @MsgParam = @Message, @DebugParam = @DebugMode;
                                END
                                ELSE
                                BEGIN
                                     -- Update the property
                                    EXEC sp_updateextendedproperty
                                        @name = @AS400Name,
                                        @value = @CurrentColumn, -- **MODIFIED: Use full column name as value**
                                        @level0type = N'SCHEMA', @level0name = @CurrentSchema,
                                        @level1type = N'TABLE',  @level1name = @CurrentTable,
                                        @level2type = N'COLUMN', @level2name = @CurrentColumn;
                                    SET @Message = 'UPDATED Column Property.';
                                    EXEC sp_executesql @AddLogMessageProc, @LogParams,
                                        @SchemaParam = @CurrentSchema, @TableParam = @CurrentTable, @ColumnParam = @CurrentColumn, @PropNameParam = @AS400Name, @PropValueParam = @CurrentColumn, @SeverityParam = 'INFO', @MsgParam = @Message, @DebugParam = @DebugMode;
                                END
                            END -- End Non-Debug execution
                        END TRY
                        BEGIN CATCH
                            SET @PropertiesFailed = @PropertiesFailed + 1;
                            SET @Message = 'FAILED adding/updating COLUMN property: ' + ERROR_MESSAGE();
                            EXEC sp_executesql @AddLogMessageProc, @LogParams,
                                @SchemaParam = @CurrentSchema, @TableParam = @CurrentTable, @ColumnParam = @CurrentColumn, @PropNameParam = @AS400Name, @PropValueParam = @CurrentColumn, @SeverityParam = 'ERROR', @MsgParam = @Message, @DebugParam = @DebugMode;
                        END CATCH
                    END
                    ELSE
                    BEGIN
                        -- **MODIFIED WARNING MESSAGE**
                        SET @Message = 'Skipping column property - Invalid derived AS400Name (Property Name) after trimming.';
                        EXEC sp_executesql @AddLogMessageProc, @LogParams,
                            @SchemaParam = @CurrentSchema, @TableParam = @CurrentTable, @ColumnParam = @CurrentColumn, @PropNameParam = @AS400Name, @PropValueParam = @CurrentColumn, @SeverityParam = 'WARNING', @MsgParam = @Message, @DebugParam = @DebugMode;
                    END
                END
                ELSE
                BEGIN
                    SET @Message = 'No separator found in column name - skipping column property.';
                     EXEC sp_executesql @AddLogMessageProc, @LogParams,
                        @SchemaParam = @CurrentSchema, @TableParam = @CurrentTable, @ColumnParam = @CurrentColumn, @PropNameParam = NULL, @PropValueParam = NULL, @SeverityParam = 'DEBUG', @MsgParam = @Message, @DebugParam = @DebugMode;
                END
                -- **************************************************
                -- ** END COLUMN PARSING LOGIC **
                -- **************************************************

                FETCH NEXT FROM ColumnCursor INTO @CurrentColumn;
            END -- End Column Cursor Loop

            CLOSE ColumnCursor;
            DEALLOCATE ColumnCursor;

        END TRY
        -- ... [Rest of the procedure remains the same] ...

        BEGIN CATCH
            SET @Message = 'FATAL ERROR processing table: ' + ERROR_MESSAGE() + ' (Line: ' + CAST(ERROR_LINE() AS VARCHAR) + ')';
            EXEC sp_executesql @AddLogMessageProc, @LogParams,
                @SchemaParam = @CurrentSchema, @TableParam = @CurrentTable, @ColumnParam = NULL, @PropNameParam = NULL, @PropValueParam = NULL, @SeverityParam = 'ERROR', @MsgParam = @Message, @DebugParam = @DebugMode;

            -- Ensure ColumnCursor is cleaned up on error
            IF CURSOR_STATUS('local', 'ColumnCursor') >= 0
            BEGIN
                CLOSE ColumnCursor;
                SET @Message = 'Closed ColumnCursor due to error.';
                EXEC sp_executesql @AddLogMessageProc, @LogParams,
                    @SchemaParam = @CurrentSchema, @TableParam = @CurrentTable, @ColumnParam = NULL, @PropNameParam = NULL, @PropValueParam = NULL, @SeverityParam = 'DEBUG', @MsgParam = @Message, @DebugParam = @DebugMode;
            END
            IF CURSOR_STATUS('local', 'ColumnCursor') >= -1
            BEGIN
                DEALLOCATE ColumnCursor;
                 SET @Message = 'Deallocated ColumnCursor due to error.';
                EXEC sp_executesql @AddLogMessageProc, @LogParams,
                    @SchemaParam = @CurrentSchema, @TableParam = @CurrentTable, @ColumnParam = NULL, @PropNameParam = NULL, @PropValueParam = NULL, @SeverityParam = 'DEBUG', @MsgParam = @Message, @DebugParam = @DebugMode;
            END
        END CATCH

        FETCH NEXT FROM TableCursor INTO @CurrentSchema, @CurrentTable;
    END -- End Table Cursor Loop

    CLOSE TableCursor;
    DEALLOCATE TableCursor;

    -- Final Summary Logging
    DECLARE @DurationSeconds DECIMAL(10, 3) = DATEDIFF(MILLISECOND, @StartTime, GETDATE()) / 1000.0;

    SET @Message = 'Processing finished. Duration: ' + CAST(@DurationSeconds AS NVARCHAR(20)) + ' seconds.';
    EXEC sp_executesql @AddLogMessageProc, @LogParams,
        @SchemaParam = NULL, @TableParam = NULL, @ColumnParam = NULL, @PropNameParam = NULL, @PropValueParam = NULL, @SeverityParam = 'INFO', @MsgParam = @Message, @DebugParam = @DebugMode;
    SET @Message = 'Processed ' + CAST(@TablesProcessed AS NVARCHAR(10)) + ' tables. Added/Updated ' + CAST(@PropertiesAdded AS NVARCHAR(10)) + ' properties. Failed attempts: ' + CAST(@PropertiesFailed AS NVARCHAR(10)) + '.';
    EXEC sp_executesql @AddLogMessageProc, @LogParams,
        @SchemaParam = NULL, @TableParam = NULL, @ColumnParam = NULL, @PropNameParam = NULL, @PropValueParam = NULL, @SeverityParam = 'INFO', @MsgParam = @Message, @DebugParam = @DebugMode;

    -- Return log results if DebugMode is enabled
    IF @DebugMode = 1
    BEGIN
        SELECT * FROM #Log ORDER BY LogID;
    END

    DROP TABLE #Log;

    SET NOCOUNT OFF;
END
GO
