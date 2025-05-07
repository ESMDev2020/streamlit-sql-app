USE SigmaTB;
GO

select [Vendor_#_____VVNDR],
[Vendor_Name_____VNAME],
[Federal_ID_Number_____VFEDID],
[SCAC_code_____VSCAC],
[Default_G/L#_____VGLACT],
[Vendor_Alpha_Search_____VALPHA],
[CITY_25_POS_____VCITY],
[ZIP_CODE_12_POS_____VZIP],
[Vendor_Address_1_____VADDR1],
[Vendor_Address_2_____VADDR2],
[Vendor_Address_3_____VADDR3],
[Vendor_FAX_Number_____VFPHON],
[Vendor_Phone_Number_____VPHONE],
[E-MAIL_ADDRESS_____VEMAL],
[WEB_SITE_ADDRESS_____VWEBS],
[State_Code_____VSTATE],
[Country_____VCNTRY]

FROM
    [mrs].[z_Vendor_Master_File_____APVEND]