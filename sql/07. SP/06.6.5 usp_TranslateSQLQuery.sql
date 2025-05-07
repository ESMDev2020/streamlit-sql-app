USE [SigmaTB]
GO

/****** Object:  StoredProcedure [mrs].[usp_TranslateSQLQuery]    Script Date: 05/06/2025 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*****************************************************************
Name: usp_TranslateSQLQuery
Description: Translates SQL query by replacing AS400 table/column names with MSSQL names and vice versa.
             The direction of translation is automatically determined by the presence of "_____" in the names.
             
Input: 
    @SQLQuery - The SQL query to translate
    @DebugMode - Flag to enable debug messages (1=Debug, 0=Normal)
    @TranslatedQuery - OUTPUT parameter to return the translated query
    
Output: Translated SQL query via OUTPUT parameter

Metadata: 
    Author: Claude
    Creation Date: 05/06/2025
    Version: 2.0
    Target Server/DB: SQL Server 2019, SigmaTB Database, mrs Schema
    
Example Usage: 
    -- Translate from AS400 to MSSQL
    DECLARE @OutputQuery NVARCHAR(MAX);
    EXEC [mrs].[usp_TranslateSQLQuery] 'SELECT CCUST, CPROD FROM ARCUST', 1, @OutputQuery OUTPUT;
    
    -- Translate from MSSQL to AS400
    DECLARE @OutputQuery NVARCHAR(MAX);
    EXEC [mrs].[usp_TranslateSQLQuery] 'SELECT CUSTOMER_NUMBER_____CCUST, PRODUCT_CODE_____CPROD FROM z_Customer_Master_File_____ARCUST', 1, @OutputQuery OUTPUT;
    
Example Resultset: 
    -- From AS400 to MSSQL: 
    -- 'SELECT CUSTOMER_NUMBER_____CCUST, PRODUCT_CODE_____CPROD FROM z_Customer_Master_File_____ARCUST'
    
    -- From MSSQL to AS400:
    -- 'SELECT CCUST, CPROD FROM ARCUST'
*****************************************************************/
ALTER PROCEDURE [mrs].[usp_TranslateSQLQuery]
    @SQLQuery NVARCHAR(MAX),
    @DebugMode BIT = 0,
    @TranslatedQuery NVARCHAR(MAX) OUTPUT,
    @Execution BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Declare variables
    DECLARE @con_TableDelimiter_Start NVARCHAR(10) = '[';
    DECLARE @con_TableDelimiter_End NVARCHAR(10) = ']';
    DECLARE @con_MSChar_Indicator NVARCHAR(10) = '_____';
    DECLARE @var_FoundTableName NVARCHAR(255);
    DECLARE @var_TranslatedTableName NVARCHAR(255);
    DECLARE @var_FoundColumnName NVARCHAR(255);
    DECLARE @var_TranslatedColumnName NVARCHAR(255);
    DECLARE @var_sql_GetOccurrences NVARCHAR(MAX);
    DECLARE @var_IntCounter INT = 1;
    DECLARE @var_LastReplaceIndex INT = 0;
    DECLARE @var_RawQuery NVARCHAR(MAX) = @SQLQuery;
    DECLARE @var_TranslatedQuery NVARCHAR(MAX) = @SQLQuery;
    DECLARE @var_CountTablesAndSchemas INT;
    DECLARE @var_TranslationDirection NVARCHAR(20);
    DECLARE @var_pos_Schema_dot INT;
    DECLARE @var_TableNameWithSchema NVARCHAR(255);
    DECLARE @var_SchemaName NVARCHAR(255);
    
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
    
    -- Create temporary table to store tables and schemas found in the query
    IF OBJECT_ID('tempdb..#TablesAndSchemas') IS NOT NULL
        DROP TABLE #TablesAndSchemas;
    
    CREATE TABLE #TablesAndSchemas (
        ID INT IDENTITY(1,1),
        TableOrSchemaName NVARCHAR(255)
    );
    
    -- Find all table names in the query using subquery approach
    SET @var_sql_GetOccurrences = N'
    WITH AllDelimiters AS (
        SELECT pos = CHARINDEX(''' + @con_TableDelimiter_Start + ''', @Query)
        WHERE CHARINDEX(''' + @con_TableDelimiter_Start + ''', @Query) > 0
        UNION ALL
        SELECT pos = CHARINDEX(''' + @con_TableDelimiter_Start + ''', @Query, pos + 1)
        FROM AllDelimiters
        WHERE CHARINDEX(''' + @con_TableDelimiter_Start + ''', @Query, pos + 1) > 0
    )
    INSERT INTO #TablesAndSchemas (TableOrSchemaName)
    SELECT DISTINCT SUBSTRING(@Query, d.pos + 1, 
        CHARINDEX(''' + @con_TableDelimiter_End + ''', @Query, d.pos) - d.pos - 1)
    FROM AllDelimiters d
    ORDER BY SUBSTRING(@Query, d.pos + 1, 
        CHARINDEX(''' + @con_TableDelimiter_End + ''', @Query, d.pos) - d.pos - 1);';
    
    -- Execute the dynamic SQL
    EXEC sp_executesql @var_sql_GetOccurrences, N'@Query NVARCHAR(MAX)', @Query = @var_RawQuery;
    
    -- Get the count of tables and schemas found
    SELECT @var_CountTablesAndSchemas = COUNT(*) FROM #TablesAndSchemas;
    
    -- Debug information
    IF @DebugMode = 1
    BEGIN
        PRINT 'Found ' + CAST(@var_CountTablesAndSchemas AS NVARCHAR(10)) + ' delimited table/schema names';
        PRINT 'Starting table name translation loop...';
    END
    
    -- Loop through the found table names and translate them
    WHILE @var_IntCounter <= @var_CountTablesAndSchemas
    BEGIN
        -- Get the current table or schema name
        SELECT @var_FoundTableName = TableOrSchemaName 
        FROM #TablesAndSchemas 
        WHERE ID = @var_IntCounter;
        
        -- Debug information
        IF @DebugMode = 1
            PRINT 'Found table/schema: [' + @var_FoundTableName + ']';
        
        -- Check if it's a schema.table format
        SET @var_pos_Schema_dot = CHARINDEX('.', @var_FoundTableName);
        
        IF @var_pos_Schema_dot > 0
        BEGIN
            -- Extract schema and table names
            SET @var_SchemaName = LEFT(@var_FoundTableName, @var_pos_Schema_dot - 1);
            SET @var_FoundTableName = SUBSTRING(@var_FoundTableName, @var_pos_Schema_dot + 1, LEN(@var_FoundTableName));
            SET @var_TableNameWithSchema = @var_SchemaName + '.' + @var_FoundTableName;
            
            -- Debug information
            IF @DebugMode = 1
            BEGIN
                PRINT 'Schema: ' + @var_SchemaName;
                PRINT 'Table: ' + @var_FoundTableName;
            END
        END
        ELSE
        BEGIN
            SET @var_TableNameWithSchema = @var_FoundTableName;
        END
        
        -- Translate the table name based on direction
        IF @var_TranslationDirection = 'AS400_TO_MSSQL'
        BEGIN
            -- Translate from AS400 to MSSQL using the existing procedure
            EXEC [mrs].[usp_TranslateObjectName] 
                @InputName = @var_FoundTableName, 
                @ContextTableName = NULL, 
                @TranslatedName = @var_TranslatedTableName OUTPUT;
        END
        ELSE -- MSSQL_TO_AS400
        BEGIN
            -- Check if the name contains the MS indicator
            IF CHARINDEX(@con_MSChar_Indicator, @var_FoundTableName) > 0
            BEGIN
                -- For MSSQL table names (with "_____"), extract the AS400 code part
                SET @var_TranslatedTableName = RIGHT(@var_FoundTableName, 
                    LEN(@var_FoundTableName) - CHARINDEX(@con_MSChar_Indicator, @var_FoundTableName) - 4);
            END
            ELSE
            BEGIN
                -- If no indicator, query the equivalents table
                SELECT @var_TranslatedTableName = [AS400_TableName]
                FROM [mrs].[01_AS400_MSSQL_Equivalents]
                WHERE [MSSQL_TableName] = @var_FoundTableName;
                
                -- If not found, keep the original name
                IF @var_TranslatedTableName IS NULL
                    SET @var_TranslatedTableName = @var_FoundTableName;
            END
        END
        
        -- Debug information
        IF @DebugMode = 1
            PRINT 'Translated to: ' + ISNULL(@var_TranslatedTableName, 'NULL');
        
        -- If schema was present, include it in the replacement
        IF @var_pos_Schema_dot > 0
        BEGIN
            -- Replace [schema.table] with [schema.translated_table]
            SET @var_TranslatedQuery = REPLACE(@var_TranslatedQuery, 
                @con_TableDelimiter_Start + @var_TableNameWithSchema + @con_TableDelimiter_End, 
                @con_TableDelimiter_Start + @var_SchemaName + '.' + @var_TranslatedTableName + @con_TableDelimiter_End);
        END
        ELSE
        BEGIN
            -- Replace [table] with [translated_table]
            SET @var_TranslatedQuery = REPLACE(@var_TranslatedQuery, 
                @con_TableDelimiter_Start + @var_FoundTableName + @con_TableDelimiter_End, 
                @con_TableDelimiter_Start + @var_TranslatedTableName + @con_TableDelimiter_End);
        END
        
        -- Increment counter
        SET @var_IntCounter = @var_IntCounter + 1;
    END
    
    -- Debug information
    IF @DebugMode = 1
    BEGIN
        PRINT 'Table name translation completed';
        PRINT 'Query after table translation: ' + @var_TranslatedQuery;
        PRINT 'Starting column name translation...';
    END
    
    ---------------------------------------------------------------------------------------
    -- COLUMN NAME TRANSLATION
    ---------------------------------------------------------------------------------------
    
    -- Reset counter
    SET @var_IntCounter = 1;
    
    -- Create temporary table to store column names
    IF OBJECT_ID('tempdb..#ColumnNames') IS NOT NULL
        DROP TABLE #ColumnNames;
    
    CREATE TABLE #ColumnNames (
        ID INT IDENTITY(1,1),
        ColumnName NVARCHAR(255)
    );
    
    -- Extract column names from the query
    -- This simplified approach finds potential column references outside of square brackets
    WITH Words AS (
        SELECT [value] AS word
        FROM STRING_SPLIT(REPLACE(REPLACE(REPLACE(REPLACE(
            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                @var_TranslatedQuery,
                '[', ' '),
                ']', ' '),
                '(', ' '),
                ')', ' '),
                ',', ' '),
                '=', ' '),
                '>', ' '),
                '<', ' '),
                ' AS ', ' '),
            ' ')
    )
    INSERT INTO #ColumnNames (ColumnName)
    SELECT DISTINCT word
    FROM Words
    WHERE LEN(word) > 0
      AND word NOT IN ('SELECT', 'FROM', 'WHERE', 'AND', 'OR', 'JOIN', 'LEFT', 'RIGHT', 'INNER', 'OUTER', 
                       'ON', 'GROUP', 'BY', 'HAVING', 'ORDER', 'TOP', 'DISTINCT', 'WITH', 'AS', 
                       'INSERT', 'UPDATE', 'DELETE', 'INTO', 'VALUES', 'SET')
      AND ISNUMERIC(word) = 0
      AND word NOT LIKE '%''%' -- Exclude string literals
    ORDER BY word;
    
    -- Get the count of column names found
    DECLARE @var_CountColumns INT;
    SELECT @var_CountColumns = COUNT(*) FROM #ColumnNames;
    
    -- Debug information
    IF @DebugMode = 1
        PRINT 'Found ' + CAST(@var_CountColumns AS NVARCHAR(10)) + ' potential column names';
    
    -- Loop through the found column names and translate them
    WHILE @var_IntCounter <= @var_CountColumns
    BEGIN
        -- Get the current column name
        SELECT @var_FoundColumnName = ColumnName 
        FROM #ColumnNames 
        WHERE ID = @var_IntCounter;
        
        -- Debug information
        IF @DebugMode = 1
            PRINT 'Processing column: ' + @var_FoundColumnName;
        
        -- Translate the column name based on direction
        IF @var_TranslationDirection = 'AS400_TO_MSSQL'
        BEGIN
            -- Translate from AS400 to MSSQL using the existing procedure
            EXEC [mrs].[usp_TranslateObjectName] 
                @InputName = @var_FoundColumnName, 
                @ContextTableName = NULL, 
                @TranslatedName = @var_TranslatedColumnName OUTPUT;
        END
        ELSE -- MSSQL_TO_AS400
        BEGIN
            -- Check if the name contains the MS indicator
            IF CHARINDEX(@con_MSChar_Indicator, @var_FoundColumnName) > 0
            BEGIN
                -- For MSSQL column names (with "_____"), extract the AS400 code part
                SET @var_TranslatedColumnName = RIGHT(@var_FoundColumnName, 
                    LEN(@var_FoundColumnName) - CHARINDEX(@con_MSChar_Indicator, @var_FoundColumnName) - 4);
            END
            ELSE
            BEGIN
                -- If no indicator and not already an AS400 name, keep as is
                SET @var_TranslatedColumnName = @var_FoundColumnName;
            END
        END
        
        -- Only apply translation if we got a valid result
        IF @var_TranslatedColumnName IS NOT NULL AND @var_TranslatedColumnName <> @var_FoundColumnName
        BEGIN
            -- Debug information
            IF @DebugMode = 1
                PRINT 'Translated to: ' + @var_TranslatedColumnName;
            
            -- Replace all occurrences of the column name considering word boundaries
            SET @var_TranslatedQuery = REPLACE(@var_TranslatedQuery, 
                ' ' + @var_FoundColumnName + ' ', ' ' + @var_TranslatedColumnName + ' ');
            SET @var_TranslatedQuery = REPLACE(@var_TranslatedQuery, 
                ' ' + @var_FoundColumnName + ',', ' ' + @var_TranslatedColumnName + ',');
            SET @var_TranslatedQuery = REPLACE(@var_TranslatedQuery, 
                ' ' + @var_FoundColumnName + ')', ' ' + @var_TranslatedColumnName + ')');
            SET @var_TranslatedQuery = REPLACE(@var_TranslatedQuery, 
                ',' + @var_FoundColumnName + ' ', ',' + @var_TranslatedColumnName + ' ');
            SET @var_TranslatedQuery = REPLACE(@var_TranslatedQuery, 
                ',' + @var_FoundColumnName + ',', ',' + @var_TranslatedColumnName + ',');
            SET @var_TranslatedQuery = REPLACE(@var_TranslatedQuery, 
                ',' + @var_FoundColumnName + ')', ',' + @var_TranslatedColumnName + ')');
            SET @var_TranslatedQuery = REPLACE(@var_TranslatedQuery, 
                '(' + @var_FoundColumnName + ' ', '(' + @var_TranslatedColumnName + ' ');
            SET @var_TranslatedQuery = REPLACE(@var_TranslatedQuery, 
                '(' + @var_FoundColumnName + ',', '(' + @var_TranslatedColumnName + ',');
            SET @var_TranslatedQuery = REPLACE(@var_TranslatedQuery, 
                '(' + @var_FoundColumnName + ')', '(' + @var_TranslatedColumnName + ')');
        END
        
        -- Increment counter
        SET @var_IntCounter = @var_IntCounter + 1;
    END
    
    -- Clean up temporary tables
    DROP TABLE #TablesAndSchemas;
    DROP TABLE #ColumnNames;
    
    -- Debug information
    IF @DebugMode = 1
    BEGIN
        PRINT 'Column name translation completed';
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
GO

