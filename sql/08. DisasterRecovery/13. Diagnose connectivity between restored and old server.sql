-- STEP 1: Create the linked server
EXEC sp_addlinkedserver   
   @server = 'SigmaTB_Restore',   -- Friendly name
   @srvproduct = '',  
   @provider = 'SQLNCLI',  
   @datasrc = 'sigmatbrestored.c67ymu6q22o1.us-east-1.rds.amazonaws.com';

-- STEP 2: Add login mapping
EXEC sp_addlinkedsrvlogin   
   @rmtsrvname = 'SigmaTB_Restore',   
   @useself = 'false',   
   @rmtuser = 'admin',   
   @rmtpassword = 'Er1c41234$';

-- STEP 3: Test the connection (fixed line)
EXEC sp_testlinkedserver @servername = 'SigmaTB_Restore';

-- Test
SELECT TOP 5 *
FROM [SigmaTB_Restore].[SigmaTB].sys.tables;





-- Compare tables
-- Set up results table
-- Compare tables
-- Set up results table

/*************************************************************************************************
* Script: Compare Table Row Counts Between Local/Old DB and Remote/New DB via Linked Server    *
* *
* Purpose: Iterates through tables in a specified schema of the local database, compares       *
* their row counts with corresponding tables in a remote database (accessed via a     *
* linked server), and reports the results.                                            *
* *
* Prerequisites:                                                                               *
* 1. Run this script while connected to the OLD/Source SQL Server instance in SSMS.        *
* 2. A Linked Server must be configured on the OLD server pointing to the NEW server.      *
* 3. The login used for the linked server connection needs appropriate permissions         *
* (CONNECT, VIEW DATABASE STATE, SELECT on system views & user tables) on the NEW DB.   *
* 4. The login running this script needs permissions on the OLD DB and permissions         *
* to use the Linked Server (often sysadmin or specific EXECUTE permissions).            *
* *
*************************************************************************************************/

-- ==================================
-- START CONFIGURATION
-- ==================================

DECLARE @NewServerLinkedName NVARCHAR(128) = N'SigmaTB_Restore'; -- <<< Linked Server name pointing to the NEW/Restored server
DECLARE @DatabaseName NVARCHAR(128) = N'SigmaTB';          -- <<< Database name (MUST be the same name used on BOTH servers)
DECLARE @SchemaName NVARCHAR(128) = N'mrs';                -- <<< Schema containing the tables to compare

-- ==================================
-- END CONFIGURATION
-- ==================================

-- == DO NOT MODIFY BELOW THIS LINE unless you understand the script's logic ==

-- Step 1: Explicitly set context to the OLD database ON THE CURRENTLY CONNECTED SERVER
-- Make SURE you are connected to your OLD server in SSMS when running this whole script
USE [SigmaTB]; -- <<< Uses the @DatabaseName variable defined above
GO

PRINT N'Starting Table Row Count Comparison script.';
PRINT N'Comparing schema [' + N'mrs' + N'] in database [' + N'SigmaTB' + N'] on local server'; -- Hardcoded variables for clarity
PRINT N'With schema [' + N'mrs' + N'] in database [' + N'SigmaTB' + N'] on linked server [' + N'SigmaTB_Restore' + N']'; -- Hardcoded variables for clarity
PRINT N'--------------------------------------------------------------------------';

-- Step 2: Set up results table
IF OBJECT_ID('tempdb..#CompareResults') IS NOT NULL
BEGIN
    PRINT N'Dropping existing #CompareResults temp table.';
    DROP TABLE #CompareResults;
END
CREATE TABLE #CompareResults (
    table_name NVARCHAR(256),
    rowcount_original BIGINT NULL, -- Allow NULLs initially
    rowcount_restored BIGINT NULL, -- Allow NULLs initially
    status VARCHAR(25) -- Increased size slightly
);
PRINT N'Temporary results table #CompareResults created.';

-- Step 3: Prepare variables for the loop
DECLARE @tableName NVARCHAR(256);
DECLARE @sql NVARCHAR(MAX);
DECLARE @restoredDbNameForSQL NVARCHAR(512);

-- Construct the correctly quoted four-part base name for the restored DB reference for use inside dynamic SQL
-- Example result: [SigmaTB_Restore].[SigmaTB]
SET @restoredDbNameForSQL = QUOTENAME(N'SigmaTB_Restore') + N'.' + QUOTENAME(N'SigmaTB'); -- Hardcoded variables for clarity

-- Step 4: Declare cursor for tables in the *current* database context (set by USE)
PRINT N'Declaring cursor to find tables in schema [' + N'mrs' + '] locally...'; -- Hardcoded variable for clarity
DECLARE table_cursor CURSOR FOR
SELECT t.name
FROM sys.tables AS t
WHERE SCHEMA_NAME(t.schema_id) = N'mrs' -- Hardcoded variable for clarity
ORDER BY t.name;

-- Step 5: Open and process the cursor
OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @tableName;

