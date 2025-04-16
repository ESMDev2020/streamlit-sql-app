USE SigmaTB;

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'General Ledger Account file', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'GLACCT';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''GLACCT'', ''General Ledger Account file'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'General Ledger Transaction File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'GLTRANS';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''GLTRANS'', ''General Ledger Transaction File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'General Ledger Account file', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'GLACCT';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''GLACCT'', ''General Ledger Account file'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'General Ledger Transaction File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'GLTRANS';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''GLTRANS'', ''General Ledger Transaction File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Salesman Master File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'SALESMAN';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''SALESMAN'', ''Salesman Master File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Sales Description Override', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'SLSDSCOV';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''SLSDSCOV'', ''Sales Description Override'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Shipments File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'SHIPMAST';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''SHIPMAST'', ''Shipments File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Purchase Order Detail File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'PODETAIL';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''PODETAIL'', ''Purchase Order Detail File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Vendor Master File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'APVEND';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''APVEND'', ''Vendor Master File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Material Processing Order Detail', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'MPDETAIL';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''MPDETAIL'', ''Material Processing Order Detail'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Tag Master File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'ITEMTAG';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''ITEMTAG'', ''Tag Master File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Customer Master File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'ARCUST';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''ARCUST'', ''Customer Master File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Item Transaction History', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'ITEMHIST';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''ITEMHIST'', ''Item Transaction History'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Item Master File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'ITEMMAST';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''ITEMMAST'', ''Item Master File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Item on Hand File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'ITEMONHD';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''ITEMONHD'', ''Item on Hand File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Order Detail File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'OEDETAIL';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''OEDETAIL'', ''Order Detail File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Open Order File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'OEOPNORD';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''OEOPNORD'', ''Open Order File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Service Purchase Order Header File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'SPHEADER';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''SPHEADER'', ''Service Purchase Order Header File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'General Ledger Account file', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'GLACCT';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''GLACCT'', ''General Ledger Account file'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'General Ledger Transaction File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'GLTRANS';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''GLTRANS'', ''General Ledger Transaction File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Salesman Master File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'SALESMAN';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''SALESMAN'', ''Salesman Master File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Sales Description Override', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'SLSDSCOV';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''SLSDSCOV'', ''Sales Description Override'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Shipments File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'SHIPMAST';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''SHIPMAST'', ''Shipments File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Open Order File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'OEOPNORD';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''OEOPNORD'', ''Open Order File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Order Detail File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'OEDETAIL';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''OEDETAIL'', ''Order Detail File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Material Processing Order Detail', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'MPDETAIL';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''MPDETAIL'', ''Material Processing Order Detail'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Vendor Master File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'APVEND';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''APVEND'', ''Vendor Master File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Purchase Order Detail File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'PODETAIL';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''PODETAIL'', ''Purchase Order Detail File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Customer Master File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'ARCUST';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''ARCUST'', ''Customer Master File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Tag Master File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'ITEMTAG';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''ITEMTAG'', ''Tag Master File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Item on Hand File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'ITEMONHD';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''ITEMONHD'', ''Item on Hand File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Item Master File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'ITEMMAST';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''ITEMMAST'', ''Item Master File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Salesman Master File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'SALESMAN';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''SALESMAN'', ''Salesman Master File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Sales Description Override', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'SLSDSCOV';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''SLSDSCOV'', ''Sales Description Override'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Shipments File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'SHIPMAST';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''SHIPMAST'', ''Shipments File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Open Order File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'OEOPNORD';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''OEOPNORD'', ''Open Order File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Order Detail File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'OEDETAIL';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''OEDETAIL'', ''Order Detail File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Material Processing Order Detail', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'MPDETAIL';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''MPDETAIL'', ''Material Processing Order Detail'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Vendor Master File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'APVEND';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''APVEND'', ''Vendor Master File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Item on Hand File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'ITEMONHD';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''ITEMONHD'', ''Item on Hand File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Purchase Order Detail File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'PODETAIL';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''PODETAIL'', ''Purchase Order Detail File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Customer Master File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'ARCUST';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''ARCUST'', ''Customer Master File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Tag Master File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'ITEMTAG';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''ITEMTAG'', ''Tag Master File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Item Transaction History', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'ITEMHIST';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''ITEMHIST'', ''Item Transaction History'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Service Purchase Order Header File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'SPHEADER';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''SPHEADER'', ''Service Purchase Order Header File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Item on Hand File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'ITEMONHD';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''ITEMONHD'', ''Item on Hand File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Item Master File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'ITEMMAST';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''ITEMMAST'', ''Item Master File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Item Transaction History', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'ITEMHIST';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''ITEMHIST'', ''Item Transaction History'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Service Purchase Order Header File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'SPHEADER';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''SPHEADER'', ''Service Purchase Order Header File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'General Ledger Account file', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'GLACCT';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''GLACCT'', ''General Ledger Account file'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'General Ledger Transaction File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'GLTRANS';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''GLTRANS'', ''General Ledger Transaction File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Salesman Master File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'SALESMAN';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''SALESMAN'', ''Salesman Master File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Sales Description Override', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'SLSDSCOV';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''SLSDSCOV'', ''Sales Description Override'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Shipments File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'SHIPMAST';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''SHIPMAST'', ''Shipments File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Material Processing Order Detail', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'MPDETAIL';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''MPDETAIL'', ''Material Processing Order Detail'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Vendor Master File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'APVEND';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''APVEND'', ''Vendor Master File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Purchase Order Detail File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'PODETAIL';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''PODETAIL'', ''Purchase Order Detail File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Tag Master File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'ITEMTAG';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''ITEMTAG'', ''Tag Master File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Customer Master File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'ARCUST';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''ARCUST'', ''Customer Master File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Item Transaction History', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'ITEMHIST';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''ITEMHIST'', ''Item Transaction History'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Item Master File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'ITEMMAST';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''ITEMMAST'', ''Item Master File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Item on Hand File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'ITEMONHD';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''ITEMONHD'', ''Item on Hand File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Order Detail File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'OEDETAIL';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''OEDETAIL'', ''Order Detail File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Open Order File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'OEOPNORD';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''OEOPNORD'', ''Open Order File'')';
END CATCH

BEGIN TRY
    EXEC sp_addextendedproperty 
      @name = N'MS_Description', 
      @value = N'Service Purchase Order Header File', 
      @level0type = N'SCHEMA', @level0name = N'dbo',
      @level1type = N'TABLE',  @level1name = N'SPHEADER';
END TRY
BEGIN CATCH
    PRINT 'Skipping: (''SPHEADER'', ''Service Purchase Order Header File'')';
END CATCH