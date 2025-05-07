CREATE PROCEDURE [mrs].[mysp_QuerySelector]
    @QueryID VARCHAR(20),              -- Identifies which query to run
    @StartDate INT = 20250101,         -- Default start date (note semicolon replaced with comma)
    @EndDate INT = 20250228,           -- Default end date (note semicolon replaced with comma)
    @DebugMode BIT = 0                 -- As per your guidelines
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Declare variables before using them (moved inside BEGIN block)
    DECLARE @MinItem VARCHAR(20) = '50000';    -- PO BDITEM, USAGE IHITEM (fixed syntax)
    DECLARE @MaxItem VARCHAR(20) = '99998';    -- (fixed syntax)  
    DECLARE @MinItem2 VARCHAR(20) = '49999';   -- ROP IMITEM (fixed syntax)
    DECLARE @MaxItem2 VARCHAR(20) = '90000';   -- (fixed syntax)
    DECLARE @SqlQuery NVARCHAR(MAX);
    
    -- Select query based on parameter
    IF @QueryID = 'help' 
    BEGIN           
        SET @SqlQuery = 'SELECT ''Available queries:'' AS QueryTypes, 
                        ''ROP_PRICE'', ''ROP_MP'', ''ROP_PO'', ''ROP_ROP'',
                        ''SALES_DATA'', ''TAG'', ''USAGE'', ''USAGE_SUM'', 
                        ''CM'', ''CUST_SUM'', ''CUST_SUM1'', ''ITEMONHD'',
                        ''SALES_ORDERS'', ''SPO'', ''SHIPMAST'', ''GLTRANS'',
                        ''SHIPMENTS'' AS AvailableQueries';
    END
    ELSE IF @QueryID = 'ROP_PRICE' 
    BEGIN
        SET @SqlQuery = 'SELECT ''price'' AS QueryType, [ITEM_NUMBER_____IOITEM], [Base_Price_____IOBPRC] 
                         FROM [mrs].[z_Item_on_Hand_File_____ITEMONHD]';
    END
    ELSE IF @QueryID = 'ROP_MP'
    BEGIN
        SET @SqlQuery = 'SELECT ''Material processing query'' AS QueryType, 
                         det.[Transaction_#_____MDORDR], 
                         vend.[Vendor_#_____VVNDR], 
                         vend.[Vendor_Alpha_Search_____VALPHA], 
                         det.[=_OPEN__C_=_CLOSED_____MDCLOS], 
                         det.[ITEM_NUMBER_____MDITEM], 
                         det.[CRT_DESCRIPTION_____MDCRTD], 
                         (CAST(CAST(det.[REQUESTED_SHIP_CENTURY_____MDRQCC] AS DECIMAL(5,1)) AS INT)*1000000+
                          CAST(CAST(det.[REQUESTED_SHIP_YEAR_____MDRQYY] AS DECIMAL(5,1)) AS INT)*10000+
                          CAST(CAST(det.[REQUESTED_SHIP_MONTH_____MDRQMM] AS DECIMAL(5,1)) AS INT)*100+
                          CAST(CAST(det.[REQUESTED_SHIP_DAY_____MDRQDD] AS DECIMAL(5,1)) AS INT)) AS CalculatedShipDate, 
                         det.[ON_ORDER_QUANTITY_____MDOQTY], 
                         det.[ORIGINAL_ORDERED_UOM_____MDOUOM], 
                         det.[ORDER_QUANTITY_____MDIQTY] 
                         FROM [mrs].[z_Vendor_Master_File_____APVEND] vend 
                         INNER JOIN [mrs].[z_Material_Processing_Order_Detail_____MPDETAIL] det 
                             ON vend.[COMPANY_NUMBER_____VCOMP] = det.[COMPANY_NUMBER_____MDCOMP] 
                             AND vend.[Vendor_#_____VVNDR] = det.[Vendor_#_____MDVNDR] 
                         ORDER BY det.[ITEM_NUMBER_____MDITEM], det.[Transaction_#_____MDORDR] DESC';
    END
    ELSE IF @QueryID = 'ROP_PO'
    BEGIN
        -- Parameters: Min Max ITEM
        SET @SqlQuery = 'SELECT ''Purchase order query'' AS QueryType, 
                         pod.[Transaction_#_____BDPONO], 
                         pod.[Vendor_#_____BDVNDR], 
                         vend.[Vendor_Name_____VNAME], 
                         pod.[Record_Code_____BDRECD], 
                         pod.[ITEM_NUMBER_____BDITEM], 
                         pod.[CRT_Description_____BDCRTD], 
                         (CAST(CAST(pod.[Revised_Promise_Century_____BDRPCC] AS DECIMAL(5,1)) AS INT)*1000000+
                          CAST(CAST(pod.[Revised_Promise_Year_____BDRPYY] AS DECIMAL(5,1)) AS INT)*10000+
                          CAST(CAST(pod.[Revised_Promise_Month_____BDRPMM] AS DECIMAL(5,1)) AS INT)*100+
                          CAST(CAST(pod.[Revised_Promise_Day_____BDRPDD] AS DECIMAL(5,1)) AS INT)) AS RevisedPromiseDate, 
                         pod.[Original_Inventory_Quantity_____BDOQOO], 
                         pod.[Inventory_UOM_____BDIUOM], 
                         pod.[Current_Inv._Quantity_Ordered_/_Received_____BDCQOO], 
                         pod.[Original_Ordered__Quantity_____BDOOQ], 
                         pod.[Total_Inventory_Quantity_Received_____BDTIQR], 
                         (CAST(CAST(pod.[Purchase_Order_Century_____BDPOCC] AS DECIMAL(5,1)) AS INT)*1000000+
                          CAST(CAST(pod.[Purchase_Order_Year_____BDPOYY] AS DECIMAL(5,1)) AS INT)*10000+
                          CAST(CAST(pod.[Purchase_Order_Month_____BDPOMM] AS DECIMAL(5,1)) AS INT)*100+
                          CAST(CAST(pod.[Purchase_Order_Day_____BDPODD] AS DECIMAL(5,1)) AS INT)) AS PurchaseOrderDate, 
                         (CAST(CAST(pod.[Received_Century_____BDRCCC] AS DECIMAL(5,1)) AS INT)*1000000+
                          CAST(CAST(pod.[Received_Year_____BDRCYY] AS DECIMAL(5,1)) AS INT)*10000+
                          CAST(CAST(pod.[Received_Month_____BDRCMM] AS DECIMAL(5,1)) AS INT)*100+
                          CAST(CAST(pod.[Received_Day_____BDRCDD] AS DECIMAL(5,1)) AS INT)) AS ReceivedDate 
                         FROM [mrs].[z_Purchase_Order_Detail_File_____PODETAIL] pod 
                         LEFT OUTER JOIN [mrs].[z_Vendor_Master_File_____APVEND] vend 
                             ON pod.[Vendor_#_____BDVNDR] = vend.[Vendor_#_____VVNDR] 
                         WHERE (pod.[ITEM_NUMBER_____BDITEM] BETWEEN @MinItem AND @MaxItem) 
                         ORDER BY pod.[ITEM_NUMBER_____BDITEM], pod.[Transaction_#_____BDPONO] DESC';
    END
    ELSE IF @QueryID = 'ROP_ROP'
    BEGIN
        -- Parameters MinItem2, MaxItem2
        SET @SqlQuery = 'SELECT ''ROP Query'' AS QueryType, 
                         im.[Fast_Path_Item_Description_____IMFSP2], 
                         im.[ITEM_NUMBER_____IMITEM], 
                         im.[Size_1_____IMSIZ1], 
                         im.[Size_2_____IMSIZ2], 
                         im.[Size_3_____IMSIZ3], 
                         im.[Item_Print_Descr_Two_____IMDSC2], 
                         im.[Weight_Per_Foot_____IMWPFT], 
                         io.[Average_Cost_____IOACST], 
                         io.[Qty_On_Hand_____IOQOH], 
                         io.[Qty_On_Order_____IOQOO], 
                         io.[Qty_On_Reserved_____IOQOR]+io.[Qty_On_Order_Rsrvd_____IOQOOR], 
                         im.[Item_Print_Descr_One_____IMDSC1], 
                         im.[PSI_=_PER_SQUARE_INCH_PLI_=_PER_LINEAR_INCH_"___"=_____IMWUOM], 
                         im.[Company_SMO_____IMCSMO] 
                         FROM [mrs].[z_Item_Master_File_____ITEMMAST] im
                         INNER JOIN [mrs].[z_Item_on_Hand_File_____ITEMONHD] io 
                             ON io.[ITEM_NUMBER_____IOITEM] = im.[ITEM_NUMBER_____IMITEM] 
                         WHERE (im.[Record_Code_____IMRECD] = ''A'') 
                             AND (im.[ITEM_NUMBER_____IMITEM] BETWEEN @MinItem2 AND @MaxItem2) 
                         ORDER BY im.[Fast_Path_Item_Description_____IMFSP2]';
    END
    -- Continue with the other query cases...
    ELSE IF @QueryID = 'SALES_DATA'
    BEGIN
        SET @SqlQuery = 'SELECT ''ROP - Sales data Query'' AS QueryType, 
                         O.[Record_Code_____OORECD], 
                         D.[Order_Type_____ODTYPE], 
                         D.[ITEM_NUMBER_____ODITEM], 
                         D.[Transaction_#_____ODORDR], 
                         O.[CUSTOMER_NUMBER_____OOCUST], 
                         C.[Customer_Alpha_Name_____CALPHA], 
                         D.[TOTAL_LBS_____ODTLBS], 
                         D.[TOTAL_FTS_____ODTFTS], 
                         CAST(CAST(O.[ORDER_DATE_CENTURY_____OOOCC] AS DECIMAL(5,1)) AS INT)*1000000 + 
                         CAST(CAST(O.[ORDER_DATE_YEAR_____OOOYY] AS DECIMAL(5,1)) AS INT)*10000 + 
                         CAST(CAST(O.[ORDER_DATE_MONTH_____OOOMM] AS DECIMAL(5,1)) AS INT)*100 + 
                         CAST(CAST(O.[ORDER_DATE_DAY_____OOODD] AS DECIMAL(5,1)) AS INT) AS OrderDate, 
                         CAST(CAST(C.[Salesman_One_District_Number_____CSMDI1] AS DECIMAL(5,1)) AS INT)*100 + 
                         CAST(CAST(C.[Salesman_One_Number_____CSLMN1] AS DECIMAL(5,1)) AS INT) AS SalesmanID
                         FROM [mrs].[z_Customer_Master_File_____ARCUST] C 
                         JOIN [mrs].[z_Open_Order_File_____OEOPNORD] O 
                             ON O.[CUSTOMER_NUMBER_____OOCUST] = C.[CUSTOMER_NUMBER_____CCUST] 
                         JOIN [mrs].[z_Order_Detail_File_____OEDETAIL] D 
                             ON D.[Transaction_#_____ODORDR] = O.[ORDER_NUMBER_____OOORDR] 
                         WHERE O.[Record_Code_____OORECD] = ''A'' 
                             AND D.[Order_Type_____ODTYPE] IN (''A'', ''C'') 
                         ORDER BY D.[ITEM_NUMBER_____ODITEM]';
    END
    -- Include additional query cases here...
    ELSE
    BEGIN
        -- Handle unknown query ID
        SET @SqlQuery = 'SELECT ''Unknown query ID: ' + @QueryID + ''' AS ErrorMessage, 
                        ''Use query ID "help" to see available queries'' AS Suggestion';
    END
    
    -- Debug mode prints query before execution
    IF @DebugMode = 1
    BEGIN
        PRINT 'Executing Query ID: ' + @QueryID;
        PRINT @SqlQuery;
    END;
    
    -- Execute the selected query with parameters
    EXEC sp_executesql @SqlQuery, 
                      N'@MinItem VARCHAR(20), @MaxItem VARCHAR(20), @MinItem2 VARCHAR(20), @MaxItem2 VARCHAR(20), @StartDate INT, @EndDate INT',
                      @MinItem, @MaxItem, @MinItem2, @MaxItem2, @StartDate, @EndDate;
END;




/*
USE Sigmatb;
GO

Declare @Only10 BIT =0; Declare @DebugMode BIT;    
DECLARE @StartDate INT = 20250201; DECLARE @EndDate INT = 20250228;	--Feb

--EXEC [mrs].[mysp_QuerySelector] 'help'
-- EXEC [mrs].[mysp_QuerySelector] 'ROP_PRICE'					, @Only10 = 1				-- ITEM, Price
-- EXEC [mrs].[mysp_QuerySelector] 'ROP_MP'						, @Only10 = 1				-- start with 4. ie. 401785 - Transaction4, vendor, ITEM, qty
-- EXEC [mrs].[mysp_QuerySelector] 'ROP_PO'						, @Only10 = 1				-- Start with 5. ie. 518046. Transaction. vendor, ITEM, QTY, dates
-- EXEC [mrs].[mysp_QuerySelector] 'ROP_ROP'					, @Only10 = 1				-- ITEM, quantity
-- EXEC [mrs].[mysp_QuerySelector] 'SALES_DATA'					, @Only10 = 1				-- Starts with 9. Transaction ODORDR 970660. Transaction, item, customer
-- EXEC [mrs].[mysp_QuerySelector] 'SALES_DATA_orbytrans'		, @Only10 = 1				-- Starts with 9. Transaction ODORDR 970660. Transaction, item, customer
-- EXEC [mrs].[mysp_QuerySelector] 'SALES_ORDERS_orbytrans'		, @Only10 = 1, @DebugMode=0	-- Order + Salesman + Type?? + Customer + Invoice + ITEM + Price + Freight0 + cost - no shipping info = GOOD
-- EXEC [mrs].[mysp_QuerySelector] 'SALES_ORDERS'				, @Only10 = 1, @DebugMode=1	-- Order + Salesman + Type?? + Customer + Invoice + ITEM + Price + Freight0 + cost - no shipping info = GOOD
-- EXEC [mrs].[mysp_QuerySelector] 'TAG'			, @Only10 = 1, @DebugMode=0			-- pending	-- ITEM, TAG, Heat, Mill, Warehouse, Tag, Qty. Ordered by ITEM, HEAT, MILL, Numeric Lenght
-- EXEC [mrs].[mysp_QuerySelector] 'USAGE'			, @Only10 = 1, @DebugMode=0			-- ITEM, Transaction type, number, vendor, customer, date. ORDER BY ITEM, Date
-- EXEC [mrs].[mysp_QuerySelector] 'USAGE_SUM'		, @Only10 = 1, @DebugMode=1		-- ITEM, transaction type, customer. ORDER BY ITEM, Customer
-- EXEC [mrs].[mysp_QuerySelector] 'CM'			, @Only10 = 1, @DebugMode=1		-- Order, type, customer, ITEM, --Params: start and ending date - I added order by transaction
EXEC [mrs].[mysp_QuerySelector] 'CUST_SUM'		, @Only10 = 1, @DebugMode=1		-- Cust + Salesman

--EXEC [mrs].[mysp_QuerySelector] 'CUST_SUM1'		, @Only10 = 1, @DebugMode=1		-- Salesman

EXEC [mrs].[mysp_QuerySelector] 'ITEMONHD'		, @Only10 = 1, @DebugMode=0		-- ITEM, Qty on Hand, Qty on Order, Avg Cost
EXEC [mrs].[mysp_QuerySelector] 'SPO'			, @Only10 = 1, @DebugMode=0		-- Order + type + Customer + Item + Inv date + ship to + Multiple SPO		=GOOD GOOD
EXEC [mrs].[mysp_QuerySelector] 'SHIPMAST'		, @Only10 = 1, @DebugMode=0		-- Pending
EXEC [mrs].[mysp_QuerySelector] 'GLTRANS'		, @Only10 = 1, @DebugMode=0		-- Pending
EXEC [mrs].[mysp_QuerySelector] 'SHIPMENTS'		, @Only10 = 1, @DebugMode=0		-- Pending
*/
