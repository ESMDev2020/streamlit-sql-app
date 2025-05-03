USE SigmaTB;

EXEC [mrs].[my_sp_audit_tables] '[Sigmatb].mrs.[z_Vendor_Master_File_____APVEND]';

SELECT name from sys.tables where name like '%spheader'

EXEC [mrs].[my_sp_audit_tables] @SchemaName = N'mrs', @TableName = N'z_Service_Purchase_Order_Header_File_____SPHEADER'

select 
CRT_Description_____IMCRTD
from 
[mrs].z_Item_Master_File_____ITEMMAST

SELECT 
    [z_Item_on_Hand_File_____ITEMONHD].[ITEM_NUMBER_____IOITEM], 
    [z_Item_on_Hand_File_____ITEMONHD].[Base_Price_____IOBPRC] 
FROM mrs.[z_Item_on_Hand_File_____ITEMONHD]


select 
Reference_Code_____IMREFC
from 
[mrs].z_Item_Master_File_____ITEMMAST
where
CRT_Description_____IMCRTD LIKE 'A'



SELECT @@VERSION;
