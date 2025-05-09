/*****************************************
*****************************************/
--ROP_query_
-- Price	
--Comment about the type of data it will retrieve
        SELECT 'price', [ITEMONHD].[IOITEM], [ITEMONHD].[IOBPRC]  
        FROM [ITEMONHD] [ITEMONHD];


/*****************************************
*****************************************/
--ROP_query_
--Material Processing	
SELECT 'Material Processing', [MPDETAIL].[MDORDR], [APVEND].[VVNDR], [APVEND].[VALPHA], [MPDETAIL].[MDCLOS], [MPDETAIL].[MDITEM], [MPDETAIL].[MDCRTD], [mdrqcc]*1000000+[mdrqyy]*10000+[mdrqmm]*100+[mdrqdd], [MPDETAIL].[MDOQTY], [MPDETAIL].[MDOUOM], [MPDETAIL].[MDIQTY]
FROM [APVEND] [APVEND], [MPDETAIL] [MPDETAIL]
WHERE [APVEND].[VCOMP] = [MPDETAIL].[MDCOMP] AND [APVEND].[VVNDR] = [MPDETAIL].[MDVNDR]
ORDER BY [MPDETAIL].[MDITEM], [MPDETAIL].[MDORDR] DESC

USE SigmaTB;
GO

SELECT 'Material Procesing Order Detail', [Material Processing Order Detail].[MDORDR], [Vendor Master File].[Vendor #], [Vendor Master File].[Vendor Alpha Search], [Material Processing Order Detail].[MDCLOS], [Material Processing Order Detail].[MDITEM], [Material Processing Order Detail].[MDCRTD], [REQUESTED SHIP CENTURY]*1000000+[REQUESTED SHIP YEAR]*10000+[REQUESTED SHIP MONTH]*100+[REQUESTED SHIP DAY], [Material Processing Order Detail].[MDOQTY], [Material Processing Order Detail].[MDOUOM], [Material Processing Order Detail].[MDIQTY]FROM [Vendor Master File] [Vendor Master File], [Material Processing Order Detail] [Material Processing Order Detail]WHERE [Vendor Master File].[COMPANY NUMBER] = [Material Processing Order Detail].[COMPANY NUMBER] AND [Vendor Master File].[Vendor #] = [Material Processing Order Detail].[Vendor #]
ORDER BY [Material Processing Order Detail].[MDITEM], [Material Processing Order Detail].[MDORDR] DESC


/*****************************************
*****************************************/
--ROP_query_
--PO query	
SELECT 'Purchase order', [PODETAIL].[BDPONO], [PODETAIL].[BDVNDR], [APVEND].[VNAME], [PODETAIL].BDRECD, [PODETAIL].BDITEM, [PODETAIL].BDCRTD, [bdrpcc]*1000000+[bdrpyy]*10000+[bdrpmm]*100+[bdrpdd], [PODETAIL].[BDOQOO], [PODETAIL].[BDIUOM], [PODETAIL].[BDCQOO], [PODETAIL].[BDOOQ], [PODETAIL].[BDTIQR], [bdpocc]*1000000+[bdpoyy]*10000+[bdpomm]*100+[bdpodd], [bdrccc]*1000000+[bdrcyy]*10000+[bdrcmm]*100+[bdrcdd]
FROM [PODETAIL] LEFT OUTER JOIN [APVEND] ON [PODETAIL].[BDVNDR] = [APVEND].[VVNDR]
WHERE ([PODETAIL].[BDITEM] Between '50000' And '99998')
ORDER BY [PODETAIL].[BDITEM], [PODETAIL].[BDPONO] DESC

/*****************************************
*****************************************/
----ROP_query_
--ROP Query	
SELECT 'ROP query', [ITEMMAST].[IMFSP2], [ITEMMAST].[IMITEM], [ITEMMAST].[IMSIZ1], [ITEMMAST].[IMSIZ2], [ITEMMAST].[IMSIZ3], [ITEMMAST].[IMDSC2], [ITEMMAST].[IMWPFT], [ITEMONHD].[IOACST], [ITEMONHD].[IOQOH], [ITEMONHD].[IOQOO], [IOQOR]+[IOQOOR], [ITEMMAST].[IMDSC1], [ITEMMAST].[IMWUOM], [ITEMMAST].[IMCSMO]
FROM [ITEMMAST] [ITEMMAST], [ITEMONHD] [ITEMONHD]
WHERE [ITEMONHD].[IOITEM] = [ITEMMAST].[IMITEM] AND (([ITEMMAST].[IMRECD]='A') AND ([ITEMMAST].[IMITEM] Between '49999' And '90000'))
ORDER BY [ITEMMAST].[IMFSP2]

/*****************************************
*****************************************/
--ROP_query_
--Sales Data	
        SELECT 'Sales data', [OEOPNORD].[OORECD], [OEDETAIL].[ODTYPE], [OEDETAIL].[ODITEM], [OEDETAIL].[ODORDR], [OEOPNORD].[OOCUST], [ARCUST].[CALPHA], [OEDETAIL].[ODTLBS], [OEDETAIL].[ODTFTS], [OEOPNORD].[OOOCC]*1000000 + [OEOPNORD].[OOOYY]*10000 + [OEOPNORD].[OOOMM]*100 + [OEOPNORD].[OOODD], [ARCUST].[CSMDI1]*100 + [ARCUST].[CSLMN1]  
        FROM [ARCUST] [ARCUST], [OEDETAIL] [OEDETAIL], [OEOPNORD] [OEOPNORD]  
        WHERE [OEDETAIL].[ODORDR] = [OEOPNORD].[OOORDR] AND [OEOPNORD].[OOCUST] = [ARCUST].[CCUST] AND ([OEOPNORD].[OORECD] = 'A' AND [OEDETAIL].[ODTYPE] IN ('A', 'C'))  
        ORDER BY [OEDETAIL].[ODITEM];



/*****************************************
*****************************************/
--ROP_query_
--Tag Query	
        SELECT 'TAG query', [ITEMTAG].[ITITEM], [ITEMTAG].[ITTAG], [ITEMTAG].[ITTDES], [ITEMTAG].[ITLNTH], [ITEMTAG].[ITTPCS], [ITEMTAG].[ITHEAT], [ITEMTAG].[ITV301], [ITEMTAG].[ITLOCT], [ITEMTAG].[ITTQTY], [ITEMTAG].[ITRQTY], [ITEMMAST].[IMFSP2]  
        FROM [ITEMMAST] [ITEMMAST], [ITEMTAG] [ITEMTAG]  
        WHERE [ITEMTAG].[ITITEM] = [ITEMMAST].[IMITEM] AND ([ITEMTAG].[ITRECD] = 'A' AND [ITEMTAG].[ITITEM] > '49999')  
        ORDER BY [ITEMTAG].[ITITEM], [ITEMTAG].[ITHEAT], [ITEMTAG].[ITV301], [ITEMTAG].[ITLNTH];



/*****************************************
*****************************************/
-- ROP_query_
-- Usage Query	
-- This query retrieves historical item usage data based on transaction dates and item ranges.
        SELECT 'Usage query', [ITEMHIST].[IHITEM], [ITEMHIST].[IHTRNT], [ITEMHIST].[IHTRN#], [ITEMHIST].[IHVNDR], [ITEMHIST].[IHCUST], [ITEMHIST].[IHTRYY], [ITEMHIST].[IHTRMM], [ITEMHIST].[IHTRDD], [ITEMHIST].[IHTQTY]  
        FROM [ITEMHIST] [ITEMHIST]  
        WHERE ([ITEMHIST].[IHTRCC]*1000000 + [ITEMHIST].[IHTRYY]*10000 + [ITEMHIST].[IHTRMM]*100 + [ITEMHIST].[IHTRDD] > ?) AND ([ITEMHIST].[IHITEM] BETWEEN '50000' AND '99998')  
        ORDER BY [ITEMHIST].[IHITEM], [ITEMHIST].[IHTRYY], [ITEMHIST].[IHTRMM], [ITEMHIST].[IHTRDD];



/*****************************************
*****************************************/
-- ROP_query_
-- Usage sum query
-- This query calculates the sum of usage for items within a specific range and date.	
        SELECT 'Usage sum query', DISTINCT [ITEMHIST].[IHITEM], [ITEMHIST].[IHTRNT], [ITEMHIST].[IHCUST], [ARCUST].[CALPHA], [ARCUST].[CSMDI1]*100 + [ARCUST].[CSLMN1]  
        FROM [ARCUST] [ARCUST], [ITEMHIST] [ITEMHIST]  
        WHERE [ARCUST].[CCUST] = [ITEMHIST].[IHCUST] AND ([ITEMHIST].[IHTRCC]*1000000 + [ITEMHIST].[IHTRYY]*10000 + [ITEMHIST].[IHTRMM]*100 + [ITEMHIST].[IHTRDD] > ? AND [ITEMHIST].[IHITEM] BETWEEN '50000' AND '99998' AND [ITEMHIST].[IHTRNT] IN ('CR', 'IN'))  
        ORDER BY [ITEMHIST].[IHITEM], [ARCUST].[CALPHA];



/*****************************************
*****************************************/
-- This section of the SQL script is related to sales analysis queries.
-- Specifically, it includes a placeholder for analyzing credit memos (CreditMemos).
-- Credit memos are typically used for financial adjustments, refunds, or corrections in sales transactions.
-- Ensure that the queries in this section are well-defined and optimized for accurate analysis.
--SalesAnalisysQuery_
--CreditMemos	
        SELECT 'credit memos', [OEDETAIL].[ODDIST]*1000000 + [OEDETAIL].[ODORDR], [SALESMAN].[SMNAME], [OEOPNORD].[OOTYPE], [OEDETAIL].[ODCDIS]*100000 + [OEDETAIL].[ODCUST], [ARCUST].[CALPHA], [OEDETAIL].[ODITEM], [OEDETAIL].[ODSIZ1], [OEDETAIL].[ODSIZ2], [OEDETAIL].[ODSIZ3], [OEDETAIL].[ODCRTD], [OEDETAIL].[ODTFTS], [OEDETAIL].[ODTLBS], [OEDETAIL].[ODTPCS], [OEDETAIL].[ODSLSX], [OEDETAIL].[ODFRTS], [OEDETAIL].[ODCSTX], [OEDETAIL].[ODPRCC], [OEDETAIL].[ODADCC], [OEDETAIL].[ODWCCS], [ARCUST].[CSTAT], [ARCUST].[CCTRY], [OEOPNORD].[OOICC]*1000000 + [OEOPNORD].[OOIYY]*10000 + [OEOPNORD].[OOIMM]*100 + [OEOPNORD].[OOIDD], [OEDETAIL].[ODCREF]  
        FROM [ARCUST] [ARCUST], [OEDETAIL] [OEDETAIL], [OEOPNORD] [OEOPNORD], [SALESMAN] [SALESMAN]  
        WHERE [OEDETAIL].[ODDIST] = [OEOPNORD].[OODIST] AND [OEDETAIL].[ODORDR] = [OEOPNORD].[OOORDR] AND [OEOPNORD].[OOCDIS] = [ARCUST].[CDIST] AND [OEOPNORD].[OOCUST] = [ARCUST].[CCUST] AND [OEOPNORD].[OOISMD] = [SALESMAN].[SMDIST] AND [OEOPNORD].[OOISMN] = [SALESMAN].[SMSMAN] AND ([OEOPNORD].[OOTYPE] = 'C' AND [OEOPNORD].[OORECD] = 'W' AND ([OEOPNORD].[OOICC]*10000 + [OEOPNORD].[OOIYY]*100 + [OEOPNORD].[OOIMM] BETWEEN ? AND ?));


/*****************************************
*****************************************/
--SalesAnalisysQuery_
--Customer-Summary	
    SELECT DISTINCT 'customer summary',  [ARCUST].[CDIST]*100000 + [ARCUST].[CCUST], [ARCUST].[CALPHA], [ARCUST].[CLIMIT], [ARCUST].[CISMD1]*100 + [ARCUST].[CISLM1], [ARCUST].[CSMDI1]*100 + [ARCUST].[CSLMN1], [SALESMAN].[SMNAME]  
    FROM [ARCUST] [ARCUST], [SALESMAN] [SALESMAN]  
    WHERE [ARCUST].[CISMD1] = [SALESMAN].[SMDIST] AND [ARCUST].[CISLM1] = [SALESMAN].[SMSMAN]  
    ORDER BY [ARCUST].[CALPHA];



/*****************************************
*****************************************/
--SalesAnalisysQuery_
--Customer-Summary1	
        SELECT DISTINCT 
            'Sales analysis Customer summary', [SALESMAN].[SMDIST]*100 + [SALESMAN].[SMSMAN], 
            [SALESMAN].[SMNAME]
        FROM 
            [SALESMAN] [SALESMAN];


/*****************************************
*****************************************/
--SalesAnalisysQuery_
--QueryFromMetalNet1	
        SELECT 'Sales analysis, query', [ITEMONHD].[IORECD], [ITEMONHD].[IOCOMP], [ITEMONHD].[IODIST], [ITEMONHD].[IOITEM], [ITEMONHD].[IOQOH], [ITEMONHD].[IOQOR], [ITEMONHD].[IOQOO], [ITEMONHD].[IOQOOR], [ITEMONHD].[IOQIT], [ITEMONHD].[IOQHLD], [ITEMONHD].[IOQCOL], [ITEMONHD].[IOROH], [ITEMONHD].[IOROR], [ITEMONHD].[IOROO], [ITEMONHD].[IOROOR], [ITEMONHD].[IORIT], [ITEMONHD].[IORIQC], [ITEMONHD].[IOBOMI], [ITEMONHD].[IOBOMC], [ITEMONHD].[IOLCCC], [ITEMONHD].[IOLCYY], [ITEMONHD].[IOLCMM], [ITEMONHD].[IOLCDD], [ITEMONHD].[IOCUOM], [ITEMONHD].[IOACST], [ITEMONHD].[IORCST], [ITEMONHD].[IORLCK], [ITEMONHD].[IOFCST], [ITEMONHD].[IOSCST], [ITEMONHD].[IOSCCC], [ITEMONHD].[IOSCYY], [ITEMONHD].[IOSCMM], [ITEMONHD].[IOSCDD], [ITEMONHD].[IODOSC], [ITEMONHD].[IODOSL], [ITEMONHD].[IOMNRQ], [ITEMONHD].[IOTORQ], [ITEMONHD].[IOPYIB], [ITEMONHD].[IOCYIB], [ITEMONHD].[IOCYIU], [ITEMONHD].[IOITST], [ITEMONHD].[IOPLVL], [ITEMONHD].[IOBGIN], [ITEMONHD].[IOMNBL], [ITEMONHD].[IOROPT], [ITEMONHD].[IOROPL], [ITEMONHD].[IOROQT], [ITEMONHD].[IOLDTM], [ITEMONHD].[IOBUY], [ITEMONHD].[IOBGIT], [ITEMONHD].[IOROFC], [ITEMONHD].[IOSSTK], [ITEMONHD].[IOLDTL], [ITEMONHD].[IOINVC], [ITEMONHD].[IOMTST], [ITEMONHD].[IODISC], [ITEMONHD].[IOOWNF], [ITEMONHD].[IONSDC], [ITEMONHD].[IO1RCT], [ITEMONHD].[IOTOPP], [ITEMONHD].[IOPMON], [ITEMONHD].[IOLOCC], [ITEMONHD].[IOLOYY], [ITEMONHD].[IOLOMM], [ITEMONHD].[IOLODD], [ITEMONHD].[IO1ACQ], [ITEMONHD].[IOLFB1], [ITEMONHD].[IOLFB2], [ITEMONHD].[IOCMNT], [ITEMONHD].[IOMSLS], [ITEMONHD].[IOYSLS], [ITEMONHD].[IOMCST], [ITEMONHD].[IOYCST], [ITEMONHD].[IOMUNT], [ITEMONHD].[IOYUNT], [ITEMONHD].[IOMWGT], [ITEMONHD].[IOYWGT], [ITEMONHD].[IODLCC], [ITEMONHD].[IODLYY], [ITEMONHD].[IODLMM], [ITEMONHD].[IODLDD], [ITEMONHD].[IOPUOM], [ITEMONHD].[IOCNTP], [ITEMONHD].[IOCNTL], [ITEMONHD].[IOBPRC], [ITEMONHD].[IOBPRL], [ITEMONHD].[IOBPCC], [ITEMONHD].[IOBPYY], [ITEMONHD].[IOBPMM], [ITEMONHD].[IOBPDD], [ITEMONHD].[IOCNTC], [ITEMONHD].[IOCDIS], [ITEMONHD].[IOCUST], [ITEMONHD].[IOMACN], [ITEMONHD].[IOPRCD], [ITEMONHD].[IORUNR], [ITEMONHD].[IORUOM], [ITEMONHD].[IOMEIF], [ITEMONHD].[IOORDI], [ITEMONHD].[IOMDIF], [ITEMONHD].[IOPMCC], [ITEMONHD].[IOPMYY], [ITEMONHD].[IOPMMM], [ITEMONHD].[IOPMDD], [ITEMONHD].[IOPMCD], [ITEMONHD].[IOLRCS], [ITEMONHD].[IOZ], [ITEMONHD].[IOC], [ITEMONHD].[IOD], [ITEMONHD].[IOPCTF], [ITEMONHD].[IOOUOM], [ITEMONHD].[IOMAGA], [ITEMONHD].[IOHURD], [ITEMONHD].[IOATAJ], [ITEMONHD].[IOLPCC], [ITEMONHD].[IOLPYY], [ITEMONHD].[IOLPMM], [ITEMONHD].[IOLPDD], [ITEMONHD].[IOLPUS], [ITEMONHD].[IOLSCC], [ITEMONHD].[IOLSYY], [ITEMONHD].[IOLSMM], [ITEMONHD].[IOLSDD], [ITEMONHD].[IOLSUS], [ITEMONHD].[IOLMCC], [ITEMONHD].[IOLMYY], [ITEMONHD].[IOLMMM], [ITEMONHD].[IOLMDD], [ITEMONHD].[IOLMUS], [ITEMONHD].[IOCLS3], [ITEMONHD].[IOSBCL], [ITEMONHD].[IOSTCL], [ITEMONHD].[IOPUSD], [ITEMONHD].[IOPUSQ], [ITEMONHD].[IOPCST], [ITEMONHD].[IOPSLS], [ITEMONHD].[IOPUNT], [ITEMONHD].[IOPLBS], [ITEMONHD].[IOPATN], [ITEMONHD].[IOMOST], [ITEMONHD].[IOBOMW], [ITEMONHD].[IOAVMS], [ITEMONHD].[IOAVLB], [ITEMONHD].[IOAVOH], [ITEMONHD].[IOAVOS], [ITEMONHD].[IOUSQT], [ITEMONHD].[IOUSDL], [ITEMONHD].[IOYTDL], [ITEMONHD].[IOLIFO], [ITEMONHD].[IOSRCE], [ITEMONHD].[IOSUCC], [ITEMONHD].[IOSUYY], [ITEMONHD].[IOSUMM], [ITEMONHD].[IOSUDD], [ITEMONHD].[IOOPPO], [ITEMONHD].[IOOPPD], [ITEMONHD].[IOTSTR], [ITEMONHD].[IOAVMQ], [ITEMONHD].[IOITDL], [ITEMONHD].[IOITUN], [ITEMONHD].[IORSTK], [ITEMONHD].[IORSMP], [ITEMONHD].[IOHFRR], [ITEMONHD].[IOCORS], [ITEMONHD].[IOTRRS], [ITEMONHD].[IOMPRS], [ITEMONHD].[IOSTOR], [ITEMONHD].[IOASOR], [ITEMONHD].[IOAVG3], [ITEMONHD].[IOAV12], [ITEMONHD].[IOPICC], [ITEMONHD].[IOPIYY], [ITEMONHD].[IOPIMM], [ITEMONHD].[IOPIDD], [ITEMONHD].[IOPDSC], [ITEMONHD].[IOITRM], [ITEMONHD].[IOLPMC], [ITEMONHD].[IOLPML], [ITEMONHD].[IOCPMC], [ITEMONHD].[IOCPML], [ITEMONHD].[IODSPS], [ITEMONHD].[IOSPCD], [ITEMONHD].[IOPRC2], [ITEMONHD].[IOSALE], [ITEMONHD].[IOQQTY], [ITEMONHD].[IOQAC], [ITEMONHD].[IOOELK], [ITEMONHD].[IOMPLK], [ITEMONHD].[IOABCP], [ITEMONHD].[IOANRS], [ITEMONHD].[IOTAX], [ITEMONHD].[IORBCS], [ITEMONHD].[IOTUNA]  
        FROM [ITEMONHD] [ITEMONHD];



/*****************************************
*****************************************/
--SalesAnalisysQuery
--SalesOrders	
        SELECT 'Sales analysis, sales orders', [SHIPMAST].[SHRECD], [SHIPMAST].[SHCOMP], [SHIPMAST].[SHDIST], [SHIPMAST].[SHORDN], [SHIPMAST].[SHCORD], [SHIPMAST].[SHOREL], [SHIPMAST].[SHITEM], [SHIPMAST].[SHMDIF], [SHIPMAST].[SHTOPP], [SHIPMAST].[SHTYPE], [SHIPMAST].[SHPFLG], [SHIPMAST].[SHCOFL], [SHIPMAST].[SHSCRP], [SHIPMAST].[SHCUTC], [SHIPMAST].[SHIPCC], [SHIPMAST].[SHIPYY], [SHIPMAST].[SHIPMM], [SHIPMAST].[SHIPDD], [SHIPMAST].[SHRFLG], [SHIPMAST].[SHSHAP], [SHIPMAST].[SHCLS3], [SHIPMAST].[SHLDIS], [SHIPMAST].[SHINSM], [SHIPMAST].[SHSQTY], [SHIPMAST].[SHUOM], [SHIPMAST].[SHBQTY], [SHIPMAST].[SHBUOM], [SHIPMAST].[SHBINC], [SHIPMAST].[SHOQTY], [SHIPMAST].[SHOUOM], [SHIPMAST].[SHOINC], [SHIPMAST].[SHTLBS], [SHIPMAST].[SHTPCS], [SHIPMAST].[SHTFTS], [SHIPMAST].[SHTSFT], [SHIPMAST].[SHTMTR], [SHIPMAST].[SHTKG], [SHIPMAST].[SHPRCG], [SHIPMAST].[SHHAND], [SHIPMAST].[SHCDIS], [SHIPMAST].[SHCUST], [SHIPMAST].[SHTERR], [SHIPMAST].[SHOUTS], [SHIPMAST].[SHLINE], [SHIPMAST].[SHORCC], [SHIPMAST].[SHORYY], [SHIPMAST].[SHORMM], [SHIPMAST].[SHORDD], [SHIPMAST].[SHPRCC], [SHIPMAST].[SHPRYY], [SHIPMAST].[SHPRMM], [SHIPMAST].[SHPRDD], [SHIPMAST].[SHIVCC], [SHIPMAST].[SHIVYY], [SHIPMAST].[SHIVMM], [SHIPMAST].[SHIVDD], [SHIPMAST].[SHMSLS], [SHIPMAST].[SHMSLD], [SHIPMAST].[SHFSLS], [SHIPMAST].[SHFSLD], [SHIPMAST].[SHPSLS], [SHIPMAST].[SHPSLD], [SHIPMAST].[SHOSLS], [SHIPMAST].[SHOSLD], [SHIPMAST].[SHDSLS], [SHIPMAST].[SHDSLD], [SHIPMAST].[SHMCSS], [SHIPMAST].[SHMCSD], [SHIPMAST].[SHFISS], [SHIPMAST].[SHFISD], [SHIPMAST].[SHFOSS], [SHIPMAST].[SHFOSD], [SHIPMAST].[SHFSFS], [SHIPMAST].[SHFSFD], [SHIPMAST].[SHPCSS], [SHIPMAST].[SHPCSD], [SHIPMAST].[SHOCSS], [SHIPMAST].[SHOCSD], [SHIPMAST].[SHADBS], [SHIPMAST].[SHADBD], [SHIPMAST].[SHOPBS], [SHIPMAST].[SHOPBD], [SHIPMAST].[SHIAJS], [SHIPMAST].[SHIAJD], [SHIPMAST].[SHSLSS], [SHIPMAST].[SHSLSD], [SHIPMAST].[SHSWGS], [SHIPMAST].[SHSWGD], [SHIPMAST].[SHADPC], [SHIPMAST].[SHUNSP], [SHIPMAST].[SHUUOM], [SHIPMAST].[SHSAFL], [SHIPMAST].[SHSACC], [SHIPMAST].[SHSAYY], [SHIPMAST].[SHSAMM], [SHIPMAST].[SHSADD], [SHIPMAST].[SHFRGH], [SHIPMAST].[SHSCDL], [SHIPMAST].[SHSCLB], [SHIPMAST].[SHSCKG], [SHIPMAST].[SHDBDC], [SHIPMAST].[SHTRCK], [SHIPMAST].[SHODES], [SHIPMAST].[SHSHOP], [SHIPMAST].[SHSHTO], [SHIPMAST].[SHBCTY], [SHIPMAST].[SHSCTY], [SHIPMAST].[SHTMPS], [SHIPMAST].[SHSTER], [SHIPMAST].[SHTRAD], [SHIPMAST].[SHBPCC], [SHIPMAST].[SHEEC], [SHIPMAST].[SHSEC], [SHIPMAST].[SHITYP], [SHIPMAST].[SHDPTI], [SHIPMAST].[SHDPTO], [SHIPMAST].[SHDSTO], [SHIPMAST].[SHCSTO], [SHIPMAST].[SHSMDO], [SHIPMAST].[SHSLMO], [SHIPMAST].[SHICMP], [SHIPMAST].[SHADR1], [SHIPMAST].[SHADR2], [SHIPMAST].[SHADR3], [SHIPMAST].[SHCITY], [SHIPMAST].[SHSTAT], [SHIPMAST].[SHZIP], [SHIPMAST].[SHJOB]  
        FROM [SHIPMAST] [SHIPMAST]  
        WHERE [SHIPMAST].[SHORDN] > 950000;


/*****************************************
*****************************************/
--SalesAnalisysQuery_
--SPO	
SELECT 'Sales analysis, SPO', [OEDETAIL].[ODDIST]*1000000 + [OEDETAIL].[ODORDR], [SALESMAN].[SMNAME], [OEOPNORD].[OOTYPE], [OEDETAIL].[ODCDIS]*100000 + [OEDETAIL].[ODCUST], [ARCUST].[CALPHA], [OEOPNORD].[OOICC]*100 + [OEOPNORD].[OOIYY], [OEOPNORD].[OOIMM], [OEOPNORD].[OOIDD], [OEDETAIL].[ODITEM], [SPHEADER].[BSSVEN], [SPHEADER].[BSSPS#]
FROM [ARCUST] [ARCUST], [OEDETAIL] [OEDETAIL], [OEOPNORD] [OEOPNORD], [SALESMAN] [SALESMAN], [SPHEADER] [SPHEADER]
WHERE [OEDETAIL].[ODDIST] = [OEOPNORD].[OODIST] AND [OEDETAIL].[ODORDR] = [OEOPNORD].[OOORDR] AND [OEOPNORD].[OOCDIS] = [ARCUST].[CDIST] AND [OEOPNORD].[OOCUST] = [ARCUST].[CCUST] AND [OEOPNORD].[OOISMD] = [SALESMAN].[SMDIST] AND [OEOPNORD].[OOISMN] = [SALESMAN].[SMSMAN] AND [OEDETAIL].[ODDIST] = [SPHEADER].[BSDIST] AND [OEDETAIL].[ODORDR] = [SPHEADER].[BSORDR] AND ([OEOPNORD].[OOTYPE] IN ('A','B') AND [OEOPNORD].[OORECD] = 'W' AND [OEDETAIL].[ODDIST] = 1 AND [OEDETAIL].[ODORDR] > ?);

/*****************************************
*****************************************/
--Shipmast_
--QueryfromMetalNet	
SELECT 
    'Shipmaster', [SHIPMAST].[SHRECD], [SHIPMAST].[SHCOMP], [SHIPMAST].[SHDIST], [SHIPMAST].[SHORDN], [SHIPMAST].[SHCORD], [SHIPMAST].[SHOREL], [SHIPMAST].[SHITEM], [SHIPMAST].[SHMDIF], [SHIPMAST].[SHTOPP], [SHIPMAST].[SHTYPE], [SHIPMAST].[SHPFLG], [SHIPMAST].[SHCOFL], [SHIPMAST].[SHSCRP], [SHIPMAST].[SHCUTC], [SHIPMAST].[SHIPCC], [SHIPMAST].[SHIPYY], [SHIPMAST].[SHIPMM], [SHIPMAST].[SHIPDD], [SHIPMAST].[SHRFLG], [SHIPMAST].[SHSHAP], [SHIPMAST].[SHCLS3], [SHIPMAST].[SHLDIS], [SHIPMAST].[SHINSM], [SHIPMAST].[SHSQTY], [SHIPMAST].[SHUOM], [SHIPMAST].[SHBQTY], [SHIPMAST].[SHBUOM], [SHIPMAST].[SHBINC], [SHIPMAST].[SHOQTY], [SHIPMAST].[SHOUOM], [SHIPMAST].[SHOINC], [SHIPMAST].[SHTLBS], [SHIPMAST].[SHTPCS], [SHIPMAST].[SHTFTS], [SHIPMAST].[SHTSFT], [SHIPMAST].[SHTMTR], [SHIPMAST].[SHTKG], [SHIPMAST].[SHPRCG], [SHIPMAST].[SHHAND], [SHIPMAST].[SHCDIS], [SHIPMAST].[SHCUST], [SHIPMAST].[SHTERR], [SHIPMAST].[SHOUTS], [SHIPMAST].[SHLINE], [SHIPMAST].[SHORCC], [SHIPMAST].[SHORYY], [SHIPMAST].[SHORMM], [SHIPMAST].[SHORDD], [SHIPMAST].[SHPRCC], [SHIPMAST].[SHPRYY], [SHIPMAST].[SHPRMM], [SHIPMAST].[SHPRDD], [SHIPMAST].[SHIVCC], [SHIPMAST].[SHIVYY], [SHIPMAST].[SHIVMM], [SHIPMAST].[SHIVDD], [SHIPMAST].[SHMSLS], [SHIPMAST].[SHMSLD], [SHIPMAST].[SHFSLS], [SHIPMAST].[SHFSLD], [SHIPMAST].[SHPSLS], [SHIPMAST].[SHPSLD], [SHIPMAST].[SHOSLS], [SHIPMAST].[SHOSLD], [SHIPMAST].[SHDSLS], [SHIPMAST].[SHDSLD], [SHIPMAST].[SHMCSS], [SHIPMAST].[SHMCSD], [SHIPMAST].[SHFISS], [SHIPMAST].[SHFISD], [SHIPMAST].[SHFOSS], [SHIPMAST].[SHFOSD], [SHIPMAST].[SHFSFS], [SHIPMAST].[SHFSFD], [SHIPMAST].[SHPCSS], [SHIPMAST].[SHPCSD], [SHIPMAST].[SHOCSS], [SHIPMAST].[SHOCSD], [SHIPMAST].[SHADBS], [SHIPMAST].[SHADBD], [SHIPMAST].[SHOPBS], [SHIPMAST].[SHOPBD], [SHIPMAST].[SHIAJS], [SHIPMAST].[SHIAJD], [SHIPMAST].[SHSLSS], [SHIPMAST].[SHSLSD], [SHIPMAST].[SHSWGS], [SHIPMAST].[SHSWGD], [SHIPMAST].[SHADPC], [SHIPMAST].[SHUNSP], [SHIPMAST].[SHUUOM], [SHIPMAST].[SHSAFL], [SHIPMAST].[SHSACC], [SHIPMAST].[SHSAYY], [SHIPMAST].[SHSAMM], [SHIPMAST].[SHSADD], [SHIPMAST].[SHFRGH], [SHIPMAST].[SHSCDL], [SHIPMAST].[SHSCLB], [SHIPMAST].[SHSCKG], [SHIPMAST].[SHDBDC], [SHIPMAST].[SHTRCK], [SHIPMAST].[SHODES], [SHIPMAST].[SHSHOP], [SHIPMAST].[SHSHTO], [SHIPMAST].[SHBCTY], [SHIPMAST].[SHSCTY], [SHIPMAST].[SHTMPS], [SHIPMAST].[SHSTER], [SHIPMAST].[SHTRAD], [SHIPMAST].[SHBPCC], [SHIPMAST].[SHEEC], [SHIPMAST].[SHSEC], [SHIPMAST].[SHITYP], [SHIPMAST].[SHDPTI], [SHIPMAST].[SHDPTO], [SHIPMAST].[SHDSTO], [SHIPMAST].[SHCSTO], [SHIPMAST].[SHSMDO], [SHIPMAST].[SHSLMO], [SHIPMAST].[SHICMP], [SHIPMAST].[SHADR1], [SHIPMAST].[SHADR2], [SHIPMAST].[SHADR3], [SHIPMAST].[SHCITY], [SHIPMAST].[SHSTAT], [SHIPMAST].[SHZIP], [SHIPMAST].[SHJOB]
FROM 
    [SHIPMAST] [SHIPMAST]
WHERE 
    [SHIPMAST].[SHORDN] > 950000;


/*****************************************
*****************************************/