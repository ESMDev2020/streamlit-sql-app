USE SigmaTB;


/*****************************************
01. IDENTIFY IF ALL THE COLUMNS HAS COMMENTS
*****************************************/
SELECT * FROM SYS.COLUMNS 


/*****************************************
01. ITEM PRICE
*****************************************/
--ROP_query_
-- Price
-- Retrieves each item and its base price from the inventory file
-- Table: ITEMONHD = Item On Hand (live inventory)
-- Fields:
--   IOITEM = Item number
--   IOBPRC = Base price
-- ITEMONHD: Contains inventory quantities, costs, and base price per item.
SELECT 
    ITEMONHD.IOITEM AS IOITEM_ItemNumber,
    ITEMONHD.IOBPRC AS IOBPRC_BasePrice
FROM 
    ITEMONHD ITEMONHD


/*****************************************
02. MATERIAL PROCESSING
*****************************************/
--ROP_query_
--Material Processing
-- Lists MPO (Material Processing Order) records with vendor info, item, quantity, and transaction dates.
-- Tables: MPDETAIL = Material Processing Detail, APVEND = Accounts Payable Vendor
-- Fields:
--   MPORDR = MPO order number              *** IMPORTANT***
--   MPVNDR = Vendor code
--   MPCLOS = Close flag
--   MPITEM = Item processed                ***IMPORTANT****
--   MPCRTD = Date created
--   MPOQTY = Quantity ordered
--   MPOUOM = Unit of measure
--   MPIQTY = Quantity issued
--   mdrqcc*1000000+mdrqyy*10000+mdrqmm*100+mdrqdd = Requested processing date
--   VALPHA = Vendor name
-- MPDETAIL: Tracks processing transactions; 
-- APVEND: Vendor master table.
SELECT 
    MPDETAIL.MDORDR AS MDORDR_MaterialProcessingOrder,
    APVEND.VVNDR AS VVNDR_VendorCode,
    APVEND.VALPHA AS VALPHA_VendorName,
    MPDETAIL.MDCLOS AS MDCLOS_CloseFlag,
    MPDETAIL.MDITEM AS MDITEM_ItemNumber,
    MPDETAIL.MDCRTD AS MDCRTD_CreationDate,
    mdrqcc*1000000+mdrqyy*10000+mdrqmm*100+mdrqdd AS MPRQDATE_RequestedProcessingDate,
    MPDETAIL.MDOQTY AS MDOQTY_QuantityOrdered,
    MPDETAIL.MDOUOM AS MDOUOM_UnitOfMeasure,
    MPDETAIL.MDIQTY AS MDIQTY_QuantityIssued
FROM 
    APVEND APVEND, 
    MPDETAIL MPDETAIL
WHERE 
    APVEND.VCOMP = MPDETAIL.MDCOMP 
    AND APVEND.VVNDR = MPDETAIL.MDVNDR
ORDER BY 
    MPDETAIL.MDITEM, 
    MPDETAIL.MDORDR DESC


/*****************************************
03. PURCHASE ORDER DETAILS
*****************************************/
--ROP_query_
--PO query
-- Retrieves purchase order details, including item, vendor, order and receipt dates, and quantities ordered.
-- Tables:  PODETAIL = Purchase Order Detail, 
--          APVEND = Vendor Master
-- Fields:
--   BDPONO = Purchase order number             *** IMPORTANT***
--   BDVNDR = Vendor code
--   VNAME  = Vendor name
--   BDRECD = PO record flag
--   BDITEM = Item code                         *** IMPORTANT***
--   BDCRTD = Creation date
--   BDOQOO = Quantity ordered
--   BDIUOM = Unit of measure
--   BDCQOO = Quantity confirmed
--   BDOOQ  = Other ordered quantity
--   BDTIQR = Time in queue (estimated)
--   Date fields are calculated using: bdrpcc, bdrpyy, bdrpmm, bdrpdd
--  PODETAIL: Purchase order lines; 
--  APVEND: Vendor names.
SELECT 
    PODETAIL.BDPONO AS BDPONO_PurchaseOrderNumber,
    PODETAIL.BDVNDR AS BDVNDR_VendorCode,
    APVEND.VNAME AS VNAME_VendorName,
    PODETAIL.BDRECD AS BDRECD_RecordFlag,
    PODETAIL.BDITEM AS BDITEM_ItemNumber,
    PODETAIL.BDCRTD AS BDCRTD_CreationDate,
    bdrpcc*1000000 + bdrpyy*10000 + bdrpmm*100 + bdrpdd AS BDRPDATE_RequiredDate,
    PODETAIL.BDOQOO AS BDOQOO_QuantityOrdered,
    PODETAIL.BDIUOM AS BDIUOM_UnitOfMeasure,
    PODETAIL.BDCQOO AS BDCQOO_ConfirmedQuantity,
    PODETAIL.BDOOQ AS BDOOQ_OtherOrderedQuantity,
    PODETAIL.BDTIQR AS BDTIQR_TimeInQueue,
    bdpocc*1000000 + bdpoyy*10000 + bdpomm*100 + bdpodd AS BDPOCDATE_PurchaseOrderDate,
    bdrccc*1000000 + bdrcyy*10000 + bdrcmm*100 + bdrcdd AS BDRCCDATE_ReceiptConfirmationDate
