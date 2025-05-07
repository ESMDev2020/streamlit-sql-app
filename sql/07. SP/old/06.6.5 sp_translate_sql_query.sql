USE [SigmaTB]
GO
/****** Object:  StoredProcedure [mrs].[sp_translate_sql_query]    Script Date: 5/6/2025 6:06:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER   PROCEDURE [mrs].[sp_translate_sql_query]
    @input_query NVARCHAR(MAX),
    @translated_query NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Temporary table to store identified object names and their translations
    DECLARE @translations TABLE (
        id INT IDENTITY(1,1) PRIMARY KEY,
        original_name NVARCHAR(512), -- Store the exact name found in the query ([name] or name)
        schema_name NVARCHAR(128),   -- Parsed schema name (unbracketed)
        object_name NVARCHAR(128),   -- Parsed object name (unbracketed)
        column_name NVARCHAR(128),   -- Parsed column name (unbracketed)
        object_type VARCHAR(10),     -- 'TABLE', 'COLUMN'
        translated_name NVARCHAR(512), -- Translated name (will be bracketed)
        processed BIT DEFAULT 0,
        original_length INT,
        is_bracketed BIT -- Flag to know if the original had brackets
    );

    -- Variables for processing
    DECLARE @current_pos INT = 1;
    DECLARE @open_bracket INT;
    DECLARE @close_bracket INT;
    DECLARE @potential_name NVARCHAR(512);
    DECLARE @name_inside NVARCHAR(512);
    DECLARE @schema_part NVARCHAR(128);
    DECLARE @object_part NVARCHAR(128);
    DECLARE @temp_query NVARCHAR(MAX) = @input_query; -- Work on a copy

    -- Basic list of common SQL keywords/operators/functions to ignore when parsing non-bracketed names
    -- This list is NOT exhaustive and might need expansion for complex queries.
    DECLARE @sql_keywords TABLE (keyword NVARCHAR(100) PRIMARY KEY);
    INSERT INTO @sql_keywords (keyword) VALUES
    ('SELECT'), ('FROM'), ('WHERE'), ('JOIN'), ('INNER'), ('LEFT'), ('RIGHT'), ('FULL'), ('OUTER'), ('ON'), ('GROUP'), ('BY'), ('ORDER'), ('HAVING'),
    ('INSERT'), ('INTO'), ('VALUES'), ('UPDATE'), ('SET'), ('DELETE'), ('AND'), ('OR'), ('NOT'), ('AS'), ('DISTINCT'), ('TOP'), ('CASE'), ('WHEN'),
    ('THEN'), ('ELSE'), ('END'), ('IS'), ('NULL'), ('LIKE'), ('BETWEEN'), ('EXISTS'), ('IN'), ('ANY'), ('ALL'), ('UNION'), ('CREATE'), ('ALTER'),
    ('DROP'), ('TABLE'), ('VIEW'), ('PROCEDURE'), ('FUNCTION'), ('INDEX'), ('CONSTRAINT'), ('PRIMARY'), ('KEY'), ('FOREIGN'), ('REFERENCES'),
    ('DEFAULT'), ('CHECK'), ('EXEC'), ('EXECUTE'), ('DECLARE'), ('CURSOR'), ('FETCH'), ('NEXT'), ('CLOSE'), ('DEALLOCATE'), ('BEGIN'), ('TRANSACTION'),
    ('COMMIT'), ('ROLLBACK'), ('GRANT'), ('REVOKE'), ('DENY'), ('GO'), ('USE'), ('DATABASE'), ('SCHEMA'), ('COLUMN'), ('ADD'), ('WITH'), ('NOLOCK'),
    ('COUNT'), ('SUM'), ('AVG'), ('MAX'), ('MIN'), ('GETDATE'), ('DATEADD'), ('DATEDIFF'), ('CAST'), ('CONVERT'), ('TRY_CONVERT'), ('ISNULL'), ('COALESCE');

    -- ==========================================================================
    -- Step 1a: Extract all potential BRACKETED names ([schema].[object], [object], [object].[column])
    -- ==========================================================================
    WHILE @current_pos <= LEN(@temp_query)
    BEGIN
        SET @open_bracket = CHARINDEX('[', @temp_query, @current_pos);
        IF @open_bracket = 0 BREAK;

        SET @close_bracket = CHARINDEX(']', @temp_query, @open_bracket + 1);
        IF @close_bracket = 0
        BEGIN
             SET @current_pos = @open_bracket + 1;
             CONTINUE;
        END

        SET @potential_name = SUBSTRING(@temp_query, @open_bracket, @close_bracket - @open_bracket + 1);
        SET @name_inside = SUBSTRING(@potential_name, 2, LEN(@potential_name) - 2);

        -- Check for duplicates before parsing
        IF NOT EXISTS (SELECT 1 FROM @translations WHERE original_name = @potential_name)
        BEGIN
            SET @schema_part = NULL;
            SET @object_part = NULL;

            -- Use PARSENAME to split the name inside the brackets
            IF PARSENAME(@name_inside, 3) IS NULL AND PARSENAME(@name_inside, 2) IS NOT NULL AND PARSENAME(@name_inside, 1) IS NOT NULL
            BEGIN
                 SET @schema_part = PARSENAME(@name_inside, 2);
                 SET @object_part = PARSENAME(@name_inside, 1);
            END
            ELSE IF PARSENAME(@name_inside, 2) IS NULL AND PARSENAME(@name_inside, 1) IS NOT NULL
            BEGIN
                 SET @object_part = PARSENAME(@name_inside, 1);
            END

            IF @object_part IS NOT NULL
            BEGIN
                 INSERT INTO @translations (original_name, schema_name, object_name, column_name, original_length, is_bracketed)
                 VALUES (@potential_name, @schema_part, @object_part, NULL, LEN(@potential_name), 1);
            END
        END
        SET @current_pos = @close_bracket + 1;
    END

    -- ==========================================================================
    -- Step 1b: Extract potential NON-BRACKETED names
    -- This is a simplified approach and may have limitations.
    -- ==========================================================================
    DECLARE @token NVARCHAR(512);
    DECLARE @separators NVARCHAR(100) = N' ,.;()[]=<>+-*/|&^%!'; -- Characters to split by

    -- Replace separators with a single common delimiter (like '|') for easier splitting
    -- This is a basic way to handle separators; more complex parsing might be needed.
    DECLARE @normalized_query NVARCHAR(MAX) = @input_query;
    DECLARE @i INT = 1;
    WHILE @i <= LEN(@separators)
    BEGIN
        SET @normalized_query = REPLACE(@normalized_query, SUBSTRING(@separators, @i, 1), '|');
        SET @i = @i + 1;
    END
    -- Also handle line breaks
    SET @normalized_query = REPLACE(REPLACE(@normalized_query, CHAR(13), '|'), CHAR(10), '|');

    -- Split the query into tokens
    DECLARE token_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT LTRIM(RTRIM(value))
        FROM STRING_SPLIT(@normalized_query, '|')
        WHERE LTRIM(RTRIM(value)) <> ''; -- Ignore empty strings resulting from split

    OPEN token_cursor;
    FETCH NEXT FROM token_cursor INTO @token;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Skip if it's numeric, a known keyword, or looks like a string literal start/end
        IF ISNUMERIC(@token) = 0
           AND NOT EXISTS (SELECT 1 FROM @sql_keywords WHERE keyword = UPPER(@token))
           AND LEFT(@token, 1) <> '''' AND RIGHT(@token, 1) <> '''' -- Basic check for literals
           AND CHARINDEX('[', @token) = 0 AND CHARINDEX(']', @token) = 0 -- Skip if it contains brackets (handled above)
        BEGIN
            SET @potential_name = @token; -- Store the exact token found
            SET @schema_part = NULL;
            SET @object_part = NULL;

            -- Use PARSENAME again. Requires replacing non-standard chars if any exist.
            -- PARSENAME is limited, but useful for simple schema.object or object.column patterns.
            IF PARSENAME(@potential_name, 3) IS NULL AND PARSENAME(@potential_name, 2) IS NOT NULL AND PARSENAME(@potential_name, 1) IS NOT NULL
            BEGIN
                 SET @schema_part = PARSENAME(@potential_name, 2);
                 SET @object_part = PARSENAME(@potential_name, 1);
            END
            ELSE IF PARSENAME(@potential_name, 2) IS NULL AND PARSENAME(@potential_name, 1) IS NOT NULL
            BEGIN
                 SET @object_part = PARSENAME(@potential_name, 1);
            END

            IF @object_part IS NOT NULL
            BEGIN
                -- Check if an equivalent name (bracketed or not) is already added
                DECLARE @unbracketed_form NVARCHAR(512) = @potential_name; -- Already unbracketed
                DECLARE @bracketed_form NVARCHAR(512) = QUOTENAME(@schema_part) + CASE WHEN @schema_part IS NOT NULL THEN '.' ELSE '' END + QUOTENAME(@object_part);

                IF NOT EXISTS (SELECT 1 FROM @translations WHERE original_name = @unbracketed_form OR original_name = @bracketed_form)
                BEGIN
                    INSERT INTO @translations (original_name, schema_name, object_name, column_name, original_length, is_bracketed)
                    VALUES (@potential_name, @schema_part, @object_part, NULL, LEN(@potential_name), 0);
                END
            END
        END

        FETCH NEXT FROM token_cursor INTO @token;
    END

    CLOSE token_cursor;
    DEALLOCATE token_cursor;


    -- ==========================================================================
    -- Step 2: Attempt to identify object types and get translations (Extended Properties)
    -- Lookup uses the parsed (unbracketed) schema/object names.
    -- ==========================================================================

    -- Update object_type and translation for Tables/Views
    UPDATE t
    SET
        t.object_type = 'TABLE',
        -- Always create translated name with brackets using QUOTENAME
        t.translated_name = ISNULL(QUOTENAME(s.name) + '.', '') + QUOTENAME(CONVERT(NVARCHAR(128), ep.value)),
        t.processed = 1
    FROM @translations t
    JOIN sys.tables st ON t.object_name = st.name -- Match parsed object name
    JOIN sys.schemas s ON st.schema_id = s.schema_id AND (t.schema_name IS NULL OR t.schema_name = s.name) -- Match parsed schema name if provided
    LEFT JOIN sys.extended_properties ep ON ep.major_id = st.object_id
                                        AND ep.minor_id = 0
                                        AND ep.name = 'MS_Description'
                                        AND ep.value IS NOT NULL -- Only update if description exists
    WHERE t.processed = 0
      AND t.column_name IS NULL;

    -- Update object_type and translation for Columns (identified as schema.object or table.column initially)
    UPDATE t
    SET
        t.object_type = 'COLUMN',
        -- Construct translated name: [TranslatedTable].[TranslatedColumn] or [Table].[TranslatedColumn] etc.
        -- Get translated table name first (might be from another entry in @translations or original name)
        t.translated_name = ISNULL(
                                (SELECT TOP 1 tt.translated_name
                                 FROM @translations tt
                                 WHERE tt.object_type = 'TABLE' AND tt.object_name = t.schema_name AND (tt.schema_name IS NULL OR tt.schema_name = PARSENAME(t.original_name, 2))
                                ),
                                QUOTENAME(t.schema_name) -- Fallback to original table name if no translation found for it
                             ) + '.' + QUOTENAME(CONVERT(NVARCHAR(128), ep.value)), -- Add translated column name
        t.processed = 1,
        t.column_name = t.object_name, -- This was the column part
        t.object_name = t.schema_name  -- This was the table/alias part
    FROM @translations t
    JOIN sys.columns sc ON t.object_name = sc.name -- The 'object_part' was the column name
    JOIN sys.tables st ON sc.object_id = st.object_id AND t.schema_name = st.name -- The 'schema_part' was the table name
    JOIN sys.schemas s ON st.schema_id = s.schema_id
    LEFT JOIN sys.extended_properties ep ON ep.major_id = sc.object_id
                                        AND ep.minor_id = sc.column_id
                                        AND ep.name = 'MS_Description'
                                        AND ep.value IS NOT NULL -- Only update if description exists
    WHERE t.processed = 0
      AND t.schema_name IS NOT NULL -- Ensure it was parsed as a two-part name
      AND t.column_name IS NULL;

    -- Attempt to translate remaining single-part names as columns (ambiguous case)
    UPDATE t
    SET
        t.object_type = 'COLUMN',
        t.translated_name = QUOTENAME(CONVERT(NVARCHAR(128), ep.value)), -- Just the translated column name, bracketed
        t.processed = 1,
        t.column_name = t.object_name, -- Assign the column name
        t.object_name = NULL,
        t.schema_name = NULL
    FROM @translations t
    CROSS APPLY (
        SELECT TOP 1 ep.value
        FROM sys.columns sc
        JOIN sys.tables st ON sc.object_id = st.object_id -- Find any table with this column
        LEFT JOIN sys.extended_properties ep ON ep.major_id = sc.object_id
                                            AND ep.minor_id = sc.column_id
                                            AND ep.name = 'MS_Description'
        WHERE sc.name = t.object_name -- Match the single part name
        ORDER BY st.name -- Arbitrary order
    ) AS ep (value)
    WHERE t.processed = 0
      AND t.schema_name IS NULL -- Only process single-part names
      AND t.column_name IS NULL
      AND ep.value IS NOT NULL; -- Only update if a translation was found

    -- Mark any remaining unprocessed items as processed, using a bracketed version of the original name as fallback
    UPDATE @translations
    SET translated_name = CASE
                            WHEN schema_name IS NOT NULL AND object_name IS NOT NULL AND column_name IS NOT NULL THEN QUOTENAME(schema_name) + '.' + QUOTENAME(object_name) + '.' + QUOTENAME(column_name) -- Should not happen based on parsing, but safe
                            WHEN schema_name IS NOT NULL AND object_name IS NOT NULL THEN QUOTENAME(schema_name) + '.' + QUOTENAME(object_name)
                            WHEN object_name IS NOT NULL AND column_name IS NOT NULL THEN QUOTENAME(object_name) + '.' + QUOTENAME(column_name) -- Ambiguous column case
                            WHEN object_name IS NOT NULL THEN QUOTENAME(object_name)
                            ELSE original_name -- Fallback to exact original if parsing failed somehow
                          END,
        processed = 1
    WHERE processed = 0;

    -- ==========================================================================
    -- Step 3: Apply translations to the query string
    -- Replace longest original names first. Uses the exact 'original_name' found.
    -- ==========================================================================
    DECLARE @original NVARCHAR(512);
    DECLARE @translated NVARCHAR(512);

    DECLARE translation_cursor CURSOR LOCAL FAST_FORWARD READ_ONLY FOR
    SELECT original_name, ISNULL(translated_name, original_name) -- Fallback should ideally not happen now
    FROM @translations
    WHERE translated_name <> original_name -- Only replace if translation is different
    ORDER BY original_length DESC;

    OPEN translation_cursor;
    FETCH NEXT FROM translation_cursor INTO @original, @translated;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Perform the replacement using the exact original form found
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
