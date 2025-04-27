TABLE: GLTRANS
PREFIX: GL
    - PK, FK
        - GLACCT            Account number          1501000000
        - GLBTCH            Batch number            36834
        - GLREF             Reference number        50572
        - GLTRNT            Transaction type        IA
        - GLTRN#            Transaction number      518-407
    - VALUES                                        
        - GLAMT             Amount                  454.11
        - GLAMTQ            Amount queries          -454.11
    
    Count_TotalGLRecords	    31951
    Count_DistinctAccounts	    80
    Count_DistinctBatches	    1635
    Count_DistinctReferences	4222
    Count_DistinctTransTypes	6
    Count_DistinctTransNumbers	2980

----------------------------------------------------------------
TABLE: SHIPMAST
PREFIX: SH
    - PK, FO
        - SHORDN            Shipment order transaction# 804,176
        - SHCORD            Customer PO             #########
    - Date                  
        - SHIPYY            
        - SHIPMM            
        - SHIPDD            
    - Details               
        - SHSHAP            shape                   T,B,
        - SHINSM            Inside Salesman
    - Core                  
        - SHSQTY            Shipped quantity
        - SHUOM                 
        - SHBQTY            Billing qty
        - SHBUOM            Billing qty uom
        - SHOINC           Order quantity inches
        - SHOQTY            Order quantity
        - SHOUOM
        - SHTLBS            Shipped total lbs
        - SHTPCS            Shipped total PCS
        - SHTFTS            Shipped total feet
        - SHTSFT            Shipped total sq ft
        - SHTMTR            Theo meters
        - SHTKG             Theo kilos
        - SHPRCG            Zero Processing Charge
        - SHHAND            Zero Handling Charge
        - SHMSLS	        Material Sales Stock
        - SHMSLD	        Matl Sales Direct
        - SHFSLS	        Frght Sales Stock
        - SHFSLD	        Frght Sales Direct
        - SHPSLS	        Proc Sales Stock
        - SHPSLD	        Process Sales Direct
        - SHOSLS	        Other Sales Stock
        - SHOSLD	        Other  Sales Direct
        - SHDSLS	        Discount Sales Stock
        - SHDSLD        	Discnt Sales Direct
        - SHMCSS	        Material Cost Stock
        - SHMCSD        	Material Cost Direct
        - SHSLSS            Sales Qty Stock
        - SHSLSD        	Sales Qty Direct
        - SHSWGS	        Sales Weight Stock
        - SHSWGD        	Sales Weight Direct
        - SHADPC        	Adjusted GP%
        - SHUNSP        	UNIT PRICE
        - SHUUOM	        Unit Selling Price UOM
        - SHSCDL	        Actual Scrap Dollars
        - SHSCLB	        Actual Scrap LBS
        - SHSCKG	        Actual Scrap KGS 
        - SHTRCK	        Truck Route
        - SHBCTY	        BILL-TO COUNTRY
        - SHSCTY	        S HIP-TO COUNTRY
        - SHDPTI	        In Sales Dept
        - SHDPTO	        Out Sales Dept
        - SHCSTO	        Orig cust#
        - SHADR1	        ADDRESS ONE
        - SHADR2	        ADDRESS TWO
        - SHADR3	        ADDRESS THREE
        - SHCITY	        CITY 25 POS
        - SHSTAT	        State Code
        - SHZIP	            Zip Code

Count_TotalShipmentRecords	1509
Count_DistinctOrders	1509
Count_DistinctCustomers	240
Count_DistinctSalesmen	8
Count_DistinctRoutes	16
Count_DistinctCountries	9
Count_DistinctCities	91
Count_DistinctStates	20
Count_DistinctZipCodes	143


python python/run_sql_generator.py
python python/sql_translator.py
translate_sql_components



----------------------------------------------------------------


----------------------------------------------------------------


        myListSourceColumns     (  'Record_Code_____GLRECD', 'GLRECD', 1)
        myStrSourceTableDesc    'z_General_Ledger_Transaction_File_____GLTRANS'


Transaction types
    CM
    IA
    MP
    OE
    PO

    CM	23757
        592011
    MP	24605
    PO	79083
    OE	1593160
    IA	610907

Order Types   
    A,D,F,IO,Q,X

