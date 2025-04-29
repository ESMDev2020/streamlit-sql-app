-- Debug query for extended properties lookup
-- This query tests the same logic as the stored procedure for column lookups

USE sigmatb;

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