USE SigmaTB;
go

SELECT top(1000)
    [Trans#_____GLTRN#],
    [Reference_Number_____GLREF],
    [Batch_Number_____GLBTCH],
    [G/L_Account_Number_____GLACCT],
    [Vendor_Name_/_Customer_Name_/_Application_____GLDESC],
    [CUSTOMER_NUMBER_____GLCUST],
    [G/L_Amount_-_Queries_____GLAMTQ],
    [G/L_Amount_____GLAMT],
    [Application_Code_____GLAPPL],
    [Credit_/_Debit_Code_____GLCRDB],
    [Record_Code_____GLRECD],
    [Order_Type_____GLTYPE],
    [Transaction_Type_____GLTRNT],
    [Lock_Box_Number_____GLLOCK],
    [Related_Party_Customer_or_Vendor_____GLRP#],
    [A/P_Trans_____GLAPTR],
    [G/L_Posting_Year_____GLPPYY],
    [Posting_Year_____GLPYY],
    [Posting_Day_____GLPDD],
    [Posting_Month_____GLPMM]
FROM
    [mrs].[z_General_Ledger_Transaction_File_____GLTRANS];