Shipment Orders
    SHORDN Shipment order number      format: 804176
    Customer purchase order
    shipment flag:                  
        BO  - Backorder
        CM  - Credit memo
        OE  - Order entry
    
    Pricing method
        B - Baseprice
        L - Last price
        N - no price or net price ????

    Cutting flag
         	8586
        A	120640      - Auto
        N	775         - No
        Y	19789       - Yes

    Shape
                1
        B	76388       - Bar
        L	2           - Angle
        O	35          - Oval
        P	418         - Plate
        T	72946       - Tube


--------------------------------------------
SALES REPORT
--------------------------------------------
SELECT 
    [z_Customer_Master_File_____ARCUST].[Customer_Alpha_Name_____CALPHA]
    [z_Customer_Master_File_____ARCUST].[Salesman_One_District_Number_____CSMDI1], 
    [z_Customer_Master_File_____ARCUST].[Salesman_One_Number_____CSLMN1], 
    [z_Customer_Master_File_____ARCUST].[CUSTOMER_NUMBER_____CCUST]
FROM 
    [SigmaTB].mrs.[z_Customer_Master_File_____ARCUST];

SELECT TOP(100) [z_Order_Detail_File_____OEDETAIL].[Order_Type_____ODTYPE],],
[z_Order_Detail_File_____OEDETAIL].[ITEM_NUMBER_____ODITEM],],
[z_Order_Detail_File_____OEDETAIL].[Transaction_#_____ODORDR],],
[z_Order_Detail_File_____OEDETAIL].[TOTAL_LBS_____ODTLBS],],
[z_Order_Detail_File_____OEDETAIL].[TOTAL_FTS_____ODTFTS]] FROM [z_Order_Detail_File_____OEDETAIL]

SELECT TOP(100) [z_Open_Order_File_____OEOPNORD].[Record_Code_____OORECD],],
[z_Open_Order_File_____OEOPNORD].[CUSTOMER_NUMBER_____OOCUST],],
[z_Open_Order_File_____OEOPNORD].[ORDER_NUMBER_____OOORDR],],
[z_Open_Order_File_____OEOPNORD].[ORDER_DATE_CENTURY_____OOOCC],],
[z_Open_Order_File_____OEOPNORD].[ORDER_DATE_YEAR_____OOOYY],],
[z_Open_Order_File_____OEOPNORD].[ORDER_DATE_MONTH_____OOOMM],],
[z_Open_Order_File_____OEOPNORD].[ORDER_DATE_DAY_____OOODD]] FROM [z_Open_Order_File_____OEOPNORD]


TABLE: ARCUST
PREFIX: GL
--ROP_query_
--Sales Data	
SELECT OEOPNORD.OORECD, OEDETAIL.ODTYPE, OEDETAIL.ODITEM, OEDETAIL.ODORDR, OEOPNORD.OOCUST, ARCUST.CALPHA, OEDETAIL.ODTLBS, OEDETAIL.ODTFTS, ooocc*1000000+oooyy*10000+ooomm*100+ooodd, csmdi1*100+cslmn1
FROM ARCUST ARCUST, OEDETAIL OEDETAIL, OEOPNORD OEOPNORD
WHERE OEDETAIL.ODORDR = OEOPNORD.OOORDR AND OEOPNORD.OOCUST = ARCUST.CCUST AND ((OEOPNORD.OORECD='A') AND (OEDETAIL.ODTYPE In ('A','C')))
ORDER BY OEDETAIL.ODITEM




SELECT 
    [OEOPNORD].[OORECD], 
    [OEDETAIL].[ODTYPE], 
    [OEDETAIL].[ODITEM], 
    [OEDETAIL].[ODORDR], 
    [OEOPNORD].[OOCUST], 
    [ARCUST].[CALPHA], 
    [OEDETAIL].[ODTLBS], 
    [OEDETAIL].[ODTFTS], 
    [OEOPNORD].[OOOCC] * 1000000 + [OEOPNORD].[OOOYY] * 10000 + [OEOPNORD].[OOOMM] * 100 + [OEOPNORD].[OOODD], 
    [ARCUST].[CSMDI1] * 100 + [ARCUST].[CSLMN1]
FROM 
    [ARCUST] [ARCUST], 
    [OEDETAIL] [OEDETAIL], 
    [OEOPNORD] [OEOPNORD]
WHERE 
    [OEDETAIL].[ODORDR] = [OEOPNORD].[OOORDR] 
    AND [OEOPNORD].[OOCUST] = [ARCUST].[CCUST] 
    AND (
        [OEOPNORD].[OORECD] = 'A' 
        AND [OEDETAIL].[ODTYPE] IN ('A', 'C')
    )
ORDER BY 
    [OEDETAIL].[ODITEM];
