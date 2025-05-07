USE [SigmaTB]; -- Ensure the correct database context
GO

-- =============================================
-- Author:      Gemini AI
-- Create date: 2025-05-04
--				FINDS COLUMNS IN OTHER TABLES LIKE THE ONE WE ARE AUDITING
-- Description: Finds extended properties attached to columns within the 'mrs' schema
--              where the property name matches a given pattern (@myVarVARCHARParamColumnCode).
--              It lists the schema, table, column name, property name (interpreted as 'Column Code'),
--              and property value. The results are ordered by the property name.
--              This procedure interprets 'Column Code' as the name of the extended property itself,
--              based on the user request "Column code = sys.extended.properties name".
--              The procedure also returns the actual table name associated with the column.
-- Database:    SigmaTB
-- Schema:      mrs
--
-- Parameters:
--   @myVarVARCHARParamColumnCode NVARCHAR(128): Pattern (using LIKE) to match the extended property name (the 'Column Code').
--   @myVarBITDebugMode BIT: 1 = Print debug/progress messages, 0 = Silent execution.
--
-- Returns:     A result set containing SchemaName, TableName (actual table name), ColumnName (actual column name),
--              PropertyName (used as 'Column Code' for filtering and sorting), PropertyValue.
-- =============================================
CREATE PROCEDURE [mrs].[sub_FindColumnPropertiesByCode]
    -- === Input Parameters ===
    -- Parameter to filter the extended property name (interpreted as 'Column Code')
    @myVarVARCHARParamColumnCode NVARCHAR(128),
    -- Parameter to enable/disable debug messages (1 for debug, 0 for silent)
    @myVarBITDebugMode BIT = 0