IF @@FETCH_STATUS <> 0
    PRINT N'>>> WARNING: No tables found in schema [' + N'mrs' + '] for the current database context!'; -- Hardcoded variable for clarity

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT N'>>> Processing table: [' + N'mrs' + '].[' + @tableName + ']...'; -- Hardcoded variable for clarity

    -- Build the dynamic SQL statement for each table
    SET @sql = N'
        DECLARE @original_count BIGINT = NULL;
        DECLARE @restored_count BIGINT = NULL;
        DECLARE @current_table_name NVARCHAR(256) = N''' + REPLACE(@tableName, '''', '''''') + '''; -- Handle quotes in table names
        DECLARE @current_schema_name NVARCHAR(128) = N''' + N'mrs' + '''; -- Hardcoded variable for clarity
        DECLARE @local_qualified_name NVARCHAR(386) = @current_schema_name + N''.'' + @current_table_name;

        -- Get original count (current DB context)
        BEGIN TRY
            SELECT @original_count = SUM(ps.row_count)
            FROM sys.dm_db_partition_stats ps
            WHERE ps.object_id = OBJECT_ID(@local_qualified_name) AND ps.index_id IN (0, 1); -- 0=Heap, 1=Clustered Index
        END TRY
        BEGIN CATCH
            PRINT N''   - Error getting local count for '' + @local_qualified_name + N'': '' + ERROR_MESSAGE();
            SET @original_count = -2; -- Indicate specific error getting local count
        END CATCH

        -- Get restored count (target DB via Linked Server)
        BEGIN TRY
            -- Find the object_id within the target DB using its metadata via linked server
            DECLARE @remote_object_id INT = NULL;
            SELECT @remote_object_id = t.object_id
            FROM ' + @restoredDbNameForSQL + N'.sys.tables t
            JOIN ' + @restoredDbNameForSQL + N'.sys.schemas s ON t.schema_id = s.schema_id
            WHERE t.name = @current_table_name COLLATE DATABASE_DEFAULT
              AND s.name = @current_schema_name COLLATE DATABASE_DEFAULT; -- Added COLLATE as safety measure

            IF @remote_object_id IS NOT NULL
            BEGIN
                SELECT @restored_count = SUM(ps.row_count)
                FROM ' + @restoredDbNameForSQL + N'.sys.dm_db_partition_stats ps
                WHERE ps.object_id = @remote_object_id AND ps.index_id IN (0, 1);
            END
            ELSE
            BEGIN
                 -- Table does not exist on remote server in that schema
                 SET @restored_count = -1; -- Use -1 to indicate Missing on Remote
                 PRINT N''   - Table '' + @current_table_name + N'' not found in schema '' + @current_schema_name + N'' on linked server.'';
            END
        END TRY
        BEGIN CATCH
            PRINT N''   - Error getting remote count for '' + @current_table_name + N'' via linked server: '' + ERROR_MESSAGE();
            SET @restored_count = -2; -- Indicate specific error getting remote count
        END CATCH

        -- Handle cases where table exists locally but not remotely (or vice versa implicitly)
        IF @original_count IS NULL AND @restored_count <> -1 -- Might happen if OBJECT_ID failed locally but table exists remotely
        BEGIN
             PRINT N''   - Table '' + @current_table_name + N'' not found locally in schema '' + @current_schema_name + N''. Setting local count to -1.'';
             SET @original_count = -1; -- Use -1 to indicate Missing Locally
        END

        -- Ensure NULLs are handled if errors didn''t set counts to -2 or table wasn't found (-1)
        SET @original_count = ISNULL(@original_count, -1); -- Default to missing if still NULL
        SET @restored_count = ISNULL(@restored_count, -1); -- Default to missing if still NULL (should be covered by logic above, but safer)


        -- Insert into results table
        INSERT INTO #CompareResults (table_name, rowcount_original, rowcount_restored, status)
        VALUES (
            @current_table_name,
            @original_count,
            @restored_count,
            CASE
                WHEN @original_count = -2 OR @restored_count = -2 THEN N''‼️ Error During Count''
                WHEN @original_count = -1 THEN N''❓ Missing Locally''
                WHEN @restored_count = -1 THEN N''❓ Missing Remotely''
                WHEN @original_count = @restored_count THEN N''✅ Match''
                ELSE N''❌ No Match ('' + CAST(@original_count AS VARCHAR(20)) + N'' vs '' + CAST(@restored_count AS VARCHAR(20)) + N'')''
            END
        );
    ';

    -- Optional: Print the dynamic SQL before executing for debugging
    -- PRINT @sql;

    -- Execute the dynamic SQL for the current table
    BEGIN TRY
        EXEC sp_executesql @sql;
    END TRY
    BEGIN CATCH
        PRINT N'>>> CRITICAL ERROR executing dynamic SQL for table: [' + @tableName + N']. Skipping this table.';
        PRINT N'   Error Message: ' + ERROR_MESSAGE();
        -- Insert an error status directly into #CompareResults for this table
        IF NOT EXISTS (SELECT 1 FROM #CompareResults WHERE table_name = @tableName)
             INSERT INTO #CompareResults (table_name, status) VALUES (@tableName, N'‼️ SQL Exec Error');
    END CATCH

    FETCH NEXT FROM table_cursor INTO @tableName;
END -- End of WHILE loop

PRINT N'>>> Cursor loop finished.';

-- Step 6: Clean up the cursor
CLOSE table_cursor;
DEALLOCATE table_cursor;
PRINT N'Cursor closed and deallocated.';

-- Step 7: Final output
PRINT N'--------------------------------------------------------------------------';
PRINT N'>>> Selecting final comparison results...';
PRINT N'Status Codes:'
PRINT N'   ✅ Match: Row counts are identical.';
PRINT N'   ❌ No Match (Local vs Remote): Row counts differ.';
PRINT N'   ❓ Missing Locally: Table found on remote but not locally in schema mrs (or local OBJECT_ID failed).';
PRINT N'   ❓ Missing Remotely: Table found locally but not on remote in schema mrs.';
PRINT N'   ‼️ Error During Count: An error occurred trying to query row counts (check messages).';
PRINT N'   ‼️ SQL Exec Error: A critical error occurred executing the dynamic SQL for the table.';
PRINT N'--------------------------------------------------------------------------';

SELECT table_name,
       rowcount_original,
       rowcount_restored,
       status
FROM #CompareResults
ORDER BY status DESC, -- Show errors/mismatches first
         table_name;

GO

-- Step 8: Clean up the temp table (optional, as it drops when session ends)
-- IF OBJECT_ID('tempdb..#CompareResults') IS NOT NULL DROP TABLE #CompareResults;
-- PRINT N'Temp table #CompareResults dropped.';


















/********** new guy /////////
*/
/*************************************************************************************************
* Script: Compare Table Row Counts Between Local/Old DB and Remote/New DB via Linked Server    *
* *
* Purpose: Iterates through tables in a specified schema of the local database, compares       *
* their row counts with corresponding tables in a remote database (accessed via a     *
* linked server), and reports the results.                                            *
* *
* Prerequisites:                                                                               *
* 1. Run this script while connected to the OLD/Source SQL Server instance in SSMS.        *
* 2. A Linked Server must be configured on the OLD server pointing to the NEW server.      *
* 3. The login used for the linked server connection needs appropriate permissions         *
* (CONNECT, VIEW DATABASE STATE, SELECT on system views & user tables) on the NEW DB.   *
* 4. The login running this script needs permissions on the OLD DB and permissions         *
* to use the Linked Server (often sysadmin or specific EXECUTE permissions).            *
* *
*************************************************************************************************/

-- ==================================
-- START CONFIGURATION
-- ==================================

-- Step 1: Explicitly set context to the OLD database ON THE CURRENTLY CONNECTED SERVER
-- Make SURE you are connected to your OLD server in SSMS when running this whole script
USE [SigmaTB];
GO

-- Define these variables in every batch where they're needed
DECLARE @NewServerLinkedName NVARCHAR(128) = N'SigmaTB_Restore'; -- <<< Linked Server name pointing to the NEW/Restored server
DECLARE @DatabaseName NVARCHAR(128) = N'SigmaTB';          -- <<< Database name (MUST be the same name used on BOTH servers)
DECLARE @SchemaName NVARCHAR(128) = N'mrs';                -- <<< Schema containing the tables to compare

-- ==================================
-- END CONFIGURATION
-- ==================================

PRINT N'Starting Table Row Count Comparison script.';
PRINT N'Comparing schema [' + @SchemaName + N'] in database [' + @DatabaseName + N'] on local server';
PRINT N'With schema [' + @SchemaName + N'] in database [' + @DatabaseName + N'] on linked server [' + @NewServerLinkedName + N']';
PRINT N'--------------------------------------------------------------------------';

-- Step 2: Set up results table
IF OBJECT_ID('tempdb..#CompareResults') IS NOT NULL
BEGIN
    PRINT N'Dropping existing #CompareResults temp table.';
    DROP TABLE #CompareResults;
END
CREATE TABLE #CompareResults (
    table_name NVARCHAR(256),
    rowcount_original BIGINT NULL, -- Allow NULLs initially
    rowcount_restored BIGINT NULL, -- Allow NULLs initially
    status VARCHAR(25) -- Increased size slightly
);
PRINT N'Temporary results table #CompareResults created.';

