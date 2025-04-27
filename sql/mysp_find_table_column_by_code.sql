USE SigmaTB;
GO

CREATE OR ALTER PROCEDURE mysp_find_table_column_by_code
    @InputTableCode SYSNAME,
    @InputColumnCode SYSNAME
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        s.name AS SchemaName,
        @InputTableCode AS FoundTableCode,
        ep_t.value AS TableDescription,
        @InputColumnCode AS FoundColumnCode,
        ep_c.value AS ColumnDescription
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
END;
GO 