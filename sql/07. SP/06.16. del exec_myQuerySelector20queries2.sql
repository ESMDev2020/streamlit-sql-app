USE SigmaTB;




DECLARE @Input NVARCHAR(MAX);
DECLARE @Output NVARCHAR(MAX);

 --SET @Input = N'SELECT * FROM [VNDREQHD]'; -- Vendor Header
 --SET @Input = N'SELECT * FROM [vendship]'; -- Vendor SHIP Address to
 --SET @Input = N'SELECT * FROM [VENDREMT]'; -- Vendor remit to addr
  -- 'SELECT * FROM [vendinst]      - just 2
  -- 'SELECT * FROM [achinfo]'      - vendor + account number
   
-- Example 1: AS400 to MSSQL Translation (Debug Mode ON)
DECLARE @InputQueryAS400 NVARCHAR(MAX) = 'SELECT * FROM [apvend]';DECLARE @OutputQueryMSSQL NVARCHAR(MAX);

EXEC [mrs].[usp_TranslateSQLQuery] 
    @SQLQuery = @InputQueryAS400, 
    @DebugMode = 1, 
    @TranslatedQuery = @OutputQueryMSSQL OUTPUT,
    @Execution = 1;

SELECT @OutputQueryMSSQL AS [MSSQL_Translated_Query];


EXEC [mrs].[sub_FindColumnPropertiesByCode] @myVarVARCHARParamColumnCode = N'%TYP%', @myVarBITDebugMode = 0;




SET @Output = NULL; -- Reset output variable
EXEC [mrs].[usp_TranslateSQLQuery] @p_InputQuery = @Input, @p_TranslatedQuery = @Output OUTPUT;
PRINT 'TRANSLATION (Debug OFF):';
PRINT @Output;


--SELECT * FROM [MRS].[z_Vendor_Request_Header_File_____VNDREQHD]	-- V10VND, V10RQ#, V10ITM, quantity, date, V10ITEMD
--SELECT * FROM [mrs].[z_Vendor_Ship_To_Address_File_____VENDSHIP]			-- VSVNDR, VSNAME, address
--SELECT * FROM [mrs].[z_Vendor_Remit_To_Address_File_____VENDREMT]	--VRVNDR, VRSEQ, VRNAME, address, date