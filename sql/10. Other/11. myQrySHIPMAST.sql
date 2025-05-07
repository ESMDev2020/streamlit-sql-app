/*****************************************************************************************************
THIS QUERY IS ABOUT THE SHIPPING MASTER FILE
*****************************************************************************************************/

SELECT TOP (100) 

--Important
      [Transaction_#_____SHORDN]
      ,[Cust_P/O#_____SHCORD]
      ,[ITEM_NUMBER_____SHITEM]
      ,[Material_Sales_Stock_____SHMSLS]
      ,[Shipment_Type_Flag_____SHTYPE]
      ,[Cutting/Process_Flag_____SHCUTC]
      ,[In_Sales_Dept_____SHDPTI]
      ,[CUSTOMER_NUMBER_____SHCUST]
      ,[Orig_cust#_____SHCSTO]
      , '-' as sec_Sales
      --Cost, freight, weight
      ,[Matl_Sales_Direct_____SHMSLD]
      ,[Proc_Sales_Stock_____SHPSLS]
      ,[Process_Sales_Direct_____SHPSLD]
        --Cost, 
            , '***********' as sec_Cost
      ,[Material_Cost_Stock_____SHMCSS]
      ,[Material_Cost_Direct_____SHMCSD]
      ,[Processing_Cost_Stock_____SHPCSS]
      ,[Processing_Cost_Direct_____SHPCSD]
      ,[UNIT_PRICE_____SHUNSP]
      ,[Unit_Selling_Price_UOM_____SHUUOM]

        --Sales Inventory, 
      , '***********' as sec_SalesInventory      
      ,[Sales_Qty_Stock_____SHSLSS]
      ,[Sales_Qty_Direct_____SHSLSD]
      ,[Sales_Weight_Stock_____SHSWGS]
      ,[Sales_Weight_Direct_____SHSWGD]
        --Freight
      , '***********' as sec_Freight
      ,[Frght_Sales_Stock_____SHFSLS]
      ,[Frght_Sales_Direct_____SHFSLD]
      ,[Freight-In_Cost_Stock_____SHFISS]
      ,[Freight-In_Cost_Direct_____SHFISD]
      ,[Frght-Out_Cost_Stock_____SHFOSS]
      ,[Frght-Out_Cost_Direct_____SHFOSD]
      ,[Freight_local+road_____SHFRGH]
      --Scrap
      , '***********' as sec_Scrap
      ,[Fin_Scrap_Fctr_Stock_____SHFSFS]
      ,[Fin_Scrap_Fctr_Direct_____SHFSFD]
      ,[Actual_Scrap_Dollars_____SHSCDL]
      ,[Actual_Scrap_LBS_____SHSCLB]
      ,[Actual_Scrap_KGS_____SHSCKG]

        --Delivery
      , '***********' as sec_Delivery
      ,[Truck_Route_____SHTRCK]
      ,[ADDRESS_ONE_____SHADR1]
      ,[ADDRESS_TWO_____SHADR2]
      ,[ADDRESS_THREE_____SHADR3]
      ,[CITY_25_POS_____SHCITY]
      ,[State_Code_____SHSTAT]
      ,[Zip_Code_____SHZIP]
      ,[SHIP-TO_COUNTRY_____SHSCTY]

        --Shipment
      , '***********' as sec_Shipment
      ,[Shipped_Qty_____SHSQTY]
      ,[SHIPPED_QTY_UOM_____SHUOM]
      ,[Billing_Qty_____SHBQTY]
      ,[BILLING_QTY_UOM_____SHBUOM]
      ,[Order_Qty_____SHOQTY]
      ,[ORDER_QTY_UOM_____SHOUOM]
      ,[Shipped_Total_LBS_____SHTLBS]
      ,[Shipped_Total_PCS_____SHTPCS]
      ,[Shipped_Total_FTS_____SHTFTS]
      ,[Shipped_Total_Sq.Ft_____SHTSFT]
      ,[Theo._Meters_____SHTMTR]
      ,[Theo_Kilos_____SHTKG]
      ,[Processing_Charge_____SHPRCG]
      ,[Handling_Charge_____SHHAND]
      ,[Outside_Salesman_____SHOUTS]

        --Unknown
      , '***********' as sec_Unknown
      ,[Adjusted_GP%_____SHADPC]

        --More details
      , '***********' as sec_MoreDetails
      ,[Other_Sales_Stock_____SHOSLS]
      ,[Other__Sales_Direct_____SHOSLD]
      ,[Discount_Sales_Stock_____SHDSLS]
      ,[Discnt_Sales_Direct_____SHDSLD]

      ,[Other_Cost_Stock_____SHOCSS]
      ,[Other_Cost_Direct_____SHOCSD]
      ,[Admin_Burden_Stock_____SHADBS]
      ,[Admin_Burden_Direct_____SHADBD]
      ,[Oper_Burden_Stock_____SHOPBS]
      ,[Oper_Burden_Direct_____SHOPBD]
      ,[Inv_Adj_Stock_____SHIAJS]
      ,[Inv_Adj_Direct_____SHIAJD]

      ,[S/A_addition_flag_____SHSAFL]
      ,[Order_designation_Code_____SHODES]
      ,[Shop_OLD_____SHSHOP]
      ,[CUSTOMER_SHIP-TO_____SHSHTO]
      ,[BILL-TO_COUNTRY_____SHBCTY]
      ,[TEMP_SHIP-TOq_____SHTMPS]
      ,[Sale_Territory_____SHSTER]
      ,[Customer_Trade_____SHTRAD]
      ,[Bus._Potential_Class_____SHBPCC]
      ,[EEC_Code_____SHEEC]
      ,[Sector_Code_____SHSEC]
      ,[Invoice_Type_____SHITYP]
      ,[Out_Sales_Dept_____SHDPTO]
      ,[Orig_cust_dist#_____SHDSTO]
      ,[Orig_Slsmn_Dist_____SHSMDO]
      ,[Orig_Slsmn_____SHSLMO]
      ,[Inv_Comp_____SHICMP]
      ,[Model_Inventory_Flag_____SHMDIF]
      ,[Pricing_method_____SHPFLG]
      ,[Cust_Owned_Flag_____SHCOFL]
      ,[Scrap_Flag_____SHSCRP]

        --Dates
      , '-' as sec_Dates
      ,[Date_Ordered_Century_____SHORCC]
      ,[Date_Ordered_Year_____SHORYY]
      ,[Date_Ordered_Month_____SHORMM]
      ,[Date_Ordered_Day_____SHORDD]
      ,[Prom_Date_Century_____SHPRCC]
      ,[Prom_Date_Year_____SHPRYY]
      ,[Prom_Date_Month_____SHPRMM]
      ,[Prom_Date_Day_____SHPRDD]
      ,[Date_Inv_Century_____SHIVCC]
      ,[Date_Inv_Year_____SHIVYY]
      ,[Date_Inv_Month_____SHIVMM]
      ,[Date_Inv_Day_____SHIVDD]
      ,[Century_added_to_S/A_____SHSACC]
      ,[Year_added_to_S/A_____SHSAYY]
      ,[Month_added_to_S/A_____SHSAMM]
      ,[Day_added_to_S/A_____SHSADD]
      ,[Valid_Values_1_-_PRODUCT_NOT_STOCKED_____SHDBDC]
      ,[Shipment_Century_____SHIPCC]
      ,[Shipment_Year_____SHIPYY]
      ,[Shipment_Month_____SHIPMM]
      ,[Shipment_Day_____SHIPDD]
      ,[Related_part_flag_____SHRFLG]
      ,[Shape_____SHSHAP]
      ,[3_POSITION_CLASS_____SHCLS3]
      ,[Salesman_Dist_____SHLDIS]
      ,[Inside_Salesman_____SHINSM]




      ,[BILLING_QTY_INCHES_____SHBINC]
      ,[ORDER_QTY_INCHES_____SHOINC]

      ,[Job_Name_____SHJOB]
  FROM [Sigmatb].[mrs].[z_Shipments_File_____SHIPMAST]