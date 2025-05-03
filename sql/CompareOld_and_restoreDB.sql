/*************************************************************************************************
* Script: Compare Table Row Counts (NO RPC VERSION)                                            *
* Purpose: Compares row counts between local and remote DB using only four-part naming.        *
* Assumes Linked Server has Data Access enabled, but RPC Out is disabled.                    *
*************************************************************************************************/

-- ==================================
-- START CONFIGURATION - MODIFY THESE
-- ==================================
DECLARE @NewServerLinkedName NVARCHAR(128) = N'SigmaTB_Restore';  -- Linked Server name pointing to the NEW/Restored server
DECLARE @DatabaseName NVARCHAR(128) = N'SigmaTB';            -- Database name (MUST be the same name used on BOTH servers)
DECLARE @SchemaName NVARCHAR(128) = N'mrs';                 -- Schema containing the tables to compare
-- ==================================
-- END CONFIGURATION
-- ==================================

-- Print confirmation of execution context and parameters
SELECT
    @@SERVERNAME AS [Current Server],
    DB_NAME() AS [Current Database],
    @SchemaName AS [Schema Being Compared],
    @NewServerLinkedName AS [Linked Server Name];
PRINT '-----------------------------------------------------------------------';
/*
Current Server	Current Database	Schema Being Compared	Linked Server Name
EC2AMAZ-7QANEJ3	SigmaTB	mrs	SigmaTB_Restore
*/


-- Step 1: Set context to the OLD database ON THE CURRENTLY CONNECTED SERVER
-- Make SURE you are connected to your OLD server in SSMS.
USE [SigmaTB]; -- Uses the @DatabaseName variable
GO

-- Step 2: Verify prerequisites locally
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'mrs') -- Use variable @SchemaName
BEGIN
    PRINT N'ERROR: Schema [' + N'mrs' + '] does not exist in the local database [' + N'SigmaTB' + ']!';
    RAISERROR('Schema does not exist locally. Script terminated.', 16, 1);
    RETURN;
END

IF NOT EXISTS (SELECT 1 FROM sys.servers WHERE name = N'SigmaTB_Restore') -- Use variable @NewServerLinkedName
BEGIN
    PRINT N'ERROR: Linked server [' + N'SigmaTB_Restore' + '] is not configured!';
    RAISERROR('Linked server not found. Script terminated.', 16, 1);
    RETURN;
END
PRINT N'Local schema and linked server verified.';
/*
Local schema and linked server verified.

Completion time: 2025-05-03T04:12:03.2371539-05:00
*/


-- Step 3: Set up results table
IF OBJECT_ID('tempdb..#CompareResults') IS NOT NULL
BEGIN
    PRINT N'Dropping existing #CompareResults temp table.';
    DROP TABLE #CompareResults;
END
CREATE TABLE #CompareResults (
    table_name NVARCHAR(256),
    rowcount_original BIGINT NULL,
    rowcount_restored BIGINT NULL,
    status VARCHAR(50)
);
PRINT N'Temporary results table #CompareResults created.';
-- runs ok

-- Step 4: Prepare variables for the loop
DECLARE @tableName NVARCHAR(256);
DECLARE @sql NVARCHAR(MAX);
DECLARE @fourPartRemoteBase NVARCHAR(512);

-- Construct the correctly quoted four-part base name for remote DB reference
-- Example result: [SigmaTB_Restore].[SigmaTB]
SET @fourPartRemoteBase = QUOTENAME(N'SigmaTB_Restore') + N'.' + QUOTENAME(N'SigmaTB'); -- Use variables @NewServerLinkedName, @DatabaseName

-- Step 5: Declare cursor for tables in the local schema
PRINT N'Declaring cursor to find tables in schema [' + N'mrs' + '] locally...'; -- Use variable @SchemaName
DECLARE table_cursor CURSOR FOR
SELECT t.name
FROM sys.tables AS t
WHERE SCHEMA_NAME(t.schema_id) = N'mrs' -- Use variable @SchemaName
ORDER BY t.name;

-- Step 6: Open and process the cursor
OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @tableName;

