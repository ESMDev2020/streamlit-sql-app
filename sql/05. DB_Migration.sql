/*************************************************************
COPY SHIPMAST
*************************************************************/

USE SIGMATB;

INSERT INTO SHIPMAST
SELECT *
FROM z_Shipments_File_____SHIPMAST;


---------------------
-- show shipmast columns

use SigmaTB;

SELECT
    TABLE_SCHEMA,
    TABLE_NAME,
    COLUMN_NAME,
    ORDINAL_POSITION,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH, -- Max length for string types
    NUMERIC_PRECISION,        -- Precision for numeric types
    NUMERIC_SCALE             -- Scale for numeric types
FROM
    INFORMATION_SCHEMA.COLUMNS
WHERE
    TABLE_NAME IN ('SHIPMAST', 'z_ShipmentS_File_____SHIPMAST')
ORDER BY
    TABLE_NAME,
    ORDINAL_POSITION;
    
    -----------
    -- COPY SHIPMAST
    -- Optional: Clear the target table first if you want to replace data
-- DELETE FROM [z_ShipmentS_File_____SHIPMAST];
-- TRUNCATE TABLE [z_ShipmentS_File_____SHIPMAST]; -- Or TRUNCATE

BEGIN TRANSACTION; -- Recommended for safety

INSERT INTO [z_ShipmentS_File_____SHIPMAST] (
    [Record Code_____SHRECD], [COMPANY NUMBER_____SHCOMP], [DISTRICT NUMBER_____SHDIST], [Transaction #_____SHORDN], [Cust P/O#_____SHCORD],
    [Order Release No._____SHOREL], [ITEM NUMBER_____SHITEM], [Model Inventory Flag_____SHMDIF], [Top Item Percentage_____SHTOPP], [Shipment Type Flag_____SHTYPE],
    [Pricing method_____SHPFLG], [Cust Owned Flag_____SHCOFL], [Scrap Flag_____SHSCRP], [Cutting/Process Flag_____SHCUTC], [Shipment Century_____SHIPCC],
    [Shipment Year_____SHIPYY], [Shipment Month_____SHIPMM], [Shipment Day_____SHIPDD], [Related part flag_____SHRFLG], [Shape_____SHSHAP],
    [3 POSITION CLASS_____SHCLS3], [Salesman Dist_____SHLDIS], [Inside Salesman_____SHINSM], [Shipped Qty_____SHSQTY], [SHIPPED QTY UOM_____SHUOM],
    [Billing Qty_____SHBQTY], [BILLING QTY UOM_____SHBUOM], [BILLING QTY INCHES_____SHBINC], [Order Qty_____SHOQTY], [ORDER QTY UOM_____SHOUOM],
    [ORDER QTY INCHES_____SHOINC], [Shipped Total LBS_____SHTLBS], [Shipped Total PCS_____SHTPCS], [Shipped Total FTS_____SHTFTS], [Shipped Total Sq.Ft_____SHTSFT],
    [Theo. Meters_____SHTMTR], [Theo Kilos_____SHTKG], [Processing Charge_____SHPRCG], [Handling Charge_____SHHAND], [Customer Dist_____SHCDIS],
    [CUSTOMER NUMBER_____SHCUST], [Salesman Dist_____SHTERR], [Outside Salesman_____SHOUTS], [Line Number_____SHLINE], [Date Ordered Century_____SHORCC],
    [Date Ordered Year_____SHORYY], [Date Ordered Month_____SHORMM], [Date Ordered Day_____SHORDD], [Prom Date Century_____SHPRCC], [Prom Date Year_____SHPRYY],
    [Prom Date Month_____SHPRMM], [Prom Date Day_____SHPRDD], [Date Inv Century_____SHIVCC], [Date Inv Year_____SHIVYY], [Date Inv Month_____SHIVMM],
    [Date Inv Day_____SHIVDD], [Material Sales Stock_____SHMSLS], [Matl Sales Direct_____SHMSLD], [Frght Sales Stock_____SHFSLS], [Frght Sales Direct_____SHFSLD],
    [Proc Sales Stock_____SHPSLS], [Process Sales Direct_____SHPSLD], [Other Sales Stock_____SHOSLS], [Other  Sales Direct_____SHOSLD], [Discount Sales Stock_____SHDSLS],
    [Discnt Sales Direct_____SHDSLD], [Material Cost Stock_____SHMCSS], [Material Cost Direct_____SHMCSD], [Freight-In Cost Stock_____SHFISS], [Freight-In Cost Direct_____SHFISD],
    [Frght-Out Cost Stock_____SHFOSS], [Frght-Out Cost Direct_____SHFOSD], [Fin Scrap Fctr Stock_____SHFSFS], [Fin Scrap Fctr Direct_____SHFSFD], [Processing Cost Stock_____SHPCSS],
    [Processing Cost Direct_____SHPCSD], [Other Cost Stock_____SHOCSS], [Other Cost Direct_____SHOCSD], [Admin Burden Stock_____SHADBS], [Admin Burden Direct_____SHADBD],
    [Oper Burden Stock_____SHOPBS], [Oper Burden Direct_____SHOPBD], [Inv Adj Stock_____SHIAJS], [Inv Adj Direct_____SHIAJD], [Sales Qty Stock_____SHSLSS],
    [Sales Qty Direct_____SHSLSD], [Sales Weight Stock_____SHSWGS], [Sales Weight Direct_____SHSWGD], [Adjusted GP%_____SHADPC], [UNIT PRICE_____SHUNSP],
    [Unit Selling Price UOM_____SHUUOM], [S/A addition flag_____SHSAFL], [Century added to S/A_____SHSACC], [Year added to S/A_____SHSAYY], [Month added to S/A_____SHSAMM],
    [Day added to S/A_____SHSADD], [Freight local+road_____SHFRGH], [Actual Scrap Dollars_____SHSCDL], [Actual Scrap LBS_____SHSCLB], [Actual Scrap KGS_____SHSCKG],
    [Valid Values 1 - PRODUCT NOT STOCKED_____SHDBDC], [Truck Route_____SHTRCK], [Order designation Code_____SHODES], [Shop OLD_____SHSHOP], [CUSTOMER SHIP-TO_____SHSHTO],
    [BILL-TO COUNTRY_____SHBCTY], [SHIP-TO COUNTRY_____SHSCTY], [TEMP SHIP-TO?_____SHTMPS], [Sale Territory_____SHSTER], [Customer Trade_____SHTRAD],
    [Bus. Potential Class_____SHBPCC], [EEC Code_____SHEEC], [Sector Code_____SHSEC], [Invoice Type_____SHITYP], [In Sales Dept_____SHDPTI],
    [Out Sales Dept_____SHDPTO], [Orig cust dist#_____SHDSTO], [Orig cust#_____SHCSTO], [Orig Slsmn Dist_____SHSMDO], [Orig Slsmn_____SHSLMO],
    [Inv Comp_____SHICMP], [ADDRESS ONE_____SHADR1], [ADDRESS TWO_____SHADR2], [ADDRESS THREE_____SHADR3], [CITY 25 POS_____SHCITY],
    [State Code_____SHSTAT], [Zip Code_____SHZIP], [Job Name_____SHJOB]
)
SELECT
    CAST([SHRECD] AS VARCHAR(1)), CAST([SHCOMP] AS NUMERIC(2,0)), CAST([SHDIST] AS NUMERIC(2,0)), CAST([SHORDN] AS NUMERIC(6,0)), CAST([SHCORD] AS VARCHAR(22)),
    CAST([SHOREL] AS VARCHAR(15)), CAST([SHITEM] AS VARCHAR(5)), CAST([SHMDIF] AS VARCHAR(1)), CAST([SHTOPP] AS NUMERIC(3,0)), CAST([SHTYPE] AS VARCHAR(2)),
    CAST([SHPFLG] AS VARCHAR(1)), CAST([SHCOFL] AS VARCHAR(1)), CAST([SHSCRP] AS VARCHAR(1)), CAST([SHCUTC] AS VARCHAR(1)), CAST([SHIPCC] AS NUMERIC(2,0)),
    CAST([SHIPYY] AS NUMERIC(2,0)), CAST([SHIPMM] AS NUMERIC(2,0)), CAST([SHIPDD] AS NUMERIC(2,0)), CAST([SHRFLG] AS VARCHAR(1)), CAST([SHSHAP] AS VARCHAR(1)),
    CAST([SHCLS3] AS VARCHAR(3)), CAST([SHLDIS] AS NUMERIC(2,0)), CAST([SHINSM] AS NUMERIC(2,0)), CAST([SHSQTY] AS DECIMAL(10,3)), CAST([SHUOM] AS VARCHAR(3)),
    CAST([SHBQTY] AS DECIMAL(10,3)), CAST([SHBUOM] AS VARCHAR(3)), CAST([SHBINC] AS NUMERIC(2,0)), CAST([SHOQTY] AS DECIMAL(10,3)), CAST([SHOUOM] AS VARCHAR(3)),
    CAST([SHOINC] AS NUMERIC(2,0)), CAST([SHTLBS] AS DECIMAL(10,3)), CAST([SHTPCS] AS DECIMAL(10,3)), CAST([SHTFTS] AS DECIMAL(10,3)), CAST([SHTSFT] AS DECIMAL(10,3)),
    CAST([SHTMTR] AS DECIMAL(10,3)), CAST([SHTKG] AS DECIMAL(10,3)), CAST([SHPRCG] AS DECIMAL(7,2)), CAST([SHHAND] AS DECIMAL(7,2)), CAST([SHCDIS] AS NUMERIC(2,0)),
    CAST([SHCUST] AS NUMERIC(5,0)), CAST([SHTERR] AS NUMERIC(2,0)), CAST([SHOUTS] AS NUMERIC(2,0)), CAST([SHLINE] AS NUMERIC(4,0)), CAST([SHORCC] AS NUMERIC(2,0)),
    CAST([SHORYY] AS NUMERIC(2,0)), CAST([SHORMM] AS NUMERIC(2,0)), CAST([SHORDD] AS NUMERIC(2,0)), CAST([SHPRCC] AS NUMERIC(2,0)), CAST([SHPRYY] AS NUMERIC(2,0)),
    CAST([SHPRMM] AS NUMERIC(2,0)), CAST([SHPRDD] AS NUMERIC(2,0)), CAST([SHIVCC] AS NUMERIC(2,0)), CAST([SHIVYY] AS NUMERIC(2,0)), CAST([SHIVMM] AS NUMERIC(2,0)),
    CAST([SHIVDD] AS NUMERIC(2,0)), CAST([SHMSLS] AS DECIMAL(13,2)), CAST([SHMSLD] AS DECIMAL(13,2)), CAST([SHFSLS] AS DECIMAL(13,2)), CAST([SHFSLD] AS DECIMAL(13,2)),
    CAST([SHPSLS] AS DECIMAL(13,2)), CAST([SHPSLD] AS DECIMAL(13,2)), CAST([SHOSLS] AS DECIMAL(13,2)), CAST([SHOSLD] AS DECIMAL(13,2)), CAST([SHDSLS] AS DECIMAL(13,2)),
    CAST([SHDSLD] AS DECIMAL(13,2)), CAST([SHMCSS] AS DECIMAL(13,2)), CAST([SHMCSD] AS DECIMAL(13,2)), CAST([SHFISS] AS DECIMAL(13,2)), CAST([SHFISD] AS DECIMAL(13,2)),
    CAST([SHFOSS] AS DECIMAL(13,2)), CAST([SHFOSD] AS DECIMAL(13,2)), CAST([SHFSFS] AS DECIMAL(13,2)), CAST([SHFSFD] AS DECIMAL(13,2)), CAST([SHPCSS] AS DECIMAL(13,2)),
    CAST([SHPCSD] AS DECIMAL(13,2)), CAST([SHOCSS] AS DECIMAL(13,2)), CAST([SHOCSD] AS DECIMAL(13,2)), CAST([SHADBS] AS DECIMAL(13,2)), CAST([SHADBD] AS DECIMAL(13,2)),
    CAST([SHOPBS] AS DECIMAL(13,2)), CAST([SHOPBD] AS DECIMAL(13,2)), CAST([SHIAJS] AS DECIMAL(13,2)), CAST([SHIAJD] AS DECIMAL(13,2)), CAST([SHSLSS] AS DECIMAL(10,3)),
    CAST([SHSLSD] AS DECIMAL(10,3)), CAST([SHSWGS] AS DECIMAL(10,3)), CAST([SHSWGD] AS DECIMAL(10,3)), CAST([SHADPC] AS DECIMAL(5,2)), CAST([SHUNSP] AS DECIMAL(9,4)),
    CAST([SHUUOM] AS VARCHAR(3)), CAST([SHSAFL] AS VARCHAR(1)), CAST([SHSACC] AS NUMERIC(2,0)), CAST([SHSAYY] AS NUMERIC(2,0)), CAST([SHSAMM] AS NUMERIC(2,0)),
    CAST([SHSADD] AS NUMERIC(2,0)), CAST([SHFRGH] AS DECIMAL(13,2)), CAST([SHSCDL] AS DECIMAL(13,2)), CAST([SHSCLB] AS DECIMAL(10,3)), CAST([SHSCKG] AS DECIMAL(10,3)),
    CAST([SHDBDC] AS VARCHAR(1)), CAST([SHTRCK] AS VARCHAR(3)), CAST([SHODES] AS NUMERIC(2,0)), CAST([SHSHOP] AS VARCHAR(5)), CAST([SHSHTO] AS NUMERIC(3,0)),
    CAST([SHBCTY] AS VARCHAR(3)), CAST([SHSCTY] AS VARCHAR(3)), CAST([SHTMPS] AS VARCHAR(1)), CAST([SHSTER] AS VARCHAR(3)), CAST([SHTRAD] AS VARCHAR(3)),
    CAST([SHBPCC] AS VARCHAR(3)), CAST([SHEEC] AS VARCHAR(2)), CAST([SHSEC] AS VARCHAR(3)), CAST([SHITYP] AS VARCHAR(1)), CAST([SHDPTI] AS VARCHAR(15)),
    CAST([SHDPTO] AS VARCHAR(15)),
    -- Using TRY_CAST for TEXT -> NUMERIC/DECIMAL conversions:
    TRY_CAST([SHDSTO] AS NUMERIC(2,0)), TRY_CAST([SHCSTO] AS NUMERIC(5,0)), TRY_CAST([SHSMDO] AS NUMERIC(2,0)), TRY_CAST([SHSLMO] AS DECIMAL(2,0)), TRY_CAST([SHICMP] AS NUMERIC(2,0)),
    -- Continue with TEXT -> VARCHAR conversions:
    CAST([SHADR1] AS VARCHAR(35)), CAST([SHADR2] AS VARCHAR(35)), CAST([SHADR3] AS VARCHAR(35)), CAST([SHCITY] AS VARCHAR(25)),
    CAST([SHSTAT] AS VARCHAR(2)), CAST([SHZIP] AS VARCHAR(12)), CAST([SHJOB] AS VARCHAR(35))
FROM
    SHIPMAST;

COMMIT TRANSACTION; -- Commit if everything looks okay after execution (or use ROLLBACK if errors)



