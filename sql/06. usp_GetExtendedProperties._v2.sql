-- Drop the procedure if it already exists in the 'mrs' schema
IF OBJECT_ID('mrs.usp_GetExtendedProperties', 'P') IS NOT NULL
    DROP PROCEDURE mrs.usp_GetExtendedProperties;
GO

-- =============================================
-- Author:      <Your Name>
-- Create date: <Create Date, e.g., 2025-04-30>
-- Description: Retrieves extended properties for database objects (Tables/Views)
--              and their columns. Allows filtering by table name and column name.
-- Parameters:
--   @TableName SYSNAME = NULL: Optional. The specific table or view name to filter by.
--                              If NULL, properties for all tables/views are retrieved.
--   @ColumnName SYSNAME = NULL: Optional. The specific column name to filter by.
--                               Requires @TableName to also be provided.
--                               If NULL (and @TableName is specified), properties for the table
--                               and all its columns are retrieved.
--                               If NULL (and @TableName is NULL), properties for all tables
--                               and all their columns are retrieved.
-- Returns:     A result set containing schema name, object name, column name (if applicable),
--              property name, and property value.
-- =============================================
CREATE PROCEDURE mrs.usp_GetExtendedProperties
    @TableName SYSNAME = NULL,
    @ColumnName SYSNAME = NULL
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

    -- Input validation: Check if @ColumnName is provided without @TableName
    IF @ColumnName IS NOT NULL AND @TableName IS NULL
    BEGIN
        -- Raise an error if trying to filter by column without specifying the table context
        RAISERROR ('If @ColumnName is specified, @TableName must also be specified.', 16, 1);
        RETURN; -- Exit the procedure
    END

    -- Core Query to retrieve extended properties
    SELECT
        s.name AS SchemaName,                           -- Schema of the object
        o.name AS ObjectName,                           -- Name of the table or view
        -- Display column name only if it's a column-level property (minor_id > 0 indicates a column)
        CASE WHEN ep.minor_id > 0 THEN c.name ELSE NULL END AS ColumnName,
        ep.name AS PropertyName,                        -- Name of the extended property
        CAST(ep.value AS NVARCHAR(MAX)) AS PropertyValue, -- Value of the extended property (cast for safety)
        ep.class_desc,                                  -- Description of the class (e.g., OBJECT_OR_COLUMN)
        ep.minor_id                                     -- 0 for table/view property, column_id for column property
    FROM
        -- Base table for extended properties
        sys.extended_properties AS ep
    INNER JOIN
        -- Join to sys.objects to get object details (like name, type, schema_id) based on major_id
        sys.objects AS o ON ep.major_id = o.object_id
    INNER JOIN
        -- Join to sys.schemas to get the schema name using schema_id from sys.objects
        sys.schemas AS s ON o.schema_id = s.schema_id
    LEFT JOIN
        -- Left join to sys.columns is necessary to retrieve column names and filter by them.
        -- The join condition matches both the object ID and the column ID (stored in minor_id for column properties).
        sys.columns AS c ON ep.major_id = c.object_id AND ep.minor_id = c.column_id
    WHERE
        -- Filter for properties associated with OBJECT or COLUMN level (class 1)
        ep.class = 1
        -- Filter for specific object types (U = User Table, V = View). Modify if other types are needed.
        AND o.type IN ('U', 'V')

        -- Apply optional Table Name Filter:
        -- If @TableName is NULL, this condition is effectively ignored (OR o.name = @TableName becomes TRUE).
        -- If @TableName has a value, only properties where the object name matches are included.
        AND (@TableName IS NULL OR o.name = @TableName)

        -- Apply optional Column Name Filter:
        -- This condition determines whether to return properties for the table itself, all columns, or a specific column.
        AND (
             -- Case 1: No column filter specified (@ColumnName IS NULL).
             -- This allows properties for the table/view itself (where minor_id = 0)
             -- AND properties for all columns (where minor_id > 0 and the LEFT JOIN to sys.columns succeeded).
             (@ColumnName IS NULL)
             OR
             -- Case 2: Specific column filter specified (@ColumnName IS NOT NULL).
             -- This requires a match on the column name from sys.columns (c.name)
             -- AND ensures it's actually a column property (ep.minor_id > 0).
             (c.name = @ColumnName AND ep.minor_id > 0)
            )
    ORDER BY
        SchemaName,
        ObjectName,
        -- Sort table-level properties (minor_id = 0) before column-level properties (minor_id > 0)
        CASE WHEN ep.minor_id = 0 THEN 0 ELSE 1 END,
        ColumnName,
        PropertyName;

END;
GO

/*
-- =============================================
-- Usage Examples:
-- =============================================

-- Example 1: Get extended properties for ALL tables/views and their columns in the database
EXEC mrs.usp_GetExtendedProperties;

-- Example 2: Get extended properties for a specific table ('YourTableName')
--            This includes properties defined on the table itself AND on all of its columns.
EXEC mrs.usp_GetExtendedProperties @TableName = 'z_Material_Processing_Order_Detail_____MPDETAIL';

-- Example 3: Get extended properties ONLY for a specific column ('YourColumnName')
--            within a specific table ('YourTableName').
EXEC mrs.usp_GetExtendedProperties @TableName = 'z_Material_Processing_Order_Detail_____MPDETAIL', @ColumnName = 'REQUESTED_SHIP_CENTURY_____MDRQCC';

-- Example 4: (Invalid Use Case Test) Try to get properties for a column without specifying the table
--            This should raise the custom error defined in the procedure.
-- EXEC mrs.usp_GetExtendedProperties @ColumnName = 'YourColumnName';

*/