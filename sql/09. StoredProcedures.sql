USE SigmaTB
GO


--NOooooooooo
EXEC mysp_format_query_with_descriptions @InputQuery = N'SELECT TOP(100) [SHIPMAST].[SHIPMAST], [SHIPMAST].[SH], [SHIPMAST].[SHORDN], [SHIPMAST].[Shipment], [SHIPMAST].[SHCORD], [SHIPMAST].[SHIPYY], [SHIPMAST].[SHIPMM], [SHIPMAST].[SHIPDD], [SHIPMAST].[SHSHAP], [SHIPMAST].[shape], [SHIPMAST].[SHINSM], [SHIPMAST].[SHSQTY], [SHIPMAST].[Shipped], [SHIPMAST].[SHUOM], [SHIPMAST].[SHBQTY], [SHIPMAST].[SHBUOM], [SHIPMAST].[SHOINC], [SHIPMAST].[SHOQTY], [SHIPMAST].[SHOUOM], [SHIPMAST].[SHTLBS], [SHIPMAST].[SHTPCS], [SHIPMAST].[SHTFTS], [SHIPMAST].[SHTSFT], [SHIPMAST].[SHTMTR], [SHIPMAST].[SHTKG], [SHIPMAST].[SHPRCG], [SHIPMAST].[SHHAND], [SHIPMAST].[SHMSLS], [SHIPMAST].[SHMSLD], [SHIPMAST].[SHFSLS], [SHIPMAST].[SHFSLD], [SHIPMAST].[SHPSLS], [SHIPMAST].[SHPSLD], [SHIPMAST].[SHOSLS], [SHIPMAST].[SHOSLD], [SHIPMAST].[SHDSLS], [SHIPMAST].[SHDSLD], [SHIPMAST].[SHMCSS], [SHIPMAST].[SHMCSD], [SHIPMAST].[SHSLSS], [SHIPMAST].[SHSLSD], [SHIPMAST].[SHSWGS], [SHIPMAST].[SHSWGD], [SHIPMAST].[SHADPC], [SHIPMAST].[SHUNSP], [SHIPMAST].[SHUUOM], [SHIPMAST].[SHSCDL], [SHIPMAST].[SHSCLB], [SHIPMAST].[SHSCKG], [SHIPMAST].[SHTRCK], [SHIPMAST].[SHBCTY], [SHIPMAST].[SHSCTY], [SHIPMAST].[SHIP-TO], [SHIPMAST].[SHDPTI], [SHIPMAST].[SHDPTO], [SHIPMAST].[SHCSTO], [SHIPMAST].[SHADR1], [SHIPMAST].[SHADR2], [SHIPMAST].[SHADR3], [SHIPMAST].[SHCITY], [SHIPMAST].[SHSTAT], [SHIPMAST].[SHZIP]
FROM [SHIPMAST]'

--Rename
EXEC sp_rename 'mrs.sp_format_query_with_descriptions', 'mysp_format_query_with_descriptions';


EXEC mysp_format_query_with_descriptions @InputQuery = N'SELECT TOP(100) ... FROM [SHIPMAST]'

/********************************************************
CHECK XP PROPERTIES
*********************************************************/
/*****************************************
Check extended properties for 1 table or column
*****************************************/

SELECT * FROM sys.tables WHERE name like '%APWK856%'

SELECT * FROM sys.columns WHERE name like '%BSORDR%'
SELECT * FROM sys.tables WHERE name like 'z_A/P_Check_Register_Work_File_____APWK856'
select * from sys.extended_properties where name like '%BSORDR%'
z_A/P_Check_Register_Work_File_____APWK856
z_A/P_Check_Register_Work_File_____APWK856
z_A/P_Check_Register_Work_File_____APWK856

USE SigmaTB;
GO

SELECT
    t.name AS table_name,         -- Table Name
    tp.name AS table_prop_name,   -- Table Extended Property Name
    tp.value AS table_prop_value,  -- Table Extended Property Value
    c.name AS column_name,        -- Column Name
    cp.name AS column_prop_name,  -- Column Extended Property Name
    cp.value AS column_prop_value -- Column Extended Property Value
FROM
    sys.schemas AS s
INNER JOIN
    sys.tables AS t ON s.schema_id = t.schema_id
LEFT JOIN -- Join for table extended properties
    sys.extended_properties AS tp ON t.object_id = tp.major_id
                                 AND tp.minor_id = 0 -- Indicates property is on the table itself
                                 AND tp.class = 1    -- Class 1 = Object or Column
LEFT JOIN -- Join for columns within the table
    sys.columns AS c ON t.object_id = c.object_id
LEFT JOIN -- Join for column extended properties
    sys.extended_properties AS cp ON c.object_id = cp.major_id
                                 AND c.column_id = cp.minor_id -- Link property to the specific column
                                 AND cp.class = 1    -- Class 1 = Object or Column
WHERE
    s.name = 'mrs'  -- Filter for the 'mrs' schema
ORDER BY
    t.name,         -- Group results primarily by table name
    c.column_id;    -- Within each table, order by column position

    
SELECT ep.*
FROM sys.extended_properties ep
JOIN sys.objects o ON ep.major_id = o.object_id
WHERE o.name = 'z_A/P_Check_Register_Work_File_____APWK856'


