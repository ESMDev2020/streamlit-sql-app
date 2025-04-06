SELECT TOP (100) 
IOITEM,
IOQOH,
IOQOO,
IOACST,
IOBPRC
FROM [SigmaTB].[dbo].[ITEMONHD]

UNION ALL

SELECT 
    'Total' AS IOITEM,
    null as IOQOH,
    null as IOQOO,
    null as IOACST,
    CAST(COUNT(*) AS VARCHAR(10)) AS IOBPRC
FROM [SigmaTB].[dbo].[ITEMONHD];


select   top 10
from ITEMHIST
where IHITEM = '50002'

select   top 10 *
from ITEMMAST

select   top 30 *
from MPDETAIL

select   top 30 *
from oedetail

select top 30 * from OEOPNORD;
select top 30 * from PODETAIL;
select top 30 * from itemtag;

select top 30 * from  ARCUST

select top 30 * from  APVEND

select top 30 * from  ITEMHIST

select top 30 * from  ITEMONHD

select top 30 * from OEOPNORD