USE SigmaTB;
GO

select 
	e.TableGroupName, e.TableCode, e.TableDescription,
	r.ColumnPK, r.columncode, r.LowestValue, r.HighestValue
FROM 
	[mrs].[01_AS400_MSSQL_Equivalents] e
LEFT JOIN
	[mrs].[PKRangeResults] r
ON
	r.tablecode = e.TableCode
GROUP BY 
	e.TableGroupName, e.TableCode, e.TableDescription,
	r.ColumnPK, r.columncode, r.LowestValue, r.HighestValue
ORDER BY
	TableGroupName ASC, ColumnPK desc, TableCode ASC,  columncode asc