FROM 
    {oj PODETAIL PODETAIL 
    LEFT OUTER JOIN APVEND APVEND 
    ON PODETAIL.BDVNDR = APVEND.VVNDR}
WHERE 
    PODETAIL.BDITEM BETWEEN '50000' AND '99998'
ORDER BY 
    PODETAIL.BDITEM, 
    PODETAIL.BDPONO DESC



/*****************************************
04. ROP INVENTORY OVERVIEW
*****************************************/
--ROP_query_
--ROP Inventory Overview
-- Retrieves inventory and product master data for relevant item ranges, combining size, grade, quantity, and cost info.
-- Tables: ITEMMAST = Item Master, ITEMONHD = Inventory On Hand
-- Fields:
--   IMFSP2 = Group or family code          *** IMPORTANT***
--   IMITEM = Item number                   *** IMPORTANT***
--   IMSIZ1, IMSIZ2, IMSIZ3 = Size specs
--   IMDSC1, IMDSC2 = Descriptions
--   IMWPFT = Weight per foot
--   IMWUOM = Weight unit of measure
--   IMCSMO = Costing model
--   IOACST = Average cost                  *** IMPORTANT***
--   IOQOH  = Quantity on hand
--   IOQOO  = Quantity on order
--   IOQOR+IOQOOR = Order + other orders
--  ITEMMAST: Master description of items; 
--  ITEMONHD: On-hand inventory data.
SELECT 
    ITEMMAST.IMFSP2 AS IMFSP2_ItemFamilyGroup,
    ITEMMAST.IMITEM AS IMITEM_ItemNumber,
    ITEMMAST.IMSIZ1 AS IMSIZ1_SizeSpec1,
    ITEMMAST.IMSIZ2 AS IMSIZ2_SizeSpec2,
    ITEMMAST.IMSIZ3 AS IMSIZ3_SizeSpec3,
    ITEMMAST.IMDSC2 AS IMDSC2_Description2,
    ITEMMAST.IMWPFT AS IMWPFT_WeightPerFoot,
    ITEMONHD.IOACST AS IOACST_AverageCost,
    ITEMONHD.IOQOH AS IOQOH_QuantityOnHand,
    ITEMONHD.IOQOO AS IOQOO_QuantityOnOrder,
    IOQOR+IOQOOR AS IOQ_TOTAL_TotalQuantityOnOrder,
    ITEMMAST.IMDSC1 AS IMDSC1_Description1,
    ITEMMAST.IMWUOM AS IMWUOM_WeightUnitOfMeasure,
    ITEMMAST.IMCSMO AS IMCSMO_CostingModel
FROM 
    ITEMMAST ITEMMAST,
    ITEMONHD ITEMONHD
WHERE 
    ITEMONHD.IOITEM = ITEMMAST.IMITEM 
    AND ((ITEMMAST.IMRECD='A') 
    AND (ITEMMAST.IMITEM BETWEEN '49999' AND '90000'))
ORDER BY 
    ITEMMAST.IMFSP2


/*****************************************
SALES DATA
*****************************************/
--ROP_query_
--Sales Data
-- Retrieves sales order line items and customer info for analysis of sales transactions.
-- Tables: 
--  OEOPNORD = Order Entry-Open Order (Header), 
--  OEDETAIL = Order Entry Detail, 
--  ARCUST = Customer Master
-- Fields:
--   OORECD = Record flag (active)
--   OOCUST = Customer ID               *** IMPORTANT***
--   CALPHA = Customer name             *** IMPORTANT***
--   ODTYPE = Order type (A, C)
--   ODITEM = Item                      *** IMPORTANT***
--   ODORDR = Order number              *** IMPORTANT***
--   ODTLBS, ODTFTS = Weight and footage
--   Date = Constructed using ooocc, oooyy, ooomm, ooodd
--   Sales Rep ID = csmdi1*100+cslmn1   
--   OORECD = Order record flag
--   TABLES
--  OEOPNORD: Order Entry-Open Order Order headers; 
--  OEDETAIL: Order lines; 
--  ARCUST: Customer master.
SELECT 
    OEOPNORD.OORECD AS OORECD_RecordFlag,
    OEDETAIL.ODTYPE AS ODTYPE_OrderType,
    OEDETAIL.ODITEM AS ODITEM_ItemCode,
    OEDETAIL.ODORDR AS ODORDR_OrderNumber,
    OEOPNORD.OOCUST AS OOCUST_CustomerID,
    ARCUST.CALPHA AS CALPHA_CustomerName,
    OEDETAIL.ODTLBS AS ODTLBS_TotalLbs,
    OEDETAIL.ODTFTS AS ODTFTS_TotalFeet,
    ooocc*1000000+oooyy*10000+ooomm*100+ooodd AS ORDER_DATE_TransactionDate,
    csmdi1*100+cslmn1 AS SALES_REP_ID_SalesmanCode
FROM 
    ARCUST ARCUST,
    OEDETAIL OEDETAIL,
    OEOPNORD OEOPNORD
