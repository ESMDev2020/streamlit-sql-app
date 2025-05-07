﻿/*
==============================================================================
Name:         [mrs].[mysp_QuerySelector]
Description:  Centralized procedure for executing various ERP-based queries.
              This stored procedure serves as a single point of access for
              multiple predefined queries, making it easier to maintain and
              standardize data access patterns. Queries primarily retrieve data
              from AS400 ERP system tables (those with z_ prefix).
              
Input:        @QueryID VARCHAR(20)   - Identifies which query to run 
                                        (use 'help' to see available options)
              @StartDate INT         - Start date in format YYYYMMDD (default: 20250101)
              @EndDate INT           - End date in format YYYYMMDD (default: 20250228)
              @DebugMode BIT         - When set to 1, prints query before execution
              
Output:       Returns a result set based on the selected query.
              Different queries return different result sets.
              
Metadata:     Author:        MRS Database Team
              Creation Date: May 2025
              Version:       1.0
              Target:        SQL Server 2022, SigmaTB Database, 'mrs' Schema

Example Usage:  
              -- Get available queries
              EXEC [mrs].[mysp_QuerySelector] @QueryID = 'help', @DebugMode = 1
              
              -- Run ROP query with default parameters
              EXEC [mrs].[mysp_QuerySelector] @QueryID = 'ROP_PRICE'
              
              -- Run query with date range
              EXEC [mrs].[mysp_QuerySelector] 
                   @QueryID = 'USAGE',
                   @StartDate = 20250401,
                   @EndDate = 20250430
                   
Example Resultset:
              -- Result set varies based on query selected
              -- The 'help' query returns a list of available query IDs
==============================================================================
*/

