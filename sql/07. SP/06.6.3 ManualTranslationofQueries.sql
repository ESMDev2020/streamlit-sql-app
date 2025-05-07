USE SigmaTB;
GO
DECLARE @myvarInputSQL NVARCHAR(MAX), @myVarOutputSQL NVARCHAR(MAX);




--ROP - Base Price
    --ORIGINAL
    --set @myvarInputSQL = '''SELECT ''price'', [ITEMONHD].[IOITEM], [ITEMONHD].[IOBPRC] FROM [ITEMONHD] [ITEMONHD];'''
    --TRANSLATED
    --SELECT 'price', [mrs].[z_Item_on_Hand_File_____ITEMONHD].[ITEM_NUMBER_____IOITEM], [z_Item_on_Hand_File_____ITEMONHD].[Base_Price_____IOBPRC] FROM [mrs].[z_Item_on_Hand_File_____ITEMONHD];



-- ROP - Material Processing
            /*--Original
            set @myvarInputSQL = 'SELECT [MPDETAIL].[MDORDR], [APVEND].[VVNDR], [APVEND].[VALPHA], [MPDETAIL].[MDCLOS], [MPDETAIL].[MDITEM], 
                    [MPDETAIL].[MDCRTD], [MPDETAIL].[MDRQCC]*1000000+[MPDETAIL].[MDRQYY]*10000+[MPDETAIL].[MDRQMM]*100+[MPDETAIL].[MDRQDD], [MPDETAIL].[MDOQTY], 
                    [MPDETAIL].[MDOUOM], [MPDETAIL].[MDIQTY] 
            FROM    [APVEND] [APVEND], [MPDETAIL] [MPDETAIL] 
            WHERE   [APVEND].[VCOMP] = [MPDETAIL].[MDCOMP] AND [APVEND].[VVNDR] = [MPDETAIL].[MDVNDR] ORDER BY [MPDETAIL].[MDITEM], [MPDETAIL].[MDORDR] DESC;'
            */

            /* TRANSLATED QUERY but we need to fix the data conversion
            SELECT [z_Material_Processing_Order_Detail_____MPDETAIL].[Transaction_#_____MDORDR], [z_Vendor_Master_File_____APVEND].[Vendor_#_____VVNDR], [z_Vendor_Master_File_____APVEND].[Vendor_Alpha_Search_____VALPHA], [z_Material_Processing_Order_Detail_____MPDETAIL].[=_OPEN__C_=_CLOSED_____MDCLOS], [z_Material_Processing_Order_Detail_____MPDETAIL].[ITEM_NUMBER_____MDITEM],
            [z_Material_Processing_Order_Detail_____MPDETAIL].[CRT_DESCRIPTION_____MDCRTD], [z_Material_Processing_Order_Detail_____MPDETAIL].[REQUESTED_SHIP_CENTURY_____MDRQCC]*1000000+[z_Material_Processing_Order_Detail_____MPDETAIL].[REQUESTED_SHIP_YEAR_____MDRQYY]*10000+[z_Material_Processing_Order_Detail_____MPDETAIL].[REQUESTED_SHIP_MONTH_____MDRQMM]*100+[z_Material_Processing_Order_Detail_____MPDETAIL].[REQUESTED_SHIP_DAY_____MDRQDD], [z_Material_Processing_Order_Detail_____MPDETAIL].[ON_ORDER_QUANTITY_____MDOQTY],
            [z_Material_Processing_Order_Detail_____MPDETAIL].[ORIGINAL_ORDERED_UOM_____MDOUOM], [z_Material_Processing_Order_Detail_____MPDETAIL].[ORDER_QUANTITY_____MDIQTY]
            FROM [mrs].[z_Vendor_Master_File_____APVEND] [z_Vendor_Master_File_____APVEND], [mrs].[z_Material_Processing_Order_Detail_____MPDETAIL] [z_Material_Processing_Order_Detail_____MPDETAIL]
            WHERE [z_Vendor_Master_File_____APVEND].[COMPANY_NUMBER_____VCOMP] = [z_Material_Processing_Order_Detail_____MPDETAIL].[COMPANY_NUMBER_____MDCOMP] AND [z_Vendor_Master_File_____APVEND].[Vendor_#_____VVNDR] = [z_Material_Processing_Order_Detail_____MPDETAIL].[Vendor_#_____MDVNDR] ORDER BY [z_Material_Processing_Order_Detail_____MPDETAIL].[ITEM_NUMBER_____MDITEM], [z_Material_Processing_Order_Detail_____MPDETAIL].[Transaction_#_____MDORDR] DESC;
            */

    /*--This is the working query
    SELECT 'Material processing query', det.[Transaction_#_____MDORDR], vend.[Vendor_#_____VVNDR], vend.[Vendor_Alpha_Search_____VALPHA], det.[=_OPEN__C_=_CLOSED_____MDCLOS], det.[ITEM_NUMBER_____MDITEM], det.[CRT_DESCRIPTION_____MDCRTD], (CAST(CAST(det.[REQUESTED_SHIP_CENTURY_____MDRQCC] AS DECIMAL(5,1)) AS INT)*1000000+CAST(CAST(det.[REQUESTED_SHIP_YEAR_____MDRQYY] AS DECIMAL(5,1)) AS INT)*10000+CAST(CAST(det.[REQUESTED_SHIP_MONTH_____MDRQMM] AS DECIMAL(5,1)) AS INT)*100+CAST(CAST(det.[REQUESTED_SHIP_DAY_____MDRQDD] AS DECIMAL(5,1)) AS INT)) AS CalculatedShipDate, det.[ON_ORDER_QUANTITY_____MDOQTY], det.[ORIGINAL_ORDERED_UOM_____MDOUOM], det.[ORDER_QUANTITY_____MDIQTY]
    FROM [mrs].[z_Vendor_Master_File_____APVEND] vend INNER JOIN [mrs].[z_Material_Processing_Order_Detail_____MPDETAIL] det
    ON vend.[COMPANY_NUMBER_____VCOMP] = det.[COMPANY_NUMBER_____MDCOMP] AND vend.[Vendor_#_____VVNDR] = det.[Vendor_#_____MDVNDR]
    ORDER BY det.[ITEM_NUMBER_____MDITEM], det.[Transaction_#_____MDORDR] DESC;
    */

--ROP - PRICE -- PO query
        /*
            --Original
            set @myvarInputSQL = '''SELECT ''Purchase order'', [PODETAIL].[BDPONO], [PODETAIL].[BDVNDR], [APVEND].[VNAME], [PODETAIL].[BDRECD], [PODETAIL].[BDITEM], [PODETAIL].[BDCRTD], [PODETAIL].[bdrpcc]*1000000+[PODETAIL].[bdrpyy]*10000+[PODETAIL].[bdrpmm]*100+[PODETAIL].[bdrpdd], [PODETAIL].[BDOQOO], [PODETAIL].[BDIUOM], [PODETAIL].[BDCQOO], [PODETAIL].[BDOOQ], [PODETAIL].[BDTIQR], [PODETAIL].[bdpocc]*1000000+[PODETAIL].[bdpoyy]*10000+[PODETAIL].[bdpomm]*100+[PODETAIL].[bdpodd], [PODETAIL].[bdrccc]*1000000+[PODETAIL].[bdrcyy]*10000+[PODETAIL].[bdrcmm]*100+[PODETAIL].[bdrcdd]
            FROM [PODETAIL] LEFT OUTER JOIN [APVEND] ON [PODETAIL].[BDVNDR] = [APVEND].[VVNDR]
            WHERE ([PODETAIL].[BDITEM] Between ''50000'' And ''99998'')
            ORDER BY [PODETAIL].[BDITEM], [PODETAIL].[BDPONO] DESC'''

            -- Translated query. Needs to be adapted to MSSQL
            SELECT 'Purchase order query', [z_Purchase_Order_Detail_File_____PODETAIL].[Transaction_#_____BDPONO], [z_Purchase_Order_Detail_File_____PODETAIL].[Vendor_#_____BDVNDR], [z_Vendor_Master_File_____APVEND].[Vendor_Name_____VNAME], [z_Purchase_Order_Detail_File_____PODETAIL].[Record_Code_____BDRECD], [z_Purchase_Order_Detail_File_____PODETAIL].[ITEM_NUMBER_____BDITEM], [z_Purchase_Order_Detail_File_____PODETAIL].[CRT_Description_____BDCRTD], [z_Purchase_Order_Detail_File_____PODETAIL].[Revised_Promise_Century_____BDRPCC]*1000000+[z_Purchase_Order_Detail_File_____PODETAIL].[Revised_Promise_Year_____BDRPYY]*10000+[z_Purchase_Order_Detail_File_____PODETAIL].[Revised_Promise_Month_____BDRPMM]*100+[z_Purchase_Order_Detail_File_____PODETAIL].[Revised_Promise_Day_____BDRPDD], [z_Purchase_Order_Detail_File_____PODETAIL].[Original_Inventory_Quantity_____BDOQOO], [z_Purchase_Order_Detail_File_____PODETAIL].[Inventory_UOM_____BDIUOM], [z_Purchase_Order_Detail_File_____PODETAIL].[Current_Inv._Quantity_Ordered_/_Received_____BDCQOO], [z_Purchase_Order_Detail_File_____PODETAIL].[Original_Ordered__Quantity_____BDOOQ], [z_Purchase_Order_Detail_File_____PODETAIL].[Total_Inventory_Quantity_Received_____BDTIQR], [z_Purchase_Order_Detail_File_____PODETAIL].[Purchase_Order_Century_____BDPOCC]*1000000+[z_Purchase_Order_Detail_File_____PODETAIL].[Purchase_Order_Year_____BDPOYY]*10000+[z_Purchase_Order_Detail_File_____PODETAIL].[Purchase_Order_Month_____BDPOMM]*100+[z_Purchase_Order_Detail_File_____PODETAIL].[Purchase_Order_Day_____BDPODD], [z_Purchase_Order_Detail_File_____PODETAIL].[Received_Century_____BDRCCC]*1000000+[z_Purchase_Order_Detail_File_____PODETAIL].[Received_Year_____BDRCYY]*10000+[z_Purchase_Order_Detail_File_____PODETAIL].[Received_Month_____BDRCMM]*100+[z_Purchase_Order_Detail_File_____PODETAIL].[Received_Day_____BDRCDD]
            FROM [mrs].[z_Purchase_Order_Detail_File_____PODETAIL] LEFT OUTER JOIN [mrs].[z_Vendor_Master_File_____APVEND] ON [z_Purchase_Order_Detail_File_____PODETAIL].[Vendor_#_____BDVNDR] = [z_Vendor_Master_File_____APVEND].[Vendor_#_____VVNDR]
            WHERE ([z_Purchase_Order_Detail_File_____PODETAIL].[ITEM_NUMBER_____BDITEM] Between '50000' And '99998')
            ORDER BY [z_Purchase_Order_Detail_File_____PODETAIL].[ITEM_NUMBER_____BDITEM], [z_Purchase_Order_Detail_File_____PODETAIL].[Transaction_#_____BDPONO] DESC

        --Working query
        SELECT 'Purchase order query', pod.[Transaction_#_____BDPONO], pod.[Vendor_#_____BDVNDR], vend.[Vendor_Name_____VNAME], pod.[Record_Code_____BDRECD], pod.[ITEM_NUMBER_____BDITEM], pod.[CRT_Description_____BDCRTD], (CAST(CAST(pod.[Revised_Promise_Century_____BDRPCC] AS DECIMAL(5,1)) AS INT)*1000000+CAST(CAST(pod.[Revised_Promise_Year_____BDRPYY] AS DECIMAL(5,1)) AS INT)*10000+CAST(CAST(pod.[Revised_Promise_Month_____BDRPMM] AS DECIMAL(5,1)) AS INT)*100+CAST(CAST(pod.[Revised_Promise_Day_____BDRPDD] AS DECIMAL(5,1)) AS INT)) AS RevisedPromiseDate, pod.[Original_Inventory_Quantity_____BDOQOO], pod.[Inventory_UOM_____BDIUOM], pod.[Current_Inv._Quantity_Ordered_/_Received_____BDCQOO], pod.[Original_Ordered__Quantity_____BDOOQ], pod.[Total_Inventory_Quantity_Received_____BDTIQR],
        (CAST(CAST(pod.[Purchase_Order_Century_____BDPOCC] AS DECIMAL(5,1)) AS INT)*1000000+CAST(CAST(pod.[Purchase_Order_Year_____BDPOYY] AS DECIMAL(5,1)) AS INT)*10000+CAST(CAST(pod.[Purchase_Order_Month_____BDPOMM] AS DECIMAL(5,1)) AS INT)*100+CAST(CAST(pod.[Purchase_Order_Day_____BDPODD] AS DECIMAL(5,1)) AS INT)) AS PurchaseOrderDate, (CAST(CAST(pod.[Received_Century_____BDRCCC] AS DECIMAL(5,1)) AS INT)*1000000+CAST(CAST(pod.[Received_Year_____BDRCYY] AS DECIMAL(5,1)) AS INT)*10000+CAST(CAST(pod.[Received_Month_____BDRCMM] AS DECIMAL(5,1)) AS INT)*100+CAST(CAST(pod.[Received_Day_____BDRCDD] AS DECIMAL(5,1)) AS INT)) AS ReceivedDate
        FROM [mrs].[z_Purchase_Order_Detail_File_____PODETAIL] pod LEFT OUTER JOIN [mrs].[z_Vendor_Master_File_____APVEND] vend ON pod.[Vendor_#_____BDVNDR] = vend.[Vendor_#_____VVNDR]
        WHERE (pod.[ITEM_NUMBER_____BDITEM] Between '50000' And '99998') ORDER BY pod.[ITEM_NUMBER_____BDITEM], pod.[Transaction_#_____BDPONO] DESC;
*/



