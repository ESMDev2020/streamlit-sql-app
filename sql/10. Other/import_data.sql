--Script to import the SigmaTB tables into the Database

Use SigmaTB;

BULK INSERT [dbo].[APVEND]
FROM '/Users/bmate/Downloads/Tables/APVEND_DATA.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK,
    CODEPAGE = '65001' -- UTF-8
);

SELECT 'APVEND' AS TableName, COUNT(*) AS MyRowCount FROM dbo.APVEND;


BULK INSERT [dbo].[ARCUST]
FROM '/Users/bmate/Workplace/Corporativo/03. Global/01. US/1. Bmate consulting Group/2025/03. Operations/02. Commercial 25/02. Execution/04. Solution development/02. Sigma - Product tracking/03. ESM/Exchange/07. Tables/ARCUST_DATA.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TEXTQUALIFIER = '"',
    TABLOCK,
    CODEPAGE = '65001' -- UTF-8
);

SELECT 'ARCUST' AS TableName, COUNT(*) AS MyRowCount FROM dbo.ARCUST;

BULK INSERT [dbo].[ITEMHIST]
FROM '/Users/bmate/Workplace/Corporativo/03. Global/01. US/1. Bmate consulting Group/2025/03. Operations/02. Commercial 25/02. Execution/04. Solution development/02. Sigma - Product tracking/03. ESM/Exchange/07. Tables/ITEMHIST_DATA.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TEXTQUALIFIER = '"',
    TABLOCK,
    CODEPAGE = '65001' -- UTF-8
);


BULK INSERT [dbo].[ITEMMAST]
FROM '/Users/bmate/Workplace/Corporativo/03. Global/01. US/1. Bmate consulting Group/2025/03. Operations/02. Commercial 25/02. Execution/04. Solution development/02. Sigma - Product tracking/03. ESM/Exchange/07. Tables/ITEMMAST_DATA.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TEXTQUALIFIER = '"',
    TABLOCK,
    CODEPAGE = '65001' -- UTF-8
);


BULK INSERT [dbo].[ITEMONHD]
FROM '/Users/bmate/Workplace/Corporativo/03. Global/01. US/1. Bmate consulting Group/2025/03. Operations/02. Commercial 25/02. Execution/04. Solution development/02. Sigma - Product tracking/03. ESM/Exchange/07. Tables/ITEMONHD_DATA.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TEXTQUALIFIER = '"',
    TABLOCK,
    CODEPAGE = '65001' -- UTF-8
);


BULK INSERT [dbo].[ITEMTAG]
FROM '/Users/bmate/Workplace/Corporativo/03. Global/01. US/1. Bmate consulting Group/2025/03. Operations/02. Commercial 25/02. Execution/04. Solution development/02. Sigma - Product tracking/03. ESM/Exchange/07. Tables/ITEMTAG_DATA.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TEXTQUALIFIER = '"',
    TABLOCK,
    CODEPAGE = '65001' -- UTF-8
);


BULK INSERT [dbo].[MPDETAIL]
FROM '/Users/bmate/Workplace/Corporativo/03. Global/01. US/1. Bmate consulting Group/2025/03. Operations/02. Commercial 25/02. Execution/04. Solution development/02. Sigma - Product tracking/03. ESM/Exchange/07. Tables/MPDETAIL_DATA.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TEXTQUALIFIER = '"',
    TABLOCK,
    CODEPAGE = '65001' -- UTF-8
);


BULK INSERT [dbo].[OEDETAIL]
FROM '/Users/bmate/Workplace/Corporativo/03. Global/01. US/1. Bmate consulting Group/2025/03. Operations/02. Commercial 25/02. Execution/04. Solution development/02. Sigma - Product tracking/03. ESM/Exchange/07. Tables/OEDETAIL_DATA.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TEXTQUALIFIER = '"',
    TABLOCK,
    CODEPAGE = '65001' -- UTF-8
);


BULK INSERT [dbo].[OEOPNORD]
FROM '/Users/bmate/Workplace/Corporativo/03. Global/01. US/1. Bmate consulting Group/2025/03. Operations/02. Commercial 25/02. Execution/04. Solution development/02. Sigma - Product tracking/03. ESM/Exchange/07. Tables/OEOPNORD_DATA.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TEXTQUALIFIER = '"',
    TABLOCK,
    CODEPAGE = '65001' -- UTF-8
);


BULK INSERT [dbo].[PODETAIL]
FROM '/Users/bmate/Workplace/Corporativo/03. Global/01. US/1. Bmate consulting Group/2025/03. Operations/02. Commercial 25/02. Execution/04. Solution development/02. Sigma - Product tracking/03. ESM/Exchange/07. Tables/PODETAIL_DATA.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TEXTQUALIFIER = '"',
    TABLOCK,
    CODEPAGE = '65001' -- UTF-8
);


--Verify that all the tables were uploaded successfully, and the number of rows correspond to the files
USE SigmaTB;
GO

SELECT 'APVEND' AS TableName, COUNT(*) AS TableRowCount FROM dbo.APVEND
UNION ALL
SELECT 'ARCUST', COUNT(*) FROM dbo.ARCUST
UNION ALL
SELECT 'ITEMHIST', COUNT(*) FROM dbo.ITEMHIST
UNION ALL
SELECT 'ITEMMAST', COUNT(*) FROM dbo.ITEMMAST
UNION ALL
SELECT 'ITEMONHD', COUNT(*) FROM dbo.ITEMONHD
UNION ALL
SELECT 'ITEMTAG', COUNT(*) FROM dbo.ITEMTAG
UNION ALL
SELECT 'MPDETAIL', COUNT(*) FROM dbo.MPDETAIL
UNION ALL
SELECT 'OEDETAIL', COUNT(*) FROM dbo.OEDETAIL
UNION ALL
SELECT 'OEOPNORD', COUNT(*) FROM dbo.OEOPNORD
UNION ALL
SELECT 'PODETAIL', COUNT(*) FROM dbo.PODETAIL;