ALTER PROCEDURE [mrs].[mysp_QuerySelector]
    @QueryID VARCHAR(30),              -- Identifies which query to run
    @StartDate INT = 20250101,         -- Default start date (fixed semicolon)
    @EndDate INT = 20250228,           -- Default end date (fixed semicolon)
    @DebugMode BIT = 0,                 -- As per your guidelines
    @Only10 BIT = 0  
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Declare variables before using them (fixed syntax)
    DECLARE @MinItem VARCHAR(20) = '50000';    -- PO BDITEM, USAGE IHITEM
    DECLARE @MaxItem VARCHAR(20) = '99998';    
    DECLARE @MinItem2 VARCHAR(20) = '49999';   -- ROP IMITEM
    DECLARE @MaxItem2 VARCHAR(20) = '90000';
    DECLARE @SqlQuery NVARCHAR(MAX);
    
    -- Select query based on parameter (changed CASE to IF-ELSE for string comparison)
    IF @QueryID = 'help'
    BEGIN           
        SET @SqlQuery = 'SELECT ''ROP_PRICE'', ''ROP_MP'', ''ROP_PO'', ''ROP_ROP'',
                        ''SALES_DATA'', ''SALES_DATA_orbytrans'', ''SALES_ORDERS_orbytrans'', 
                        ''TAG'', ''USAGE'', ''USAGE_SUM'', 
                        ''CM'', ''CUST_SUM'', ''CUST_SUM1'', ''ITEMONHD'',
                        ''SALES_ORDERS'', ''SPO'', ''SHIPMAST'', ''GLTRANS'',
                        ''SHIPMENTS''';
    END
    ELSE IF @QueryID = 'ROP_PRICE'
    BEGIN
        SET @SqlQuery = 'SELECT ''price'', [mrs].[z_Item_on_Hand_File_____ITEMONHD].[ITEM_NUMBER_____IOITEM], [z_Item_on_Hand_File_____ITEMONHD].[Base_Price_____IOBPRC] FROM [mrs].[z_Item_on_Hand_File_____ITEMONHD]';
    END
    ELSE IF @QueryID = 'ROP_MP'
    BEGIN
        SET @SqlQuery = 'SELECT ''Material processing query'', det.[Transaction_#_____MDORDR], vend.[Vendor_#_____VVNDR], vend.[Vendor_Alpha_Search_____VALPHA], det.[=_OPEN__C_=_CLOSED_____MDCLOS], det.[ITEM_NUMBER_____MDITEM], det.[CRT_DESCRIPTION_____MDCRTD], (CAST(CAST(det.[REQUESTED_SHIP_CENTURY_____MDRQCC] AS DECIMAL(5,1)) AS INT)*1000000+CAST(CAST(det.[REQUESTED_SHIP_YEAR_____MDRQYY] AS DECIMAL(5,1)) AS INT)*10000+CAST(CAST(det.[REQUESTED_SHIP_MONTH_____MDRQMM] AS DECIMAL(5,1)) AS INT)*100+CAST(CAST(det.[REQUESTED_SHIP_DAY_____MDRQDD] AS DECIMAL(5,1)) AS INT)) AS CalculatedShipDate, det.[ON_ORDER_QUANTITY_____MDOQTY], det.[ORIGINAL_ORDERED_UOM_____MDOUOM], det.[ORDER_QUANTITY_____MDIQTY] FROM [mrs].[z_Vendor_Master_File_____APVEND] vend INNER JOIN [mrs].[z_Material_Processing_Order_Detail_____MPDETAIL] det ON vend.[COMPANY_NUMBER_____VCOMP] = det.[COMPANY_NUMBER_____MDCOMP] AND vend.[Vendor_#_____VVNDR] = det.[Vendor_#_____MDVNDR] ORDER BY det.[ITEM_NUMBER_____MDITEM], det.[Transaction_#_____MDORDR] DESC';
    END
    ELSE IF @QueryID = 'ROP_PO'
    BEGIN
        -- Parameters: Min Max ITEM
        SET @SqlQuery = 'SELECT ''Purchase order query'', pod.[Transaction_#_____BDPONO], pod.[Vendor_#_____BDVNDR], vend.[Vendor_Name_____VNAME], pod.[Record_Code_____BDRECD], pod.[ITEM_NUMBER_____BDITEM], pod.[CRT_Description_____BDCRTD], (CAST(CAST(pod.[Revised_Promise_Century_____BDRPCC] AS DECIMAL(5,1)) AS INT)*1000000+CAST(CAST(pod.[Revised_Promise_Year_____BDRPYY] AS DECIMAL(5,1)) AS INT)*10000+CAST(CAST(pod.[Revised_Promise_Month_____BDRPMM] AS DECIMAL(5,1)) AS INT)*100+CAST(CAST(pod.[Revised_Promise_Day_____BDRPDD] AS DECIMAL(5,1)) AS INT)) AS RevisedPromiseDate, pod.[Original_Inventory_Quantity_____BDOQOO], pod.[Inventory_UOM_____BDIUOM], pod.[Current_Inv._Quantity_Ordered_/_Received_____BDCQOO], pod.[Original_Ordered__Quantity_____BDOOQ], pod.[Total_Inventory_Quantity_Received_____BDTIQR], (CAST(CAST(pod.[Purchase_Order_Century_____BDPOCC] AS DECIMAL(5,1)) AS INT)*1000000+CAST(CAST(pod.[Purchase_Order_Year_____BDPOYY] AS DECIMAL(5,1)) AS INT)*10000+CAST(CAST(pod.[Purchase_Order_Month_____BDPOMM] AS DECIMAL(5,1)) AS INT)*100+CAST(CAST(pod.[Purchase_Order_Day_____BDPODD] AS DECIMAL(5,1)) AS INT)) AS PurchaseOrderDate, (CAST(CAST(pod.[Received_Century_____BDRCCC] AS DECIMAL(5,1)) AS INT)*1000000+CAST(CAST(pod.[Received_Year_____BDRCYY] AS DECIMAL(5,1)) AS INT)*10000+CAST(CAST(pod.[Received_Month_____BDRCMM] AS DECIMAL(5,1)) AS INT)*100+CAST(CAST(pod.[Received_Day_____BDRCDD] AS DECIMAL(5,1)) AS INT)) AS ReceivedDate FROM [mrs].[z_Purchase_Order_Detail_File_____PODETAIL] pod LEFT OUTER JOIN [mrs].[z_Vendor_Master_File_____APVEND] vend ON pod.[Vendor_#_____BDVNDR] = vend.[Vendor_#_____VVNDR] WHERE (pod.[ITEM_NUMBER_____BDITEM] Between @MinItem And @MaxItem) ORDER BY pod.[ITEM_NUMBER_____BDITEM], pod.[Transaction_#_____BDPONO] DESC';
    END
    ELSE IF @QueryID = 'ROP_ROP'
    BEGIN
        -- Parameters MinItem2, MaxItem2
        SET @SqlQuery = 'SELECT ''ROP Query'', [z_Item_Master_File_____ITEMMAST].[Fast_Path_Item_Description_____IMFSP2], [z_Item_Master_File_____ITEMMAST].[ITEM_NUMBER_____IMITEM], [z_Item_Master_File_____ITEMMAST].[Size_1_____IMSIZ1], [z_Item_Master_File_____ITEMMAST].[Size_2_____IMSIZ2], [z_Item_Master_File_____ITEMMAST].[Size_3_____IMSIZ3], [z_Item_Master_File_____ITEMMAST].[Item_Print_Descr_Two_____IMDSC2], [z_Item_Master_File_____ITEMMAST].[Weight_Per_Foot_____IMWPFT], [z_Item_on_Hand_File_____ITEMONHD].[Average_Cost_____IOACST], [z_Item_on_Hand_File_____ITEMONHD].[Qty_On_Hand_____IOQOH], [z_Item_on_Hand_File_____ITEMONHD].[Qty_On_Order_____IOQOO], [z_Item_on_Hand_File_____ITEMONHD].[Qty_On_Reserved_____IOQOR]+[z_Item_on_Hand_File_____ITEMONHD].[Qty_On_Order_Rsrvd_____IOQOOR], [z_Item_Master_File_____ITEMMAST].[Item_Print_Descr_One_____IMDSC1], [z_Item_Master_File_____ITEMMAST].[PSI_=_PER_SQUARE_INCH_PLI_=_PER_LINEAR_INCH_"___"=_____IMWUOM], [z_Item_Master_File_____ITEMMAST].[Company_SMO_____IMCSMO] FROM [mrs].[z_Item_Master_File_____ITEMMAST] [z_Item_Master_File_____ITEMMAST], [mrs].[z_Item_on_Hand_File_____ITEMONHD] [z_Item_on_Hand_File_____ITEMONHD] WHERE [z_Item_on_Hand_File_____ITEMONHD].[ITEM_NUMBER_____IOITEM] = [z_Item_Master_File_____ITEMMAST].[ITEM_NUMBER_____IMITEM] AND (([z_Item_Master_File_____ITEMMAST].[Record_Code_____IMRECD]=''A'') AND ([z_Item_Master_File_____ITEMMAST].[ITEM_NUMBER_____IMITEM] Between @MinItem2 And @MaxItem2)) ORDER BY [z_Item_Master_File_____ITEMMAST].[Fast_Path_Item_Description_____IMFSP2]';
    END
    ELSE IF @QueryID = 'SALES_DATA'
    BEGIN
        SET @SqlQuery = 'SELECT ''ROP - Sales data Query'', O.[Record_Code_____OORECD], D.[Order_Type_____ODTYPE], D.[ITEM_NUMBER_____ODITEM], D.[Transaction_#_____ODORDR], O.[CUSTOMER_NUMBER_____OOCUST], C.[Customer_Alpha_Name_____CALPHA], D.[TOTAL_LBS_____ODTLBS], D.[TOTAL_FTS_____ODTFTS], CAST(CAST(O.[ORDER_DATE_CENTURY_____OOOCC] AS DECIMAL(5,1)) AS INT)*1000000 + CAST(CAST(O.[ORDER_DATE_YEAR_____OOOYY] AS DECIMAL(5,1)) AS INT)*10000 + CAST(CAST(O.[ORDER_DATE_MONTH_____OOOMM] AS DECIMAL(5,1)) AS INT)*100 + CAST(CAST(O.[ORDER_DATE_DAY_____OOODD] AS DECIMAL(5,1)) AS INT), CAST(CAST(C.[Salesman_One_District_Number_____CSMDI1] AS DECIMAL(5,1)) AS INT)*100 + CAST(CAST(C.[Salesman_One_Number_____CSLMN1] AS DECIMAL(5,1)) AS INT) FROM [mrs].[z_Customer_Master_File_____ARCUST] C JOIN [mrs].[z_Open_Order_File_____OEOPNORD] O ON O.[CUSTOMER_NUMBER_____OOCUST] = C.[CUSTOMER_NUMBER_____CCUST] JOIN [mrs].[z_Order_Detail_File_____OEDETAIL] D ON D.[Transaction_#_____ODORDR] = O.[ORDER_NUMBER_____OOORDR] WHERE O.[Record_Code_____OORECD] = ''A'' AND D.[Order_Type_____ODTYPE] IN (''A'', ''C'') ORDER BY D.[ITEM_NUMBER_____ODITEM]';
    END
    ELSE IF @QueryID = 'SALES_DATA_orbytrans'
    BEGIN
        SET @SqlQuery = 'SELECT ''ROP - Sales data Query'', O.[Record_Code_____OORECD], D.[Order_Type_____ODTYPE], D.[ITEM_NUMBER_____ODITEM], D.[Transaction_#_____ODORDR], O.[CUSTOMER_NUMBER_____OOCUST], C.[Customer_Alpha_Name_____CALPHA], D.[TOTAL_LBS_____ODTLBS], D.[TOTAL_FTS_____ODTFTS], CAST(CAST(O.[ORDER_DATE_CENTURY_____OOOCC] AS DECIMAL(5,1)) AS INT)*1000000 + CAST(CAST(O.[ORDER_DATE_YEAR_____OOOYY] AS DECIMAL(5,1)) AS INT)*10000 + CAST(CAST(O.[ORDER_DATE_MONTH_____OOOMM] AS DECIMAL(5,1)) AS INT)*100 + CAST(CAST(O.[ORDER_DATE_DAY_____OOODD] AS DECIMAL(5,1)) AS INT), CAST(CAST(C.[Salesman_One_District_Number_____CSMDI1] AS DECIMAL(5,1)) AS INT)*100 + CAST(CAST(C.[Salesman_One_Number_____CSLMN1] AS DECIMAL(5,1)) AS INT) FROM [mrs].[z_Customer_Master_File_____ARCUST] C JOIN [mrs].[z_Open_Order_File_____OEOPNORD] O ON O.[CUSTOMER_NUMBER_____OOCUST] = C.[CUSTOMER_NUMBER_____CCUST] JOIN [mrs].[z_Order_Detail_File_____OEDETAIL] D ON D.[Transaction_#_____ODORDR] = O.[ORDER_NUMBER_____OOORDR] WHERE O.[Record_Code_____OORECD] = ''A'' AND D.[Order_Type_____ODTYPE] IN (''A'', ''C'') ORDER BY D.[TRANSACTION_#_____ODORDR] DESC';
    END
    ELSE IF @QueryID = 'SALES_ORDERS_orbytrans'
    BEGIN
        -- Using procedure parameters instead of hardcoded values
        SET @SqlQuery = 'SELECT CAST(CAST([z_Order_Detail_File_____OEDETAIL].[O/E_District_#_____ODDIST] AS DECIMAL(18, 2)) AS INT) * 1000000 + CAST(CAST([z_Order_Detail_File_____OEDETAIL].[Transaction_#_____ODORDR] AS DECIMAL(18, 2)) AS INT) Order_districtPlusTransaction, [z_Salesman_Master_File_____SALESMAN].[Salesman_Name_____SMNAME], [z_Open_Order_File_____OEOPNORD].[Order_Type_____OOTYPE], CAST(CAST([z_Order_Detail_File_____OEDETAIL].[CUSTOMER_DISTRICT_____ODCDIS] AS DECIMAL(18, 2)) AS INT) * 100000 + CAST(CAST([z_Order_Detail_File_____OEDETAIL].[CUSTOMER_NUMBER_____ODCUST] AS DECIMAL(18, 2)) AS INT) Customer_DistrictPlusCustomer, [z_Customer_Master_File_____ARCUST].[Customer_Alpha_Name_____CALPHA], CAST(CAST([z_Open_Order_File_____OEOPNORD].[INVOICE_CENTURY_____OOICC] AS DECIMAL(18, 2)) AS INT) * 1000000 + CAST(CAST([z_Open_Order_File_____OEOPNORD].[INVOICE_YEAR_____OOIYY] AS DECIMAL(18, 2)) AS INT) * 10000 + CAST(CAST([z_Open_Order_File_____OEOPNORD].[INVOICE_MONTH_____OOIMM] AS DECIMAL(18, 2)) AS INT) * 100 + CAST(CAST([z_Open_Order_File_____OEOPNORD].[INVOICE_DAY_____OOIDD] AS DECIMAL(18, 2)) AS INT) as InvoiceDate_OOI, [z_Order_Detail_File_____OEDETAIL].[ITEM_NUMBER_____ODITEM], [z_Order_Detail_File_____OEDETAIL].[SIZE_1_____ODSIZ1], [z_Order_Detail_File_____OEDETAIL].[SIZE_2_____ODSIZ2], [z_Order_Detail_File_____OEDETAIL].[SIZE_3_____ODSIZ3], [z_Order_Detail_File_____OEDETAIL].[CRT_DESCRIPTION_____ODCRTD], [z_Sales_Description_Override_____SLSDSCOV].[Item_Print_Descr_Two_____DXDSC2], [z_Order_Detail_File_____OEDETAIL].[TOTAL_FTS_____ODTFTS], [z_Order_Detail_File_____OEDETAIL].[TOTAL_LBS_____ODTLBS], [z_Order_Detail_File_____OEDETAIL].[TOTAL_PCS_____ODTPCS], [z_Order_Detail_File_____OEDETAIL].[NEGOTIATED_SELL_$_EXT_____ODSLSX], [z_Order_Detail_File_____OEDETAIL].[PRORATED_FREIGHT_SALES_____ODFRTS], [z_Order_Detail_File_____OEDETAIL].[COSTING_METHOD_COST_EXT_____ODCSTX], [z_Order_Detail_File_____OEDETAIL].[TOTAL_PROCESS_COST_____ODPRCC], [z_Order_Detail_File_____OEDETAIL].[TOTAL_ADDTL_CHG_COST_____ODADCC], [z_Order_Detail_File_____OEDETAIL].[PRORATED_WHOLE_ORDER_COST_AMT_____ODWCCS], [z_Customer_Master_File_____ARCUST].[State_____CSTAT], [z_Customer_Master_File_____ARCUST].[Country_____CCTRY] FROM [mrs].[z_Customer_Master_File_____ARCUST] AS [z_Customer_Master_File_____ARCUST], [mrs].[z_Order_Detail_File_____OEDETAIL] AS [z_Order_Detail_File_____OEDETAIL], [mrs].[z_Open_Order_File_____OEOPNORD] AS [z_Open_Order_File_____OEOPNORD], [mrs].[z_Salesman_Master_File_____SALESMAN] AS [z_Salesman_Master_File_____SALESMAN], [mrs].[z_Sales_Description_Override_____SLSDSCOV] AS [z_Sales_Description_Override_____SLSDSCOV] WHERE CAST(CAST([z_Order_Detail_File_____OEDETAIL].[O/E_District_#_____ODDIST] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Open_Order_File_____OEOPNORD].[O/E_Dist#_____OODIST] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Order_Detail_File_____OEDETAIL].[O/E_District_#_____ODDIST] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Sales_Description_Override_____SLSDSCOV].[Tran._District_#_____DXDIST] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Order_Detail_File_____OEDETAIL].[MAIN_LINE_____ODMLIN] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Sales_Description_Override_____SLSDSCOV].[MAIN_LINE_____DXMLIN] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Order_Detail_File_____OEDETAIL].[Transaction_#_____ODORDR] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Open_Order_File_____OEOPNORD].[ORDER_NUMBER_____OOORDR] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Order_Detail_File_____OEDETAIL].[Transaction_#_____ODORDR] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Sales_Description_Override_____SLSDSCOV].[Transaction_#_____DXORDR] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Open_Order_File_____OEOPNORD].[CUSTOMER_DISTRICT_____OOCDIS] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Customer_Master_File_____ARCUST].[CUSTOMER_DISTRICT_NUMBER_____CDIST] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Open_Order_File_____OEOPNORD].[CUSTOMER_NUMBER_____OOCUST] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Customer_Master_File_____ARCUST].[CUSTOMER_NUMBER_____CCUST] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Open_Order_File_____OEOPNORD].[INSIDE_SALESMAN_DISTRICT_____OOISMD] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Salesman_Master_File_____SALESMAN].[Salesman_District_Number_____SMDIST] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Open_Order_File_____OEOPNORD].[INSIDE_SALESMAN_NUMBER_____OOISMN] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Salesman_Master_File_____SALESMAN].[Salesman_Number_____SMSMAN] AS DECIMAL(18, 2)) AS INT) AND (([z_Open_Order_File_____OEOPNORD].[Order_Type_____OOTYPE] IN (''A'',''B'')) AND ([z_Open_Order_File_____OEOPNORD].[Record_Code_____OORECD]=''W'') AND (CAST(CAST([z_Open_Order_File_____OEOPNORD].[INVOICE_CENTURY_____OOICC] AS DECIMAL(18, 2)) AS INT)*10000+CAST(CAST([z_Open_Order_File_____OEOPNORD].[INVOICE_YEAR_____OOIYY] AS DECIMAL(18, 2)) AS INT)*100+CAST(CAST([z_Open_Order_File_____OEOPNORD].[INVOICE_MONTH_____OOIMM] AS DECIMAL(18, 2)) AS INT) BETWEEN @StartDate/100 AND @EndDate/100)) ORDER BY [z_Order_Detail_File_____OEDETAIL].[Transaction_#_____ODORDR] DESC';
    END
    ELSE IF @QueryID = 'TAG'
    BEGIN
        -- Params: MinItem2
        -- Ordered by ITEM, HEAT, COIL, NumericLenght
        SET @SqlQuery = 'SELECT ''ROP - TAG query'', [z_Tag_Master_File_____ITEMTAG].[ITEM_NUMBER_____ITITEM], [z_Tag_Master_File_____ITEMTAG].[TAG_NUMBER_ALPHA_____ITTAG], [z_Tag_Master_File_____ITEMTAG].[Tag_Master_Description_____ITTDES], [z_Tag_Master_File_____ITEMTAG].[Numeric_Length_____ITLNTH], [z_Tag_Master_File_____ITEMTAG].[Tag_Pieces_____ITTPCS], [z_Tag_Master_File_____ITEMTAG].[Heat_#_____ITHEAT], [z_Tag_Master_File_____ITEMTAG].[Mill_Coil#_____ITV301], [z_Tag_Master_File_____ITEMTAG].[Warehouse_Loc_____ITLOCT], [z_Tag_Master_File_____ITEMTAG].[Tag_Quantity_____ITTQTY], [z_Tag_Master_File_____ITEMTAG].[Reserved_Quantity_____ITRQTY], [z_Item_Master_File_____ITEMMAST].[Fast_Path_Item_Description_____IMFSP2] FROM [mrs].[z_Item_Master_File_____ITEMMAST] [z_Item_Master_File_____ITEMMAST], [mrs].[z_Tag_Master_File_____ITEMTAG] [z_Tag_Master_File_____ITEMTAG] WHERE [z_Tag_Master_File_____ITEMTAG].[ITEM_NUMBER_____ITITEM] = [z_Item_Master_File_____ITEMMAST].[ITEM_NUMBER_____IMITEM] AND ([z_Tag_Master_File_____ITEMTAG].[Record_Code_____ITRECD] = ''A'' AND [z_Tag_Master_File_____ITEMTAG].[ITEM_NUMBER_____ITITEM] > @MinItem2) ORDER BY [z_Tag_Master_File_____ITEMTAG].[ITEM_NUMBER_____ITITEM], [z_Tag_Master_File_____ITEMTAG].[Heat_#_____ITHEAT], [z_Tag_Master_File_____ITEMTAG].[Mill_Coil#_____ITV301], [z_Tag_Master_File_____ITEMTAG].[Numeric_Length_____ITLNTH]';
    END
    ELSE IF @QueryID = 'USAGE'
    BEGIN
        -- Parameters MinItem, MaxItem
        SET @SqlQuery = 'SELECT ''ROP - Usage query'', T.[ITEM_NUMBER_____IHITEM], T.[Transaction_Type_____IHTRNT], T.[Transaction_#_____IHTRN#], T.[Vendor_#_____IHVNDR], T.[CUSTOMER_NUMBER_____IHCUST], T.[Trans_YY_____IHTRYY], T.[Trans_MM_____IHTRMM], T.[Trans_DD_____IHTRDD], T.[Trans_Inv_Qty_____IHTQTY] FROM [mrs].[z_Item_Transaction_History_____ITEMHIST] T WHERE (CAST(CAST(T.[Trans_CC_____IHTRCC] AS DECIMAL(5,1)) AS INT)*1000000 + CAST(CAST(T.[Trans_YY_____IHTRYY] AS DECIMAL(5,1)) AS INT)*10000 + CAST(CAST(T.[Trans_MM_____IHTRMM] AS DECIMAL(5,1)) AS INT)*100 + CAST(CAST(T.[Trans_DD_____IHTRDD] AS DECIMAL(5,1)) AS INT) > @StartDate) AND (T.[ITEM_NUMBER_____IHITEM] BETWEEN @MinItem AND @MaxItem) ORDER BY T.[ITEM_NUMBER_____IHITEM], T.[Trans_YY_____IHTRYY], T.[Trans_MM_____IHTRMM], T.[Trans_DD_____IHTRDD]';
    END
    ELSE IF @QueryID = 'USAGE_SUM'
    BEGIN
        -- Parameters
        SET @SqlQuery = 'SELECT ''ROP - Usage sum query'' AS QueryName, T.[ITEM_NUMBER_____IHITEM], T.[Transaction_Type_____IHTRNT], T.[CUSTOMER_NUMBER_____IHCUST], C.[Customer_Alpha_Name_____CALPHA], CAST(CAST(C.[Salesman_One_District_Number_____CSMDI1] AS DECIMAL(5,1)) AS INT)*100 + CAST(CAST(C.[Salesman_One_Number_____CSLMN1] AS DECIMAL(5,1)) AS INT) AS SalesmanCode FROM [mrs].[z_Customer_Master_File_____ARCUST] C INNER JOIN [mrs].[z_Item_Transaction_History_____ITEMHIST] T ON C.[CUSTOMER_NUMBER_____CCUST] = T.[CUSTOMER_NUMBER_____IHCUST] WHERE (CAST(CAST(T.[Trans_CC_____IHTRCC] AS DECIMAL(5,1)) AS INT)*1000000 + CAST(CAST(T.[Trans_YY_____IHTRYY] AS DECIMAL(5,1)) AS INT)*10000 + CAST(CAST(T.[Trans_MM_____IHTRMM] AS DECIMAL(5,1)) AS INT)*100 + CAST(CAST(T.[Trans_DD_____IHTRDD] AS DECIMAL(5,1)) AS INT) > @StartDate) AND (T.[ITEM_NUMBER_____IHITEM] BETWEEN @MinItem AND @MaxItem) AND (T.[Transaction_Type_____IHTRNT] IN (''CR'', ''IN'')) GROUP BY T.[ITEM_NUMBER_____IHITEM], T.[Transaction_Type_____IHTRNT], T.[CUSTOMER_NUMBER_____IHCUST], C.[Customer_Alpha_Name_____CALPHA], CAST(CAST(C.[Salesman_One_District_Number_____CSMDI1] AS DECIMAL(5,1)) AS INT)*100 + CAST(CAST(C.[Salesman_One_Number_____CSLMN1] AS DECIMAL(5,1)) AS INT) ORDER BY T.[ITEM_NUMBER_____IHITEM], C.[Customer_Alpha_Name_____CALPHA]';
    END
    ELSE IF @QueryID = 'CM'
    BEGIN
        -- Parameters. C = Credit. W = ??. start date, end date
        SET @SqlQuery = 'SELECT ''Sales Analisis - credit memos'', CAST(CAST(D.[O/E_District_#_____ODDIST] AS DECIMAL(5,1)) AS INT)*1000000 + CAST(CAST(D.[Transaction_#_____ODORDR] AS DECIMAL(10,1)) AS INT) as Order__District_ODDIST_PlusTransaction_ODORDR, S.[Salesman_Name_____SMNAME], O.[Order_Type_____OOTYPE], CAST(CAST(D.[CUSTOMER_DISTRICT_____ODCDIS] AS DECIMAL(5,1)) AS INT)*100000 + CAST(CAST(D.[CUSTOMER_NUMBER_____ODCUST] AS DECIMAL(10,1)) AS INT) as CustomerDistrict_ODCDIS_PlusNumber_ODCUST, C.[Customer_Alpha_Name_____CALPHA], D.[ITEM_NUMBER_____ODITEM], D.[SIZE_1_____ODSIZ1], D.[SIZE_2_____ODSIZ2], D.[SIZE_3_____ODSIZ3], D.[CRT_DESCRIPTION_____ODCRTD], D.[TOTAL_FTS_____ODTFTS], D.[TOTAL_LBS_____ODTLBS], D.[TOTAL_PCS_____ODTPCS], D.[NEGOTIATED_SELL_$_EXT_____ODSLSX], D.[PRORATED_FREIGHT_SALES_____ODFRTS], D.[COSTING_METHOD_COST_EXT_____ODCSTX], D.[TOTAL_PROCESS_COST_____ODPRCC], D.[TOTAL_ADDTL_CHG_COST_____ODADCC], D.[PRORATED_WHOLE_ORDER_COST_AMT_____ODWCCS], C.[State_____CSTAT], C.[Country_____CCTRY], CAST(CAST(O.[INVOICE_CENTURY_____OOICC] AS DECIMAL(5,1)) AS INT)*1000000 + CAST(CAST(O.[INVOICE_YEAR_____OOIYY] AS DECIMAL(5,1)) AS INT)*10000 + CAST(CAST(O.[INVOICE_MONTH_____OOIMM] AS DECIMAL(5,1)) AS INT)*100 + CAST(CAST(O.[INVOICE_DAY_____OOIDD] AS DECIMAL(5,1)) AS INT) as CustInvoiceDate_OOIC, D.[CUSTOMER_REFERENCE_____ODCREF] FROM [mrs].[z_Order_Detail_File_____OEDETAIL] AS D INNER JOIN [mrs].[z_Open_Order_File_____OEOPNORD] AS O ON D.[O/E_District_#_____ODDIST] = O.[O/E_Dist#_____OODIST] AND D.[Transaction_#_____ODORDR] = O.[ORDER_NUMBER_____OOORDR] INNER JOIN [mrs].[z_Customer_Master_File_____ARCUST] AS C ON O.[CUSTOMER_DISTRICT_____OOCDIS] = C.[CUSTOMER_DISTRICT_NUMBER_____CDIST] AND O.[CUSTOMER_NUMBER_____OOCUST] = C.[CUSTOMER_NUMBER_____CCUST] INNER JOIN [mrs].[z_Salesman_Master_File_____SALESMAN] AS S ON O.[INSIDE_SALESMAN_DISTRICT_____OOISMD] = S.[Salesman_District_Number_____SMDIST] AND O.[INSIDE_SALESMAN_NUMBER_____OOISMN] = S.[Salesman_Number_____SMSMAN] WHERE O.[Order_Type_____OOTYPE] = ''C'' AND O.[Record_Code_____OORECD] = ''W'' AND (CAST(CAST(O.[INVOICE_CENTURY_____OOICC] AS DECIMAL(5,1)) AS INT)*1000000 + CAST(CAST(O.[INVOICE_YEAR_____OOIYY] AS DECIMAL(5,1)) AS INT)*10000 + CAST(CAST(O.[INVOICE_MONTH_____OOIMM] AS DECIMAL(5,1)) AS INT)*100 + CAST(CAST(O.[INVOICE_DAY_____OOIDD] AS DECIMAL(5,1)) AS INT) BETWEEN @StartDate AND @EndDate) ORDER BY D.[Transaction_#_____ODORDR] DESC';
    END
    ELSE IF @QueryID = 'CUST_SUM'
    BEGIN
         SET @SqlQuery = 'SELECT ''customer summary'', [dbo].[Customer Master File].[CUSTOMER DISTRICT NUMBER] * 100000 + [dbo].[Customer Master File].[CUSTOMER NUMBER], [dbo].[Customer Master File].[Customer Alpha''Name], [dbo].[Customer Master File].[Credit Limit], [dbo].[Customer Master File].[Inside Salesman District Number] * 100 + [dbo].[Customer Master File].[Inside Salesman Number], [dbo].[Customer Master File].[Salesman One''District Number] * 100 + [dbo].[Customer Master File].[Salesman One Number], [dbo].[Salesman Master File].[Salesman Name] FROM [dbo].[Customer Master File] [dbo].[Customer Master File], [dbo].[Salesman Master File] [dbo].[Salesman Master File] WHERE [dbo].[Customer Master File].[Inside Salesman District Number] = [dbo].[Salesman Master File].[Salesman District Number] AND [dbo].[Customer Master File].[Inside Salesman Number] = [dbo].[Salesman Master File].[Salesman Number] GROUP BY [dbo].[Customer Master File].[CUSTOMER DISTRICT NUMBER] * 100000 + [dbo].[Customer Master File].[CUSTOMER NUMBER], [dbo].[Customer Master File].[Customer Alpha''Name], [dbo].[Customer Master File].[Credit Limit], [dbo].[Customer Master File].[Inside Salesman District Number] * 100 + [dbo].[Customer Master File].[Inside Salesman Number], [dbo].[Customer Master File].[Salesman One''District Number] * 100 + [dbo].[Customer Master File].[Salesman One Number], [dbo].[Salesman Master File].[Salesman Name] ORDER BY [dbo].[Customer Master File].[Customer Alpha''Name]';
    END
    ELSE IF @QueryID = 'CUST_SUM1'
    BEGIN
        SET @SqlQuery = 'SELECT ''Sales analysis Salesman summary'', CAST(CAST([z_Salesman_Master_File_____SALESMAN].[Salesman_District_Number_____SMDIST] AS DECIMAL(18, 2)) AS INT) * 100 + CAST(CAST([z_Salesman_Master_File_____SALESMAN].[Salesman_Number_____SMSMAN] AS DECIMAL(18, 2)) AS INT) AS Salesman_Combined_ID_SALESMAN_SMSMAN, [z_Salesman_Master_File_____SALESMAN].[Salesman_Name_____SMNAME] FROM [mrs].[z_Salesman_Master_File_____SALESMAN] [z_Salesman_Master_File_____SALESMAN] GROUP BY CAST(CAST([z_Salesman_Master_File_____SALESMAN].[Salesman_District_Number_____SMDIST] AS DECIMAL(18, 2)) AS INT) * 100 + CAST(CAST([z_Salesman_Master_File_____SALESMAN].[Salesman_Number_____SMSMAN] AS DECIMAL(18, 2)) AS INT), [z_Salesman_Master_File_____SALESMAN].[Salesman_Name_____SMNAME]';
    END
    ELSE IF @QueryID = 'ITEMONHD'
    BEGIN
        SET @SqlQuery = 'SELECT ''Item On-Hand Query'' AS QueryType, [ITEM_NUMBER_____IOITEM], [Qty_On_Hand_____IOQOH], [Qty_On_Order_____IOQOO], [Average_Cost_____IOACST] FROM [mrs].[z_Item_on_Hand_File_____ITEMONHD]';
    END
    ELSE IF @QueryID = 'SALES_ORDERS'
    BEGIN
        -- Using procedure parameters instead of hardcoded values
        SET @SqlQuery = 'SELECT CAST(CAST([z_Order_Detail_File_____OEDETAIL].[O/E_District_#_____ODDIST] AS DECIMAL(18, 2)) AS INT) * 1000000 + CAST(CAST([z_Order_Detail_File_____OEDETAIL].[Transaction_#_____ODORDR] AS DECIMAL(18, 2)) AS INT) Order_districtPlusTransaction, [z_Salesman_Master_File_____SALESMAN].[Salesman_Name_____SMNAME], [z_Open_Order_File_____OEOPNORD].[Order_Type_____OOTYPE], CAST(CAST([z_Order_Detail_File_____OEDETAIL].[CUSTOMER_DISTRICT_____ODCDIS] AS DECIMAL(18, 2)) AS INT) * 100000 + CAST(CAST([z_Order_Detail_File_____OEDETAIL].[CUSTOMER_NUMBER_____ODCUST] AS DECIMAL(18, 2)) AS INT) Customer_DistrictPlusCustomer, [z_Customer_Master_File_____ARCUST].[Customer_Alpha_Name_____CALPHA], CAST(CAST([z_Open_Order_File_____OEOPNORD].[INVOICE_CENTURY_____OOICC] AS DECIMAL(18, 2)) AS INT) * 1000000 + CAST(CAST([z_Open_Order_File_____OEOPNORD].[INVOICE_YEAR_____OOIYY] AS DECIMAL(18, 2)) AS INT) * 10000 + CAST(CAST([z_Open_Order_File_____OEOPNORD].[INVOICE_MONTH_____OOIMM] AS DECIMAL(18, 2)) AS INT) * 100 + CAST(CAST([z_Open_Order_File_____OEOPNORD].[INVOICE_DAY_____OOIDD] AS DECIMAL(18, 2)) AS INT) as InvoiceDate_OOI, [z_Order_Detail_File_____OEDETAIL].[ITEM_NUMBER_____ODITEM], [z_Order_Detail_File_____OEDETAIL].[SIZE_1_____ODSIZ1], [z_Order_Detail_File_____OEDETAIL].[SIZE_2_____ODSIZ2], [z_Order_Detail_File_____OEDETAIL].[SIZE_3_____ODSIZ3], [z_Order_Detail_File_____OEDETAIL].[CRT_DESCRIPTION_____ODCRTD], [z_Sales_Description_Override_____SLSDSCOV].[Item_Print_Descr_Two_____DXDSC2], [z_Order_Detail_File_____OEDETAIL].[TOTAL_FTS_____ODTFTS], [z_Order_Detail_File_____OEDETAIL].[TOTAL_LBS_____ODTLBS], [z_Order_Detail_File_____OEDETAIL].[TOTAL_PCS_____ODTPCS], [z_Order_Detail_File_____OEDETAIL].[NEGOTIATED_SELL_$_EXT_____ODSLSX], [z_Order_Detail_File_____OEDETAIL].[PRORATED_FREIGHT_SALES_____ODFRTS], [z_Order_Detail_File_____OEDETAIL].[COSTING_METHOD_COST_EXT_____ODCSTX], [z_Order_Detail_File_____OEDETAIL].[TOTAL_PROCESS_COST_____ODPRCC], [z_Order_Detail_File_____OEDETAIL].[TOTAL_ADDTL_CHG_COST_____ODADCC], [z_Order_Detail_File_____OEDETAIL].[PRORATED_WHOLE_ORDER_COST_AMT_____ODWCCS], [z_Customer_Master_File_____ARCUST].[State_____CSTAT], [z_Customer_Master_File_____ARCUST].[Country_____CCTRY] FROM [mrs].[z_Customer_Master_File_____ARCUST] AS [z_Customer_Master_File_____ARCUST], [mrs].[z_Order_Detail_File_____OEDETAIL] AS [z_Order_Detail_File_____OEDETAIL], [mrs].[z_Open_Order_File_____OEOPNORD] AS [z_Open_Order_File_____OEOPNORD], [mrs].[z_Salesman_Master_File_____SALESMAN] AS [z_Salesman_Master_File_____SALESMAN], [mrs].[z_Sales_Description_Override_____SLSDSCOV] AS [z_Sales_Description_Override_____SLSDSCOV] WHERE CAST(CAST([z_Order_Detail_File_____OEDETAIL].[O/E_District_#_____ODDIST] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Open_Order_File_____OEOPNORD].[O/E_Dist#_____OODIST] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Order_Detail_File_____OEDETAIL].[O/E_District_#_____ODDIST] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Sales_Description_Override_____SLSDSCOV].[Tran._District_#_____DXDIST] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Order_Detail_File_____OEDETAIL].[MAIN_LINE_____ODMLIN] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Sales_Description_Override_____SLSDSCOV].[MAIN_LINE_____DXMLIN] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Order_Detail_File_____OEDETAIL].[Transaction_#_____ODORDR] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Open_Order_File_____OEOPNORD].[ORDER_NUMBER_____OOORDR] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Order_Detail_File_____OEDETAIL].[Transaction_#_____ODORDR] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Sales_Description_Override_____SLSDSCOV].[Transaction_#_____DXORDR] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Open_Order_File_____OEOPNORD].[CUSTOMER_DISTRICT_____OOCDIS] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Customer_Master_File_____ARCUST].[CUSTOMER_DISTRICT_NUMBER_____CDIST] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Open_Order_File_____OEOPNORD].[CUSTOMER_NUMBER_____OOCUST] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Customer_Master_File_____ARCUST].[CUSTOMER_NUMBER_____CCUST] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Open_Order_File_____OEOPNORD].[INSIDE_SALESMAN_DISTRICT_____OOISMD] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Salesman_Master_File_____SALESMAN].[Salesman_District_Number_____SMDIST] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Open_Order_File_____OEOPNORD].[INSIDE_SALESMAN_NUMBER_____OOISMN] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Salesman_Master_File_____SALESMAN].[Salesman_Number_____SMSMAN] AS DECIMAL(18, 2)) AS INT) AND (([z_Open_Order_File_____OEOPNORD].[Order_Type_____OOTYPE] IN (''A'',''B'')) AND ([z_Open_Order_File_____OEOPNORD].[Record_Code_____OORECD]=''W'') AND (CAST(CAST([z_Open_Order_File_____OEOPNORD].[INVOICE_CENTURY_____OOICC] AS DECIMAL(18, 2)) AS INT)*10000+CAST(CAST([z_Open_Order_File_____OEOPNORD].[INVOICE_YEAR_____OOIYY] AS DECIMAL(18, 2)) AS INT)*100+CAST(CAST([z_Open_Order_File_____OEOPNORD].[INVOICE_MONTH_____OOIMM] AS DECIMAL(18, 2)) AS INT) BETWEEN @StartDate/100 AND @EndDate/100) )';
    END
    ELSE IF @QueryID = 'SPO'
    BEGIN
        SET @SqlQuery = 'DECLARE @TransactionNumber INT = 951239; SELECT ''Sales analysis, SPO'' as QueryName, CAST(CAST([z_Order_Detail_File_____OEDETAIL].[O/E_District_#_____ODDIST] AS DECIMAL(18, 2)) AS INT) * 1000000 + CAST(CAST([z_Order_Detail_File_____OEDETAIL].[Transaction_#_____ODORDR] AS DECIMAL(18, 2)) AS INT) as Order_districtPlusTransaction, [z_Salesman_Master_File_____SALESMAN].[Salesman_Name_____SMNAME], [z_Open_Order_File_____OEOPNORD].[Order_Type_____OOTYPE], CAST(CAST([z_Order_Detail_File_____OEDETAIL].[CUSTOMER_DISTRICT_____ODCDIS] AS DECIMAL(18, 2)) AS INT) * 100000 + CAST(CAST([z_Order_Detail_File_____OEDETAIL].[CUSTOMER_NUMBER_____ODCUST] AS DECIMAL(18, 2)) AS INT) as Customer_DistrictPlusCustomer, [z_Customer_Master_File_____ARCUST].[Customer_Alpha_Name_____CALPHA], CAST(CAST([z_Open_Order_File_____OEOPNORD].[INVOICE_CENTURY_____OOICC] AS DECIMAL(18, 2)) AS INT) * 1000000 + CAST(CAST([z_Open_Order_File_____OEOPNORD].[INVOICE_YEAR_____OOIYY] AS DECIMAL(18, 2)) AS INT) * 10000 + CAST(CAST([z_Open_Order_File_____OEOPNORD].[INVOICE_MONTH_____OOIMM] AS DECIMAL(18, 2)) AS INT) * 100 + CAST(CAST([z_Open_Order_File_____OEOPNORD].[INVOICE_DAY_____OOIDD] AS DECIMAL(18, 2)) AS INT) as InvoiceDate_OOI, [z_Order_Detail_File_____OEDETAIL].[ITEM_NUMBER_____ODITEM], [z_Service_Purchase_Order_Header_File_____SPHEADER].[Ship_To_Vendor_#_____BSSVEN], [z_Service_Purchase_Order_Header_File_____SPHEADER].[Multiple_SPO_____BSSPS#] FROM [mrs].[z_Customer_Master_File_____ARCUST] AS [z_Customer_Master_File_____ARCUST], [mrs].[z_Order_Detail_File_____OEDETAIL] AS [z_Order_Detail_File_____OEDETAIL], [mrs].[z_Open_Order_File_____OEOPNORD] AS [z_Open_Order_File_____OEOPNORD], [mrs].[z_Salesman_Master_File_____SALESMAN] AS [z_Salesman_Master_File_____SALESMAN], [mrs].[z_Service_Purchase_Order_Header_File_____SPHEADER] AS [z_Service_Purchase_Order_Header_File_____SPHEADER] WHERE CAST(CAST([z_Order_Detail_File_____OEDETAIL].[O/E_District_#_____ODDIST] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Open_Order_File_____OEOPNORD].[O/E_Dist#_____OODIST] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Order_Detail_File_____OEDETAIL].[Transaction_#_____ODORDR] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Open_Order_File_____OEOPNORD].[ORDER_NUMBER_____OOORDR] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Open_Order_File_____OEOPNORD].[CUSTOMER_DISTRICT_____OOCDIS] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Customer_Master_File_____ARCUST].[CUSTOMER_DISTRICT_NUMBER_____CDIST] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Open_Order_File_____OEOPNORD].[CUSTOMER_NUMBER_____OOCUST] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Customer_Master_File_____ARCUST].[CUSTOMER_NUMBER_____CCUST] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Open_Order_File_____OEOPNORD].[INSIDE_SALESMAN_DISTRICT_____OOISMD] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Salesman_Master_File_____SALESMAN].[Salesman_District_Number_____SMDIST] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Open_Order_File_____OEOPNORD].[INSIDE_SALESMAN_NUMBER_____OOISMN] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Salesman_Master_File_____SALESMAN].[Salesman_Number_____SMSMAN] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Order_Detail_File_____OEDETAIL].[O/E_District_#_____ODDIST] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Service_Purchase_Order_Header_File_____SPHEADER].[DISTRICT_NUMBER_____BSDIST] AS DECIMAL(18, 2)) AS INT) AND CAST(CAST([z_Order_Detail_File_____OEDETAIL].[Transaction_#_____ODORDR] AS DECIMAL(18, 2)) AS INT) = CAST(CAST([z_Service_Purchase_Order_Header_File_____SPHEADER].[Transaction_#_____BSORDR] AS DECIMAL(18, 2)) AS INT) AND (([z_Open_Order_File_____OEOPNORD].[Order_Type_____OOTYPE] IN (''A'',''B'')) AND ([z_Open_Order_File_____OEOPNORD].[Record_Code_____OORECD] = ''W'') AND CAST(CAST([z_Order_Detail_File_____OEDETAIL].[O/E_District_#_____ODDIST] AS DECIMAL(18, 2)) AS INT) = 1 AND CAST(CAST([z_Order_Detail_File_____OEDETAIL].[Transaction_#_____ODORDR] AS DECIMAL(18, 2)) AS INT) > @TransactionNumber)';
    END
    ELSE IF @QueryID = 'SHIPMAST'
    BEGIN
        SET @SqlQuery = 'SELECT ''SHIPMAST Query - Pending Implementation'' AS Status, ''Please add implementation'' AS Action';
    END
    ELSE IF @QueryID = 'GLTRANS'
    BEGIN
        SET @SqlQuery = 'SELECT ''GLTRANS Query - Pending Implementation'' AS Status, ''Please add implementation'' AS Action';
    END
    ELSE IF @QueryID = 'SHIPMENTS'
    BEGIN
        SET @SqlQuery = 'SELECT ''SHIPMENTS Query - Pending Implementation'' AS Status, ''Please add implementation'' AS Action';
    END
    ELSE
    BEGIN
        -- Handle unknown query ID
        SET @SqlQuery = 'SELECT ''Unknown query ID: ' + @QueryID + ''' AS ErrorMessage, ''Use query ID "help" to see available queries'' AS Suggestion';
    END


    -- Modify query to limit to 10 rows if @Only10 = 1
    IF @Only10 = 1 AND @QueryID <> 'help'
    BEGIN
        -- Check if the query already contains DISTINCT
        IF CHARINDEX('SELECT DISTINCT', @SqlQuery) > 0
        BEGIN
            -- Replace 'SELECT DISTINCT' with 'SELECT TOP 10 DISTINCT'
            SET @SqlQuery = REPLACE(@SqlQuery, 'SELECT DISTINCT', 'SELECT TOP 10 DISTINCT');
        END
        ELSE IF LEFT(LTRIM(@SqlQuery), 6) = 'SELECT'
        BEGIN
            -- Add TOP 10 after SELECT for queries without DISTINCT
            SET @SqlQuery = STUFF(@SqlQuery, 7, 0, ' TOP 10');
        END
    END    
    -- Debug mode prints query before execution
    IF @DebugMode = 1
    BEGIN
        SELECT 'Executing Query ID: ' + @QueryID;
        SELECT @SqlQuery;
    END;
    
    -- Execute the selected query with parameters
    EXEC sp_executesql @SqlQuery, 
                      N'@MinItem VARCHAR(20), @MaxItem VARCHAR(20), @MinItem2 VARCHAR(20), @MaxItem2 VARCHAR(20), @StartDate INT, @EndDate INT',
                      @MinItem, @MaxItem, @MinItem2, @MaxItem2, @StartDate, @EndDate;