WHERE 
    OEDETAIL.ODORDR = OEOPNORD.OOORDR 
    AND OEOPNORD.OOCUST = ARCUST.CCUST 
    AND OEOPNORD.OORECD = 'A'
    AND OEDETAIL.ODTYPE IN ('A', 'C')
ORDER BY 
    OEDETAIL.ODITEM


/*****************************************
06. TAG
*****************************************/
--ROP_query_
--Tag Query
-- Retrieves tag-level inventory info: physical stock by heat number, quantity, and tag attributes.
-- Tables: 
--  ITEMTAG = Inventory Tags, 
--  ITEMMAST = Item Master
-- Fields:
--   ITITEM = Item number                               *** IMPORTANT***
--   ITTAG = Tag number
--   ITTDES = Tag description                           
--   ITLNTH = Length
--   ITTPCS = Number of pieces
--   ITHEAT = Heat number (traceability)                *** IMPORTANT***
--   ITV301 = Possibly vendor/batch                     *** IMPORTANT***
--   ITLOCT = Location                                  
--   ITTQTY = Total quantity
--   ITRQTY = Reserved quantity
-- TABLES
-- ITEMTAG: Inventory tags, like 8.250 BAR HF 4340 AR; 
-- ITEMMAST: Item descriptions.
SELECT 
    ITEMTAG.ITITEM AS ITITEM_ItemNumber,
    ITEMTAG.ITTAG AS ITTAG_TagNumber,
    ITEMTAG.ITTDES AS ITTDES_TagDescription,
    ITEMTAG.ITLNTH AS ITLNTH_LengthFeet,
    ITEMTAG.ITTPCS AS ITTPCS_NumberOfPieces,
    ITEMTAG.ITHEAT AS ITHEAT_HeatNumber,
    ITEMTAG.ITV301 AS ITV301_VendorOrBatchCode,
    ITEMTAG.ITLOCT AS ITLOCT_StorageLocation,
    ITEMTAG.ITTQTY AS ITTQTY_TotalQuantity,
    ITEMTAG.ITRQTY AS ITRQTY_ReservedQuantity,
    ITEMMAST.IMFSP2 AS IMFSP2_ItemFamilyGroup
FROM 
    ITEMMAST ITEMMAST,
    ITEMTAG ITEMTAG
WHERE 
    ITEMTAG.ITITEM = ITEMMAST.IMITEM 
    AND ITEMTAG.ITRECD = 'A' 
    AND ITEMTAG.ITITEM > '49999'
ORDER BY 
    ITEMTAG.ITITEM, 
    ITEMTAG.ITHEAT, 
    ITEMTAG.ITV301, 
    ITEMTAG.ITLNTH


/*****************************************
07. USAGE
*****************************************/
-- ROP_query_
-- Usage Query
-- Retrieves historical inventory transactions (sales, returns, adjustments) for items within a date range.
-- Table: ITEMHIST = Inventory History
-- Fields:
--   IHITEM = Item number                                   *** IMPORTANT***
--   IHTRNT = Transaction type (e.g. IN, CR)                
--   IHTRN# = Transaction number                            *** IMPORTANT***
--   IHVNDR = Vendor involved                               *** IMPORTANT***
--   IHCUST = Customer involved                             *** IMPORTANT***
--   IHTRYY, IHTRMM, IHTRDD = Transaction date
--   IHTQTY = Quantity transacted
--  TABLES
--      ITEMHIST: Inventory transaction history for usage analysis.
SELECT 
    ITEMHIST.IHITEM AS IHITEM_ItemNumber,
    ITEMHIST.IHTRNT AS IHTRNT_TransactionType,
    ITEMHIST.IHTRN# AS IHTRN_TransactionNumber,
    ITEMHIST.IHVNDR AS IHVNDR_VendorID,
    ITEMHIST.IHCUST AS IHCUST_CustomerID,
    ITEMHIST.IHTRYY AS IHTRYY_TransactionYear,
    ITEMHIST.IHTRMM AS IHTRMM_TransactionMonth,
    ITEMHIST.IHTRDD AS IHTRDD_TransactionDay,
    ITEMHIST.IHTQTY AS IHTQTY_QuantityTransacted
FROM 
    ITEMHIST ITEMHIST
WHERE 
    IHTRYY = 25 AND IHTRMM = 2
    AND ITEMHIST.IHITEM BETWEEN '50000' AND '99998'
ORDER BY 
    ITEMHIST.IHITEM, 
    ITEMHIST.IHTRYY, 
    ITEMHIST.IHTRMM, 
    ITEMHIST.IHTRDD


/*****************************************
08. USAGE BY CUSTOMER
*****************************************/
-- ROP_query_
-- Usage sum query
-- Sums item usage by customer and transaction type within a date range (e.g. for sales forecasting).
--  Tables: ITEMHIST = Item History, 
--  ARCUST = Customer Master
-- Fields:
--   IHITEM = Item number
--   IHTRNT = Transaction type
--   IHCUST = Customer code
--   CALPHA = Customer name
--   Sales Rep ID = csmdi1*100+cslmn1
-- ITEMHIST: Usage log; ARCUST: Customer master file.
SELECT DISTINCT 
    ITEMHIST.IHITEM AS IHITEM_ItemNumber,
    ITEMHIST.IHTRNT AS IHTRNT_TransactionType,
    ITEMHIST.IHCUST AS IHCUST_CustomerCode,
    ARCUST.CALPHA AS CALPHA_CustomerName,
    csmdi1*100 + cslmn1 AS SALES_REP_ID_SalesmanCode