IF @@FETCH_STATUS <> 0
    PRINT N'>>> WARNING: No tables found in schema [' + N'mrs' + '] for the current database context!'; -- Use variable @SchemaName

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT N'>>> Processing table: [' + N'mrs' + '].[' + @tableName + ']...'; -- Use variable @SchemaName

    -- Build the dynamic SQL statement to be executed LOCALLY
    -- This dynamic SQL uses four-part naming to query the remote server
    SET @sql = N'
        DECLARE @original_count BIGINT = NULL;
        DECLARE @restored_count BIGINT = NULL;
        DECLARE @current_table_name NVARCHAR(256) = N''' + REPLACE(@tableName, '''', '''''') + ''';
        DECLARE @current_schema_name NVARCHAR(128) = N''' + N'mrs' + '''; -- Use variable @SchemaName
        DECLARE @local_object_id INT = NULL;
        DECLARE @remote_object_id INT = NULL;

        -- Get local object_id and count using sys.partitions
        BEGIN TRY
            SELECT @local_object_id = o.object_id
            FROM sys.objects AS o
            INNER JOIN sys.schemas AS s ON o.schema_id = s.schema_id
            WHERE o.name = @current_table_name AND s.name = @current_schema_name AND o.type = ''U''; -- U = User Table

            IF @local_object_id IS NOT NULL
                SELECT @original_count = SUM(p.rows)
                FROM sys.partitions AS p
                WHERE p.object_id = @local_object_id AND p.index_id IN (0, 1); -- 0=Heap, 1=Clustered Index
            ELSE
                SET @original_count = -1; -- Not found locally

            -- If table exists but has no rows/partitions, SUM might be NULL. Treat as 0 unless table itself was missing.
            SET @original_count = ISNULL(@original_count, 0);
            IF @local_object_id IS NULL SET @original_count = -1;

        END TRY
        BEGIN CATCH
            PRINT N''   - Error getting local count for '' + QUOTENAME(@current_schema_name) + N''.'' + QUOTENAME(@current_table_name) + N'': '' + ERROR_MESSAGE();
            SET @original_count = -2; -- Indicate specific error getting local count
        END CATCH

        -- Get remote object_id and count using sys.partitions via four-part naming
        BEGIN TRY
            -- Find remote object_id using four-part naming
            SELECT @remote_object_id = o.object_id
            FROM ' + @fourPartRemoteBase + N'.sys.objects AS o
            INNER JOIN ' + @fourPartRemoteBase + N'.sys.schemas AS s ON o.schema_id = s.schema_id
            WHERE o.name = @current_table_name AND s.name = @current_schema_name AND o.type = ''U'';

            IF @remote_object_id IS NOT NULL
                -- Get remote count using four-part naming
                SELECT @restored_count = SUM(p.rows)
                FROM ' + @fourPartRemoteBase + N'.sys.partitions AS p
                WHERE p.object_id = @remote_object_id AND p.index_id IN (0, 1);
            ELSE
                SET @restored_count = -1; -- Not found remotely

            -- If table exists but has no rows/partitions, SUM might be NULL. Treat as 0 unless table itself was missing.
            SET @restored_count = ISNULL(@restored_count, 0);
            IF @remote_object_id IS NULL SET @restored_count = -1;

        END TRY
        BEGIN CATCH
            PRINT N''   - Error getting remote count for '' + QUOTENAME(@current_schema_name) + N''.'' + QUOTENAME(@current_table_name) + N'' via linked server: '' + ERROR_MESSAGE();
            SET @restored_count = -2; -- Indicate specific error getting remote count
        END CATCH

        -- Insert results into the temp table
        INSERT INTO #CompareResults (table_name, rowcount_original, rowcount_restored, status)
        VALUES (
            @current_table_name,
            @original_count,
            @restored_count,
            CASE
                WHEN @original_count = -2 OR @restored_count = -2 THEN N''‼️ Error During Count''
                WHEN @original_count = -1 AND @restored_count = -1 THEN N''❓ Missing Both Sides''
                WHEN @original_count = -1 THEN N''❓ Missing Locally''
                WHEN @restored_count = -1 THEN N''❓ Missing Remotely''
                WHEN @original_count = @restored_count THEN N''✅ Match''
                ELSE N''❌ No Match ('' + CONVERT(VARCHAR(20), @original_count) + N'' vs '' + CONVERT(VARCHAR(20), @restored_count) + N'')''
            END
        );
    '; -- End of dynamic SQL string

    -- Execute the dynamic SQL LOCALLY. It contains the four-part queries.
    BEGIN TRY
        EXEC sp_executesql @sql;
    END TRY
    BEGIN CATCH
        PRINT N'>>> CRITICAL ERROR executing dynamic SQL for table: [' + @tableName + N']. Skipping this table.';
        PRINT N'   Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(20));
        PRINT N'   Error Message: ' + ERROR_MESSAGE();
        PRINT N'--- Start Failing SQL ---';
        PRINT @sql; -- Print the exact SQL that failed
        PRINT N'--- End Failing SQL ---';
        IF NOT EXISTS (SELECT 1 FROM #CompareResults WHERE table_name = @tableName)
             INSERT INTO #CompareResults (table_name, status) VALUES (@tableName, N'‼️ SQL Exec Error');
    END CATCH

    FETCH NEXT FROM table_cursor INTO @tableName;
END -- End of WHILE loop

PRINT N'>>> Cursor loop finished.';

-- Step 7: Clean up the cursor
CLOSE table_cursor;
DEALLOCATE table_cursor;
PRINT N'Cursor closed and deallocated.';

-- Step 8: Final output
PRINT N'--------------------------------------------------------------------------';
PRINT N'>>> Selecting final comparison results...';
-- (Status code descriptions remain the same)
PRINT N'Status Codes:'
PRINT N'   ✅ Match: Row counts are identical.';
PRINT N'   ❌ No Match (Local vs Remote): Row counts differ.';
PRINT N'   ❓ Missing Locally: Table not found locally (or error) but exists remotely.';
PRINT N'   ❓ Missing Remotely: Table found locally but not remotely (or error).';
PRINT N'   ❓ Missing Both Sides: Table not found (or error) on either side.';
PRINT N'   ‼️ Error During Count: An error occurred trying to query row counts (check messages).';
PRINT N'   ‼️ SQL Exec Error: A critical error occurred executing the dynamic SQL for the table (check messages).';
PRINT N'--------------------------------------------------------------------------';

SELECT table_name,
       rowcount_original,
       rowcount_restored,
       status
FROM #CompareResults
ORDER BY CASE status
            WHEN N'✅ Match' THEN 5
            WHEN N'❌ No Match' THEN 1
            WHEN N'❓ Missing Remotely' THEN 2
            WHEN N'❓ Missing Locally' THEN 3
            WHEN N'❓ Missing Both Sides' THEN 4
            ELSE 0 -- Errors highest priority
         END,
         table_name;

GO

-- Step 9: Clean up the temp table (optional)
-- IF OBJECT_ID('tempdb..#CompareResults') IS NOT NULL DROP TABLE #CompareResults;
-- PRINT N'Temp table #CompareResults dropped.';