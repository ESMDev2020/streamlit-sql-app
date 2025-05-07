-- =============================================
-- Author:      Gemini
-- Create date: 2025-04-29
-- Description: Translates AS/400 object names (tables, columns) enclosed
--              in square brackets within a given SQL query string to their
--              corresponding MSSQL names using the [mrs].[usp_TranslateObjectName] procedure.
-- Parameters:
--   @p_InputQuery NVARCHAR(MAX): The input SQL query string with AS/400 names
--                                 in brackets (e.g., "SELECT [COL1] FROM [TABLE1]").
--   @p_TranslatedQuery NVARCHAR(MAX) OUTPUT: The resulting query string with
--                                            MSSQL names. NULL on error.
-- Returns:     Outputs the translated query via @p_TranslatedQuery.
--              Prints start and end timestamps.
--              Prints error information if an error occurs.
-- =============================================

-- =============================================
-- Author:      Gemini
-- Create date: 2025-04-29
-- Description: Translates AS/400 object names (tables, columns) enclosed
--              in square brackets within a given SQL query string to their
--              corresponding MSSQL names using the [mrs].[usp_TranslateObjectName] procedure.
--              Includes debug printing of parameters passed to usp_TranslateObjectName.
-- Parameters:
--   @p_InputQuery NVARCHAR(MAX): The input SQL query string with AS/400 names
--                                 in brackets (e.g., "SELECT [COL1] FROM [TABLE1]").
--   @p_TranslatedQuery NVARCHAR(MAX) OUTPUT: The resulting query string with
--                                            MSSQL names. NULL on error.
-- Returns:     Outputs the translated query via @p_TranslatedQuery.
--              Prints start and end timestamps.
--              Prints error information if an error occurs.
--              Prints debug info before calling usp_TranslateObjectName.
-- =============================================


-- =============================================
-- Corrected Stored Procedure: usp_TranslateSQLQuery (with Debug Prints)
-- =============================================

USE [SigmaTB];
GO

IF OBJECT_ID('[mrs].[usp_TranslateSQLQuery]', 'P') IS NOT NULL
    DROP PROCEDURE [mrs].[usp_TranslateSQLQuery];
GO

