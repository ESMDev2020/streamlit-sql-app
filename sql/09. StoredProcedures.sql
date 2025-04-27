
--NOooooooooo
EXEC mysp_format_query_with_descriptions @InputQuery = N'SELECT TOP(100) [SHIPMAST].[SHIPMAST], [SHIPMAST].[SH], [SHIPMAST].[SHORDN], [SHIPMAST].[Shipment], [SHIPMAST].[SHCORD], [SHIPMAST].[SHIPYY], [SHIPMAST].[SHIPMM], [SHIPMAST].[SHIPDD], [SHIPMAST].[SHSHAP], [SHIPMAST].[shape], [SHIPMAST].[SHINSM], [SHIPMAST].[SHSQTY], [SHIPMAST].[Shipped], [SHIPMAST].[SHUOM], [SHIPMAST].[SHBQTY], [SHIPMAST].[SHBUOM], [SHIPMAST].[SHOINC], [SHIPMAST].[SHOQTY], [SHIPMAST].[SHOUOM], [SHIPMAST].[SHTLBS], [SHIPMAST].[SHTPCS], [SHIPMAST].[SHTFTS], [SHIPMAST].[SHTSFT], [SHIPMAST].[SHTMTR], [SHIPMAST].[SHTKG], [SHIPMAST].[SHPRCG], [SHIPMAST].[SHHAND], [SHIPMAST].[SHMSLS], [SHIPMAST].[SHMSLD], [SHIPMAST].[SHFSLS], [SHIPMAST].[SHFSLD], [SHIPMAST].[SHPSLS], [SHIPMAST].[SHPSLD], [SHIPMAST].[SHOSLS], [SHIPMAST].[SHOSLD], [SHIPMAST].[SHDSLS], [SHIPMAST].[SHDSLD], [SHIPMAST].[SHMCSS], [SHIPMAST].[SHMCSD], [SHIPMAST].[SHSLSS], [SHIPMAST].[SHSLSD], [SHIPMAST].[SHSWGS], [SHIPMAST].[SHSWGD], [SHIPMAST].[SHADPC], [SHIPMAST].[SHUNSP], [SHIPMAST].[SHUUOM], [SHIPMAST].[SHSCDL], [SHIPMAST].[SHSCLB], [SHIPMAST].[SHSCKG], [SHIPMAST].[SHTRCK], [SHIPMAST].[SHBCTY], [SHIPMAST].[SHSCTY], [SHIPMAST].[SHIP-TO], [SHIPMAST].[SHDPTI], [SHIPMAST].[SHDPTO], [SHIPMAST].[SHCSTO], [SHIPMAST].[SHADR1], [SHIPMAST].[SHADR2], [SHIPMAST].[SHADR3], [SHIPMAST].[SHCITY], [SHIPMAST].[SHSTAT], [SHIPMAST].[SHZIP]
FROM [SHIPMAST]'

--Rename
EXEC sp_rename 'dbo.sp_format_query_with_descriptions', 'mysp_format_query_with_descriptions';


EXEC sp_format_query_with_descriptions @InputQuery = N'SELECT TOP(100) ... FROM [SHIPMAST]'

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
    

EXEC my_sp_getXPfromObjects  'SHIPMAST', 'table', 'code'        -- bad
EXEC my_sp_getXPfromObjects @lookfor = '[GLTRANS].[GLACCT]', @isobject = 'column', @returnvalue = 'name';

EXEC mysp_find_table_column_by_code    'SHIPMAST', 'SHPFLG'  
EXEC sp_format_query_with_descriptions 'SELECT TOP(100) [SHIPMAST].[SHIPMAST], [SHIPMAST].[SH], [SHIPMAST].[SHORDN], [SHIPMAST].[Shipment], [SHIPMAST].[SHCORD], [SHIPMAST].[SHIPYY], [SHIPMAST].[SHIPMM], [SHIPMAST].[SHIPDD], [SHIPMAST].[SHSHAP], [SHIPMAST].[shape], [SHIPMAST].[SHINSM], [SHIPMAST].[SHSQTY], [SHIPMAST].[Shipped], [SHIPMAST].[SHUOM], [SHIPMAST].[SHBQTY
