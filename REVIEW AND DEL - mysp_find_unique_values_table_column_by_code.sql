USE SigmaTB;
GO

CREATE OR ALTER PROCEDURE mysp_find_unique_values_table_column_by_code
    @InputTableCode SYSNAME,
    @InputColumnCode SYSNAME
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TableName NVARCHAR(128);
    DECLARE @ColumnName NVARCHAR(128);
    DECLARE @SchemaName NVARCHAR(128);
    DECLARE @SQL NVARCHAR(MAX);

    -- First, get the actual table and column names
    SELECT TOP 1
        @SchemaName = s.name,
        @TableName = t.name,
        @ColumnName = c.name
    FROM
        sys.extended_properties AS ep_t
    INNER JOIN
        sys.tables AS t ON ep_t.major_id = t.object_id
    INNER JOIN
        sys.schemas AS s ON t.schema_id = s.schema_id
    INNER JOIN
        sys.columns AS c ON t.object_id = c.object_id
    INNER JOIN
        sys.extended_properties AS ep_c
        ON ep_c.major_id = c.object_id
        AND ep_c.minor_id = c.column_id
    WHERE
        ep_t.class = 1
        AND ep_t.minor_id = 0
        AND ep_t.name = @InputTableCode
        AND ep_c.class = 1
        AND ep_c.name = @InputColumnCode;

    -- If we found the table and column, execute the dynamic SQL
    IF @TableName IS NOT NULL AND @ColumnName IS NOT NULL
    BEGIN
        SET @SQL = N'
        SELECT DISTINCT 
            [' + @ColumnName + '] AS UniqueValue
        FROM 
            [' + @SchemaName + '].[' + @TableName + ']
        WHERE 
            [' + @ColumnName + '] IS NOT NULL
        ORDER BY 
            [' + @ColumnName + ']';

        EXEC sp_executesql @SQL;
    END
    ELSE
    BEGIN
        RAISERROR('Table or column not found with the specified codes', 16, 1);
    END
END;
GO 