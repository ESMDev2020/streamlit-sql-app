/**************************************
Execution cas to the stored procedure to 
create Extended Properties in MSSQL
****************************************/


USE SigmaTB;
GO

-- Basic execution with defaults
EXEC mrs.UpdateExtendedPropertiesForZTables @DebugMode = 0;


-- With custom parameters
EXEC dbo.UpdateExtendedPropertiesForZTables 
    @Separator = '____',
    @SchemaName = 'sales',
    @TableNamePattern = 'temp_%',
    @DebugMode = 1;

-- Just show what would happen without making changes
EXEC dbo.UpdateExtendedPropertiesForZTables @DebugMode = 1;


-- Check status
SELECT
    t.name AS TableName,
    ep.name AS XPName,
    ep.value AS XPValue
FROM
    sys.tables AS t
INNER JOIN
    sys.extended_properties AS ep ON t.object_id = ep.major_id
WHERE
    t.schema_id = SCHEMA_ID('mrs')
    AND ep.minor_id = 0;
