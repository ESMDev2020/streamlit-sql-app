-- CLAUDE , FK detection for value match

USE [SigmaTB]; -- Ensure the correct database context
GO

-- =============================================
-- Author:      Gemini AI (Modified by Claude)
-- Create date: 2025-05-04
--				FINDS COLUMNS IN OTHER TABLES LIKE THE ONE WE ARE AUDITING
-- Description: Finds extended properties attached to columns within the 'mrs' schema
--              where the property name matches a given pattern (@myVarVARCHARParamColumnCode).
--              It lists the schema, table, column name, property name (interpreted as 'Column Code'),
--              property value, and now includes the minimum and maximum distinct values for each column.
--              The procedure also identifies if the column is a primary key or foreign key and checks
--              if the values match with known primary keys stored in mrs.PKRangeResults.
--              The results are ordered by the property name.
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
--              PropertyName (used as 'Column Code' for filtering and sorting), PropertyValue,
--              IsPrimaryKey (Yes/No), ValuesMatchPK (Yes/No),
--              MaxDistinctValue, MinDistinctValue.
-- =============================================
CREATE OR ALTER PROCEDURE [mrs].[sub_FindColumnPropertiesByCode]
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
    -- Variables for dynamic SQL
    DECLARE @myVarNvarSQL NVARCHAR(MAX);
    -- Variables for table and column info
    DECLARE @myVarNvarSchemaName NVARCHAR(128);
    DECLARE @myVarNvarTableName NVARCHAR(128);
    DECLARE @myVarNvarColumnName NVARCHAR(128);
    DECLARE @myVarNvarFullTableName NVARCHAR(257); -- Schema + Table with brackets
    
    -- Check if the PKRangeResults table exists
    DECLARE @myVarBITTableExists BIT = 0;
    IF EXISTS (SELECT 1 FROM sys.tables t 
               INNER JOIN sys.schemas s ON t.schema_id = s.schema_id 
               WHERE t.name = 'PKRangeResults' AND s.name = 'mrs')
    BEGIN
        SET @myVarBITTableExists = 1;
        
        IF @myVarBITDebugMode = 1
        BEGIN
            PRINT N'PKRangeResults table found - will check for PK matching.';
        END
    END
    ELSE
    BEGIN
        IF @myVarBITDebugMode = 1
        BEGIN
            PRINT N'WARNING: PKRangeResults table not found - PK checking will be skipped.';
        END
    END

    -- Create a temporary table to store results with MIN/MAX values and PK information
    CREATE TABLE #ColumnResults (
        [SchemaName] NVARCHAR(128),
        [TableName] NVARCHAR(128),
        [ColumnName] NVARCHAR(128),
        [ColumnCode] NVARCHAR(128),
        [PropertyValue] NVARCHAR(MAX),
        [IsPrimaryKey] NVARCHAR(3) DEFAULT 'No',
        [ValuesMatchPK] NVARCHAR(3) DEFAULT 'No',
        [MinDistinctValue] NVARCHAR(255),
        [MaxDistinctValue] NVARCHAR(255),
        [IsError] BIT,
        [ErrorMessage] NVARCHAR(MAX)
    );

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
        -- First, get all columns with the matching property name
        -- and insert them into our temporary results table
        INSERT INTO #ColumnResults ([SchemaName], [TableName], [ColumnName], [ColumnCode], [PropertyValue], [MinDistinctValue], [MaxDistinctValue], [IsError], [ErrorMessage])
        SELECT
            [s].[name] AS [SchemaName],         -- Schema of the table
            [t].[name] AS [TableName],          -- Actual name of the table the column belongs to
            [c].[name] AS [ColumnName],         -- Actual name of the column the property is attached to
            [ep].[name] AS [ColumnCode],        -- Name of the extended property (used as 'Column Code')
            CAST([ep].[value] AS NVARCHAR(MAX)) AS [PropertyValue], -- Value of the extended property
            NULL AS [MinDistinctValue],         -- Placeholder for minimum distinct value (to be updated)
            NULL AS [MaxDistinctValue],         -- Placeholder for maximum distinct value (to be updated)
            0 AS [IsError],                     -- Flag to indicate error status (0 = no error)
            NULL AS [ErrorMessage]              -- Field to store error messages if any
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
            AND [ep].[name] LIKE @myVarVARCHARParamColumnCode;

        -- Debug: Print number of columns found
        IF @myVarBITDebugMode = 1
        BEGIN
            DECLARE @myVarINTColumnCount INT = (SELECT COUNT(*) FROM #ColumnResults);
            PRINT N'Found ' + CAST(@myVarINTColumnCount AS NVARCHAR) + N' columns with matching property name.';
        END

        -- Now, for each column, get the MIN and MAX distinct values
        -- Create a cursor to loop through each schema, table, column combination
        DECLARE column_cursor CURSOR FOR
        SELECT [SchemaName], [TableName], [ColumnName] FROM #ColumnResults;

        -- Open the cursor
        OPEN column_cursor;

        -- Fetch the first row
        FETCH NEXT FROM column_cursor INTO @myVarNvarSchemaName, @myVarNvarTableName, @myVarNvarColumnName;

        -- Loop through all rows
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Debug: Print current column being processed
            IF @myVarBITDebugMode = 1
            BEGIN
                PRINT N'Processing column: [' + @myVarNvarSchemaName + N'].[' + @myVarNvarTableName + N'].[' + @myVarNvarColumnName + N']';
            END

            -- Construct the full table name
            SET @myVarNvarFullTableName = QUOTENAME(@myVarNvarSchemaName) + N'.' + QUOTENAME(@myVarNvarTableName);

            -- Construct dynamic SQL to get MIN and MAX values
            -- Using dynamic SQL to handle different data types and avoid conversion errors
            SET @myVarNvarSQL = N'
            BEGIN TRY
                UPDATE #ColumnResults
                SET 
                    [MinDistinctValue] = CONVERT(NVARCHAR(255), (SELECT MIN(' + QUOTENAME(@myVarNvarColumnName) + ') FROM ' + @myVarNvarFullTableName + ' WHERE ' + QUOTENAME(@myVarNvarColumnName) + ' IS NOT NULL)),
                    [MaxDistinctValue] = CONVERT(NVARCHAR(255), (SELECT MAX(' + QUOTENAME(@myVarNvarColumnName) + ') FROM ' + @myVarNvarFullTableName + ' WHERE ' + QUOTENAME(@myVarNvarColumnName) + ' IS NOT NULL)),
                    [IsError] = 0,
                    [ErrorMessage] = NULL
                WHERE
                    [SchemaName] = ''' + REPLACE(@myVarNvarSchemaName, '''', '''''') + ''' AND
                    [TableName] = ''' + REPLACE(@myVarNvarTableName, '''', '''''') + ''' AND
                    [ColumnName] = ''' + REPLACE(@myVarNvarColumnName, '''', '''''') + ''';
            END TRY
            BEGIN CATCH
                UPDATE #ColumnResults
                SET 
                    [MinDistinctValue] = ''ERROR'',
                    [MaxDistinctValue] = ''ERROR'',
                    [IsError] = 1,
                    [ErrorMessage] = ERROR_MESSAGE()
                WHERE
                    [SchemaName] = ''' + REPLACE(@myVarNvarSchemaName, '''', '''''') + ''' AND
                    [TableName] = ''' + REPLACE(@myVarNvarTableName, '''', '''''') + ''' AND
                    [ColumnName] = ''' + REPLACE(@myVarNvarColumnName, '''', '''''') + ''';
            END CATCH';

            -- Execute the dynamic SQL
            BEGIN TRY
                EXEC sp_executesql @myVarNvarSQL;
                
                -- Debug: Print success message
                IF @myVarBITDebugMode = 1
                BEGIN
                    PRINT N'  Successfully retrieved MIN/MAX values for column.';
                END
            END TRY
            BEGIN CATCH
                -- If the dynamic SQL execution itself fails, update the record
                UPDATE #ColumnResults
                SET 
                    [MinDistinctValue] = 'EXEC ERROR',
                    [MaxDistinctValue] = 'EXEC ERROR',
                    [IsError] = 1,
                    [ErrorMessage] = 'Execute SQL error: ' + ERROR_MESSAGE()
                WHERE
                    [SchemaName] = @myVarNvarSchemaName AND
                    [TableName] = @myVarNvarTableName AND
                    [ColumnName] = @myVarNvarColumnName;
                
                -- Debug: Print error message
                IF @myVarBITDebugMode = 1
                BEGIN
                    PRINT N'  ERROR executing SQL for column: ' + ERROR_MESSAGE();
                END
            END CATCH

            -- Fetch the next row
            FETCH NEXT FROM column_cursor INTO @myVarNvarSchemaName, @myVarNvarTableName, @myVarNvarColumnName;
        END

        -- Close and deallocate the cursor
        CLOSE column_cursor;
        DEALLOCATE column_cursor;

        -- Check if the column is a primary key by looking at PKRangeResults table
        IF @myVarBITTableExists = 1
        BEGIN
            -- Update IsPrimaryKey flag for columns that exist in PKRangeResults
            UPDATE cr
            SET cr.[IsPrimaryKey] = 'Yes'
            FROM #ColumnResults cr
            INNER JOIN mrs.PKRangeResults pk 
                ON pk.[TableName] = cr.[TableName]
                AND pk.[ColumnPK] = cr.[ColumnName];

            IF @myVarBITDebugMode = 1
            BEGIN
                DECLARE @myVarINTPKCount INT = (SELECT COUNT(*) FROM #ColumnResults WHERE [IsPrimaryKey] = 'Yes');
                PRINT N'Found ' + CAST(@myVarINTPKCount AS NVARCHAR) + N' primary key columns.';
            END

            -- For each column that is not a primary key, check if its values match any primary key values
            DECLARE value_match_cursor CURSOR FOR
            SELECT cr.[SchemaName], cr.[TableName], cr.[ColumnName] 
            FROM #ColumnResults cr
            WHERE cr.[IsPrimaryKey] = 'No';

            OPEN value_match_cursor;

            FETCH NEXT FROM value_match_cursor INTO @myVarNvarSchemaName, @myVarNvarTableName, @myVarNvarColumnName;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                -- For each column, check if it potentially matches any primary key range in PKRangeResults
                DECLARE @myVarNvarMinValue NVARCHAR(255);
                DECLARE @myVarNvarMaxValue NVARCHAR(255);

                -- Get the min/max values for the current column
                SELECT @myVarNvarMinValue = [MinDistinctValue], @myVarNvarMaxValue = [MaxDistinctValue]
                FROM #ColumnResults 
                WHERE [SchemaName] = @myVarNvarSchemaName 
                  AND [TableName] = @myVarNvarTableName 
                  AND [ColumnName] = @myVarNvarColumnName;

                -- Skip error values
                IF @myVarNvarMinValue <> 'ERROR' AND @myVarNvarMaxValue <> 'ERROR' 
                   AND @myVarNvarMinValue <> 'EXEC ERROR' AND @myVarNvarMaxValue <> 'EXEC ERROR'
                BEGIN
                    -- If column values fall within any primary key's range, mark it as a potential foreign key
                    UPDATE cr
                    SET cr.[ValuesMatchPK] = 'Yes'
                    FROM #ColumnResults cr
                    WHERE cr.[SchemaName] = @myVarNvarSchemaName
                      AND cr.[TableName] = @myVarNvarTableName
                      AND cr.[ColumnName] = @myVarNvarColumnName
                      AND EXISTS (
                          SELECT 1 
                          FROM mrs.PKRangeResults pk
                          WHERE 
                          -- Check if the range overlaps (one of these conditions must be true)
                          -- This is a simplified check to detect potential FK relationships
                          (
                              -- Handle NULL values gracefully
                              (@myVarNvarMinValue IS NOT NULL AND pk.[LowestValue] IS NOT NULL AND 
                               @myVarNvarMaxValue IS NOT NULL AND pk.[HighestValue] IS NOT NULL)
                              AND
                              -- Simple range overlap check
                              (@myVarNvarMinValue <= pk.[HighestValue] AND @myVarNvarMaxValue >= pk.[LowestValue])
                          )
                      );
                END

                -- Debug: Print current column being checked for value matches
                IF @myVarBITDebugMode = 1
                BEGIN
                    DECLARE @myVarNvarMatchStatus NVARCHAR(3) = (
                        SELECT [ValuesMatchPK] 
                        FROM #ColumnResults 
                        WHERE [SchemaName] = @myVarNvarSchemaName 
                          AND [TableName] = @myVarNvarTableName 
                          AND [ColumnName] = @myVarNvarColumnName
                    );
                    
                    PRINT N'Checked column for PK value match: [' + @myVarNvarSchemaName + N'].[' + 
                          @myVarNvarTableName + N'].[' + @myVarNvarColumnName + N'] - Match: ' + 
                          @myVarNvarMatchStatus;
                END

                FETCH NEXT FROM value_match_cursor INTO @myVarNvarSchemaName, @myVarNvarTableName, @myVarNvarColumnName;
            END

            CLOSE value_match_cursor;
            DEALLOCATE value_match_cursor;
        END

        -- Return the final results
        SELECT
            [SchemaName],
            [TableName],
            [ColumnName],
            [ColumnCode],
            [PropertyValue],
            [IsPrimaryKey],
            [ValuesMatchPK],
            [MinDistinctValue],
            [MaxDistinctValue]
        FROM
            #ColumnResults
        ORDER BY
            -- Order results by Property Name ('Column Code') ascending as requested
            [ColumnCode] ASC;

    END TRY
    -- === Error Handling ===
    BEGIN CATCH
        -- Close and deallocate cursors if they're still open
        IF CURSOR_STATUS('global', 'column_cursor') >= 0
        BEGIN
            CLOSE column_cursor;
            DEALLOCATE column_cursor;
        END
        
        IF CURSOR_STATUS('global', 'value_match_cursor') >= 0
        BEGIN
            CLOSE value_match_cursor;
            DEALLOCATE value_match_cursor;
        END

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
    -- Check if debug mode is enabled AND no error occurred previously
    IF @myVarBITDebugMode = 1 AND @@ERROR = 0
    BEGIN
        DECLARE @myVarDATETIMEEndTime DATETIME2 = SYSUTCDATETIME(); -- Get the end time
        DECLARE @myVarINTDurationMs INT = DATEDIFF(MILLISECOND, @myVarDATETIMEStartTime, @myVarDATETIMEEndTime); -- Calculate duration
        -- Construct and print the success message including timestamp and duration
        SET @myVarVARCHARMessage = CONCAT(N'Finished execution successfully at: ', CONVERT(VARCHAR, @myVarDATETIMEEndTime, 121), N'. Duration: ', CAST(@myVarINTDurationMs AS VARCHAR), N' ms.');
        PRINT @myVarVARCHARMessage;
    END

    -- Clean up the temporary table
    DROP TABLE #ColumnResults;

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
EXEC [mrs].[sub_FindColumnPropertiesByCode] @myVarVARCHARParamColumnCode = N'%ORDR%', @myVarBITDebugMode = 0;
--N'FK_%'
-- Example 2: Find all extended properties for columns in schema 'mrs'
--            where the property name (Column Code) contains 'ORD' (Debug mode ON)
EXEC [mrs].[sub_FindColumnPropertiesByCode] @myVarVARCHARParamColumnCode = N'%ORD%', @myVarBITDebugMode = 1;

-- Example 3: Find properties where the name (Column Code) contains 'Description' (Case sensitivity depends on collation)
-- Note: This would find properties named 'MS_Description', 'ColumnDescription', etc.
EXEC [mrs].[sub_FindColumnPropertiesByCode] @myVarVARCHARParamColumnCode = N'%Description%', @myVarBITDebugMode = 1;

-- Example 4: Find the standard MS_Description property if it's used as a 'Column Code'
EXEC [mrs].[sub_FindColumnPropertiesByCode] @myVarVARCHARParamColumnCode = N'MS_Description', @myVarBITDebugMode = 0;

-- Example Results (Sample output):
/*
SchemaName  TableName   ColumnName    ColumnCode       PropertyValue              IsPrimaryKey  ValuesMatchPK  MinDistinctValue  MaxDistinctValue
----------- ----------- ------------- ---------------- -------------------------- ------------- -------------- ----------------- -----------------
mrs         Orders      OrderID       ORD_PrimaryKey   Primary key for Orders     Yes           No             1000001           9999999
mrs         Orders      CustomerID    FK_CustomerID    Foreign key to Customers   No            Yes            CUST001           CUST999
mrs         Orders      StatusCode    ORD_StatusCode   Order status identifier    No            No             CANCELED          SHIPPED
mrs         Customers   CustomerID    CUST_PrimaryKey  Primary key for Customers  Yes           No             CUST001           CUST999
mrs         Products    ProductCode   PROD_Code        Product identifier code    No            No             A001-XZ           Z999-YY
mrs         Inventory   CustomerID    FK_CustID        Reference to customer      No            Yes            CUST010           CUST950
*/
*/
GO