-- ==================================
-- START CONFIGURATION
-- ==================================
DECLARE @NewServerLinkedName NVARCHAR(128) = N'SigmaTB_Restore';  -- Linked Server name pointing to the NEW/Restored server
DECLARE @DatabaseName NVARCHAR(128) = N'SigmaTB';            -- Database name (used on BOTH servers)
-- ==================================
-- END CONFIGURATION
-- ==================================

-- Set context to the source database
USE [SigmaTB]; -- Uses the @DatabaseName variable
GO

PRINT N'Comparing Stored Procedures in database [' + N'SigmaTB' + N'] on local server';
PRINT N'With database [' + N'SigmaTB' + N'] on linked server [' + N'SigmaTB_Restore' + N']';
PRINT N'--------------------------------------------------------------------------';

-- Construct the correctly quoted four-part base name for remote DB reference
DECLARE @fourPartRemoteBase NVARCHAR(512);
SET @fourPartRemoteBase = QUOTENAME(N'SigmaTB_Restore') + N'.' + QUOTENAME(N'SigmaTB'); -- Use variables

-- Build the dynamic SQL to perform the comparison
-- Using dynamic SQL to easily incorporate the four-part name variable
DECLARE @sql NVARCHAR(MAX);
SET @sql = N'
SELECT
    s_local.name AS [Source Schema],
    p_local.name AS [Source Stored Procedure],
    CASE
        WHEN p_remote.object_id IS NOT NULL THEN ''✅ Exists in Restored DB''
        ELSE ''❌ Does Not Exist in Restored DB''
    END AS [Restored DB Status]
FROM
    sys.procedures AS p_local
INNER JOIN
    sys.schemas AS s_local ON p_local.schema_id = s_local.schema_id
LEFT JOIN
    ' + @fourPartRemoteBase + N'.sys.procedures AS p_remote
    ON s_local.name = SCHEMA_NAME(p_remote.schema_id) -- Compare schema names
    AND p_local.name = p_remote.name                  -- Compare procedure names
ORDER BY
    [Restored DB Status] DESC, -- Show missing ones first
    [Source Schema],
    [Source Stored Procedure];
';

-- Execute the comparison query
EXEC sp_executesql @sql;

GO

/***************************************************


Source Schema	Source Stored Procedure	Restored DB Status
dbo	my_sp_getAllColumnXPfromTables	? Exists in Restored DB
dbo	my_sp_getXPfromObjects	? Exists in Restored DB
dbo	mysp_analyze_table_columns	? Exists in Restored DB
dbo	mysp_find_table_column_by_code	? Exists in Restored DB
dbo	mysp_find_unique_values_table_column_by_code	? Exists in Restored DB
dbo	mysp_format_query_with_descriptions	? Exists in Restored DB
dbo	sp_alterdiagram	? Exists in Restored DB
dbo	sp_audit_tables	? Exists in Restored DB
dbo	sp_creatediagram	? Exists in Restored DB
dbo	sp_dropdiagram	? Exists in Restored DB
dbo	sp_helpdiagramdefinition	? Exists in Restored DB
dbo	sp_helpdiagrams	? Exists in Restored DB
dbo	sp_renamediagram	? Exists in Restored DB
dbo	sp_translate_sql_query	? Exists in Restored DB
dbo	sp_upgraddiagrams	? Exists in Restored DB
dbo	usp_UpdateExtendedProperties	? Exists in Restored DB
dbo	usp_UpdateExtendedProperties_Diagnostic	? Exists in Restored DB
dbo	usp_UpdateExtendedPropertiesFromNames	? Exists in Restored DB
dbo	usp_UpdateExtendedPropertiesFromNames_v2	? Exists in Restored DB
mrs	my_sp_audit_tables	? Exists in Restored DB
mrs	my_sp_translate_sql_query	? Exists in Restored DB
mrs	sp_translate_sql_query	? Exists in Restored DB
mrs	UpdateExtendedPropertiesForZTables	? Exists in Restored DB
mrs	usp_GetExtendedProperties	? Exists in Restored DB
mrs	usp_infer_all_relationships	? Exists in Restored DB
mrs	usp_infer_relationships_batch	? Exists in Restored DB
mrs	usp_TranslateName	? Exists in Restored DB
mrs	usp_TranslateObjectName	? Exists in Restored DB
mrs	usp_TranslateSQLQuery	? Exists in Restored DB
mrs	usp_UpdateExtendedProperties	? Exists in Restored DB
mrs	IdentifyPotentialPrimaryKeys	? Does Not Exist in Restored DB
mrs	IdentifyPrimaryKeys	? Does Not Exist in Restored DB
***************************************************/