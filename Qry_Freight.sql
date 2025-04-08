Use SigmaTB;

SELECT * FROM SalesData;
SELECT count(*) FROM SalesData;

Select * from SalesOrders
select count(*) from SalesOrders
select * from Salesorders where Cast(Invoiced as date) between '01/01/2025' and '12/01/2025'

-- Get the rows
SELECT *
FROM Salesorders
WHERE CONVERT(date, CAST(Invoiced AS CHAR(8)), 112) 
      BETWEEN '2025-01-01' AND '2025-12-01';

-- all sales order detail
SELECT *, CONVERT(date, CAST(Invoiced AS CHAR(8)), 112) AS InvoicedDate
FROM Salesorders
WHERE CONVERT(date, CAST(Invoiced AS CHAR(8)), 112) 
      BETWEEN '2025-02-01' AND '2025-02-28';

--February sales + frt sales total
select sum(sales) + sum([Frt Sales])
FROM Salesorders
WHERE CONVERT(date, CAST(Invoiced AS CHAR(8)), 112) 
      BETWEEN '2025-02-01' AND '2025-02-28';

--February sales total
select sum(sales) as 'Sales', sum(Salesorders.Profit) as 'Gross Profit' 
FROM Salesorders
WHERE CONVERT(date, CAST(Invoiced AS CHAR(8)), 112) 
      BETWEEN '2025-02-01' AND '2025-02-28';




--Lets gonna check if we find the salesorders
-- This is the query from SalesOrder report that populates the salesorder worksheet
SELECT  oddist*1000000+odordr,                      -- Order ID
        SALESMAN.SMNAME,                            -- Sales man name
        OEOPNORD.OOTYPE,                            -- Order type
        odcdis*100000+odcust,                       -- distributor + customer
        ARCUST.CALPHA,                              -- Name of the customer
        OOICC*1000000+OOIYY*10000+OOIMM*100+OOIDD,  -- Cost center + YY, MM, DD
        OEDETAIL.ODITEM,                            -- ITEM
        OEDETAIL.ODSIZ1,                            -- SIZES  
        OEDETAIL.ODSIZ2, 
        OEDETAIL.ODSIZ3, 
        OEDETAIL.ODCRTD,                            -- Order Created Date
        SLSDSCOV.DXDSC2,                            -- Sales Description
        OEDETAIL.ODTFTS,                            -- Feet
        OEDETAIL.ODTLBS,                            -- Pounds
        OEDETAIL.ODTPCS,                            -- Pieces
        OEDETAIL.ODSLSX,                            -- Sales extended???
        OEDETAIL.ODFRTS,                            -- Freight charges   
        OEDETAIL.ODCSTX,                            -- Cost ???
        OEDETAIL.ODPRCC,                            -- Price
        OEDETAIL.ODADCC,                            -- Additional charges
        OEDETAIL.ODWCCS,                            -- Weight cost
        ARCUST.CSTAT,                               -- Customer state
        ARCUST.CCTRY                                -- Customer Country
FROM    S219EAAV.MW4FILE.ARCUST ARCUST,             -- Account Receivable - customer
        S219EAAV.MW4FILE.OEDETAIL OEDETAIL,         -- Order Entry - detail
        S219EAAV.MW4FILE.OEOPNORD OEOPNORD,         -- Order Entry - Order Processing - 
        S219EAAV.MW4FILE.SALESMAN SALESMAN,         -- Salesman
        S219EAAV.MW4FILE.SLSDSCOV SLSDSCOV          -- Distributor
WHERE   OEDETAIL.ODDIST = OEOPNORD.OODIST           
        AND OEDETAIL.ODDIST = SLSDSCOV.DXDIST 
        AND OEDETAIL.ODMLIN = SLSDSCOV.DXMLIN 
        AND OEDETAIL.ODORDR = OEOPNORD.OOORDR 
        AND OEDETAIL.ODORDR = SLSDSCOV.DXORDR 
        AND OEOPNORD.OOCDIS = ARCUST.CDIST 
        AND OEOPNORD.OOCUST = ARCUST.CCUST 
        AND OEOPNORD.OOISMD = SALESMAN.SMDIST 
        AND OEOPNORD.OOISMN = SALESMAN.SMSMAN 
        AND ((OEOPNORD.OOTYPE In ('A','B')) 
        AND (OEOPNORD.OORECD='W') 
        AND (ooicc*10000+ooiyy*100+ooimm Between 20250201 And 20250228))