--ROP - QUERY -- ROP QUERY
/*
        --Original
        set @myvarInputSQL = '''SELECT ''ROP Query'', [ITEMMAST].[IMFSP2], [ITEMMAST].[IMITEM], [ITEMMAST].[IMSIZ1], [ITEMMAST].[IMSIZ2], [ITEMMAST].[IMSIZ3], [ITEMMAST].[IMDSC2], [ITEMMAST].[IMWPFT], [ITEMONHD].[IOACST], [ITEMONHD].[IOQOH], [ITEMONHD].[IOQOO], [ITEMONHD].[IOQOR]+[ITEMONHD].[IOQOOR], [ITEMMAST].[IMDSC1], [ITEMMAST].[IMWUOM], [ITEMMAST].[IMCSMO]
        FROM [ITEMMAST] [ITEMMAST], [ITEMONHD] [ITEMONHD]
        WHERE [ITEMONHD].[IOITEM] = [ITEMMAST].[IMITEM] AND (([ITEMMAST].[IMRECD]=''A'') AND ([ITEMMAST].[IMITEM] Between ''49999'' And ''90000''))
        ORDER BY [ITEMMAST].[IMFSP2]'''

        --Ready
        SELECT 'ROP Query', [z_Item_Master_File_____ITEMMAST].[Fast_Path_Item_Description_____IMFSP2], [z_Item_Master_File_____ITEMMAST].[ITEM_NUMBER_____IMITEM], [z_Item_Master_File_____ITEMMAST].[Size_1_____IMSIZ1], [z_Item_Master_File_____ITEMMAST].[Size_2_____IMSIZ2], [z_Item_Master_File_____ITEMMAST].[Size_3_____IMSIZ3], [z_Item_Master_File_____ITEMMAST].[Item_Print_Descr_Two_____IMDSC2], [z_Item_Master_File_____ITEMMAST].[Weight_Per_Foot_____IMWPFT], [z_Item_on_Hand_File_____ITEMONHD].[Average_Cost_____IOACST], [z_Item_on_Hand_File_____ITEMONHD].[Qty_On_Hand_____IOQOH], [z_Item_on_Hand_File_____ITEMONHD].[Qty_On_Order_____IOQOO], [z_Item_on_Hand_File_____ITEMONHD].[Qty_On_Reserved_____IOQOR]+[z_Item_on_Hand_File_____ITEMONHD].[Qty_On_Order_Rsrvd_____IOQOOR], [z_Item_Master_File_____ITEMMAST].[Item_Print_Descr_One_____IMDSC1], [z_Item_Master_File_____ITEMMAST].[PSI_=_PER_SQUARE_INCH_PLI_=_PER_LINEAR_INCH_"___"=_____IMWUOM], [z_Item_Master_File_____ITEMMAST].[Company_SMO_____IMCSMO]
        FROM [mrs].[z_Item_Master_File_____ITEMMAST] [z_Item_Master_File_____ITEMMAST], [mrs].[z_Item_on_Hand_File_____ITEMONHD] [z_Item_on_Hand_File_____ITEMONHD]
        WHERE [z_Item_on_Hand_File_____ITEMONHD].[ITEM_NUMBER_____IOITEM] = [z_Item_Master_File_____ITEMMAST].[ITEM_NUMBER_____IMITEM] AND (([z_Item_Master_File_____ITEMMAST].[Record_Code_____IMRECD]='A') AND ([z_Item_Master_File_____ITEMMAST].[ITEM_NUMBER_____IMITEM] Between '49999' And '90000'))
        ORDER BY [z_Item_Master_File_____ITEMMAST].[Fast_Path_Item_Description_____IMFSP2]
*/

--ROP_query_
--Sales Data	
            /*
            --Original
            set @myvarInputSQL = '''SELECT ''Sales data'', [OEOPNORD].[OORECD], [OEDETAIL].[ODTYPE], [OEDETAIL].[ODITEM], [OEDETAIL].[ODORDR], [OEOPNORD].[OOCUST], [ARCUST].[CALPHA], [OEDETAIL].[ODTLBS], [OEDETAIL].[ODTFTS], [OEOPNORD].[OOOCC]*1000000 + [OEOPNORD].[OOOYY]*10000 + [OEOPNORD].[OOOMM]*100 + [OEOPNORD].[OOODD], [ARCUST].[CSMDI1]*100 + [ARCUST].[CSLMN1]  
                    FROM [ARCUST] [ARCUST], [OEDETAIL] [OEDETAIL], [OEOPNORD] [OEOPNORD]  
                    WHERE [OEDETAIL].[ODORDR] = [OEOPNORD].[OOORDR] AND [OEOPNORD].[OOCUST] = [ARCUST].[CCUST] AND ([OEOPNORD].[OORECD] = ''A'' AND [OEDETAIL].[ODTYPE] IN (''A'', ''C''))  
                    ORDER BY [OEDETAIL].[ODITEM];'''

            --Translated
            SELECT 'Sales data', [z_Open_Order_File_____OEOPNORD].[Record_Code_____OORECD], [z_Order_Detail_File_____OEDETAIL].[Order_Type_____ODTYPE], [z_Order_Detail_File_____OEDETAIL].[ITEM_NUMBER_____ODITEM], [z_Order_Detail_File_____OEDETAIL].[Transaction_#_____ODORDR], [z_Open_Order_File_____OEOPNORD].[CUSTOMER_NUMBER_____OOCUST], [z_Customer_Master_File_____ARCUST].[Customer_Alpha_Name_____CALPHA], [z_Order_Detail_File_____OEDETAIL].[TOTAL_LBS_____ODTLBS], [z_Order_Detail_File_____OEDETAIL].[TOTAL_FTS_____ODTFTS], [z_Open_Order_File_____OEOPNORD].[ORDER_DATE_CENTURY_____OOOCC]*1000000 + [z_Open_Order_File_____OEOPNORD].[ORDER_DATE_YEAR_____OOOYY]*10000 + [z_Open_Order_File_____OEOPNORD].[ORDER_DATE_MONTH_____OOOMM]*100 + [z_Open_Order_File_____OEOPNORD].[ORDER_DATE_DAY_____OOODD], [z_Customer_Master_File_____ARCUST].[Salesman_One_District_Number_____CSMDI1]*100 + [z_Customer_Master_File_____ARCUST].[Salesman_One_Number_____CSLMN1]
            FROM [mrs].[z_Customer_Master_File_____ARCUST] [z_Customer_Master_File_____ARCUST], [mrs].[z_Order_Detail_File_____OEDETAIL] [z_Order_Detail_File_____OEDETAIL], [mrs].[z_Open_Order_File_____OEOPNORD] [z_Open_Order_File_____OEOPNORD]
            WHERE [z_Order_Detail_File_____OEDETAIL].[Transaction_#_____ODORDR] = [z_Open_Order_File_____OEOPNORD].[ORDER_NUMBER_____OOORDR] AND [z_Open_Order_File_____OEOPNORD].[CUSTOMER_NUMBER_____OOCUST] = [z_Customer_Master_File_____ARCUST].[CUSTOMER_NUMBER_____CCUST] AND ([z_Open_Order_File_____OEOPNORD].[Record_Code_____OORECD] = 'A' AND [z_Order_Detail_File_____OEDETAIL].[Order_Type_____ODTYPE] IN ('A', 'C'))
            ORDER BY [z_Order_Detail_File_____OEDETAIL].[ITEM_NUMBER_____ODITEM]

            --Converted. Working
            SELECT 'ROP - Sales data Query', O.[Record_Code_____OORECD], D.[Order_Type_____ODTYPE], D.[ITEM_NUMBER_____ODITEM], D.[Transaction_#_____ODORDR], O.[CUSTOMER_NUMBER_____OOCUST], C.[Customer_Alpha_Name_____CALPHA], D.[TOTAL_LBS_____ODTLBS], D.[TOTAL_FTS_____ODTFTS], CAST(CAST(O.[ORDER_DATE_CENTURY_____OOOCC] AS DECIMAL(5,1)) AS INT)*1000000 + CAST(CAST(O.[ORDER_DATE_YEAR_____OOOYY] AS DECIMAL(5,1)) AS INT)*10000 + CAST(CAST(O.[ORDER_DATE_MONTH_____OOOMM] AS DECIMAL(5,1)) AS INT)*100 + CAST(CAST(O.[ORDER_DATE_DAY_____OOODD] AS DECIMAL(5,1)) AS INT), CAST(CAST(C.[Salesman_One_District_Number_____CSMDI1] AS DECIMAL(5,1)) AS INT)*100 + CAST(CAST(C.[Salesman_One_Number_____CSLMN1] AS DECIMAL(5,1)) AS INT)
            FROM [mrs].[z_Customer_Master_File_____ARCUST] C JOIN [mrs].[z_Open_Order_File_____OEOPNORD] O ON O.[CUSTOMER_NUMBER_____OOCUST] = C.[CUSTOMER_NUMBER_____CCUST] JOIN [mrs].[z_Order_Detail_File_____OEDETAIL] D ON D.[Transaction_#_____ODORDR] = O.[ORDER_NUMBER_____OOORDR]
            WHERE O.[Record_Code_____OORECD] = 'A' AND D.[Order_Type_____ODTYPE] IN ('A', 'C')
            ORDER BY D.[ITEM_NUMBER_____ODITEM]
            */


