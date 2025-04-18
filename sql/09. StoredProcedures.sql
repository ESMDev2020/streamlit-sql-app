/*********************************************************
THIS RETURNS BOTH, THE TABLE AND COLUMN NAME BASED ON CODE
*******************************************************/
USE SigmaTB;
GO

CREATE OR ALTER PROCEDURE mysp_find_table_column_by_code
    @InputTableCode SYSNAME,
    @InputColumnCode SYSNAME
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        s.name AS SchemaName,
        @InputTableCode AS FoundTableCode,
        ep_t.value AS TableDescription,
        @InputColumnCode AS FoundColumnCode,
        ep_c.value AS ColumnDescription
    FROM
        sys.extended_properties AS ep_t
    INNER JOIN
        sys.tables AS t ON ep_t.major_id = t.object_id
    INNER JOIN
        sys.schemas AS s ON t.schema_id = s.schema_id
    INNER JOIN
        sys.columns AS c ON t.object_id = c.object_id
    INNER JOIN
        sys.extended_properties AS ep_c
        ON ep_c.major_id = c.object_id
        AND ep_c.minor_id = c.column_id
    WHERE
        ep_t.class = 1
        AND ep_t.minor_id = 0
        AND ep_t.name = @InputTableCode
        AND ep_c.class = 1
        AND ep_c.name = @InputColumnCode;
END;
GO




/********************************************************
CHECK XP PROPERTIES
*********************************************************/
/*****************************************
Check extended properties for 1 table or column
*****************************************/

SELECT * FROM sys.columns WHERE name like '%GLACCT'
select * from sys.extended_properties where name like '%GLTRANS'


EXEC my_sp_getXPfromObjects @InputSearchTerm = 'YourTableOrColumnCode';
EXEC my_sp_getXPfromObjects @InputSearchTerm = 'GLTRANS';

--Column
EXEC my_sp_getXPfromObjects @lookfor = '[GLTRANS].[GLACCT]', @isobject = 'column', @returnvalue = 'name';
EXEC my_sp_getXPfromObjects @lookfor = '[GLTRANS].[GLACCT]', @isobject = 'column', @returnvalue = 'code';

--Table 
EXEC my_sp_getXPfromObjects @lookfor = '[GLTRANS].[GLACCT]', @isobject = 'table', @returnvalue = 'name';
EXEC my_sp_getXPfromObjects @lookfor = '[GLTRANS].[GLACCT]', @isobject = 'table', @returnvalue = 'code';

--Table
EXEC my_sp_getXPfromObjects @lookfor = '[GLTRANS]', @isobject = 'table', @returnvalue = 'name';
EXEC my_sp_getXPfromObjects @lookfor = '[GLTRANS]', @isobject = 'table', @returnvalue = 'code';


/***************************************************************
WHAT STORED PROCEDURES
***************************************************************/
-- What stored procedures?
SELECT
    SCHEMA_NAME(schema_id) AS SchemaName, -- Gets the schema name (e.g., 'dbo')
    name AS ProcedureName,                 -- The name of the stored procedure
    create_date,                           -- When it was created
    modify_date                            -- When it was last modified
FROM
    sys.procedures
-- Optional: Filter by schema if you usually create them in a specific one
-- WHERE SCHEMA_NAME(schema_id) = 'YourSchemaName'
ORDER BY
    Modify_date DESC,
    SchemaName,
    ProcedureName;

/***************************************************************
LIST OF STORED PROCEDURES
***************************************************************/
mysp_analyze_table_columns    'SHIPMAST'        --Provides the count of unique values for all the columns

-- ROWCOUNT by unique value by 1 column
EXEC mysp_find_unique_values_table_column_by_code
    @InputTableCode = 'SHIPMAST',
    @InputColumnCode = 'SHPFLG',
    @InputColumnDescription = 'Shipment Flag'
    

my_sp_getXPfromObjects
mysp_find_table_column_by_code
sp_format_query_with_descriptions