--Lets gonna try our query in our SQL Server
SELECT top 1
    OEDETAIL.ODDIST * 1000000 + OEDETAIL.ODORDR AS OrderID,
    SALESMAN.SMNAME AS SalesmanName,
    OEOPNORD.OOTYPE AS OrderType,
    OEOPNORD.OOCDIS * 100000 + OEOPNORD.OOCUST AS DistributorCustomer,
    ARCUST.CALPHA AS CustomerName,
    OEOPNORD.OOICC * 1000000 + OEOPNORD.OOIYY * 10000 + OEOPNORD.OOIMM * 100 + OEOPNORD.OOIDD AS OrderDateKey,
    OEDETAIL.ODITEM,
    OEDETAIL.ODSIZ1,
    OEDETAIL.ODSIZ2,
    OEDETAIL.ODSIZ3,
    OEDETAIL.ODCRTD AS OrderCreatedDate,
    SLSDSCOV.DXDSC2 AS SalesDescription,
    OEDETAIL.ODTFTS AS Feet,
    OEDETAIL.ODTLBS AS Pounds,
    OEDETAIL.ODTPCS AS Pieces,
    OEDETAIL.ODSLSX AS ExtendedSales,
    OEDETAIL.ODFRTS AS FreightCharges,
    OEDETAIL.ODCSTX AS Cost,
    OEDETAIL.ODPRCC AS Price,
    OEDETAIL.ODADCC AS AdditionalCharges,
    OEDETAIL.ODWCCS AS WeightCost,
    ARCUST.CSTAT AS CustomerState,
    ARCUST.CCTRY AS CustomerCountry
FROM 
    ARCUST
INNER JOIN OEOPNORD ON 
    OEOPNORD.OOCDIS = ARCUST.CDIST AND 
    OEOPNORD.OOCUST = ARCUST.CCUST
INNER JOIN SALESMAN ON 
    OEOPNORD.OOISMD = SALESMAN.SMDIST AND 
    OEOPNORD.OOISMN = SALESMAN.SMSMAN
INNER JOIN OEDETAIL ON 
    OEDETAIL.ODDIST = OEOPNORD.OODIST AND 
    OEDETAIL.ODORDR = OEOPNORD.OOORDR
INNER JOIN SLSDSCOV ON 
    OEDETAIL.ODDIST = SLSDSCOV.DXDIST AND 
    OEDETAIL.ODORDR = SLSDSCOV.DXORDR AND 
    OEDETAIL.ODMLIN = SLSDSCOV.DXMLIN
WHERE 
    OEOPNORD.OOTYPE IN ('A', 'B') AND
    OEOPNORD.OORECD = 'W' AND
    (OEOPNORD.OOIYY = 25 AND OEOPNORD.OOIMM = 2)


--Lets gonna look for OrderID = Document
--Error. Costs are not right
SELECT 
    OEDETAIL.ODDIST * 1000000 + OEDETAIL.ODORDR AS OrderID,
    SALESMAN.SMNAME AS SalesmanName,
    OEOPNORD.OOTYPE AS OrderType,
    OEOPNORD.OOCDIS * 100000 + OEOPNORD.OOCUST AS DistributorCustomer,
    ARCUST.CALPHA AS CustomerName,
    OEOPNORD.OOICC * 1000000 + OEOPNORD.OOIYY * 10000 + OEOPNORD.OOIMM * 100 + OEOPNORD.OOIDD AS OrderDateKey,
    OEDETAIL.ODITEM,
    OEDETAIL.ODSIZ1,
    OEDETAIL.ODSIZ2,
    OEDETAIL.ODSIZ3,
    OEDETAIL.ODCRTD AS [Size],
    SLSDSCOV.DXDSC2 AS [Specification],
    OEDETAIL.ODTFTS AS Feet,
    OEDETAIL.ODTLBS AS Pounds,
    OEDETAIL.ODTPCS AS Pieces,
    OEDETAIL.ODSLSX AS TotalSales,
    OEDETAIL.ODFRTS AS FreightCharges,
    OEDETAIL.ODCSTX AS MaterialCost,
    OEDETAIL.ODPRCC AS UNKNOWNPrice,
    OEDETAIL.ODADCC AS AdditionalCharges,
    OEDETAIL.ODWCCS AS WeightCost,
    ARCUST.CSTAT AS CustomerState,
    ARCUST.CCTRY AS CustomerCountry
FROM 
    ARCUST
INNER JOIN OEOPNORD ON 
    OEOPNORD.OOCDIS = ARCUST.CDIST AND 
    OEOPNORD.OOCUST = ARCUST.CCUST
INNER JOIN SALESMAN ON 
    OEOPNORD.OOISMD = SALESMAN.SMDIST AND 
    OEOPNORD.OOISMN = SALESMAN.SMSMAN
INNER JOIN OEDETAIL ON 
    OEDETAIL.ODDIST = OEOPNORD.OODIST AND 
    OEDETAIL.ODORDR = OEOPNORD.OOORDR
INNER JOIN SLSDSCOV ON 
    OEDETAIL.ODDIST = SLSDSCOV.DXDIST AND 
    OEDETAIL.ODORDR = SLSDSCOV.DXORDR AND 
    OEDETAIL.ODMLIN = SLSDSCOV.DXMLIN
WHERE 
    (OEDETAIL.ODORDR =  965943 )


select * from OEDETAIL WHERE ORDETAIL.OR