--ROP_query_


--Tag Query	
        /*
        --Original
        set @myvarInputSQL = '''SELECT ''TAG query'', [ITEMTAG].[ITITEM], [ITEMTAG].[ITTAG], [ITEMTAG].[ITTDES], [ITEMTAG].[ITLNTH], [ITEMTAG].[ITTPCS], [ITEMTAG].[ITHEAT], [ITEMTAG].[ITV301], [ITEMTAG].[ITLOCT], [ITEMTAG].[ITTQTY], [ITEMTAG].[ITRQTY], [ITEMMAST].[IMFSP2]  
                FROM [ITEMMAST] [ITEMMAST], [ITEMTAG] [ITEMTAG]  
                WHERE [ITEMTAG].[ITITEM] = [ITEMMAST].[IMITEM] AND ([ITEMTAG].[ITRECD] = ''A'' AND [ITEMTAG].[ITITEM] > ''49999'')  
                ORDER BY [ITEMTAG].[ITITEM], [ITEMTAG].[ITHEAT], [ITEMTAG].[ITV301], [ITEMTAG].[ITLNTH];'''

        --Working
        SELECT 'ROP - TAG query', [z_Tag_Master_File_____ITEMTAG].[ITEM_NUMBER_____ITITEM], [z_Tag_Master_File_____ITEMTAG].[TAG_NUMBER_ALPHA_____ITTAG], [z_Tag_Master_File_____ITEMTAG].[Tag_Master_Description_____ITTDES], [z_Tag_Master_File_____ITEMTAG].[Numeric_Length_____ITLNTH], [z_Tag_Master_File_____ITEMTAG].[Tag_Pieces_____ITTPCS], [z_Tag_Master_File_____ITEMTAG].[Heat_#_____ITHEAT], [z_Tag_Master_File_____ITEMTAG].[Mill_Coil#_____ITV301], [z_Tag_Master_File_____ITEMTAG].[Warehouse_Loc_____ITLOCT], [z_Tag_Master_File_____ITEMTAG].[Tag_Quantity_____ITTQTY], [z_Tag_Master_File_____ITEMTAG].[Reserved_Quantity_____ITRQTY], [z_Item_Master_File_____ITEMMAST].[Fast_Path_Item_Description_____IMFSP2]
        FROM [mrs].[z_Item_Master_File_____ITEMMAST] [z_Item_Master_File_____ITEMMAST], [mrs].[z_Tag_Master_File_____ITEMTAG] [z_Tag_Master_File_____ITEMTAG]
        WHERE [z_Tag_Master_File_____ITEMTAG].[ITEM_NUMBER_____ITITEM] = [z_Item_Master_File_____ITEMMAST].[ITEM_NUMBER_____IMITEM] AND ([z_Tag_Master_File_____ITEMTAG].[Record_Code_____ITRECD] = 'A' AND [z_Tag_Master_File_____ITEMTAG].[ITEM_NUMBER_____ITITEM] > '49999')
        ORDER BY [z_Tag_Master_File_____ITEMTAG].[ITEM_NUMBER_____ITITEM], [z_Tag_Master_File_____ITEMTAG].[Heat_#_____ITHEAT], [z_Tag_Master_File_____ITEMTAG].[Mill_Coil#_____ITV301], [z_Tag_Master_File_____ITEMTAG].[Numeric_Length_____ITLNTH];
        */




-- ROP_query_
-- Usage Query	
-- This query retrieves historical item usage data based on transaction dates and item ranges.
-- This query has a PARAMETER in which ask the date.. for query purposes I set january 1st 2025
/*
        -- Original
        set @myvarInputSQL = '''SELECT ''Usage query'', [ITEMHIST].[IHITEM], [ITEMHIST].[IHTRNT], [ITEMHIST].[IHTRN#], [ITEMHIST].[IHVNDR], [ITEMHIST].[IHCUST], [ITEMHIST].[IHTRYY], [ITEMHIST].[IHTRMM], [ITEMHIST].[IHTRDD], [ITEMHIST].[IHTQTY]  
                FROM [ITEMHIST] [ITEMHIST]  
                WHERE ([ITEMHIST].[IHTRCC]*1000000 + [ITEMHIST].[IHTRYY]*10000 + [ITEMHIST].[IHTRMM]*100 + [ITEMHIST].[IHTRDD] > ?) AND ([ITEMHIST].[IHITEM] BETWEEN ''50000'' AND ''99998'')  
                ORDER BY [ITEMHIST].[IHITEM], [ITEMHIST].[IHTRYY], [ITEMHIST].[IHTRMM], [ITEMHIST].[IHTRDD];'''

        --Translated
        SELECT 'ROP - Usage query', T.[ITEM_NUMBER_____IHITEM], T.[Transaction_Type_____IHTRNT], T.[Transaction_#_____IHTRN#], T.[Vendor_#_____IHVNDR], T.[CUSTOMER_NUMBER_____IHCUST], T.[Trans_YY_____IHTRYY], T.[Trans_MM_____IHTRMM], T.[Trans_DD_____IHTRDD], T.[Trans_Inv_Qty_____IHTQTY]
        FROM [mrs].[z_Item_Transaction_History_____ITEMHIST] T
        WHERE (CAST(CAST(T.[Trans_CC_____IHTRCC] AS DECIMAL(5,1)) AS INT)*1000000 + CAST(CAST(T.[Trans_YY_____IHTRYY] AS DECIMAL(5,1)) AS INT)*10000 + CAST(CAST(T.[Trans_MM_____IHTRMM] AS DECIMAL(5,1)) AS INT)*100 + CAST(CAST(T.[Trans_DD_____IHTRDD] AS DECIMAL(5,1)) AS INT) > 20250101) AND (T.[ITEM_NUMBER_____IHITEM] BETWEEN '50000' AND '99998')
        ORDER BY T.[ITEM_NUMBER_____IHITEM], T.[Trans_YY_____IHTRYY], T.[Trans_MM_____IHTRMM], T.[Trans_DD_____IHTRDD]
*/


-- ROP_query
-- Usage sum query
-- This query calculates the sum of usage for items within a specific range and date.	
/*
        -- Original
            set @myvarInputSQL = '''SELECT ''ROP - Usage sum query'', DISTINCT [ITEMHIST].[IHITEM], [ITEMHIST].[IHTRNT], [ITEMHIST].[IHCUST], [ARCUST].[CALPHA], [ARCUST].[CSMDI1]*100 + [ARCUST].[CSLMN1]  
                    FROM [ARCUST] [ARCUST], [ITEMHIST] [ITEMHIST]  
                    WHERE [ARCUST].[CCUST] = [ITEMHIST].[IHCUST] AND ([ITEMHIST].[IHTRCC]*1000000 + [ITEMHIST].[IHTRYY]*10000 + [ITEMHIST].[IHTRMM]*100 + [ITEMHIST].[IHTRDD] > ? AND [ITEMHIST].[IHITEM] BETWEEN ''50000'' AND ''99998'' AND [ITEMHIST].[IHTRNT] IN (''CR'', ''IN''))  
                    ORDER BY [ITEMHIST].[IHITEM], [ARCUST].[CALPHA];'''

            --Translation
            SELECT 'ROP - Usage sum query', DISTINCT [z_Item_Transaction_History_____ITEMHIST].[ITEM_NUMBER_____IHITEM], [z_Item_Transaction_History_____ITEMHIST].[Transaction_Type_____IHTRNT], [z_Item_Transaction_History_____ITEMHIST].[CUSTOMER_NUMBER_____IHCUST], [z_Customer_Master_File_____ARCUST].[Customer_Alpha_Name_____CALPHA], [z_Customer_Master_File_____ARCUST].[Salesman_One_District_Number_____CSMDI1]*100 + [z_Customer_Master_File_____ARCUST].[Salesman_One_Number_____CSLMN1]
            FROM [mrs].[z_Customer_Master_File_____ARCUST] [z_Customer_Master_File_____ARCUST], [mrs].[z_Item_Transaction_History_____ITEMHIST] [z_Item_Transaction_History_____ITEMHIST]
            WHERE [z_Customer_Master_File_____ARCUST].[CUSTOMER_NUMBER_____CCUST] = [z_Item_Transaction_History_____ITEMHIST].[CUSTOMER_NUMBER_____IHCUST] AND ([z_Item_Transaction_History_____ITEMHIST].[Trans_CC_____IHTRCC]*1000000 + [z_Item_Transaction_History_____ITEMHIST].[Trans_YY_____IHTRYY]*10000 + [z_Item_Transaction_History_____ITEMHIST].[Trans_MM_____IHTRMM]*100 + [z_Item_Transaction_History_____ITEMHIST].[Trans_DD_____IHTRDD] > 20250101 AND [z_Item_Transaction_History_____ITEMHIST].[ITEM_NUMBER_____IHITEM] BETWEEN '50000' AND '99998' AND [z_Item_Transaction_History_____ITEMHIST].[Transaction_Type_____IHTRNT] IN ('CR', 'IN'))
            ORDER BY [z_Item_Transaction_History_____ITEMHIST].[ITEM_NUMBER_____IHITEM], [z_Customer_Master_File_____ARCUST].[Customer_Alpha_Name_____CALPHA]

            --Final working query
            SELECT DISTINCT 'ROP - Usage sum query', T.[ITEM_NUMBER_____IHITEM], T.[Transaction_Type_____IHTRNT], T.[CUSTOMER_NUMBER_____IHCUST], C.[Customer_Alpha_Name_____CALPHA], CAST(CAST(C.[Salesman_One_District_Number_____CSMDI1] AS DECIMAL(5,1)) AS INT)*100 + CAST(CAST(C.[Salesman_One_Number_____CSLMN1] AS DECIMAL(5,1)) AS INT)
            FROM [mrs].[z_Customer_Master_File_____ARCUST] C INNER JOIN [mrs].[z_Item_Transaction_History_____ITEMHIST] T ON C.[CUSTOMER_NUMBER_____CCUST] = T.[CUSTOMER_NUMBER_____IHCUST]
            WHERE (CAST(CAST(T.[Trans_CC_____IHTRCC] AS DECIMAL(5,1)) AS INT)*1000000 + CAST(CAST(T.[Trans_YY_____IHTRYY] AS DECIMAL(5,1)) AS INT)*10000 + CAST(CAST(T.[Trans_MM_____IHTRMM] AS DECIMAL(5,1)) AS INT)*100 + CAST(CAST(T.[Trans_DD_____IHTRDD] AS DECIMAL(5,1)) AS INT) > 20250101) AND (T.[ITEM_NUMBER_____IHITEM] BETWEEN '50000' AND '99998') AND (T.[Transaction_Type_____IHTRNT] IN ('CR', 'IN'))
            ORDER BY T.[ITEM_NUMBER_____IHITEM], C.[Customer_Alpha_Name_____CALPHA]
*/


