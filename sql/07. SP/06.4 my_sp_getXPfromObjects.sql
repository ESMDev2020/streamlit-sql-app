USE SigmaTB;
GO

/********************************************************
Stored Procedure: my_sp_getXPfromObjects
Description: Retrieves extended property information for tables or columns
*********************************************************/
CREATE OR ALTER PROCEDURE my_sp_getXPfromObjects
    @lookfor NVARCHAR(255),
    @isobject NVARCHAR(10),
    @returnvalue NVARCHAR(10)
AS
BEGIN
    -- === ALL DECLARATIONS MUST BE AT THE TOP ===
    DECLARE @my_var_varchar_procedure_start_message VARCHAR(50);
    DECLARE @my_var_varchar_procedure_end_message VARCHAR(50);
    DECLARE @my_var_varchar_not_found VARCHAR(20);
    DECLARE @my_var_datetime_start_time DATETIME2;
    DECLARE @my_var_datetime_end_time DATETIME2;
    DECLARE @my_var_int_error_number INT;
    DECLARE @my_var_int_error_severity INT;
    DECLARE @my_var_int_error_state INT;
    DECLARE @my_var_nvarchar_error_procedure NVARCHAR(128);
    DECLARE @my_var_int_error_line INT;
    DECLARE @my_var_nvarchar_error_message NVARCHAR(MAX);
    DECLARE @my_var_nvarchar_table_name NVARCHAR(255);
    DECLARE @my_var_nvarchar_column_name NVARCHAR(255);
    DECLARE @mystrresultobject NVARCHAR(255);
    DECLARE @my_var_int_table_object_id INT;
    -- === END OF DECLARATIONS ===

    -- Create temporary table for debug information
    CREATE TABLE #DebugInfo (
        StepNumber INT IDENTITY(1,1),
        StepDescription NVARCHAR(255),
        VariableName NVARCHAR(100),
        VariableValue NVARCHAR(MAX),
        Timestamp DATETIME2 DEFAULT GETDATE()
    );

    -- === INITIALIZE VARIABLES using SET ===
    SET @my_var_varchar_procedure_start_message = 'Starting execution';
    SET @my_var_varchar_procedure_end_message = 'Finished execution';
    SET @my_var_varchar_not_found = 'NOT FOUND';
    -- === END OF INITIALIZATION ===

    -- Debug: Store input parameters
    INSERT INTO #DebugInfo (StepDescription, VariableName, VariableValue)
    VALUES ('Input Parameters', '@lookfor', @lookfor),
           ('Input Parameters', '@isobject', @isobject),
           ('Input Parameters', '@returnvalue', @returnvalue);

    -- Command: Record the start time
    SET @my_var_datetime_start_time = SYSUTCDATETIME();
    INSERT INTO #DebugInfo (StepDescription, VariableName, VariableValue)
    VALUES ('Start Time', 'Timestamp', FORMAT(@my_var_datetime_start_time, 'yyyy-MM-dd HH:mm:ss.fff'));

    BEGIN TRY
        -- Extract table name from @lookfor (always between first [ and first ])
        SET @my_var_nvarchar_table_name = SUBSTRING(@lookfor, 
            CHARINDEX('[', @lookfor) + 1, 
            CHARINDEX(']', @lookfor) - CHARINDEX('[', @lookfor) - 1);
        
        -- Debug: Store extracted table name
        INSERT INTO #DebugInfo (StepDescription, VariableName, VariableValue)
        VALUES ('Table Name', 'Extracted', @my_var_nvarchar_table_name);

        -- If looking for a column, extract column name
        IF @isobject = 'column'
        BEGIN
            -- Check if there's a second set of brackets (for column)
            IF CHARINDEX('[', @lookfor, CHARINDEX(']', @lookfor) + 1) > 0
            BEGIN
                -- Get the column name (between second [ and second ])
                SET @my_var_nvarchar_column_name = SUBSTRING(@lookfor, 
                    CHARINDEX('[', @lookfor, CHARINDEX(']', @lookfor) + 1) + 1,
                    CHARINDEX(']', @lookfor, CHARINDEX(']', @lookfor) + 1) - CHARINDEX('[', @lookfor, CHARINDEX(']', @lookfor) + 1) - 1);
                
                -- Debug: Store extracted column name
                INSERT INTO #DebugInfo (StepDescription, VariableName, VariableValue)
                VALUES ('Column Name', 'Extracted', @my_var_nvarchar_column_name);
            END
            ELSE
            BEGIN
                -- If no second set of brackets found, set column name to NOT FOUND
                SET @my_var_nvarchar_column_name = @my_var_varchar_not_found;
                INSERT INTO #DebugInfo (StepDescription, VariableName, VariableValue)
                VALUES ('Column Name', 'Error', 'No column name found in input');
            END
        END

        -- Control Logic: Handle table lookup
        IF @isobject = 'table'
        BEGIN
            INSERT INTO #DebugInfo (StepDescription, VariableName, VariableValue)
            VALUES ('Table Lookup', 'Status', 'Starting Table Lookup for: ' + @my_var_nvarchar_table_name);
            
            IF EXISTS (
                SELECT 1
                FROM sys.extended_properties AS ep
                INNER JOIN sys.tables AS t ON ep.major_id = t.object_id
                WHERE ep.class = 1
                  AND ep.minor_id = 0
                  AND ep.name = @my_var_nvarchar_table_name
            )
            BEGIN
                INSERT INTO #DebugInfo (StepDescription, VariableName, VariableValue)
                VALUES ('Table Lookup', 'Status', 'Table Found: ' + @my_var_nvarchar_table_name);
                
                IF @returnvalue = 'name'
                BEGIN
                    SELECT @mystrresultobject = CONVERT(NVARCHAR(MAX), ep.value)
                    FROM sys.extended_properties AS ep
                    INNER JOIN sys.tables AS t ON ep.major_id = t.object_id
                    WHERE ep.class = 1
                      AND ep.minor_id = 0
                      AND ep.name = @my_var_nvarchar_table_name;

                    INSERT INTO #DebugInfo (StepDescription, VariableName, VariableValue)
                    VALUES ('Table Lookup', 'Return Type', 'Returning Table Name: ' + @mystrresultobject);
                END
                ELSE -- 'code'
                BEGIN
                    SELECT @mystrresultobject = CONVERT(NVARCHAR(MAX), ep.name)
                    FROM sys.extended_properties AS ep
                    INNER JOIN sys.tables AS t ON ep.major_id = t.object_id
                    WHERE ep.class = 1
                      AND ep.minor_id = 0
                      AND ep.name = @my_var_nvarchar_table_name;

                    INSERT INTO #DebugInfo (StepDescription, VariableName, VariableValue)
                    VALUES ('Table Lookup', 'Return Type', 'Returning Table Code: ' + @mystrresultobject);
                END
                
                SELECT result = @mystrresultobject;
            END
            ELSE
            BEGIN
                INSERT INTO #DebugInfo (StepDescription, VariableName, VariableValue)
                VALUES ('Table Lookup', 'Status', 'Table Not Found: ' + @my_var_nvarchar_table_name);
                
                SELECT @my_var_varchar_not_found AS result;
            END
        END
        -- Control Logic: Handle column lookup
        ELSE IF @isobject = 'column'
        BEGIN
            IF @my_var_nvarchar_column_name = @my_var_varchar_not_found
            BEGIN
                INSERT INTO #DebugInfo (StepDescription, VariableName, VariableValue)
                VALUES ('Column Lookup', 'Error', 'Invalid column format');
                
                SELECT @my_var_varchar_not_found AS result;
            END
            ELSE
            BEGIN
                INSERT INTO #DebugInfo (StepDescription, VariableName, VariableValue)
                VALUES ('Column Lookup', 'Status', 'Starting Column Lookup for: ' + @my_var_nvarchar_column_name + ' in table: ' + @my_var_nvarchar_table_name);
                
                -- First find the table's object_id using the table code
                SELECT @my_var_int_table_object_id = t.object_id
                FROM sys.extended_properties AS ep
                INNER JOIN sys.tables AS t ON ep.major_id = t.object_id
                WHERE ep.class = 1
                  AND ep.minor_id = 0
                  AND ep.name = @my_var_nvarchar_table_name;

                IF @my_var_int_table_object_id IS NOT NULL
                BEGIN
                    INSERT INTO #DebugInfo (StepDescription, VariableName, VariableValue)
                    VALUES ('Column Lookup', 'Status', 'Table Found with object_id: ' + CAST(@my_var_int_table_object_id AS NVARCHAR(20)));
                    
                    -- Now look for the column in that table
                    IF EXISTS (
                        SELECT 1
                        FROM sys.extended_properties AS ep
                        INNER JOIN sys.columns AS c ON ep.major_id = c.object_id AND ep.minor_id = c.column_id
                        WHERE ep.class = 1
                          AND ep.major_id = @my_var_int_table_object_id
                          AND ep.name = @my_var_nvarchar_column_name
                    )
                    BEGIN
                        INSERT INTO #DebugInfo (StepDescription, VariableName, VariableValue)
                        VALUES ('Column Lookup', 'Status', 'Column Found: ' + @my_var_nvarchar_column_name);
                        
                        IF @returnvalue = 'name'
                        BEGIN
                            SELECT @mystrresultobject = CONVERT(NVARCHAR(MAX), ep.value)
                            FROM sys.extended_properties AS ep
                            INNER JOIN sys.columns AS c ON ep.major_id = c.object_id AND ep.minor_id = c.column_id
                            WHERE ep.class = 1
                              AND ep.major_id = @my_var_int_table_object_id
                              AND ep.name = @my_var_nvarchar_column_name;

                            INSERT INTO #DebugInfo (StepDescription, VariableName, VariableValue)
                            VALUES ('Column Lookup', 'Return Type', 'Returning Column Name: ' + @mystrresultobject);
                        END
                        ELSE -- 'code'
                        BEGIN
                            SELECT @mystrresultobject = CONVERT(NVARCHAR(MAX), ep.name)
                            FROM sys.extended_properties AS ep
                            INNER JOIN sys.columns AS c ON ep.major_id = c.object_id AND ep.minor_id = c.column_id
                            WHERE ep.class = 1
                              AND ep.major_id = @my_var_int_table_object_id
                              AND ep.name = @my_var_nvarchar_column_name;

                            INSERT INTO #DebugInfo (StepDescription, VariableName, VariableValue)
                            VALUES ('Column Lookup', 'Return Type', 'Returning Column Code: ' + @mystrresultobject);
                        END
                        
                        SELECT result = @mystrresultobject;
                    END
                    ELSE
                    BEGIN
                        INSERT INTO #DebugInfo (StepDescription, VariableName, VariableValue)
                        VALUES ('Column Lookup', 'Status', 'Column Not Found: ' + @my_var_nvarchar_column_name);
                        
                        SELECT @my_var_varchar_not_found AS result;
                    END
                END
                ELSE
                BEGIN
                    INSERT INTO #DebugInfo (StepDescription, VariableName, VariableValue)
                    VALUES ('Column Lookup', 'Status', 'Table Not Found: ' + @my_var_nvarchar_table_name);
                    
                    SELECT @my_var_varchar_not_found AS result;
                END
            END
        END
        ELSE
        BEGIN
            INSERT INTO #DebugInfo (StepDescription, VariableName, VariableValue)
            VALUES ('Error', 'Status', 'Invalid Object Type');
            
            SELECT @my_var_varchar_not_found AS result;
        END
    END TRY
    BEGIN CATCH
        -- Error Handling: Capture and display any errors
        SELECT
            @my_var_int_error_number = ERROR_NUMBER(),
            @my_var_int_error_severity = ERROR_SEVERITY(),
            @my_var_int_error_state = ERROR_STATE(),
            @my_var_nvarchar_error_procedure = ERROR_PROCEDURE(),
            @my_var_int_error_line = ERROR_LINE(),
            @my_var_nvarchar_error_message = ERROR_MESSAGE();

        INSERT INTO #DebugInfo (StepDescription, VariableName, VariableValue)
        VALUES ('Error', 'Error Number', CAST(@my_var_int_error_number AS NVARCHAR(50))),
               ('Error', 'Severity', CAST(@my_var_int_error_severity AS NVARCHAR(50))),
               ('Error', 'State', CAST(@my_var_int_error_state AS NVARCHAR(50))),
               ('Error', 'Procedure', ISNULL(@my_var_nvarchar_error_procedure, 'N/A')),
               ('Error', 'Line', CAST(@my_var_int_error_line AS NVARCHAR(50))),
               ('Error', 'Message', @my_var_nvarchar_error_message);
    END CATCH;

    -- Command: Record the end time
    SET @my_var_datetime_end_time = SYSUTCDATETIME();
    INSERT INTO #DebugInfo (StepDescription, VariableName, VariableValue)
    VALUES ('End Time', 'Timestamp', FORMAT(@my_var_datetime_end_time, 'yyyy-MM-dd HH:mm:ss.fff'));

    -- Return debug information
    SELECT * FROM #DebugInfo ORDER BY StepNumber;

    -- Clean up
    DROP TABLE #DebugInfo;
END;
GO

-- Example of how to execute the stored procedure
-- For table: EXEC my_sp_getXPfromObjects @lookfor = '[GLTRANS]', @isobject = 'table', @returnvalue = 'name';
-- For column: EXEC my_sp_getXPfromObjects @lookfor = '[GLTRANS].[GLACCT]', @isobject = 'column', @returnvalue = 'name';
