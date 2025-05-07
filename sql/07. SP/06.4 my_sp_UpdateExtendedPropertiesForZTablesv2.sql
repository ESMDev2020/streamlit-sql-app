USE SigmaTB; -- Ensure this is the correct database context
GO

/*************************************************************************************************
** Stored Procedure: mrs.UpdateExtendedPropertiesForZTables
**
** Description:
** This stored procedure can operate in two modes based on the @OperationMode parameter:
** 1. Update/Add Mode (@OperationMode = 1, default):
** Iterates through tables and columns within a specified schema matching a pattern.
** Parses names based on a separator and adds/updates an extended property where:
** - Property Name: Part of the object name *after* the *last* separator (leading '_' trimmed).
** - Property Value: The *full original* object name.
** 2. Delete Mode (@OperationMode = 0):
** Deletes *all* extended properties (both table and column level) for objects
** matching the specified schema and table name pattern.
**
** Parameters:
** @OperationMode BIT = 1
** - Determines the procedure's action.
** - 1 = Update/Add Mode (Default): Parses names and adds/updates properties.
** - 0 = Delete Mode: Deletes existing properties matching the schema/pattern.
**
** @Separator NVARCHAR(10) = '_____'
** - (Update/Add Mode Only) The string used to separate the desired property name.
** - Looks for the *last* occurrence. Default: '_____'
**
** @SchemaName NVARCHAR(128) = 'mrs'
** - The target schema for both update and delete operations. Default: 'mrs'
**
** @TableNamePattern NVARCHAR(128) = 'z_%'
** - A LIKE pattern to filter tables for both update and delete operations. Default: 'z_%'
**
** @DebugMode BIT = 0
** - If set to 1:
** - Prints detailed log messages.
** - Returns the log table (#Log) as a result set.
** - In Update/Add Mode: Does *not* actually modify properties.
** - In Delete Mode: Does *not* actually delete properties.
** - If set to 0 (default): Executes the chosen operation (Update/Add or Delete).
**
** Logic Highlights:
** - Uses @OperationMode to switch between Update/Add and Delete logic paths.
** - Update/Add uses REVERSE/CHARINDEX/SUBSTRING for robust parsing.
** - Delete uses a cursor to find and drop matching properties.
** - Both modes use sp_executesql for logging via #Log table.
** - Includes TRY...CATCH blocks for error handling.
**
** Assumptions:
** - Login has permissions for sys views, temp tables, and sp_add/update/dropextendedproperty.
** - Database context is correctly set.
**
** Revision History:
** [Date] - [Author] - Initial Creation
** [Date] - [Author] - Revised parsing logic for Update/Add mode.
** [Date] - [Author] - Added documentation and execution examples.
** [Date] - [Author] - Added @OperationMode parameter and integrated Delete functionality.
** Modified Delete logic to target table/column props matching schema/pattern.
**
*************************************************************************************************/
CREATE OR ALTER PROCEDURE mrs.UpdateExtendedPropertiesForZTables
    @OperationMode BIT = 1,                  -- 1 = Update/Add, 0 = Delete
    @Separator NVARCHAR(10) = '_____',      -- Separator used in table/column names (Update Mode)
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
    DECLARE @PropertiesAdded INT = 0; -- Update Mode
    DECLARE @PropertiesFailed INT = 0;  -- Update Mode
    DECLARE @PropertiesDropped INT = 0; -- Delete Mode
    DECLARE @DeleteErrors INT = 0;    -- Delete Mode

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

    -- Initial Log Message indicating mode
    IF @OperationMode = 1
        SET @Message = 'Starting extended properties UPDATE/ADD process.';
    ELSE IF @OperationMode = 0
        SET @Message = 'Starting extended properties DELETE process.';
    ELSE
    BEGIN
        SET @Message = 'Invalid @OperationMode specified. Must be 1 (Update/Add) or 0 (Delete).';
        EXEC sp_executesql @AddLogMessageProc, @LogParams, NULL, NULL, NULL, NULL, NULL, 'ERROR', @Message, @DebugMode;
        RETURN; -- Exit if mode is invalid
    END
    EXEC sp_executesql @AddLogMessageProc, @LogParams, NULL, NULL, NULL, NULL, NULL, 'INFO', @Message, @DebugMode;


    -- Get counts (primarily for Update mode logging, but good info anyway)
    SELECT @TableCount = COUNT(DISTINCT t.object_id)
    FROM sys.tables t
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.name LIKE @TableNamePattern AND s.name = @SchemaName;

    SELECT @ColumnCount = COUNT(c.column_id)
    FROM sys.columns c
    INNER JOIN sys.tables t ON c.object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.name LIKE @TableNamePattern AND s.name = @SchemaName;

    SET @Message = 'Target Schema: [' + @SchemaName + '], Table Pattern: ''' + @TableNamePattern + '''';
    IF @OperationMode = 1 SET @Message = @Message + ', Separator: ''' + @Separator + '''';
    EXEC sp_executesql @AddLogMessageProc, @LogParams, NULL, NULL, NULL, NULL, NULL, 'INFO', @Message, @DebugMode;

    SET @Message = 'Found ' + CAST(@TableCount AS NVARCHAR(10)) + ' tables and ' + CAST(@ColumnCount AS NVARCHAR(10)) + ' columns matching criteria for potential processing.';
     EXEC sp_executesql @AddLogMessageProc, @LogParams, NULL, NULL, NULL, NULL, NULL, 'INFO', @Message, @DebugMode;


    -- ==================================================
    -- == OPERATION MODE: UPDATE / ADD (1)
    -- ==================================================
    IF @OperationMode = 1
    BEGIN
        -- Main processing loop for tables (Update/Add Mode)
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
            SET @Message = '(Table ' + CAST(@TablesProcessed AS NVARCHAR(10)) + '/' + CAST(@TableCount AS NVARCHAR(10)) + ') Processing for Update/Add';
            EXEC sp_executesql @AddLogMessageProc, @LogParams,
                @SchemaParam = @CurrentSchema, @TableParam = @CurrentTable, @ColumnParam = NULL, @PropNameParam = NULL, @PropValueParam = NULL, @SeverityParam = 'INFO', @MsgParam = @Message, @DebugParam = @DebugMode;

            BEGIN TRY
                -- Reset derived names for the current table
                SET @AS400Name = NULL;
                SET @MSSQLName = @CurrentTable; -- Property VALUE is always the full original name for tables
                SET @LastSeparatorPosition = 0;

                -- **************************************************
                -- ** TABLE PARSING LOGIC (Find LAST Separator) **
                -- **************************************************
                DECLARE @ReversedTableName NVARCHAR(MAX) = REVERSE(@CurrentTable);
                DECLARE @ReversedSeparator NVARCHAR(10) = REVERSE(@Separator);
                DECLARE @LastSeparatorPositionReverse INT = CHARINDEX(@ReversedSeparator, @ReversedTableName);

                IF @LastSeparatorPositionReverse > 0 AND LEN(@Separator) > 0
                BEGIN
                    SET @LastSeparatorPosition = LEN(@CurrentTable) - @LastSeparatorPositionReverse + 2;
                    SET @AS400Name = SUBSTRING(@CurrentTable, @LastSeparatorPosition, LEN(@CurrentTable));

                    IF @DebugMode = 1
                    BEGIN
                        SET @Message = 'DEBUG: Found last separator for table at pos ' + CAST(@LastSeparatorPosition AS VARCHAR) + '. Raw AS400Name=[' + ISNULL(@AS400Name,'NULL') + ']';
                        EXEC sp_executesql @AddLogMessageProc, @LogParams, @CurrentSchema, @CurrentTable, NULL, NULL, NULL, 'DEBUG', @Message, @DebugMode;
                    END

                    WHILE LEFT(@AS400Name, 1) = '_' AND LEN(@AS400Name) > 1 BEGIN SET @AS400Name = SUBSTRING(@AS400Name, 2, LEN(@AS400Name)); END
                    IF @AS400Name = '_' SET @AS400Name = '';

                    IF @AS400Name IS NOT NULL AND @AS400Name <> ''
                    BEGIN
                        BEGIN TRY
                            IF @DebugMode = 1
                            BEGIN
                                SET @Message = 'DEBUG: Would add/update TABLE property Name=[' + @AS400Name + '], Value=[' + @MSSQLName + ']';
                                EXEC sp_executesql @AddLogMessageProc, @LogParams, @CurrentSchema, @CurrentTable, NULL, @AS400Name, @MSSQLName, 'DEBUG', @Message, @DebugMode;
                            END
                            ELSE
                            BEGIN
                                IF NOT EXISTS ( SELECT 1 FROM sys.extended_properties ep JOIN sys.tables t ON ep.major_id = t.object_id JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = @CurrentSchema AND t.name = @CurrentTable AND ep.class = 1 AND ep.minor_id = 0 AND ep.name = @AS400Name)
                                BEGIN
                                    EXEC sp_addextendedproperty @name = @AS400Name, @value = @MSSQLName, @level0type = N'SCHEMA', @level0name = @CurrentSchema, @level1type = N'TABLE',  @level1name = @CurrentTable;
                                    SET @PropertiesAdded = @PropertiesAdded + 1; SET @Message = 'ADDED Table Property.';
                                    EXEC sp_executesql @AddLogMessageProc, @LogParams, @CurrentSchema, @CurrentTable, NULL, @AS400Name, @MSSQLName, 'INFO', @Message, @DebugMode;
                                END
                                ELSE
                                BEGIN
                                    EXEC sp_updateextendedproperty @name = @AS400Name, @value = @MSSQLName, @level0type = N'SCHEMA', @level0name = @CurrentSchema, @level1type = N'TABLE',  @level1name = @CurrentTable;
                                    SET @Message = 'UPDATED Table Property.';
                                    EXEC sp_executesql @AddLogMessageProc, @LogParams, @CurrentSchema, @CurrentTable, NULL, @AS400Name, @MSSQLName, 'INFO', @Message, @DebugMode;
                                END
                            END
                        END TRY
                        BEGIN CATCH
                            SET @PropertiesFailed = @PropertiesFailed + 1; SET @Message = 'FAILED adding/updating TABLE property: ' + ERROR_MESSAGE();
                            EXEC sp_executesql @AddLogMessageProc, @LogParams, @CurrentSchema, @CurrentTable, NULL, @AS400Name, @MSSQLName, 'ERROR', @Message, @DebugMode;
                        END CATCH
                    END
                    ELSE
                    BEGIN
                        SET @Message = 'Skipping table property - Derived AS400Name was empty after separator/trimming.';
                        EXEC sp_executesql @AddLogMessageProc, @LogParams, @CurrentSchema, @CurrentTable, NULL, @AS400Name, @MSSQLName, 'WARNING', @Message, @DebugMode;
                    END
                END
                ELSE
                BEGIN
                    SET @Message = 'No separator found in table name - skipping table property.';
                    EXEC sp_executesql @AddLogMessageProc, @LogParams, @CurrentSchema, @CurrentTable, NULL, NULL, NULL, 'WARNING', @Message, @DebugMode;
                END
                -- **************************************************
                -- ** END TABLE PARSING LOGIC **
                -- **************************************************


                -- Process columns for the current table (Update/Add Mode)
                DECLARE ColumnCursor CURSOR LOCAL FAST_FORWARD FOR
                    SELECT c.name FROM sys.columns c WHERE c.object_id = OBJECT_ID(QUOTENAME(@CurrentSchema) + '.' + QUOTENAME(@CurrentTable)) ORDER BY c.column_id;

                OPEN ColumnCursor;
                FETCH NEXT FROM ColumnCursor INTO @CurrentColumn;

                WHILE @@FETCH_STATUS = 0
                BEGIN
                    SET @AS400Name = NULL; SET @MSSQLName = @CurrentColumn; SET @LastSeparatorPosition = 0;

                    -- **************************************************
                    -- ** COLUMN PARSING LOGIC (Find LAST Separator) **
                    -- **************************************************
                    DECLARE @ReversedColumnName NVARCHAR(MAX) = REVERSE(@CurrentColumn);
                    SET @LastSeparatorPositionReverse = CHARINDEX(@ReversedSeparator, @ReversedColumnName);

                    IF @LastSeparatorPositionReverse > 0 AND LEN(@Separator) > 0
                    BEGIN
                        SET @LastSeparatorPosition = LEN(@CurrentColumn) - @LastSeparatorPositionReverse + 2;
                        SET @AS400Name = SUBSTRING(@CurrentColumn, @LastSeparatorPosition, LEN(@CurrentColumn));

                        IF @DebugMode = 1
                        BEGIN
                            SET @Message = 'DEBUG: Found last separator for column at pos ' + CAST(@LastSeparatorPosition AS VARCHAR) + '. Raw AS400Name=[' + ISNULL(@AS400Name,'NULL') + ']';
                            EXEC sp_executesql @AddLogMessageProc, @LogParams, @CurrentSchema, @CurrentTable, @CurrentColumn, NULL, NULL, 'DEBUG', @Message, @DebugMode;
                        END

                        WHILE LEFT(@AS400Name, 1) = '_' AND LEN(@AS400Name) > 1 BEGIN SET @AS400Name = SUBSTRING(@AS400Name, 2, LEN(@AS400Name)); END
                        IF @AS400Name = '_' SET @AS400Name = '';

                        IF @AS400Name IS NOT NULL AND @AS400Name <> ''
                        BEGIN
                            BEGIN TRY
                                IF @DebugMode = 1
                                BEGIN
                                    SET @Message = 'DEBUG: Would add/update COLUMN property Name=[' + @AS400Name + '], Value=[' + @MSSQLName + ']';
                                    EXEC sp_executesql @AddLogMessageProc, @LogParams, @CurrentSchema, @CurrentTable, @CurrentColumn, @AS400Name, @MSSQLName, 'DEBUG', @Message, @DebugMode;
                                END
                                ELSE
                                BEGIN
                                    IF NOT EXISTS ( SELECT 1 FROM sys.extended_properties ep JOIN sys.tables t ON ep.major_id = t.object_id JOIN sys.columns c ON ep.major_id = c.object_id AND ep.minor_id = c.column_id JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = @CurrentSchema AND t.name = @CurrentTable AND c.name = @CurrentColumn AND ep.class = 1 AND ep.name = @AS400Name )
                                    BEGIN
                                        EXEC sp_addextendedproperty @name = @AS400Name, @value = @MSSQLName, @level0type = N'SCHEMA', @level0name = @CurrentSchema, @level1type = N'TABLE',  @level1name = @CurrentTable, @level2type = N'COLUMN', @level2name = @CurrentColumn;
                                        SET @PropertiesAdded = @PropertiesAdded + 1; SET @Message = 'ADDED Column Property.';
                                        EXEC sp_executesql @AddLogMessageProc, @LogParams, @CurrentSchema, @CurrentTable, @CurrentColumn, @AS400Name, @MSSQLName, 'INFO', @Message, @DebugMode;
                                    END
                                    ELSE
                                    BEGIN
                                        EXEC sp_updateextendedproperty @name = @AS400Name, @value = @MSSQLName, @level0type = N'SCHEMA', @level0name = @CurrentSchema, @level1type = N'TABLE',  @level1name = @CurrentTable, @level2type = N'COLUMN', @level2name = @CurrentColumn;
                                        SET @Message = 'UPDATED Column Property.';
                                        EXEC sp_executesql @AddLogMessageProc, @LogParams, @CurrentSchema, @CurrentTable, @CurrentColumn, @AS400Name, @MSSQLName, 'INFO', @Message, @DebugMode;
                                    END
                                END
                            END TRY
                            BEGIN CATCH
                                SET @PropertiesFailed = @PropertiesFailed + 1; SET @Message = 'FAILED adding/updating COLUMN property: ' + ERROR_MESSAGE();
                                EXEC sp_executesql @AddLogMessageProc, @LogParams, @CurrentSchema, @CurrentTable, @CurrentColumn, @AS400Name, @MSSQLName, 'ERROR', @Message, @DebugMode;
                            END CATCH
                        END
                        ELSE
                        BEGIN
                            SET @Message = 'Skipping column property - Invalid derived AS400Name (Property Name) after separator/trimming.';
                            EXEC sp_executesql @AddLogMessageProc, @LogParams, @CurrentSchema, @CurrentTable, @CurrentColumn, @AS400Name, @MSSQLName, 'WARNING', @Message, @DebugMode;
                        END
                    END
                    ELSE
                    BEGIN
                        SET @Message = 'No separator found in column name - skipping column property.';
                         EXEC sp_executesql @AddLogMessageProc, @LogParams, @CurrentSchema, @CurrentTable, @CurrentColumn, NULL, NULL, 'DEBUG', @Message, @DebugMode;
                    END
                    -- **************************************************
                    -- ** END COLUMN PARSING LOGIC **
                    -- **************************************************

                    FETCH NEXT FROM ColumnCursor INTO @CurrentColumn;
                END -- End Column Cursor Loop

                CLOSE ColumnCursor;
                DEALLOCATE ColumnCursor;

            END TRY
            BEGIN CATCH
                SET @Message = 'FATAL ERROR processing table for Update/Add: ' + ERROR_MESSAGE() + ' (Line: ' + CAST(ERROR_LINE() AS VARCHAR) + ')';
                EXEC sp_executesql @AddLogMessageProc, @LogParams, @CurrentSchema, @CurrentTable, NULL, NULL, NULL, 'ERROR', @Message, @DebugMode;
                IF CURSOR_STATUS('local', 'ColumnCursor') >= 0 BEGIN CLOSE ColumnCursor; END
                IF CURSOR_STATUS('local', 'ColumnCursor') >= -1 BEGIN DEALLOCATE ColumnCursor; END
            END CATCH

            FETCH NEXT FROM TableCursor INTO @CurrentSchema, @CurrentTable;
        END -- End Table Cursor Loop

        CLOSE TableCursor;
        DEALLOCATE TableCursor;

        -- Final Summary Logging for Update/Add Mode
        DECLARE @DurationSeconds DECIMAL(10, 3) = DATEDIFF(MILLISECOND, @StartTime, GETDATE()) / 1000.0;
        SET @Message = 'Update/Add processing finished. Duration: ' + CAST(@DurationSeconds AS NVARCHAR(20)) + ' seconds.';
        EXEC sp_executesql @AddLogMessageProc, @LogParams, NULL, NULL, NULL, NULL, NULL, 'INFO', @Message, @DebugMode;
        SET @Message = 'Processed ' + CAST(@TablesProcessed AS NVARCHAR(10)) + ' tables. Added/Updated ' + CAST(@PropertiesAdded AS NVARCHAR(10)) + ' properties. Failed attempts: ' + CAST(@PropertiesFailed AS NVARCHAR(10)) + '.';
        EXEC sp_executesql @AddLogMessageProc, @LogParams, NULL, NULL, NULL, NULL, NULL, 'INFO', @Message, @DebugMode;

    END -- End Update/Add Mode Block

    -- ==================================================
    -- == OPERATION MODE: DELETE (0)
    -- ==================================================
    ELSE IF @OperationMode = 0
    BEGIN
        DECLARE @DelPropName NVARCHAR(128), @DelLevel0Type NVARCHAR(128), @DelLevel0Name NVARCHAR(128),
                @DelLevel1Type NVARCHAR(128), @DelLevel1Name NVARCHAR(128), @DelLevel2Type NVARCHAR(128), @DelLevel2Name NVARCHAR(128);

        SET @Message = 'Starting search for properties to delete...';
        EXEC sp_executesql @AddLogMessageProc, @LogParams, @SchemaName, NULL, NULL, NULL, NULL, 'INFO', @Message, @DebugMode;

        -- Cursor to find ALL table and column level extended properties matching schema and table pattern
        DECLARE DeleteCursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT ep.name, N'SCHEMA', s.name, N'TABLE', t.name, NULL, NULL -- Table Level
            FROM sys.extended_properties ep
            JOIN sys.tables t ON ep.major_id = t.object_id
            JOIN sys.schemas s ON t.schema_id = s.schema_id
            WHERE s.name = @SchemaName
              AND t.name LIKE @TableNamePattern
              AND ep.class = 1 AND ep.minor_id = 0 -- Table level properties
            UNION ALL
            SELECT ep.name, N'SCHEMA', s.name, N'TABLE', t.name, N'COLUMN', c.name -- Column Level
            FROM sys.extended_properties ep
            JOIN sys.tables t ON ep.major_id = t.object_id
            JOIN sys.columns c ON ep.major_id = c.object_id AND ep.minor_id = c.column_id
            JOIN sys.schemas s ON t.schema_id = s.schema_id
            WHERE s.name = @SchemaName
              AND t.name LIKE @TableNamePattern
              AND ep.class = 1 AND ep.minor_id > 0; -- Column level properties

        OPEN DeleteCursor;
        FETCH NEXT FROM DeleteCursor INTO @DelPropName, @DelLevel0Type, @DelLevel0Name, @DelLevel1Type, @DelLevel1Name, @DelLevel2Type, @DelLevel2Name;

        IF @@FETCH_STATUS = -1 -- No properties found
        BEGIN
            SET @Message = 'No extended properties found matching the criteria to delete.';
            EXEC sp_executesql @AddLogMessageProc, @LogParams, @SchemaName, NULL, NULL, NULL, NULL, 'INFO', @Message, @DebugMode;
        END

        WHILE @@FETCH_STATUS = 0
        BEGIN
            DECLARE @ObjectIdentifier NVARCHAR(514) = QUOTENAME(@DelLevel0Name) + '.' + QUOTENAME(@DelLevel1Name) + ISNULL('.' + QUOTENAME(@DelLevel2Name), '');

            BEGIN TRY
                IF @DebugMode = 1
                BEGIN
                    SET @Message = 'DEBUG: Would delete property [' + @DelPropName + '] for object ' + @ObjectIdentifier;
                    EXEC sp_executesql @AddLogMessageProc, @LogParams, @DelLevel0Name, @DelLevel1Name, @DelLevel2Name, @DelPropName, NULL, 'DEBUG', @Message, @DebugMode;
                    -- Increment count even in debug mode to show what *would* happen
                    SET @PropertiesDropped = @PropertiesDropped + 1;
                END
                ELSE
                BEGIN
                    SET @Message = 'Deleting property [' + @DelPropName + '] for object ' + @ObjectIdentifier + '...';
                    EXEC sp_executesql @AddLogMessageProc, @LogParams, @DelLevel0Name, @DelLevel1Name, @DelLevel2Name, @DelPropName, NULL, 'INFO', @Message, @DebugMode;

                    EXEC sys.sp_dropextendedproperty
                        @name = @DelPropName,
                        @level0type = @DelLevel0Type, @level0name = @DelLevel0Name,
                        @level1type = @DelLevel1Type, @level1name = @DelLevel1Name,
                        @level2type = @DelLevel2Type, @level2name = @DelLevel2Name;

                    SET @PropertiesDropped = @PropertiesDropped + 1;
                    SET @Message = '...Deleted successfully.';
                    EXEC sp_executesql @AddLogMessageProc, @LogParams, @DelLevel0Name, @DelLevel1Name, @DelLevel2Name, @DelPropName, NULL, 'INFO', @Message, @DebugMode;
                END
            END TRY
            BEGIN CATCH
                SET @DeleteErrors = @DeleteErrors + 1;
                SET @Message = '*** ERROR Deleting property [' + @DelPropName + '] for object ' + @ObjectIdentifier + ': ' + ERROR_MESSAGE();
                EXEC sp_executesql @AddLogMessageProc, @LogParams, @DelLevel0Name, @DelLevel1Name, @DelLevel2Name, @DelPropName, NULL, 'ERROR', @Message, @DebugMode;
            END CATCH

            FETCH NEXT FROM DeleteCursor INTO @DelPropName, @DelLevel0Type, @DelLevel0Name, @DelLevel1Type, @DelLevel1Name, @DelLevel2Type, @DelLevel2Name;
        END

        CLOSE DeleteCursor;
        DEALLOCATE DeleteCursor;

        -- Final Summary Logging for Delete Mode
        SET @DurationSeconds = DATEDIFF(MILLISECOND, @StartTime, GETDATE()) / 1000.0; -- Recalculate duration
        SET @Message = 'Delete processing finished. Duration: ' + CAST(@DurationSeconds AS NVARCHAR(20)) + ' seconds.';
        EXEC sp_executesql @AddLogMessageProc, @LogParams, NULL, NULL, NULL, NULL, NULL, 'INFO', @Message, @DebugMode;
        SET @Message = 'Properties dropped: ' + CAST(@PropertiesDropped AS VARCHAR) + '. Errors encountered: ' + CAST(@DeleteErrors AS VARCHAR) + '.';
        IF @DebugMode = 1 SET @Message = @Message + ' (Ran in Debug Mode - No actual deletions occurred)';
        EXEC sp_executesql @AddLogMessageProc, @LogParams, NULL, NULL, NULL, NULL, NULL, 'INFO', @Message, @DebugMode;

    END -- End Delete Mode Block

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
-- Example 1: Run Update/Add with default settings (Schema 'mrs', Table pattern 'z_%', Separator '_____', Debug OFF)
-- This will actually add/update extended properties.
EXEC mrs.UpdateExtendedPropertiesForZTables @OperationMode = 1;
-- Or simply (since Update/Add is default):
-- EXEC mrs.UpdateExtendedPropertiesForZTables;
GO
*/

/*
-- Example 2: Run Update/Add in Debug Mode with default settings.
-- This will NOT modify properties but will print detailed logs and return the log table.
EXEC mrs.UpdateExtendedPropertiesForZTables @OperationMode = 1, @DebugMode = 1;
-- Or simply:
-- EXEC mrs.UpdateExtendedPropertiesForZTables @DebugMode = 1;
GO
*/

/*
-- Example 3: Run Delete Mode for schema 'mrs', pattern 'z_%' (Debug OFF)
-- WARNING: This will delete properties! Review the pattern carefully.
EXEC mrs.UpdateExtendedPropertiesForZTables @OperationMode = 0, @SchemaName = 'mrs', @TableNamePattern = 'z_%', @DebugMode = 0;
GO
*/

/*
-- Example 4: Run Delete Mode in Debug Mode for schema 'mrs', pattern 'z_%'.
-- This will show which properties *would* be deleted without actually deleting them. Recommended before running Example 3.
EXEC mrs.UpdateExtendedPropertiesForZTables @OperationMode = 0, @SchemaName = 'mrs', @TableNamePattern = 'z_%', @DebugMode = 1;
GO
*/


/*
-- Example 5: Run Update/Add for a different schema ('dbo') and table pattern ('Sales%')
EXEC mrs.UpdateExtendedPropertiesForZTables
    @OperationMode = 1, -- Explicitly setting mode
    @SchemaName = 'dbo',
    @TableNamePattern = 'Sales%',
    @DebugMode = 0; -- Set to 1 for debugging this specific run
GO
*/

/*
-- Example 6: Run Update/Add with a different separator ('--SEP--') for tables starting with 'import_' in 'staging' schema.
EXEC mrs.UpdateExtendedPropertiesForZTables
    @OperationMode = 1,
    @Separator = '--SEP--',
    @SchemaName = 'staging',
    @TableNamePattern = 'import_%',
    @DebugMode = 1; -- Recommended to run in debug first with custom settings
GO
*/

/*
-- Example 7: Process the specific problematic name provided earlier in Update/Add mode (Debug ON)
-- NOTE: This requires a table (e.g., 'mrs.z_TestTable') and the column to exist.
-- Create dummy objects first if needed:
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'mrs') EXEC('CREATE SCHEMA mrs');
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'z_TestTable' AND schema_id = SCHEMA_ID('mrs'))
    CREATE TABLE mrs.z_TestTable (
        [PSI_=_PER_SQUARE_INCH_PLI_=_PER_LINEAR_INCH_"___"=_____IMWUOM] INT,
        SomeOtherColumn_____OTHERCOL INT,
        AnotherTableLevelProperty_____TBLPROP INT -- Example for table property
    );
GO

-- Now run the procedure targeting this table in Update/Add debug mode:
EXEC mrs.UpdateExtendedPropertiesForZTables
    @OperationMode = 1,
    @SchemaName = 'mrs',
    @TableNamePattern = 'z_TestTable',
    @Separator = '_____',
    @DebugMode = 1;
GO

-- Example 8: Run Delete Mode in Debug Mode for the dummy table created above
EXEC mrs.UpdateExtendedPropertiesForZTables
    @OperationMode = 0,
    @SchemaName = 'mrs',
    @TableNamePattern = 'z_TestTable',
    @DebugMode = 1;
GO

-- Clean up dummy objects if created:
-- DROP TABLE mrs.z_TestTable;
-- IF NOT EXISTS (SELECT * FROM sys.tables WHERE schema_id = SCHEMA_ID('mrs')) DROP SCHEMA mrs;
-- GO
*/