--SalesAnalisysQuery_
--CreditMemos	
            -- Parameters. 
            --       OOTPE = C... credit
            --       OORECD = W     ????
            --          uses 2 dates, sums up columns to generate codes
            --          OEDistrict_ODDIST   +Transation_ORORDR  
            --          CusDistrict_ODCDIS  +Customer_ODCUST    
            --     
            /*     
            -- Original
            --set @myvarInputSQL = '''SELECT ''credit memos'', [OEDETAIL].[ODDIST]*1000000 + [OEDETAIL].[ODORDR], [SALESMAN].[SMNAME], [OEOPNORD].[OOTYPE], [OEDETAIL].[ODCDIS]*100000 + [OEDETAIL].[ODCUST], [ARCUST].[CALPHA], [OEDETAIL].[ODITEM], [OEDETAIL].[ODSIZ1], [OEDETAIL].[ODSIZ2], [OEDETAIL].[ODSIZ3], [OEDETAIL].[ODCRTD], [OEDETAIL].[ODTFTS], [OEDETAIL].[ODTLBS], [OEDETAIL].[ODTPCS], [OEDETAIL].[ODSLSX], [OEDETAIL].[ODFRTS], [OEDETAIL].[ODCSTX], [OEDETAIL].[ODPRCC], [OEDETAIL].[ODADCC], [OEDETAIL].[ODWCCS], [ARCUST].[CSTAT], [ARCUST].[CCTRY], [OEOPNORD].[OOICC]*1000000 + [OEOPNORD].[OOIYY]*10000 + [OEOPNORD].[OOIMM]*100 + [OEOPNORD].[OOIDD], [OEDETAIL].[ODCREF]  
            --        FROM [ARCUST] [ARCUST], [OEDETAIL] [OEDETAIL], [OEOPNORD] [OEOPNORD], [SALESMAN] [SALESMAN]  
            --       WHERE [OEDETAIL].[ODDIST] = [OEOPNORD].[OODIST] AND [OEDETAIL].[ODORDR] = [OEOPNORD].[OOORDR] AND [OEOPNORD].[OOCDIS] = [ARCUST].[CDIST] AND [OEOPNORD].[OOCUST] = [ARCUST].[CCUST] AND [OEOPNORD].[OOISMD] = [SALESMAN].[SMDIST] AND [OEOPNORD].[OOISMN] = [SALESMAN].[SMSMAN] AND ([OEOPNORD].[OOTYPE] = ''C'' AND [OEOPNORD].[OORECD] = ''W'' AND ([OEOPNORD].[OOICC]*10000 + [OEOPNORD].[OOIYY]*100 + [OEOPNORD].[OOIMM] BETWEEN 20250101 AND ?));'''

            -- Working
            DECLARE @StartDate INT = 20250101; DECLARE @EndDate   INT = 20250228;

            SELECT 'Sales Analisis - credit memos',
                CAST(CAST(D.[O/E_District_#_____ODDIST] AS DECIMAL(5,1)) AS INT)*1000000 + CAST(CAST(D.[Transaction_#_____ODORDR] AS DECIMAL(10,1)) AS INT) as Order__District_ODDIST_PlusTransaction_ODORDR, 
                -- Casts needed due to '1.0' error
                S.[Salesman_Name_____SMNAME],
                O.[Order_Type_____OOTYPE],
                CAST(CAST(D.[CUSTOMER_DISTRICT_____ODCDIS] AS DECIMAL(5,1)) AS INT)*100000 + CAST(CAST(D.[CUSTOMER_NUMBER_____ODCUST] AS DECIMAL(10,1)) AS INT) as CustomerDistrict_ODCDIS_PlusNumber_ODCUST, -- Casts needed due to '1.0' error
                C.[Customer_Alpha_Name_____CALPHA], D.[ITEM_NUMBER_____ODITEM], D.[SIZE_1_____ODSIZ1], D.[SIZE_2_____ODSIZ2], D.[SIZE_3_____ODSIZ3], D.[CRT_DESCRIPTION_____ODCRTD], D.[TOTAL_FTS_____ODTFTS], D.[TOTAL_LBS_____ODTLBS], D.[TOTAL_PCS_____ODTPCS], D.[NEGOTIATED_SELL_$_EXT_____ODSLSX], D.[PRORATED_FREIGHT_SALES_____ODFRTS], D.[COSTING_METHOD_COST_EXT_____ODCSTX], D.[TOTAL_PROCESS_COST_____ODPRCC], D.[TOTAL_ADDTL_CHG_COST_____ODADCC], D.[PRORATED_WHOLE_ORDER_COST_AMT_____ODWCCS], C.[State_____CSTAT], C.[Country_____CCTRY],
                CAST(CAST(O.[INVOICE_CENTURY_____OOICC] AS DECIMAL(5,1)) AS INT)*1000000 + CAST(CAST(O.[INVOICE_YEAR_____OOIYY] AS DECIMAL(5,1)) AS INT)*10000 + CAST(CAST(O.[INVOICE_MONTH_____OOIMM] AS DECIMAL(5,1)) AS INT)*100 + CAST(CAST(O.[INVOICE_DAY_____OOIDD] AS DECIMAL(5,1)) AS INT) as CustInvoiceDate_OOIC,
                D.[CUSTOMER_REFERENCE_____ODCREF]
            FROM [mrs].[z_Order_Detail_File_____OEDETAIL] AS D
            INNER JOIN [mrs].[z_Open_Order_File_____OEOPNORD] AS O ON D.[O/E_District_#_____ODDIST] = O.[O/E_Dist#_____OODIST] AND D.[Transaction_#_____ODORDR] = O.[ORDER_NUMBER_____OOORDR]
            INNER JOIN [mrs].[z_Customer_Master_File_____ARCUST] AS C ON O.[CUSTOMER_DISTRICT_____OOCDIS] = C.[CUSTOMER_DISTRICT_NUMBER_____CDIST] AND O.[CUSTOMER_NUMBER_____OOCUST] = C.[CUSTOMER_NUMBER_____CCUST]
            INNER JOIN [mrs].[z_Salesman_Master_File_____SALESMAN] AS S ON O.[INSIDE_SALESMAN_DISTRICT_____OOISMD] = S.[Salesman_District_Number_____SMDIST] AND O.[INSIDE_SALESMAN_NUMBER_____OOISMN] = S.[Salesman_Number_____SMSMAN]
            WHERE O.[Order_Type_____OOTYPE] = 'C' AND O.[Record_Code_____OORECD] = 'W' AND (CAST(CAST(O.[INVOICE_CENTURY_____OOICC] AS DECIMAL(5,1)) AS INT)*1000000 + CAST(CAST(O.[INVOICE_YEAR_____OOIYY] AS DECIMAL(5,1)) AS INT)*10000 + CAST(CAST(O.[INVOICE_MONTH_____OOIMM] AS DECIMAL(5,1)) AS INT)*100 + CAST(CAST(O.[INVOICE_DAY_____OOIDD] AS DECIMAL(5,1)) AS INT) BETWEEN @StartDate AND @EndDate);
*/














--SalesAnalisysQuery_
--Customer-Summary	
        /*
        -- Original
        set @myvarInputSQL = '''SELECT DISTINCT ''customer summary'',  [ARCUST].[CDIST]*100000 + [ARCUST].[CCUST] as CDIST_CCUST, [ARCUST].[CALPHA], [ARCUST].[CLIMIT], [ARCUST].[CISMD1]*100 + [ARCUST].[CISLM1], [ARCUST].[CSMDI1]*100 + [ARCUST].[CSLMN1], [SALESMAN].[SMNAME]  
            FROM [ARCUST] [ARCUST], [SALESMAN] [SALESMAN]  
            WHERE [ARCUST].[CISMD1] = [SALESMAN].[SMDIST] AND [ARCUST].[CISLM1] = [SALESMAN].[SMSMAN]  
            ORDER BY [ARCUST].[CALPHA];'''


        -- Working query
        SELECT DISTINCT  'Sales Analysis - customer summary', CAST([z_Customer_Master_File_____ARCUST].[CUSTOMER_DISTRICT_NUMBER_____CDIST] AS INT) * 100000 + CAST([z_Customer_Master_File_____ARCUST].[CUSTOMER_NUMBER_____CCUST] AS INT) as CDIST_CCUST, [z_Customer_Master_File_____ARCUST].[Customer_Alpha_Name_____CALPHA], [z_Customer_Master_File_____ARCUST].[Credit_Limit_____CLIMIT], CAST([z_Customer_Master_File_____ARCUST].[Inside_Salesman_District_Number_____CISMD1] AS INT) * 100 + CAST([z_Customer_Master_File_____ARCUST].[Inside_Salesman_Number_____CISLM1] AS INT) AS Customer_InsideSalesMan_CISMD1_CISLM1, CAST([z_Customer_Master_File_____ARCUST].[Salesman_One_District_Number_____CSMDI1] AS INT) * 100 + CAST([z_Customer_Master_File_____ARCUST].[Salesman_One_Number_____CSLMN1] AS INT) as Customer_Salesman_CSMDI1_CSLMN1, [z_Salesman_Master_File_____SALESMAN].[Salesman_Name_____SMNAME]
        FROM [mrs].[z_Customer_Master_File_____ARCUST] [z_Customer_Master_File_____ARCUST], [mrs].[z_Salesman_Master_File_____SALESMAN] [z_Salesman_Master_File_____SALESMAN]
        WHERE [z_Customer_Master_File_____ARCUST].[Inside_Salesman_District_Number_____CISMD1] = [z_Salesman_Master_File_____SALESMAN].[Salesman_District_Number_____SMDIST] AND [z_Customer_Master_File_____ARCUST].[Inside_Salesman_Number_____CISLM1] = [z_Salesman_Master_File_____SALESMAN].[Salesman_Number_____SMSMAN]
        ORDER BY [z_Customer_Master_File_____ARCUST].[Customer_Alpha_Name_____CALPHA]



        */


--SalesAnalisysQuery_
--Customer-Summary1	
        /*
            --Original
            set @myvarInputSQL = '''SELECT DISTINCT ''Sales analysis Customer summary'', [SALESMAN].[SMDIST]*100 + [SALESMAN].[SMSMAN], [SALESMAN].[SMNAME]
                    FROM [SALESMAN] [SALESMAN];'''

            --working
            SELECT DISTINCT
            'Sales analysis Salesman summary',    CAST(CAST([z_Salesman_Master_File_____SALESMAN].[Salesman_District_Number_____SMDIST] AS DECIMAL(18, 2)) AS INT) * 100    + CAST(CAST([z_Salesman_Master_File_____SALESMAN].[Salesman_Number_____SMSMAN] AS DECIMAL(18, 2)) AS INT) AS Salesman_Combined_ID_SALESMAN_SMSMAN,    [z_Salesman_Master_File_____SALESMAN].[Salesman_Name_____SMNAME]
            FROM    [mrs].[z_Salesman_Master_File_____SALESMAN] [z_Salesman_Master_File_____SALESMAN]
        */


