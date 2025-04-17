-- ==================================================================
-- Create Main Stored Procedure (Calls Helper Function) for SigmaTB Database
-- ==================================================================
USE SigmaTB;
GO

-- Drop the procedure if it already exists
IF OBJECT_ID('dbo.usp_UpdateExtendedPropertiesFromNames', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_UpdateExtendedPropertiesFromNames;
GO

CREATE PROCEDURE dbo.usp_UpdateExtendedPropertiesFromNames
AS
BEGIN
    SET NOCOUNT ON;

    -- Configuration & Initialization
    DECLARE @SchemaNameFilter SYSNAME = N'dbo';
    DECLARE @TableNameFilter NVARCHAR(100) = N'z_%';
    DECLARE @Separator NVARCHAR(5) = N'_____';
    DECLARE @StartTime DATETIME2 = SYSUTCDATETIME();
    DECLARE @Count INT;
    DECLARE @ColumnCount INT;

    PRINT N'==================================================================';
    PRINT N'PROCEDURE START: ' + CONVERT(VARCHAR, @StartTime, 120);
    PRINT N'==================================================================';

    -- Create temporary table for tables to process
    IF OBJECT_ID('tempdb..#TablesToProcess') IS NOT NULL DROP TABLE #TablesToProcess;
    CREATE TABLE #TablesToProcess (
        SchemaName SYSNAME,
        TableName SYSNAME,
        ObjectId INT
    );

    -- Get list of tables to process
    INSERT INTO #TablesToProcess (SchemaName, TableName, ObjectId)
    SELECT 
        s.name,
        t.name,
        t.object_id
    FROM sys.tables t
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.name LIKE @TableNameFilter 
    AND (@SchemaNameFilter IS NULL OR s.name = @SchemaNameFilter);

    SELECT @Count = COUNT(*) FROM #TablesToProcess;
    PRINT N'Total tables to process: ' + CAST(@Count AS VARCHAR(10));
    PRINT N'==================================================================';

    -- Process each table
    DECLARE @CurrentSchema SYSNAME;
    DECLARE @CurrentTable SYSNAME;
    DECLARE @CurrentObjectId INT;
    DECLARE @TableCounter INT = 0;
    DECLARE @CurrentTime DATETIME2;

    DECLARE TableCursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT SchemaName, TableName, ObjectId
    FROM #TablesToProcess
    ORDER BY SchemaName, TableName;

    OPEN TableCursor;
    FETCH NEXT FROM TableCursor INTO @CurrentSchema, @CurrentTable, @CurrentObjectId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @TableCounter = @TableCounter + 1;
        SET @CurrentTime = SYSUTCDATETIME();
        
        -- Get column count for current table
        SELECT @ColumnCount = COUNT(*)
        FROM sys.columns c
        WHERE c.object_id = @CurrentObjectId;

        PRINT N'[' + CONVERT(VARCHAR, @CurrentTime, 120) + N'] Processing table ' + 
              CAST(@TableCounter AS VARCHAR(10)) + N' of ' + CAST(@Count AS VARCHAR(10)) + 
              N': [' + @CurrentSchema + N'].[' + @CurrentTable + N']' +
              N' (Columns: ' + CAST(@ColumnCount AS VARCHAR(10)) + N')';

        -- Process current table
        BEGIN TRY
            -- Process table properties
            DECLARE @TableCode NVARCHAR(128) = dbo.udf_GetDerivedCode(@CurrentTable, @Separator);
            
            IF @TableCode IS NOT NULL
            BEGIN
                -- Check if table property exists
                IF EXISTS (
                    SELECT 1 
                    FROM sys.extended_properties ep
                    WHERE ep.major_id = @CurrentObjectId
                    AND ep.minor_id = 0
                    AND ep.name = @TableCode
                    AND ep.class = 1
                )
                BEGIN
                    -- Update existing property
                    EXEC sp_updateextendedproperty 
                        @name = @TableCode,
                        @value = @CurrentTable,
                        @level0type = N'SCHEMA',
                        @level0name = @CurrentSchema,
                        @level1type = N'TABLE',
                        @level1name = @CurrentTable;
                END
                ELSE
                BEGIN
                    -- Add new property
                    EXEC sp_addextendedproperty 
                        @name = @TableCode,
                        @value = @CurrentTable,
                        @level0type = N'SCHEMA',
                        @level0name = @CurrentSchema,
                        @level1type = N'TABLE',
                        @level1name = @CurrentTable;
                END
            END

            -- Process column properties
            DECLARE @ColumnName SYSNAME;
            DECLARE @ColumnId INT;
            DECLARE @ColumnCode NVARCHAR(128);
            DECLARE @ColumnCounter INT = 0;

            DECLARE ColumnCursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT c.name, c.column_id
            FROM sys.columns c
            WHERE c.object_id = @CurrentObjectId;

            OPEN ColumnCursor;
            FETCH NEXT FROM ColumnCursor INTO @ColumnName, @ColumnId;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @ColumnCounter = @ColumnCounter + 1;
                SET @ColumnCode = dbo.udf_GetDerivedCode(@ColumnName, @Separator);
                
                IF @ColumnCode IS NOT NULL
                BEGIN
                    -- Check if column property exists
                    IF EXISTS (
                        SELECT 1 
                        FROM sys.extended_properties ep
                        WHERE ep.major_id = @CurrentObjectId
                        AND ep.minor_id = @ColumnId
                        AND ep.name = @ColumnCode
                        AND ep.class = 1
                    )
                    BEGIN
                        -- Update existing property
                        EXEC sp_updateextendedproperty 
                            @name = @ColumnCode,
                            @value = @ColumnName,
                            @level0type = N'SCHEMA',
                            @level0name = @CurrentSchema,
                            @level1type = N'TABLE',
                            @level1name = @CurrentTable,
                            @level2type = N'COLUMN',
                            @level2name = @ColumnName;
                    END
                    ELSE
                    BEGIN
                        -- Add new property
                        EXEC sp_addextendedproperty 
                            @name = @ColumnCode,
                            @value = @ColumnName,
                            @level0type = N'SCHEMA',
                            @level0name = @CurrentSchema,
                            @level1type = N'TABLE',
                            @level1name = @CurrentTable,
                            @level2type = N'COLUMN',
                            @level2name = @ColumnName;
                    END
                END

                FETCH NEXT FROM ColumnCursor INTO @ColumnName, @ColumnId;
            END

            CLOSE ColumnCursor;
            DEALLOCATE ColumnCursor;

            PRINT N'[' + CONVERT(VARCHAR, SYSUTCDATETIME(), 120) + N'] Completed table [' + @CurrentSchema + N'].[' + @CurrentTable + N']' +
                  N' (Processed ' + CAST(@ColumnCounter AS VARCHAR(10)) + N' columns)';

        END TRY
        BEGIN CATCH
            PRINT N'[' + CONVERT(VARCHAR, SYSUTCDATETIME(), 120) + N'] ERROR processing table [' + @CurrentSchema + N'].[' + @CurrentTable + N']: ' + ERROR_MESSAGE();
            IF CURSOR_STATUS('local','ColumnCursor') >= 0 CLOSE ColumnCursor;
            IF CURSOR_STATUS('local','ColumnCursor') >= -1 DEALLOCATE ColumnCursor;
        END CATCH

        FETCH NEXT FROM TableCursor INTO @CurrentSchema, @CurrentTable, @CurrentObjectId;
    END

    CLOSE TableCursor;
    DEALLOCATE TableCursor;

    -- Cleanup
    IF OBJECT_ID('tempdb..#TablesToProcess') IS NOT NULL DROP TABLE #TablesToProcess;

    -- Final timestamp
    DECLARE @EndTime DATETIME2 = SYSUTCDATETIME();
    PRINT N'==================================================================';
    PRINT N'PROCEDURE END: ' + CONVERT(VARCHAR, @EndTime, 120);
    PRINT N'Total Duration: ' + CAST(DATEDIFF(MILLISECOND, @StartTime, @EndTime) / 1000.0 AS DECIMAL(10, 3)) + N' seconds';
    PRINT N'Processed ' + CAST(@TableCounter AS VARCHAR(10)) + N' tables';
    PRINT N'==================================================================';
    SET NOCOUNT OFF;
END;
GO

PRINT N'Stored procedure dbo.usp_UpdateExtendedPropertiesFromNames created successfully in SigmaTB.';
PRINT N'To run, execute: EXEC dbo.usp_UpdateExtendedPropertiesFromNames;';
GO