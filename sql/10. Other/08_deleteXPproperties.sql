-- Script to delete ALL column-level extended properties for tables in the 'mrs' schema.
-- WARNING: Review carefully before execution.

DECLARE @SchemaName NVARCHAR(128) = N'mrs'; -- Target schema
DECLARE @TableName NVARCHAR(128);
DECLARE @ColumnName NVARCHAR(128);
DECLARE @PropertyName NVARCHAR(128);

DECLARE @DroppedCount INT = 0;
DECLARE @ErrorCount INT = 0;

PRINT 'Starting deletion of column extended properties for schema: ' + QUOTENAME(@SchemaName);
PRINT '--------------------------------------------------------------';

-- Cursor to find all column-level extended properties for tables in the specified schema
DECLARE prop_cursor CURSOR LOCAL FAST_FORWARD FOR
SELECT
    s.name AS SchemaName,
    o.name AS TableName,
    c.name AS ColumnName,
    ep.name AS PropertyName
FROM
    sys.extended_properties AS ep
INNER JOIN
    sys.objects AS o ON ep.major_id = o.object_id
INNER JOIN
    sys.schemas AS s ON o.schema_id = s.schema_id
INNER JOIN
    sys.columns AS c ON ep.major_id = c.object_id AND ep.minor_id = c.column_id
WHERE
    ep.class = 1 -- Class 1 = Object or Column
    AND ep.minor_id > 0 -- Indicates it's a column property
    AND o.type = 'U' -- User Tables
    AND s.name = @SchemaName;

OPEN prop_cursor;

FETCH NEXT FROM prop_cursor INTO @SchemaName, @TableName, @ColumnName, @PropertyName;

WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        PRINT N'Dropping property [' + @PropertyName + N'] for column [' + @SchemaName + N'].[' + @TableName + N'].[' + @ColumnName + N']...';

        EXEC sys.sp_dropextendedproperty
            @name = @PropertyName,
            @level0type = N'SCHEMA',
            @level0name = @SchemaName,
            @level1type = N'TABLE',
            @level1name = @TableName,
            @level2type = N'COLUMN',
            @level2name = @ColumnName;

        SET @DroppedCount = @DroppedCount + 1;
        PRINT N'  ...Dropped successfully.';

    END TRY
    BEGIN CATCH
        SET @ErrorCount = @ErrorCount + 1;
        PRINT N'  *** ERROR Dropping property [' + @PropertyName + N'] for column [' + @SchemaName + N'].[' + @TableName + N'].[' + @ColumnName + N'] ***';
        PRINT N'  Error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
    END CATCH

    FETCH NEXT FROM prop_cursor INTO @SchemaName, @TableName, @ColumnName, @PropertyName;
END

CLOSE prop_cursor;
DEALLOCATE prop_cursor;

PRINT '--------------------------------------------------------------';
PRINT 'Extended property deletion summary:';
PRINT 'Schema processed: ' + QUOTENAME(@SchemaName);
PRINT 'Properties dropped: ' + CAST(@DroppedCount AS VARCHAR);
PRINT 'Errors encountered: ' + CAST(@ErrorCount AS VARCHAR);
PRINT '--------------------------------------------------------------';
GO