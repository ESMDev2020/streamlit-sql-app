--Monitor Performance
SELECT processed, COUNT(*) 
FROM #processed_columns 
GROUP BY processed;

SELECT TOP 100 * FROM [mrs].[z_inferred_relationships];



-- Check which tables have been processed (by looking at results)
SELECT DISTINCT source_table 
FROM [mrs].[z_inferred_relationships]
ORDER BY source_table;

229
