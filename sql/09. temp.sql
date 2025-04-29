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
