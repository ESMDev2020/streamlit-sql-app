USE SigmaTB; -- Ensure this is the correct database context
GO

/*************************************************************************************************
** Stored Procedure: mrs.UpdateExtendedPropertiesForZTables
**
** Description:
** This stored procedure iterates through tables and columns within a specified schema
** (defaulting to 'mrs') that match a given pattern (defaulting to 'z_%').
** It parses the table and column names based on a specified separator (defaulting to '_____').
** For each table/column containing the separator, it adds or updates an extended property:
** - Property Name: The part of the object name *after* the *last* occurrence of the separator.
** Leading underscores are trimmed from this derived name.
** - Property Value: The *full original* name of the table or column.
**
** This is typically used to store an original system name (like an AS/400 name) as an
** extended property, using the potentially longer or more descriptive SQL Server name
** as the value for easier reference.
**
** Parameters:
** @Separator NVARCHAR(10) = '_____'
** - The string used to separate the desired property name from the rest of the object name.
** - The procedure looks for the *last* occurrence of this separator.
** - Default: '_____'
**
** @SchemaName NVARCHAR(128) = 'mrs'
** - The name of the schema containing the tables to process.
** - Default: 'mrs'
**
** @TableNamePattern NVARCHAR(128) = 'z_%'
** - A pattern (using SQL LIKE syntax) to filter the tables within the specified schema.
** - Default: 'z_%' (processes tables starting with 'z_')
**
** @DebugMode BIT = 0
** - If set to 1, the procedure will not actually add/update properties. Instead, it will:
** 1. Print detailed log messages to the console.
** 2. Return a result set containing the contents of the temporary log table (#Log).
** - If set to 0 (default), the procedure executes normally, adding/updating properties
** and only printing essential INFO, WARNING, or ERROR messages.
**
** Logic Highlights:
** - Uses cursors to iterate through matching tables and their columns.
** - Employs REVERSE and CHARINDEX to reliably find the *last* occurrence of the separator.
** - Uses SUBSTRING for robust extraction of the property name.
** - Handles potential leading underscores in the extracted property name by trimming them.
** - Skips objects where the separator is not found or where the derived property name is empty after trimming.
** - Uses sp_addextendedproperty or sp_updateextendedproperty as appropriate.
** - Includes detailed logging (controlled by @DebugMode) using a temporary table and dynamic SQL.
** - Includes TRY...CATCH blocks for error handling at table and property levels.
**
** Assumptions:
** - The SQL Server login executing this procedure has permissions to:
** - Read system views (sys.tables, sys.columns, sys.schemas, sys.extended_properties).
** - Execute sp_addextendedproperty and sp_updateextendedproperty on the target schema/tables/columns.
** - Create and drop temporary tables.
** - The database context ('USE SigmaTB;' in this example) is set correctly before execution.
**
** Revision History:
** [Date] - [Author] - Initial Creation
** [Date] - [Author] - Revised parsing logic to use REVERSE/CHARINDEX/SUBSTRING to find
** the *last* separator, improving handling of complex names.
** Ensured property value is always the full original object name.
** [Date] - [Author] - Added documentation and execution examples.
**
*************************************************************************************************/
CREATE OR ALTER PROCEDURE mrs.UpdateExtendedPropertiesForZTables
    @Separator NVARCHAR(10) = '_____',      -- Separator used in table/column names
    @SchemaName NVARCHAR(128) = 'mrs',      -- Target schema
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
    DECLARE @AS400Name NVARCHAR(128); -- Name for the extended property (part after LAST separator)
    DECLARE @MSSQLName NVARCHAR(256); -- Value for the extended property (full original name)
    DECLARE @Message NVARCHAR(MAX);
    DECLARE @Severity NVARCHAR(20);
    DECLARE @LastSeparatorPosition INT; -- To find the LAST separator index

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

    -- Internal procedure/helper SQL for logging (unchanged)
    DECLARE @AddLogMessageProc NVARCHAR(MAX) = N'
    BEGIN TRY
        INSERT INTO #Log (SchemaName, TableName, ColumnName, PropertyName, PropertyValue, Severity, Message)
        VALUES (@SchemaParam, @TableParam, @ColumnParam, @PropNameParam, @PropValueParam, @SeverityParam, @MsgParam);

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

    DECLARE @LogParams NVARCHAR(MAX) = N'@SchemaParam NVARCHAR(128), @TableParam NVARCHAR(256), @ColumnParam NVARCHAR(128), @PropNameParam NVARCHAR(128), @PropValueParam NVARCHAR(MAX), @SeverityParam NVARCHAR(20), @MsgParam NVARCHAR(MAX), @DebugParam BIT';

    -- Initial Log Message
    SET @Message = 'Starting extended properties update process.';
    EXEC sp_executesql @AddLogMessageProc, @LogParams,
        @SchemaParam = NULL, @TableParam = NULL, @ColumnParam = NULL, @PropNameParam = NULL, @PropValueParam = NULL, @SeverityParam = 'INFO', @MsgParam = @Message, @DebugParam = @DebugMode;

    -- Get counts (unchanged)
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

    -- Optional Deletion Block (remains the same)
    /*
    -- Example: Delete existing properties before adding new ones (Use with caution!)
    IF @DebugMode = 0 -- Only delete if not in debug mode
    BEGIN
        DECLARE @PropName NVARCHAR(128), @Level0Type NVARCHAR(128), @Level0Name NVARCHAR(128),
                @Level1Type NVARCHAR(128), @Level1Name NVARCHAR(128), @Level2Type NVARCHAR(128), @Level2Name NVARCHAR(128);

        DECLARE DelCursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT ep.name, N'SCHEMA', s.name, N'TABLE', t.name, NULL, NULL
            FROM sys.extended_properties ep
            JOIN sys.tables t ON ep.major_id = t.object_id
            JOIN sys.schemas s ON t.schema_id = s.schema_id
            WHERE s.name = @SchemaName AND t.name LIKE @TableNamePattern AND ep.minor_id = 0 -- Table level
            UNION ALL
            SELECT ep.name, N'SCHEMA', s.name, N'TABLE', t.name, N'COLUMN', c.name
            FROM sys.extended_properties ep
            JOIN sys.tables t ON ep.major_id = t.object_id
            JOIN sys.columns c ON ep.major_id = c.object_id AND ep.minor_id = c.column_id
            JOIN sys.schemas s ON t.schema_id = s.schema_id
            WHERE s.name = @SchemaName AND t.name LIKE @TableNamePattern; -- Column level

        OPEN DelCursor;
        FETCH NEXT FROM DelCursor INTO @PropName, @Level0Type, @Level0Name, @Level1Type, @Level1Name, @Level2Type, @Level2Name;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            BEGIN TRY
                EXEC sp_dropextendedproperty @name = @PropName,
                    @level0type = @Level0Type, @level0name = @Level0Name,
                    @level1type = @Level1Type, @level1name = @Level1Name,
                    @level2type = @Level2Type, @level2name = @Level2Name;

                SET @Message = 'Deleted existing property [' + @PropName + '] for ' + @Level0Name + '.' + @Level1Name + ISNULL('.' + @Level2Name, '');
                EXEC sp_executesql @AddLogMessageProc, @LogParams,
                    @SchemaParam = @Level0Name, @TableParam = @Level1Name, @ColumnParam = @Level2Name, @PropNameParam = @PropName, @PropValueParam = NULL, @SeverityParam = 'INFO', @MsgParam = @Message, @DebugParam = @DebugMode;

            END TRY
            BEGIN CATCH
                 SET @Message = 'FAILED deleting property [' + @PropName + '] for ' + @Level0Name + '.' + @Level1Name + ISNULL('.' + @Level2Name, '') + ': ' + ERROR_MESSAGE();
                 EXEC sp_executesql @AddLogMessageProc, @LogParams,
                    @SchemaParam = @Level0Name, @TableParam = @Level1Name, @ColumnParam = @Level2Name, @PropNameParam = @PropName, @PropValueParam = NULL, @SeverityParam = 'ERROR', @MsgParam = @Message, @DebugParam = @DebugMode;
            END CATCH
            FETCH NEXT FROM DelCursor INTO @PropName, @Level0Type, @Level0Name, @Level1Type, @Level1Name, @Level2Type, @Level2Name;
        END
        CLOSE DelCursor;
        DEALLOCATE DelCursor;
        SET @Message = 'Finished deleting existing properties.';
        EXEC sp_executesql @AddLogMessageProc, @LogParams, NULL, NULL, NULL, NULL, NULL, 'INFO', @Message, @DebugMode;
    END
    ELSE
    BEGIN
        SET @Message = 'Skipping deletion of existing properties because DebugMode is ON.';
        EXEC sp_executesql @AddLogMessageProc, @LogParams, NULL, NULL, NULL, NULL, NULL, 'INFO', @Message, @DebugMode;
    END
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
            SET @MSSQLName = @CurrentTable; -- Property VALUE is always the full original name for tables
            SET @LastSeparatorPosition = 0;

            -- **************************************************
            -- ** REVISED TABLE PARSING LOGIC (Find LAST Separator) **
            -- **************************************************
            -- Find the position of the *last* occurrence of the separator
            DECLARE @ReversedTableName NVARCHAR(MAX) = REVERSE(@CurrentTable);
            DECLARE @ReversedSeparator NVARCHAR(10) = REVERSE(@Separator);
            DECLARE @LastSeparatorPositionReverse INT = CHARINDEX(@ReversedSeparator, @ReversedTableName);

            IF @LastSeparatorPositionReverse > 0 AND LEN(@Separator) > 0
            BEGIN
                -- Calculate the starting position in the original string
                -- Position is the index *after* the separator ends
                SET @LastSeparatorPosition = LEN(@CurrentTable) - @LastSeparatorPositionReverse - LEN(@Separator) + 2; -- Adjusted calculation

                -- Extract the part AFTER the last separator
                SET @AS400Name = SUBSTRING(@CurrentTable, @LastSeparatorPosition, LEN(@CurrentTable));

                IF @DebugMode = 1
                BEGIN
                    SET @Message = 'DEBUG: Found last separator for table at pos ' + CAST(@LastSeparatorPosition AS VARCHAR) + '. Raw AS400Name=[' + ISNULL(@AS400Name,'NULL') + ']';
                    EXEC sp_executesql @AddLogMessageProc, @LogParams,
                        @SchemaParam = @CurrentSchema, @TableParam = @CurrentTable, @ColumnParam = NULL, @PropNameParam = NULL, @PropValueParam = NULL, @SeverityParam = 'DEBUG', @MsgParam = @Message, @DebugParam = @DebugMode;
                END

                -- Trim leading underscores specifically from the derived name
                WHILE LEFT(@AS400Name, 1) = '_' AND LEN(@AS400Name) > 1
                BEGIN
                    SET @AS400Name = SUBSTRING(@AS400Name, 2, LEN(@AS400Name));
                END
                IF @AS400Name = '_' SET @AS400Name = ''; -- Handle case where name was just "_" after separator

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
            -- ** END REVISED TABLE PARSING LOGIC **
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
                SET @MSSQLName = @CurrentColumn; -- Property VALUE is always the full original name for columns
                SET @LastSeparatorPosition = 0;

                -- **************************************************
                -- ** REVISED COLUMN PARSING LOGIC (Find LAST Separator) **
                -- **************************************************
                DECLARE @ReversedColumnName NVARCHAR(MAX) = REVERSE(@CurrentColumn);
                -- @ReversedSeparator already declared and reversed above

                SET @LastSeparatorPositionReverse = CHARINDEX(@ReversedSeparator, @ReversedColumnName);

                IF @LastSeparatorPositionReverse > 0 AND LEN(@Separator) > 0
                BEGIN
                    -- Calculate the starting position in the original string
                    SET @LastSeparatorPosition = LEN(@CurrentColumn) - @LastSeparatorPositionReverse - LEN(@Separator) + 2; -- Adjusted calculation

                    -- Extract the part AFTER the last separator (Property Name)
                    SET @AS400Name = SUBSTRING(@CurrentColumn, @LastSeparatorPosition, LEN(@CurrentColumn));

                    IF @DebugMode = 1
                    BEGIN
                        SET @Message = 'DEBUG: Found last separator for column at pos ' + CAST(@LastSeparatorPosition AS VARCHAR) + '. Raw AS400Name=[' + ISNULL(@AS400Name,'NULL') + ']';
                        EXEC sp_executesql @AddLogMessageProc, @LogParams,
                            @SchemaParam = @CurrentSchema, @TableParam = @CurrentTable, @ColumnParam = @CurrentColumn, @PropNameParam = NULL, @PropValueParam = NULL, @SeverityParam = 'DEBUG', @MsgParam = @Message, @DebugParam = @DebugMode;
                    END

                    -- Trim leading underscores specifically from the derived Property Name
                    WHILE LEFT(@AS400Name, 1) = '_' AND LEN(@AS400Name) > 1
                    BEGIN
                        SET @AS400Name = SUBSTRING(@AS400Name, 2, LEN(@AS400Name));
                    END
                    IF @AS400Name = '_' SET @AS400Name = ''; -- Handle case where name was just "_" after separator

                    -- Validate derived Property Name is not empty
                    IF @AS400Name IS NOT NULL AND @AS400Name <> ''
                    BEGIN
                        -- Add/Update column extended property within its own TRY/CATCH
                        BEGIN TRY
                            IF @DebugMode = 1
                            BEGIN
                                SET @Message = 'DEBUG: Would add/update COLUMN property Name=[' + @AS400Name + '], Value=[' + @MSSQLName + ']'; -- Value is @CurrentColumn
                                EXEC sp_executesql @AddLogMessageProc, @LogParams,
                                    @SchemaParam = @CurrentSchema, @TableParam = @CurrentTable, @ColumnParam = @CurrentColumn, @PropNameParam = @AS400Name, @PropValueParam = @MSSQLName, @SeverityParam = 'DEBUG', @MsgParam = @Message, @DebugParam = @DebugMode;
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
                                        @value = @MSSQLName, -- Use full column name as value
                                        @level0type = N'SCHEMA', @level0name = @CurrentSchema,
                                        @level1type = N'TABLE',  @level1name = @CurrentTable,
                                        @level2type = N'COLUMN', @level2name = @CurrentColumn;
                                    SET @PropertiesAdded = @PropertiesAdded + 1;
                                    SET @Message = 'ADDED Column Property.';
                                    EXEC sp_executesql @AddLogMessageProc, @LogParams,
                                        @SchemaParam = @CurrentSchema, @TableParam = @CurrentTable, @ColumnParam = @CurrentColumn, @PropNameParam = @AS400Name, @PropValueParam = @MSSQLName, @SeverityParam = 'INFO', @MsgParam = @Message, @DebugParam = @DebugMode;
                                END
                                ELSE
                                BEGIN
                                     -- Update the property
                                    EXEC sp_updateextendedproperty
                                        @name = @AS400Name,
                                        @value = @MSSQLName, -- Use full column name as value
                                        @level0type = N'SCHEMA', @level0name = @CurrentSchema,
                                        @level1type = N'TABLE',  @level1name = @CurrentTable,
                                        @level2type = N'COLUMN', @level2name = @CurrentColumn;
                                    SET @Message = 'UPDATED Column Property.';
                                    EXEC sp_executesql @AddLogMessageProc, @LogParams,
                                        @SchemaParam = @CurrentSchema, @TableParam = @CurrentTable, @ColumnParam = @CurrentColumn, @PropNameParam = @AS400Name, @PropValueParam = @MSSQLName, @SeverityParam = 'INFO', @MsgParam = @Message, @DebugParam = @DebugMode;
                                END
                            END -- End Non-Debug execution
                        END TRY
                        BEGIN CATCH
                            SET @PropertiesFailed = @PropertiesFailed + 1;
                            SET @Message = 'FAILED adding/updating COLUMN property: ' + ERROR_MESSAGE();
                            EXEC sp_executesql @AddLogMessageProc, @LogParams,
                                @SchemaParam = @CurrentSchema, @TableParam = @CurrentTable, @ColumnParam = @CurrentColumn, @PropNameParam = @AS400Name, @PropValueParam = @MSSQLName, @SeverityParam = 'ERROR', @MsgParam = @Message, @DebugParam = @DebugMode;
                        END CATCH
                    END
                    ELSE
                    BEGIN
                        SET @Message = 'Skipping column property - Invalid derived AS400Name (Property Name) after separator/trimming.';
                        EXEC sp_executesql @AddLogMessageProc, @LogParams,
                            @SchemaParam = @CurrentSchema, @TableParam = @CurrentTable, @ColumnParam = @CurrentColumn, @PropNameParam = @AS400Name, @PropValueParam = @MSSQLName, @SeverityParam = 'WARNING', @MsgParam = @Message, @DebugParam = @DebugMode;
                    END
                END
                ELSE
                BEGIN
                    SET @Message = 'No separator found in column name - skipping column property.';
                     EXEC sp_executesql @AddLogMessageProc, @LogParams,
                         @SchemaParam = @CurrentSchema, @TableParam = @CurrentTable, @ColumnParam = @CurrentColumn, @PropNameParam = NULL, @PropValueParam = NULL, @SeverityParam = 'DEBUG', @MsgParam = @Message, @DebugParam = @DebugMode; -- Changed to DEBUG as this might be expected
                END
                -- **************************************************
                -- ** END REVISED COLUMN PARSING LOGIC **
                -- **************************************************

                FETCH NEXT FROM ColumnCursor INTO @CurrentColumn;
            END -- End Column Cursor Loop

            CLOSE ColumnCursor;
            DEALLOCATE ColumnCursor;

        END TRY
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

    -- Final Summary Logging (unchanged)
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

/*************************************************************************************************
** Execution Examples:
*************************************************************************************************/

