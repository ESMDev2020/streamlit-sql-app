USE SigmaTB;
GO

SELECT TOP(1000)
    [Transaction_#_____IHTRN#],
    [Document_#_____IHDOC#],
    [PO_Rcpt_List#_____IHLIST],
    [ITEM_NUMBER_____IHITEM],
    [Transaction_Type_____IHTRNT],
    [Trans_Subtype_____IHSTYP],
    [Transport_ID_____IHTID],
    [Debit_Memo#_____IHDMEM],
    [Vendor_#_____IHVNDR],
    [Assoc_PO_Number_____IHPONM],
    [Trans_Length_____IHLNTH],
    [CUSTOMER_NUMBER_____IHCUST],
    [TAG_NUMBER_ALPHA_____IHTAG],
    [Heat_#_____IHHEAT],
    [Extended_Trans_Price_____IHEPRC],
    [PROCESSED_YEAR_____IHPRPY],
    [Trans_YY_____IHTRYY],
    [Trans_MM_____IHTRMM],
    [Trans_Width_____IHWDTH],
    [Extended_Trans_Cost_____IHECST],
    [Qty_On_Hand_____IHQOH],
    [Average_Cost_____IHACST],
    [Trans_Cost_____IHTCST],
    [Trans_Price_____IHTPRC],
    [Trans_Inv_Qty_____IHTQTY]
FROM
    [SigmaTB].[mrs].[z_Item_Transaction_History_____ITEMHIST];