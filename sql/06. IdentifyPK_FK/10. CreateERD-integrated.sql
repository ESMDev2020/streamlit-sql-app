USE [SigmaTB]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Create schema if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'mrs')
BEGIN
    EXEC('CREATE SCHEMA [mrs]')
END
GO

-- Drop tables if they exist (in reverse dependency order)
IF OBJECT_ID('mrs.z_Order_Detail_File_____OEDETAIL', 'U') IS NOT NULL DROP TABLE [mrs].[z_Order_Detail_File_____OEDETAIL];
IF OBJECT_ID('mrs.z_Open_Order_File_____OEOPNORD', 'U') IS NOT NULL DROP TABLE [mrs].[z_Open_Order_File_____OEOPNORD];
IF OBJECT_ID('mrs.z_Purchase_Order_Detail_File_____PODETAIL', 'U') IS NOT NULL DROP TABLE [mrs].[z_Purchase_Order_Detail_File_____PODETAIL];
IF OBJECT_ID('mrs.z_Salesman_Master_File_____SALESMAN', 'U') IS NOT NULL DROP TABLE [mrs].[z_Salesman_Master_File_____SALESMAN];
IF OBJECT_ID('mrs.z_Shipments_File_____SHIPMAST', 'U') IS NOT NULL DROP TABLE [mrs].[z_Shipments_File_____SHIPMAST];
IF OBJECT_ID('mrs.z_Sales_Description_Override_____SLSDSCOV', 'U') IS NOT NULL DROP TABLE [mrs].[z_Sales_Description_Override_____SLSDSCOV];
IF OBJECT_ID('mrs.z_Service_Purchase_Order_Header_File_____SPHEADER', 'U') IS NOT NULL DROP TABLE [mrs].[z_Service_Purchase_Order_Header_File_____SPHEADER];
IF OBJECT_ID('mrs.z_Customer_Master_File_____ARCUST', 'U') IS NOT NULL DROP TABLE [mrs].[z_Customer_Master_File_____ARCUST];
IF OBJECT_ID('mrs.z_Item_Transaction_History_____ITEMHIST', 'U') IS NOT NULL DROP TABLE [mrs].[z_Item_Transaction_History_____ITEMHIST];
GO

