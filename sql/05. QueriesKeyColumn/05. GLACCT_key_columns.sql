USE SigmaTB;
go


SELECT
    [GL_Account_Number_____GACCT],
    [GL_Description_____GACDES],
    [Alt._Report_Line_3_____GAAR3],
    [Report_Line_3_____GARP3],
    [GL_Bal._Sheet_Type_____GATYPC],
    [Alt._Report_Line_1_____GAAR1],
    [Report_Line_1_____GARP1],
    [Last_Maintained_Year_____GALMYY],
    [01-12_____GALMMM],
    [Alt._Report_Line_2_____GAAR2],
    [Report_Line_2_____GARP2],
    [GL_P&L_Type_____GATYPE],
    [A=ACTIVE__D=DELETED_I=INACTIVE_____GARECD]
FROM
    [mrs].[z_General_Ledger_Account_file_____GLACCT];