FROM 
    ARCUST ARCUST,
    ITEMHIST ITEMHIST
WHERE 
    ARCUST.CCUST = ITEMHIST.IHCUST
    AND ihtryy = 25 and ihtrmm = 2 
    AND ITEMHIST.IHITEM BETWEEN '50000' AND '99998'
    AND ITEMHIST.IHTRNT IN ('CR', 'IN')
ORDER BY 
    ITEMHIST.IHITEM, 
    ARCUST.CALPHA


/*****************************************
*****************************************/
-- NOTE: This is a partial copy. Full script with all queries will follow.



/*****************************************
*****************************************/
-- FS_query
-- NOTE: No query provided for the FS file, this may be a placeholder for future financial statement integration.

/*****************************************
09. CREDIT MEMOS
*****************************************/
--SalesAnalysisQuery_
--CreditMemos
-- Analyzes credit memos (returns, adjustments) linked to sales orders and customer accounts.
-- Tables: 
--  OEOPNORD = Order Entry-Open Order - Order Header, 
--  OEDETAIL = Order Detail, 
--  ARCUST = Customer, SALESMAN = Sales rep
-- Fields:
--   OODIST = Distribution ID
--   ODORDR = Order number                              *** IMPORTANT***
--   OOTYPE = Order type ('C' = credit memo)
--   ODCUST = Customer ID                               *** IMPORTANT***
--   CALPHA = Customer name                             
--   ODITEM = Item                                      *** IMPORTANT***
--   ODCRTD = Creation date                             *** IMPORTANT***
--   ODFRTS, ODCSTX = Freight & cost
--   ODPRCC = Price charged
--   ODCREF = Credit reference                          *** IMPORTANT***
--   OOICC + OOIYY + OOIMM + OOIDD = Transaction date
--   LOOK IF THERE IS ANY DETAIL ABOUT THE CANCELLING

SELECT 
    oddist * 1000000 + odordr AS ORDER_KEY_DistributionOrderID,
    SALESMAN.SMNAME AS SMNAME_SalesmanName,
    OEOPNORD.OOTYPE AS OOTYPE_OrderType,
    odcdis * 100000 + odcust AS CUSTOMER_KEY_DistributionCustomerID,
    ARCUST.CALPHA AS CALPHA_CustomerName,
    OEDETAIL.ODITEM AS ODITEM_ItemNumber,
    OEDETAIL.ODSIZ1 AS ODSIZ1_Size1,
    OEDETAIL.ODSIZ2 AS ODSIZ2_Size2,
    OEDETAIL.ODSIZ3 AS ODSIZ3_Size3,
    OEDETAIL.ODCRTD AS ODCRTD_CreationDate,
    OEDETAIL.ODTFTS AS ODTFTS_TotalFeet,
    OEDETAIL.ODTLBS AS ODTLBS_TotalPounds,
    OEDETAIL.ODTPCS AS ODTPCS_TotalPieces,
    OEDETAIL.ODSLSX AS ODSLSX_SalesExtension,
    OEDETAIL.ODFRTS AS ODFRTS_FreightCost,
    OEDETAIL.ODCSTX AS ODCSTX_ItemCost,
    OEDETAIL.ODPRCC AS ODPRCC_UnitPriceCharged,
    OEDETAIL.ODADCC AS ODADCC_AdditionalCharges,
    OEDETAIL.ODWCCS AS ODWCCS_WholesaleCredit,
    ARCUST.CSTAT AS CSTAT_CustomerState,
    ARCUST.CCTRY AS CCTRY_CustomerCountry,
    OOICC * 1000000 + OOIYY * 10000 + OOIMM * 100 + OOIDD AS TRANSACTION_DATE,
    OEDETAIL.ODCREF AS ODCREF_CreditReference
FROM 
    ARCUST ARCUST,
    OEDETAIL OEDETAIL,
    OEOPNORD OEOPNORD,
    SALESMAN SALESMAN
WHERE 
    OEDETAIL.ODDIST = OEOPNORD.OODIST
    AND OEDETAIL.ODORDR = OEOPNORD.OOORDR
    AND OEOPNORD.OOCDIS = ARCUST.CDIST
    AND OEOPNORD.OOCUST = ARCUST.CCUST
    AND OEOPNORD.OOISMD = SALESMAN.SMDIST
    AND OEOPNORD.OOISMN = SALESMAN.SMSMAN
    AND OEOPNORD.OOTYPE = 'C'
    AND OEOPNORD.OORECD = 'W'
    AND OOIYY = 25 AND OOIMM = 2
    


