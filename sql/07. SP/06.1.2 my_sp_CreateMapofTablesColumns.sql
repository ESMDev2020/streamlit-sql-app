-- Name: my_sp_CreateMapofTablesColumns
-- Description: Creates and populates the [mrs].[01_AS400_MSSQL_Equivalents_Columns] table
--              with AS400 to MSSQL table and column name mappings
-- Input: 
--    @DebugMode BIT - 1=Debug mode (shows detailed messages), 0=Normal mode (default)
--    @UpdateMaxMin BIT - 1=Update min/max values for each column, 0=Skip min/max update (default)
-- Output: Table [mrs].[01_AS400_MSSQL_Equivalents_Columns] created and populated
-- Metadata: Author: Claude, Creation Date: 2025-05-07, Version: 1.0
-- Example Usage: 
--    EXEC [mrs].[my_sp_CreateMapofTablesColumns] @DebugMode = 0, @UpdateMaxMin = 0 -- Create table only
--    EXEC [mrs].[my_sp_CreateMapofTablesColumns] @DebugMode = 1, @UpdateMaxMin = 0 -- Create table with debug output
--    EXEC [mrs].[my_sp_CreateMapofTablesColumns] @DebugMode = 0, @UpdateMaxMin = 1 -- Create table and update min/max
--    EXEC [mrs].[my_sp_CreateMapofTablesColumns] @DebugMode = 1, @UpdateMaxMin = 1 -- Full debug + min/max update
-- Example Resultset: N/A - Creates and populates a table with the following columns:
--    ID (IDENTITY) - Primary key
--    Schema - Database schema name
--    TableGroupName - Group name from [mrs].[01_AS400_MSSQL_Equivalents]
--    TableAS400Name - Original AS400 table name
--    TableMSSQLName - Corresponding MSSQL table name
--    ColumnAS400Name - Original AS400 column name
--    ColumnMSSQLName - Corresponding MSSQL column name
--    MinValues - Minimum values (for numeric columns)
--    MaxValues - Maximum values (for numeric columns)
--	select * from [mrs].[01_AS400_MSSQL_Equivalents_Columns]

