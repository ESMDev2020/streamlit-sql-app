use sigmatb;
go

select distinct([Shipment_Type_Flag_____SHTYPE]), count(*) AS Ocurrences
FROM [Sigmatb].[mrs].[z_Shipments_File_____SHIPMAST] 
GROUP BY [Shipment_Type_Flag_____SHTYPE]


select distinct([Model_Inventory_Flag_____SHMDIF]), count(*) AS Ocurrences
FROM [Sigmatb].[mrs].[z_Shipments_File_____SHIPMAST] 
GROUP BY [Model_Inventory_Flag_____SHMDIF]

select distinct([Transaction_#_____SHORDN]), count(*) AS Ocurrences
FROM [Sigmatb].[mrs].[z_Shipments_File_____SHIPMAST] 
GROUP BY [Transaction_#_____SHORDN]

select distinct([Material_Cost_Direct_____SHMCSD]), count(*) AS Ocurrences
FROM [Sigmatb].[mrs].[z_Shipments_File_____SHIPMAST] 
GROUP BY [Material_Cost_Direct_____SHMCSD]



drop PROCEDURE mrs.usp_TranslateObjectName 



DECLARE @myvarInputSQL NVARCHAR(MAX);
DECLARE @myVarOutputSQL NVARCHAR(MAX);
set @myvarInputSQL = 'SELECT [SPHEADER].[BSREC] FROM [SPHEADER]'
EXEC [mrs].[usp_TranslateSQLQuery] @p_InputQuery = @myVarInputSQL, @p_TranslatedQuery = @myVarOutputSQL OUTPUT;
print @myVarOutputSQL







-- See which tables have been processed
SELECT 
    SchemaName + '.' + TableName AS TableName,
    COUNT(ColumnName) AS ColumnsAnalyzed,
    MAX(AnalysisTime) AS LastAnalyzed
FROM mrs.PK_Analysis_Results
GROUP BY SchemaName, TableName
ORDER BY LastAnalyzed DESC;

-- See progress count
SELECT 
    COUNT(DISTINCT SchemaName + '.' + TableName) AS TablesProcessed,
    (SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped = 0) AS TotalTables,
    CAST(COUNT(DISTINCT SchemaName + '.' + TableName) * 100.0 / 
         (SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped = 0) AS DECIMAL(5,2)) AS PercentComplete
FROM mrs.PK_Analysis_Results;