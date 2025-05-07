-- Stored procedure: mysp_analyze_table_columns
-- Description: This procedure analyzes the columns of a specified table.
-- It retrieves the column code from the column name (part after separator)
-- and then executes the "mysp_find_unique_values_table_column_by_code" procedure
-- for each column, printing the results.

USE sigmatb;
GO

-- Drop the procedure if it exists
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'mysp_analyze_table_columns')
    DROP PROCEDURE mysp_analyze_table_columns;
GO

CREATE PROCEDURE mysp_analyze_table_columns (
    @tableXPCode VARCHAR(255)
)
AS
BEGIN
    -- Declare variables
    DECLARE @columnName VARCHAR(255);
    DECLARE @columnCode VARCHAR(255);
    DECLARE @columnDescription VARCHAR(255);
    DECLARE @columnCount INT = 0;
    DECLARE @separator CHAR(1) = '_'; -- Default separator

    -- Declare cursor to iterate through columns
    DECLARE column_cursor CURSOR FOR
    SELECT 
        c.name,
        CONVERT(VARCHAR(255), ep.value) AS column_description
    FROM sys.columns c
    INNER JOIN sys.extended_properties ep ON ep.major_id = c.object_id 
        AND ep.minor_id = c.column_id
        AND ep.class = 1
    WHERE c.object_id = OBJECT_ID(@tableXPCode);

    -- Open cursor
    OPEN column_cursor;

    -- Fetch first row
    FETCH NEXT FROM column_cursor INTO @columnName, @columnDescription;

    -- Loop through all columns
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Increment column counter
        SET @columnCount = @columnCount + 1;

        -- Extract column code from name (part after last separator)
        IF CHARINDEX(@separator, @columnName) > 0
            SET @columnCode = SUBSTRING(@columnName, CHARINDEX(@separator, @columnName) + 1, LEN(@columnName))
        ELSE
            SET @columnCode = @columnName;

        -- Print column information
        PRINT 'Analyzing Column: ' + CAST(@columnCount AS VARCHAR) + ', Column Name: ' + @columnName + ', Column Code: ' + @columnCode + ', Column Description: ' + @columnDescription;

        -- Execute the stored procedure to find unique values
        EXEC mysp_find_unique_values_table_column_by_code 
            @InputTableCode = @tableXPCode, 
            @InputColumnCode = @columnCode,
            @InputColumnDescription = @columnDescription;

        -- Fetch next row
        FETCH NEXT FROM column_cursor INTO @columnName, @columnDescription;
    END;

    -- Clean up cursor
    CLOSE column_cursor;
    DEALLOCATE column_cursor;
END;
GO