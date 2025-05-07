/****************************************************
DOES NOT WORK


USE [SigmaTBLocal]
GO

ALTER PROCEDURE [mrs].[usp_TranslateSQLQuery]
    @SQLQuery NVARCHAR(MAX),
    @DebugMode BIT = 0,
    @TranslatedQuery NVARCHAR(MAX) OUTPUT,
    @Execution BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Declare variables
    DECLARE @var_RawQuery NVARCHAR(MAX) = @SQLQuery;
    DECLARE @var_TranslatedQuery NVARCHAR(MAX) = @SQLQuery;
    DECLARE @var_TranslationDirection NVARCHAR(20);
    DECLARE @con_MSChar_Indicator NVARCHAR(10) = '_____';
    
    -- Variables for table name translation
    DECLARE @var_FoundTableName NVARCHAR(255);
    DECLARE @var_TranslatedTableName NVARCHAR(255);
    DECLARE @var_IntCounter INT = 1;
    DECLARE @var_CountTables INT;
    
    -- Variables for column translation
    DECLARE @var_FoundTableAlias NVARCHAR(255);
    DECLARE @var_FoundColumnName NVARCHAR(255);
    DECLARE @var_TranslatedColumnName NVARCHAR(255);
    DECLARE @var_CountColumns INT;
    
    -- Other variables for parsing
    DECLARE @pos INT;
    DECLARE @openBracket INT;
    DECLARE @closeBracket INT;
    DECLARE @dot INT;
    DECLARE @fromPos INT;
    DECLARE @fromEndPos INT;
    DECLARE @wherePos INT;
    DECLARE @orderByPos INT;
    DECLARE @bracketContent NVARCHAR(255);
    
    -- Debug information
    IF @DebugMode = 1
    BEGIN
        PRINT '-- Debug Mode ON --';
        PRINT 'Original Query: ' + @var_RawQuery;
        
        -- Determine the translation direction by checking for the presence of "_____" in the query
        IF CHARINDEX(@con_MSChar_Indicator, @var_RawQuery) > 0
        BEGIN
            SET @var_TranslationDirection = 'MSSQL_TO_AS400';
            PRINT 'Translation Direction: MSSQL to AS400';
        END
        ELSE
        BEGIN
            SET @var_TranslationDirection = 'AS400_TO_MSSQL';
            PRINT 'Translation Direction: AS400 to MSSQL';
        END
    END
    ELSE
    BEGIN
        -- Still need to determine direction even when not in debug mode
        IF CHARINDEX(@con_MSChar_Indicator, @var_RawQuery) > 0
        BEGIN
            SET @var_TranslationDirection = 'MSSQL_TO_AS400';
        END
        ELSE
        BEGIN
            SET @var_TranslationDirection = 'AS400_TO_MSSQL';
        END
    END
    
    ---------------------------------------------------------------------------------------
    -- TABLE NAME TRANSLATION
    ---------------------------------------------------------------------------------------
    
    -- Create temporary tables for table processing
    IF OBJECT_ID('tempdb..#TableNames') IS NOT NULL DROP TABLE #TableNames;
    CREATE TABLE #TableNames (
        ID INT IDENTITY(1,1),
        TableName NVARCHAR(255),
        Alias NVARCHAR(255),
        TranslatedName NVARCHAR(255)
    );
    
    -- Extract the FROM clause
    SET @fromPos = CHARINDEX(' FROM ', ' ' + @var_RawQuery);
    SET @wherePos = CHARINDEX(' WHERE ', ' ' + @var_RawQuery);
    SET @orderByPos = CHARINDEX(' ORDER BY ', ' ' + @var_RawQuery);
    
    -- Find the end of the FROM clause
    IF @wherePos > 0
        SET @fromEndPos = @wherePos;
    ELSE IF @orderByPos > 0
        SET @fromEndPos = @orderByPos;
    ELSE
        SET @fromEndPos = LEN(@var_RawQuery) + 1;
    
    -- Extract the FROM clause
    DECLARE @fromClause NVARCHAR(MAX) = SUBSTRING(@var_RawQuery, @fromPos + 6, @fromEndPos - @fromPos - 6);
    
    IF @DebugMode = 1
        PRINT 'FROM clause: ' + @fromClause;
    
    -- Find table references in the FROM clause
    SET @pos = 1;
    WHILE @pos <= LEN(@fromClause)
    BEGIN
        -- Find next open bracket
        SET @openBracket = CHARINDEX('[', @fromClause, @pos);
        IF @openBracket = 0 BREAK;
        
        -- Find closing bracket
        SET @closeBracket = CHARINDEX(']', @fromClause, @openBracket);
        IF @closeBracket = 0 BREAK;
        
        -- Extract table name
        SET @var_FoundTableName = SUBSTRING(@fromClause, @openBracket + 1, @closeBracket - @openBracket - 1);
        
        -- Check for alias (next bracketed item)
        DECLARE @nextOpenBracket INT = CHARINDEX('[', @fromClause, @closeBracket + 1);
        DECLARE @nextCloseBracket INT = 0;
        DECLARE @alias NVARCHAR(255) = NULL;
        
        -- Skip whitespace between table and potential alias
        DECLARE @afterTable NVARCHAR(20) = SUBSTRING(@fromClause, @closeBracket + 1, 
            CASE WHEN @nextOpenBracket > 0 THEN @nextOpenBracket - @closeBracket - 1 ELSE 0 END);
        
        -- Check if next bracketed item is right after this one (an alias)
        IF @nextOpenBracket > 0 AND DATALENGTH(LTRIM(RTRIM(@afterTable))) = 0
        BEGIN
            SET @nextCloseBracket = CHARINDEX(']', @fromClause, @nextOpenBracket);
            IF @nextCloseBracket > 0
            BEGIN
                SET @alias = SUBSTRING(@fromClause, @nextOpenBracket + 1, @nextCloseBracket - @nextOpenBracket - 1);
                
                -- Move position past the alias
                SET @pos = @nextCloseBracket + 1;
            END
        END
        ELSE
        BEGIN
            -- Move position past the table name
            SET @pos = @closeBracket + 1;
        END
        
        -- Skip commas and whitespace
        WHILE @pos <= LEN(@fromClause) AND (SUBSTRING(@fromClause, @pos, 1) = ',' OR SUBSTRING(@fromClause, @pos, 1) = ' ')
            SET @pos = @pos + 1;
        
        -- Add to our table collection if not already there
        IF NOT EXISTS (SELECT 1 FROM #TableNames WHERE TableName = @var_FoundTableName)
        BEGIN
            INSERT INTO #TableNames (TableName, Alias, TranslatedName)
            VALUES (@var_FoundTableName, @alias, NULL);
            
            IF @DebugMode = 1
            BEGIN
                PRINT 'Found table: [' + @var_FoundTableName + ']';
                IF @alias IS NOT NULL
                    PRINT 'Found alias: [' + @alias + '] for table [' + @var_FoundTableName + ']';
            END
        END
    END
    
    -- Get the count of tables found
    SELECT @var_CountTables = COUNT(*) FROM #TableNames;
    
    IF @DebugMode = 1
        PRINT 'Found ' + CAST(@var_CountTables AS NVARCHAR(10)) + ' table references';
    
    -- Translate each table name using a cursor instead of complex subquery
    IF @DebugMode = 1
        PRINT 'Starting table name translation loop...';
    
    DECLARE @tableCursor CURSOR;
    DECLARE @tableID INT;
    DECLARE @tableName NVARCHAR(255);
    
    SET @tableCursor = CURSOR FOR 
        SELECT ID, TableName FROM #TableNames;
    
    OPEN @tableCursor;
    FETCH NEXT FROM @tableCursor INTO @tableID, @tableName;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Translate the table name
        EXEC [AWS_SigmaTB].[SigmaTB].[mrs].[usp_TranslateObjectName] 
            @InputName = @tableName, 
            @ContextTableName = NULL, 
            @TranslatedName = @var_TranslatedTableName OUTPUT;
        
        -- Update the translated name in our table
        UPDATE #TableNames 
        SET TranslatedName = @var_TranslatedTableName 
        WHERE ID = @tableID;
        
        IF @DebugMode = 1
        BEGIN
            PRINT 'Found table: [' + @tableName + ']';
            PRINT 'Translated to: ' + ISNULL(@var_TranslatedTableName, 'NULL');
        END
        
        FETCH NEXT FROM @tableCursor INTO @tableID, @tableName;
    END
    
    CLOSE @tableCursor;
    DEALLOCATE @tableCursor;
    
    -- Now rebuild the FROM clause with translated table names
    DECLARE @newFromClause NVARCHAR(MAX) = '';
    DECLARE @translatedName NVARCHAR(255);
    
    SET @tableCursor = CURSOR FOR
        SELECT TableName, Alias, TranslatedName FROM #TableNames;
    
    OPEN @tableCursor;
    FETCH NEXT FROM @tableCursor INTO @tableName, @alias, @translatedName;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Add comma if not the first table
        IF LEN(@newFromClause) > 0
            SET @newFromClause = @newFromClause + ', ';
        
        -- Add the translated table name with schema prefix
        SET @newFromClause = @newFromClause + '[AWS_SigmaTB].[SigmaTB].[mrs].[' + @translatedName + ']';
        
        -- Add alias if present
        IF @alias IS NOT NULL
            SET @newFromClause = @newFromClause + ' [' + @alias + ']';
        
        FETCH NEXT FROM @tableCursor INTO @tableName, @alias, @translatedName;
    END
    
    CLOSE @tableCursor;
    DEALLOCATE @tableCursor;
    
    -- Replace the FROM clause in the query
    SET @var_TranslatedQuery = STUFF(@var_TranslatedQuery, @fromPos + 6, @fromEndPos - @fromPos - 6, @newFromClause);
    
    IF @DebugMode = 1
    BEGIN
        PRINT 'Table name translation completed';
        PRINT ' ';
        PRINT 'Starting column name translation...';
    END
    
    ---------------------------------------------------------------------------------------
    -- COLUMN NAME TRANSLATION
    ---------------------------------------------------------------------------------------
    
    -- Create temporary table for column references
    IF OBJECT_ID('tempdb..#ColumnReferences') IS NOT NULL DROP TABLE #ColumnReferences;
    CREATE TABLE #ColumnReferences (
        ID INT IDENTITY(1,1),
        TableName NVARCHAR(255),
        ColumnName NVARCHAR(255),
        FullReference NVARCHAR(500)
    );
    
    -- Find all table.column references in the query using pattern matching
    SET @pos = 1;
    WHILE @pos <= LEN(@var_TranslatedQuery)
    BEGIN
        -- Find the start of a table reference
        SET @openBracket = CHARINDEX('[', @var_TranslatedQuery, @pos);
        IF @openBracket = 0 BREAK;
        
        -- Find the end of the table name
        SET @closeBracket = CHARINDEX(']', @var_TranslatedQuery, @openBracket);
        IF @closeBracket = 0 BREAK;
        
        -- Check if followed by a dot and another bracket (column reference)
        SET @dot = CHARINDEX('].[', @var_TranslatedQuery, @openBracket);
        
        -- If this is a table.column pattern
        IF @dot = @closeBracket
        BEGIN
            -- Extract the table name or alias
            SET @var_FoundTableAlias = SUBSTRING(@var_TranslatedQuery, @openBracket + 1, @closeBracket - @openBracket - 1);
            
            -- Find the column part
            SET @openBracket = @dot + 2; -- Position after '.[' 
            SET @closeBracket = CHARINDEX(']', @var_TranslatedQuery, @openBracket);
            
            IF @closeBracket > 0
            BEGIN
                -- Extract the column name
                SET @var_FoundColumnName = SUBSTRING(@var_TranslatedQuery, @openBracket + 1, @closeBracket - @openBracket - 1);
                
                -- Create the full reference
                DECLARE @fullRef NVARCHAR(500) = '[' + @var_FoundTableAlias + '].[' + @var_FoundColumnName + ']';
                
                -- Add to our column references if not already there
                IF NOT EXISTS (SELECT 1 FROM #ColumnReferences 
                               WHERE TableName = @var_FoundTableAlias 
                               AND ColumnName = @var_FoundColumnName)
                BEGIN
                    INSERT INTO #ColumnReferences (TableName, ColumnName, FullReference)
                    VALUES (@var_FoundTableAlias, @var_FoundColumnName, @fullRef);
                END
                
                -- Move position past this reference
                SET @pos = @closeBracket + 1;
            END
            ELSE
                SET @pos = @openBracket + 1;
        END
        ELSE
            SET @pos = @closeBracket + 1;
    END
    
    -- Get the number of column references
    SELECT @var_CountColumns = COUNT(*) FROM #ColumnReferences;
    
    IF @DebugMode = 1
        PRINT 'Found ' + CAST(@var_CountColumns AS NVARCHAR(10)) + ' column references';
    
    -- Process each column reference
    DECLARE @columnCursor CURSOR;
    DECLARE @colTableName NVARCHAR(255);
    DECLARE @colName NVARCHAR(255);
    DECLARE @colRef NVARCHAR(500);
    DECLARE @originalTableName NVARCHAR(255);
    
    SET @columnCursor = CURSOR FOR
        SELECT TableName, ColumnName, FullReference 
        FROM #ColumnReferences;
    
    OPEN @columnCursor;
    FETCH NEXT FROM @columnCursor INTO @colTableName, @colName, @colRef;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @DebugMode = 1
            PRINT 'Processing column reference: ' + @colRef;
        
        -- Find the original table name (if this is an alias)
        SELECT TOP 1 @originalTableName = TableName 
        FROM #TableNames 
        WHERE Alias = @colTableName;
        
        -- If not found as an alias, it might be the table name itself
        IF @originalTableName IS NULL
            SET @originalTableName = @colTableName;
        
        -- Translate the column name using the original table as context
        EXEC [AWS_SigmaTB].[SigmaTB].[mrs].[usp_TranslateObjectName] 
            @InputName = @colName, 
            @ContextTableName = @originalTableName, 
            @TranslatedName = @var_TranslatedColumnName OUTPUT;
        
        -- If translation successful, replace in the query
        IF @var_TranslatedColumnName IS NOT NULL
        BEGIN
            IF @DebugMode = 1
                PRINT 'Translated column: ' + @colName + ' to: ' + @var_TranslatedColumnName;
            
            -- Create the new reference with translated column name
            DECLARE @newRef NVARCHAR(500) = '[' + @colTableName + '].[' + @var_TranslatedColumnName + ']';
            
            -- Replace in the query
            SET @var_TranslatedQuery = REPLACE(@var_TranslatedQuery, @colRef, @newRef);
        END
        
        FETCH NEXT FROM @columnCursor INTO @colTableName, @colName, @colRef;
    END
    
    CLOSE @columnCursor;
    DEALLOCATE @columnCursor;
    
    -- Clean up temporary tables
    DROP TABLE #TableNames;
    DROP TABLE #ColumnReferences;
    
    -- Debug information
    IF @DebugMode = 1
    BEGIN
        PRINT 'Column name translation completed';
        PRINT ' ';
        PRINT 'Final translated query: ' + @var_TranslatedQuery;
    END
    
    -- Assign the translated query to the output parameter
    SET @TranslatedQuery = @var_TranslatedQuery;
    
    -- Execute the translated query if requested
    IF @Execution = 1
    BEGIN
        IF @DebugMode = 1
            PRINT 'Executing translated query: ' + @var_TranslatedQuery;
            
        -- Execute the translated query using sp_executesql
        BEGIN TRY
            EXEC sp_executesql @var_TranslatedQuery;
            
            IF @DebugMode = 1
                PRINT 'Query executed successfully.';
        END TRY
        BEGIN CATCH
            DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
            DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
            DECLARE @ErrorState INT = ERROR_STATE();
            
            IF @DebugMode = 1
                PRINT 'Error executing query: ' + @ErrorMessage;
                
            -- Re-throw the error
            RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        END CATCH
    END
    
    RETURN 0;
END