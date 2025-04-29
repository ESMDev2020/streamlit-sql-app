/********************************
sp_translate_query. to translate CODES into sql queries
***********************************/

USE SigmaTB; -- Ensure this is the correct database context
GO

-- Drop the procedure if it already exists (optional, CREATE OR ALTER handles this)
-- IF OBJECT_ID('dbo.sp_translate_sql_query', 'P') IS NOT NULL
--     DROP PROCEDURE dbo.sp_translate_sql_query;
-- GO

CREATE OR ALTER PROCEDURE dbo.sp_translate_sql_query
    @input_query NVARCHAR(MAX),
    @translated_query NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Temporary table to store identified object names and their translations
    DECLARE @translations TABLE (
        id INT IDENTITY(1,1) PRIMARY KEY,
        original_name NVARCHAR(512), -- Increased size for schema.table.column
        schema_name NVARCHAR(128),
        object_name NVARCHAR(128),
        column_name NVARCHAR(128),
        object_type VARCHAR(10), -- 'TABLE', 'COLUMN'
        translated_name NVARCHAR(512),
        processed BIT DEFAULT 0,
        original_length INT
    );

    -- Variables for processing
    DECLARE @current_pos INT = 1;
    DECLARE @open_bracket INT;
    DECLARE @close_bracket INT;
    DECLARE @potential_name NVARCHAR(512);
    DECLARE @dot_pos INT;
    DECLARE @schema_part NVARCHAR(128);
    DECLARE @object_part NVARCHAR(128);
    DECLARE @column_part NVARCHAR(128);
    DECLARE @temp_query NVARCHAR(MAX) = @input_query; -- Work on a copy

    -- ==========================================================================
    -- Step 1: Extract all potential bracketed names ([schema].[object], [object], [object].[column])
    -- This loop finds bracketed identifiers. It's a basic parser and might
    -- miss complex cases or incorrectly identify strings containing brackets.
    -- ==========================================================================
    WHILE @current_pos <= LEN(@temp_query)
    BEGIN
        SET @open_bracket = CHARINDEX('[', @temp_query, @current_pos);
        IF @open_bracket = 0 BREAK; -- No more opening brackets

        SET @close_bracket = CHARINDEX(']', @temp_query, @open_bracket + 1);
        IF @close_bracket = 0 -- Malformed (open bracket without close) - stop or skip? Let's skip past it.
        BEGIN
             SET @current_pos = @open_bracket + 1;
             CONTINUE;
        END

        -- Extract the full potential name including brackets
        SET @potential_name = SUBSTRING(@temp_query, @open_bracket, @close_bracket - @open_bracket + 1);

        -- Basic check to avoid adding duplicates immediately
        IF NOT EXISTS (SELECT 1 FROM @translations WHERE original_name = @potential_name)
        BEGIN
            -- Attempt to parse the name inside brackets
            DECLARE @name_inside NVARCHAR(512) = SUBSTRING(@potential_name, 2, LEN(@potential_name) - 2);
            SET @schema_part = NULL;
            SET @object_part = NULL;
            SET @column_part = NULL;

            -- Use PARSENAME for splitting. NOTE: PARSENAME expects 'object.schema.database.server'
            -- It works reasonably well for 'schema.object' or 'object.column' if used carefully.
            -- It returns NULL if the name has more than 4 parts or invalid characters (besides '.').
            -- We'll handle 2-part names ([schema].[table] or [table].[column]) and 1-part names ([table/column]).

            IF PARSENAME(@name_inside, 3) IS NULL AND PARSENAME(@name_inside, 2) IS NOT NULL AND PARSENAME(@name_inside, 1) IS NOT NULL -- Likely schema.object or object.column
            BEGIN
                 -- Could be [schema].[table] or [table].[column]. We need to check sys.objects/sys.columns later.
                 -- Let's tentatively assign:
                 SET @schema_part = PARSENAME(@name_inside, 2); -- Potential schema or table
                 SET @object_part = PARSENAME(@name_inside, 1); -- Potential table or column
            END
            ELSE IF PARSENAME(@name_inside, 2) IS NULL AND PARSENAME(@name_inside, 1) IS NOT NULL -- Likely single object name
            BEGIN
                 SET @object_part = PARSENAME(@name_inside, 1); -- Potential table or column (unqualified)
            END
            -- Else: Could be malformed, have >2 parts, or contain invalid chars for PARSENAME. Skip insertion for now.

            -- Insert if we parsed something potentially valid
            IF @object_part IS NOT NULL
            BEGIN
                 INSERT INTO @translations (original_name, schema_name, object_name, column_name, original_length)
                 VALUES (@potential_name, @schema_part, @object_part, NULL, LEN(@potential_name)); -- Initially assume it's not a column
            END
        END

        -- Move past the closing bracket for the next search
        SET @current_pos = @close_bracket + 1;
    END

    -- ==========================================================================
    -- Step 2: Attempt to identify object types and get translations (Extended Properties)
    -- ==========================================================================

    -- Update object_type and translation for Tables/Views
    UPDATE t
    SET
        t.object_type = 'TABLE',
        t.translated_name = QUOTENAME(CONVERT(NVARCHAR(128), ep.value)), -- Use QUOTENAME to add brackets []
        t.processed = 1
    FROM @translations t
    JOIN sys.tables st ON t.object_name = st.name -- Match object part with table name
    JOIN sys.schemas s ON st.schema_id = s.schema_id AND (t.schema_name IS NULL OR t.schema_name = s.name) -- Match schema if provided
    LEFT JOIN sys.extended_properties ep ON ep.major_id = st.object_id
                                        AND ep.minor_id = 0 -- 0 for table/view properties
                                        AND ep.name = 'MS_Description' -- Standard name for description
    WHERE t.processed = 0
      AND t.column_name IS NULL; -- Only process items not yet identified as columns

    -- Update object_type and translation for Columns
    -- This prioritizes columns where the table name was also identified
    UPDATE t
    SET
        t.object_type = 'COLUMN',
        -- Reconstruct the translated name as [Table].[TranslatedColumn] or just [TranslatedColumn]
        t.translated_name = ISNULL(QUOTENAME(t.schema_name) + '.', '') + QUOTENAME(t.object_name) + '.' + QUOTENAME(CONVERT(NVARCHAR(128), ep.value)),
        t.processed = 1,
        t.column_name = t.object_name, -- Correctly assign the column name
        t.object_name = t.schema_name  -- Assign the table/view name to object_name (schema_name was holding it)
    FROM @translations t
    JOIN sys.columns sc ON t.object_name = sc.name -- The 'object_part' was the column name here
    JOIN sys.tables st ON sc.object_id = st.object_id AND t.schema_name = st.name -- The 'schema_part' was the table name
    JOIN sys.schemas s ON st.schema_id = s.schema_id -- Schema of the table
    LEFT JOIN sys.extended_properties ep ON ep.major_id = sc.object_id
                                        AND ep.minor_id = sc.column_id -- Column properties
                                        AND ep.name = 'MS_Description'
    WHERE t.processed = 0
      AND t.schema_name IS NOT NULL -- Ensure it was a two-part name like [Table].[Column]
      AND t.column_name IS NULL; -- Ensure not already processed

    -- Attempt to translate remaining single-part names as columns (ambiguous)
    -- This assumes a single-part name like [ColumnName] refers to a column.
    -- It finds the *first* matching column and its description. This might be wrong
    -- if the same column name exists in multiple tables used in the query.
    -- Consider removing this block if only fully qualified names should be translated.
    UPDATE t
    SET
        t.object_type = 'COLUMN',
        t.translated_name = QUOTENAME(CONVERT(NVARCHAR(128), ep.value)),
        t.processed = 1,
        t.column_name = t.object_name, -- Assign the column name
        t.object_name = NULL,          -- Clear object name as it was the column
        t.schema_name = NULL           -- Clear schema name
    FROM @translations t
    CROSS APPLY (
        SELECT TOP 1 ep.value
        FROM sys.columns sc
        JOIN sys.tables st ON sc.object_id = st.object_id
        LEFT JOIN sys.extended_properties ep ON ep.major_id = sc.object_id
                                            AND ep.minor_id = sc.column_id
                                            AND ep.name = 'MS_Description'
        WHERE sc.name = t.object_name -- Match the single part name with a column name
        ORDER BY st.name -- Arbitrary order to get TOP 1 if multiple tables have this column
    ) AS ep (value)
    WHERE t.processed = 0
      AND t.schema_name IS NULL -- Only process single-part names
      AND t.column_name IS NULL -- Ensure not already processed
      AND ep.value IS NOT NULL; -- Only update if a translation was found

    -- Mark any remaining unprocessed items as processed, using original name
    UPDATE @translations
    SET translated_name = original_name,
        processed = 1
    WHERE processed = 0;

    -- ==========================================================================
    -- Step 3: Apply translations to the query string
    -- Replace longest original names first to avoid partial replacements
    -- ==========================================================================
    DECLARE @original NVARCHAR(512);
    DECLARE @translated NVARCHAR(512);

    -- Use a cursor to iterate through translations ordered by length DESC
    DECLARE translation_cursor CURSOR LOCAL FAST_FORWARD READ_ONLY FOR
    SELECT original_name, ISNULL(translated_name, original_name) -- Fallback to original if translation failed
    FROM @translations
    ORDER BY original_length DESC;

    OPEN translation_cursor;
    FETCH NEXT FROM translation_cursor INTO @original, @translated;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Perform the replacement
        -- Note: REPLACE is case-insensitive by default in most SQL Server collations.
        -- If case-sensitivity is required, COLLATE might be needed, adding complexity.
        SET @temp_query = REPLACE(@temp_query, @original, @translated);

        FETCH NEXT FROM translation_cursor INTO @original, @translated;
    END

    CLOSE translation_cursor;
    DEALLOCATE translation_cursor;

    -- ==========================================================================
    -- Step 4: Output the final translated query
    -- ==========================================================================
    SET @translated_query = @temp_query;

