-- ==================================================================
-- !! IMPORTANT !! Replace 'YourActualDatabaseName' with your DB name
-- ==================================================================
USE SigmaTB;; 
GO

-- Drop the procedure if it already exists
IF OBJECT_ID('dbo.usp_UpdateExtendedPropertiesFromNames', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_UpdateExtendedPropertiesFromNames;
GO

CREATE PROCEDURE dbo.usp_UpdateExtendedPropertiesFromNames
AS
BEGIN
    -- Prevent extra messages from interfering with SELECT results (like 'x rows affected')
    SET NOCOUNT ON;

    -- =============================================
    -- Configuration & Initialization
    -- =============================================
    DECLARE @SchemaNameFilter SYSNAME = N'dbo'; -- Set to NULL to process all schemas, or specify one like 'dbo'
    DECLARE @TableNameFilter NVARCHAR(100) = N'z_%'; -- Filter for table names
    DECLARE @Separator NVARCHAR(5) = N'_____'; -- The separator used to derive the code
    DECLARE @StartTime DATETIME2 = SYSUTCDATETIME(); -- Use UTC for consistency

    PRINT N'--- Procedure Start ---';
    PRINT N'Start Time (UTC): ' + CONVERT(VARCHAR, @StartTime, 120); -- Format:<y_bin_46>-mm-dd hh:mi:ss

    -- =============================================
    -- Temporary table to hold all processing info
    -- =============================================
    IF OBJECT_ID('tempdb..#PropsToUpdate') IS NOT NULL
        DROP TABLE #PropsToUpdate;

    CREATE TABLE #PropsToUpdate (
        SchemaName SYSNAME NOT NULL,
        ObjectName SYSNAME NOT NULL, -- Table or Column Name
        ParentTableName SYSNAME NOT NULL, -- Relevant for columns
        ObjectType TINYINT NOT NULL, -- 0 = Table, 1 = Column
        MajorId INT NOT NULL, -- Table Object ID
        MinorId INT NOT NULL, -- 0 for Table, Column ID for Column
        DerivedCode NVARCHAR(128) NULL, -- Max length for extended property name
        OriginalName NVARCHAR(MAX) NOT NULL,
        PropertyExists BIT NOT NULL DEFAULT 0,
        CurrentValue NVARCHAR(MAX) NULL -- Store current value if property exists
    );

    -- =============================================
    -- 1. Gather Table and Column Information (Set-Based)
    --    *** MODIFIED: Using two separate INSERT statements ***
    -- =============================================
    PRINT N'Gathering table and column information...';
    BEGIN TRY
        -- *** Insert Table Info ***
        INSERT INTO #PropsToUpdate (
            SchemaName, ObjectName, ParentTableName, ObjectType, MajorId, MinorId, OriginalName, DerivedCode
        )
        SELECT
            s.name AS SchemaName,
            t.name AS ObjectName,
            t.name AS ParentTableName, -- Table is its own parent in this context
            0 AS ObjectType, -- 0 = Table
            t.object_id AS MajorId,
            0 AS MinorId, -- 0 for table-level properties
            t.name AS OriginalName,
            -- Derivation using RIGHT()
            CASE
                WHEN CHARINDEX(@Separator, t.name) > 0 THEN
                    NULLIF(RIGHT(t.name, CHARINDEX(REVERSE(@Separator), REVERSE(t.name)) - 1), '')
                ELSE NULL -- Separator not found, code cannot be derived
            END AS DerivedCode
        FROM sys.tables t
        INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE t.name LIKE @TableNameFilter
          AND (@SchemaNameFilter IS NULL OR s.name = @SchemaNameFilter);

        -- *** Insert Column Info ***
        INSERT INTO #PropsToUpdate (
            SchemaName, ObjectName, ParentTableName, ObjectType, MajorId, MinorId, OriginalName, DerivedCode
        )
        SELECT
            s.name AS SchemaName,
            c.name AS ObjectName,
            t.name AS ParentTableName,
            1 AS ObjectType, -- 1 = Column
            t.object_id AS MajorId,
            c.column_id AS MinorId, -- Column ID for column-level properties
            c.name AS OriginalName,
             -- Derivation using RIGHT()
            CASE
                WHEN CHARINDEX(@Separator, c.name) > 0 THEN
                     NULLIF(RIGHT(c.name, CHARINDEX(REVERSE(@Separator), REVERSE(c.name)) - 1), '')
                ELSE NULL -- Separator not found, code cannot be derived
            END AS DerivedCode
        FROM sys.columns c
        INNER JOIN sys.tables t ON c.object_id = t.object_id
        INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE t.name LIKE @TableNameFilter
          AND (@SchemaNameFilter IS NULL OR s.name = @SchemaNameFilter);

        -- Remove entries where code could not be derived or is empty after trimming
        DELETE FROM #PropsToUpdate WHERE DerivedCode IS NULL OR LTRIM(RTRIM(DerivedCode)) = '';

        PRINT N'Gathered ' + CAST((SELECT COUNT(*) FROM #PropsToUpdate) AS VARCHAR(10)) + N' potential properties to check/update.';

    END TRY
    BEGIN CATCH
        PRINT N'ERROR Gathering Data: ' + ERROR_MESSAGE();
        IF OBJECT_ID('tempdb..#PropsToUpdate') IS NOT NULL DROP TABLE #PropsToUpdate;
        RETURN; -- Exit procedure on error
    END CATCH

    -- =============================================
    -- 2. Check for Existing Properties (Set-Based Update)
    -- =============================================
     PRINT N'Checking for existing extended properties...';
    BEGIN TRY
        UPDATE tmp
        SET
            tmp.PropertyExists = 1,
            tmp.CurrentValue = CAST(ep.value AS NVARCHAR(MAX)) -- Store current value
        FROM #PropsToUpdate tmp
        INNER JOIN sys.extended_properties ep ON ep.major_id = tmp.MajorId
                                             AND ep.minor_id = tmp.MinorId
                                             AND ep.name = tmp.DerivedCode -- Match on the DERIVED code name
                                             AND ep.class = 1; -- Class 1 = Object or Column

         PRINT N'Finished checking existing properties.';
    END TRY
    BEGIN CATCH
        PRINT N'ERROR Checking Existing Properties: ' + ERROR_MESSAGE();
        IF OBJECT_ID('tempdb..#PropsToUpdate') IS NOT NULL DROP TABLE #PropsToUpdate;
        RETURN; -- Exit procedure on error
    END CATCH

    -- =============================================
    -- 3. Iterate by TABLE and Apply Updates/Adds
    -- =============================================
    PRINT N'Applying updates/adds...';

    DECLARE @TableCounter INT = 0;
    DECLARE @TotalTablesToProcess INT;
    DECLARE @CurrentTableSchema SYSNAME;
    DECLARE @CurrentTableName SYSNAME;
    DECLARE @CurrentTableMajorId INT;

    -- Determine distinct tables to process
    IF OBJECT_ID('tempdb..#TablesToProcess') IS NOT NULL DROP TABLE #TablesToProcess;
    SELECT DISTINCT SchemaName, ParentTableName, MajorId INTO #TablesToProcess FROM #PropsToUpdate ORDER BY SchemaName, ParentTableName;
    SET @TotalTablesToProcess = @@ROWCOUNT;


    PRINT N'Total distinct tables to process: ' + CAST(@TotalTablesToProcess AS VARCHAR(10));

    -- Cursor to iterate through distinct tables
    DECLARE TableCursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT SchemaName, ParentTableName, MajorId FROM #TablesToProcess ORDER BY SchemaName, ParentTableName;

    OPEN TableCursor;
    FETCH NEXT FROM TableCursor INTO @CurrentTableSchema, @CurrentTableName, @CurrentTableMajorId;

    BEGIN TRANSACTION; -- Start transaction before applying changes

    BEGIN TRY
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @TableCounter = @TableCounter + 1;
            -- Print Table Progress with Timestamp
            PRINT CONVERT(VARCHAR, SYSUTCDATETIME(), 120) + N' Processing Table ' + CAST(@TableCounter AS VARCHAR(10)) + N' of ' + CAST(@TotalTablesToProcess AS VARCHAR(10)) + N': [' + @CurrentTableSchema + N'].[' + @CurrentTableName + N']';

            -- Variables for inner loop (properties of the current table)
            DECLARE @CurObjectName SYSNAME;
            DECLARE @CurObjectType TINYINT;
            DECLARE @CurMinorId INT;
            DECLARE @CurDerivedCode NVARCHAR(128);
            DECLARE @CurOriginalName NVARCHAR(MAX);
            DECLARE @CurPropertyExists BIT;
            DECLARE @CurCurrentValue NVARCHAR(MAX);

            -- Cursor for properties related to the CURRENT table
            DECLARE PropertyCursor CURSOR LOCAL FAST_FORWARD FOR
                 SELECT ObjectName, ObjectType, MinorId, DerivedCode, OriginalName, PropertyExists, CurrentValue
                 FROM #PropsToUpdate
                 WHERE MajorId = @CurrentTableMajorId -- Filter for current table
                 ORDER BY ObjectType, MinorId; -- Process table prop first, then columns

            OPEN PropertyCursor;
            FETCH NEXT FROM PropertyCursor INTO @CurObjectName, @CurObjectType, @CurMinorId, @CurDerivedCode, @CurOriginalName, @CurPropertyExists, @CurCurrentValue;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                 -- Apply Add/Update logic (same as before, but inside nested loop)
                 IF @CurPropertyExists = 1
                 BEGIN
                     -- UPDATE (only if value changed)
                     IF @CurCurrentValue IS NULL OR @CurCurrentValue <> @CurOriginalName
                     BEGIN
                         IF @CurObjectType = 0 -- Table
                            EXEC sp_updateextendedproperty @name = @CurDerivedCode, @value = @CurOriginalName, @level0type = N'SCHEMA', @level0name = @CurrentTableSchema, @level1type = N'TABLE', @level1name = @CurrentTableName;
                         ELSE -- Column
                            EXEC sp_updateextendedproperty @name = @CurDerivedCode, @value = @CurOriginalName, @level0type = N'SCHEMA', @level0name = @CurrentTableSchema, @level1type = N'TABLE', @level1name = @CurrentTableName, @level2type = N'COLUMN', @level2name = @CurObjectName;
                     END
                 END
                 ELSE
                 BEGIN
                     -- ADD
                     IF @CurObjectType = 0 -- Table
                        EXEC sp_addextendedproperty @name = @CurDerivedCode, @value = @CurOriginalName, @level0type = N'SCHEMA', @level0name = @CurrentTableSchema, @level1type = N'TABLE', @level1name = @CurrentTableName;
                     ELSE -- Column
                        EXEC sp_addextendedproperty @name = @CurDerivedCode, @value = @CurOriginalName, @level0type = N'SCHEMA', @level0name = @CurrentTableSchema, @level1type = N'TABLE', @level1name = @CurrentTableName, @level2type = N'COLUMN', @level2name = @CurObjectName;
                 END

                 FETCH NEXT FROM PropertyCursor INTO @CurObjectName, @CurObjectType, @CurMinorId, @CurDerivedCode, @CurOriginalName, @CurPropertyExists, @CurCurrentValue;
            END

            CLOSE PropertyCursor;
            DEALLOCATE PropertyCursor;

            FETCH NEXT FROM TableCursor INTO @CurrentTableSchema, @CurrentTableName, @CurrentTableMajorId;
        END -- End of TableCursor Loop

        COMMIT TRANSACTION; -- Commit if loop completes successfully
        PRINT N'--- Successfully processed ' + CAST(@TableCounter AS VARCHAR(10)) + N' tables. Transaction Committed. ---';

    END TRY
    BEGIN CATCH
        -- If any error occurred during the loop, rollback the transaction
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        PRINT N'ERROR during property application: ' + ERROR_MESSAGE();
        PRINT N'Transaction Rolled Back.';

        -- Clean up cursors if open
        IF CURSOR_STATUS('local','TableCursor') >= 0 CLOSE TableCursor;
        IF CURSOR_STATUS('local','TableCursor') >= -1 DEALLOCATE TableCursor; -- Deallocate even if closed
        IF CURSOR_STATUS('local','PropertyCursor') >= 0 CLOSE PropertyCursor;
        IF CURSOR_STATUS('local','PropertyCursor') >= -1 DEALLOCATE PropertyCursor; -- Deallocate even if closed

        -- Cleanup temp tables
        IF OBJECT_ID('tempdb..#PropsToUpdate') IS NOT NULL DROP TABLE #PropsToUpdate;
        IF OBJECT_ID('tempdb..#TablesToProcess') IS NOT NULL DROP TABLE #TablesToProcess;
        RETURN; -- Exit procedure
    END CATCH

    -- Clean up Table cursor if loop finished normally
    CLOSE TableCursor;
    DEALLOCATE TableCursor;

    -- =============================================
    -- 4. Cleanup & Final Timestamp
    -- =============================================
    IF OBJECT_ID('tempdb..#PropsToUpdate') IS NOT NULL
        DROP TABLE #PropsToUpdate;
    IF OBJECT_ID('tempdb..#TablesToProcess') IS NOT NULL
        DROP TABLE #TablesToProcess;

    DECLARE @EndTime DATETIME2 = SYSUTCDATETIME();
    PRINT N'--- Procedure End ---';
    PRINT N'End Time (UTC):   ' + CONVERT(VARCHAR, @EndTime, 120);
    PRINT N'Total Duration: ' + CAST(DATEDIFF(MILLISECOND, @StartTime, @EndTime) / 1000.0 AS DECIMAL(10, 3)) + N' seconds';

    SET NOCOUNT OFF;

END;
GO

PRINT N'Stored procedure dbo.usp_UpdateExtendedPropertiesFromNames created successfully.';
PRINT N'To run, execute: EXEC dbo.usp_UpdateExtendedPropertiesFromNames;';
GO

-- Example Execution:
-- EXEC dbo.usp_UpdateExtendedPropertiesFromNames;
GO