-- ==================================================================
-- Create Helper Function to Derive Code for SigmaTB Database
-- ==================================================================
USE SigmaTB; -- Database name updated
GO

IF OBJECT_ID('dbo.udf_GetDerivedCode', 'FN') IS NOT NULL
    DROP FUNCTION dbo.udf_GetDerivedCode;
GO

CREATE FUNCTION dbo.udf_GetDerivedCode
(
    @OriginalName NVARCHAR(MAX),
    @Separator NVARCHAR(5)
)
RETURNS NVARCHAR(128) -- Max length for extended property name
AS
BEGIN
    DECLARE @DerivedCode NVARCHAR(128) = NULL;

    -- Check if separator exists to avoid errors with CHARINDEX returning 0
    IF CHARINDEX(@Separator, @OriginalName) > 0
    BEGIN
        -- Calculate using RIGHT()
        SET @DerivedCode = NULLIF(RIGHT(@OriginalName, CHARINDEX(REVERSE(@Separator), REVERSE(@OriginalName)) - 1), '');
    END
    -- ELSE: @DerivedCode remains NULL

    RETURN @DerivedCode;
END;
GO

PRINT N'Function dbo.udf_GetDerivedCode created successfully in SigmaTB.';
GO

/***********************************************************************************
NOW WE CREATE THE STORED PROCEDURE
***********************************************************************************/


