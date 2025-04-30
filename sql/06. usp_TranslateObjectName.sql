/*****************************************************************
This stored procedure translates tables and column names
between AS400 and MSSQL names

*****************************************************************/

-- =============================================
-- Database Context
-- =============================================
USE SigmaTB;
GO

-- Drop the procedure if it already exists
IF OBJECT_ID('mrs.usp_TranslateObjectName', 'P') IS NOT NULL
    DROP PROCEDURE mrs.usp_TranslateObjectName;
GO

CREATE PROCEDURE mrs.usp_TranslateObjectName
    @InputName NVARCHAR(500),             -- Input name (AS400 or MSSQL)
    @ContextTableName NVARCHAR(500) = NULL, -- Optional: Context table name (AS400 if Input is AS400 Col, MSSQL if Input is MSSQL Col)
    @TranslatedName NVARCHAR(500) OUTPUT  -- Translated name
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IsMSSQLName BIT = 0;
    DECLARE @IsTable BIT = 0; -- Not strictly used for branching anymore, but good for clarity
    DECLARE @IsColumn BIT = 0; -- Not strictly used for branching anymore
    DECLARE @ObjectID INT = NULL;
    DECLARE @ColumnID INT = NULL;
    DECLARE @ContextTableObjectID INT = NULL;


    -- 1. Determine if the input is likely an MSSQL Name
    IF CHARINDEX('_____', @InputName) > 0
        SET @IsMSSQLName = 1;

    SET @TranslatedName = NULL; -- Default to NULL if not found

    -- 2. Logic based on whether it's MSSQL or AS400 name
    IF @IsMSSQLName = 1
    BEGIN
        -- Input is MSSQL Name, translate to AS400 Name

        -- 2a. Check if it's a TABLE name
        SELECT TOP 1 @ObjectID = t.object_id
        FROM sys.tables t
        WHERE SCHEMA_NAME(t.schema_id) = 'mrs'
          AND t.name = @InputName;

        IF @ObjectID IS NOT NULL -- It's potentially a table
        BEGIN
             -- Check if context was provided - if so, ignore if it doesn't match (input is table, but context given?)
             IF @ContextTableName IS NULL OR @ContextTableName = @InputName
             BEGIN
                 SET @IsTable = 1;
                 -- Get AS400 name from extended property 'name' where 'value' matches
                 SELECT @TranslatedName = ep.name
                 FROM sys.extended_properties ep
                 WHERE ep.class = 1 AND ep.major_id = @ObjectID AND ep.minor_id = 0 -- Table level
                   AND ep.value = @InputName;
             END
             -- ELSE: It looked like a table name, but context was given and didn't match? Or handle differently?
        END
        -- If not identified as a table OR if context didn't match (if provided for table), check if it's a column
        IF @IsTable = 0
        BEGIN
            -- 2b. Check if it's a COLUMN name
            IF @ContextTableName IS NOT NULL
            BEGIN
                -- Context IS provided (assume MSSQL Table Name): Find column within specific table
                SELECT TOP 1 @ObjectID = c.object_id, @ColumnID = c.column_id
                FROM sys.columns c
                JOIN sys.tables t ON c.object_id = t.object_id
                WHERE SCHEMA_NAME(t.schema_id) = 'mrs'
                  AND c.name = @InputName          -- Match MSSQL Column Name
                  AND t.name = @ContextTableName;  -- Match MSSQL Table Name
            END
            ELSE
            BEGIN
                -- Context NOT provided: Find first matching column name (potential ambiguity)
                SELECT TOP 1 @ObjectID = c.object_id, @ColumnID = c.column_id
                FROM sys.columns c
                JOIN sys.tables t ON c.object_id = t.object_id
                WHERE SCHEMA_NAME(t.schema_id) = 'mrs'
                  AND c.name = @InputName;
            END

            IF @ObjectID IS NOT NULL AND @ColumnID IS NOT NULL
            BEGIN
                 SET @IsColumn = 1;
                 -- Get AS400 name from extended property 'name' where 'value' matches
                 SELECT @TranslatedName = ep.name
                 FROM sys.extended_properties ep
                 WHERE ep.class = 1 AND ep.major_id = @ObjectID AND ep.minor_id = @ColumnID -- Column level
                   AND ep.value = @InputName;
            END
        END
        -- ELSE: Input MSSQLName not found as a table or column (or context mismatch)
    END
    ELSE -- Input is AS400 Name
    BEGIN
        -- Input is AS400 Name, translate to MSSQL Name

        -- 2c. Check if it's an AS400 TABLE name
        SELECT TOP 1 @ObjectID = ep.major_id
        FROM sys.extended_properties ep
        JOIN sys.tables t ON ep.major_id = t.object_id
        WHERE ep.class = 1 AND ep.minor_id = 0 -- Table level
          AND ep.name = @InputName -- Match AS400 Name stored in 'name'
          AND SCHEMA_NAME(t.schema_id) = 'mrs';

        IF @ObjectID IS NOT NULL -- It's potentially a table
        BEGIN
             -- Check if context was provided - if so, ignore if it doesn't match
             IF @ContextTableName IS NULL OR @ContextTableName = @InputName
             BEGIN
                 SET @IsTable = 1;
                 -- Get MSSQL name from extended property 'value'
                 SELECT @TranslatedName = CONVERT(NVARCHAR(500), ep.value)
                 FROM sys.extended_properties ep
                 WHERE ep.class = 1 AND ep.major_id = @ObjectID AND ep.minor_id = 0
                   AND ep.name = @InputName;
             END
        END

        -- If not identified as table OR context mismatch, check if it's a column
        IF @IsTable = 0
        BEGIN
             -- 2d. Check if it's an AS400 COLUMN name
             IF @ContextTableName IS NULL
             BEGIN
                 -- Cannot reliably translate AS400 column name without table context
                 -- Set to NULL (already default) or a specific message if preferred
                 -- SET @TranslatedName = N'[Error] Context table name required for AS400 column translation';
                 SET @TranslatedName = NULL; -- Keep it NULL to indicate failure due to missing info
             END
             ELSE
             BEGIN
                 -- Context IS provided (assume AS400 Table Name)
                 -- Find the object_id of the context table
                 SELECT @ContextTableObjectID = ep.major_id
                 FROM sys.extended_properties ep
                 JOIN sys.tables t ON ep.major_id = t.object_id
                 WHERE ep.class = 1 AND ep.minor_id = 0 -- Table level
                   AND ep.name = @ContextTableName -- Match context AS400 Table Name
                   AND SCHEMA_NAME(t.schema_id) = 'mrs';

                 IF @ContextTableObjectID IS NOT NULL
                 BEGIN
                     -- Now find the column within that specific table
                     SELECT TOP 1 @ObjectID = ep.major_id, @ColumnID = ep.minor_id
                     FROM sys.extended_properties ep
                     WHERE ep.class = 1
                       AND ep.major_id = @ContextTableObjectID -- Filter by the specific table
                       AND ep.minor_id > 0 -- Column level
                       AND ep.name = @InputName; -- Match AS400 Column Name

                     IF @ObjectID IS NOT NULL AND @ColumnID IS NOT NULL
                     BEGIN
                          SET @IsColumn = 1;
                          -- Get MSSQL name from extended property 'value'
                          SELECT @TranslatedName = CONVERT(NVARCHAR(500), ep.value)
                          FROM sys.extended_properties ep
                          WHERE ep.class = 1 AND ep.major_id = @ObjectID AND ep.minor_id = @ColumnID
                            AND ep.name = @InputName;
                     END
                     -- ELSE: AS400 Column name not found in the specified AS400 context table
                 END
                 -- ELSE: AS400 Context table name not found
             END
        END
        -- ELSE: Input AS400 Name not found as table or column
    END

    -- 3. Return the result (already set in @TranslatedName)

