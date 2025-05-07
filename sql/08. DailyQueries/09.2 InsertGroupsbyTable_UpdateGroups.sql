-- Update [mrs].[01_AS400_MSSQL_Equivalents] with values from [mrs].[01_tmp]
-- This query updates TableCode, Prefix, TableGroupName, and TableGroupNumber columns
-- when the TableCode values match between the two tables (with spaces trimmed)

BEGIN TRANSACTION;

-- For safety, first check how many rows will be affected
DECLARE @RowsToBeUpdated INT;
SELECT @RowsToBeUpdated = COUNT(*)
FROM [mrs].[01_AS400_MSSQL_Equivalents] AS e
INNER JOIN [mrs].[01_tmp] AS t
ON LTRIM(RTRIM(e.[AS400_TableName])) = LTRIM(RTRIM(t.[TableCode]));

PRINT 'Number of rows to be updated: ' + CAST(@RowsToBeUpdated AS VARCHAR);

-- Perform the update
UPDATE [mrs].[01_AS400_MSSQL_Equivalents]
SET 
    [TableCode] = t.[TableCode],
    [Prefix] = t.[Prefix],
    [TableGroupName] = t.[TableGroupName],
    [TableGroupNumber] = t.[TableGroupNumber]
FROM [mrs].[01_AS400_MSSQL_Equivalents] AS e
INNER JOIN [mrs].[01_tmp] AS t
ON LTRIM(RTRIM(e.[AS400_TableName])) = LTRIM(RTRIM(t.[TableCode]));

-- Verify the update was successful
DECLARE @RowsUpdated INT;
SET @RowsUpdated = @@ROWCOUNT;
PRINT 'Number of rows updated: ' + CAST(@RowsUpdated AS VARCHAR);

-- Check if the expected number of rows were updated
IF @RowsUpdated = @RowsToBeUpdated
    COMMIT TRANSACTION;
ELSE
BEGIN
    PRINT 'Warning: Number of rows updated does not match expected count.';
    PRINT 'Rolling back transaction.';
    ROLLBACK TRANSACTION;
END


/*select * from [mrs].[01_AS400_MSSQL_Equivalents]
select * from [mrs].[01_tmp]
delete  from [mrs].[01_tmp]
*/