-- Step 3: Prepare variables for the loop
DECLARE @tableName NVARCHAR(256);
DECLARE @sql NVARCHAR(MAX);
DECLARE @restoredDbNameForSQL NVARCHAR(512);
DECLARE @params NVARCHAR(MAX);
DECLARE @original_count BIGINT;
DECLARE @restored_count BIGINT;

-- Construct the correctly quoted four-part base name for the restored DB reference for use inside dynamic SQL
-- Example result: [SigmaTB_Restore].[SigmaTB]
SET @restoredDbNameForSQL = QUOTENAME(@NewServerLinkedName) + N'.' + QUOTENAME(@DatabaseName);

-- Step 4: Declare cursor for tables in the *current* database context (set by USE)
PRINT N'Declaring cursor to find tables in schema [' + @SchemaName + '] locally...';
DECLARE table_cursor CURSOR FOR
SELECT t.name
FROM sys.tables AS t
WHERE SCHEMA_NAME(t.schema_id) = @SchemaName
ORDER BY t.name;

-- Step 5: Open and process the cursor
OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @tableName;

IF @@FETCH_STATUS <> 0
    PRINT N'>>> WARNING: No tables found in schema [' + @SchemaName + '] for the current database context!';

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT N'>>> Processing table: [' + @SchemaName + '].[' + @tableName + ']...';
    
    -- Initialize variables for this table
    SET @original_count = NULL;
    SET @restored_count = NULL;
    
    -- Get original count (current DB context)
    BEGIN TRY
        DECLARE @local_qualified_name NVARCHAR(386) = QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@tableName);
        
        SELECT @original_count = SUM(ps.row_count)
        FROM sys.dm_db_partition_stats ps
        WHERE ps.object_id = OBJECT_ID(@local_qualified_name) AND ps.index_id IN (0, 1); -- 0=Heap, 1=Clustered Index
    END TRY
    BEGIN CATCH
        PRINT N'   - Error getting local count for ' + @local_qualified_name + N': ' + ERROR_MESSAGE();
        SET @original_count = -2; -- Indicate specific error getting local count
    END CATCH

    -- Get restored count (target DB via Linked Server)
    BEGIN TRY
        -- First check if the table exists in the target database
        SET @sql = N'
            SELECT @remote_count = SUM(ps.row_count)
            FROM ' + @restoredDbNameForSQL + N'.sys.dm_db_partition_stats ps
            JOIN ' + @restoredDbNameForSQL + N'.sys.tables t ON ps.object_id = t.object_id
            JOIN ' + @restoredDbNameForSQL + N'.sys.schemas s ON t.schema_id = s.schema_id
            WHERE t.name = @table_name 
              AND s.name = @schema_name
              AND ps.index_id IN (0, 1)';
        
        SET @params = N'@table_name NVARCHAR(256), @schema_name NVARCHAR(128), @remote_count BIGINT OUTPUT';
        
        EXEC sp_executesql 
            @sql, 
            @params, 
            @table_name = @tableName, 
            @schema_name = @SchemaName, 
            @remote_count = @restored_count OUTPUT;
            
        -- If @restored_count is NULL, the table wasn't found
        IF @restored_count IS NULL
        BEGIN
            SET @restored_count = -1; -- Use -1 to indicate Missing on Remote
            PRINT N'   - Table ' + @tableName + N' not found in schema ' + @SchemaName + N' on linked server.';
        END
    END TRY
    BEGIN CATCH
        PRINT N'   - Error getting remote count for ' + @tableName + N' via linked server: ' + ERROR_MESSAGE();
        SET @restored_count = -2; -- Indicate specific error getting remote count
    END CATCH

    -- Handle cases where table exists locally but not remotely (or vice versa implicitly)
    IF @original_count IS NULL AND ISNULL(@restored_count, -3) <> -1 -- Might happen if OBJECT_ID failed locally but table exists remotely
    BEGIN
        PRINT N'   - Table ' + @tableName + N' not found locally in schema ' + @SchemaName + N'. Setting local count to -1.';
        SET @original_count = -1; -- Use -1 to indicate Missing Locally
    END

    -- Ensure NULLs are handled if errors didn't set counts to -2 or table wasn't found (-1)
    SET @original_count = ISNULL(@original_count, -1); -- Default to missing if still NULL
    SET @restored_count = ISNULL(@restored_count, -1); -- Default to missing if still NULL
    
    -- Insert into results table
    INSERT INTO #CompareResults (table_name, rowcount_original, rowcount_restored, status)
    VALUES (
        @tableName,
        @original_count,
        @restored_count,
        CASE
            WHEN @original_count = -2 OR @restored_count = -2 THEN 'Error During Count'
            WHEN @original_count = -1 THEN 'Missing Locally'
            WHEN @restored_count = -1 THEN 'Missing Remotely'
            WHEN @original_count = @restored_count THEN 'Match'
            ELSE 'No Match (' + CAST(@original_count AS VARCHAR(20)) + ' vs ' + CAST(@restored_count AS VARCHAR(20)) + ')'
        END
    );

    FETCH NEXT FROM table_cursor INTO @tableName;