/*****************************************************************
-- =============================================
-- Example Usage for usp_TranslateSQLQuery
-- =============================================

-- Example 1: AS400 to MSSQL Translation (Debug Mode ON)
DECLARE @InputQueryAS400 NVARCHAR(MAX) = 'SELECT * FROM [VENDREMT]';
DECLARE @OutputQueryMSSQL NVARCHAR(MAX);

EXEC [mrs].[usp_TranslateSQLQuery] 
    @SQLQuery = @InputQueryAS400, 
    @DebugMode = 1, 
    @TranslatedQuery = @OutputQueryMSSQL OUTPUT;

SELECT @OutputQueryMSSQL AS [MSSQL_Translated_Query];
-- Expected result: SELECT * FROM [z_Vendor_Remote_File_____VENDREMT]

-- Example 2: MSSQL to AS400 Translation (Debug Mode ON)
DECLARE @InputQueryMSSQL NVARCHAR(MAX) = 'SELECT CUSTOMER_NUMBER_____CCUST, PRODUCT_CODE_____CPROD FROM [z_Customer_Master_File_____ARCUST]';
DECLARE @OutputQueryAS400 NVARCHAR(MAX);

EXEC [mrs].[usp_TranslateSQLQuery] 
    @SQLQuery = @InputQueryMSSQL, 
    @DebugMode = 1, 
    @TranslatedQuery = @OutputQueryAS400 OUTPUT;

SELECT @OutputQueryAS400 AS [AS400_Translated_Query];
-- Expected result: SELECT CCUST, CPROD FROM [ARCUST]

-- Example 3: Complex Query with JOINs (AS400 to MSSQL)
DECLARE @ComplexQueryAS400 NVARCHAR(MAX) = 'SELECT a.CCUST, a.CPROD, b.ORDRNO 
                                            FROM [ARCUST] a 
                                            JOIN [ORDERS] b ON a.CCUST = b.CUSTNO 
                                            WHERE a.CSTAT = ''A''';
DECLARE @ComplexQueryMSSQL NVARCHAR(MAX);

EXEC [mrs].[usp_TranslateSQLQuery] 
    @SQLQuery = @ComplexQueryAS400, 
    @DebugMode = 0, 
    @TranslatedQuery = @ComplexQueryMSSQL OUTPUT;

SELECT @ComplexQueryMSSQL AS [Complex_MSSQL_Translated_Query];
-- Expected result will translate all table and column names to their MSSQL equivalents

-- Example 4: Complex Query with JOINs (MSSQL to AS400)
DECLARE @ComplexQueryMSSQL NVARCHAR(MAX) = 'SELECT a.CUSTOMER_NUMBER_____CCUST, a.PRODUCT_CODE_____CPROD, b.ORDER_NUMBER_____ORDRNO 
                                            FROM [z_Customer_Master_File_____ARCUST] a 
                                            JOIN [z_Order_Header_File_____ORDERS] b ON a.CUSTOMER_NUMBER_____CCUST = b.CUSTOMER_NUMBER_____CUSTNO 
                                            WHERE a.CUSTOMER_STATUS_____CSTAT = ''A''';
DECLARE @ComplexQueryAS400 NVARCHAR(MAX);

EXEC [mrs].[usp_TranslateSQLQuery] 
    @SQLQuery = @ComplexQueryMSSQL, 
    @DebugMode = 0, 
    @TranslatedQuery = @ComplexQueryAS400 OUTPUT;

SELECT @ComplexQueryAS400 AS [Complex_AS400_Translated_Query];
-- Expected result will translate all table and column names to their AS400 equivalents
*****************************************************************/