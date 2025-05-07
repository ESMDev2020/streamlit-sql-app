USE SigmaTB;
GO

/*
Stored Procedure: mrs.IdentifyPotentialPKs
Purpose: Identifies potential primary keys with proper variable scoping
Parameters:
    @DebugMode - 1 = Detailed logging, 0 = Silent
    @ExecuteFromZero - 1 = Fresh start, 0 = Resume
*/
CREATE OR ALTER PROCEDURE mrs.IdentifyPotentialPKs
    @DebugMode BIT = 0,
    @ExecuteFromZero BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Single declaration of all variables
    DECLARE @myConNvDbName NVARCHAR(128) = 'SigmaTB',
            @myConNvSchemaName NVARCHAR(128) = 'mrs',
            @myConNvResultsTable NVARCHAR(128) = 'PKCheckResults',
            @myVarNvCurrentTable NVARCHAR(128),
            @myVarNvCurrentColumn NVARCHAR(128),
            @myVarIntTableRows INT,
            @myVarIntDistinctCount INT,
            @myVarNvDynamicSQL NVARCHAR(MAX),
            @myVarIntTotalTables INT,
            @myVarIntProcessedTables INT = 0,
            @myVarIntTotalColumns INT,
            @myVarIntProcessedColumns INT = 0,
            @myVarBitSkipColumn BIT,
            @myVarBitHasPK BIT,
            @myVarDtProcessStart DATETIME,
            @myVarDtTableStart DATETIME,
            @myVarDtColumnStart DATETIME;

    BEGIN TRY
        IF @DebugMode = 1
        BEGIN
            PRINT CONVERT(NVARCHAR, GETDATE(), 120) + ' - PROC START';
            SET @myVarDtProcessStart = GETDATE();
        END

        -- Results table handling
        IF @ExecuteFromZero = 1
        BEGIN
            IF OBJECT_ID('mrs.PKCheckResults') IS NOT NULL
            BEGIN
                DROP TABLE mrs.[PKCheckResults];
                IF @DebugMode = 1
                    PRINT CONVERT(NVARCHAR, GETDATE(), 120) + ' - Dropped existing results table';
            END
            
            CREATE TABLE mrs.[PKCheckResults] (
                TableName NVARCHAR(128),
                [RowCount] INT,
                Comment NVARCHAR(255),
                ColumnPK NVARCHAR(128)
            );
        END
        ELSE IF OBJECT_ID('mrs.PKCheckResults') IS NULL
        BEGIN
            CREATE TABLE mrs.[PKCheckResults] (
                TableName NVARCHAR(128),
                [RowCount] INT,
                Comment NVARCHAR(255),
                ColumnPK NVARCHAR(128)
            );
        END

        -- Get tables to process
        DECLARE myCurTables CURSOR LOCAL STATIC FOR
        SELECT t.TABLE_NAME
        FROM INFORMATION_SCHEMA.TABLES t
        LEFT JOIN mrs.[PKCheckResults] r
            ON t.TABLE_NAME = r.TableName
        WHERE t.TABLE_SCHEMA = @myConNvSchemaName
            AND t.TABLE_TYPE = 'BASE TABLE'
            AND (r.TableName IS NULL OR @ExecuteFromZero = 1);

        OPEN myCurTables;
        FETCH NEXT FROM myCurTables INTO @myVarNvCurrentTable;

        -- Main processing loop
        WHILE @@FETCH_STATUS = 0
        BEGIN
            BEGIN TRY
                BEGIN TRANSACTION;

                -- Get table row count
                SET @myVarDtTableStart = GETDATE();
                SET @myVarNvDynamicSQL = N'SELECT @rc = COUNT(*) FROM ' 
                    + QUOTENAME(@myConNvSchemaName) + '.' 
                    + QUOTENAME(@myVarNvCurrentTable);
                
                EXEC sp_executesql @myVarNvDynamicSQL, 
                    N'@rc INT OUTPUT', 
                    @myVarIntTableRows OUTPUT;

                -- Debug: Table progress
                SET @myVarIntProcessedTables += 1;
                IF @DebugMode = 1
                BEGIN
                    PRINT CONVERT(NVARCHAR, GETDATE(), 120) + 
                        ' - Processing table ' + CAST(@myVarIntProcessedTables AS NVARCHAR) + 
                        ': ' + @myVarNvCurrentTable + 
                        ' (' + CAST(@myVarIntTableRows AS NVARCHAR) + ' rows)';
                END

                -- Column analysis
                DECLARE myCurColumns CURSOR LOCAL FAST_FORWARD FOR
                SELECT COLUMN_NAME
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_SCHEMA = @myConNvSchemaName
                    AND TABLE_NAME = @myVarNvCurrentTable;

                OPEN myCurColumns;
                FETCH NEXT FROM myCurColumns INTO @myVarNvCurrentColumn;

                SET @myVarBitHasPK = 0;
                WHILE @@FETCH_STATUS = 0 AND @myVarBitHasPK = 0
                BEGIN
                    -- Column exclusion check
                    SET @myVarBitSkipColumn = CASE
                        WHEN RIGHT(@myVarNvCurrentColumn, 2) IN ('DD','MM','YY','CC') THEN 1
                        WHEN RIGHT(@myVarNvCurrentColumn, 3) IN ('QTY','UOM') THEN 1
                        ELSE 0
                    END;

                    IF @myVarBitSkipColumn = 0
                    BEGIN
                        -- Distinct count check
                        SET @myVarDtColumnStart = GETDATE();
                        SET @myVarNvDynamicSQL = N'SELECT @dc = COUNT(DISTINCT ' 
                            + QUOTENAME(@myVarNvCurrentColumn) + ') FROM ' 
                            + QUOTENAME(@myConNvSchemaName) + '.' 
                            + QUOTENAME(@myVarNvCurrentTable);

                        EXEC sp_executesql @myVarNvDynamicSQL, 
                            N'@dc INT OUTPUT', 
                            @myVarIntDistinctCount OUTPUT;

                        -- Debug: Column analysis
                        IF @DebugMode = 1
                        BEGIN
                            PRINT CONVERT(NVARCHAR, GETDATE(), 120) + 
                                ' - Analyzed column: ' + @myVarNvCurrentColumn + 
                                ' | Distinct: ' + CAST(@myVarIntDistinctCount AS NVARCHAR) + 
                                ' | Time: ' + 
                                CAST(DATEDIFF(MILLISECOND, @myVarDtColumnStart, GETDATE()) AS NVARCHAR) + 'ms';
                        END

                        -- PK check
                        IF @myVarIntDistinctCount = @myVarIntTableRows
                        BEGIN
                            INSERT INTO mrs.[PKCheckResults] (
                                TableName,
                                [RowCount],
                                Comment,
                                ColumnPK
                            ) VALUES (
                                @myVarNvCurrentTable,
                                @myVarIntTableRows,
                                'PK found',
                                @myVarNvCurrentColumn
                            );
                            SET @myVarBitHasPK = 1;
                        END
                    END

                    FETCH NEXT FROM myCurColumns INTO @myVarNvCurrentColumn;
                END

                CLOSE myCurColumns;
                DEALLOCATE myCurColumns;

                -- Handle no PK found
                IF @myVarBitHasPK = 0
                BEGIN
                    INSERT INTO mrs.[PKCheckResults] (
                        TableName,
                        [RowCount],
                        Comment,
                        ColumnPK
                    ) VALUES (
                        @myVarNvCurrentTable,
                        @myVarIntTableRows,
                        'no PK found',
                        NULL
                    );
                END

                COMMIT TRANSACTION;
                FETCH NEXT FROM myCurTables INTO @myVarNvCurrentTable;
            END TRY
            BEGIN CATCH
                IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
                DECLARE @errMsg NVARCHAR(2000) = 
                    'Error processing ' + QUOTENAME(@myVarNvCurrentTable) + 
                    ': ' + ERROR_MESSAGE();
                RAISERROR(@errMsg, 16, 1);
            END CATCH
        END

        CLOSE myCurTables;
        DEALLOCATE myCurTables;

        IF @DebugMode = 1
        BEGIN
            PRINT CONVERT(NVARCHAR, GETDATE(), 120) + ' - PROC COMPLETE';
            PRINT 'Total execution time: ' + 
                CAST(DATEDIFF(SECOND, @myVarDtProcessStart, GETDATE()) AS NVARCHAR) + ' seconds';
        END
    END TRY
    BEGIN CATCH
        DECLARE @finalErr NVARCHAR(2000) = 'Procedure failed: ' + ERROR_MESSAGE();
        RAISERROR(@finalErr, 16, 1);
    END CATCH
END;
GO