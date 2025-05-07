USE SigmaTB;

-- Example usage with schema specified in FROM clause
DECLARE @input_query NVARCHAR(MAX) = N'
SELECT MPDETAIL.MDORDR, APVEND.VVNDR, APVEND.VALPHA, MPDETAIL.MDCLOS, MPDETAIL.MDITEM, MPDETAIL.MDCRTD, mdrqcc*1000000+mdrqyy*10000+mdrqmm*100+mdrqdd, MPDETAIL.MDOQTY, MPDETAIL.MDOUOM, MPDETAIL.MDIQTY
FROM mrs.APVEND APVEND, mrs.MPDETAIL MPDETAIL
WHERE APVEND.VCOMP = MPDETAIL.MDCOMP AND APVEND.VVNDR = MPDETAIL.MDVNDR
ORDER BY MPDETAIL.MDITEM, MPDETAIL.MDORDR DESC
';

DECLARE @output_query NVARCHAR(MAX);

EXEC [mrs].[my_sp_translate_sql_query]
    @input_query = @input_query,
    @translated_query = @output_query OUTPUT;

-- View results
SELECT @output_query AS TranslatedQuery;
SELECT @input_query AS OriginalQuery;