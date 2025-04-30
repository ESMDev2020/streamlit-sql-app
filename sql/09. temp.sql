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