CREATE PROCEDURE [mrs].[usp_TranslateSQLQuery]
    @p_InputQuery NVARCHAR(MAX),
    @p_TranslatedQuery NVARCHAR(MAX) OUTPUT
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

    IF @myVarNVARCHARInputQuery IS NULL
    BEGIN
        SET @p_TranslatedQuery = NULL;
        RETURN;
    END;

    SET @myVarINTInputLength = LEN(@myVarNVARCHARInputQuery);

    IF @myVarINTInputLength = 0
    BEGIN
        SET @p_TranslatedQuery = N'';
        RETURN;
    END;

    WHILE @myVarINTCurrentPosition <= @myVarINTInputLength
    BEGIN
        SET @myVarINTStartBracketPos1 = CHARINDEX(N'[', @myVarNVARCHARInputQuery, @myVarINTCurrentPosition);

        IF @myVarINTStartBracketPos1 = 0
        BEGIN
            SET @myVarNVARCHARTranslatedQuery += SUBSTRING(@myVarNVARCHARInputQuery, @myVarINTCurrentPosition, @myVarINTInputLength - @myVarINTCurrentPosition + 1);
            BREAK;
        END
        ELSE
        BEGIN
            SET @myVarNVARCHARTranslatedQuery += SUBSTRING(@myVarNVARCHARInputQuery, @myVarINTCurrentPosition, @myVarINTStartBracketPos1 - @myVarINTCurrentPosition);
            SET @myVarINTEndBracketPos1 = CHARINDEX(N']', @myVarNVARCHARInputQuery, @myVarINTStartBracketPos1 + 1);

            IF @myVarINTEndBracketPos1 = 0 OR @myVarINTEndBracketPos1 < @myVarINTStartBracketPos1
            BEGIN
                SET @myVarNVARCHARErrorMessage = N'Malformed input string near position ' + CAST(@myVarINTStartBracketPos1 AS NVARCHAR(10));
                THROW 50001, @myVarNVARCHARErrorMessage, 1;
            END;

            SET @myVarNVARCHARAS400Name1 = SUBSTRING(@myVarNVARCHARInputQuery, @myVarINTStartBracketPos1 + 1, @myVarINTEndBracketPos1 - @myVarINTStartBracketPos1 - 1);
            SET @myVarBITIsTableColumnPair = 0;

            -- Check for '.[' following the first closing bracket to detect table.column pattern
            IF (@myVarINTEndBracketPos1 + 2) <= @myVarINTInputLength AND SUBSTRING(@myVarNVARCHARInputQuery, @myVarINTEndBracketPos1 + 1, 2) = N'.['
            BEGIN
                SET @myVarINTStartBracketPos2 = @myVarINTEndBracketPos1 + 2;
                SET @myVarINTEndBracketPos2 = CHARINDEX(N']', @myVarNVARCHARInputQuery, @myVarINTStartBracketPos2 + 1);

                IF @myVarINTEndBracketPos2 > @myVarINTStartBracketPos2
                BEGIN
                    SET @myVarNVARCHARAS400Name2 = SUBSTRING(@myVarNVARCHARInputQuery, @myVarINTStartBracketPos2 + 1, @myVarINTEndBracketPos2 - @myVarINTStartBracketPos2 - 1);
                    IF LEN(@myVarNVARCHARAS400Name1) > 0 AND LEN(@myVarNVARCHARAS400Name2) > 0
                        SET @myVarBITIsTableColumnPair = 1;
                    ELSE
                         SET @myVarBITIsTableColumnPair = 0; -- Ensure flag is reset if second part is empty
                END
                ELSE
                BEGIN
                     -- Malformed: Found '[' after '.[' but no matching ']'
                     SET @myVarBITIsTableColumnPair = 0; -- Treat first part as single object
                     -- No error throw, just proceed as if it wasn't a pair
                END;
            END;

            SET @myVarNVARCHARMSSQLName = NULL;
            SET @myVarNVARCHARTranslatedName1 = NULL; -- Reset for safety
            SET @myVarNVARCHARTranslatedName2 = NULL; -- Reset for safety

            IF @myVarBITIsTableColumnPair = 1
            BEGIN
                -- Translate the first part (potential table)
                PRINT N'-->> Calling usp_TranslateObjectName [Table Part]: InputName=''' + @myVarNVARCHARAS400Name1 + ''', ContextTableName=NULL'; -- DEBUG PRINT ADDED
                BEGIN TRY
                    EXEC [mrs].[usp_TranslateObjectName] @InputName = @myVarNVARCHARAS400Name1, @ContextTableName = NULL, @TranslatedName = @myVarNVARCHARTranslatedName1 OUTPUT;
                    PRINT N'-->> Result [Table Part]: ' + ISNULL(QUOTENAME(@myVarNVARCHARTranslatedName1), 'NULL'); -- DEBUG PRINT ADDED
                END TRY
                BEGIN CATCH
                    PRINT N'-->> ERROR Translating [Table Part]: ' + @myVarNVARCHARAS400Name1; -- DEBUG PRINT ADDED
                    SET @myVarNVARCHARTranslatedName1 = NULL;
                END CATCH

                -- Translate the second part (potential column)
                PRINT N'-->> Calling usp_TranslateObjectName [Column Part]: InputName=''' + @myVarNVARCHARAS400Name2 + ''', ContextTableName=''' + ISNULL(@myVarNVARCHARAS400Name1, 'NULL') + ''''; -- DEBUG PRINT ADDED
                BEGIN TRY
                     -- Pass the *original* AS400 Table Name as context
                    EXEC [mrs].[usp_TranslateObjectName] @InputName = @myVarNVARCHARAS400Name2, @ContextTableName = @myVarNVARCHARAS400Name1, @TranslatedName = @myVarNVARCHARTranslatedName2 OUTPUT;
                    PRINT N'-->> Result [Column Part]: ' + ISNULL(QUOTENAME(@myVarNVARCHARTranslatedName2), 'NULL'); -- DEBUG PRINT ADDED
                END TRY
                BEGIN CATCH
                    PRINT N'-->> ERROR Translating [Column Part]: ' + @myVarNVARCHARAS400Name2 + N' with Context: ' + @myVarNVARCHARAS400Name1; -- DEBUG PRINT ADDED
                    SET @myVarNVARCHARTranslatedName2 = NULL;
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
            END
            ELSE -- Not a table.column pair, or second part was invalid
            BEGIN
                -- Translate the single name
                 PRINT N'-->> Calling usp_TranslateObjectName [Single Part]: InputName=''' + @myVarNVARCHARAS400Name1 + ''', ContextTableName=NULL'; -- DEBUG PRINT ADDED
                BEGIN TRY
                    EXEC [mrs].[usp_TranslateObjectName] @InputName = @myVarNVARCHARAS400Name1, @ContextTableName = NULL, @TranslatedName = @myVarNVARCHARTranslatedName1 OUTPUT;
                    PRINT N'-->> Result [Single Part]: ' + ISNULL(QUOTENAME(@myVarNVARCHARTranslatedName1), 'NULL'); -- DEBUG PRINT ADDED
                END TRY
                BEGIN CATCH
                     PRINT N'-->> ERROR Translating [Single Part]: ' + @myVarNVARCHARAS400Name1; -- DEBUG PRINT ADDED
                    SET @myVarNVARCHARTranslatedName1 = NULL;
                END CATCH

                -- Construct the translated name or use fallback
                IF @myVarNVARCHARTranslatedName1 IS NOT NULL
                    SET @myVarNVARCHARMSSQLName = QUOTENAME(@myVarNVARCHARTranslatedName1);
                ELSE
                    SET @myVarNVARCHARMSSQLName = N'[' + @myVarNVARCHARAS400Name1 + N']'; -- Use original name

                -- Advance position past the first bracket
                SET @myVarINTCurrentPosition = @myVarINTEndBracketPos1 + 1;
            END

            -- Append the translated (or original) name to the result query
            SET @myVarNVARCHARTranslatedQuery += ISNULL(@myVarNVARCHARMSSQLName, N'');
        END
    END

    SET @p_TranslatedQuery = @myVarNVARCHARTranslatedQuery;

END
GO