/*****************************************
10. SALES ANALYSIS - NICE BUT USELESS
*****************************************/
--SalesAnalysisQuery_
--Customer-Summary
-- Summarizes customer data including credit limit and assigned sales rep.
-- Tables: ARCUST = Customer, SALESMAN = Sales rep
-- Fields:
--   CDIST+CCUST = Customer full code
--   CALPHA = Customer name
--   CLIMIT = Credit limit
--   CISMD1*100+CISLM1 = Sales rep ID
SELECT DISTINCT 
    cdist * 100000 + ccust AS CUSTOMER_KEY_DistributionCustomerID,
    ARCUST.CALPHA AS CALPHA_CustomerName,
    ARCUST.CLIMIT AS CLIMIT_CreditLimit,
    CISMD1 * 100 + CISLM1 AS SALES_REP_ID_Primary,
    CSMDI1 * 100 + CSLMN1 AS SALES_REP_ID_Secondary,
    SALESMAN.SMNAME AS SMNAME_SalesmanName
FROM 
    ARCUST ARCUST,
    SALESMAN SALESMAN
WHERE 
    ARCUST.CISMD1 = SALESMAN.SMDIST
    AND ARCUST.CISLM1 = SALESMAN.SMSMAN
ORDER BY 
    ARCUST.CALPHA


/*****************************************
11. SALES REPRESENTATIVES
*****************************************/
--SalesAnalysisQuery_
--Customer-Summary1
-- Lists all sales reps by code and name
-- Tables: SALESMAN = Sales rep
SELECT DISTINCT 
    smdist * 100 + smsman AS SALES_REP_ID_SalesmanCode,
    SALESMAN.SMNAME AS SMNAME_SalesmanName
FROM 
    SALESMAN SALESMAN


/*****************************************
12. INVENTORY
*****************************************/
--SalesAnalysisQuery_
--QueryFromMetalNet1
-- Retrieves detailed inventory data per item for export or dashboard integration.
-- Table: ITEMONHD = Inventory On Hand
SELECT 
    IOITEM AS IOITEM_ItemNumber,
    IOQOH AS IOQOH_QuantityOnHand,
    IOROH AS IOROH_ROPHeader,
    IOBOMI AS IOBOMI_BOMItem,
    IOQOR AS IOQOR_QuantityOnOrderRequired,
    IOQOO AS IOQOO_QuantityOnOrder,
    IOQOOR AS IOQOOR_OtherOrderQuantity,
    IOFCST AS IOFCST_ForecastQty,
    IOBUY AS IOBUY_BuyerCode,
    IODOSC AS IODOSC_DaysOnShelf,
    IOCOMP AS IOCOMP_CompanyCode,
    IORECD AS IORECD_RecordStatus,
    IODIST AS IODIST_DistributionCode,

    IOQIT AS IOQIT_QuantityInTransit,
    IOQHLD AS IOQHLD_QuantityOnHold,
    IOQCOL AS IOQCOL_QuantityCommitted,
    IOROR AS IOROR_ROPReorder,
    IOROO AS IOROO_ROPOrderOpen,
    IOROOR AS IOROOR_ROPOrderOther,
    IORIT AS IORIT_ROPItemThreshold,
    IORIQC AS IORIQC_ROPQualityControlQty,
    IOBOMC AS IOBOMC_BOMCost,
    IOLCCC AS IOLCCC_LastCountCentury,
    IOLCYY AS IOLCYY_LastCountYear,
    IOLCMM AS IOLCMM_LastCountMonth,
    IOLCDD AS IOLCDD_LastCountDay,
    IOCUOM AS IOCUOM_CountUOM,
    IOACST AS IOACST_AverageCost,
    IORCST AS IORCST_RecentCost,
    IORLCK AS IORLCK_ReorderLock,
    IOSCST AS IOSCST_StandardCost,
    IOSCCC AS IOSCCC_StdCostCentury,
    IOSCYY AS IOSCYY_StdCostYear,
    IOSCMM AS IOSCMM_StdCostMonth,
    IOSCDD AS IOSCDD_StdCostDay,
    IODOSL AS IODOSL_DaysOnShelfLast,
    IOMNRQ AS IOMNRQ_MinReorderQty,
    IOTORQ AS IOTORQ_TotalReorderQty,
    IOPYIB AS IOPYIB_PriorYearInbound,
    IOCYIB AS IOCYIB_CurrentYearInbound,
    IOCYIU AS IOCYIU_CurrentYearIssued,
    IOITST AS IOITST_ItemStatus,
    IOPLVL AS IOPLVL_PlanningLevel,
    IOBGIN AS IOBGIN_BeginningInventory,
    IOMNBL AS IOMNBL_MinimumBalance,
    IOROPT AS IOROPT_ReorderPoint,
    IOROPL AS IOROPL_ROPLevel,
    IOROQT AS IOROQT_ROPQty,
    IOLDTM AS IOLDTM_LastTransactionMonth,
    IOBGIT AS IOBGIT_BeginningItemQty,
    IOROFC AS IOROFC_ReorderForecast,
    IOSSTK AS IOSSTK_SafetyStock,
    IOLDTL AS IOLDTL_LastDetailTrans,
    IOINVC AS IOINVC_InvoiceCount,
    IOMTST AS IOMTST_MaterialStatus,
    IODISC AS IODISC_DiscontinuedFlag,
    IOOWNF AS IOOWNF_OwnedFlag,
    IONSDC AS IONSDC_NeedsCountFlag,
    IO1RCT AS IO1RCT_FirstReceiptDate,
    IOTOPP AS IOTOPP_TopPickFlag,
    IOPMON AS IOPMON_PlanningMonth,
    IOLOCC AS IOLOCC_LocationCodeCentury,
    IOLOYY AS IOLOYY_LocationCodeYear,
    IOLOMM AS IOLOMM_LocationCodeMonth,
    IOLODD AS IOLODD_LocationCodeDay,
    IO1ACQ AS IO1ACQ_FirstAcquisitionDate
