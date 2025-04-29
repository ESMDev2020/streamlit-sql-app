/*******************************************************************
                     INFER RELATIONSHIPS
************************************** ****************************/
USE SigmaTB;
GO


USE SigmaTB;
GO

-- First, alter the target table to add confidence_level if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('[mrs].[z_inferred_relationships]') AND name = 'confidence_level')
BEGIN
    ALTER TABLE [mrs].[z_inferred_relationships] ADD confidence_level INT NULL;
    PRINT 'Added confidence_level column to z_inferred_relationships';
END
GO

CREATE OR ALTER PROCEDURE [mrs].[usp_infer_relationships_batch]
    @batch_size INT = 5,      -- Process 5 tables at a time
    @continue BIT = 1,        -- Set to 0 to start fresh
    @debug BIT = 0            -- Set to 1 for verbose logging
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Create processing tracking table if it doesn't exist
    IF OBJECT_ID('tempdb..#processed_columns') IS NULL
    BEGIN
        CREATE TABLE #processed_columns (
            table_name NVARCHAR(255),
            column_name NVARCHAR(255),
            processed BIT DEFAULT 0,
            PRIMARY KEY (table_name, column_name)
        );
        
        IF @debug = 1 PRINT 'Created #processed_columns temp table';
    END
    
    -- Initialize on fresh start
    IF @continue = 0
    BEGIN
        TRUNCATE TABLE #processed_columns;
        
        -- Populate with all columns to process
        INSERT INTO #processed_columns (table_name, column_name)
        SELECT t.name, c.name
        FROM sys.tables t
        JOIN sys.columns c ON t.object_id = c.object_id
        WHERE t.name LIKE 'z[_]%'
        ORDER BY t.name, c.name;
        
        -- Clear results if starting fresh
        TRUNCATE TABLE [mrs].[z_inferred_relationships];
        
        IF @debug = 1 
            PRINT 'Fresh start - initialized ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' columns for processing';
    END
    ELSE IF NOT EXISTS (SELECT 1 FROM #processed_columns)
    BEGIN
        -- If continuing but temp table is empty, repopulate without clearing results
        INSERT INTO #processed_columns (table_name, column_name)
        SELECT t.name, c.name
        FROM sys.tables t
        JOIN sys.columns c ON t.object_id = c.object_id
        WHERE t.name LIKE 'z[_]%'
        AND NOT EXISTS (
            SELECT 1 FROM [mrs].[z_inferred_relationships] r
            WHERE r.source_table = t.name AND r.source_column = c.name
        )
        ORDER BY t.name, c.name;
        
        IF @debug = 1 
            PRINT 'Continue mode - initialized ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' unprocessed columns';
    END
    
    DECLARE @tables_processed INT = 0;
    DECLARE @columns_processed INT = 0;
    DECLARE @current_table NVARCHAR(255);
    DECLARE @current_column NVARCHAR(255);
    
    -- Process columns in batches
    WHILE @tables_processed < @batch_size AND 
          EXISTS (SELECT 1 FROM #processed_columns WHERE processed = 0)
    BEGIN
        -- Get next column to process
        SELECT TOP 1 
            @current_table = table_name,
            @current_column = column_name
        FROM #processed_columns
        WHERE processed = 0
        ORDER BY table_name, column_name;
        
        IF @debug = 1 
            PRINT 'Processing: ' + @current_table + '.' + @current_column;
        
        -- Process this specific column with confidence calculation
        INSERT INTO [mrs].[z_inferred_relationships] (
            source_table, source_column, source_description, source_as400_column,
            target_table, target_column, target_description, target_as400_column,
            match_pattern, confidence_level
        )
        SELECT 
            t.name AS source_table,
            c.name AS source_column,
            CONVERT(NVARCHAR(255), ep.value) AS source_description,
            CASE 
                WHEN CHARINDEX('_____', c.name) > 0 
                THEN RIGHT(c.name, LEN(c.name) - CHARINDEX('_____', c.name) - 4)
                ELSE c.name
            END AS source_as400_column,
            t2.name AS target_table,
            c2.name AS target_column,
            CONVERT(NVARCHAR(255), ep2.value) AS target_description,
            CASE 
                WHEN CHARINDEX('_____', c2.name) > 0 
                THEN RIGHT(c2.name, LEN(c2.name) - CHARINDEX('_____', c2.name) - 4)
                ELSE c2.name
            END AS target_as400_column,
            RIGHT(CASE 
                WHEN CHARINDEX('_____', c.name) > 0 
                THEN RIGHT(c.name, LEN(c.name) - CHARINDEX('_____', c.name) - 4)
                ELSE c.name
            END, 4) AS match_pattern,
            -- Composite confidence calculation (0-100 scale)
            (
                -- 1. Pattern Matching Confidence (50% weight)
                CASE 
                    WHEN RIGHT(CASE WHEN CHARINDEX('_____', c.name) > 0 
                              THEN RIGHT(c.name, LEN(c.name) - CHARINDEX('_____', c.name) - 4)
                              ELSE c.name END, 4) = 
                         RIGHT(CASE WHEN CHARINDEX('_____', c2.name) > 0 
                              THEN RIGHT(c2.name, LEN(c2.name) - CHARINDEX('_____', c2.name) - 4)
                              ELSE c2.name END, 4)
                    THEN 50 
                    WHEN RIGHT(CASE WHEN CHARINDEX('_____', c.name) > 0 
                              THEN RIGHT(c.name, LEN(c.name) - CHARINDEX('_____', c.name) - 4)
                              ELSE c.name END, 3) = 
                         RIGHT(CASE WHEN CHARINDEX('_____', c2.name) > 0 
                              THEN RIGHT(c2.name, LEN(c2.name) - CHARINDEX('_____', c2.name) - 4)
                              ELSE c2.name END, 3)
                    THEN 30
                    WHEN RIGHT(CASE WHEN CHARINDEX('_____', c.name) > 0 
                              THEN RIGHT(c.name, LEN(c.name) - CHARINDEX('_____', c.name) - 4)
                              ELSE c.name END, 2) = 
                         RIGHT(CASE WHEN CHARINDEX('_____', c2.name) > 0 
                              THEN RIGHT(c2.name, LEN(c2.name) - CHARINDEX('_____', c2.name) - 4)
                              ELSE c2.name END, 2)
                    THEN 10
                    ELSE 0
                END +
                -- 2. Data Type Matching Confidence (30% weight)
                CASE WHEN tp1.name = tp2.name THEN 30 ELSE 0 END +
                -- 3. Table Name Similarity Confidence (20% weight)
                CASE 
                    WHEN REPLACE(t.name, 'z______', '') = REPLACE(t2.name, 'z______', '') THEN 20
                    WHEN LEFT(REPLACE(t.name, 'z______', ''), 4) = LEFT(REPLACE(t2.name, 'z______', ''), 4) THEN 10
                    ELSE 0
                END
            ) AS confidence_level
        FROM sys.columns c
        JOIN sys.tables t ON c.object_id = t.object_id
        JOIN sys.types tp1 ON c.user_type_id = tp1.user_type_id
        LEFT JOIN sys.extended_properties ep ON 
            ep.major_id = c.object_id AND 
            ep.minor_id = c.column_id
        CROSS JOIN sys.tables t2
        JOIN sys.columns c2 ON c2.object_id = t2.object_id
        JOIN sys.types tp2 ON c2.user_type_id = tp2.user_type_id
        LEFT JOIN sys.extended_properties ep2 ON 
            ep2.major_id = c2.object_id AND 
            ep2.minor_id = c2.column_id
        WHERE 
            t.name = @current_table AND
            c.name = @current_column AND
            t2.name LIKE 'z[_]%' AND
            t2.name <> t.name AND
            LEN(CASE 
                WHEN CHARINDEX('_____', c.name) > 0 
                THEN RIGHT(c.name, LEN(c.name) - CHARINDEX('_____', c.name) - 4)
                ELSE c.name
            END) >= 4;
        
        -- Mark column as processed
        UPDATE #processed_columns
        SET processed = 1
        WHERE table_name = @current_table AND column_name = @current_column;
        
        SET @columns_processed = @columns_processed + 1;
        
        -- Count tables only when we finish all columns in a table
        IF NOT EXISTS (
            SELECT 1 FROM #processed_columns 
            WHERE table_name = @current_table AND processed = 0
        )
        BEGIN
            SET @tables_processed = @tables_processed + 1;
            IF @debug = 1 
                PRINT 'Completed table: ' + @current_table;
        END
        
        IF @debug = 1 AND @columns_processed % 10 = 0
            PRINT 'Processed ' + CAST(@columns_processed AS NVARCHAR) + ' columns';
    END
    
    -- Remove duplicate relationships (with required semicolon)
    ;WITH DuplicateCTE AS (
        SELECT 
            relationship_id,
            ROW_NUMBER() OVER (
                PARTITION BY 
                    CASE WHEN source_table < target_table THEN source_table ELSE target_table END,
                    CASE WHEN source_table < target_table THEN target_table ELSE source_table END,
                    match_pattern
                ORDER BY confidence_level DESC -- Keep highest confidence relationship
            ) AS row_num
        FROM [mrs].[z_inferred_relationships]
    )
    DELETE FROM DuplicateCTE WHERE row_num > 1;
    
    -- Report status
    DECLARE @remaining_columns INT, @remaining_tables INT;
    DECLARE @total_relationships INT;
    DECLARE @high_confidence INT, @medium_confidence INT, @low_confidence INT;
    
    SELECT @remaining_columns = COUNT(*) 
    FROM #processed_columns 
    WHERE processed = 0;
    
    SELECT @remaining_tables = COUNT(DISTINCT table_name)
    FROM #processed_columns
    WHERE processed = 0;
    
    SELECT @total_relationships = COUNT(*) 
    FROM [mrs].[z_inferred_relationships];
    
    SELECT @high_confidence = COUNT(*)
    FROM [mrs].[z_inferred_relationships]
    WHERE confidence_level >= 70;
    
    SELECT @medium_confidence = COUNT(*)
    FROM [mrs].[z_inferred_relationships]
    WHERE confidence_level BETWEEN 40 AND 69;
    
    SELECT @low_confidence = COUNT(*)
    FROM [mrs].[z_inferred_relationships]
    WHERE confidence_level < 40;
    
    PRINT 'Batch processing completed.';
    PRINT 'Tables processed in this batch: ' + CAST(@tables_processed AS NVARCHAR);
    PRINT 'Columns processed in this batch: ' + CAST(@columns_processed AS NVARCHAR);
    PRINT 'Remaining tables: ' + CAST(@remaining_tables AS NVARCHAR);
    PRINT 'Remaining columns: ' + CAST(@remaining_columns AS NVARCHAR);
    PRINT 'Total relationships found: ' + CAST(@total_relationships AS NVARCHAR);
    PRINT 'High confidence relationships (≥70): ' + CAST(@high_confidence AS NVARCHAR);
    PRINT 'Medium confidence (40-69): ' + CAST(@medium_confidence AS NVARCHAR);
    PRINT 'Low confidence (<40): ' + CAST(@low_confidence AS NVARCHAR);
    
    IF @remaining_columns > 0
        PRINT 'Run EXEC [mrs].[usp_infer_relationships_batch] @continue = 1 to process next batch';
    ELSE
        PRINT 'All columns processed!';
END
GO