END -- End of WHILE loop

PRINT N'>>> Cursor loop finished.';

-- Step 6: Clean up the cursor
CLOSE table_cursor;
DEALLOCATE table_cursor;
PRINT N'Cursor closed and deallocated.';

-- Step 7: Final output
PRINT N'--------------------------------------------------------------------------';
PRINT N'>>> Selecting final comparison results...';
PRINT N'Status Codes:';
PRINT N'   Match: Row counts are identical.';
PRINT N'   No Match (Local vs Remote): Row counts differ.';
PRINT N'   Missing Locally: Table found on remote but not locally in schema ' + @SchemaName + ' (or local OBJECT_ID failed).';
PRINT N'   Missing Remotely: Table found locally but not on remote in schema ' + @SchemaName + '.';
PRINT N'   Error During Count: An error occurred trying to query row counts (check messages).';
PRINT N'   SQL Exec Error: A critical error occurred executing the dynamic SQL for the table.';
PRINT N'--------------------------------------------------------------------------';

SELECT table_name,
       rowcount_original,
       rowcount_restored,
       status
FROM #CompareResults
ORDER BY 
    CASE status
        WHEN 'Error During Count' THEN 1
        WHEN 'SQL Exec Error' THEN 2
        WHEN 'Missing Locally' THEN 3
        WHEN 'Missing Remotely' THEN 4
        WHEN 'No Match' THEN 5
        WHEN 'Match' THEN 6
        ELSE 7
    END,
    table_name;

