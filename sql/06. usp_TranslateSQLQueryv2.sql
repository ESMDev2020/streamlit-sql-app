USE [SigmaTB];
GO

IF OBJECT_ID('[mrs].[usp_TranslateSQLQuery]', 'P') IS NOT NULL
    DROP PROCEDURE [mrs].[usp_TranslateSQLQuery];
GO

-- =============================================
-- Author:      Gemini
-- Create date: 2025-04-29
-- Modify date: 2025-04-30
-- Description: Translates AS/400 object names (tables, columns) enclosed
--              in square brackets within a given SQL query string to their
--              corresponding MSSQL names using the [mrs].[usp_TranslateObjectName] procedure.
--              Handles single objects like [TABLE1] and qualified objects like [TABLE1].[COLUMN1].
--              Includes an optional debug mode.
-- Parameters:
--   @p_InputQuery NVARCHAR(MAX): The input SQL query string with AS/400 names
--                                 in brackets (e.g., "SELECT [COL1] FROM [TABLE1]").
--   @p_TranslatedQuery NVARCHAR(MAX) OUTPUT: The resulting query string with
--                                             MSSQL names. NULL on error or if input is NULL.
--   @p_DebugMode BIT = 0       : Optional. Set to 1 to enable debug PRINT messages.
--                                 Defaults to 0 (disabled).
-- Returns:     Outputs the translated query via @p_TranslatedQuery.
--              If @p_DebugMode = 1, prints debug information during execution.
--              Throws an error on malformed input or translation failures.
-- =============================================
CREATE PROCEDURE [mrs].[usp_TranslateSQLQuery]
    @p_InputQuery NVARCHAR(MAX),
    @p_TranslatedQuery NVARCHAR(MAX) OUTPUT,
    @p_DebugMode BIT = 0 -- Added debug mode parameter, default is OFF
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @myVarNVARCHARInputQuery NVARCHAR(MAX) = @p_InputQuery,
        @myVarNVARCHARTranslatedQuery NVARCHAR(MAX) = N'',
        @myVarNVARCHARAS400Name1 NVARCHAR(128),
        @myVarNVARCHARAS400Name2 NVARCHAR(128),
        @myVarNVARCHARTranslatedName1 NVARCHAR(500),
        @myVarNVARCHARTranslatedName2 NVARCHAR(500),
        @myVarNVARCHARMSSQLName NVARCHAR(MAX),
        @myVarINTCurrentPosition INT = 1,
        @myVarINTInputLength INT,
        @myVarINTStartBracketPos1 INT,
        @myVarINTEndBracketPos1 INT,
        @myVarINTStartBracketPos2 INT,
        @myVarINTEndBracketPos2 INT,
        @myVarBITIsTableColumnPair BIT = 0,
        @myVarNVARCHARErrorMessage NVARCHAR(MAX),
        @myVarINTErrorSeverity INT,
        @myVarINTErrorState INT;

    IF @p_DebugMode = 1 PRINT N'-- usp_TranslateSQLQuery Start --';
    IF @p_DebugMode = 1 PRINT N'-- Input Query: ' + ISNULL(@myVarNVARCHARInputQuery, 'NULL');
    IF @p_DebugMode = 1 PRINT N'-- Debug Mode: ON';

    IF @myVarNVARCHARInputQuery IS NULL
    BEGIN
        SET @p_TranslatedQuery = NULL;
        IF @p_DebugMode = 1 PRINT N'-- Input query is NULL. Returning NULL. --';
        RETURN;
    END;

    SET @myVarINTInputLength = LEN(@myVarNVARCHARInputQuery);

    IF @myVarINTInputLength = 0
    BEGIN
        SET @p_TranslatedQuery = N'';
        IF @p_DebugMode = 1 PRINT N'-- Input query is empty. Returning empty string. --';
        RETURN;
    END;

    WHILE @myVarINTCurrentPosition <= @myVarINTInputLength
    BEGIN
        SET @myVarINTStartBracketPos1 = CHARINDEX(N'[', @myVarNVARCHARInputQuery, @myVarINTCurrentPosition);

        IF @myVarINTStartBracketPos1 = 0
        BEGIN
            -- No more brackets found, append the rest of the string
            SET @myVarNVARCHARTranslatedQuery += SUBSTRING(@myVarNVARCHARInputQuery, @myVarINTCurrentPosition, @myVarINTInputLength - @myVarINTCurrentPosition + 1);
            IF @p_DebugMode = 1 PRINT N'-- No more brackets found. Appending remaining string: ' + SUBSTRING(@myVarNVARCHARInputQuery, @myVarINTCurrentPosition, @myVarINTInputLength - @myVarINTCurrentPosition + 1);
            BREAK; -- Exit the loop
        END
        ELSE
        BEGIN
            -- Append the text before the bracket
            SET @myVarNVARCHARTranslatedQuery += SUBSTRING(@myVarNVARCHARInputQuery, @myVarINTCurrentPosition, @myVarINTStartBracketPos1 - @myVarINTCurrentPosition);
            IF @p_DebugMode = 1 AND (@myVarINTStartBracketPos1 - @myVarINTCurrentPosition > 0) PRINT N'-- Appending text before bracket: ' + SUBSTRING(@myVarNVARCHARInputQuery, @myVarINTCurrentPosition, @myVarINTStartBracketPos1 - @myVarINTCurrentPosition);

            SET @myVarINTEndBracketPos1 = CHARINDEX(N']', @myVarNVARCHARInputQuery, @myVarINTStartBracketPos1 + 1);

            IF @myVarINTEndBracketPos1 = 0 OR @myVarINTEndBracketPos1 < @myVarINTStartBracketPos1
            BEGIN
                -- Malformed input: Opening bracket without a closing one
                SET @myVarNVARCHARErrorMessage = N'Malformed input string: Unmatched bracket starting near position ' + CAST(@myVarINTStartBracketPos1 AS NVARCHAR(10));
                IF @p_DebugMode = 1 PRINT N'-- ERROR: ' + @myVarNVARCHARErrorMessage;
                THROW 50001, @myVarNVARCHARErrorMessage, 1;
            END;

            SET @myVarNVARCHARAS400Name1 = SUBSTRING(@myVarNVARCHARInputQuery, @myVarINTStartBracketPos1 + 1, @myVarINTEndBracketPos1 - @myVarINTStartBracketPos1 - 1);
            SET @myVarBITIsTableColumnPair = 0; -- Reset flag

            IF @p_DebugMode = 1 PRINT N'-- Found potential object 1: [' + @myVarNVARCHARAS400Name1 + N']';

            -- Check for '.[' pattern immediately following the first closing bracket
            IF (@myVarINTEndBracketPos1 + 2) <= @myVarINTInputLength AND SUBSTRING(@myVarNVARCHARInputQuery, @myVarINTEndBracketPos1 + 1, 2) = N'.['
            BEGIN
                SET @myVarINTStartBracketPos2 = @myVarINTEndBracketPos1 + 2;
                SET @myVarINTEndBracketPos2 = CHARINDEX(N']', @myVarNVARCHARInputQuery, @myVarINTStartBracketPos2 + 1);

                IF @myVarINTEndBracketPos2 > @myVarINTStartBracketPos2
                BEGIN
                    SET @myVarNVARCHARAS400Name2 = SUBSTRING(@myVarNVARCHARInputQuery, @myVarINTStartBracketPos2 + 1, @myVarINTEndBracketPos2 - @myVarINTStartBracketPos2 - 1);
                    IF LEN(@myVarNVARCHARAS400Name1) > 0 AND LEN(@myVarNVARCHARAS400Name2) > 0
                    BEGIN
                       SET @myVarBITIsTableColumnPair = 1;
                       IF @p_DebugMode = 1 PRINT N'-- Detected table.column pattern: [' + @myVarNVARCHARAS400Name1 + N'].[' + @myVarNVARCHARAS400Name2 + N']';
                    END
                    ELSE
                    BEGIN
                         IF @p_DebugMode = 1 PRINT N'-- Detected table.column pattern but one part is empty. Treating as single object.';
                         SET @myVarBITIsTableColumnPair = 0; -- Ensure flag is reset if second part is empty
                    END
                END
                ELSE
                BEGIN
                    -- Malformed: Found '[' after '.[' but no matching ']'
                    IF @p_DebugMode = 1 PRINT N'-- Detected ''.['' but no subsequent closing bracket. Treating [' + @myVarNVARCHARAS400Name1 + N'] as single object.';
                    SET @myVarBITIsTableColumnPair = 0; -- Treat first part as single object
                    -- No error throw, just proceed as if it wasn't a pair
                END;
            END;

            -- Reset translation variables
            SET @myVarNVARCHARMSSQLName = NULL;
            SET @myVarNVARCHARTranslatedName1 = NULL;
            SET @myVarNVARCHARTranslatedName2 = NULL;

            IF @myVarBITIsTableColumnPair = 1
            BEGIN
                -- Translate the first part (potential table)
                IF @p_DebugMode = 1 PRINT N'-->> Calling usp_TranslateObjectName [Table Part]: InputName=''' + @myVarNVARCHARAS400Name1 + ''', ContextTableName=NULL';
                BEGIN TRY
                    EXEC [mrs].[usp_TranslateObjectName] @InputName = @myVarNVARCHARAS400Name1, @ContextTableName = NULL, @TranslatedName = @myVarNVARCHARTranslatedName1 OUTPUT;
                    IF @p_DebugMode = 1 PRINT N'-->> Result [Table Part]: ' + ISNULL(QUOTENAME(@myVarNVARCHARTranslatedName1), 'NULL');
                END TRY
                BEGIN CATCH
                    IF @p_DebugMode = 1 PRINT N'-->> ERROR Translating [Table Part]: ' + @myVarNVARCHARAS400Name1;
                    SET @myVarNVARCHARTranslatedName1 = NULL; -- Ensure it's null on error
                    -- Optional: Decide whether to re-throw or just use original name
                    -- THROW; -- Uncomment to stop execution on table translation error
                END CATCH

                -- Translate the second part (potential column) using original AS400 table name as context
                IF @p_DebugMode = 1 PRINT N'-->> Calling usp_TranslateObjectName [Column Part]: InputName=''' + @myVarNVARCHARAS400Name2 + ''', ContextTableName=''' + ISNULL(@myVarNVARCHARAS400Name1, 'NULL') + '''';
                BEGIN TRY
                    EXEC [mrs].[usp_TranslateObjectName] @InputName = @myVarNVARCHARAS400Name2, @ContextTableName = @myVarNVARCHARAS400Name1, @TranslatedName = @myVarNVARCHARTranslatedName2 OUTPUT;
                    IF @p_DebugMode = 1 PRINT N'-->> Result [Column Part]: ' + ISNULL(QUOTENAME(@myVarNVARCHARTranslatedName2), 'NULL');
                END TRY
                BEGIN CATCH
                    IF @p_DebugMode = 1 PRINT N'-->> ERROR Translating [Column Part]: ' + @myVarNVARCHARAS400Name2 + N' with Context: ' + @myVarNVARCHARAS400Name1;
                    SET @myVarNVARCHARTranslatedName2 = NULL; -- Ensure it's null on error
                    -- Optional: Decide whether to re-throw or just use original name
                    -- THROW; -- Uncomment to stop execution on column translation error
                END CATCH

                -- Construct the translated pair or use fallbacks
                IF @myVarNVARCHARTranslatedName1 IS NOT NULL
                BEGIN
                    IF @myVarNVARCHARTranslatedName2 IS NOT NULL
                        SET @myVarNVARCHARMSSQLName = QUOTENAME(@myVarNVARCHARTranslatedName1) + N'.' + QUOTENAME(@myVarNVARCHARTranslatedName2);
                    ELSE -- Table translated, column did not
                        SET @myVarNVARCHARMSSQLName = QUOTENAME(@myVarNVARCHARTranslatedName1) + N'.[' + @myVarNVARCHARAS400Name2 + N']'; -- Use original column name
                END
                ELSE -- Table did not translate
                BEGIN
                    IF @myVarNVARCHARTranslatedName2 IS NOT NULL -- Column translated (unlikely without table context, but possible)
                        SET @myVarNVARCHARMSSQLName = N'[' + @myVarNVARCHARAS400Name1 + N'].' + QUOTENAME(@myVarNVARCHARTranslatedName2); -- Use original table name
                    ELSE -- Neither translated
                        SET @myVarNVARCHARMSSQLName = N'[' + @myVarNVARCHARAS400Name1 + N'].[' + @myVarNVARCHARAS400Name2 + N']'; -- Use original pair
                END;

                -- Advance position past the second bracket
                SET @myVarINTCurrentPosition = @myVarINTEndBracketPos2 + 1;
                IF @p_DebugMode = 1 PRINT N'-- Appending translated pair: ' + @myVarNVARCHARMSSQLName + N'. Advancing position to ' + CAST(@myVarINTCurrentPosition AS NVARCHAR(10));

            END
            ELSE -- Not a table.column pair, or second part was invalid
            BEGIN
                -- Translate the single name
                IF @p_DebugMode = 1 PRINT N'-->> Calling usp_TranslateObjectName [Single Part]: InputName=''' + @myVarNVARCHARAS400Name1 + ''', ContextTableName=NULL';
                BEGIN TRY
                    EXEC [mrs].[usp_TranslateObjectName] @InputName = @myVarNVARCHARAS400Name1, @ContextTableName = NULL, @TranslatedName = @myVarNVARCHARTranslatedName1 OUTPUT;
                    IF @p_DebugMode = 1 PRINT N'-->> Result [Single Part]: ' + ISNULL(QUOTENAME(@myVarNVARCHARTranslatedName1), 'NULL');
                END TRY
                BEGIN CATCH
                     IF @p_DebugMode = 1 PRINT N'-->> ERROR Translating [Single Part]: ' + @myVarNVARCHARAS400Name1;
                     SET @myVarNVARCHARTranslatedName1 = NULL; -- Ensure it's null on error
                    -- Optional: Decide whether to re-throw or just use original name
                    -- THROW; -- Uncomment to stop execution on single object translation error
                END CATCH

                -- Construct the translated name or use fallback
                IF @myVarNVARCHARTranslatedName1 IS NOT NULL
                    SET @myVarNVARCHARMSSQLName = QUOTENAME(@myVarNVARCHARTranslatedName1);
                ELSE
                    SET @myVarNVARCHARMSSQLName = N'[' + @myVarNVARCHARAS400Name1 + N']'; -- Use original name if translation failed or returned NULL

                -- Advance position past the first bracket
                SET @myVarINTCurrentPosition = @myVarINTEndBracketPos1 + 1;
                IF @p_DebugMode = 1 PRINT N'-- Appending translated single object: ' + @myVarNVARCHARMSSQLName + N'. Advancing position to ' + CAST(@myVarINTCurrentPosition AS NVARCHAR(10));

            END

            -- Append the translated (or original) name to the result query
            SET @myVarNVARCHARTranslatedQuery += ISNULL(@myVarNVARCHARMSSQLName, N''); -- Use ISNULL just in case something went wrong
        END
    END

    SET @p_TranslatedQuery = @myVarNVARCHARTranslatedQuery;
    IF @p_DebugMode = 1 PRINT N'-- Final Translated Query: ' + ISNULL(@p_TranslatedQuery, 'NULL');
    IF @p_DebugMode = 1 PRINT N'-- usp_TranslateSQLQuery End --';

END
GO

/*
-- =============================================
-- Example Usage
-- =============================================

-- Assuming [mrs].[usp_TranslateObjectName] exists and is populated.
-- For example, it might translate:
-- 'TABLE1' -> 'MyMsSqlTable1'
-- 'COL1' (with context 'TABLE1') -> 'MsSqlColumnA'
-- 'COL2' (with context 'TABLE1') -> 'MsSqlColumnB'
-- 'OTHERTBL' -> 'OtherMsSqlTable'
-- 'FLD3' -> 'Field3'  (perhaps a global column name if context is NULL)

DECLARE @Input NVARCHAR(MAX);
DECLARE @Output NVARCHAR(MAX);

-- Example 1: Simple query, Debug OFF (Default)
SET @Input = N'SELECT [COL1], [COL2] FROM [TABLE1] WHERE [COL1] > 100';
SET @Output = NULL; -- Reset output variable
EXEC [mrs].[usp_TranslateSQLQuery] @p_InputQuery = @Input, @p_TranslatedQuery = @Output OUTPUT;
PRINT 'Example 1 (Debug OFF):';
PRINT @Output;
-- Expected Output (Example): SELECT [MsSqlColumnA], [MsSqlColumnB] FROM [MyMsSqlTable1] WHERE [MsSqlColumnA] > 100

-- Example 2: Query with table.column syntax, Debug ON
SET @Input = N'SELECT T1.[COL1], T2.[FLD3] FROM [TABLE1] AS T1 JOIN [OTHERTBL] AS T2 ON T1.[KEYCOL] = T2.[FKCOL]';
SET @Output = NULL; -- Reset output variable
EXEC [mrs].[usp_TranslateSQLQuery] @p_InputQuery = @Input, @p_TranslatedQuery = @Output OUTPUT, @p_DebugMode = 1;
PRINT 'Example 2 (Debug ON) - Output Query:';
PRINT @Output;
-- Expected Output (Example, assuming KEYCOL/FKCOL translate): SELECT T1.[MsSqlColumnA], T2.[Field3] FROM [MyMsSqlTable1] AS T1 JOIN [OtherMsSqlTable] AS T2 ON T1.[TranslatedKeyCol] = T2.[TranslatedFkCol]
-- (Debug messages will also be printed during execution)

-- Example 3: Query with mixed syntax and untranslatable parts, Debug OFF
SET @Input = N'SELECT [TABLE1].[COL1], [UNTRANS_TBL].[SOME_COL] FROM [TABLE1] LEFT JOIN [UNTRANS_TBL] ON [TABLE1].[ID] = [UNTRANS_TBL].[ID] WHERE [GLOBAL_FIELD] IS NOT NULL';
SET @Output = NULL; -- Reset output variable
EXEC [mrs].[usp_TranslateSQLQuery] @p_InputQuery = @Input, @p_TranslatedQuery = @Output OUTPUT;
PRINT 'Example 3 (Mixed/Untranslatable):';
PRINT @Output;
-- Expected Output (Example, assuming UNTRANS_TBL/SOME_COL/ID/GLOBAL_FIELD don't translate): SELECT [MyMsSqlTable1].[MsSqlColumnA], [UNTRANS_TBL].[SOME_COL] FROM [MyMsSqlTable1] LEFT JOIN [UNTRANS_TBL] ON [MyMsSqlTable1].[ID] = [UNTRANS_TBL].[ID] WHERE [GLOBAL_FIELD] IS NOT NULL

-- Example 4: Empty Input, Debug ON
SET @Input = N'';
SET @Output = NULL;
EXEC [mrs].[usp_TranslateSQLQuery] @p_InputQuery = @Input, @p_TranslatedQuery = @Output OUTPUT, @p_DebugMode = 1;
PRINT 'Example 4 (Empty Input):';
PRINT '|' + @Output + '|'; -- Print delimiters to show it's empty
-- Expected Output: || (and debug messages indicating empty input)


-- Example 5: NULL Input, Debug ON
SET @Input = NULL;
SET @Output = N'InitialValue'; -- Set to non-null to see if it gets set to NULL
EXEC [mrs].[usp_TranslateSQLQuery] @p_InputQuery = @Input, @p_TranslatedQuery = @Output OUTPUT, @p_DebugMode = 1;
PRINT 'Example 5 (NULL Input):';
PRINT ISNULL(@Output, 'NULL');
-- Expected Output: NULL (and debug messages indicating NULL input)

-- Example 6: Malformed Input (unmatched bracket), Debug ON
SET @Input = N'SELECT [COL1 FROM [TABLE1]';
SET @Output = NULL;
BEGIN TRY
    EXEC [mrs].[usp_TranslateSQLQuery] @p_InputQuery = @Input, @p_TranslatedQuery = @Output OUTPUT, @p_DebugMode = 1;
    PRINT 'Example 6 (Malformed Input):';
    PRINT ISNULL(@Output, 'NULL');
END TRY
BEGIN CATCH
    PRINT 'Example 6 Caught Error: ' + ERROR_MESSAGE();
END CATCH
-- Expected Output: Error message thrown by the procedure (and debug messages up to the error point)

*/