END;

/*
==============================================================================
USAGE EXAMPLES
==============================================================================

Example 1: Get a list of available queries
-----------------------------------------
EXEC [mrs].[mysp_QuerySelector] 
    @QueryID = 'help', 
    @DebugMode = 1;

Expected Result: Returns a list of all available query names like 'ROP_PRICE', 'SALES_DATA', etc.


Example 2: View item pricing information
-----------------------------------------
EXEC [mrs].[mysp_QuerySelector] 
    @QueryID = 'ROP_PRICE';

Expected Result: Returns item numbers and prices from the [z_Item_on_Hand_File_____ITEMONHD] table.


Example 3: Get item usage data for a specific date range
-----------------------------------------
EXEC [mrs].[mysp_QuerySelector] 
    @QueryID = 'USAGE', 
    @StartDate = 20250301, 
    @EndDate = 20250331;

Expected Result: Returns transaction history data for items between MinItem and MaxItem 
where transaction date is after 20250301.


Example 4: Generate a customer summary with debug mode
-----------------------------------------
EXEC [mrs].[mysp_QuerySelector] 
    @QueryID = 'CUST_SUM', 
    @DebugMode = 1;

Expected Result: First outputs the generated SQL query to Messages window,
then returns customer information with salesman data.


Example 5: Review sales orders for specific dates
-----------------------------------------
EXEC [mrs].[mysp_QuerySelector] 
    @QueryID = 'SALES_ORDERS', 
    @StartDate = 20250101, 
    @EndDate = 20250228;

Expected Result: Returns detailed sales order information for orders with invoice dates 
in January and February 2025.

==============================================================================
*/