-- Step 8: Clean up the temp table (optional, as it drops when session ends)
-- IF OBJECT_ID('tempdb..#CompareResults') IS NOT NULL DROP TABLE #CompareResults;
-- PRINT N'Temp table #CompareResults dropped.';


SELECT name FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name = 'mrs';

SELECT name FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name = 'mrs';




















-- Run these queries to diagnose why no results are showing up

-- 1. Check if the mrs schema exists in the local database
SELECT schema_id, name FROM sys.schemas WHERE name = 'mrs';

-- 2. Check if there are tables in the mrs schema
SELECT t.name AS table_name, s.name AS schema_name 
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name = 'mrs';

-- 3. Verify linked server exists and is accessible
SELECT name, product, provider, data_source 
FROM sys.servers 
WHERE name = 'SigmaTB_Restore';

-- 4. Test basic access to the linked server
BEGIN TRY
    EXEC('SELECT 1 AS TestResult') AT [SigmaTB_Restore];
    PRINT 'Basic linked server connection successful';
END TRY
BEGIN CATCH
    PRINT 'Failed to connect to linked server: ' + ERROR_MESSAGE();
END CATCH

-- 5. Test if the schema exists on the linked server
BEGIN TRY
    DECLARE @sql NVARCHAR(MAX) = N'
        SELECT schema_id, name FROM [SigmaTB_Restore].[SigmaTB].sys.schemas 
        WHERE name = ''mrs''';
    EXEC sp_executesql @sql;
    PRINT 'Schema query on linked server successful';
END TRY
BEGIN CATCH
    PRINT 'Failed to query schema on linked server: ' + ERROR_MESSAGE();
END CATCH

-- 6. Check if any tables exist in that schema on the linked server
BEGIN TRY
    DECLARE @sql NVARCHAR(MAX) = N'
        SELECT t.name AS table_name, s.name AS schema_name 
        FROM [SigmaTB_Restore].[SigmaTB].sys.tables t
        JOIN [SigmaTB_Restore].[SigmaTB].sys.schemas s ON t.schema_id = s.schema_id
        WHERE s.name = ''mrs''';
    EXEC sp_executesql @sql;
    PRINT 'Table query on linked server successful';
END TRY
BEGIN CATCH
    PRINT 'Failed to query tables on linked server: ' + ERROR_MESSAGE();
END CATCH

-- 7. Check permissions on linked server
BEGIN TRY
    DECLARE @sql NVARCHAR(MAX) = N'
        SELECT SUSER_NAME() AS CurrentLogin, 
               HAS_PERMS_BY_NAME(''[SigmaTB].sys.tables'', ''OBJECT'', ''SELECT'') AS HasTablePerms,
               HAS_PERMS_BY_NAME(''[SigmaTB]'', ''DATABASE'', ''VIEW DATABASE STATE'') AS HasDBStatePerms;';
    EXEC (@sql) AT [SigmaTB_Restore];
    PRINT 'Permission check on linked server successful';
END TRY
BEGIN CATCH
    PRINT 'Failed to check permissions on linked server: ' + ERROR_MESSAGE();
END CATCH










-- Simple query to verify which server you're currently connected to
SELECT 
    @@SERVERNAME AS [Server Name],
    DB_NAME() AS [Current Database],
    SUSER_NAME() AS [Current Login],
    HOST_NAME() AS [Client Machine]


-- Check linked servers configured on the current server
SELECT 
    name AS [Linked Server Name],
    product AS [Product Name],
    provider AS [Provider Name],
    data_source AS [Remote Server Name]
FROM sys.servers
WHERE is_linked = 1











-- Comprehensive verification of current server and linked server
-- Run this on your OLD server (EC2AMAZ-7QANEJ3)

-- 1. Current Server Information
SELECT 
    @@SERVERNAME AS [Server Name],
    SERVERPROPERTY('MachineName') AS [Machine Name],
    SERVERPROPERTY('ServerName') AS [Instance Name],
    SERVERPROPERTY('Edition') AS [Edition],
    SERVERPROPERTY('ProductVersion') AS [Product Version],
    DB_NAME() AS [Current Database],
    SUSER_NAME() AS [Current Login];

	/*
	EC2AMAZ-7QANEJ3	EC2AMAZ-7QANEJ3	EC2AMAZ-7QANEJ3	Standard Edition (64-bit)	15.0.4420.2	SigmaTB	admin
	*/

