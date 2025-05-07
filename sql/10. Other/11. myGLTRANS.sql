SELECT TOP (1000) 

-- type
        '***************' AS tab_Transaction
      ,[CUSTOMER_NUMBER_____GLCUST]         -- FK
      ,[Vendor_Name_/_Customer_Name_/_Application_____GLDESC]
      ,[G/L_Account_Number_____GLACCT]      --FK
      ,[G/L_Amount_____GLAMT]               -- Amount (Absolute value)
      ,[G/L_Amount_-_Queries_____GLAMTQ]    -- Amount

    --Administrative
    ,'***************' AS tab_Administrative
      ,[Credit_/_Debit_Code_____GLCRDB]         --C, D
      ,[Application_Code_____GLAPPL]        --IN, IA, IU, AP, CR
      ,[Transaction_Type_____GLTRNT]        --OE, IA, PO, MP
      ,[Order_Type_____GLTYPE]              --null, Q, O, I, A

    --Reference
    ,'***************' AS tab_Reference
      ,[Reference_Number_____GLREF]                                 --FK    50699
      ,[Trans#_____GLTRN#]                                          --FK....843366.0..... LOOK FOR
      ,[Trans_Dist_____GLTRDS]

    --Unknown
    ,'***************' AS tab_Unknown
      ,[Lock_Box_Number_____GLLOCK]         -- FK - Lockbox
      ,[Main_Line_____GLMLIN]

      --Dates
    ,'***************' AS tab_Dates
      ,[G/L_Posting_Period_____GLPERD]      --Date - Posting
      ,[G/L_Posting_Year_____GLPPYY]
      ,[Posting_Century_____GLPCC]
      ,[Posting_Year_____GLPYY]
      ,[Posting_Month_____GLPMM]
      ,[Posting_Day_____GLPDD]
      ,[System_Year_____GLSYY]
      ,[System_Month_____GLSMM]
      ,[System_Day_____GLSDD]


    --On Shipment
    ,'***************' AS tab_Shipment
      ,[Batch_District_____GLBDIS]                                  --0, 1,  ??????
      ,[Batch_Number_____GLBTCH]                                    --FK

    --Customer / Vendor
    ,'***************' AS tab_Customer_Vendor
      ,[Related_Parties_____GLRPTY]                                 -- Null, V... should be (Customer, Vendor
      ,[Related_Party_Customer_or_Vendor_____GLRP#]                 -- FK. With this I can link the freight. 
      ,[Vendor_Name_/_Customer_Name_/_Application_____GLDESC]

        
    --Dates
    ,'***************' AS tab_Dates
      ,[Reference_Cent_____GLRFCC]
      ,[Reference_Year_____GLRFYY]
      ,[Reference_Month_____GLRFMM]
      ,[Reference_Day_____GLRFDD]
      ,[Extract_Date_____GLEXDT]            --Dates
      ,[Extract_Time_____GLEXTM]            --Dates
      ,[Time_____GLTIME]

    --Unknown system
    ,'***************' AS tab_UnknownSystem
      ,[Program_ID_____GLPGM]                                       --OE222
      [Record_Code_____GLRECD]                                      -- Active, E
      ,[A/P_Trans_____GLAPTR]
      ,[Display_ID_____GLDSP]               --KSAUCEDO
      ,[User_____GLUSER]

-- Not used
    ,'***************' AS tab_NotUsed
      ,[Cost_Center_____GLCSTC]

  FROM [Sigmatb].[mrs].[z_General_Ledger_Transaction_File_____GLTRANS]




  --      ,[Company_Number_____GLCOMP]
--      ,[District_Number_____GLDIST]
--      ,[Cust_Dist_____GLCDIS]         1, 0
