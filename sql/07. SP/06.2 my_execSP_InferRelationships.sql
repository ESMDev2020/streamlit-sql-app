/********************************************************************
EXECUTION PART OF THE INFER RELATIONSHIPS
********************************************************************/
-- Execution of the query (May take 2 hours)
-- Query to monitor progress
-- Queries for reporting
--
--
--Execution of the SP
-- Batch size:		numbert of tables to work on
-- Continue			continue previous or start from scratch. 1-yes, 0-no
-- Debug			1- yes, 0-no


EXEC [mrs].[usp_infer_relationships_batch] @batch_size=400, @continue=0, @debug=0;

--Data review
select * from [mrs].[z_inferred_relationships]


--Monitor Performance
SELECT processed, COUNT(*) 
FROM #processed_columns 
GROUP BY processed;

SELECT TOP 100 * FROM [mrs].[z_inferred_relationships];


/**********************************************************************
Review our reports
**********************************************************************/

-- Basic relationship_________________________________________________________________
SELECT 
    source_table,
    COUNT(*) AS relationship_count,
    STRING_AGG(DISTINCT match_pattern, ', ') AS common_patterns
FROM [mrs].[z_inferred_relationships]
GROUP BY source_table
ORDER BY relationship_count DESC;

-- Most common relationship patterns_________________________________________________________________
SELECT 
    match_pattern,
    COUNT(*) AS pattern_count,
    MIN(source_table + '.' + source_column) AS example_source,
    MIN(target_table + '.' + target_column) AS example_target
FROM [mrs].[z_inferred_relationships]
GROUP BY match_pattern
ORDER BY pattern_count DESC;

-- Potential FK Candidates_________________________________________________________________
SELECT 
    source_table,
    source_column,
    COUNT(DISTINCT target_table) AS linked_tables_count,
    STRING_AGG(DISTINCT target_table + '.' + target_column, ', ') AS linked_columns
FROM [mrs].[z_inferred_relationships]
GROUP BY source_table, source_column
HAVING COUNT(DISTINCT target_table) > 1
ORDER BY linked_tables_count DESC;

-- Cross-Table relationship matrix_________________________________________________________________
SELECT 
    source_table,
    COUNT(DISTINCT CASE WHEN target_table LIKE 'z[_]cust%' THEN target_table END) AS customer_tables,
    COUNT(DISTINCT CASE WHEN target_table LIKE 'z[_]item%' THEN target_table END) AS item_tables,
    COUNT(DISTINCT CASE WHEN target_table LIKE 'z[_]ord%' THEN target_table END) AS order_tables,
    COUNT(DISTINCT target_table) AS total_connected_tables
FROM [mrs].[z_inferred_relationships]
GROUP BY source_table
ORDER BY total_connected_tables DESC;

-- Detailed relationship explorer_________________________________________________________________
SELECT 
    r.source_table,
    r.source_column,
    r.source_description,
    r.match_pattern,
    r.target_table,
    r.target_column,
    r.target_description,
    CASE 
        WHEN t1.table_type = 'BASE TABLE' AND t2.table_type = 'BASE TABLE' THEN 'Table-to-Table'
        WHEN t1.table_type = 'VIEW' OR t2.table_type = 'VIEW' THEN 'Involving View'
        ELSE 'Other'
    END AS relationship_type
FROM [mrs].[z_inferred_relationships] r
LEFT JOIN information_schema.tables t1 
    ON t1.table_name = REPLACE(r.source_table, 'z_', '')
LEFT JOIN information_schema.tables t2 
    ON t2.table_name = REPLACE(r.target_table, 'z_', '')
ORDER BY r.source_table, r.target_table;


-- Data dictionary with relationships_________________________________________________________________

WITH table_columns AS (
    SELECT 
        t.name AS table_name,
        c.name AS column_name,
        ep.value AS column_description,
        CASE 
            WHEN CHARINDEX('_____', c.name) > 0 
            THEN RIGHT(c.name, LEN(c.name) - CHARINDEX('_____', c.name) - 4)
            ELSE c.name
        END AS as400_column_name
    FROM sys.columns c
    JOIN sys.tables t ON c.object_id = t.object_id
    LEFT JOIN sys.extended_properties ep ON 
        ep.major_id = c.object_id AND 
        ep.minor_id = c.column_id AND 
        ep.name = 'MS_Description'
    WHERE t.name LIKE 'z[_]%'
)
SELECT 
    tc.table_name,
    tc.column_name,
    tc.column_description,
    tc.as400_column_name,
    STRING_AGG(DISTINCT r.target_table + '.' + r.target_column, ', ') AS related_columns,
    COUNT(DISTINCT r.target_table) AS related_table_count
FROM table_columns tc
LEFT JOIN [mrs].[z_inferred_relationships] r ON 
    tc.table_name = r.source_table AND 
    tc.column_name = r.source_column
GROUP BY tc.table_name, tc.column_name, tc.column_description, tc.as400_column_name
ORDER BY tc.table_name, related_table_count DESC;

-- Exportable relationship Map (for visualization tools)_________________________________________________________________
SELECT 
    source_table AS 'source',
    source_column AS 'source_attribute',
    target_table AS 'target',
    target_column AS 'target_attribute',
    match_pattern AS 'relationship_type',
    'directed' AS 'edge_type'
FROM [mrs].[z_inferred_relationships]
ORDER BY source_table, target_table;


-- Potential primary key identification_________________________________________________________________
SELECT 
    table_name,
    column_name,
    COUNT(*) AS reference_count
FROM (
    SELECT source_table AS table_name, source_column AS column_name FROM [mrs].[z_inferred_relationships]
    UNION ALL
    SELECT target_table AS table_name, target_column AS column_name FROM [mrs].[z_inferred_relationships]
) AS all_columns
GROUP BY table_name, column_name
HAVING COUNT(*) > 1
ORDER BY reference_count DESC;

