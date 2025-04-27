-- Debug query for extended properties lookup
-- This query tests the same logic as the stored procedure for column lookups

-- First, let's see all extended properties
SELECT 
    ep.name AS property_name,
    ep.value AS property_value,
    ep.class,
    ep.major_id,
    ep.minor_id
FROM sys.extended_properties ep
ORDER BY ep.name;

-- Now let's look for the specific property we're looking for
SELECT 
    ep.name AS property_name,
    ep.value AS property_value,
    ep.class,
    ep.major_id,
    ep.minor_id
FROM sys.extended_properties ep
WHERE ep.name = 'GLACCT'
ORDER BY ep.name;

-- Let's see what objects these properties are attached to
SELECT 
    ep.name AS property_name,
    ep.value AS property_value,
    ep.class,
    ep.major_id,
    ep.minor_id,
    CASE 
        WHEN ep.minor_id = 0 THEN 'Table'
        ELSE 'Column'
    END AS object_type,
    t.name AS table_name,
    c.name AS column_name
FROM sys.extended_properties ep
LEFT JOIN sys.tables t ON ep.major_id = t.object_id
LEFT JOIN sys.columns c ON ep.major_id = c.object_id AND ep.minor_id = c.column_id
WHERE ep.name = 'GLACCT'
ORDER BY ep.name;

-- Let's check all properties that might be related to our search
SELECT 
    ep.name AS property_name,
    ep.value AS property_value,
    ep.class,
    ep.major_id,
    ep.minor_id,
    CASE 
        WHEN ep.minor_id = 0 THEN 'Table'
        ELSE 'Column'
    END AS object_type,
    t.name AS table_name,
    c.name AS column_name
FROM sys.extended_properties ep
LEFT JOIN sys.tables t ON ep.major_id = t.object_id
LEFT JOIN sys.columns c ON ep.major_id = c.object_id AND ep.minor_id = c.column_id
WHERE ep.name LIKE '%GL%'
ORDER BY ep.name;

SELECT
    SCHEMA_NAME(t.schema_id) AS SchemaName,
    t.name AS TableName,
    c.name AS ColumnName,
    c.column_id,
    type_name(c.user_type_id) AS DataType,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    ep_table.name AS TableCode,           -- The code (e.g., 'GLTRANS')
    ep_table.value AS TableDescription,   -- The description for the table
    ep_col.name AS ColumnDescription,     -- The description for the column
    ep_col.value AS ColumnCode            -- The code (e.g., 'GLACCT')
FROM
    sys.tables AS t
INNER JOIN
    -- Find tables with the specified extended property NAME (table code)
    sys.extended_properties AS ep_table ON ep_table.major_id = t.object_id
                                      AND ep_table.class = 1      -- Object or Column class
                                      AND ep_table.minor_id = 0   -- 0 indicates table level
                                      AND ep_table.name = 'GLTRANS' -- Match NAME for the table code
INNER JOIN
    sys.columns AS c ON c.object_id = t.object_id -- Join to columns of that table
INNER JOIN
    -- Find columns within that table with the specified extended property VALUE (column code)
    sys.extended_properties AS ep_col ON ep_col.major_id = c.object_id -- Match column's object_id
                                    AND ep_col.minor_id = c.column_id -- Match column_id
                                    AND ep_col.class = 1      -- Object or Column class
                                    AND ep_col.value = 'GLACCT' -- Match VALUE for the column code
                                    AND ep_col.name = 'GLTRANS'; -- Ensure it's from the same table

-- Additional debug queries to help understand the data structure
SELECT 'All Extended Properties for GLTRANS Table' AS QueryDescription;
SELECT 
    ep.name AS PropertyName,
    ep.value AS PropertyValue,
    CASE ep.minor_id 
        WHEN 0 THEN 'Table Level'
        ELSE 'Column Level'
    END AS PropertyLevel
FROM sys.extended_properties AS ep
INNER JOIN sys.tables AS t ON ep.major_id = t.object_id
WHERE t.name = 'GLTRANS'
ORDER BY ep.minor_id, ep.name;

SELECT 'All Extended Properties for GLACCT Column' AS QueryDescription;
SELECT 
    ep.name AS PropertyName,
    ep.value AS PropertyValue,
    t.name AS TableName,
    c.name AS ColumnName
FROM sys.extended_properties AS ep
INNER JOIN sys.columns AS c ON ep.major_id = c.object_id AND ep.minor_id = c.column_id
INNER JOIN sys.tables AS t ON c.object_id = t.object_id
WHERE ep.value = 'GLACCT'
ORDER BY t.name, c.name; 