/*
-- Example 1: Run with default settings (Schema 'mrs', Table pattern 'z_%', Separator '_____', Debug OFF)
-- This will actually add/update extended properties.
EXEC mrs.UpdateExtendedPropertiesForZTables;
GO
*/

/*
-- Example 2: Run in Debug Mode with default settings.
-- This will NOT modify properties but will print detailed logs and return the log table.
EXEC mrs.UpdateExtendedPropertiesForZTables @DebugMode = 1;
GO
*/

/*
-- Example 3: Run for a different schema ('dbo') and table pattern ('Sales%')
EXEC mrs.UpdateExtendedPropertiesForZTables
    @SchemaName = 'dbo',
    @TableNamePattern = 'Sales%',
    @DebugMode = 0; -- Set to 1 for debugging this specific run
GO
*/

/*
-- Example 4: Run with a different separator ('--SEP--') for tables starting with 'import_' in 'staging' schema.
EXEC mrs.UpdateExtendedPropertiesForZTables
    @Separator = '--SEP--',
    @SchemaName = 'staging',
    @TableNamePattern = 'import_%',
    @DebugMode = 1; -- Recommended to run in debug first with custom settings
GO
*/

/*
-- Example 5: Process the specific problematic name provided earlier (assuming it's a column name)
-- NOTE: This requires a table (e.g., 'mrs.z_TestTable') and the column to exist.
-- Create dummy objects first if needed:
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'mrs') EXEC('CREATE SCHEMA mrs');
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'z_TestTable' AND schema_id = SCHEMA_ID('mrs'))
    CREATE TABLE mrs.z_TestTable (
        [PSI_=_PER_SQUARE_INCH_PLI_=_PER_LINEAR_INCH_"___"=_____IMWUOM] INT,
        SomeOtherColumn_____OTHERCOL INT
    );
GO

-- Now run the procedure targeting this table in debug mode:
EXEC mrs.UpdateExtendedPropertiesForZTables
    @SchemaName = 'mrs',
    @TableNamePattern = 'z_TestTable',
    @Separator = '_____',
    @DebugMode = 1;
GO

-- Clean up dummy objects if created:
-- DROP TABLE mrs.z_TestTable;
-- IF NOT EXISTS (SELECT * FROM sys.tables WHERE schema_id = SCHEMA_ID('mrs')) DROP SCHEMA mrs;
-- GO
*/