-- 2. Check if the mrs schema exists in local database
SELECT 
    schema_id, 
    name AS [Schema Name],
    principal_id AS [Owner ID]
FROM sys.schemas 
WHERE name = 'mrs';
/*
schema_id	Schema Name	Owner ID
6	mrs	5
*/

-- 3. Count tables in the mrs schema locally
SELECT 
    COUNT(*) AS [Table Count in mrs Schema]
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name = 'mrs';
/*
Table Count in mrs Schema
308
*/

-- 4. Get first 5 table names in mrs schema (if any)
SELECT TOP 5
    t.name AS [Table Name],
    t.object_id AS [Object ID],
    t.create_date AS [Created Date]
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name = 'mrs'
ORDER BY t.name;
/*
Table Name	Object ID	Created Date
01_AS400_MSSQL_Equivalents	1453248232	2025-04-25 11:21:36.550
z_***_remove_next_rel_____CLIMITA	1314103722	2025-04-13 10:12:28.807
z______ADDHSTCT	706101556	2025-04-13 10:12:28.680
z______AROEHITS	1275151588	2025-04-25 00:33:50.503
z______DELCODE	710293590	2025-04-26 14:59:53.243
*/


-- 5. Verify linked server details
SELECT 
    name AS [Linked Server Name],
    product AS [Product Name],
    provider AS [Provider Name],
    data_source AS [Remote Server Name],
    catalog AS [Default Catalog],
    is_remote_login_enabled AS [Remote Login Enabled],
    is_data_access_enabled AS [Data Access Enabled],
    is_rpc_out_enabled AS [RPC Out Enabled]
FROM sys.servers
WHERE name = 'SigmaTB_Restore';
/*
Linked Server Name	Product Name	Provider Name	Remote Server Name	Default Catalog	Remote Login Enabled	Data Access Enabled	RPC Out Enabled
SigmaTB_Restore		SQLNCLI	sigmatbrestored.c67ymu6q22o1.us-east-1.rds.amazonaws.com	NULL	0	1	0
*/


-- 6. Test linked server connection (simple test)
BEGIN TRY
    EXEC('SELECT @@SERVERNAME AS [Remote Server Name], DB_NAME() AS [Remote DB Name]') 
    AT [SigmaTB_Restore];
    PRINT 'Basic linked server connection successful';
END TRY
BEGIN CATCH
    PRINT 'Failed to connect to linked server: ' + ERROR_MESSAGE();
END CATCH
/*
Failed to connect to linked server: Server 'SigmaTB_Restore' is not configured for RPC.

Completion time: 2025-05-03T03:57:31.1191520-05:00

*/


-- 7. Check if mrs schema exists on the linked server
BEGIN TRY
    DECLARE @sql NVARCHAR(MAX) = N'
        SELECT COUNT(*) AS [Remote mrs Schema Count]
        FROM [SigmaTB_Restore].[SigmaTB].sys.schemas 
        WHERE name = ''mrs''';
    EXEC sp_executesql @sql;
    PRINT 'Schema query on linked server successful';
END TRY
BEGIN CATCH
    PRINT 'Failed to query schema on linked server: ' + ERROR_MESSAGE();
END CATCH
/*
Remote mrs Schema Count
1
*/


-- 8. Check if tables exist in mrs schema on linked server
BEGIN TRY
    DECLARE @sql NVARCHAR(MAX) = N'
        SELECT COUNT(*) AS [Remote Tables in mrs Schema]
        FROM [SigmaTB_Restore].[SigmaTB].sys.tables t
        JOIN [SigmaTB_Restore].[SigmaTB].sys.schemas s ON t.schema_id = s.schema_id
        WHERE s.name = ''mrs''';
    EXEC sp_executesql @sql;
    PRINT 'Table count query on linked server successful';
END TRY
BEGIN CATCH
    PRINT 'Failed to query tables on linked server: ' + ERROR_MESSAGE();
END CATCH
/*
Remote Tables in mrs Schema
308
*/


/*************************************************************************************************
* Script: Compare Table Row Counts Between Local/Old DB and Remote/New DB via Linked Server    *
*                                                                                              *
* Purpose: Iterates through tables in a specified schema of the local database, compares       *
*          their row counts with corresponding tables in a remote database (accessed via a     *
*          linked server), and reports the results.                                            *
*                                                                                              *
* Prerequisites:                                                                               *
*    1. Run this script while connected to the OLD/Source SQL Server instance in SSMS.         *
*    2. A Linked Server must be configured on the OLD server pointing to the NEW server.       *
*    3. The login used for the linked server connection needs appropriate permissions          *
*       (CONNECT, VIEW DATABASE STATE, SELECT on system views & user tables) on the NEW DB.    *
*    4. The login running this script needs permissions on the OLD DB and permissions          *
*       to use the Linked Server (often sysadmin or specific EXECUTE permissions).             *
*                                                                                              *
*************************************************************************************************/

