USE SigmaTB;


SELECT TOP(100) z_Shipments_File_____SHIPMAST.Transaction_#_____SHORDN,
    z_Shipments_File_____SHIPMAST.[Cust_P/O#_____SHCORD],
    z_Shipments_File_____SHIPMAST.[Shipment_Year_____SHIPYY],
    z_Shipments_File_____SHIPMAST.[Shipment_Month_____SHIPMM],
    z_Shipments_File_____SHIPMAST.[Shipment_Day_____SHIPDD],
    z_Shipments_File_____SHIPMAST.[Shape_____SHSHAP],
    z_Shipments_File_____SHIPMAST.[Inside_Salesman_____SHINSM],
    z_Shipments_File_____SHIPMAST.[Shipped_Qty_____SHSQTY],
    z_Shipments_File_____SHIPMAST.SHIPPED_QTY_UOM_____SHUOM,
    z_Shipments_File_____SHIPMAST.[Billing_Qty_____SHBQTY],
    z_Shipments_File_____SHIPMAST.[BILLING_QTY_UOM_____SHBUOM],
    z_Shipments_File_____SHIPMAST.[ORDER_QTY_INCHES_____SHOINC],
    z_Shipments_File_____SHIPMAST.[Order_Qty_____SHOQTY],
    z_Shipments_File_____SHIPMAST.[ORDER_QTY_UOM_____SHOUOM],
    z_Shipments_File_____SHIPMAST.[Shipped_Total_LBS_____SHTLBS],
    z_Shipments_File_____SHIPMAST.[Shipped_Total_PCS_____SHTPCS],
    z_Shipments_File_____SHIPMAST.[Shipped_Total_FTS_____SHTFTS],
    z_Shipments_File_____SHIPMAST.[Shipped_Total_Sq.Ft_____SHTSFT],
    z_Shipments_File_____SHIPMAST.[Theo._Meters_____SHTMTR],
    z_Shipments_File_____SHIPMAST.[Theo_Kilos_____SHTKG],
    z_Shipments_File_____SHIPMAST.[Processing_Charge_____SHPRCG],
    z_Shipments_File_____SHIPMAST.[Handling_Charge_____SHHAND],
    z_Shipments_File_____SHIPMAST.[Material_Sales_Stock_____SHMSLS],
    z_Shipments_File_____SHIPMAST.[Matl_Sales_Direct_____SHMSLD],
    z_Shipments_File_____SHIPMAST.[Frght_Sales_Stock_____SHFSLS],
    z_Shipments_File_____SHIPMAST.[Frght_Sales_Direct_____SHFSLD],
    z_Shipments_File_____SHIPMAST.[Proc_Sales_Stock_____SHPSLS],
    z_Shipments_File_____SHIPMAST.[Process_Sales_Direct_____SHPSLD],
    z_Shipments_File_____SHIPMAST.[Other_Sales_Stock_____SHOSLS],
    z_Shipments_File_____SHIPMAST.[Other__Sales_Direct_____SHOSLD],
    z_Shipments_File_____SHIPMAST.[Discount_Sales_Stock_____SHDSLS],
    z_Shipments_File_____SHIPMAST.[Discnt_Sales_Direct_____SHDSLD],
    z_Shipments_File_____SHIPMAST.[Material_Cost_Stock_____SHMCSS],
    z_Shipments_File_____SHIPMAST.[Material_Cost_Direct_____SHMCSD],
    z_Shipments_File_____SHIPMAST.[Sales_Qty_Stock_____SHSLSS],
    z_Shipments_File_____SHIPMAST.[Sales_Qty_Direct_____SHSLSD],
    z_Shipments_File_____SHIPMAST.[Sales_Weight_Stock_____SHSWGS],
    z_Shipments_File_____SHIPMAST.[Sales_Weight_Direct_____SHSWGD],
    z_Shipments_File_____SHIPMAST.[Adjusted_GP%_____SHADPC],
    z_Shipments_File_____SHIPMAST.[UNIT_PRICE_____SHUNSP],
    z_Shipments_File_____SHIPMAST.[Unit_Selling_Price_UOM_____SHUUOM],
    z_Shipments_File_____SHIPMAST.[Actual_Scrap_Dollars_____SHSCDL],
    z_Shipments_File_____SHIPMAST.[Actual_Scrap_LBS_____SHSCLB],
    z_Shipments_File_____SHIPMAST.[Actual_Scrap_KGS_____SHSCKG],
    z_Shipments_File_____SHIPMAST.[Truck_Route_____SHTRCK],
    z_Shipments_File_____SHIPMAST.[BILL-TO_COUNTRY_____SHBCTY],
    z_Shipments_File_____SHIPMAST.[SHIP-TO_COUNTRY_____SHSCTY],
    z_Shipments_File_____SHIPMAST.[In_Sales_Dept_____SHDPTI],
    z_Shipments_File_____SHIPMAST.[Out_Sales_Dept_____SHDPTO],
    z_Shipments_File_____SHIPMAST.[Orig_cust#_____SHCSTO],
    z_Shipments_File_____SHIPMAST.[ADDRESS_ONE_____SHADR1],
    z_Shipments_File_____SHIPMAST.[ADDRESS_TWO_____SHADR2],
    z_Shipments_File_____SHIPMAST.[ADDRESS_THREE_____SHADR3],
    z_Shipments_File_____SHIPMAST.[CITY_25_POS_____SHCITY],
    z_Shipments_File_____SHIPMAST.[State_Code_____SHSTAT],
    z_Shipments_File_____SHIPMAST.[Zip_Code_____SHZIP] 
FROM 
    mrs.z_Shipments_File_____SHIPMAST
WHERE
    z_Shipments_File_____SHIPMAST.[Shipment_Year_____SHIPYY] = 25
    AND z_Shipments_File_____SHIPMAST.[Shipment_Month_____SHIPMM] = 2;  



-- **************************************************
-- lets build a report with the previous query
-- **************************************************
-- Define the base filtered data for the specific month
--Numbers of shipments
--Different orders
--Different customers
--Different salesmen
--Different routes
--Different countries
--Different cities
--Different states
--Different zip codes

        WITH FilteredShipments AS (
            SELECT
                [Transaction_#_____SHORDN],
                [Orig_cust#_____SHCSTO],
                [Inside_Salesman_____SHINSM],
                [Truck_Route_____SHTRCK],
                [SHIP-TO_COUNTRY_____SHSCTY],
                [CITY_25_POS_____SHCITY],
                [State_Code_____SHSTAT],
                [Zip_Code_____SHZIP]
                -- Only select columns needed for counting distinct values + the base filter
            FROM
                mrs.z_Shipments_File_____SHIPMAST
            WHERE
                [Shipment_Year_____SHIPYY] = 25 -- Base filter condition 1
                AND [Shipment_Month_____SHIPMM] = 2 -- Base filter condition 2
        )
        -- Calculate all the distinct counts from the filtered data
        SELECT
            COUNT(*) AS Count_TotalShipmentRecords,  -- Total rows matching filter
            COUNT(DISTINCT [Transaction_#_____SHORDN]) AS Count_DistinctOrders,
            COUNT(DISTINCT [Orig_cust#_____SHCSTO]) AS Count_DistinctCustomers,
            COUNT(DISTINCT [Inside_Salesman_____SHINSM]) AS Count_DistinctSalesmen,
            COUNT(DISTINCT [Truck_Route_____SHTRCK]) AS Count_DistinctRoutes,
            COUNT(DISTINCT [SHIP-TO_COUNTRY_____SHSCTY]) AS Count_DistinctCountries,
            COUNT(DISTINCT [CITY_25_POS_____SHCITY]) AS Count_DistinctCities,
            COUNT(DISTINCT [State_Code_____SHSTAT]) AS Count_DistinctStates,
            COUNT(DISTINCT [Zip_Code_____SHZIP]) AS Count_DistinctZipCodes
        FROM
            FilteredShipments;


-- **************************************************
-- lets check GLTRANS
-- **************************************************

-------------------------------------------
SELECT TOP(100) 
    [z_General_Ledger_Transaction_File_____GLTRANS].[G/L_Account_Number_____GLACCT],
    [z_General_Ledger_Transaction_File_____GLTRANS].[Batch_Number_____GLBTCH],
    [z_General_Ledger_Transaction_File_____GLTRANS].[Reference_Number_____GLREF],
    [z_General_Ledger_Transaction_File_____GLTRANS].[Transaction_Type_____GLTRNT],
    [z_General_Ledger_Transaction_File_____GLTRANS].[Trans#_____GLTRN#],
    [z_General_Ledger_Transaction_File_____GLTRANS].[Posting_Year_____GLPYY],
    [z_General_Ledger_Transaction_File_____GLTRANS].[Posting_Month_____GLPMM],
    [z_General_Ledger_Transaction_File_____GLTRANS].[G/L_Amount_____GLAMT],
    [z_General_Ledger_Transaction_File_____GLTRANS].[G/L_Amount_-_Queries_____GLAMTQ] 
FROM 
    mrs.[z_General_Ledger_Transaction_File_____GLTRANS]
WHERE
    [z_General_Ledger_Transaction_File_____GLTRANS].[Posting_Year_____GLPYY] = 25
    AND [z_General_Ledger_Transaction_File_____GLTRANS].[Posting_Month_____GLPMM] = 2;


-- **************************************************
-- Now we summarize
-- **************************************************
-- Define the base filtered General Ledger data for the specific posting period
    WITH FilteredGLTrans AS (
        SELECT
            [G/L_Account_Number_____GLACCT],
            [Batch_Number_____GLBTCH],
            [Reference_Number_____GLREF],
            [Transaction_Type_____GLTRNT],
            [Trans#_____GLTRN#]
            -- Select only the columns needed for the distinct counts and the filter
        FROM
            mrs.[z_General_Ledger_Transaction_File_____GLTRANS]
        WHERE
            [Posting_Year_____GLPYY] = 25 -- Filter condition 1
            AND [Posting_Month_____GLPMM] = 2 -- Filter condition 2
    )
    -- Calculate all the distinct counts from the filtered data in one result set
    SELECT
        COUNT(*) AS Count_TotalGLRecords,  -- Optional: Total transaction records matching criteria
        COUNT(DISTINCT [G/L_Account_Number_____GLACCT]) AS Count_DistinctAccounts,
        COUNT(DISTINCT [Batch_Number_____GLBTCH]) AS Count_DistinctBatches,
        COUNT(DISTINCT [Reference_Number_____GLREF]) AS Count_DistinctReferences,
        COUNT(DISTINCT [Transaction_Type_____GLTRNT]) AS Count_DistinctTransTypes,
        COUNT(DISTINCT [Trans#_____GLTRN#]) AS Count_DistinctTransNumbers
    FROM
        FilteredGLTrans;


SELECT top(100)
    [z_Customer_Master_File_____ARCUST].[Customer_Alpha_Name_____CALPHA],
    [z_Customer_Master_File_____ARCUST].[Salesman_One_District_Number_____CSMDI1], 
    [z_Customer_Master_File_____ARCUST].[Salesman_One_Number_____CSLMN1], 
    [z_Customer_Master_File_____ARCUST].[CUSTOMER_NUMBER_____CCUST]
FROM 
    [SigmaTB].mrs.[z_Customer_Master_File_____ARCUST];

    SELECT TOP(100) [z_Order_Detail_File_____OEDETAIL].[Order_Type_____ODTYPE],
[z_Order_Detail_File_____OEDETAIL].[ITEM_NUMBER_____ODITEM],
[z_Order_Detail_File_____OEDETAIL].[Transaction_#_____ODORDR],
[z_Order_Detail_File_____OEDETAIL].[TOTAL_LBS_____ODTLBS],
[z_Order_Detail_File_____OEDETAIL].[TOTAL_FTS_____ODTFTS] FROM mrs.[z_Order_Detail_File_____OEDETAIL]

SELECT TOP(100) [z_Open_Order_File_____OEOPNORD].[Record_Code_____OORECD],
[z_Open_Order_File_____OEOPNORD].[CUSTOMER_NUMBER_____OOCUST],
[z_Open_Order_File_____OEOPNORD].[ORDER_NUMBER_____OOORDR],
[z_Open_Order_File_____OEOPNORD].[ORDER_DATE_CENTURY_____OOOCC],
[z_Open_Order_File_____OEOPNORD].[ORDER_DATE_YEAR_____OOOYY],
[z_Open_Order_File_____OEOPNORD].[ORDER_DATE_MONTH_____OOOMM],
[z_Open_Order_File_____OEOPNORD].[ORDER_DATE_DAY_____OOODD] FROM mrs.[z_Open_Order_File_____OEOPNORD]

select count(*) from  mrs.[z_Order_Detail_File_____OEDETAIL]

/***********************************************
PROBLEMS. WE DONT HAVE DATA
***********************************************/

    SELECT
        s.name AS SchemaName,                   -- Schema Name
        t.name AS TableName,                    -- Table Name
        SUM(ps.row_count) AS ApproximateRowCount -- Sum of rows across partitions for the table
    FROM
        sys.tables AS t                         -- Get table information
    INNER JOIN
        sys.schemas AS s ON t.schema_id = s.schema_id -- Join to get schema names
    INNER JOIN
        sys.dm_db_partition_stats AS ps ON t.object_id = ps.object_id -- Join to get partition stats (including row counts)
    WHERE
        t.type_desc = 'USER_TABLE'              -- Ensure we only get user tables (not system tables etc.)
        AND s.name = 'mrs'                      -- Filter for ONLY the 'mrs' schema
        AND ps.index_id IN (0, 1)               -- Consider only the Heap (0) or Clustered Index (1) rows for the table count
                                                -- Avoids double-counting if non-clustered indexes were included without this filter
    GROUP BY
        s.name,                                 -- Group by schema...
        t.name                                  -- ...and table to get per-table counts
    ORDER BY
        s.name,                                 -- Sort by schema (useful if checking multiple schemas)
        t.name;                                 -- Sort by table name for readability