END;
GO

-- Example Usage:

USE SigmaTB;
go

-- Table translation (Context not needed, ignored if provided)
DECLARE @ResultT1 NVARCHAR(500);
EXEC mrs.usp_TranslateObjectName @InputName = 'SPHEADER', @ContextTableName = NULL, @TranslatedName = @ResultT1 OUTPUT;
SELECT @ResultT1 AS Translated;

DECLARE @ResultT2 NVARCHAR(500);
EXEC mrs.usp_TranslateObjectName @InputName = 'z_Service_Purchase_Order_Header_File_____SPHEADER', @ContextTableName = NULL, @TranslatedName = @ResultT2 OUTPUT;
SELECT @ResultT2 AS Translated_z_Order_Tracking_File;

-- AS400 Column to MSSQL Column **WITH CONTEXT** (Context is AS400 Table Name)
DECLARE @ResultC1 NVARCHAR(500);
EXEC mrs.usp_TranslateObjectName @InputName = 'Transaction_#_____BSORDR', @ContextTableName = 'z_Service_Purchase_Order_Header_File_____SPHEADER', @TranslatedName = @ResultC1 OUTPUT;
SELECT @ResultC1 AS Translated_SPHEADER_BSORDR; -- Should return the MSSQL name for BSORDR *from SPHEADER*