--SalesAnalisysQuery_
--QueryFromMetalNet1	
            
                -- Original
                -- its all the ITEMONHD
 /*           set @myvarInputSQL = '''SELECT ''Sales analysis, query'', [ITEMONHD].[IORECD], [ITEMONHD].[IOCOMP], [ITEMONHD].[IODIST], [ITEMONHD].[IOITEM],
                [ITEMONHD].[IOQOH], [ITEMONHD].[IOQOR], [ITEMONHD].[IOQOO], [ITEMONHD].[IOQOOR], [ITEMONHD].[IOQIT], [ITEMONHD].[IOQHLD], [ITEMONHD].[IOQCOL], 
                [ITEMONHD].[IOROH], [ITEMONHD].[IOROR], [ITEMONHD].[IOROO], [ITEMONHD].[IOROOR], [ITEMONHD].[IORIT], [ITEMONHD].[IORIQC], [ITEMONHD].[IOBOMI], 
                [ITEMONHD].[IOBOMC], [ITEMONHD].[IOLCCC], [ITEMONHD].[IOLCYY], [ITEMONHD].[IOLCMM], [ITEMONHD].[IOLCDD], [ITEMONHD].[IOCUOM], [ITEMONHD].[IOACST], 
                [ITEMONHD].[IORCST], [ITEMONHD].[IORLCK], [ITEMONHD].[IOFCST], [ITEMONHD].[IOSCST], [ITEMONHD].[IOSCCC], [ITEMONHD].[IOSCYY], [ITEMONHD].[IOSCMM], 
                [ITEMONHD].[IOSCDD], [ITEMONHD].[IODOSC], [ITEMONHD].[IODOSL], [ITEMONHD].[IOMNRQ], [ITEMONHD].[IOTORQ], [ITEMONHD].[IOPYIB], [ITEMONHD].[IOCYIB], 
                [ITEMONHD].[IOCYIU], [ITEMONHD].[IOITST], [ITEMONHD].[IOPLVL], [ITEMONHD].[IOBGIN], [ITEMONHD].[IOMNBL], [ITEMONHD].[IOROPT], [ITEMONHD].[IOROPL], 
                [ITEMONHD].[IOROQT], [ITEMONHD].[IOLDTM], [ITEMONHD].[IOBUY], [ITEMONHD].[IOBGIT], [ITEMONHD].[IOROFC], [ITEMONHD].[IOSSTK], [ITEMONHD].[IOLDTL], 
                [ITEMONHD].[IOINVC], [ITEMONHD].[IOMTST], [ITEMONHD].[IODISC], [ITEMONHD].[IOOWNF], [ITEMONHD].[IONSDC], [ITEMONHD].[IO1RCT], [ITEMONHD].[IOTOPP], 
                [ITEMONHD].[IOPMON], [ITEMONHD].[IOLOCC], [ITEMONHD].[IOLOYY], [ITEMONHD].[IOLOMM], [ITEMONHD].[IOLODD], [ITEMONHD].[IO1ACQ], [ITEMONHD].[IOLFB1], 
                [ITEMONHD].[IOLFB2], [ITEMONHD].[IOCMNT], [ITEMONHD].[IOMSLS], [ITEMONHD].[IOYSLS], [ITEMONHD].[IOMCST], [ITEMONHD].[IOYCST], [ITEMONHD].[IOMUNT], 
                [ITEMONHD].[IOYUNT], [ITEMONHD].[IOMWGT], [ITEMONHD].[IOYWGT], [ITEMONHD].[IODLCC], [ITEMONHD].[IODLYY], [ITEMONHD].[IODLMM], [ITEMONHD].[IODLDD], 
                [ITEMONHD].[IOPUOM], [ITEMONHD].[IOCNTP], [ITEMONHD].[IOCNTL], [ITEMONHD].[IOBPRC], [ITEMONHD].[IOBPRL], [ITEMONHD].[IOBPCC], [ITEMONHD].[IOBPYY], 
                [ITEMONHD].[IOBPMM], [ITEMONHD].[IOBPDD], [ITEMONHD].[IOCNTC], [ITEMONHD].[IOCDIS], [ITEMONHD].[IOCUST], [ITEMONHD].[IOMACN], [ITEMONHD].[IOPRCD], 
                [ITEMONHD].[IORUNR], [ITEMONHD].[IORUOM], [ITEMONHD].[IOMEIF], [ITEMONHD].[IOORDI], [ITEMONHD].[IOMDIF], [ITEMONHD].[IOPMCC], [ITEMONHD].[IOPMYY], 
                [ITEMONHD].[IOPMMM], [ITEMONHD].[IOPMDD], [ITEMONHD].[IOPMCD], [ITEMONHD].[IOLRCS], [ITEMONHD].[IOZ], [ITEMONHD].[IOC], [ITEMONHD].[IOD], [ITEMONHD].
                [IOPCTF], [ITEMONHD].[IOOUOM], [ITEMONHD].[IOMAGA], [ITEMONHD].[IOHURD], [ITEMONHD].[IOATAJ], [ITEMONHD].[IOLPCC], [ITEMONHD].[IOLPYY], [ITEMONHD].[IOLPMM], 
                [ITEMONHD].[IOLPDD], [ITEMONHD].[IOLPUS], [ITEMONHD].[IOLSCC], [ITEMONHD].[IOLSYY], [ITEMONHD].[IOLSMM], [ITEMONHD].[IOLSDD], [ITEMONHD].[IOLSUS], 
                [ITEMONHD].[IOLMCC], [ITEMONHD].[IOLMYY], [ITEMONHD].[IOLMMM], [ITEMONHD].[IOLMDD], [ITEMONHD].[IOLMUS], [ITEMONHD].[IOCLS3], [ITEMONHD].[IOSBCL], 
                [ITEMONHD].[IOSTCL], [ITEMONHD].[IOPUSD], [ITEMONHD].[IOPUSQ], [ITEMONHD].[IOPCST], [ITEMONHD].[IOPSLS], [ITEMONHD].[IOPUNT], [ITEMONHD].[IOPLBS], 
                [ITEMONHD].[IOPATN], [ITEMONHD].[IOMOST], [ITEMONHD].[IOBOMW], [ITEMONHD].[IOAVMS], [ITEMONHD].[IOAVLB], [ITEMONHD].[IOAVOH], [ITEMONHD].[IOAVOS], 
                [ITEMONHD].[IOUSQT], [ITEMONHD].[IOUSDL], [ITEMONHD].[IOYTDL], [ITEMONHD].[IOLIFO], [ITEMONHD].[IOSRCE], [ITEMONHD].[IOSUCC], [ITEMONHD].[IOSUYY], 
                [ITEMONHD].[IOSUMM], [ITEMONHD].[IOSUDD], [ITEMONHD].[IOOPPO], [ITEMONHD].[IOOPPD], [ITEMONHD].[IOTSTR], [ITEMONHD].[IOAVMQ], [ITEMONHD].[IOITDL], 
                [ITEMONHD].[IOITUN], [ITEMONHD].[IORSTK], [ITEMONHD].[IORSMP], [ITEMONHD].[IOHFRR], [ITEMONHD].[IOCORS], [ITEMONHD].[IOTRRS], [ITEMONHD].[IOMPRS], 
                [ITEMONHD].[IOSTOR], [ITEMONHD].[IOASOR], [ITEMONHD].[IOAVG3], [ITEMONHD].[IOAV12], [ITEMONHD].[IOPICC], [ITEMONHD].[IOPIYY], [ITEMONHD].[IOPIMM], 
                [ITEMONHD].[IOPIDD], [ITEMONHD].[IOPDSC], [ITEMONHD].[IOITRM], [ITEMONHD].[IOLPMC], [ITEMONHD].[IOLPML], [ITEMONHD].[IOCPMC], [ITEMONHD].[IOCPML], 
                [ITEMONHD].[IODSPS], [ITEMONHD].[IOSPCD], [ITEMONHD].[IOPRC2], [ITEMONHD].[IOSALE], [ITEMONHD].[IOQQTY], [ITEMONHD].[IOQAC], [ITEMONHD].[IOOELK], 
                [ITEMONHD].[IOMPLK], [ITEMONHD].[IOABCP], [ITEMONHD].[IOANRS], [ITEMONHD].[IOTAX], [ITEMONHD].[IORBCS], [ITEMONHD].[IOTUNA]  
                    FROM [ITEMONHD] [ITEMONHD];'''

/*            
            -- WORKING
            SELECT * FROM ITEMONHD

*/


