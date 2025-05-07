USE SigmaTB;
GO

/***************************************************************************************************
* Stored Procedure: usp_GetExtendedProperties
* 
* Purpose: This stored procedure retrieves extended properties for tables and their columns within 
*          the specified schema in the SigmaTB database.
*
* Input Parameters: None (currently hardcoded to 'mrs' schema, but could be parameterized in future)
*
* Output: Returns a result set containing table names, column names, and their associated extended 
*         properties (both names and values).
*
* Creation Date: [Current Date]
* Created By: [Your Name]
*
* Modification History:
* [Date] - [Modifier Name] - [Description of changes]
*
* Notes:
* - Extended properties provide metadata about database objects that can be used for documentation,
*   version control, or application-specific purposes.
* - The procedure joins system tables to retrieve both table-level and column-level properties.
* - Properties with minor_id = 0 are table-level properties.
* - Class = 1 indicates the property is on an object or column.
***************************************************************************************************/

CREATE OR ALTER PROCEDURE usp_GetExtendedProperties
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Retrieve extended properties for tables and columns in the 'mrs' schema
    SELECT
        t.name AS table_name,         -- Name of the table
        tp.name AS table_prop_name,   -- Name of the table's extended property
        tp.value AS table_prop_value, -- Value of the table's extended property
        c.name AS column_name,        -- Name of the column (NULL if property is table-level only)
        cp.name AS column_prop_name,  -- Name of the column's extended property
        cp.value AS column_prop_value -- Value of the column's extended property
    FROM
        sys.schemas AS s
    INNER JOIN
        sys.tables AS t ON s.schema_id = t.schema_id
    -- Left join for table extended properties (minor_id = 0 indicates table-level properties)
    LEFT JOIN 
        sys.extended_properties AS tp ON t.object_id = tp.major_id
                                     AND tp.minor_id = 0 
                                     AND tp.class = 1    -- Class 1 = Object or Column
    -- Left join for columns within each table
    LEFT JOIN 
        sys.columns AS c ON t.object_id = c.object_id
    -- Left join for column extended properties (minor_id matches column_id)
    LEFT JOIN 
        sys.extended_properties AS cp ON c.object_id = cp.major_id
                                     AND c.column_id = cp.minor_id 
                                     AND cp.class = 1    -- Class 1 = Object or Column
    WHERE
        s.name = 'mrs'  -- Filter to only include tables in the 'mrs' schema
    ORDER BY
        t.name,         -- Primary sort by table name
        c.column_id;    -- Secondary sort by column position within table
    
    SET NOCOUNT OFF;
END;
GO

-- Example execution:
-- EXEC usp_GetExtendedProperties;