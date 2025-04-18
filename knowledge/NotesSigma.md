GLTRANS
    - PK, FK
        - GLACCT            Account number          1501000000
        - GLBTCH            Batch number            36834
        - GLREF             Reference number        50572
        - GLTRNT            Transaction type        IA
        - GLTRN#            Transaction number      518-407
    - VALUES                                        
        - GLAMT             Amount                  454.11
        - GLAMTQ            Amount queries          -454.11

----------------------------------------------------------------
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
        - SHMSLS	Material Sales Stock
        - SHMSLD	Matl Sales Direct
        - SHFSLS	Frght Sales Stock
        - SHFSLD	Frght Sales Direct
        - SHPSLS	Proc Sales Stock
        - SHPSLD	Process Sales Direct
        - SHOSLS	Other Sales Stock
        - SHOSLD	Other  Sales Direct
        - SHDSLS	Discount Sales Stock
        - SHDSLD	Discnt Sales Direct
        - SHMCSS	Material Cost Stock
        - SHMCSD	Material Cost Direct
        - SHSLSS	Sales Qty Stock
        - SHSLSD	Sales Qty Direct
        - SHSWGS	Sales Weight Stock
        - SHSWGD	Sales Weight Direct
        - SHADPC	Adjusted GP%
        - SHUNSP	UNIT PRICE
        - SHUUOM	Unit Selling Price UOM
        - SHSCDL	Actual Scrap Dollars
        - SHSCLB	Actual Scrap LBS
        - SHSCKG	Actual Scrap KGS 
        - SHTRCK	Truck Route
        - SHBCTY	BILL-TO COUNTRY
        - SHSCTY	SHIP-TO COUNTRY
        - SHDPTI	In Sales Dept
        - SHDPTO	Out Sales Dept
        - SHCSTO	Orig cust#
        - SHADR1	ADDRESS ONE
        - SHADR2	ADDRESS TWO
        - SHADR3	ADDRESS THREE
        - SHCITY	CITY 25 POS
        - SHSTAT	State Code
        - SHZIP	Zip Code





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