-- Create tables with primary keys and foreign key constraints
CREATE TABLE [mrs].[z_Customer_Master_File_____ARCUST] (
    [CUSTOMER_NUMBER_____CCUST] numeric(5,0) NOT NULL,
    [Customer_Name_____CCUSTN] varchar(35) NOT NULL,
    [ORIG_CUST#_____CCUSTO] numeric(5,0) NOT NULL,
    [Federal_Tax_I.D._____CFEDID] varchar(25) NULL,
    [Customer_Alpha_Name_____CALPHA] varchar(35) NOT NULL,
    [Country_____CCTRY] varchar(3) NOT NULL,
    [ZIP_CODE_12_POS_____CZIP] varchar(12) NOT NULL,
    [City_____CCITY] varchar(25) NOT NULL,
    [State_____CSTAT] varchar(2) NOT NULL,
    [Address_1_____CADDR1] varchar(35) NOT NULL,
    [Address_2_____CADDR2] varchar(35) NOT NULL,
    [Address_3_____CADDR3] varchar(35) NOT NULL,
    [Customer_Phone_Number_____CPHON] varchar(18) NOT NULL,
    [E-MAIL_ADDRESS_____CEMAL] varchar(50) NOT NULL,
    [Fax_Phone_Number_____CFPHON] varchar(18) NOT NULL,
    [WEB_SITE_ADDRESS_____CWEBS] varchar(50) NOT NULL,
    [Orig_Slsmn_One#_____CSLM1O] decimal(2,0) NOT NULL,
    [Salesman_One_Number_____CSLMN1] decimal(2,0) NOT NULL,
    [Multi_Bill_____CFLAG9] varchar(1) NOT NULL,
    [Risk_Flag_Y_N_H_____CRSYNH] varchar(1) NOT NULL,
    [Special_Invoice_Handling_Y_or_N_____CSPCYN] varchar(1) NOT NULL,
    [Subject_to_Purge_____CPURG] varchar(1) NOT NULL,
    [A=ACTIVE__I=INACTIVE_D=DELETED_____CRECD] varchar(1) NOT NULL,
    [Auto_Inv_Upd_____CFLAG1] varchar(1) NOT NULL,
    [BOL_Dft_Print_Heat_____CFLG14] varchar(1) NOT NULL,
    [BOL_Dft_Print_M/C_____CFLG15] varchar(1) NOT NULL,
    [Dflt_email_____CFLG10] varchar(1) NOT NULL,
    [Prv_Cust_#_X-ref_____CXREF] varchar(15) NOT NULL,
    [Customer_Parent_Code_____CCPCOD] varchar(4) NULL,
    [EDI_AGENCY_CODE_____CEDIAG] varchar(2) NULL,
    [FEDERAL_TAX_CODE_____CFDCD] varchar(3) NULL,
    [City_Code_____CCTCD] varchar(3) NULL,
    [City_Tax_Code_____CCITTX] varchar(5) NULL,
    [County_Code_____CCNTY] varchar(2) NULL,
    [County_Tax_Code_____CCNTTX] varchar(3) NULL,
    [Customer_Addition_Code_____CCADDC] varchar(1) NULL,
    [Customer_Pricing_Code_____CPRCOD] varchar(2) NULL,
    [Delivery_Date_Code_____CDDCD] varchar(1) NOT NULL,
    CONSTRAINT [PK_z_Customer_Master_File] PRIMARY KEY ([CUSTOMER_NUMBER_____CCUST])
);
GO

CREATE TABLE [mrs].[z_Item_Transaction_History_____ITEMHIST] (
    [Transaction_#_____IHTRN#] nvarchar(MAX) NOT NULL,
    [Document_#_____IHDOC#] nvarchar(MAX) NOT NULL,
    [PO_Rcpt_List#_____IHLIST] nvarchar(MAX) NOT NULL,
    [ITEM_NUMBER_____IHITEM] nvarchar(MAX) NOT NULL,
    [Transaction_Type_____IHTRNT] nvarchar(MAX) NOT NULL,
    [Trans_Subtype_____IHSTYP] nvarchar(MAX) NOT NULL,
    [Transport_ID_____IHTID] nvarchar(MAX) NOT NULL,
    [Debit_Memo#_____IHDMEM] nvarchar(MAX) NOT NULL,
    [Vendor_#_____IHVNDR] nvarchar(MAX) NOT NULL,
    [Assoc_PO_Number_____IHPONM] nvarchar(MAX) NOT NULL,
    [Trans_Length_____IHLNTH] nvarchar(MAX) NOT NULL,
    [CUSTOMER_NUMBER_____IHCUST] nvarchar(MAX) NOT NULL,
    [TAG_NUMBER_ALPHA_____IHTAG] nvarchar(MAX) NOT NULL,
    [Heat_#_____IHHEAT] nvarchar(MAX) NOT NULL,
    [Extended_Trans_Price_____IHEPRC] nvarchar(MAX) NOT NULL,
    [PROCESSED_YEAR_____IHPRPY] nvarchar(MAX) NOT NULL,
    [Trans_YY_____IHTRYY] nvarchar(MAX) NOT NULL,
    [Trans_MM_____IHTRMM] nvarchar(MAX) NOT NULL,
    [Trans_Width_____IHWDTH] nvarchar(MAX) NOT NULL,
    [Extended_Trans_Cost_____IHECST] nvarchar(MAX) NOT NULL,
    [Qty_On_Hand_____IHQOH] nvarchar(MAX) NOT NULL,
    [Average_Cost_____IHACST] nvarchar(MAX) NOT NULL,
    [Trans_Cost_____IHTCST] nvarchar(MAX) NOT NULL,
    [Trans_Price_____IHTPRC] nvarchar(MAX) NOT NULL,
    [Trans_Inv_Qty_____IHTQTY] nvarchar(MAX) NOT NULL,
    [Assoc_PO_Line_____IHPOLN] nvarchar(MAX) NOT NULL,
    [Workstation_ID_____IHWSID] nvarchar(MAX) NOT NULL,
    [PROCESSED_PERIOD_____IHPRPP] nvarchar(MAX) NOT NULL,
    [G/L_FISCAL_PERIOD_____IHGLPP] nvarchar(MAX) NOT NULL,
    [L/M_MONTH_____IHLMMM] nvarchar(MAX) NOT NULL,
    [G/L_FISCAL_YEAR_____IHGLPY] nvarchar(MAX) NOT NULL,
    [L/M_YEAR_____IHLMYY] nvarchar(MAX) NOT NULL,
    [Remote_Inv_Vendor_____IHRIV] nvarchar(MAX) NOT NULL,
    [Trans_Price_UOM_____IHPUOM] nvarchar(MAX) NOT NULL,
    [Processed_by_M/E_____IHPRCD] nvarchar(MAX) NOT NULL,
    [Port_of_Entry_____IHPOE] nvarchar(MAX) NOT NULL,
    [Trans_Cost_UOM_____IHTUOM] nvarchar(MAX) NOT NULL,
    [Assoc_PO_Dist_____IHPODS] nvarchar(MAX) NOT NULL,
    CONSTRAINT [PK_z_Item_Transaction_History] PRIMARY KEY ([Transaction_#_____IHTRN#], [Document_#_____IHDOC#], [ITEM_NUMBER_____IHITEM]),
    CONSTRAINT [FK_ITEMHIST_CUSTOMER] FOREIGN KEY ([CUSTOMER_NUMBER_____IHCUST]) 
    REFERENCES [mrs].[z_Customer_Master_File_____ARCUST] ([CUSTOMER_NUMBER_____CCUST])
);
GO

CREATE TABLE [mrs].[z_Service_Purchase_Order_Header_File_____SPHEADER] (
    [Transaction_#_____BSORDR] nvarchar(MAX) NOT NULL,
    [Move_Order_weight_override_____BSMOWO] nvarchar(MAX) NULL,
    [SPO_DESCRIPTION_____BSDESC] nvarchar(MAX) NULL,
    [SPO_DESCRIPTION_2_____BSDES2] nvarchar(MAX) NULL,
    [TRANSACTION_TYPE_____BSTRNT] nvarchar(MAX) NOT NULL,
    [CUSTOMER_NUMBER_____BSCUS#] nvarchar(MAX) NOT NULL,
    [CALCULATING_LENGTH_____BSLENG] nvarchar(MAX) NULL,
    [Density_Factor_____BSDENF] nvarchar(MAX) NULL,
    [Inner_Diameter_____BSIND] nvarchar(MAX) NULL,
    [Mail-To_Seq_Number_____BSMAIL] nvarchar(MAX) NULL,
    [ORDER_QUANTITY_____BSIQTY] nvarchar(MAX) NULL,
    [Outside_Diameter_____BSOUTD] nvarchar(MAX) NULL,
    [Salesman_____BSSMN#] nvarchar(MAX) NULL,
    [Ship_To_Vendor_#_____BSSVEN] nvarchar(MAX) NULL,
    [Vendor_#_____BSVNDR] nvarchar(MAX) NULL,
    [Vendor_Ship-to_Seq#_____BSSHIP] nvarchar(MAX) NULL,
    [Wall_____BSWALL] nvarchar(MAX) NULL,
    [Weight_Factor_____BSWGTF] nvarchar(MAX) NULL,
    [Confirmation_Century_____BSCOCC] nvarchar(MAX) NULL,
    [Confirmation_Day_____BSCODD] nvarchar(MAX) NULL,
    [Confirmation_Month_____BSCOMM] nvarchar(MAX) NULL,
    [Confirmation_Year_____BSCOYY] nvarchar(MAX) NULL,
    [Due_Century_____BSDUCC] nvarchar(MAX) NULL,
    [Due_Day_____BSDUDD] nvarchar(MAX) NULL,
    [Due_Month_____BSDUMM] nvarchar(MAX) NULL,
    [Due_Year_____BSDUYY] nvarchar(MAX) NULL,
    [P/O_Century_____BSPOCC] nvarchar(MAX) NULL,
    [P/O_Day_____BSPODD] nvarchar(MAX) NULL,
    [P/O_Month_____BSPOMM] nvarchar(MAX) NULL,
    [P/O_Year_____BSPOYY] nvarchar(MAX) NULL,
    [Ship_Date_Century_____BSSHCC] nvarchar(MAX) NULL,
    [Ship_Date_Day_____BSSHDD] nvarchar(MAX) NULL,
    [Ship_Date_Month_____BSSHMM] nvarchar(MAX) NULL,
    [Ship_Date_Year_____BSSHYY] nvarchar(MAX) NULL,
    [Record_Code_____BSRECD] nvarchar(MAX) NOT NULL,
    [Terms_Code_____BSTERM] nvarchar(MAX) NULL,
    [Tracking_Code_____BSTRAK] nvarchar(MAX) NULL,
    [CALCULATING_WIDTH_____BSWDTH] nvarchar(MAX) NULL,
    CONSTRAINT [PK_z_Service_Purchase_Order_Header_File] PRIMARY KEY ([Transaction_#_____BSORDR]),
    CONSTRAINT [FK_SPHEADER_CUSTOMER] FOREIGN KEY ([CUSTOMER_NUMBER_____BSCUS#]) 
    REFERENCES [mrs].[z_Customer_Master_File_____ARCUST] ([CUSTOMER_NUMBER_____CCUST])
);
GO

CREATE TABLE [mrs].[z_Sales_Description_Override_____SLSDSCOV] (
    [Transaction_#_____DXORDR] nvarchar(MAX) NOT NULL,
    [Item_Print_Descr_Two_____DXDSC2] nvarchar(MAX) NULL,
    [Item_Print_Desc_Three_____DXDSC3] nvarchar(MAX) NULL,
    [Item_Print_Descr_Four_____DXDSC4] nvarchar(MAX) NULL,
    [Item_Print_Descr_Five_____DXDSC5] nvarchar(MAX) NULL,
    [Item_Print_Descr_Six_____DXDSC6] nvarchar(MAX) NULL,
    [Order_Type_____DXTRNT] nvarchar(MAX) NOT NULL,
    [Order_Type_____DXTYPE] nvarchar(MAX) NOT NULL,
    [L/M_Century_____DXLMCC] nvarchar(MAX) NOT NULL,
    [L/M_Day_____DXLMDD] nvarchar(MAX) NOT NULL,
    [L/M_Month_____DXLMMM] nvarchar(MAX) NOT NULL,
    [L/M_Year_____DXLMYY] nvarchar(MAX) NOT NULL,
    [Record_Code_____DXRECD] nvarchar(MAX) NOT NULL,
    [MAIN_LINE_____DXMLIN] nvarchar(MAX) NOT NULL,
    [L/M_User_____DXLMUS] nvarchar(MAX) NULL,
    [Tran._District_#_____DXDIST] nvarchar(MAX) NOT NULL,
    CONSTRAINT [PK_z_Sales_Description_Override] PRIMARY KEY ([Transaction_#_____DXORDR])
);
GO

CREATE TABLE [mrs].[z_Shipments_File_____SHIPMAST] (
    [Transaction_#_____SHORDN] nvarchar(MAX) NOT NULL,
    [Cust_P/O#_____SHCORD] nvarchar(MAX) NULL,
    [CUSTOMER_NUMBER_____SHCUST] nvarchar(MAX) NOT NULL,
    [Billing_Qty_____SHBQTY] nvarchar(MAX) NULL,
    [ORDER_QTY_UOM_____SHOUOM] nvarchar(MAX) NULL,
    [ITEM_NUMBER_____SHITEM] nvarchar(MAX) NOT NULL,
    [CUSTOMER_SHIP-TO_____SHSHTO] nvarchar(MAX) NULL,
    [Discount_Sales_Stock_____SHDSLS] nvarchar(MAX) NULL,
    [Material_Cost_Direct_____SHMCSD] nvarchar(MAX) NULL,
    [Material_Cost_Stock_____SHMCSS] nvarchar(MAX) NULL,
    [Material_Sales_Stock_____SHMSLS] nvarchar(MAX) NULL,
    [Matl_Sales_Direct_____SHMSLD] nvarchar(MAX) NULL,
    [Order_Qty_____SHOQTY] nvarchar(MAX) NULL,
    [Shipment_Type_Flag_____SHTYPE] nvarchar(MAX) NOT NULL,
    [BILL-TO_COUNTRY_____SHBCTY] nvarchar(MAX) NOT NULL,
    [BILLING_QTY_UOM_____SHBUOM] nvarchar(MAX) NULL,
    [State_Code_____SHSTAT] nvarchar(MAX) NULL,
    [Zip_Code_____SHZIP] nvarchar(MAX) NULL,
    [ADDRESS_ONE_____SHADR1] nvarchar(MAX) NULL,
    [ADDRESS_THREE_____SHADR3] nvarchar(MAX) NULL,
    [ADDRESS_TWO_____SHADR2] nvarchar(MAX) NULL,
    [Actual_Scrap_Dollars_____SHSCDL] nvarchar(MAX) NULL,
    [Actual_Scrap_KGS_____SHSCKG] nvarchar(MAX) NULL,
    [Actual_Scrap_LBS_____SHSCLB] nvarchar(MAX) NULL,
    [Adjusted_GP%_____SHADPC] nvarchar(MAX) NULL,
    [CITY_25_POS_____SHCITY] nvarchar(MAX) NULL,
    [Discnt_Sales_Direct_____SHDSLD] nvarchar(MAX) NULL,
    [Freight_local+road_____SHFRGH] nvarchar(MAX) NULL,
    [Frght_Sales_Stock_____SHFSLS] nvarchar(MAX) NULL,
    [Frght-Out_Cost_Stock_____SHFOSS] nvarchar(MAX) NULL,
    [In_Sales_Dept_____SHDPTI] nvarchar(MAX) NULL,
    [Inside_Salesman_____SHINSM] nvarchar(MAX) NULL,
    [Orig_cust#_____SHCSTO] nvarchar(MAX) NULL,
    [Proc_Sales_Stock_____SHPSLS] nvarchar(MAX) NULL,
    [Process_Sales_Direct_____SHPSLD] nvarchar(MAX) NULL,
    [Processing_Cost_Direct_____SHPCSD] nvarchar(MAX) NULL,
    [Processing_Cost_Stock_____SHPCSS] nvarchar(MAX) NULL,
    [Sales_Qty_Direct_____SHSLSD] nvarchar(MAX) NULL,
    CONSTRAINT [PK_z_Shipments_File] PRIMARY KEY ([Transaction_#_____SHORDN]),
    CONSTRAINT [FK_SHIPMAST_CUSTOMER] FOREIGN KEY ([CUSTOMER_NUMBER_____SHCUST]) 
    REFERENCES [mrs].[z_Customer_Master_File_____ARCUST] ([CUSTOMER_NUMBER_____CCUST])
);
GO

CREATE TABLE [mrs].[z_Salesman_Master_File_____SALESMAN] (
    [Salesman_Number_____SMSMAN] nvarchar(MAX) NOT NULL,
    [Salesman_Name_____SMNAME] nvarchar(MAX) NULL,
    [Employee#_____SMEMPL] nvarchar(MAX) NULL,
    [Record_Code_____SMRECD] nvarchar(MAX) NOT NULL,
    [L/M_USER_____SMLMUS] nvarchar(MAX) NULL,
    [E-MAIL_ADDRESS_____SMEMAL] nvarchar(MAX) NULL,
    [Sales_Dept_____SMDEPT] nvarchar(MAX) NULL,
    [L/M_CENTURY_____SMLMCC] nvarchar(MAX) NOT NULL,
    [L/M_DAY_____SMLMDD] nvarchar(MAX) NOT NULL,
    [L/M_MONTH_____SMLMMM] nvarchar(MAX) NOT NULL,
    [L/M_YEAR_____SMLMYY] nvarchar(MAX) NOT NULL,
    [Commission_-_Lot_Amount_____SMLOTA] nvarchar(MAX) NOT NULL,
    [Commission_-_Percent_Of_Gross_Material_Margin_____SMGMPC] nvarchar(MAX) NOT NULL,
    [Commission_-_Percent_Of_Gross_Profit_____SMGPPC] nvarchar(MAX) NOT NULL,
    [Commission_-_Percent_Of_Sales_____SMSLPC] nvarchar(MAX) NOT NULL,
    [Commission_-_Rate_Per_Ton_____SMCRAT] nvarchar(MAX) NOT NULL,
    [Price_Hold_Dollar_Value_____SMPHDV] nvarchar(MAX) NOT NULL,
    [Price_Hold_Variance_____SMPVAR] nvarchar(MAX) NOT NULL,
    [PRIMARY_ROUTE#_____SMROUT] nvarchar(MAX) NOT NULL,
    [Salesman_District_Number_____SMDIST] nvarchar(MAX) NOT NULL,
    [Salesman_Profit_____SMPROF] nvarchar(MAX) NOT NULL,
    [Vendor_Number_____SMVNDR] nvarchar(MAX) NOT NULL,
    [I=INSIDE_O=OUTSIDE_R=REP_M=MGR_____SMTYPE] nvarchar(MAX) NOT NULL,
    [Issue_Warning_If_Gross_Profit_%_Over_____SMIWGO] nvarchar(MAX) NOT NULL,
    [Issue_Warning_If_Gross_Profit_%_Under_____SMIWGU] nvarchar(MAX) NOT NULL,
    [RESTRICTED_ACCESS_____SMRAYN] nvarchar(MAX) NOT NULL,
    [PRIMARY_STOP_SEQ_____SMSTOP] nvarchar(MAX) NULL,
    CONSTRAINT [PK_z_Salesman_Master_File] PRIMARY KEY ([Salesman_Number_____SMSMAN])
);
GO

CREATE TABLE [mrs].[z_Purchase_Order_Detail_File_____PODETAIL] (
    [Transaction_#_____BDPONO] nvarchar(MAX) NOT NULL,
    [ITEM_NUMBER_____BDITEM] nvarchar(MAX) NOT NULL,
    [Material_Cost_____BDMCST] nvarchar(MAX) NULL,
    [Company_SMO_____BDCSMO] nvarchar(MAX) NULL,
    [Linked_Order_Number_____BDLOR#] nvarchar(MAX) NULL,
    [CUSTOMER_NUMBER_____BDCUST] nvarchar(MAX) NOT NULL,
    [Vendor_#_____BDVNDR] nvarchar(MAX) NOT NULL,
    [CRT_Description_____BDCRTD] nvarchar(MAX) NULL,
    [Original_Inventory_Quantity_____BDOQOO] nvarchar(MAX) NULL,
    [Original_Ordered__Quantity_____BDOOQ] nvarchar(MAX) NULL,
    [Reserved_Quantity_____BDRESV] nvarchar(MAX) NULL,
    [Current_Quantity_Ordered_/_Received_____BDCQTY] nvarchar(MAX) NULL,
    [Extended_Material_Cost_____BDEMCS] nvarchar(MAX) NULL,
    [Theo._Feet_Ordered_/_Received_____BDTFT] nvarchar(MAX) NULL,
    [Theo._Meters_Ordered_/_Received_____BDTMTR] nvarchar(MAX) NULL,
    [Theo._Pieces_Ordered_/_Received_____BDTPC] nvarchar(MAX) NULL,
    [Theo._Pounds_Ordered_/_Received_____BDTLB] nvarchar(MAX) NULL,
    [Theo_Kilos_Ordered_/_Received_____BDTKG] nvarchar(MAX) NULL,
    [Total_Inventory_Quantity_Received_____BDTIQR] nvarchar(MAX) NULL,
    [B=Buyout_D=Mill_Direct_____BDLTYP] nvarchar(MAX) NULL,
    [Country_____BDCTRY] nvarchar(MAX) NULL,
    [Current_Quantity_UOM_Ordered_/_Received_____BDQUOM] nvarchar(MAX) NULL,
    [Extended_Additional_Charge_Cost_____BDEACS] nvarchar(MAX) NULL,
    [Freight_Cost_UOM_Inbound_/_Full_____BDFUOM] nvarchar(MAX) NULL,
    [Freight_Terms_(MOP)_____BDFRTR] nvarchar(MAX) NULL,
    [Inventory_UOM_____BDIUOM] nvarchar(MAX) NULL,
    [Material_Cost_UOM_____BDCUOM] nvarchar(MAX) NULL,
    [Ordered_UOM_____BDOUOM] nvarchar(MAX) NULL,
    [P/O_Receiving_Batch/Register_Seq_Number_____BDBTCH] nvarchar(MAX) NULL,
    [PO_Line#_____BDLINE] nvarchar(MAX) NULL,
    [Line_In_Use_Code_____BDINUS] nvarchar(MAX) NULL,
    [Processed_Code_____BDPRCD] nvarchar(MAX) NULL,
    [Record_Code_____BDRECD] nvarchar(MAX) NOT NULL,
    [Tariff_Code_____BDTRF] nvarchar(MAX) NULL,
    [3_POSITION_CLASS_____BDCLS3] nvarchar(MAX) NULL,
    [35_POSITION_DESCRIPTION_____BDMSCD] nvarchar(MAX) NULL,
    [Calculating_Length_____BDLNTH] nvarchar(MAX) NULL,
    [Current_Inv._Quantity_Ordered_/_Received_____BDCQOO] nvarchar(MAX) NULL,
    CONSTRAINT [PK_z_Purchase_Order_Detail_File] PRIMARY KEY ([Transaction_#_____BDPONO], [ITEM_NUMBER_____BDITEM]),
    CONSTRAINT [FK_PODETAIL_CUSTOMER] FOREIGN KEY ([CUSTOMER_NUMBER_____BDCUST]) 
    REFERENCES [mrs].[z_Customer_Master_File_____ARCUST] ([CUSTOMER_NUMBER_____CCUST])
);
GO

CREATE TABLE [mrs].[z_Open_Order_File_____OEOPNORD] (
    [ORDER_NUMBER_____OOORDR] nvarchar(MAX) NOT NULL,
    [ADJ_GROSS_PROFIT_%_____OOGPPC] nvarchar(MAX) NULL,
    [CONT_CUST_NAME_____OOCCUS] nvarchar(MAX) NULL,
    [CUSTOMER_NUMBER_____OOCUST] nvarchar(MAX) NOT NULL,
    [CUSTOMER_PO_NUMBER_____OOCPO] nvarchar(MAX) NULL,
    [CUSTOMER_SHIP-TO_____OOSHTO] nvarchar(MAX) NULL,
    [CUTTING_CHARGE_COST_OUTSIDE_____OOCCSO] nvarchar(MAX) NULL,
    [CUTTING_CHARGE_SALES_OUTSIDE_____OOCSLO] nvarchar(MAX) NULL,
    [EX_CUTTING_CHARGE_SALES_OUTSIDE_____OOXCSO] nvarchar(MAX) NULL,
    [EX_MATERIAL_SALES_____OOXMSL] nvarchar(MAX) NULL,
    [EX_NET_AR_____OOXAMT] nvarchar(MAX) NULL,
    [EX_NET_SALES_____OOXNSL] nvarchar(MAX) NULL,
    [EXCH_STATE_TAX_AMT_____OOXSTA] nvarchar(MAX) NULL,
    [Exchange_Rate_____OOXRAT] nvarchar(MAX) NULL,
    [FREIGHT____OUT__COST_____OOFRTO] nvarchar(MAX) NULL,
    [FREIGHT_SALES_____OOFRTS] nvarchar(MAX) NULL,
    [Order_Type_____OOTYPE] nvarchar(MAX) NOT NULL,
    [SPECIAL_INVOICE_HANDLING_____OOSPIY] nvarchar(MAX) NOT NULL,
    [Tax_Country_____OOCTRY] nvarchar(MAX) NULL,
    [TERMS_OF_SALE_____OOSTRM] nvarchar(MAX) NOT NULL,
    [GROSS_MARGIN_$_AMT_____OOGM$] nvarchar(MAX) NULL,
    [GROSS_MARGIN_%_____OOGMPC] nvarchar(MAX) NULL,
    [GROSS_PROFIT_$_AMT_____OOGP$] nvarchar(MAX) NULL,
    [MATERIAL_COST_____OOMCST] nvarchar(MAX) NULL,
    [MATERIAL_SALES_____OOMSLS] nvarchar(MAX) NULL,
    [NET_A/R_____OONAR] nvarchar(MAX) NULL,
    [NET_COST_____OONCST] nvarchar(MAX) NULL,
    [NET_SALES_____OONSAL] nvarchar(MAX) NULL,
    [ACTUAL_SHIP_CENTURY_____OOACCC] nvarchar(MAX) NULL,
    [ACTUAL_SHIP_DAY_____OOACDD] nvarchar(MAX) NULL,
    [ACTUAL_SHIP_MONTH_____OOACMM] nvarchar(MAX) NULL,
    [ACTUAL_SHIP_YEAR_____OOACYY] nvarchar(MAX) NULL,
    [Audited_Century_____OOAUCC] nvarchar(MAX) NULL,
    [Audited_Day_____OOAUDD] nvarchar(MAX) NULL,
    [Audited_Month_____OOAUMM] nvarchar(MAX) NULL,
    [Audited_Year_____OOAUYY] nvarchar(MAX) NULL,
    [Century_____OOEXCC] nvarchar(MAX) NULL,
    [Effective_Century_____OOEFCC] nvarchar(MAX) NULL,
    CONSTRAINT [PK_z_Open_Order_File] PRIMARY KEY ([ORDER_NUMBER_____OOORDR]),
    CONSTRAINT [FK_OEOPNORD_CUSTOMER] FOREIGN KEY ([CUSTOMER_NUMBER_____OOCUST]) 
    REFERENCES [mrs].[z_Customer_Master_File_____ARCUST] ([CUSTOMER_NUMBER_____CCUST])
);
GO

CREATE TABLE [mrs].[z_Order_Detail_File_____OEDETAIL] (
    [Transaction_#_____ODORDR] nvarchar(MAX) NOT NULL,
    [INBOUND_ORDER_NUMBER_____ODIBOR] nvarchar(MAX) NOT NULL,
    [Order_Type_____ODTYPE] nvarchar(MAX) NOT NULL,
    [ITEM_NUMBER_____ODITEM] nvarchar(MAX) NOT NULL,
    [CRT_DESCRIPTION_____ODCRTD] nvarchar(MAX) NULL,
    [CUSTOMER_NUMBER_____ODCUST] nvarchar(MAX) NOT NULL,
    [CUSTOMER_PART_NUMBER_____ODCPRT] nvarchar(MAX) NULL,
    [CUSTOMER_REFERENCE_____ODCREF] nvarchar(MAX) NULL,
    [3_POSITION_CLASS_____ODCLAS] nvarchar(MAX) NULL,
    [ADJUSTED_BOOK_PRICE_____ODJPRC] nvarchar(MAX) NULL,
    [ADJUSTED_BOOK_PRICE_EXT_____ODJEXT] nvarchar(MAX) NULL,
    [AVG_COST_EXT_____ODACSX] nvarchar(MAX) NULL,
    [BASE/BOOK_PRICE_____ODBPRC] nvarchar(MAX) NULL,
    [BASE/BOOK_PRICE_EXT_____ODBEXT] nvarchar(MAX) NULL,
    [CALCULATING_LENGTH_____ODLENG] nvarchar(MAX) NULL,
    [COSTING_METHOD_COST_EXT_____ODCSTX] nvarchar(MAX) NULL,
    [COSTING_METHOD_UNIT_COST_____ODUCST] nvarchar(MAX) NULL,
    [Display_Length_____ODDSPL] nvarchar(MAX) NULL,
    [Display_Width_____ODDSPW] nvarchar(MAX) NULL,
    [EXCHANGE_$_AMT_____ODXAMT] nvarchar(MAX) NULL,
    [EXCHANGE_PRICE_____ODXSEL] nvarchar(MAX) NULL,
    [FREIGHT____OUT__COST_____ODFRTO] nvarchar(MAX) NULL,
    [Inner_Diameter_____ODIND] nvarchar(MAX) NULL,
    [INVENTORY_RESERVE_QUANTITY_____ODINVR] nvarchar(MAX) NULL,
    [MATERIAL_WEIGHT_____ODMLBS] nvarchar(MAX) NULL,
    [NEGOTIATED_SELL_$_EXT_____ODSLSX] nvarchar(MAX) NULL,
    [NEGOTITED_SELL_PRICE_____ODUSEL] nvarchar(MAX) NULL,
    [ORDER_QUANTITY_____ODIQTY] nvarchar(MAX) NULL,
    [Orig_Cost_Factor_____ODOCST] nvarchar(MAX) NULL,
    [ORIGINAL_QUANTITY_ORDERED_____ODORQT] nvarchar(MAX) NULL,
    [Outside_Diameter_____ODOUTD] nvarchar(MAX) NULL,
    [PRORATED_FREIGHT_SALES_____ODFRTS] nvarchar(MAX) NULL,
    [SALES_DISCOUNT_____ODDISC] nvarchar(MAX) NULL,
    [SCRAP_DEVALUATION_____ODSDEV] nvarchar(MAX) NULL,
    [SIZE_1_____ODSIZ1] nvarchar(MAX) NULL,
    [SIZE_2_____ODSIZ2] nvarchar(MAX) NULL,
    [SIZE_3_____ODSIZ3] nvarchar(MAX) NULL,
    [STOCK_INV.QTY_FOR_PRICING_____ODINVP] nvarchar(MAX) NULL,
    CONSTRAINT [PK_z_Order_Detail_File] PRIMARY KEY ([Transaction_#_____ODORDR], [INBOUND_ORDER_NUMBER_____ODIBOR], [ITEM_NUMBER_____ODITEM]),
    CONSTRAINT [FK_OEDETAIL_CUSTOMER] FOREIGN KEY ([CUSTOMER_NUMBER_____ODCUST]) 
    REFERENCES [mrs].[z_Customer_Master_File_____ARCUST] ([CUSTOMER_NUMBER_____CCUST]),
    CONSTRAINT [FK_OEDETAIL_OEOPNORD] FOREIGN KEY ([Transaction_#_____ODORDR]) 
    REFERENCES [mrs].[z_Open_Order_File_____OEOPNORD] ([ORDER_NUMBER_____OOORDR])
);
GO

/********************************
second part
**************************************/

-- Drop tables if they exist (in reverse dependency order)
IF OBJECT_ID('mrs.z_Material_Processing_Order_Detail_____MPDETAIL', 'U') IS NOT NULL DROP TABLE [mrs].[z_Material_Processing_Order_Detail_____MPDETAIL];
IF OBJECT_ID('mrs.z_Tag_Master_File_____ITEMTAG', 'U') IS NOT NULL DROP TABLE [mrs].[z_Tag_Master_File_____ITEMTAG];
IF OBJECT_ID('mrs.z_Item_on_Hand_File_____ITEMONHD', 'U') IS NOT NULL DROP TABLE [mrs].[z_Item_on_Hand_File_____ITEMONHD];
IF OBJECT_ID('mrs.z_Item_Master_File_____ITEMMAST', 'U') IS NOT NULL DROP TABLE [mrs].[z_Item_Master_File_____ITEMMAST];
IF OBJECT_ID('mrs.z_General_Ledger_Transaction_File_____GLTRANS', 'U') IS NOT NULL DROP TABLE [mrs].[z_General_Ledger_Transaction_File_____GLTRANS];
IF OBJECT_ID('mrs.z_General_Ledger_Account_file_____GLACCT', 'U') IS NOT NULL DROP TABLE [mrs].[z_General_Ledger_Account_file_____GLACCT];
IF OBJECT_ID('mrs.z_Vendor_Master_File_____APVEND', 'U') IS NOT NULL DROP TABLE [mrs].[z_Vendor_Master_File_____APVEND];
GO

-- z_Item_Master_File_____ITEMMAST table
CREATE TABLE [mrs].[z_Item_Master_File_____ITEMMAST] (
    [ITEM_NUMBER_____IMITEM] nvarchar(MAX) NOT NULL,
    [Rem_Item_Code_____IMREM] nvarchar(MAX) NULL,
    [X-Reference_Item_Number_____IMXITM] nvarchar(MAX) NULL,
    [Outside_Diameter_____IMOUTD] nvarchar(MAX) NULL,
    [Size_1_____IMSIZ1] nvarchar(MAX) NULL,
    [Size_2_____IMSIZ2] nvarchar(MAX) NULL,
    [Size_3_____IMSIZ3] nvarchar(MAX) NULL,
    [Wall_____IMWALL] nvarchar(MAX) NULL,
    [Item_Print_Descr_One_____IMDSC1] nvarchar(MAX) NULL,
    [Item_Print_Descr_Two_____IMDSC2] nvarchar(MAX) NULL,
    [Fast_Path_Item_Description_____IMFSP2] nvarchar(MAX) NULL,
    [CRT_Description_____IMCRTD] nvarchar(MAX) NULL,
    [Print_P.O._Description_____IMFDSC] nvarchar(MAX) NULL,
    [25_POSITION_ALPHA_____IMXRF2] nvarchar(MAX) NULL,
    [Scrap_Item_Code_____IMSCRP] nvarchar(MAX) NULL,
    [Company_SMO_____IMCSMO] nvarchar(MAX) NULL,
    [Average_Material_Receipt_Cost_____IMAVRC] nvarchar(MAX) NULL,
    [Last_Receipt_Cost_____IMRCST] nvarchar(MAX) NULL,
    [Last_Receipt_Purchase_Order_____IMPORD] nvarchar(MAX) NULL,
    [Numeric_Thickness_____IMTHIK] nvarchar(MAX) NULL,
    [VALUES_=_LB_,_CWT,_EA_,_MPC_FT_,_CFT,_SFT,_CSF_____IMCUOM] nvarchar(MAX) NULL,
    [W_=_LBS__P_=_PCS__S_=_SFT__F_=_FT_____IMMCOD] nvarchar(MAX) NULL,
    [W_=_WEIGHTED_P_=_PIECE_F_=_FOOT_S_=_SQUARE_FOOTM_=_____IMICOD] nvarchar(MAX) NULL,
    [WEB_THICKNESS_____IMWTHK] nvarchar(MAX) NULL,
    [3_POSITION_CLASS_____IMCLS3] nvarchar(MAX) NULL,
    [C_=_COIL__S_=_SHEET__P_=_PLATE__O_=_OTHER_T_=_TUBE_____IMSHAP] nvarchar(MAX) NULL,
    [Inner_Diameter_____IMIND] nvarchar(MAX) NULL,
    [Weight_Factor_____IMWGTF] nvarchar(MAX) NULL,
    [WEB_O.D._____IMWOD] nvarchar(MAX) NULL,
    [WEB_WALL_____IMWWAL] nvarchar(MAX) NULL,
    [Weight_Per_Foot_____IMWPFT] nvarchar(MAX) NULL,
    [Calculating_Length_____IMLNTH] nvarchar(MAX) NULL,
    [Calculating_Width_____IMWDTH] nvarchar(MAX) NULL,
    [Display_Length_____IMDSPL] nvarchar(MAX) NULL,
    [1_-_AVERAGE_COSTING__2_-_TAG_COSTING_3_-_TRANSACTI_____IMCSMD] nvarchar(MAX) NULL,
    [Record_Code_____IMRECD] nvarchar(MAX) NULL,
    [Reference_Code_____IMRFC2] nvarchar(MAX) NULL,
    [Scrap_Item_Flag_____IMSCRF] nvarchar(MAX) NULL,
    CONSTRAINT [PK_z_Item_Master_File] PRIMARY KEY ([ITEM_NUMBER_____IMITEM])
);
GO

-- z_Tag_Master_File_____ITEMTAG table
CREATE TABLE [mrs].[z_Tag_Master_File_____ITEMTAG] (
    [TAG_NUMBER_ALPHA_____ITTAG] nvarchar(MAX) NOT NULL,
    [Tag_Master_Description_____ITTDES] nvarchar(MAX) NULL,
    [Transaction_#_____ITTRN#] nvarchar(MAX) NULL,
    [List#_____ITLIST] nvarchar(MAX) NULL,
    [Mill_Coil#_____ITV301] nvarchar(MAX) NULL,
    [Heat_#_____ITHEAT] nvarchar(MAX) NULL,
    [PO#_____ITPOOR] nvarchar(MAX) NULL,
    [A/R_Cust#_____ITCUST] nvarchar(MAX) NULL,
    [A/R_Cust_TAG#_____ITCTAG] nvarchar(MAX) NULL,
    [ITEM_NUMBER_____ITITEM] nvarchar(MAX) NOT NULL,
    [COMMENT_LINE1_____ITV302] nvarchar(MAX) NULL,
    [COMMENT_LINE2_____ITV303] nvarchar(MAX) NULL,
    [COMMENT_LINE3_____ITV304] nvarchar(MAX) NULL,
    [Original_ITEM#_1_____ITOIC1] nvarchar(MAX) NULL,
    [Original_TAG#_1_____ITOIG1] nvarchar(MAX) NULL,
    [Size_1_____ITSIZ1] nvarchar(MAX) NULL,
    [Size_2_____ITSIZ2] nvarchar(MAX) NULL,
    [Size_3_____ITSIZ3] nvarchar(MAX) NULL,
    [PO_Line_#_____ITPOLN] nvarchar(MAX) NULL,
    [Vendor#_____ITVNDR] nvarchar(MAX) NULL,
    [HEAD_OR_1ST_MIC_READING_____ITMIC1] nvarchar(MAX) NULL,
    [Main_Line#_____ITMLIN] nvarchar(MAX) NULL,
    [Numeric_Length_____ITLNTH] nvarchar(MAX) NULL,
    [Numeric_Width_____ITWDTH] nvarchar(MAX) NULL,
    [ORG_REC_INV_QTY_____ITORRQ] nvarchar(MAX) NULL,
    [ORG_REC_PIECE_COUNT_____ITORRP] nvarchar(MAX) NULL,
    [Reserved_Quantity_____ITRQTY] nvarchar(MAX) NULL,
    [SECONDARY_TAG__QTY_____ITSQTY] nvarchar(MAX) NULL,
    [Tag_Cost_____ITTCST] nvarchar(MAX) NULL,
    [Tag_Pieces_____ITTPCS] nvarchar(MAX) NULL,
    [Tag_Quantity_____ITTQTY] nvarchar(MAX) NULL,
    [Time_Stamp_____ITTIMES] nvarchar(MAX) NULL,
    [Vendor_Quantity_____ITVQTY] nvarchar(MAX) NULL,
    [Warehouse_Loc_____ITLOCT] nvarchar(MAX) NULL,
    [Weight_Factor_____ITWGTF] nvarchar(MAX) NULL,
    [MATERIAL_RECIEVED_____ITRTAF] nvarchar(MAX) NULL,
    [MP_Processed_____ITFLG2] nvarchar(MAX) NULL,
    [PO_Type_____ITPOTY] nvarchar(MAX) NULL,
    CONSTRAINT [PK_z_Tag_Master_File] PRIMARY KEY ([TAG_NUMBER_ALPHA_____ITTAG]),
    CONSTRAINT [FK_ITEMTAG_ITEMMAST] FOREIGN KEY ([ITEM_NUMBER_____ITITEM]) 
    REFERENCES [mrs].[z_Item_Master_File_____ITEMMAST] ([ITEM_NUMBER_____IMITEM])
);
GO

-- z_Item_on_Hand_File_____ITEMONHD table
CREATE TABLE [mrs].[z_Item_on_Hand_File_____ITEMONHD] (
    [ITEM_NUMBER_____IOITEM] nvarchar(MAX) NOT NULL,
    [Qty_On_Hand_____IOQOH] nvarchar(MAX) NULL,
    [Qty_On_Order_____IOQOO] nvarchar(MAX) NULL,
    [Qty_On_Reserved_____IOQOR] nvarchar(MAX) NULL,
    [Matl._Prcs_Reserve_____IOMPRS] nvarchar(MAX) NULL,
    [Qty_On_Order_Rsrvd_____IOQOOR] nvarchar(MAX) NULL,
    [R/I_On_Hand_Qty_____IOROH] nvarchar(MAX) NULL,
    [R/I_On_Order_Qty_____IOROO] nvarchar(MAX) NULL,
    [Top_Item_Percentage_____IOTOPP] nvarchar(MAX) NULL,
    [VALUES_=_LB_,_CWT,_EA_,_MPC_FT_,_CFT,_SFT,_CSF_____IOPUOM] nvarchar(MAX) NULL,
    [3_POSITION_CLASS_____IOCLS3] nvarchar(MAX) NULL,
    [Average_Cost_____IOACST] nvarchar(MAX) NULL,
    [Average_Month_Sales_Qty_____IOAVMQ] nvarchar(MAX) NULL,
    [Avg._12_mos._Usage_____IOAV12] nvarchar(MAX) NULL,
    [Avg._3_mos._Usage_____IOAVG3] nvarchar(MAX) NULL,
    [Avg._OnHand_Dollars_____IOAVOS] nvarchar(MAX) NULL,
    [Avg._OnHand_Qty_____IOAVOH] nvarchar(MAX) NULL,
    [Base_Price_____IOBPRC] nvarchar(MAX) NULL,
    [BOM_Extended_Cost_____IOBOMC] nvarchar(MAX) NULL,
    [BOM_Inventory_____IOBOMI] nvarchar(MAX) NULL,
    [BOM_Weight_____IOBOMW] nvarchar(MAX) NULL,
    [Curr._YTD_Activity_Dol._____IOUSDL] nvarchar(MAX) NULL,
    [Curr._YTD_Activity_Qty_____IOUSQT] nvarchar(MAX) NULL,
    [Current_Year_Accumulated_Inv._Balance_(Dollars)_____IOCYIB] nvarchar(MAX) NULL,
    [Current_Year_Accumulated_Inv._Balance_(units)_____IOCYIU] nvarchar(MAX) NULL,
    [Customer_Order_Reserve_____IOCORS] nvarchar(MAX) NULL,
    [First_Acquisition_Cost_____IO1ACQ] nvarchar(MAX) NULL,
    [Inventory_Turns_$_____IOITDL] nvarchar(MAX) NULL,
    [Inventory_Turns_Units_____IOITUN] nvarchar(MAX) NULL,
    [Last_Receipt_Cost_____IOLRCS] nvarchar(MAX) NULL,
    [Months_Positive_Inv_____IOPMON] nvarchar(MAX) NULL,
    [MTD_Cost_Dollars_GP_____IOMCST] nvarchar(MAX) NULL,
    [MTD_Sales_Dollars_GP_____IOMSLS] nvarchar(MAX) NULL,
    [MTD_Units_Sold_____IOMUNT] nvarchar(MAX) NULL,
    [MTD_Weight_Sold_____IOMWGT] nvarchar(MAX) NULL,
    [Number_of_Days_Item_Has_Been_Set_Up_____IOITST] nvarchar(MAX) NULL,
    [Number_of_Days_Out_of_Stock_Current_Year_____IODOSC] nvarchar(MAX) NULL,
    [Number_of_Days_Out_of_Stock_Last_Year_____IODOSL] nvarchar(MAX) NULL,
    CONSTRAINT [PK_z_Item_on_Hand_File] PRIMARY KEY ([ITEM_NUMBER_____IOITEM]),
    CONSTRAINT [FK_ITEMONHD_ITEMMAST] FOREIGN KEY ([ITEM_NUMBER_____IOITEM]) 
    REFERENCES [mrs].[z_Item_Master_File_____ITEMMAST] ([ITEM_NUMBER_____IMITEM])
);
GO

-- z_Material_Processing_Order_Detail_____MPDETAIL table
CREATE TABLE [mrs].[z_Material_Processing_Order_Detail_____MPDETAIL] (
    [Transaction_#_____MDORDR] nvarchar(MAX) NOT NULL,
    [ITEM_NUMBER_____MDITEM] nvarchar(MAX) NULL,
    [Inventory_Code_____MDINVC] nvarchar(MAX) NULL,
    [CRT_DESCRIPTION_____MDCRTD] nvarchar(MAX) NULL,
    [Size_1_____MDSIZ1] nvarchar(MAX) NULL,
    [Size_2_____MDSIZ2] nvarchar(MAX) NULL,
    [Size_3_____MDSIZ3] nvarchar(MAX) NULL,
    [PROC_STATUS_CODE_____MDMSTS] nvarchar(MAX) NULL,
    [Record_Code_____MDRECD] nvarchar(MAX) NULL,
    [TAG_CODE_____MDTAGC] nvarchar(MAX) NULL,
    [Y_=_YES__N_=_NO_____MDSKID] nvarchar(MAX) NULL,
    [3_POSITION_CLASS_____MDCLAS] nvarchar(MAX) NULL,
    [CALCULATING_WIDTH_____MDWDTH] nvarchar(MAX) NULL,
    [Display_Width_____MDDSPW] nvarchar(MAX) NULL,
    [Last_Maintained_User_____MDLMUS] nvarchar(MAX) NULL,
    [REMOTE_INVENTORY_VENDOR_____MDRVND] nvarchar(MAX) NULL,
    [Shape_____MDSHAP] nvarchar(MAX) NULL,
    [TOTAL_FEET_____MDTFTS] nvarchar(MAX) NULL,
    [TOTAL_PIECES_____MDTPCS] nvarchar(MAX) NULL,
    [TOTAL_SQUARE_FEET_____MDTSFT] nvarchar(MAX) NULL,
    [Vendor_#_____MDVNDR] nvarchar(MAX) NULL,
    [CALCULATING_LENGTH_____MDLENG] nvarchar(MAX) NULL,
    [COSTING_METHOD_UNIT_COST_____MDUCST] nvarchar(MAX) NULL,
    [COSTING_METHOD_UNIT_COST_EXT_____MDCSTX] nvarchar(MAX) NULL,
    [Display_Length_____MDDSPL] nvarchar(MAX) NULL,
    [FILLED_ON_ORDER_QUANTITY_____MDFQTY] nvarchar(MAX) NULL,
    [INVENTORY_RESERVE_QUANTITY_____MDINVR] nvarchar(MAX) NULL,
    [ON_ORDER_QUANTITY_____MDOQTY] nvarchar(MAX) NULL,
    [ORDER_QUANTITY_____MDIQTY] nvarchar(MAX) NULL,
    [ORG_EST_WEIGHT_____MDUEWT] nvarchar(MAX) NULL,
    [ORIGINAL_ORDER_QUANTITY_____MDORQT] nvarchar(MAX) NULL,
    [Theo._Meters_____MDTMTR] nvarchar(MAX) NULL,
    [Theo_Kilos_____MDTKG] nvarchar(MAX) NULL,
    [TOTAL_POUNDS_____MDTLBS] nvarchar(MAX) NULL,
    [Weight_Factor_____MDWGTF] nvarchar(MAX) NULL,
    [TOTAL_PROCESS_COST_____MDPRCC] nvarchar(MAX) NULL,
    [REQUESTED_SHIP_CENTURY_____MDRQCC] nvarchar(MAX) NULL,
    [REQUESTED_SHIP_DAY_____MDRQDD] nvarchar(MAX) NULL,
    CONSTRAINT [PK_z_Material_Processing_Order_Detail] PRIMARY KEY ([Transaction_#_____MDORDR]),
    CONSTRAINT [FK_MPDETAIL_ITEMTAG] FOREIGN KEY ([ITEM_NUMBER_____MDITEM]) 
    REFERENCES [mrs].[z_Tag_Master_File_____ITEMTAG] ([ITEM_NUMBER_____ITITEM])
);
GO

-- z_General_Ledger_Account_file_____GLACCT table
CREATE TABLE [mrs].[z_General_Ledger_Account_file_____GLACCT] (
    [GL_Account_Number_____GACCT] nvarchar(MAX) NOT NULL,
    [GL_Description_____GACDES] nvarchar(MAX) NULL,
    [Alt._Report_Line_3_____GAAR3] nvarchar(MAX) NULL,
    [Report_Line_3_____GARP3] nvarchar(MAX) NULL,
    [GL_Bal._Sheet_Type_____GATYPC] nvarchar(MAX) NULL,
    [Alt._Report_Line_1_____GAAR1] nvarchar(MAX) NULL,
    [Report_Line_1_____GARP1] nvarchar(MAX) NULL,
    [Last_Maintained_Year_____GALMYY] nvarchar(MAX) NULL,
    [01-12_____GALMMM] nvarchar(MAX) NULL,
    [Alt._Report_Line_2_____GAAR2] nvarchar(MAX) NULL,
    [Report_Line_2_____GARP2] nvarchar(MAX) NULL,
    [GL_P&L_Type_____GATYPE] nvarchar(MAX) NULL,
    [A=ACTIVE__D=DELETED_I=INACTIVE_____GARECD] nvarchar(MAX) NULL,
    [Last_Maintained_User_____GALMUS] nvarchar(MAX) NULL,
    [Balance_Code_____GABALC] nvarchar(MAX) NULL,
    [Contra_Acct_Code_____GACONT] nvarchar(MAX) NULL,
    [Last_Maintained_Century_____GALMCC] nvarchar(MAX) NULL,
    [Alt._Report_Line_10_____GAAR10] nvarchar(MAX) NULL,
    [Alt._Report_Line_4_____GAAR4] nvarchar(MAX) NULL,
    [Alt._Report_Line_5_____GAAR5] nvarchar(MAX) NULL,
    [Alt._Report_Line_6_____GAAR6] nvarchar(MAX) NULL,
    [Alt._Report_Line_7_____GAAR7] nvarchar(MAX) NULL,
    [Alt._Report_Line_8_____GAAR8] nvarchar(MAX) NULL,
    [Alt._Report_Line_9_____GAAR9] nvarchar(MAX) NULL,
    [Corporate_Acct?_____GACORP] nvarchar(MAX) NULL,
    [Report_Line_10_____GARP10] nvarchar(MAX) NULL,
    [Report_Line_4_____GARP4] nvarchar(MAX) NULL,
    [Report_Line_5_____GARP5] nvarchar(MAX) NULL,
    [Report_Line_6_____GARP6] nvarchar(MAX) NULL,
    [Report_Line_7_____GARP7] nvarchar(MAX) NULL,
    [Report_Line_8_____GARP8] nvarchar(MAX) NULL,
    [Report_Line_9_____GARP9] nvarchar(MAX) NULL,
    [Last_Maintained_Day_____GALMDD] nvarchar(MAX) NULL,
    CONSTRAINT [PK_z_General_Ledger_Account_file] PRIMARY KEY ([GL_Account_Number_____GACCT])
);
GO

-- z_Vendor_Master_File_____APVEND table
CREATE TABLE [mrs].[z_Vendor_Master_File_____APVEND] (
    [Vendor_#_____VVNDR] nvarchar(MAX) NOT NULL,
    [Vendor_Name_____VNAME] nvarchar(MAX) NULL,
    [Federal_ID_Number_____VFEDID] nvarchar(MAX) NULL,
    [SCAC_code_____VSCAC] nvarchar(MAX) NULL,
    [Default_G/L#_____VGLACT] nvarchar(MAX) NULL,
    [Vendor_Alpha_Search_____VALPHA] nvarchar(MAX) NULL,
    [CITY_25_POS_____VCITY] nvarchar(MAX) NULL,
    [ZIP_CODE_12_POS_____VZIP] nvarchar(MAX) NULL,
    [Vendor_Address_1_____VADDR1] nvarchar(MAX) NULL,
    [Vendor_Address_2_____VADDR2] nvarchar(MAX) NULL,
    [Vendor_Address_3_____VADDR3] nvarchar(MAX) NULL,
    [Vendor_FAX_Number_____VFPHON] nvarchar(MAX) NULL,
    [Vendor_Phone_Number_____VPHONE] nvarchar(MAX) NULL,
    [E-MAIL_ADDRESS_____VEMAL] nvarchar(MAX) NULL,
    [WEB_SITE_ADDRESS_____VWEBS] nvarchar(MAX) NULL,
    [State_Code_____VSTATE] nvarchar(MAX) NULL,
    [Country_____VCNTRY] nvarchar(MAX) NULL,
    [Ctry_of_Origin_____VCORIG] nvarchar(MAX) NULL,
    [Days_Due_____VDAYDU] nvarchar(MAX) NULL,
    [Material_Type_D/I/C_____VMATL] nvarchar(MAX) NULL,
    [Cage_Code_____VCAGE] nvarchar(MAX) NULL,
    [Taxation_ID_Number_____VTAXID] nvarchar(MAX) NULL,
    [Record_Code_____VRECD] nvarchar(MAX) NULL,
    [County_Code_____VCNTY] nvarchar(MAX) NULL,
    [Language_Code_____VLANG] nvarchar(MAX) NULL,
    [PAYMENT_CODE_____VVPAYM] nvarchar(MAX) NULL,
    [Freight_Terms_____VFRTRM] nvarchar(MAX) NULL,
    [VENDOR_DESIGNATION_CODE_____VDECO] nvarchar(MAX) NULL,
    [Vendor_Parent_Code_____VPCODE] nvarchar(MAX) NULL,
    [_____VFLAG3] nvarchar(MAX) NULL,
    [_____VFLAG5] nvarchar(MAX) NULL,
    [_____VFLAG6] nvarchar(MAX) NULL,
    [1099_Required_____VR1099] nvarchar(MAX) NULL,
    [A/R_Customer_Number_____VCCUST] nvarchar(MAX) NULL,
    [ALLOW_NON-INV_RCPT_ENTRY_____VNIRCE] nvarchar(MAX) NULL,
    [Century_Vendor_Added_____VADDCC] nvarchar(MAX) NULL,
    [COMPANY_NUMBER_____VCOMP] nvarchar(MAX) NULL,
    [County_Name_____VCONM] nvarchar(MAX) NULL,
    CONSTRAINT [PK_z_Vendor_Master_File] PRIMARY KEY ([Vendor_#_____VVNDR])
);
GO

-- z_General_Ledger_Transaction_File_____GLTRANS table
CREATE TABLE [mrs].[z_General_Ledger_Transaction_File_____GLTRANS] (
    [Trans#_____GLTRN#] nvarchar(MAX) NULL,
    [Reference_Number_____GLREF] nvarchar(MAX) NULL,
    [Batch_Number_____GLBTCH] nvarchar(MAX) NULL,
    [G/L_Account_Number_____GLACCT] nvarchar(MAX) NULL,
    [Vendor_Name_/_Customer_Name_/_Application_____GLDESC] nvarchar(MAX) NULL,
    [CUSTOMER_NUMBER_____GLCUST] nvarchar(MAX) NULL,
    [G/L_Amount_-_Queries_____GLAMTQ] nvarchar(MAX) NULL,
    [G/L_Amount_____GLAMT] nvarchar(MAX) NULL,
    [Application_Code_____GLAPPL] nvarchar(MAX) NULL,
    [Credit_/_Debit_Code_____GLCRDB] nvarchar(MAX) NULL,
    [Record_Code_____GLRECD] nvarchar(MAX) NULL,
    [Order_Type_____GLTYPE] nvarchar(MAX) NULL,
    [Transaction_Type_____GLTRNT] nvarchar(MAX) NULL,
    [Lock_Box_Number_____GLLOCK] nvarchar(MAX) NULL,
    [Related_Party_Customer_or_Vendor_____GLRP#] nvarchar(MAX) NULL,
    [A/P_Trans_____GLAPTR] nvarchar(MAX) NULL,
    [G/L_Posting_Year_____GLPPYY] nvarchar(MAX) NULL,
    [Posting_Year_____GLPYY] nvarchar(MAX) NULL,
    [Posting_Day_____GLPDD] nvarchar(MAX) NULL,
    [Posting_Month_____GLPMM] nvarchar(MAX) NULL,
    [G/L_Posting_Period_____GLPERD] nvarchar(MAX) NULL,
    [Reference_Month_____GLRFMM] nvarchar(MAX) NULL,
    [Reference_Year_____GLRFYY] nvarchar(MAX) NULL,
    [System_Year_____GLSYY] nvarchar(MAX) NULL,
    [Batch_District_____GLBDIS] nvarchar(MAX) NULL,
    [Cust_Dist_____GLCDIS] nvarchar(MAX) NULL,
    [Reference_Cent_____GLRFCC] nvarchar(MAX) NULL,
    [Related_Parties_____GLRPTY] nvarchar(MAX) NULL,
    [Trans_Dist_____GLTRDS] nvarchar(MAX) NULL,
    [Company_Number_____GLCOMP] nvarchar(MAX) NULL,
    [Cost_Center_____GLCSTC] nvarchar(MAX) NULL,
    [District_Number_____GLDIST] nvarchar(MAX) NULL,
    [Posting_Century_____GLPCC] nvarchar(MAX) NULL,
    [Time_____GLTIME] nvarchar(MAX) NULL,
    [Extract_Time_____GLEXTM] nvarchar(MAX) NULL,
    [Display_ID_____GLDSP] nvarchar(MAX) NULL,
    [Extract_Date_____GLEXDT] nvarchar(MAX) NULL
    -- Note: No primary key specified in the data
);
GO