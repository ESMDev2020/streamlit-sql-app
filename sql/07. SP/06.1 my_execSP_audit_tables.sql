USE SigmaTB;

EXEC [mrs].[my_sp_audit_tables] '[Sigmatb].mrs.[z_Vendor_Master_File_____APVEND]';

SELECT name from sys.tables where name like '%itemmast'

EXEC [mrs].[my_sp_audit_tables] @SchemaName = N'mrs', @TableName = N'z_Item_Master_File_____ITEMMAST';

select 
CRT_Description_____IMCRTD
from 
[mrs].z_Item_Master_File_____ITEMMAST


select 
CRT_Description_____IMCRTD
from 
[mrs].z_Item_Master_File_____ITEMMAST
where
CRT_Description_____IMCRTD LIKE 'A'