END
GO

-- Example Usage:
/*
-- Prerequisites: Create dummy tables/columns and add extended properties
IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL DROP TABLE dbo.Customers;
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
GO
CREATE TABLE dbo.Customers (CustomerID INT PRIMARY KEY, CustomerName NVARCHAR(100));
CREATE TABLE dbo.Orders (OrderID INT PRIMARY KEY, CustomerID INT, OrderDate DATE);
GO

-- Add descriptions (translations)
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Clientes' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Customers';
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Pedidos' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Orders';
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'IDCliente' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Customers', @level2type=N'COLUMN',@level2name=N'CustomerID';
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'NombreCliente' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Customers', @level2type=N'COLUMN',@level2name=N'CustomerName';
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'IDPedido' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Orders', @level2type=N'COLUMN',@level2name=N'OrderID';
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'FechaPedido' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Orders', @level2type=N'COLUMN',@level2name=N'OrderDate';
-- Note: No description added for Orders.CustomerID to test fallback
GO

-- Declare variables for testing
DECLARE @input NVARCHAR(MAX) = N'SELECT c.[CustomerName], o.[OrderDate] FROM [dbo].[Customers] AS c JOIN [dbo].[Orders] AS o ON c.[CustomerID] = o.[CustomerID] WHERE c.[CustomerID] > 10;';
DECLARE @output NVARCHAR(MAX);

-- Execute the procedure
EXEC dbo.sp_translate_sql_query @input_query = @input, @translated_query = @output OUTPUT;

-- Print the result
PRINT 'Original Query:';
PRINT @input;
PRINT '';
PRINT 'Translated Query:';
PRINT @output;
GO

-- Cleanup (Optional)
-- EXEC sys.sp_dropextendedproperty @name=N'MS_Description', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Customers';
-- EXEC sys.sp_dropextendedproperty @name=N'MS_Description', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Orders';
-- ... drop other properties ...
-- IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL DROP TABLE dbo.Customers;
-- IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
-- IF OBJECT_ID('dbo.sp_translate_sql_query', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_translate_sql_query;
-- GO
*/