-- AS400 Column to MSSQL Column **WITH CONTEXT** (Context is AS400 Table Name)
DECLARE @ResultC1 NVARCHAR(500);
EXEC mrs.usp_TranslateObjectName @InputName = 'BSORDR', @ContextTableName = 'SPHEADER', @TranslatedName = @ResultC1 OUTPUT;
SELECT @ResultC1 AS Translated_SPHEADER_BSORDR; -- Should return the MSSQL name for BSORDR *from SPHEADER*


-- AS400 Column to MSSQL Column **WITHOUT CONTEXT** (Should fail / return NULL)
DECLARE @ResultC2 NVARCHAR(500);
EXEC mrs.usp_TranslateObjectName @InputName = 'BSORDR', @ContextTableName = NULL, @TranslatedName = @ResultC2 OUTPUT;
SELECT @ResultC2 AS Translated_BSORDR_NoContext; -- Should be NULL

-- MSSQL Column to AS400 Column **WITH CONTEXT** (Context is MSSQL Table Name)
DECLARE @ResultC3 NVARCHAR(500);
DECLARE @MSSQLColName NVARCHAR(500) = -- Get the actual MSSQL column name for BSORDR in SPHEADER first
    (SELECT TOP 1 CONVERT(NVARCHAR(500), ep.value) FROM sys.extended_properties ep JOIN sys.tables t ON ep.major_id=t.object_id WHERE SCHEMA_NAME(t.schema_id)='mrs' AND ep.name='BSORDR' AND ep.class=1 AND ep.minor_id > 0 AND t.name LIKE '%SPHEADER');
DECLARE @MSSQLTableName NVARCHAR(500) = -- Get the actual MSSQL table name for SPHEADER
    (SELECT TOP 1 t.name FROM sys.tables t JOIN sys.extended_properties ep ON ep.major_id=t.object_id WHERE SCHEMA_NAME(t.schema_id)='mrs' AND ep.name='SPHEADER' AND ep.class=1 AND ep.minor_id=0);

-- Make sure the names were found before executing
IF @MSSQLColName IS NOT NULL AND @MSSQLTableName IS NOT NULL
BEGIN
    PRINT 'Translating MSSQL Column: ' + @MSSQLColName + ' within Table: ' + @MSSQLTableName;
    EXEC mrs.usp_TranslateObjectName @InputName = @MSSQLColName, @ContextTableName = @MSSQLTableName, @TranslatedName = @ResultC3 OUTPUT;
    SELECT @ResultC3 AS Translated_MSSQL_Col_WithContext; -- Should be BSORDR
END
ELSE
BEGIN
	PRINT 'Could not find prerequisite MSSQL names for test C3';
	SELECT NULL AS Translated_MSSQL_Col_WithContext;
END

-- MSSQL Column to AS400 Column **WITHOUT CONTEXT** (May work, but potentially ambiguous)
DECLARE @ResultC4 NVARCHAR(500);
EXEC mrs.usp_TranslateObjectName @InputName = @MSSQLColName, @ContextTableName = NULL, @TranslatedName = @ResultC4 OUTPUT;
SELECT @ResultC4 AS Translated_MSSQL_Col_NoContext; -- Should be BSORDR (if TOP 1 finds the right one)

-- Test case for a name not found
DECLARE @Result5 NVARCHAR(500);
EXEC mrs.usp_TranslateObjectName @InputName = 'NON_EXISTENT_NAME', @ContextTableName = 'SPHEADER', @TranslatedName = @Result5 OUTPUT;
SELECT @Result5 AS Translated_NonExistent; -- Should be NULL