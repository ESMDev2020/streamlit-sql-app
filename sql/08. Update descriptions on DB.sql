-- ==================================================================
-- !! IMPORTANT !! Replace 'YourActualDatabaseName' with your DB name
-- !! This is a DIAGNOSTIC version - it does NOT calculate the real code !!
-- ==================================================================
USE SigmaTB;
GO

-- Drop the procedure if it already exists
IF OBJECT_ID('dbo.usp_UpdateExtendedProperties_Diagnostic', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_UpdateExtendedProperties_Diagnostic;
GO

CREATE PROCEDURE dbo.usp_UpdateExtendedProperties_Diagnostic
AS
BEGIN
    SET NOCOUNT ON;
    PRINT N'--- Diagnostic Procedure Start ---';

    DECLARE @SchemaNameFilter SYSNAME = N'dbo';
    DECLARE @TableNameFilter NVARCHAR(100) = N'z_%';
    -- DECLARE @Separator NVARCHAR(5) = N'_____'; -- Not used in this version
    DECLARE @StartTime DATETIME2 = SYSUTCDATETIME();
    PRINT N'Start Time (UTC): ' + CONVERT(VARCHAR, @StartTime, 120);

    -- Temp table
    IF OBJECT_ID('tempdb..#PropsToUpdateDiag') IS NOT NULL DROP TABLE #PropsToUpdateDiag;
    CREATE TABLE #PropsToUpdateDiag ( SchemaName SYSNAME, ObjectName SYSNAME, ParentTableName SYSNAME, ObjectType TINYINT, MajorId INT, MinorId INT, DerivedCode NVARCHAR(128) NULL, OriginalName NVARCHAR(MAX), PropertyExists BIT DEFAULT 0, CurrentValue NVARCHAR(MAX) NULL );
    PRINT N'Created #PropsToUpdateDiag temp table.';

    -- Simplified data gathering
    PRINT N'Gathering basic info...';
    BEGIN TRY
        INSERT INTO #PropsToUpdateDiag (SchemaName, ObjectName, ParentTableName, ObjectType, MajorId, MinorId, OriginalName) SELECT s.name, t.name, t.name, 0, t.object_id, 0, t.name FROM sys.tables t INNER JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE t.name LIKE @TableNameFilter AND (@SchemaNameFilter IS NULL OR s.name = @SchemaNameFilter);
        INSERT INTO #PropsToUpdateDiag (SchemaName, ObjectName, ParentTableName, ObjectType, MajorId, MinorId, OriginalName) SELECT s.name, c.name, t.name, 1, t.object_id, c.column_id, c.name FROM sys.columns c INNER JOIN sys.tables t ON c.object_id = t.object_id INNER JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE t.name LIKE @TableNameFilter AND (@SchemaNameFilter IS NULL OR s.name = @SchemaNameFilter);
        PRINT N'Gathered basic object info.';
    END TRY
    BEGIN CATCH PRINT N'ERROR Gathering Basic Data: ' + ERROR_MESSAGE(); IF OBJECT_ID('tempdb..#PropsToUpdateDiag') IS NOT NULL DROP TABLE #PropsToUpdateDiag; RETURN; END CATCH

    -- Simplified Code Calculation (using a dummy value)
    PRINT N'Applying dummy derived codes...';
    BEGIN TRY
        UPDATE #PropsToUpdateDiag SET DerivedCode = N'TestCode_T' WHERE ObjectType = 0; -- Dummy code for tables
        UPDATE #PropsToUpdateDiag SET DerivedCode = N'TestCode_C' WHERE ObjectType = 1; -- Dummy code for columns
        DELETE FROM #PropsToUpdateDiag WHERE DerivedCode IS NULL; -- Should not delete anything here, but keep structure
        PRINT N'Applied dummy codes.';
    END TRY
    BEGIN CATCH PRINT N'ERROR Applying Dummy Codes: ' + ERROR_MESSAGE(); IF OBJECT_ID('tempdb..#PropsToUpdateDiag') IS NOT NULL DROP TABLE #PropsToUpdateDiag; RETURN; END CATCH

    -- Check existing properties (Simplified)
    PRINT N'Checking existing properties...';
    BEGIN TRY
        UPDATE tmp SET tmp.PropertyExists = 1, tmp.CurrentValue = CAST(ep.value AS NVARCHAR(MAX)) FROM #PropsToUpdateDiag tmp INNER JOIN sys.extended_properties ep ON ep.major_id = tmp.MajorId AND ep.minor_id = tmp.MinorId AND ep.name = tmp.DerivedCode AND ep.class = 1;
        PRINT N'Checked existing properties.';
    END TRY
    BEGIN CATCH PRINT N'ERROR Checking Existing Properties: ' + ERROR_MESSAGE(); IF OBJECT_ID('tempdb..#PropsToUpdateDiag') IS NOT NULL DROP TABLE #PropsToUpdateDiag; RETURN; END CATCH

    -- Simplified Iteration (just prints, doesn't call SPs)
    PRINT N'Starting dummy iteration...';
    DECLARE @TableCounter INT = 0, @TotalTablesToProcess INT = 0;
    IF OBJECT_ID('tempdb..#TablesToProcessDiag') IS NOT NULL DROP TABLE #TablesToProcessDiag;
    SELECT DISTINCT SchemaName, ParentTableName, MajorId INTO #TablesToProcessDiag FROM #PropsToUpdateDiag ORDER BY SchemaName, ParentTableName;
    SET @TotalTablesToProcess = @@ROWCOUNT;
    PRINT N'Total distinct tables to process: ' + CAST(@TotalTablesToProcess AS VARCHAR(10));

    DECLARE @CurrentTableSchema SYSNAME, @CurrentTableName SYSNAME, @CurrentTableMajorId INT;
    DECLARE TableCursor CURSOR LOCAL FAST_FORWARD FOR SELECT SchemaName, ParentTableName, MajorId FROM #TablesToProcessDiag ORDER BY SchemaName, ParentTableName;
    OPEN TableCursor; FETCH NEXT FROM TableCursor INTO @CurrentTableSchema, @CurrentTableName, @CurrentTableMajorId;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @TableCounter = @TableCounter + 1;
        PRINT CONVERT(VARCHAR, SYSUTCDATETIME(), 120) + N' Mock Processing Table ' + CAST(@TableCounter AS VARCHAR(10)) + N' of ' + CAST(@TotalTablesToProcess AS VARCHAR(10)) + N': [' + @CurrentTableSchema + N'].[' + @CurrentTableName + N']';
        -- Mock processing properties for this table - just fetching to simulate cursor
         DECLARE @DummyVar INT;
         DECLARE PropertyCursor CURSOR LOCAL FAST_FORWARD FOR SELECT MinorId FROM #PropsToUpdateDiag WHERE MajorId = @CurrentTableMajorId;
         OPEN PropertyCursor; FETCH NEXT FROM PropertyCursor INTO @DummyVar;
         WHILE @@FETCH_STATUS = 0 FETCH NEXT FROM PropertyCursor INTO @DummyVar;
         CLOSE PropertyCursor; DEALLOCATE PropertyCursor;

        FETCH NEXT FROM TableCursor INTO @CurrentTableSchema, @CurrentTableName, @CurrentTableMajorId;
    END
    CLOSE TableCursor; DEALLOCATE TableCursor;
    PRINT N'Finished dummy iteration.';

    -- Cleanup
    IF OBJECT_ID('tempdb..#PropsToUpdateDiag') IS NOT NULL DROP TABLE #PropsToUpdateDiag;
    IF OBJECT_ID('tempdb..#TablesToProcessDiag') IS NOT NULL DROP TABLE #TablesToProcessDiag;
    PRINT N'Cleaned up temp tables.';

    DECLARE @EndTime DATETIME2 = SYSUTCDATETIME();
    PRINT N'--- Diagnostic Procedure End ---';
    PRINT N'End Time (UTC):   ' + CONVERT(VARCHAR, @EndTime, 120);
    PRINT N'Total Duration: ' + CAST(DATEDIFF(MILLISECOND, @StartTime, @EndTime) / 1000.0 AS DECIMAL(10, 3)) + N' seconds';
    SET NOCOUNT OFF;
END;
GO

PRINT N'Attempting to create DIAGNOSTIC stored procedure dbo.usp_UpdateExtendedProperties_Diagnostic.';
GO