FROM 
    ITEMONHD ITEMONHD
/*****************************************
14. SALES ORDERS
*****************************************/
--SalesAnalysisQuery_
--SalesOrders
-- Provides detailed sales orders including item specs, pricing, weights, and rep info.
-- Tables: OEOPNORD, OEDETAIL, ARCUST, SALESMAN, 
-- SLSDSCOV - sales discount coverage
-- Fields:
--   Includes ODCRTD = Created date, ODITEM = Item, ODTPCS = Pieces, ODPRCC = Price charged
SELECT 
    oddist * 1000000 + odordr AS ORDER_KEY_DistributionOrderID,
    SALESMAN.SMNAME AS SMNAME_SalesmanName,
    OEOPNORD.OOTYPE AS OOTYPE_OrderType,
    odcdis * 100000 + odcust AS CUSTOMER_KEY_DistributionCustomerID,
    ARCUST.CALPHA AS CALPHA_CustomerName,
    OOICC * 1000000 + OOIYY * 10000 + OOIMM * 100 + OOIDD AS ORDER_DATE_TransactionDate,
    OEDETAIL.ODITEM AS ODITEM_ItemNumber,
    OEDETAIL.ODSIZ1 AS ODSIZ1_SizeSpecification1,
    OEDETAIL.ODSIZ2 AS ODSIZ2_SizeSpecification2,
    OEDETAIL.ODSIZ3 AS ODSIZ3_SizeSpecification3,
    OEDETAIL.ODCRTD AS ODCRTD_CreationDate,
    SLSDSCOV.DXDSC2 AS DXDSC2_DiscountDescription,
    OEDETAIL.ODTFTS AS ODTFTS_TotalFeetShipped,
    OEDETAIL.ODTLBS AS ODTLBS_TotalPoundsShipped,
    OEDETAIL.ODTPCS AS ODTPCS_TotalPiecesShipped,
    OEDETAIL.ODSLSX AS ODSLSX_ExtendedSalesAmount,
    OEDETAIL.ODFRTS AS ODFRTS_FreightCharge,
    OEDETAIL.ODCSTX AS ODCSTX_ItemCost,
    OEDETAIL.ODPRCC AS ODPRCC_UnitPriceCharged,
    OEDETAIL.ODADCC AS ODADCC_AdditionalCharges,
    OEDETAIL.ODWCCS AS ODWCCS_DiscountedSalesTotal,
    ARCUST.CSTAT AS CSTAT_CustomerState,
    ARCUST.CCTRY AS CCTRY_CustomerCountry
FROM 
    ARCUST ARCUST,
    OEDETAIL OEDETAIL,
    OEOPNORD OEOPNORD,
    SALESMAN SALESMAN,
    SLSDSCOV SLSDSCOV
WHERE 
    OEDETAIL.ODDIST = OEOPNORD.OODIST
    AND OEDETAIL.ODDIST = SLSDSCOV.DXDIST
    AND OEDETAIL.ODMLIN = SLSDSCOV.DXMLIN
    AND OEDETAIL.ODORDR = OEOPNORD.OOORDR
    AND OEDETAIL.ODORDR = SLSDSCOV.DXORDR
    AND OEOPNORD.OOCDIS = ARCUST.CDIST
    AND OEOPNORD.OOCUST = ARCUST.CCUST
    AND OEOPNORD.OOISMD = SALESMAN.SMDIST
    AND OEOPNORD.OOISMN = SALESMAN.SMSMAN
    AND OEOPNORD.OOTYPE IN ('A', 'B')
    AND OEOPNORD.OORECD = 'W'
    AND OOIYY = 25 AND OOIMM = 2
    
/*****************************************
15. SALES ANALYSIS (HEATH TREATING) USELESS.. ITS EMPTY
*****************************************/
--SalesAnalysisQuery_
--SPO (Service Purchase Order)
-- Links sales orders with external services (e.g. heat treating) through SPHEADER.
-- Tables: OEOPNORD, OEDETAIL, ARCUST, SALESMAN, SPHEADER

-- =============================================
-- TABLE: SPHEADER (Service Purchase Header)
-- Description: Links external service orders (e.g. heat treating, machining)
--              to sales orders. Provides PO reference, service vendor, and job tracking.
-- =============================================