--SalesAnalisysQuery
--SalesOrders	xxxx
/*
                
                -- Original

                --SELECT CAST([OEDETAIL].[oddist] AS INT) * 1000000 + CAST([OEDETAIL].[odordr] AS INT), [SALESMAN].[SMNAME], [OEOPNORD].[OOTYPE], CAST([OEDETAIL].[odcdis] AS INT) * 100000 + CAST([OEDETAIL].[odcust] AS INT), [ARCUST].[CALPHA], CAST([OEOPNORD].[OOICC] AS INT) * 1000000 + CAST([OEOPNORD].[OOIYY] AS INT) * 10000 + CAST([OEOPNORD].[OOIMM] AS INT) * 100 + CAST([OEOPNORD].[OOIDD] AS INT), [OEDETAIL].[ODITEM], [OEDETAIL].[ODSIZ1], [OEDETAIL].[ODSIZ2], [OEDETAIL].[ODSIZ3], [OEDETAIL].[ODCRTD], [SLSDSCOV].[DXDSC2], [OEDETAIL].[ODTFTS], [OEDETAIL].[ODTLBS], [OEDETAIL].[ODTPCS], [OEDETAIL].[ODSLSX], [OEDETAIL].[ODFRTS], [OEDETAIL].[ODCSTX], [OEDETAIL].[ODPRCC], [OEDETAIL].[ODADCC], [OEDETAIL].[ODWCCS], [ARCUST].[CSTAT], [ARCUST].[CCTRY]
                --FROM [mrs].[ARCUST] AS [ARCUST], [mrs].[OEDETAIL] AS [OEDETAIL], [mrs].[OEOPNORD] AS [OEOPNORD], [mrs].[SALESMAN] AS [SALESMAN], [mrs].[SLSDSCOV] AS [SLSDSCOV]
                --WHERE CAST([OEDETAIL].[ODDIST] AS INT) = CAST([OEOPNORD].[OODIST] AS INT) AND CAST([OEDETAIL].[ODDIST] AS INT) = CAST([SLSDSCOV].[DXDIST] AS INT) AND CAST([OEDETAIL].[ODMLIN] AS INT) = CAST([SLSDSCOV].[DXMLIN] AS INT) AND CAST([OEDETAIL].[ODORDR] AS INT) = CAST([OEOPNORD].[OOORDR] AS INT) AND CAST([OEDETAIL].[ODORDR] AS INT) = CAST([SLSDSCOV].[DXORDR] AS INT) AND CAST([OEOPNORD].[OOCDIS] AS INT) = CAST([ARCUST].[CDIST] AS INT) AND CAST([OEOPNORD].[OOCUST] AS INT) = CAST([ARCUST].[CCUST] AS INT) AND CAST([OEOPNORD].[OOISMD] AS INT) = CAST([SALESMAN].[SMDIST] AS INT) AND CAST([OEOPNORD].[OOISMN] AS INT) = CAST([SALESMAN].[SMSMAN] AS INT) AND (([OEOPNORD].[OOTYPE] IN ('A','B')) AND ([OEOPNORD].[OORECD]='W') AND (CAST([OEOPNORD].[ooicc] AS INT)*10000+CAST([OEOPNORD].[ooiyy] AS INT)*100+CAST([OEOPNORD].[ooimm] AS INT) BETWEEN @StartDate AND @EndDate))

                --Ready
                --DECLARE @StartDate INT = 202501; DECLARE @EndDate INT = 202502;
                --SELECT CAST(CAST([z_Order_Detail_File_____OEDETAIL].[O/E_District_#_____ODDIST] AS DECIMAL(18, 2)) AS INT) * 1000000 + CAST(CAST([z_Order_Detail_File_____OEDETAIL].[Transaction_#_____ODORDR] AS DECIMAL(18, 2)) AS INT) Order_districtPlusTransaction, [z_Salesman_Master_File_____SALESMAN].[Salesman_Name_____SMNAME], [z_Open_Order_File_____OEOPNORD].[Order_Type_____OOTYPE], CAST(CAST([z_Order_Detail_File_____OEDETAIL].[CUSTOMER_DISTRICT_____ODCDIS] AS DECIMAL(18, 2)) AS INT) * 100000 + CAST(CAST([z_Order_Detail_File_____OEDETAIL].[CUSTOMER_NUMBER_____ODCUST] AS DECIMAL(18, 2)) AS INT) Customer_DistrictPlusCustomer, [z_Customer_Master_File_____ARCUST].[Customer_Alpha_Name_____CALPHA], CAST(CAST([z_Open_Order_File_____OEOPNORD].[INVOICE_CENTURY_____OOICC] AS DECIMAL(18, 2)) AS INT) * 1000000 + CAST(CAST([z_Open_Order_File_____OEOPNORD].[INVOICE_YEAR_____OOIYY] AS DECIMAL(18, 2)) AS INT) * 10000 + CAST(CAST([z_Open_Order_File_____OEOPNORD].[INVOICE_MONTH_____OOIMM] AS DECIMAL(18, 2)) AS INT) * 100 + CAST(CAST([z_Open_Order_File_____OEOPNORD].[INVOICE_DAY_____OOIDD] AS DECIMAL(18, 2)) AS INT) as InvoiceDate_OOI, [z_Order_Detail_File_____OEDETAIL].[ITEM_NUMBER_____ODITEM], [z_Order_Detail_File_____OEDETAIL].[SIZE_1_____ODSIZ1], [z_Order_Detail_File_____OEDETAIL].[SIZE_2_____ODSIZ2], [z_Order_Detail_File_____OEDETAIL].[SIZE_3_____ODSIZ3], [z_Order_Detail_File_____OEDETAIL].[CRT_DESCRIPTION_____ODCRTD], [z_Sales_Description_Override_____SLSDSCOV].[Item_Print_Descr_Two_____DXDSC2], [z_Order_Detail_File_____OEDETAIL].[TOTAL_FTS_____ODTFTS], [z_Order_Detail_File_____OEDETAIL].[TOTAL_LBS_____ODTLBS], [z_Order_Detail_File_____OEDETAIL].[TOTAL_PCS_____ODTPCS], [z_Order_Detail_File_____OEDETAIL].[NEGOTIATED_SELL_$_EXT_____ODSLSX], [z_Order_Detail_File_____OEDETAIL].[PRORATED_FREIGHT_SALES_____ODFRTS], [z_Order_Detail_File_____OEDETAIL].[COSTING_METHOD_COST_EXT_____ODCSTX], [z_Order_Detail_File_____OEDETAIL].[TOTAL_PROCESS_COST_____ODPRCC], [z_Order_Detail_File_____OEDETAIL].[TOTAL_ADDTL_CHG_COST_____ODADCC], [z_Order_Detail_File_____OEDETAIL].[PRORATED_WHOLE_ORDER_COST_AMT_____ODWCCS], [z_Customer_Master_File_____ARCUST].[State_____CSTAT], [z_Customer_Master_File_____ARCUST].[Country_____CCTRY] FROM [mrs].[z_Customer_Master_File_____ARCUST] AS [z_Customer_Master_File_____ARCUST], [mrs].[z_Order_Detail_File_____OEDETAIL] AS [z_Order_Detail_File_____OEDETAIL], [mrs].[z_Open_Order_File_____OEOPNORD] AS [z_Open_Order_File_____OEOPNORD], [mrs].[z_Salesman_Master_File_____SALESMAN] AS [z_Salesman_Master_File_____SALESMAN], [mrs].[z_Sales_Description_Override_____SLSDSCOV] AS [z_Sales_Description_Override_____SLSDSCOV] WHERE CAST(CAST([z_Order_Detail_File_____OEDETAIL].[O/E_District_#_____ODDIST] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Open_Order_File_____OEOPNORD].[O/E_Dist#_____OODIST] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Order_Detail_File_____OEDETAIL].[O/E_District_#_____ODDIST] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Sales_Description_Override_____SLSDSCOV].[Tran._District_#_____DXDIST] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Order_Detail_File_____OEDETAIL].[MAIN_LINE_____ODMLIN] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Sales_Description_Override_____SLSDSCOV].[MAIN_LINE_____DXMLIN] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Order_Detail_File_____OEDETAIL].[Transaction_#_____ODORDR] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Open_Order_File_____OEOPNORD].[ORDER_NUMBER_____OOORDR] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Order_Detail_File_____OEDETAIL].[Transaction_#_____ODORDR] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Sales_Description_Override_____SLSDSCOV].[Transaction_#_____DXORDR] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Open_Order_File_____OEOPNORD].[CUSTOMER_DISTRICT_____OOCDIS] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Customer_Master_File_____ARCUST].[CUSTOMER_DISTRICT_NUMBER_____CDIST] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Open_Order_File_____OEOPNORD].[CUSTOMER_NUMBER_____OOCUST] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Customer_Master_File_____ARCUST].[CUSTOMER_NUMBER_____CCUST] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Open_Order_File_____OEOPNORD].[INSIDE_SALESMAN_DISTRICT_____OOISMD] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Salesman_Master_File_____SALESMAN].[Salesman_District_Number_____SMDIST] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Open_Order_File_____OEOPNORD].[INSIDE_SALESMAN_NUMBER_____OOISMN] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Salesman_Master_File_____SALESMAN].[Salesman_Number_____SMSMAN] AS DECIMAL(18, 2)) AS INT) AND (([z_Open_Order_File_____OEOPNORD].[Order_Type_____OOTYPE] IN ('A','B')) AND ([z_Open_Order_File_____OEOPNORD].[Record_Code_____OORECD]='W') AND (CAST(CAST([z_Open_Order_File_____OEOPNORD].[INVOICE_CENTURY_____OOICC] AS DECIMAL(18, 2)) AS INT)*10000+CAST(CAST([z_Open_Order_File_____OEOPNORD].[INVOICE_YEAR_____OOIYY] AS DECIMAL(18, 2)) AS INT)*100+CAST(CAST([z_Open_Order_File_____OEOPNORD].[INVOICE_MONTH_____OOIMM] AS DECIMAL(18, 2)) AS INT) BETWEEN @StartDate AND @EndDate));

*/





--SalesAnalisysQuery_
--SPO
        /*
        --Original
                --set @myvarInputSQL = '''SELECT ''Sales analysis, SPO'', [OEDETAIL].[ODDIST]*1000000 + [OEDETAIL].[ODORDR], [SALESMAN].[SMNAME], [OEOPNORD].[OOTYPE], [OEDETAIL].[ODCDIS]*100000 + [OEDETAIL].[ODCUST], [ARCUST].[CALPHA], [OEOPNORD].[OOICC]*100 + [OEOPNORD].[OOIYY], [OEOPNORD].[OOIMM], [OEOPNORD].[OOIDD], [OEDETAIL].[ODITEM], [SPHEADER].[BSSVEN], [SPHEADER].[BSSPS#]
                --FROM [ARCUST] [ARCUST], [OEDETAIL] [OEDETAIL], [OEOPNORD] [OEOPNORD], [SALESMAN] [SALESMAN], [SPHEADER] [SPHEADER]
                --WHERE [OEDETAIL].[ODDIST] = [OEOPNORD].[OODIST] AND [OEDETAIL].[ODORDR] = [OEOPNORD].[OOORDR] AND [OEOPNORD].[OOCDIS] = [ARCUST].[CDIST] AND [OEOPNORD].[OOCUST] = [ARCUST].[CCUST] AND [OEOPNORD].[OOISMD] = [SALESMAN].[SMDIST] AND [OEOPNORD].[OOISMN] = [SALESMAN].[SMSMAN] AND [OEDETAIL].[ODDIST] = [SPHEADER].[BSDIST] AND [OEDETAIL].[ODORDR] = [SPHEADER].[BSORDR] AND ([OEOPNORD].[OOTYPE] IN ('A','B') AND [OEOPNORD].[OORECD] = 'W' AND [OEDETAIL].[ODDIST] = 1 AND [OEDETAIL].[ODORDR] > ?);'''

                --SET @myvarInputSQL = 'SELECT ''Sales analysis, SPO'', [OEDETAIL].[ODDIST]*1000000 + [OEDETAIL].[ODORDR], [SALESMAN].[SMNAME], [OEOPNORD].[OOTYPE], [OEDETAIL].[ODCDIS]*100000 + [OEDETAIL].[ODCUST], [ARCUST].[CALPHA], [OEOPNORD].[OOICC]*100 + [OEOPNORD].[OOIYY], [OEOPNORD].[OOIMM], [OEOPNORD].[OOIDD], [OEDETAIL].[ODITEM], [SPHEADER].[BSSVEN], [SPHEADER].[BSSPS#] FROM [ARCUST] AS [ARCUST], [OEDETAIL] AS [OEDETAIL], [OEOPNORD] AS [OEOPNORD], [SALESMAN] AS [SALESMAN], [SPHEADER] AS [SPHEADER] WHERE [OEDETAIL].[ODDIST] = [OEOPNORD].[OODIST] AND [OEDETAIL].[ODORDR] = [OEOPNORD].[OOORDR] AND [OEOPNORD].[OOCDIS] = [ARCUST].[CDIST] AND [OEOPNORD].[OOCUST] = [ARCUST].[CCUST] AND [OEOPNORD].[OOISMD] = [SALESMAN].[SMDIST] AND [OEOPNORD].[OOISMN] = [SALESMAN].[SMSMAN] AND [OEDETAIL].[ODDIST] = [SPHEADER].[BSDIST] AND [OEDETAIL].[ODORDR] = [SPHEADER].[BSORDR] AND ([OEOPNORD].[OOTYPE] IN (''A'',''B'') AND [OEOPNORD].[OORECD] = ''W'' AND [OEDETAIL].[ODDIST] = 1 AND [OEDETAIL].[ODORDR] > ?);';

        --Working Query
                DECLARE @TransactionNumber INT = 951239; -- I dont know the transaction numbers
                SELECT 'Sales analysis, SPO' as QueryName, CAST(CAST([z_Order_Detail_File_____OEDETAIL].[O/E_District_#_____ODDIST] AS DECIMAL(18, 2)) AS INT) * 1000000 + CAST(CAST([z_Order_Detail_File_____OEDETAIL].[Transaction_#_____ODORDR] AS DECIMAL(18, 2)) AS INT) as Order_districtPlusTransaction, [z_Salesman_Master_File_____SALESMAN].[Salesman_Name_____SMNAME], [z_Open_Order_File_____OEOPNORD].[Order_Type_____OOTYPE], CAST(CAST([z_Order_Detail_File_____OEDETAIL].[CUSTOMER_DISTRICT_____ODCDIS] AS DECIMAL(18, 2)) AS INT) * 100000 + CAST(CAST([z_Order_Detail_File_____OEDETAIL].[CUSTOMER_NUMBER_____ODCUST] AS DECIMAL(18, 2)) AS INT) as Customer_DistrictPlusCustomer, [z_Customer_Master_File_____ARCUST].[Customer_Alpha_Name_____CALPHA], CAST(CAST([z_Open_Order_File_____OEOPNORD].[INVOICE_CENTURY_____OOICC] AS DECIMAL(18, 2)) AS INT) * 1000000 + CAST(CAST([z_Open_Order_File_____OEOPNORD].[INVOICE_YEAR_____OOIYY] AS DECIMAL(18, 2)) AS INT) * 10000 + CAST(CAST([z_Open_Order_File_____OEOPNORD].[INVOICE_MONTH_____OOIMM] AS DECIMAL(18, 2)) AS INT) * 100 + CAST(CAST([z_Open_Order_File_____OEOPNORD].[INVOICE_DAY_____OOIDD] AS DECIMAL(18, 2)) AS INT) as InvoiceDate_OOI, [z_Order_Detail_File_____OEDETAIL].[ITEM_NUMBER_____ODITEM], [z_Service_Purchase_Order_Header_File_____SPHEADER].[Ship_To_Vendor_#_____BSSVEN], [z_Service_Purchase_Order_Header_File_____SPHEADER].[Multiple_SPO_____BSSPS#] FROM [mrs].[z_Customer_Master_File_____ARCUST] AS [z_Customer_Master_File_____ARCUST], [mrs].[z_Order_Detail_File_____OEDETAIL] AS [z_Order_Detail_File_____OEDETAIL], [mrs].[z_Open_Order_File_____OEOPNORD] AS [z_Open_Order_File_____OEOPNORD], [mrs].[z_Salesman_Master_File_____SALESMAN] AS [z_Salesman_Master_File_____SALESMAN], [mrs].[z_Service_Purchase_Order_Header_File_____SPHEADER] AS [z_Service_Purchase_Order_Header_File_____SPHEADER] WHERE CAST(CAST([z_Order_Detail_File_____OEDETAIL].[O/E_District_#_____ODDIST] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Open_Order_File_____OEOPNORD].[O/E_Dist#_____OODIST] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Order_Detail_File_____OEDETAIL].[Transaction_#_____ODORDR] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Open_Order_File_____OEOPNORD].[ORDER_NUMBER_____OOORDR] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Open_Order_File_____OEOPNORD].[CUSTOMER_DISTRICT_____OOCDIS] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Customer_Master_File_____ARCUST].[CUSTOMER_DISTRICT_NUMBER_____CDIST] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Open_Order_File_____OEOPNORD].[CUSTOMER_NUMBER_____OOCUST] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Customer_Master_File_____ARCUST].[CUSTOMER_NUMBER_____CCUST] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Open_Order_File_____OEOPNORD].[INSIDE_SALESMAN_DISTRICT_____OOISMD] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Salesman_Master_File_____SALESMAN].[Salesman_District_Number_____SMDIST] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Open_Order_File_____OEOPNORD].[INSIDE_SALESMAN_NUMBER_____OOISMN] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Salesman_Master_File_____SALESMAN].[Salesman_Number_____SMSMAN] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Order_Detail_File_____OEDETAIL].[O/E_District_#_____ODDIST] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Service_Purchase_Order_Header_File_____SPHEADER].[DISTRICT_NUMBER_____BSDIST] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Order_Detail_File_____OEDETAIL].[Transaction_#_____ODORDR] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Service_Purchase_Order_Header_File_____SPHEADER].[Transaction_#_____BSORDR] AS DECIMAL(18, 2)) AS INT) AND (([z_Open_Order_File_____OEOPNORD].[Order_Type_____OOTYPE] IN ('A','B')) AND ([z_Open_Order_File_____OEOPNORD].[Record_Code_____OORECD] = 'W') AND CAST(CAST([z_Order_Detail_File_____OEDETAIL].[O/E_District_#_____ODDIST] AS DECIMAL(18, 2)) AS INT) = 1 AND CAST(CAST([z_Order_Detail_File_____OEDETAIL].[Transaction_#_____ODORDR] AS DECIMAL(18, 2)) AS INT) > @TransactionNumber );
        */