AS
BEGIN
    -- === Local Variables ===
    -- Variable to store the start time for duration calculation in debug mode
    DECLARE @myVarDATETIMEStartTime DATETIME2;
    -- Variable for constructing debug messages
    DECLARE @myVarVARCHARMessage NVARCHAR(MAX);

    -- Setting the start time
    SET @myVarDATETIMEStartTime = SYSUTCDATETIME(); -- Assign current UTC time to the variable

    -- Improve performance by preventing the 'xx rows affected' messages
    SET NOCOUNT ON;

    -- === Debug: Print start message ===
    -- Check if debug mode is enabled
    IF @myVarBITDebugMode = 1
    BEGIN
        -- Construct and print the start message including the timestamp
        SET @myVarVARCHARMessage = CONCAT(N'Starting execution at: ', CONVERT(VARCHAR, @myVarDATETIMEStartTime, 121));
        PRINT @myVarVARCHARMessage;
        PRINT N'-- Parameters: @myVarVARCHARParamColumnCode = ''' + ISNULL(@myVarVARCHARParamColumnCode, N'NULL') + ''', @myVarBITDebugMode = ' + CAST(@myVarBITDebugMode AS VARCHAR);
        PRINT N'-- Action: Searching for extended properties on columns in schema [mrs] where property name (Column Code) LIKE @myVarVARCHARParamColumnCode.';
    END

    -- === Main Logic ===
    BEGIN TRY
        -- Select information about extended properties attached to columns
        -- matching the specified name pattern (interpreted as 'Column Code')
        -- within the 'mrs' schema.
        SELECT
            [s].[name] AS [SchemaName],         -- Schema of the table
            [t].[name] AS [TableName],          -- Actual name of the table the column belongs to
            [c].[name] AS [ColumnName],         -- Actual name of the column the property is attached to
            [ep].[name] AS [ColumnCode],        -- Name of the extended property (used as 'Column Code')
            CAST([ep].[value] AS NVARCHAR(MAX)) AS [PropertyValue]     -- Value of the extended property
        FROM
            -- Source table for extended properties
            [sys].[extended_properties] AS [ep]
        INNER JOIN
            -- Join with columns based on object ID and column ID
            [sys].[columns] AS [c] ON [ep].[major_id] = [c].[object_id] AND [ep].[minor_id] = [c].[column_id]
        INNER JOIN
            -- Join with tables based on object ID
            [sys].[tables] AS [t] ON [c].[object_id] = [t].[object_id]
        INNER JOIN
            -- Join with schemas based on schema ID
            [sys].[schemas] AS [s] ON [t].[schema_id] = [s].[schema_id]
        WHERE
            -- Filter for properties specifically attached to columns (class=1 means object/column, minor_id > 0 means column)
            [ep].[class] = 1 AND [ep].[minor_id] > 0
            -- Filter for the specified schema 'mrs'
            AND [s].[name] = N'mrs'
            -- Filter for property names (interpreted as 'Column Code') matching the input pattern
            AND [ep].[name] LIKE @myVarVARCHARParamColumnCode
        ORDER BY
            -- Order results by Property Name ('Column Code') ascending as requested
            [ColumnCode] ASC;

    END TRY
    -- === Error Handling ===
    BEGIN CATCH
        -- Print error details if an exception occurs
        PRINT N'ERROR: An error occurred during execution.';
        PRINT N'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR);
        PRINT N'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR);
        PRINT N'Error State: ' + CAST(ERROR_STATE() AS VARCHAR);
        PRINT N'Error Procedure: ' + ISNULL(ERROR_PROCEDURE(), N'N/A');
        PRINT N'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR);
        PRINT N'Error Message: ' + ERROR_MESSAGE();

        -- === Debug: Print error completion message ===
        -- Check if debug mode is enabled
        IF @myVarBITDebugMode = 1
        BEGIN
            DECLARE @myVarDATETIMEErrorTime DATETIME2 = SYSUTCDATETIME(); -- Get time of error
            -- Construct and print the error completion message
            SET @myVarVARCHARMessage = CONCAT(N'Execution failed at: ', CONVERT(VARCHAR, @myVarDATETIMEErrorTime, 121));
            PRINT @myVarVARCHARMessage;
        END;

        -- Re-throw the error so the calling application knows the procedure failed
        THROW;
    END CATCH

    -- === Debug: Print successful completion message ===
    -- Check if debug mode is enabled AND no error occurred previously (@@ERROR is 0 within this scope if CATCH was not executed)
    IF @myVarBITDebugMode = 1 AND @@ERROR = 0 -- @@ERROR check might be redundant after TRY/CATCH but adds clarity
    BEGIN
         DECLARE @myVarDATETIMEEndTime DATETIME2 = SYSUTCDATETIME(); -- Get the end time
         DECLARE @myVarINTDurationMs INT = DATEDIFF(MILLISECOND, @myVarDATETIMEStartTime, @myVarDATETIMEEndTime); -- Calculate duration
         -- Construct and print the success message including timestamp and duration
         SET @myVarVARCHARMessage = CONCAT(N'Finished execution successfully at: ', CONVERT(VARCHAR, @myVarDATETIMEEndTime, 121), N'. Duration: ', CAST(@myVarINTDurationMs AS VARCHAR), N' ms.');
         PRINT @myVarVARCHARMessage;
    END

    -- Restore default row count behavior
    SET NOCOUNT OFF;
END;
GO -- End of stored procedure definition

/*
-- =============================================
-- Usage Examples
-- =============================================
-- Prerequisites: Ensure you are in the context of the [SigmaTB] database.
--                The [mrs] schema and the procedure [mrs].[sub_FindColumnPropertiesByCode] must exist.
--                Extended properties must be defined on columns within the [mrs] schema where the *name*
--                of the property represents the 'Column Code' you want to search for.

-- Example 1: Find all extended properties for columns in schema 'mrs'
--            where the property name (Column Code) starts with 'FK_' (Debug mode OFF)
-- Note: This assumes you use property names like 'FK_UserID', 'FK_OrderID' as your 'Column Codes'.
EXEC [mrs].[sub_FindColumnPropertiesByCode] @myVarVARCHARParamColumnCode = N'FK_%', @myVarBITDebugMode = 0;

-- Example 2: Find all extended properties for columns in schema 'mrs'
--            where the property name (Column Code) is exactly 'LegacyRefID' (Debug mode ON)
EXEC [mrs].[sub_FindColumnPropertiesByCode] @myVarVARCHARParamColumnCode = N'%ORD%', @myVarBITDebugMode = 1;

-- Example 3: Find properties where the name (Column Code) contains 'Description' (Case sensitivity depends on collation)
-- Note: This would find properties named 'MS_Description', 'ColumnDescription', etc.
EXEC [mrs].[sub_FindColumnPropertiesByCode] @myVarVARCHARParamColumnCode = N'%Description%', @myVarBITDebugMode = 1;

-- Example 4: Find the standard MS_Description property if it's used as a 'Column Code'
EXEC [mrs].[sub_FindColumnPropertiesByCode] @myVarVARCHARParamColumnCode = N'MS_Description', @myVarBITDebugMode = 0;

*/
GO