SELECT 
    OEDETAIL.ODDIST * 1000000 + OEDETAIL.ODORDR AS SalesOrderID,
    SALESMAN.SMNAME AS SalespersonName,
    OEOPNORD.OOTYPE AS OrderType,
    OEDETAIL.ODCDIS * 100000 + OEDETAIL.ODCUST AS CustomerID,
    ARCUST.CALPHA AS CustomerName,
    OOICC * 100 + OOIYY AS CenturyYear,
    OEOPNORD.OOIMM AS OrderMonth,
    OEOPNORD.OOIDD AS OrderDay,
    OEDETAIL.ODITEM AS ItemCode,
    SPHEADER.BSCUST AS ServiceVendorID,       -- <- substitute for BSSVEN
    SPHEADER.BSREF# AS ServicePO              -- <- substitute for BSSPS#
FROM 
    OEDETAIL
    INNER JOIN OEOPNORD ON OEDETAIL.ODDIST = OEOPNORD.OODIST AND OEDETAIL.ODORDR = OEOPNORD.OOORDR
    INNER JOIN ARCUST ON OEOPNORD.OOCDIS = ARCUST.CDIST AND OEOPNORD.OOCUST = ARCUST.CCUST
    INNER JOIN SALESMAN ON OEOPNORD.OOISMD = SALESMAN.SMDIST AND OEOPNORD.OOISMN = SALESMAN.SMSMAN
    INNER JOIN SPHEADER ON OEDETAIL.ODDIST = SPHEADER.BSDIST AND OEDETAIL.ODORDR = SPHEADER.BSORDR
WHERE 
    OEOPNORD.OOTYPE IN ('A', 'B') AND 
    OEOPNORD.OORECD = 'W' AND 
    OEDETAIL.ODDIST = 1 AND 
    OEDETAIL.ODORDR > ?;

/*****************************************
*****************************************/
--Shipmast_
--QueryfromMetalNet
-- Retrieves detailed shipment records for logistics and freight audit purposes.
-- Table: SHIPMAST = Shipment Master (weights, costs, UOMs, destinations)
--USE SigmaTB;
--SELECT TOP * FROM SHIPMAST SHIPMAST
--WHERE (SHIPMAST.SHORDN>950000)


USE SigmaTB;