;

--Shipmast_
--QueryfromMetalNet	
--set @myvarInputSQL = ''' SELECT ''Shipmaster'', [SHIPMAST].[SHRECD], [SHIPMAST].[SHCOMP], [SHIPMAST].[SHDIST], [SHIPMAST].[SHORDN], [SHIPMAST].[SHCORD], [SHIPMAST].[SHOREL], [SHIPMAST].[SHITEM], [SHIPMAST].[SHMDIF], [SHIPMAST].[SHTOPP], [SHIPMAST].[SHTYPE], [SHIPMAST].[SHPFLG], [SHIPMAST].[SHCOFL], [SHIPMAST].[SHSCRP], [SHIPMAST].[SHCUTC], [SHIPMAST].[SHIPCC], [SHIPMAST].[SHIPYY], [SHIPMAST].[SHIPMM], [SHIPMAST].[SHIPDD], [SHIPMAST].[SHRFLG], [SHIPMAST].[SHSHAP], [SHIPMAST].[SHCLS3], [SHIPMAST].[SHLDIS], [SHIPMAST].[SHINSM], [SHIPMAST].[SHSQTY], [SHIPMAST].[SHUOM], [SHIPMAST].[SHBQTY], [SHIPMAST].[SHBUOM], [SHIPMAST].[SHBINC], [SHIPMAST].[SHOQTY], [SHIPMAST].[SHOUOM], [SHIPMAST].[SHOINC], [SHIPMAST].[SHTLBS], [SHIPMAST].[SHTPCS], [SHIPMAST].[SHTFTS], [SHIPMAST].[SHTSFT], [SHIPMAST].[SHTMTR], [SHIPMAST].[SHTKG], [SHIPMAST].[SHPRCG], [SHIPMAST].[SHHAND], [SHIPMAST].[SHCDIS], [SHIPMAST].[SHCUST], [SHIPMAST].[SHTERR], [SHIPMAST].[SHOUTS], [SHIPMAST].[SHLINE], [SHIPMAST].[SHORCC], [SHIPMAST].[SHORYY], [SHIPMAST].[SHORMM], [SHIPMAST].[SHORDD], [SHIPMAST].[SHPRCC], [SHIPMAST].[SHPRYY], [SHIPMAST].[SHPRMM], [SHIPMAST].[SHPRDD], [SHIPMAST].[SHIVCC], [SHIPMAST].[SHIVYY], [SHIPMAST].[SHIVMM], [SHIPMAST].[SHIVDD], [SHIPMAST].[SHMSLS], [SHIPMAST].[SHMSLD], [SHIPMAST].[SHFSLS], [SHIPMAST].[SHFSLD], [SHIPMAST].[SHPSLS], [SHIPMAST].[SHPSLD], [SHIPMAST].[SHOSLS], [SHIPMAST].[SHOSLD], [SHIPMAST].[SHDSLS], [SHIPMAST].[SHDSLD], [SHIPMAST].[SHMCSS], [SHIPMAST].[SHMCSD], [SHIPMAST].[SHFISS], [SHIPMAST].[SHFISD], [SHIPMAST].[SHFOSS], [SHIPMAST].[SHFOSD], [SHIPMAST].[SHFSFS], [SHIPMAST].[SHFSFD], [SHIPMAST].[SHPCSS], [SHIPMAST].[SHPCSD], [SHIPMAST].[SHOCSS], [SHIPMAST].[SHOCSD], [SHIPMAST].[SHADBS], [SHIPMAST].[SHADBD], [SHIPMAST].[SHOPBS], [SHIPMAST].[SHOPBD], [SHIPMAST].[SHIAJS], [SHIPMAST].[SHIAJD], [SHIPMAST].[SHSLSS], [SHIPMAST].[SHSLSD], [SHIPMAST].[SHSWGS], [SHIPMAST].[SHSWGD], [SHIPMAST].[SHADPC], [SHIPMAST].[SHUNSP], [SHIPMAST].[SHUUOM], [SHIPMAST].[SHSAFL], [SHIPMAST].[SHSACC], [SHIPMAST].[SHSAYY], [SHIPMAST].[SHSAMM], [SHIPMAST].[SHSADD], [SHIPMAST].[SHFRGH], [SHIPMAST].[SHSCDL], [SHIPMAST].[SHSCLB], [SHIPMAST].[SHSCKG], [SHIPMAST].[SHDBDC], [SHIPMAST].[SHTRCK], [SHIPMAST].[SHODES], [SHIPMAST].[SHSHOP], [SHIPMAST].[SHSHTO], [SHIPMAST].[SHBCTY], [SHIPMAST].[SHSCTY], [SHIPMAST].[SHTMPS], [SHIPMAST].[SHSTER], [SHIPMAST].[SHTRAD], [SHIPMAST].[SHBPCC], [SHIPMAST].[SHEEC], [SHIPMAST].[SHSEC], [SHIPMAST].[SHITYP], [SHIPMAST].[SHDPTI], [SHIPMAST].[SHDPTO], [SHIPMAST].[SHDSTO], [SHIPMAST].[SHCSTO], [SHIPMAST].[SHSMDO], [SHIPMAST].[SHSLMO], [SHIPMAST].[SHICMP], [SHIPMAST].[SHADR1], [SHIPMAST].[SHADR2], [SHIPMAST].[SHADR3], [SHIPMAST].[SHCITY], [SHIPMAST].[SHSTAT], [SHIPMAST].[SHZIP], [SHIPMAST].[SHJOB]
--FROM  [SHIPMAST] [SHIPMAST]
--WHERE [SHIPMAST].[SHORDN] > 950000;'''