-- ==================================
-- START CONFIGURATION - MODIFY THESE
-- ==================================
DECLARE @NewServerLinkedName NVARCHAR(128) = N'SigmaTB_Restore';  -- Linked Server name pointing to the NEW/Restored server
DECLARE @DatabaseName NVARCHAR(128) = N'SigmaTB';                 -- Database name (MUST be the same name used on BOTH servers)
DECLARE @SchemaName NVARCHAR(128) = N'mrs';                       -- Schema containing the tables to compare
-- ==================================
-- END CONFIGURATION
-- ==================================

-- Print confirmation of which server we're connected to
SELECT 
    @@SERVERNAME AS [Current Server],
    DB_NAME() AS [Current Database],
    @SchemaName AS [Schema Being Compared],
    @NewServerLinkedName AS [Linked Server Name]
PRINT '-----------------------------------------------------------------------';
/*
Current Server	Current Database	Schema Being Compared	Linked Server Name
EC2AMAZ-7QANEJ3	SigmaTB	mrs	SigmaTB_Restore
*/

-- Set up results table
IF OBJECT_ID('tempdb..#CompareResults') IS NOT NULL
BEGIN
    DROP TABLE #CompareResults;
END

CREATE TABLE #CompareResults (
    table_name NVARCHAR(256),
    rowcount_original BIGINT NULL,
    rowcount_restored BIGINT NULL,
    status VARCHAR(50)
);

--runs ok

-- First check if schema exists locally
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = @SchemaName)
BEGIN
    PRINT 'ERROR: Schema [' + @SchemaName + '] does not exist in the local database!';
    RAISERROR('Schema does not exist locally. Script terminated.', 16, 1);
    RETURN;
END
--runs ok

-- Then check if linked server exists
IF NOT EXISTS (SELECT 1 FROM sys.servers WHERE name = @NewServerLinkedName)
BEGIN
    PRINT 'ERROR: Linked server [' + @NewServerLinkedName + '] is not configured!';
    RAISERROR('Linked server not found. Script terminated.', 16, 1);
    RETURN;
END

--runs ok

-- Test linked server basic connectivity
BEGIN TRY
    DECLARE @testSql NVARCHAR(MAX) = N'SELECT 1';
    EXEC (@testSql) AT [SigmaTB_Restore];
    PRINT 'Linked server [' + @NewServerLinkedName + '] connection test successful.';
END TRY
BEGIN CATCH
    PRINT 'ERROR: Cannot connect to linked server [' + @NewServerLinkedName + ']!';
    PRINT 'Error message: ' + ERROR_MESSAGE();
    RAISERROR('Linked server connectivity test failed. Script terminated.', 16, 1);
    RETURN;
END CATCH
--fails because the exec


/*

(1 row affected)
-----------------------------------------------------------------------
ERROR: Cannot connect to linked server [SigmaTB_Restore]!
Error message: Server 'SigmaTB_Restore' is not configured for RPC.
Msg 50000, Level 16, State 1, Line 804
Linked server connectivity test failed. Script terminated.

Completion time: 2025-05-03T04:04:54.1619409-05:00

*/

-- Check if schema exists on linked server
BEGIN TRY
    DECLARE @remoteSchemaSql NVARCHAR(MAX) = N'
        SELECT COUNT(*) FROM [' + @NewServerLinkedName + '].[' + @DatabaseName + '].sys.schemas 
        WHERE name = ''' + @SchemaName + '''';
    
    DECLARE @remoteSchemaCount INT;
    EXEC sp_executesql @remoteSchemaSql, N'@count INT OUTPUT', @count = @remoteSchemaCount OUTPUT;
    
    IF @remoteSchemaCount = 0
    BEGIN
        PRINT 'ERROR: Schema [' + @SchemaName + '] does not exist in the remote database!';
        RAISERROR('Schema does not exist on linked server. Script terminated.', 16, 1);
        RETURN;
    END
    ELSE
    BEGIN
        PRINT 'Schema [' + @SchemaName + '] exists on both local and remote databases.';
    END
END TRY
BEGIN CATCH
    PRINT 'ERROR: Failed to check if schema exists on linked server!';
    PRINT 'Error message: ' + ERROR_MESSAGE();
    RAISERROR('Remote schema check failed. Script terminated.', 16, 1);
    RETURN;
END CATCH

-- Get list of tables in local schema
DECLARE @tableCursor CURSOR;
DECLARE @tableName NVARCHAR(256);
DECLARE @localTableCount INT;

SELECT @localTableCount = COUNT(*) 
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name = @SchemaName;

PRINT 'Found ' + CAST(@localTableCount AS NVARCHAR(10)) + ' tables in local schema [' + @SchemaName + '].';

IF @localTableCount = 0
BEGIN
    PRINT 'WARNING: No tables found in local schema [' + @SchemaName + ']. Nothing to compare.';
    RETURN;
END

SET @tableCursor = CURSOR FOR
    SELECT t.name
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = @SchemaName
    ORDER BY t.name;

OPEN @tableCursor;
FETCH NEXT FROM @tableCursor INTO @tableName;

DECLARE @tablesProcessed INT = 0;
DECLARE @matchCount INT = 0;
DECLARE @mismatchCount INT = 0;
DECLARE @errorCount INT = 0;

WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @localRowCount BIGINT;
    DECLARE @remoteRowCount BIGINT;
    DECLARE @statusText VARCHAR(50);
    
    SET @tablesProcessed = @tablesProcessed + 1;
    
    -- Get local row count
    BEGIN TRY
        DECLARE @localSql NVARCHAR(MAX) = N'
            SELECT @rowCount = SUM(row_count)
            FROM sys.dm_db_partition_stats
            WHERE object_id = OBJECT_ID(''' + @SchemaName + '.' + @tableName + ''')
            AND index_id IN (0, 1)';
            
        EXEC sp_executesql @localSql, N'@rowCount BIGINT OUTPUT', @rowCount = @localRowCount OUTPUT;
        
        -- Handle NULL results (table might not exist or be empty)
        SET @localRowCount = ISNULL(@localRowCount, 0);
    END TRY
    BEGIN CATCH
        SET @localRowCount = -1;
        PRINT 'Error getting local row count for [' + @SchemaName + '].[' + @tableName + ']: ' + ERROR_MESSAGE();
    END CATCH
    
    -- Get remote row count
    BEGIN TRY
        DECLARE @remoteSql NVARCHAR(MAX) = N'
            SELECT @rowCount = SUM(ps.row_count)
            FROM [' + @NewServerLinkedName + '].[' + @DatabaseName + '].sys.dm_db_partition_stats ps
            JOIN [' + @NewServerLinkedName + '].[' + @DatabaseName + '].sys.objects o 
                ON ps.object_id = o.object_id
            JOIN [' + @NewServerLinkedName + '].[' + @DatabaseName + '].sys.schemas s 
                ON o.schema_id = s.schema_id
            WHERE s.name = ''' + @SchemaName + '''
            AND o.name = ''' + @tableName + '''
            AND ps.index_id IN (0, 1)';
            
        EXEC sp_executesql @remoteSql, N'@rowCount BIGINT OUTPUT', @rowCount = @remoteRowCount OUTPUT;
        
        -- Handle NULL results (table might not exist or be empty)
        SET @remoteRowCount = ISNULL(@remoteRowCount, -2);
        
        IF @remoteRowCount = -2
        BEGIN
            SET @statusText = 'Missing on Remote';
            SET @errorCount = @errorCount + 1;
        END
        ELSE IF @localRowCount = @remoteRowCount
        BEGIN
            SET @statusText = 'Match';
            SET @matchCount = @matchCount + 1;
        END
        ELSE
        BEGIN
            SET @statusText = 'Different Counts';
            SET @mismatchCount = @mismatchCount + 1;
        END
    END TRY
    BEGIN CATCH
        SET @remoteRowCount = -1;
        SET @statusText = 'Error';
        SET @errorCount = @errorCount + 1;
        PRINT 'Error getting remote row count for [' + @SchemaName + '].[' + @tableName + ']: ' + ERROR_MESSAGE();
    END CATCH
    
    -- Insert result
    INSERT INTO #CompareResults (table_name, rowcount_original, rowcount_restored, status)
    VALUES (
        @tableName,
        @localRowCount,
        @remoteRowCount,
        CASE
            WHEN @localRowCount = -1 THEN 'Error: Local Count Failed'
            WHEN @remoteRowCount = -1 THEN 'Error: Remote Count Failed'
            WHEN @remoteRowCount = -2 THEN 'Missing on Remote'
            WHEN @localRowCount = @remoteRowCount THEN 'Match'
            ELSE 'Different: ' + CAST(@localRowCount AS VARCHAR(20)) + ' vs ' + CAST(@remoteRowCount AS VARCHAR(20))
        END
    );
    
    -- Progress indicator for large schemas
    IF @tablesProcessed % 10 = 0
    BEGIN
        PRINT 'Processed ' + CAST(@tablesProcessed AS VARCHAR(10)) + ' of ' + CAST(@localTableCount AS VARCHAR(10)) + ' tables...';
    END
    
    FETCH NEXT FROM @tableCursor INTO @tableName;
END

CLOSE @tableCursor;
DEALLOCATE @tableCursor;

-- Print summary results
PRINT '-----------------------------------------------------------------------';
PRINT 'Comparison complete! Summary:';
PRINT '  Tables processed: ' + CAST(@tablesProcessed AS VARCHAR(10));
PRINT '  Matching tables: ' + CAST(@matchCount AS VARCHAR(10));
PRINT '  Mismatched tables: ' + CAST(@mismatchCount AS VARCHAR(10));
PRINT '  Errors/missing tables: ' + CAST(@errorCount AS VARCHAR(10));
PRINT '-----------------------------------------------------------------------';

-- Display detailed results
SELECT 
    table_name AS [Table Name],
    rowcount_original AS [Local Row Count],
    rowcount_restored AS [Remote Row Count],
    status AS [Status]
FROM #CompareResults
ORDER BY 
    CASE 
        WHEN status LIKE 'Error%' THEN 1
        WHEN status LIKE 'Missing%' THEN 2
        WHEN status LIKE 'Different%' THEN 3
        ELSE 4
    END,
    table_name;

-- Clean up
DROP TABLE #CompareResults;