SELECT TOP 100
    SHRECD AS SHRECD_Shipping_record,
    SHCOMP AS SHCOMP_Company_code,
    SHDIST AS SHDIST_District,
    SHORDN AS SHORDN_Order,
    SHCORD AS SHCORD_Customer_Order,
    SHOREL AS SHOREL_Order_Release,
    SHITEM AS SHITEM_ITEM,
    SHMDIF AS SHMDIF_Modification,
    SHTOPP AS SHTOPP_Priority,
    SHTYPE AS SHTYPE_Type,
    SHPFLG AS SHPFLG_Flag,
    SHCOFL AS SHCOFL_CompanyFlag,
    SHSCRP AS SHSCRP_Scrap,
    SHCUTC AS SHCUTC_Cut_number,
    SHIPCC AS SHIPCC_Century,
    SHIPYY AS SHIPYY_Year,
    SHIPMM AS SHIPMM_Month,
    SHIPDD AS SHIPDD_Day,
    SHRFLG AS SHRFLG_Return_flag,
    SHSHAP AS SHSHAP_Shape,
    SHCLS3 AS SHCLS3_Class_3,
    SHLDIS AS SHLDIS_Load_discount,
    SHINSM AS SHINSM_Insurance,
    SHSQTY AS SHSQTY_Shipped_quantity,
    SHUOM AS SHUOM_Unit_of_Measure,
    SHBQTY AS SHBQTY_Base_quantity,
    SHBUOM AS SHBUOM_Base_Unit_of_Measure,
    SHBINC AS SHBINC_Base_unit_increment,
    SHOQTY AS SHOQTY_Original_quantity,
    SHOUOM AS SHOUOM_Original_Unit_of_Measure,
    SHOINC AS SHOINC_Original_unit_increment,
    SHTLBS AS SHTLBS_Total_pounds,
    SHTPCS AS SHTPCS_Total_pieces,
    SHTFTS AS SHTFTS_Total_feet,
    SHTSFT AS SHTSFT_Total_feet,
    SHTMTR AS SHTMTR_Total_meters,
    SHTKG AS SHTKG_Total_kilograms,
    SHPRCG AS SHPRCG_Pricing_category,
    SHHAND AS SHHAND_Handling_code,
    SHCDIS AS SHCDIS_Customer_discount,
    SHCUST AS SHCUST_Customer_number,
    SHTERR AS SHTERR_Territory_code,
    SHOUTS AS SHOUTS_Outsource_flag,
    SHLINE AS SHLINE_Line,
    SHORCC AS SHORCC_OrigCentury,
    SHORYY AS SHORYY_Order_Year,
    SHORMM AS SHORMM_Order_Month,
    SHORDD AS SHORDD_Order_Day,
    SHPRCC AS SHPRCC_Pricing_Company,
    SHPRYY AS SHPRYY_Pricing_Year,
    SHPRMM AS SHPRMM_Pricing_Month,
    SHPRDD AS SHPRDD_Pricing_Day,
    SHIVCC AS SHIVCC_Invoice_Company_Code,
    SHIVYY AS SHIVYY_Invoice_Year,
    SHIVMM AS SHIVMM_Invoice_Month,
    SHIVDD AS SHIVDD_Invoice_Day,
    SHMSLS AS SHMSLS_Main_Sales,
    SHMSLD AS SHMSLD_Main_Sales_Discount,
    SHFSLS AS SHFSLS_Final_Sales,
    SHFSLD AS SHFSLD_Final_Sales_Discount,
    SHPSLS AS SHPSLS_Promotional_Sales,
    SHPSLD AS SHPSLD_Promotional_Sales_Discount,
    SHOSLS AS SHOSLS_Other_Sales,
    SHOSLD AS SHOSLD_Other_Sales_Discount,
    SHDSLS AS SHDSLS_Discounted_Sales,
    SHDSLD AS SHDSLD_Discounted_Sales_Discount,
    SHMCSS AS SHMCSS_Main_Cost_Start,
    SHMCSD AS SHMCSD_Main_Cost_Discount,
    SHFISS AS SHFISS_Final_Issued_Sales,
    SHFISD AS SHFISD_Final_Issued_Discount,
    SHFOSS AS SHFOSS_Final_Other_Sales,
    SHFOSD AS SHFOSD_Final_Other_Sales_Discount,
    SHFSFS AS SHFSFS_Final_Settlement_Sales,
    SHFSFD AS SHFSFD_Final_Settlement_Discount,
    SHPCSS AS SHPCSS_Price_Calculation_Start_Sales,
    SHPCSD AS SHPCSD_Price_Calculation_Discount,
    SHOCSS AS SHOCSS_Other_Cost_Start_Sales,
    SHOCSD AS SHOCSD_Other_Cost_Discount,
    SHADBS AS SHADBS_Additional_Base_Sales,
    SHADBD AS SHADBD_Additional_Base_Discount,
    SHOPBS AS SHOPBS_Optional_Base_Sales,
    SHOPBD AS SHOPBD_Optional_Base_Discount,
    SHIAJS AS SHIAJS_Inventory_Adjustment_Sales,
    SHIAJD AS SHIAJD_Inventory_Adjustment_Discount,
    SHSLSS AS SHSLSS_Sales_Ledger_Summary_Sales,
    SHSLSD AS SHSLSD_Sales_Ledger_Discount,
    SHSWGS AS SHSWGS_Swaged_Goods_Sales,
    SHSWGD AS SHSWGD_Swaged_Goods_Discount,
    SHADPC AS SHADPC_Additional_Processing_Cost,
    SHUNSP AS SHUNSP_Unshipped_Quantity_,
    SHUUOM AS SHUUOM_Unit_of_Measure,
    SHSAFL AS SHSAFL_Sales_Account_Flag,
    SHSACC AS SHSACC_Sales_Account_Code,
    SHSAYY AS SHSAYY_Sales_Accounting_Year,
    SHSAMM AS SHSAMM_Sales_Accounting_Month,
    SHSADD AS SHSADD_Sales_Accounting_Day,
    SHFRGH AS SHFRGH_Freight_Cost,
    SHSCDL AS SHSCDL_Scheduled_Load_Lenght,
    SHSCLB AS SHSCLB_Scheduled_Load_Pounds,
    SHSCKG AS SHSCKG_Scheduled_Load_Kg,
    SHDBDC AS SHDBDC_TODO,
    SHTRCK AS SHTRCK_Truck_Route,
    SHODES AS SHODES_Order_designation_Code,
    SHSHOP AS SHSHOP_Shop_OLD,
    SHSHTO AS SHSHTO_CUSTOMER_SHIP_TO,
    SHBCTY AS SHBCTY_BILL-TO_COUNTRY,
    SHSCTY AS SHSCTY_SHIP-TO_COUNTRY,
    SHTMPS AS SHTMPS_TEMP_SHIP_TO,
    SHSTER AS SHSTER_Sale_Territory,
    SHTRAD AS SHTRAD_Customer_Trade,
    SHBPCC AS SHBPCC_Bus_Potential_Class,
    SHEEC AS SHEEC_EEC_Code,
    SHSEC AS SHSEC_Sector_Code,
    SHITYP AS SHITYP_Invoice_Type,
    SHDPTI AS SHDPTI_In_Sales_Dept,
    SHDPTO AS SHDPTO_Out_Sales_Dept,
    SHDSTO AS SHDSTO_Orig_cust_dist#,
    SHCSTO AS SHCSTO_Orig_cust#,
    SHSMDO AS SHSMDO_Orig_Slsmn_Dist,
    SHSLMO AS SHSLMO_Orig_Slsmn,
    SHICMP AS SHICMP_Inv_Comp,
    SHADR1 AS SHADR1_ADDRESS_ONE,
    SHADR2 AS SHADR2_ADDRESS_TWO,
    SHADR3 AS SHADR3_ADDRESS_THREE,
    SHCITY AS SHCITY_CITY_25_POS,
    SHSTAT AS SHSTAT_State_Code,
    SHZIP AS SHZIP_Zip_Code,
    SHJOB AS SHJOB_Job_Name
FROM SHIPMAST
WHERE SHORDN > 950000;