/*

QUERIES FROM EXCEL
                --Credit memos
                SELECT oddist*1000000+odordr, SALESMAN.SMNAME, OEOPNORD.OOTYPE, odcdis*100000+odcust, ARCUST.CALPHA, OEDETAIL.ODITEM, OEDETAIL.ODSIZ1, OEDETAIL.ODSIZ2, OEDETAIL.ODSIZ3, OEDETAIL.ODCRTD, OEDETAIL.ODTFTS, OEDETAIL.ODTLBS, OEDETAIL.ODTPCS, OEDETAIL.ODSLSX, OEDETAIL.ODFRTS, OEDETAIL.ODCSTX, OEDETAIL.ODPRCC, OEDETAIL.ODADCC, OEDETAIL.ODWCCS, ARCUST.CSTAT, ARCUST.CCTRY, OOICC*1000000+OOIYY*10000+OOIMM*100+OOIDD, OEDETAIL.ODCREF
                FROM S219EAAV.MW4FILE.ARCUST ARCUST, S219EAAV.MW4FILE.OEDETAIL OEDETAIL, S219EAAV.MW4FILE.OEOPNORD OEOPNORD, S219EAAV.MW4FILE.SALESMAN SALESMAN
                WHERE OEDETAIL.ODDIST = OEOPNORD.OODIST AND OEDETAIL.ODORDR = OEOPNORD.OOORDR AND OEOPNORD.OOCDIS = ARCUST.CDIST AND OEOPNORD.OOCUST = ARCUST.CCUST AND OEOPNORD.OOISMD = SALESMAN.SMDIST AND OEOPNORD.OOISMN = SALESMAN.SMSMAN AND ((OEOPNORD.OOTYPE='C') AND (OEOPNORD.OORECD='W') AND (ooicc*10000+ooiyy*100+ooimm Between ? And ?))

                Union open orders, order detail, customer, salesman. 
                OEDETAIL, OEOPNORD, (DISTRICT, ORDER) customer district, customer number, internal salesman
                Open order type c, open order record W

--Customer summary
SELECT DISTINCT cdist*100000+ccust, ARCUST.CALPHA, ARCUST.CLIMIT, CISMD1*100+CISLM1, CSMDI1*100+CSLMN1,SALESMAN.SMNAME
FROM S219EAAV.MW4FILE.ARCUST ARCUST, S219EAAV.MW4FILE.SALESMAN SALESMAN
WHERE ARCUST.CISMD1 = SALESMAN.SMDIST AND ARCUST.CISLM1 = SALESMAN.SMSMAN
ORDER BY ARCUST.CALPHA

--joins customer and salesman
In excel this produces monthly sales by customer and salesman
                


--Customer summary 1
SELECT DISTINCT smdist*100+smsman, SALESMAN.SMNAME
FROM MW4FILE.SALESMAN SALESMAN
--In excel this produces monthly sales by salesman


-- Query for metalnet
SELECT ITEMONHD.IORECD, ITEMONHD.IOCOMP, ITEMONHD.IODIST, ITEMONHD.IOITEM, ITEMONHD.IOQOH, ITEMONHD.IOQOR, ITEMONHD.IOQOO, ITEMONHD.IOQOOR, ITEMONHD.IOQIT, ITEMONHD.IOQHLD, ITEMONHD.IOQCOL, ITEMONHD.IOROH, ITEMONHD.IOROR, ITEMONHD.IOROO, ITEMONHD.IOROOR, ITEMONHD.IORIT, ITEMONHD.IORIQC, ITEMONHD.IOBOMI, ITEMONHD.IOBOMC, ITEMONHD.IOLCCC, ITEMONHD.IOLCYY, ITEMONHD.IOLCMM, ITEMONHD.IOLCDD, ITEMONHD.IOCUOM, ITEMONHD.IOACST, ITEMONHD.IORCST, ITEMONHD.IORLCK, ITEMONHD.IOFCST, ITEMONHD.IOSCST, ITEMONHD.IOSCCC, ITEMONHD.IOSCYY, ITEMONHD.IOSCMM, ITEMONHD.IOSCDD, ITEMONHD.IODOSC, ITEMONHD.IODOSL, ITEMONHD.IOMNRQ, ITEMONHD.IOTORQ, ITEMONHD.IOPYIB, ITEMONHD.IOCYIB, ITEMONHD.IOCYIU, ITEMONHD.IOITST, ITEMONHD.IOPLVL, ITEMONHD.IOBGIN, ITEMONHD.IOMNBL, ITEMONHD.IOROPT, ITEMONHD.IOROPL, ITEMONHD.IOROQT, ITEMONHD.IOLDTM, ITEMONHD.IOBUY, ITEMONHD.IOBGIT, ITEMONHD.IOROFC, ITEMONHD.IOSSTK, ITEMONHD.IOLDTL, ITEMONHD.IOINVC, ITEMONHD.IOMTST, ITEMONHD.IODISC, ITEMONHD.IOOWNF, ITEMONHD.IONSDC, ITEMONHD.IO1RCT, ITEMONHD.IOTOPP, ITEMONHD.IOPMON, ITEMONHD.IOLOCC, ITEMONHD.IOLOYY, ITEMONHD.IOLOMM, ITEMONHD.IOLODD, ITEMONHD.IO1ACQ, ITEMONHD.IOLFB1, ITEMONHD.IOLFB2, ITEMONHD.IOCMNT, ITEMONHD.IOMSLS, ITEMONHD.IOYSLS, ITEMONHD.IOMCST, ITEMONHD.IOYCST, ITEMONHD.IOMUNT, ITEMONHD.IOYUNT, ITEMONHD.IOMWGT, ITEMONHD.IOYWGT, ITEMONHD.IODLCC, ITEMONHD.IODLYY, ITEMONHD.IODLMM, ITEMONHD.IODLDD, ITEMONHD.IOPUOM, ITEMONHD.IOCNTP, ITEMONHD.IOCNTL, ITEMONHD.IOBPRC, ITEMONHD.IOBPRL, ITEMONHD.IOBPCC, ITEMONHD.IOBPYY, ITEMONHD.IOBPMM, ITEMONHD.IOBPDD, ITEMONHD.IOCNTC, ITEMONHD.IOCDIS, ITEMONHD.IOCUST, ITEMONHD.IOMACN, ITEMONHD.IOPRCD, ITEMONHD.IORUNR, ITEMONHD.IORUOM, ITEMONHD.IOMEIF, ITEMONHD.IOORDI, ITEMONHD.IOMDIF, ITEMONHD.IOPMCC, ITEMONHD.IOPMYY, ITEMONHD.IOPMMM, ITEMONHD.IOPMDD, ITEMONHD.IOPMCD, ITEMONHD.IOLRCS, ITEMONHD.IOZ, ITEMONHD.IOC, ITEMONHD.IOD, ITEMONHD.IOPCTF, ITEMONHD.IOOUOM, ITEMONHD.IOMAGA, ITEMONHD.IOHURD, ITEMONHD.IOATAJ, ITEMONHD.IOLPCC, ITEMONHD.IOLPYY, ITEMONHD.IOLPMM, ITEMONHD.IOLPDD, ITEMONHD.IOLPUS, ITEMONHD.IOLSCC, ITEMONHD.IOLSYY, ITEMONHD.IOLSMM, ITEMONHD.IOLSDD, ITEMONHD.IOLSUS, ITEMONHD.IOLMCC, ITEMONHD.IOLMYY, ITEMONHD.IOLMMM, ITEMONHD.IOLMDD, ITEMONHD.IOLMUS, ITEMONHD.IOCLS3, ITEMONHD.IOSBCL, ITEMONHD.IOSTCL, ITEMONHD.IOPUSD, ITEMONHD.IOPUSQ, ITEMONHD.IOPCST, ITEMONHD.IOPSLS, ITEMONHD.IOPUNT, ITEMONHD.IOPLBS, ITEMONHD.IOPATN, ITEMONHD.IOMOST, ITEMONHD.IOBOMW, ITEMONHD.IOAVMS, ITEMONHD.IOAVLB, ITEMONHD.IOAVOH, ITEMONHD.IOAVOS, ITEMONHD.IOUSQT, ITEMONHD.IOUSDL, ITEMONHD.IOYTDL, ITEMONHD.IOLIFO, ITEMONHD.IOSRCE, ITEMONHD.IOSUCC, ITEMONHD.IOSUYY, ITEMONHD.IOSUMM, ITEMONHD.IOSUDD, ITEMONHD.IOOPPO, ITEMONHD.IOOPPD, ITEMONHD.IOTSTR, ITEMONHD.IOAVMQ, ITEMONHD.IOITDL, ITEMONHD.IOITUN, ITEMONHD.IORSTK, ITEMONHD.IORSMP, ITEMONHD.IOHFRR, ITEMONHD.IOCORS, ITEMONHD.IOTRRS, ITEMONHD.IOMPRS, ITEMONHD.IOSTOR, ITEMONHD.IOASOR, ITEMONHD.IOAVG3, ITEMONHD.IOAV12, ITEMONHD.IOPICC, ITEMONHD.IOPIYY, ITEMONHD.IOPIMM, ITEMONHD.IOPIDD, ITEMONHD.IOPDSC, ITEMONHD.IOITRM, ITEMONHD.IOLPMC, ITEMONHD.IOLPML, ITEMONHD.IOCPMC, ITEMONHD.IOCPML, ITEMONHD.IODSPS, ITEMONHD.IOSPCD, ITEMONHD.IOPRC2, ITEMONHD.IOSALE, ITEMONHD.IOQQTY, ITEMONHD.IOQAC, ITEMONHD.IOOELK, ITEMONHD.IOMPLK, ITEMONHD.IOABCP, ITEMONHD.IOANRS, ITEMONHD.IOTAX, ITEMONHD.IORBCS, ITEMONHD.IOTUNA
FROM S219EAAV.MW4FILE.ITEMONHD ITEMONHD
-- Crazy.. in excel is liked to price

*/

/*
-- Salesorders
SELECT oddist*1000000+odordr, SALESMAN.SMNAME, OEOPNORD.OOTYPE, odcdis*100000+odcust, ARCUST.CALPHA, OOICC*1000000+OOIYY*10000+OOIMM*100+OOIDD, OEDETAIL.ODITEM, OEDETAIL.ODSIZ1, OEDETAIL.ODSIZ2, OEDETAIL.ODSIZ3, OEDETAIL.ODCRTD, SLSDSCOV.DXDSC2, OEDETAIL.ODTFTS, OEDETAIL.ODTLBS, OEDETAIL.ODTPCS, OEDETAIL.ODSLSX, OEDETAIL.ODFRTS, OEDETAIL.ODCSTX, OEDETAIL.ODPRCC, OEDETAIL.ODADCC, OEDETAIL.ODWCCS, ARCUST.CSTAT, ARCUST.CCTRY
FROM S219EAAV.MW4FILE.ARCUST ARCUST, S219EAAV.MW4FILE.OEDETAIL OEDETAIL, S219EAAV.MW4FILE.OEOPNORD OEOPNORD, S219EAAV.MW4FILE.SALESMAN SALESMAN, S219EAAV.MW4FILE.SLSDSCOV SLSDSCOV
WHERE OEDETAIL.ODDIST = OEOPNORD.OODIST AND OEDETAIL.ODDIST = SLSDSCOV.DXDIST AND OEDETAIL.ODMLIN = SLSDSCOV.DXMLIN AND OEDETAIL.ODORDR = OEOPNORD.OOORDR AND OEDETAIL.ODORDR = SLSDSCOV.DXORDR AND OEOPNORD.OOCDIS = ARCUST.CDIST AND OEOPNORD.OOCUST = ARCUST.CCUST AND OEOPNORD.OOISMD = SALESMAN.SMDIST AND OEOPNORD.OOISMN = SALESMAN.SMSMAN AND ((OEOPNORD.OOTYPE In ('A','B')) AND (OEOPNORD.OORECD='W') AND (ooicc*10000+ooiyy*100+ooimm Between ? And ?))
--In excel -- Order, invoiced, salesman, customer, so... orders



--SPO
SELECT oddist*1000000+odordr, SALESMAN.SMNAME, OEOPNORD.OOTYPE, odcdis*100000+odcust, ARCUST.CALPHA, ooicc*100+ooiyy, OEOPNORD.OOIMM, OEOPNORD.OOIDD, OEDETAIL.ODITEM, SPHEADER.BSSVEN, SPHEADER.BSSPS#
FROM S219EAAV.MW4FILE.ARCUST ARCUST, S219EAAV.MW4FILE.OEDETAIL OEDETAIL, S219EAAV.MW4FILE.OEOPNORD OEOPNORD, S219EAAV.MW4FILE.SALESMAN SALESMAN, S219EAAV.MW4FILE.SPHEADER SPHEADER
WHERE OEDETAIL.ODDIST = OEOPNORD.OODIST AND OEDETAIL.ODORDR = OEOPNORD.OOORDR AND OEOPNORD.OOCDIS = ARCUST.CDIST AND OEOPNORD.OOCUST = ARCUST.CCUST AND OEOPNORD.OOISMD = SALESMAN.SMDIST AND OEOPNORD.OOISMN = SALESMAN.SMSMAN AND OEDETAIL.ODDIST = SPHEADER.BSDIST AND OEDETAIL.ODORDR = SPHEADER.BSORDR AND ((OEOPNORD.OOTYPE In ('A','B')) AND (OEOPNORD.OORECD='W') AND (OEDETAIL.ODDIST=1) AND (OEDETAIL.ODORDR>?))

*/










EXEC [mrs].[usp_TranslateSQLQuery] @p_InputQuery = @myVarInputSQL, @p_TranslatedQuery = @myVarOutputSQL OUTPUT,  @p_DebugMode = 0;
SELECT @myVarOutputSQL




**************************************************************************