--EXEC my_sp_getXPfromObjects @InputSearchTerm = 'YourTableOrColumnCode';       -- Old version
--EXEC my_sp_getXPfromObjects @InputSearchTerm = 'GLTRANS';                     -- Old version

--Column
EXEC my_sp_getXPfromObjects @lookfor = '[GLTRANS].[GLACCT]', @isobject = 'column', @returnvalue = 'name';
EXEC my_sp_getXPfromObjects @lookfor = '[GLTRANS].[GLACCT]', @isobject = 'column', @returnvalue = 'code';
--233767890


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
    SCHEMA_NAME(schema_id) AS SchemaName, -- Gets the schema name (e.g., 'mrs')
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

EXEC mysp_find_table_column_by_code    'SHIPMAST', 'SHPFLG'  --fails
--works
EXEC mysp_format_query_with_descriptions 'SELECT TOP(100) [SHIPMAST].[SHIPMAST], [SHIPMAST].[SH], [SHIPMAST].[SHORDN], [SHIPMAST].[Shipment], [SHIPMAST].[SHCORD], [SHIPMAST].[SHIPYY], [SHIPMAST].[SHIPMM], [SHIPMAST].[SHIPDD], [SHIPMAST].[SHSHAP], [SHIPMAST].[shape], [SHIPMAST].[SHINSM], [SHIPMAST].[SHSQTY], [SHIPMAST].[Shipped], [SHIPMAST].[SHUOM], [SHIPMAST].[SHBQTY]'

DECLARE @output_query NVARCHAR(MAX); 
EXEC mrs.my_sp_translate_sql_query @input_query = 'SELECT TOP(100) [SHIPMAST].[SHIPMAST], [SHIPMAST].[SH], [SHIPMAST].[SHORDN], [SHIPMAST].[Shipment], [SHIPMAST].[SHCORD], [SHIPMAST].[SHIPYY], [SHIPMAST].[SHIPMM], [SHIPMAST].[SHIPDD], [SHIPMAST].[SHSHAP], [SHIPMAST].[shape], [SHIPMAST].[SHINSM], [SHIPMAST].[SHSQTY], [SHIPMAST].[Shipped], [SHIPMAST].[SHUOM], [SHIPMAST].[SHBQTY]', @translated_query = @output_query OUTPUT
SELECT @output_query AS TranslatedQuery;

EXEC dbo.sp_translate_sql_query
EXEC mrs.sp_translate_sql_query
EXEC my_sp_getAllColumnXPfromTables
EXEC mysp_format_query_with_descriptions
EXEC my_sp_getXPfromObjects                     --old

    @input_query NVARCHAR(MAX),
    @translated_query NVARCHAR(MAX) OUTPUT

USE Sigmatb;
EXEC mrs.usp_TranslateName @InputName = 'ARCUST'

select top(10) * from [mrs].[01_AS400_MSSQL_Equivalents]


/****************************************************************
GET EXTENDED PROPERTIES
*****************************************************************/
        -- =============================================
        -- Usage Examples:
        -- =============================================

        -- Example 1: Get extended properties for ALL tables/views and their columns in the database
        EXEC mrs.usp_GetExtendedProperties;

        -- Example 2: Get extended properties for a specific table ('YourTableName')
        --            This includes properties defined on the table itself AND on all of its columns.
        
        /*

/*
-- Example 3: Run Delete Mode for schema 'mrs', pattern 'z_%' (Debug OFF)
-- WARNING: This will delete properties! Review the pattern carefully.

GO
*/

        -- coooool
        EXEC mrs.UpdateExtendedPropertiesForZTables @OperationMode = 0, @SchemaName = 'mrs', @TableNamePattern = 'z_%', @DebugMode = 0; --DELETE
        EXEC mrs.UpdateExtendedPropertiesForZTables @DebugMode = 0                                                                      --UPDATE
        EXEC mrs.usp_GetExtendedProperties;                                                                                          --VERIFIES ALL TABLES
        EXEC mrs.usp_GetExtendedProperties @TableName = 'z_Item_Master_File_____ITEMMAST';                                              --VERIFIES 1 TABLE
        EXEC mrs.usp_GetExtendedProperties @TableName = 'z_Item_Master_File_____ITEMMAST', @ColumnName = 'PSI_=_PER_SQUARE_INCH_PLI_=_PER_LINEAR_INCH_"___"=_____IMWUOM';   --VERIFIES 1 COLUMN

        USE Sigmatb;
        EXEC mrs.usp_TranslateName @InputName = 'ARCUST'    --no
        DECLARE @TranslatedName NVARCHAR(MAX), @ContextTableName NVARCHAR(MAX), @InputName NVARCHAR(MAX); SET @InputName = 'ITEMHIST'; SET @ContextTableName = NULL; EXEC mrs.usp_TranslateObjectName @InputName = @InputName, @ContextTableName = @ContextTableName, @TranslatedName = @TranslatedName OUTPUT; SELECT @TranslatedName;
            --no

        -- Example 4: (Invalid Use Case Test) Try to get properties for a column without specifying the table
        --            This should raise the custom error defined in the procedure.
        -- EXEC mrs.usp_GetExtendedProperties @ColumnName = 'YourColumnName';