CREATE OR ALTER PROCEDURE [mrs].[my_sp_CreateMapofTablesColumns]
    @DebugMode BIT = 0,
    @UpdateMaxMin BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Print start timestamp
    DECLARE @StartTime DATETIME = GETDATE();
    PRINT 'Starting execution at: ' + CONVERT(VARCHAR, @StartTime, 120);
    
    -- Check if table exists and drop if it does
    IF OBJECT_ID('[mrs].[01_AS400_MSSQL_Equivalents_Columns]', 'U') IS NOT NULL
    BEGIN
        IF @DebugMode = 1
            PRINT 'Dropping existing table [mrs].[01_AS400_MSSQL_Equivalents_Columns]';
            
        DROP TABLE [mrs].[01_AS400_MSSQL_Equivalents_Columns];
    END
    
    -- Create the table
    IF @DebugMode = 1
        PRINT 'Creating table [mrs].[01_AS400_MSSQL_Equivalents_Columns]';
        
    CREATE TABLE [mrs].[01_AS400_MSSQL_Equivalents_Columns] (
        [ID] INT IDENTITY(1,1) PRIMARY KEY,
        [Schema] NVARCHAR(128),
        [TableGroupName] NVARCHAR(255),
        [TableAS400Name] NVARCHAR(255),
        [TableMSSQLName] NVARCHAR(255),
        [ColumnAS400Name] NVARCHAR(255),
        [ColumnMSSQLName] NVARCHAR(255),
        [MinValues] BIGINT NULL,
        [MaxValues] BIGINT NULL
    );
    
    -- Prepare the INSERT query
    DECLARE @InsertQuery NVARCHAR(MAX) = '
    INSERT INTO [mrs].[01_AS400_MSSQL_Equivalents_Columns] (
        [Schema],
        [TableGroupName],
        [TableAS400Name],
        [TableMSSQLName],
        [ColumnAS400Name],
        [ColumnMSSQLName]
    )
    SELECT
        SCHEMA_NAME([so].[schema_id]) AS [Schema],
        [eq].[TableGroupName],
        [table_ep].[name] AS [TableAS400Name],
        CAST([table_ep].[value] AS NVARCHAR(255)) AS [TableMSSQLName],
        [col_ep].[name] AS [ColumnAS400Name],
        CAST([col_ep].[value] AS NVARCHAR(255)) AS [ColumnMSSQLName]
    FROM
        [mrs].[01_AS400_MSSQL_Equivalents] AS [eq]
    JOIN
        [sys].[extended_properties] AS [table_ep] ON 
            [table_ep].[name] = [eq].[AS400_TableName] AND
            [table_ep].[minor_id] = 0 AND -- Table-level property
            [table_ep].[class] = 1 -- Object/table
    JOIN
        [sys].[objects] AS [so] ON 
            [so].[object_id] = [table_ep].[major_id] AND
            SCHEMA_NAME([so].[schema_id]) = ''mrs'' -- Filter for ''mrs'' schema
    JOIN
        [sys].[columns] AS [sc] ON [sc].[object_id] = [so].[object_id]
    JOIN
        [sys].[extended_properties] AS [col_ep] ON 
            [col_ep].[major_id] = [so].[object_id] AND
            [col_ep].[minor_id] = [sc].[column_id] AND
            [col_ep].[class] = 1 -- Column
    WHERE
        [eq].[TableGroupName] IS NOT NULL
    GROUP BY
        SCHEMA_NAME([so].[schema_id]),
        [eq].[TableGroupName],
        [table_ep].[name],
        [table_ep].[value],
        [col_ep].[name],
        [col_ep].[value]
    ORDER BY
        [Schema],
        [eq].[TableGroupName]';
    
    -- Print and execute query
    IF @DebugMode = 1
        PRINT @InsertQuery;
        
    EXEC sp_executesql @InsertQuery;
    
    -- Get row count
    DECLARE @RowCount INT = @@ROWCOUNT;
    
    -- Print completion information
    DECLARE @EndTime DATETIME = GETDATE();
    PRINT 'Execution completed at: ' + CONVERT(VARCHAR, @EndTime, 120);
    PRINT 'Total execution time: ' + 
          CAST(DATEDIFF(MILLISECOND, @StartTime, @EndTime) / 1000.0 AS VARCHAR) + ' seconds';
    PRINT 'Rows inserted: ' + CAST(@RowCount AS VARCHAR);
    
    -- Return the row count
    
    -- Update min and max values if requested
    IF @UpdateMaxMin = 1
    BEGIN
        IF @DebugMode = 1
            PRINT 'Updating Min and Max values for each column...';
            
        DECLARE @TotalRows INT;
        SELECT @TotalRows = COUNT(*) FROM [mrs].[01_AS400_MSSQL_Equivalents_Columns];
        
        DECLARE @CurrentRow INT = 0;
        DECLARE @TableSchema NVARCHAR(128);
        DECLARE @TableName NVARCHAR(255);
        DECLARE @ColumnName NVARCHAR(255);
        DECLARE @ID INT;
        DECLARE @SqlMin NVARCHAR(MAX);
        DECLARE @SqlMax NVARCHAR(MAX);
        DECLARE @MinVal BIGINT;
        DECLARE @MaxVal BIGINT;
        DECLARE @ParmDefinition NVARCHAR(100) = N'@MinOut BIGINT OUTPUT, @MaxOut BIGINT OUTPUT';
        
        -- Create a cursor to iterate through each row
        DECLARE column_cursor CURSOR FOR
            SELECT 
                [ID], 
                [Schema], 
                [TableMSSQLName], 
                [ColumnMSSQLName]
            FROM 
                [mrs].[01_AS400_MSSQL_Equivalents_Columns]
            ORDER BY 
                [ID];
        
        OPEN column_cursor;
        
        FETCH NEXT FROM column_cursor INTO @ID, @TableSchema, @TableName, @ColumnName;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @CurrentRow = @CurrentRow + 1;
            
            -- Print progress
            IF @DebugMode = 1 AND @CurrentRow % 100 = 0
                PRINT 'Processing row ' + CAST(@CurrentRow AS VARCHAR) + ' of ' + CAST(@TotalRows AS VARCHAR) + ' (' + 
                      CAST(CAST((@CurrentRow * 100.0 / @TotalRows) AS INT) AS VARCHAR) + '%)';
            
            BEGIN TRY
                -- First check if column is actually numeric data type
                DECLARE @DataType NVARCHAR(128);
                DECLARE @SqlCheckType NVARCHAR(MAX) = N'
                    SELECT @DataType = t.name
                    FROM sys.columns c
                    JOIN sys.types t ON c.system_type_id = t.system_type_id
                    WHERE OBJECT_ID(''' + @TableSchema + '.' + @TableName + ''') = c.object_id
                    AND c.name = ''' + @ColumnName + '''';
                
                EXEC sp_executesql @SqlCheckType, N'@DataType NVARCHAR(128) OUTPUT', @DataType OUTPUT;
                
                -- For native numeric types, use direct MIN/MAX
                IF @DataType IN ('bigint', 'int', 'smallint', 'tinyint', 'decimal', 'numeric', 'float', 'real', 'money', 'smallmoney')
                BEGIN
                    -- Numeric column - direct MIN/MAX
                    SET @SqlMin = N'
                        SELECT @MinOut = MIN([' + @ColumnName + ']) 
                        FROM [' + @TableSchema + '].[' + @TableName + '] 
                        WHERE [' + @ColumnName + '] IS NOT NULL';
                    
                    SET @SqlMax = N'
                        SELECT @MaxOut = MAX([' + @ColumnName + ']) 
                        FROM [' + @TableSchema + '].[' + @TableName + '] 
                        WHERE [' + @ColumnName + '] IS NOT NULL';
                    
                    -- Execute for min value
                    EXEC sp_executesql @SqlMin, @ParmDefinition, @MinOut = @MinVal OUTPUT;
                    -- Execute for max value
                    EXEC sp_executesql @SqlMax, @ParmDefinition, @MaxOut = @MaxVal OUTPUT;
                    
                    IF @DebugMode = 1
                        PRINT 'Processed numeric column: ' + @TableSchema + '.' + @TableName + '.' + @ColumnName + 
                              ' MIN=' + ISNULL(CAST(@MinVal AS VARCHAR(50)), 'NULL') + 
                              ' MAX=' + ISNULL(CAST(@MaxVal AS VARCHAR(50)), 'NULL');
                END
                ELSE
                BEGIN
                    -- Text column - check if it contains numeric data
                    DECLARE @AllNumeric BIT;
                    DECLARE @SqlCheckNumeric NVARCHAR(MAX) = N'
                        SELECT @AllNumeric = 
                            CASE WHEN EXISTS (
                                SELECT 1 FROM [' + @TableSchema + '].[' + @TableName + '] 
                                WHERE [' + @ColumnName + '] IS NOT NULL 
                                  AND ISNUMERIC([' + @ColumnName + ']) = 0
                            ) THEN 0 ELSE 1 END';
                    
                    EXEC sp_executesql @SqlCheckNumeric, N'@AllNumeric BIT OUTPUT', @AllNumeric OUTPUT;
                    
                    IF @AllNumeric = 1
                    BEGIN
                        -- All values are numeric - get MIN value first
                        SET @MinVal = NULL;
                        SET @SqlMin = N'
                            SELECT @MinOut = MIN(CAST([' + @ColumnName + '] AS BIGINT)) 
                            FROM [' + @TableSchema + '].[' + @TableName + '] 
                            WHERE [' + @ColumnName + '] IS NOT NULL';
                        
                        BEGIN TRY
                            EXEC sp_executesql @SqlMin, N'@MinOut BIGINT OUTPUT', @MinOut = @MinVal OUTPUT;
                            
                            IF @DebugMode = 1
                                PRINT 'Got MIN for ' + @TableSchema + '.' + @TableName + '.' + @ColumnName + ': ' + 
                                      ISNULL(CAST(@MinVal AS VARCHAR(50)), 'NULL');
                        END TRY
                        BEGIN CATCH
                            SET @MinVal = NULL;
                            IF @DebugMode = 1
                                PRINT 'Error getting numeric MIN for ' + @TableSchema + '.' + @TableName + '.' + @ColumnName + ': ' + ERROR_MESSAGE();
                        END CATCH
                        
                        -- Now get MAX value in separate execution
                        SET @MaxVal = NULL;
                        SET @SqlMax = N'
                            SELECT @MaxOut = MAX(CAST([' + @ColumnName + '] AS BIGINT)) 
                            FROM [' + @TableSchema + '].[' + @TableName + '] 
                            WHERE [' + @ColumnName + '] IS NOT NULL';
                        
                        BEGIN TRY
                            EXEC sp_executesql @SqlMax, N'@MaxOut BIGINT OUTPUT', @MaxOut = @MaxVal OUTPUT;
                            
                            IF @DebugMode = 1
                                PRINT 'Got MAX for ' + @TableSchema + '.' + @TableName + '.' + @ColumnName + ': ' + 
                                      ISNULL(CAST(@MaxVal AS VARCHAR(50)), 'NULL');
                        END TRY
                        BEGIN CATCH
                            SET @MaxVal = NULL;
                            IF @DebugMode = 1
                                PRINT 'Error getting numeric MAX for ' + @TableSchema + '.' + @TableName + '.' + @ColumnName + ': ' + ERROR_MESSAGE();
                        END CATCH
                        
                        IF @DebugMode = 1
                            PRINT 'Processed text column with numeric values: ' + @TableSchema + '.' + @TableName + '.' + @ColumnName + 
                                  ' MIN=' + ISNULL(CAST(@MinVal AS VARCHAR(50)), 'NULL') + 
                                  ' MAX=' + ISNULL(CAST(@MaxVal AS VARCHAR(50)), 'NULL');
                    END
                    ELSE
                    BEGIN
                        -- Get alphabetical min and max
                        SET @SqlMin = N'
                            SELECT @MinOut = NULL, @MaxOut = NULL'; -- Initialize
                        
                        EXEC sp_executesql @SqlMin, @ParmDefinition, @MinOut = @MinVal OUTPUT, @MaxOut = @MaxVal OUTPUT;
                        
                        IF @DebugMode = 1
                            PRINT 'Text column with mixed/non-numeric values: ' + @TableSchema + '.' + @TableName + '.' + @ColumnName + 
                                  ' - not updating min/max values for this column';
                    END
                END
                
                -- Update the row with min and max values
                UPDATE [mrs].[01_AS400_MSSQL_Equivalents_Columns]
                SET [MinValues] = @MinVal,
                    [MaxValues] = @MaxVal
                WHERE [ID] = @ID;
                
            END TRY
            BEGIN CATCH
                IF @DebugMode = 1
                    PRINT 'Error processing row ' + CAST(@ID AS VARCHAR) + ': ' + ERROR_MESSAGE();
            END CATCH
            
            FETCH NEXT FROM column_cursor INTO @ID, @TableSchema, @TableName, @ColumnName;
        END
        
        CLOSE column_cursor;
        DEALLOCATE column_cursor;
        
        IF @DebugMode = 1
            PRINT 'Min and Max value update completed.';
    END
    
    RETURN @RowCount;
END;