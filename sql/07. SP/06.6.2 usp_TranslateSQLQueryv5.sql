USE [SigmaTB];
GO

IF OBJECT_ID('[mrs].[usp_TranslateSQLQuery]', 'P') IS NOT NULL
    DROP PROCEDURE [mrs].[usp_TranslateSQLQuery];
GO

-- =============================================
-- Author:      Gemini (Updated by Claude)
-- Create date: 2025-04-29
-- Modify date: 2025-05-07
-- Description: Translates object names (tables, columns) enclosed in square brackets
--              within a given SQL query string bidirectionally:
--              1. AS/400 short names to MSSQL long names (when no "_____" is present)
--              2. MSSQL long names to AS/400 short names (when "_____" is present)
--              Handles single objects like [TABLE1] and qualified objects like [TABLE1].[COLUMN1].
--              Includes debug mode and option to execute the translated query.
-- Parameters:
--   @SQLQuery NVARCHAR(MAX)      : The input SQL query string with object names in brackets
--   @DebugMode BIT = 0           : Optional. Set to 1 to enable debug messages (reduced)
--   @TranslatedQuery NVARCHAR(MAX) OUTPUT: The resulting translated query string
--   @Execution BIT = 0           : Optional. Set to 1 to execute the translated query
-- =============================================
CREATE PROCEDURE [mrs].[usp_TranslateSQLQuery]
    @SQLQuery NVARCHAR(MAX),
    @DebugMode BIT = 0,
    @TranslatedQuery NVARCHAR(MAX) OUTPUT,
    @Execution BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @myVarNVARCHARInputQuery NVARCHAR(MAX) = @SQLQuery,
        @myVarNVARCHARTranslatedQuery NVARCHAR(MAX) = N'',
        @myVarNVARCHARObjectName1 NVARCHAR(128),
        @myVarNVARCHARObjectName2 NVARCHAR(128),
        @myVarNVARCHARTranslatedName1 NVARCHAR(500),
        @myVarNVARCHARTranslatedName2 NVARCHAR(500),
        @myVarNVARCHARTranslatedObject NVARCHAR(MAX),
        @myVarINTCurrentPosition INT = 1,
        @myVarINTInputLength INT,
        @myVarINTStartBracketPos1 INT,
        @myVarINTEndBracketPos1 INT,
        @myVarINTStartBracketPos2 INT,
        @myVarINTEndBracketPos2 INT,
        @myVarBITIsTableColumnPair BIT = 0,
        @myVarBITIsAS400ToMSSQL BIT, -- Direction flag
        @myVarNVARCHARErrorMessage NVARCHAR(MAX),
        @myVarNVARCHARSQL NVARCHAR(MAX),
        @myVarINTErrorSeverity INT,
        @myVarINTErrorState INT;

    IF @DebugMode = 1 
    BEGIN
        PRINT N'-- Query translation started. ' + 
              N'Input length: ' + CAST(LEN(@myVarNVARCHARInputQuery) AS NVARCHAR(10)) + 
              N', Debug: ON' + 
              CASE WHEN @Execution = 1 THEN N', Execution: ON' ELSE N'' END;
    END

    IF @myVarNVARCHARInputQuery IS NULL
    BEGIN
        SET @TranslatedQuery = NULL;
        IF @DebugMode = 1 PRINT N'-- Input query is NULL. Returning NULL.';
        RETURN;
    END;

    SET @myVarINTInputLength = LEN(@myVarNVARCHARInputQuery);

    IF @myVarINTInputLength = 0
    BEGIN
        SET @TranslatedQuery = N'';
        IF @DebugMode = 1 PRINT N'-- Input query is empty. Returning empty string.';
        RETURN;
    END;

    WHILE @myVarINTCurrentPosition <= @myVarINTInputLength
    BEGIN
        SET @myVarINTStartBracketPos1 = CHARINDEX(N'[', @myVarNVARCHARInputQuery, @myVarINTCurrentPosition);

        IF @myVarINTStartBracketPos1 = 0
        BEGIN
            -- No more brackets found, append the rest of the string
            SET @myVarNVARCHARTranslatedQuery += SUBSTRING(@myVarNVARCHARInputQuery, @myVarINTCurrentPosition, @myVarINTInputLength - @myVarINTCurrentPosition + 1);
            BREAK; -- Exit the loop
        END
        ELSE
        BEGIN
            -- Append the text before the bracket
            SET @myVarNVARCHARTranslatedQuery += SUBSTRING(@myVarNVARCHARInputQuery, @myVarINTCurrentPosition, @myVarINTStartBracketPos1 - @myVarINTCurrentPosition);

            SET @myVarINTEndBracketPos1 = CHARINDEX(N']', @myVarNVARCHARInputQuery, @myVarINTStartBracketPos1 + 1);

            IF @myVarINTEndBracketPos1 = 0 OR @myVarINTEndBracketPos1 < @myVarINTStartBracketPos1
            BEGIN
                -- Malformed input: Opening bracket without a closing one
                SET @myVarNVARCHARErrorMessage = N'Malformed input string: Unmatched bracket at position ' + CAST(@myVarINTStartBracketPos1 AS NVARCHAR(10));
                IF @DebugMode = 1 PRINT N'-- ERROR: ' + @myVarNVARCHARErrorMessage;
                RAISERROR(@myVarNVARCHARErrorMessage, 16, 1);
            END;

            SET @myVarNVARCHARObjectName1 = SUBSTRING(@myVarNVARCHARInputQuery, @myVarINTStartBracketPos1 + 1, @myVarINTEndBracketPos1 - @myVarINTStartBracketPos1 - 1);
            SET @myVarBITIsTableColumnPair = 0; -- Reset flag

            -- Skip translation for schema-qualified objects
            IF @myVarNVARCHARObjectName1 LIKE 'mrs.%'
            BEGIN
                SET @myVarNVARCHARTranslatedObject = N'[' + @myVarNVARCHARObjectName1 + N']';
                SET @myVarINTCurrentPosition = @myVarINTEndBracketPos1 + 1;
                IF @DebugMode = 1 PRINT N'-- Found schema-qualified object [' + @myVarNVARCHARObjectName1 + N'], skipping translation';
                SET @myVarNVARCHARTranslatedQuery += @myVarNVARCHARTranslatedObject;
                CONTINUE;
            END

            -- Determine conversion direction based on "_____" pattern
            SET @myVarBITIsAS400ToMSSQL = CASE WHEN CHARINDEX(N'_____', @myVarNVARCHARObjectName1) = 0 THEN 1 ELSE 0 END;
            
            IF @DebugMode = 1 
            BEGIN
                PRINT N'-- Object: [' + @myVarNVARCHARObjectName1 + N'], Direction: ' + 
                      CASE WHEN @myVarBITIsAS400ToMSSQL = 1 THEN 'AS400 to MSSQL' ELSE 'MSSQL to AS400' END;
            END

            -- Check for '.[' pattern immediately following the first closing bracket
            IF (@myVarINTEndBracketPos1 + 2) <= @myVarINTInputLength AND SUBSTRING(@myVarNVARCHARInputQuery, @myVarINTEndBracketPos1 + 1, 2) = N'.['
            BEGIN
                SET @myVarINTStartBracketPos2 = @myVarINTEndBracketPos1 + 2;
                SET @myVarINTEndBracketPos2 = CHARINDEX(N']', @myVarNVARCHARInputQuery, @myVarINTStartBracketPos2 + 1);

                IF @myVarINTEndBracketPos2 > @myVarINTStartBracketPos2
                BEGIN
                    SET @myVarNVARCHARObjectName2 = SUBSTRING(@myVarNVARCHARInputQuery, @myVarINTStartBracketPos2 + 1, @myVarINTEndBracketPos2 - @myVarINTStartBracketPos2 - 1);
                    
                    IF LEN(@myVarNVARCHARObjectName1) > 0 AND LEN(@myVarNVARCHARObjectName2) > 0
                    BEGIN
                       SET @myVarBITIsTableColumnPair = 1;
                    END
                    ELSE
                    BEGIN
                         SET @myVarBITIsTableColumnPair = 0; -- Ensure flag is reset if second part is empty
                    END
                END
                ELSE
                BEGIN
                    SET @myVarBITIsTableColumnPair = 0; -- Treat first part as single object
                END;
            END;

            -- Reset translation variables
            SET @myVarNVARCHARTranslatedObject = NULL;
            SET @myVarNVARCHARTranslatedName1 = NULL;
            SET @myVarNVARCHARTranslatedName2 = NULL;

            IF @myVarBITIsTableColumnPair = 1
            BEGIN
                -- Handle table.column pair translation
                IF @myVarBITIsAS400ToMSSQL = 1
                BEGIN
                    -- AS400 to MSSQL translation
                    BEGIN TRY
                        EXEC [mrs].[usp_TranslateObjectName] @InputName = @myVarNVARCHARObjectName1, @ContextTableName = NULL, @TranslatedName = @myVarNVARCHARTranslatedName1 OUTPUT;
                    END TRY
                    BEGIN CATCH
                        SET @myVarNVARCHARTranslatedName1 = NULL; -- Ensure it's null on error
                    END CATCH

                    -- Translate the second part (potential column) using original AS400 table name as context
                    BEGIN TRY
                        EXEC [mrs].[usp_TranslateObjectName] @InputName = @myVarNVARCHARObjectName2, @ContextTableName = @myVarNVARCHARObjectName1, @TranslatedName = @myVarNVARCHARTranslatedName2 OUTPUT;
                    END TRY
                    BEGIN CATCH
                        SET @myVarNVARCHARTranslatedName2 = NULL; -- Ensure it's null on error
                    END CATCH
                END
                ELSE -- MSSQL to AS400 translation
                BEGIN
                    -- Extract AS400 table name from MSSQL format (after the "_____")
                    DECLARE @TableAS400Name NVARCHAR(128);
                    
                    -- For table part
                    BEGIN TRY
                        -- Look for "_____" pattern in the table name
                        DECLARE @UnderscorePos1 INT = CHARINDEX(N'_____', @myVarNVARCHARObjectName1);
                        IF @UnderscorePos1 > 0
                        BEGIN
                            -- Extract AS400 name which is after "_____"
                            SET @TableAS400Name = SUBSTRING(@myVarNVARCHARObjectName1, @UnderscorePos1 + 5, LEN(@myVarNVARCHARObjectName1) - @UnderscorePos1 - 5 + 1);
                            SET @myVarNVARCHARTranslatedName1 = @TableAS400Name;
                        END
                        ELSE
                        BEGIN
                            -- No "_____" found in table name, use as is
                            SET @myVarNVARCHARTranslatedName1 = @myVarNVARCHARObjectName1;
                        END
                    END TRY
                    BEGIN CATCH
                        SET @myVarNVARCHARTranslatedName1 = NULL;
                    END CATCH
                    
                    -- For column part
                    BEGIN TRY
                        -- Look for "_____" pattern in the column name
                        DECLARE @UnderscorePos2 INT = CHARINDEX(N'_____', @myVarNVARCHARObjectName2);
                        IF @UnderscorePos2 > 0
                        BEGIN
                            -- Extract AS400 name which is after "_____"
                            SET @myVarNVARCHARTranslatedName2 = SUBSTRING(@myVarNVARCHARObjectName2, @UnderscorePos2 + 5, LEN(@myVarNVARCHARObjectName2) - @UnderscorePos2 - 5 + 1);
                        END
                        ELSE
                        BEGIN
                            -- No "_____" found in column name, use as is
                            SET @myVarNVARCHARTranslatedName2 = @myVarNVARCHARObjectName2;
                        END
                    END TRY
                    BEGIN CATCH
                        SET @myVarNVARCHARTranslatedName2 = NULL;
                    END CATCH
                END

                -- Construct the translated pair or use fallbacks
                IF @myVarNVARCHARTranslatedName1 IS NOT NULL
                BEGIN
                    IF @myVarNVARCHARTranslatedName2 IS NOT NULL
                        SET @myVarNVARCHARTranslatedObject = QUOTENAME(@myVarNVARCHARTranslatedName1) + N'.' + QUOTENAME(@myVarNVARCHARTranslatedName2);
                    ELSE -- Table translated, column did not
                        SET @myVarNVARCHARTranslatedObject = QUOTENAME(@myVarNVARCHARTranslatedName1) + N'.[' + @myVarNVARCHARObjectName2 + N']'; -- Use original column name
                END
                ELSE -- Table did not translate
                BEGIN
                    IF @myVarNVARCHARTranslatedName2 IS NOT NULL -- Column translated
                        SET @myVarNVARCHARTranslatedObject = N'[' + @myVarNVARCHARObjectName1 + N'].' + QUOTENAME(@myVarNVARCHARTranslatedName2); -- Use original table name
                    ELSE -- Neither translated
                        SET @myVarNVARCHARTranslatedObject = N'[' + @myVarNVARCHARObjectName1 + N'].[' + @myVarNVARCHARObjectName2 + N']'; -- Use original pair
                END;

                -- Advance position past the second bracket
                SET @myVarINTCurrentPosition = @myVarINTEndBracketPos2 + 1;
            END
            ELSE -- Not a table.column pair, or second part was invalid
            BEGIN
                -- Handle single object translation
                IF @myVarBITIsAS400ToMSSQL = 1
                BEGIN
                    -- AS400 to MSSQL translation
                    BEGIN TRY
                        EXEC [mrs].[usp_TranslateObjectName] @InputName = @myVarNVARCHARObjectName1, @ContextTableName = NULL, @TranslatedName = @myVarNVARCHARTranslatedName1 OUTPUT;
                    END TRY
                    BEGIN CATCH
                         SET @myVarNVARCHARTranslatedName1 = NULL; -- Ensure it's null on error
                    END CATCH
                END
                ELSE -- MSSQL to AS400 translation
                BEGIN
                    BEGIN TRY
                        -- Look for "_____" pattern
                        DECLARE @UnderscorePos INT = CHARINDEX(N'_____', @myVarNVARCHARObjectName1);
                        IF @UnderscorePos > 0
                        BEGIN
                            -- Extract AS400 name which is after "_____"
                            SET @myVarNVARCHARTranslatedName1 = SUBSTRING(@myVarNVARCHARObjectName1, @UnderscorePos + 5, LEN(@myVarNVARCHARObjectName1) - @UnderscorePos - 5 + 1);
                        END
                        ELSE
                        BEGIN
                            -- No "_____" found, use as is
                            SET @myVarNVARCHARTranslatedName1 = @myVarNVARCHARObjectName1;
                        END
                    END TRY
                    BEGIN CATCH
                        SET @myVarNVARCHARTranslatedName1 = NULL;
                    END CATCH
                END

                -- Construct the translated name or use fallback
                IF @myVarNVARCHARTranslatedName1 IS NOT NULL
                    SET @myVarNVARCHARTranslatedObject = QUOTENAME(@myVarNVARCHARTranslatedName1);
                ELSE
                    SET @myVarNVARCHARTranslatedObject = N'[' + @myVarNVARCHARObjectName1 + N']'; -- Use original name if translation failed or returned NULL

                -- Advance position past the first bracket
                SET @myVarINTCurrentPosition = @myVarINTEndBracketPos1 + 1;
            END

            -- Append the translated (or original) name to the result query
            SET @myVarNVARCHARTranslatedQuery += ISNULL(@myVarNVARCHARTranslatedObject, N''); -- Use ISNULL just in case something went wrong
        END
    END

    SET @TranslatedQuery = @myVarNVARCHARTranslatedQuery;
    
    IF @DebugMode = 1 
    BEGIN
        PRINT N'-- Translation complete. Output length: ' + CAST(LEN(@TranslatedQuery) AS NVARCHAR(10));
    END
    
    -- Execute the translated query if requested
    IF @Execution = 1 AND @TranslatedQuery IS NOT NULL AND LEN(@TranslatedQuery) > 0
    BEGIN
        -- Handle schema addition while respecting existing schemas
        DECLARE @myVarNVARCHARQueryWithSchema NVARCHAR(MAX);
        SET @myVarNVARCHARQueryWithSchema = @TranslatedQuery;
        
        -- Process schema references - only add schema to tables without schema
        SET @myVarNVARCHARQueryWithSchema = REPLACE(@myVarNVARCHARQueryWithSchema, ' FROM [', ' FROM [mrs].[');
        SET @myVarNVARCHARQueryWithSchema = REPLACE(@myVarNVARCHARQueryWithSchema, ' JOIN [', ' JOIN [mrs].[');
        SET @myVarNVARCHARQueryWithSchema = REPLACE(@myVarNVARCHARQueryWithSchema, ', [', ', [mrs].[');
        
        -- Fix schema references - adjust for cases where schema is already present
        SET @myVarNVARCHARQueryWithSchema = REPLACE(@myVarNVARCHARQueryWithSchema, '[mrs].[mrs].[', '[mrs].[');
        SET @myVarNVARCHARQueryWithSchema = REPLACE(@myVarNVARCHARQueryWithSchema, '[mrs].[mrs].', '[mrs].');
        
        -- Final SQL with NOCOUNT
        SET @myVarNVARCHARSQL = N'SET NOCOUNT ON; ' + @myVarNVARCHARQueryWithSchema;
        
        IF @DebugMode = 1 
        BEGIN
            PRINT N'-- Executing query with schema: ';
            PRINT @myVarNVARCHARSQL;
        END
        
        BEGIN TRY
            EXEC sp_executesql @myVarNVARCHARSQL;
            
            IF @DebugMode = 1 PRINT N'-- Query executed successfully.';
        END TRY
        BEGIN CATCH
            SET @myVarNVARCHARErrorMessage = ERROR_MESSAGE();
            SET @myVarINTErrorSeverity = ERROR_SEVERITY();
            SET @myVarINTErrorState = ERROR_STATE();
            
            IF @DebugMode = 1 
            BEGIN
                PRINT N'-- Execution error: ' + @myVarNVARCHARErrorMessage;
            END
            
            -- Re-throw the caught error
            RAISERROR(@myVarNVARCHARErrorMessage, @myVarINTErrorSeverity, @myVarINTErrorState)
        END CATCH
    END
END
GO