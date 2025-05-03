-- SQL DDL using ObjectDBName with INFERRED Inline Keys
-- WARNING: Keys are GUESSED. Identifiers taken from ObjectDBName (quoted).
--          Thoroughly review and CORRECT this schema in your ERD tool (DBSchema).

-- Table: "z_A/P_Debit_Detail_File_____APDEBD" (Code: APDEBD)
CREATE TABLE "z_A/P_Debit_Detail_File_____APDEBD" (
    "z_A/P_Debit_Detail_File_____APDEBD_ID" INT,
    "z_A/P_Debit_Detail_File_____APDEBD" VARCHAR(255),
    "z_A/P_Debit_Detail_File_____APDEBD" VARCHAR(255),
    PRIMARY KEY ("z_A/P_Debit_Detail_File_____APDEBD_ID") -- Generic PK (NEEDS VALIDATION!)
);

-- Table: "z_Vendor_Master_File_____APVEND" (Code: APVEND)
CREATE TABLE "z_Vendor_Master_File_____APVEND" (
    "z_Vendor_Master_File_____APVEND_ID" INT,
    "z_Vendor_Master_File_____APVEND" VARCHAR(255),
    "z_Vendor_Master_File_____APVEND" VARCHAR(255),
    "z_Vendor_Master_File_____APVEND" VARCHAR(255),
    "z_Vendor_Master_File_____APVEND" VARCHAR(255),
    "z_Vendor_Master_File_____APVEND" VARCHAR(255),
    PRIMARY KEY ("z_Vendor_Master_File_____APVEND_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_Vendor_Master_File_____APVEND") REFERENCES "z_Customer_Master_File_____ARCUST" ("z_Customer_Master_File_____ARCUST") -- Inferred FK (Codes: VCCUST->ARCUST.CCUST, Suffix: 'CUST'),
    FOREIGN KEY ("z_Vendor_Master_File_____APVEND") REFERENCES "z_Customer_Master_File_____ARCUST" ("z_Customer_Master_File_____ARCUST") -- Inferred FK (Codes: VCUST->ARCUST.CCUST, Suffix: 'CUST')
);

-- Table: "z_A/P_Check_Register_Work_File_____APWK856" (Code: APWK856)
CREATE TABLE "z_A/P_Check_Register_Work_File_____APWK856" (
    "z_A/P_Check_Register_Work_File_____APWK856_ID" INT,
    "z_A/P_Check_Register_Work_File_____APWK856" VARCHAR(255),
    "z_A/P_Check_Register_Work_File_____APWK856" VARCHAR(255),
    PRIMARY KEY ("z_A/P_Check_Register_Work_File_____APWK856_ID") -- Generic PK (NEEDS VALIDATION!)
);

-- Table: "z_Customer_Master_File_____ARCUST" (Code: ARCUST)
CREATE TABLE "z_Customer_Master_File_____ARCUST" (
    "z_Customer_Master_File_____ARCUST" VARCHAR(255),
    "z_Customer_Master_File_____ARCUST" VARCHAR(255),
    "z_Customer_Master_File_____ARCUST" VARCHAR(255),
    "z_Customer_Master_File_____ARCUST" VARCHAR(255),
    PRIMARY KEY ("z_Customer_Master_File_____ARCUST")
);

-- Table: "z_Customer_Class_Summary_file_MTD_____CCLSMT" (Code: CCLSMT)
CREATE TABLE "z_Customer_Class_Summary_file_MTD_____CCLSMT" (
    "z_Customer_Class_Summary_file_MTD_____CCLSMT_ID" INT,
    "z_Customer_Class_Summary_file_MTD_____CCLSMT" VARCHAR(255),
    "z_Customer_Class_Summary_file_MTD_____CCLSMT" VARCHAR(255),
    PRIMARY KEY ("z_Customer_Class_Summary_file_MTD_____CCLSMT_ID") -- Generic PK (NEEDS VALIDATION!)
);

-- Table: "z_Customer_Class_Summary_file_YTD_____CCLSYT" (Code: CCLSYT)
CREATE TABLE "z_Customer_Class_Summary_file_YTD_____CCLSYT" (
    "z_Customer_Class_Summary_file_YTD_____CCLSYT_ID" INT,
    "z_Customer_Class_Summary_file_YTD_____CCLSYT" VARCHAR(255),
    "z_Customer_Class_Summary_file_YTD_____CCLSYT" VARCHAR(255),
    PRIMARY KEY ("z_Customer_Class_Summary_file_YTD_____CCLSYT_ID") -- Generic PK (NEEDS VALIDATION!)
);

-- Table: "z_Credit_Comment_File_____CRCOMMNT" (Code: CRCOMMNT)
CREATE TABLE "z_Credit_Comment_File_____CRCOMMNT" (
    "z_Credit_Comment_File_____CRCOMMNT_ID" INT,
    "z_Credit_Comment_File_____CRCOMMNT" VARCHAR(255),
    PRIMARY KEY ("z_Credit_Comment_File_____CRCOMMNT_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_Credit_Comment_File_____CRCOMMNT") REFERENCES "z_Customer_Master_File_____ARCUST" ("z_Customer_Master_File_____ARCUST") -- Inferred FK (Codes: C7CUST->ARCUST.CCUST, Suffix: 'CUST')
);

-- Table: "z_Credit_Memo_Detail_File_____CRDETAIL" (Code: CRDETAIL)
CREATE TABLE "z_Credit_Memo_Detail_File_____CRDETAIL" (
    "z_Credit_Memo_Detail_File_____CRDETAIL_ID" INT,
    "z_Credit_Memo_Detail_File_____CRDETAIL" VARCHAR(255),
    "z_Credit_Memo_Detail_File_____CRDETAIL" VARCHAR(255),
    PRIMARY KEY ("z_Credit_Memo_Detail_File_____CRDETAIL_ID") -- Generic PK (NEEDS VALIDATION!)
);

-- Table: "z_Credit_Memo_Header_File_____CRHEADER" (Code: CRHEADER)
CREATE TABLE "z_Credit_Memo_Header_File_____CRHEADER" (
    "z_Credit_Memo_Header_File_____CRHEADER_ID" INT,
    "z_Credit_Memo_Header_File_____CRHEADER" VARCHAR(255),
    PRIMARY KEY ("z_Credit_Memo_Header_File_____CRHEADER_ID") -- Generic PK (NEEDS VALIDATION!)
);

-- Table: "z_Delivery_Tracking_Performance_File_____DELTRACK" (Code: DELTRACK)
CREATE TABLE "z_Delivery_Tracking_Performance_File_____DELTRACK" (
    "z_Delivery_Tracking_Performance_File_____DELTRACK_ID" INT,
    "z_Delivery_Tracking_Performance_File_____DELTRACK" TIMESTAMP,
    "z_Delivery_Tracking_Performance_File_____DELTRACK" VARCHAR(255),
    "z_Delivery_Tracking_Performance_File_____DELTRACK" VARCHAR(255),
    "z_Delivery_Tracking_Performance_File_____DELTRACK" TIMESTAMP,
    "z_Delivery_Tracking_Performance_File_____DELTRACK" VARCHAR(255),
    "z_Delivery_Tracking_Performance_File_____DELTRACK" VARCHAR(255),
    "z_Delivery_Tracking_Performance_File_____DELTRACK" VARCHAR(255),
    PRIMARY KEY ("z_Delivery_Tracking_Performance_File_____DELTRACK_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_Delivery_Tracking_Performance_File_____DELTRACK") REFERENCES "z_Customer_Master_File_____ARCUST" ("z_Customer_Master_File_____ARCUST") -- Inferred FK (Codes: DPCUST->ARCUST.CCUST, Suffix: 'CUST')
);

-- Table: "z_Query_Builder_Physical_File_____DPPFFD" (Code: DPPFFD)
CREATE TABLE "z_Query_Builder_Physical_File_____DPPFFD" (
    "z_Query_Builder_Physical_File_____DPPFFD_ID" INT,
    "z_Query_Builder_Physical_File_____DPPFFD" VARCHAR(255),
    PRIMARY KEY ("z_Query_Builder_Physical_File_____DPPFFD_ID") -- Generic PK (NEEDS VALIDATION!)
);

-- Table: "z_Last_Day_of_Period_File_____EMLSTDAY" (Code: EMLSTDAY)
CREATE TABLE "z_Last_Day_of_Period_File_____EMLSTDAY" (
    "z_Last_Day_of_Period_File_____EMLSTDAY_ID" INT,
    "z_Last_Day_of_Period_File_____EMLSTDAY" VARCHAR(255),
    PRIMARY KEY ("z_Last_Day_of_Period_File_____EMLSTDAY_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_Last_Day_of_Period_File_____EMLSTDAY") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: ELDIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST')
);

-- Table: "z_Freight_Reconciliation_File_____FRTHST" (Code: FRTHST)
CREATE TABLE "z_Freight_Reconciliation_File_____FRTHST" (
    "z_Freight_Reconciliation_File_____FRTHST_ID" INT,
    "z_Freight_Reconciliation_File_____FRTHST" VARCHAR(255),
    "z_Freight_Reconciliation_File_____FRTHST" VARCHAR(255),
    "z_Freight_Reconciliation_File_____FRTHST" DECIMAL(18, 4),
    "z_Freight_Reconciliation_File_____FRTHST" VARCHAR(255),
    PRIMARY KEY ("z_Freight_Reconciliation_File_____FRTHST_ID") -- Generic PK (NEEDS VALIDATION!)
);

-- Table: "z_G/L_Journal_Batch_Header_File_____GLJRBA" (Code: GLJRBA)
CREATE TABLE "z_G/L_Journal_Batch_Header_File_____GLJRBA" (
    "z_G/L_Journal_Batch_Header_File_____GLJRBA_ID" INT,
    "z_G/L_Journal_Batch_Header_File_____GLJRBA" DECIMAL(18, 4),
    PRIMARY KEY ("z_G/L_Journal_Batch_Header_File_____GLJRBA_ID") -- Generic PK (NEEDS VALIDATION!)
);

-- Table: "z_General_Ledger_Master_File_____GLMAST" (Code: GLMAST)
CREATE TABLE "z_General_Ledger_Master_File_____GLMAST" (
    "z_General_Ledger_Master_File_____GLMAST_ID" INT,
    "z_General_Ledger_Master_File_____GLMAST" VARCHAR(255),
    PRIMARY KEY ("z_General_Ledger_Master_File_____GLMAST_ID") -- Generic PK (NEEDS VALIDATION!)
);

-- Table: "z_General_Ledger_Transaction_File_____GLTRANS" (Code: GLTRANS)
CREATE TABLE "z_General_Ledger_Transaction_File_____GLTRANS" (
    "z_General_Ledger_Transaction_File_____GLTRANS_ID" INT,
    "z_General_Ledger_Transaction_File_____GLTRANS" VARCHAR(255),
    "z_General_Ledger_Transaction_File_____GLTRANS" VARCHAR(255),
    "z_General_Ledger_Transaction_File_____GLTRANS" VARCHAR(255),
    "z_General_Ledger_Transaction_File_____GLTRANS" VARCHAR(255),
    "z_General_Ledger_Transaction_File_____GLTRANS" VARCHAR(255),
    "z_General_Ledger_Transaction_File_____GLTRANS" VARCHAR(255),
    PRIMARY KEY ("z_General_Ledger_Transaction_File_____GLTRANS_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_General_Ledger_Transaction_File_____GLTRANS") REFERENCES "z_Customer_Master_File_____ARCUST" ("z_Customer_Master_File_____ARCUST") -- Inferred FK (Codes: GLCUST->ARCUST.CCUST, Suffix: 'CUST'),
    FOREIGN KEY ("z_General_Ledger_Transaction_File_____GLTRANS") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: GLDIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST')
);

-- Table: "z_IATRANS_-_History_(Save_Batch)_____IATRANHS" (Code: IATRANHS)
CREATE TABLE "z_IATRANS_-_History_(Save_Batch)_____IATRANHS" (
    "z_IATRANS_-_History_(Save_Batch)_____IATRANHS" INT,
    "z_IATRANS_-_History_(Save_Batch)_____IATRANHS" VARCHAR(255),
    "z_IATRANS_-_History_(Save_Batch)_____IATRANHS" VARCHAR(255),
    "z_IATRANS_-_History_(Save_Batch)_____IATRANHS" VARCHAR(255),
    "z_IATRANS_-_History_(Save_Batch)_____IATRANHS" VARCHAR(255),
    "z_IATRANS_-_History_(Save_Batch)_____IATRANHS" VARCHAR(255),
    PRIMARY KEY ("z_IATRANS_-_History_(Save_Batch)_____IATRANHS"),
    FOREIGN KEY ("z_IATRANS_-_History_(Save_Batch)_____IATRANHS") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: IADIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST')
);

-- Table: "z_IATRANS_-_Inventory_Adj_Transactions_____IATRANS" (Code: IATRANS)
CREATE TABLE "z_IATRANS_-_Inventory_Adj_Transactions_____IATRANS" (
    "z_IATRANS_-_Inventory_Adj_Transactions_____IATRANS" INT,
    "z_IATRANS_-_Inventory_Adj_Transactions_____IATRANS" VARCHAR(255),
    "z_IATRANS_-_Inventory_Adj_Transactions_____IATRANS" VARCHAR(255),
    "z_IATRANS_-_Inventory_Adj_Transactions_____IATRANS" VARCHAR(255),
    "z_IATRANS_-_Inventory_Adj_Transactions_____IATRANS" VARCHAR(255),
    "z_IATRANS_-_Inventory_Adj_Transactions_____IATRANS" VARCHAR(255),
    PRIMARY KEY ("z_IATRANS_-_Inventory_Adj_Transactions_____IATRANS"),
    FOREIGN KEY ("z_IATRANS_-_Inventory_Adj_Transactions_____IATRANS") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: IADIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST')
);

-- Table: "z_Image_PDF_____IMAGEPDF" (Code: IMAGEPDF)
CREATE TABLE "z_Image_PDF_____IMAGEPDF" (
    "z_Image_PDF_____IMAGEPDF" VARCHAR(255),
    "z_Image_PDF_____IMAGEPDF" VARCHAR(255),
    "z_Image_PDF_____IMAGEPDF" VARCHAR(255),
    "z_Image_PDF_____IMAGEPDF" VARCHAR(255),
    "z_Image_PDF_____IMAGEPDF" VARCHAR(255),
    "z_Image_PDF_____IMAGEPDF" VARCHAR(255),
    "z_Image_PDF_____IMAGEPDF" INT,
    PRIMARY KEY ("z_Image_PDF_____IMAGEPDF"),
    FOREIGN KEY ("z_Image_PDF_____IMAGEPDF") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: SDDIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST'),
    FOREIGN KEY ("z_Image_PDF_____IMAGEPDF") REFERENCES "z_List_/_Heat_Number_____LISTHEAT" ("z_List_/_Heat_Number_____LISTHEAT_ID") -- Inferred FK (Codes: ITHEAT->LISTHEAT._LISTHEAT_GENERIC_PK_, Suffix: 'HEAT')
);

-- Table: "z_Image_PDF_____IMAGEPDFB4" (Code: IMAGEPDFB4)
CREATE TABLE "z_Image_PDF_____IMAGEPDFB4" (
    "z_Image_PDF_____IMAGEPDFB4" VARCHAR(255),
    "z_Image_PDF_____IMAGEPDFB4" VARCHAR(255),
    "z_Image_PDF_____IMAGEPDFB4" VARCHAR(255),
    "z_Image_PDF_____IMAGEPDFB4" VARCHAR(255),
    "z_Image_PDF_____IMAGEPDFB4" VARCHAR(255),
    "z_Image_PDF_____IMAGEPDFB4" VARCHAR(255),
    "z_Image_PDF_____IMAGEPDFB4" INT,
    PRIMARY KEY ("z_Image_PDF_____IMAGEPDFB4"),
    FOREIGN KEY ("z_Image_PDF_____IMAGEPDFB4") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: SDDIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST'),
    FOREIGN KEY ("z_Image_PDF_____IMAGEPDFB4") REFERENCES "z_List_/_Heat_Number_____LISTHEAT" ("z_List_/_Heat_Number_____LISTHEAT_ID") -- Inferred FK (Codes: ITHEAT->LISTHEAT._LISTHEAT_GENERIC_PK_, Suffix: 'HEAT')
);

-- Table: "z_Inventory_Mill_File_____INVMILL" (Code: INVMILL)
CREATE TABLE "z_Inventory_Mill_File_____INVMILL" (
    "z_Inventory_Mill_File_____INVMILL_ID" INT,
    "z_Inventory_Mill_File_____INVMILL" VARCHAR(255),
    PRIMARY KEY ("z_Inventory_Mill_File_____INVMILL_ID") -- Generic PK (NEEDS VALIDATION!)
);

-- Table: "z_Item_Master_File_____ITEMBG" (Code: ITEMBG)
CREATE TABLE "z_Item_Master_File_____ITEMBG" (
    "z_Item_Master_File_____ITEMBG_ID" INT,
    "z_Item_Master_File_____ITEMBG" VARCHAR(255),
    PRIMARY KEY ("z_Item_Master_File_____ITEMBG_ID") -- Generic PK (NEEDS VALIDATION!)
);

-- Table: "z_Three_Position_Item_Class_File_____ITEMCLS3" (Code: ITEMCLS3)
CREATE TABLE "z_Three_Position_Item_Class_File_____ITEMCLS3" (
    "z_Three_Position_Item_Class_File_____ITEMCLS3_ID" INT,
    "z_Three_Position_Item_Class_File_____ITEMCLS3" VARCHAR(255),
    PRIMARY KEY ("z_Three_Position_Item_Class_File_____ITEMCLS3_ID") -- Generic PK (NEEDS VALIDATION!)
);

-- Table: "z_Item_Transaction_History_____ITEMHIST" (Code: ITEMHIST)
CREATE TABLE "z_Item_Transaction_History_____ITEMHIST" (
    "z_Item_Transaction_History_____ITEMHIST" VARCHAR(255),
    "z_Item_Transaction_History_____ITEMHIST" VARCHAR(255),
    "z_Item_Transaction_History_____ITEMHIST" INT,
    "z_Item_Transaction_History_____ITEMHIST" VARCHAR(255),
    PRIMARY KEY ("z_Item_Transaction_History_____ITEMHIST"),
    FOREIGN KEY ("z_Item_Transaction_History_____ITEMHIST") REFERENCES "z_Customer_Master_File_____ARCUST" ("z_Customer_Master_File_____ARCUST") -- Inferred FK (Codes: IHCUST->ARCUST.CCUST, Suffix: 'CUST'),
    FOREIGN KEY ("z_Item_Transaction_History_____ITEMHIST") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: IHDIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST'),
    FOREIGN KEY ("z_Item_Transaction_History_____ITEMHIST") REFERENCES "z_List_/_Heat_Number_____LISTHEAT" ("z_List_/_Heat_Number_____LISTHEAT_ID") -- Inferred FK (Codes: IHHEAT->LISTHEAT._LISTHEAT_GENERIC_PK_, Suffix: 'HEAT')
);

-- Table: "z_Item_Master_File_____ITEMMAST" (Code: ITEMMAST)
CREATE TABLE "z_Item_Master_File_____ITEMMAST" (
    "z_Item_Master_File_____ITEMMAST_ID" INT,
    "z_Item_Master_File_____ITEMMAST" VARCHAR(255),
    "z_Item_Master_File_____ITEMMAST" VARCHAR(255),
    PRIMARY KEY ("z_Item_Master_File_____ITEMMAST_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_Item_Master_File_____ITEMMAST") REFERENCES "z_Customer_Master_File_____ARCUST" ("z_Customer_Master_File_____ARCUST") -- Inferred FK (Codes: IMCUST->ARCUST.CCUST, Suffix: 'CUST')
);

-- Table: "z_Item_Master_File_____ITEMMASTXX" (Code: ITEMMASTXX)
CREATE TABLE "z_Item_Master_File_____ITEMMASTXX" (
    "z_Item_Master_File_____ITEMMASTXX_ID" INT,
    "z_Item_Master_File_____ITEMMASTXX" VARCHAR(255),
    PRIMARY KEY ("z_Item_Master_File_____ITEMMASTXX_ID") -- Generic PK (NEEDS VALIDATION!)
);

-- Table: "z_Item_on_hand_comment_file_____ITEMONCM" (Code: ITEMONCM)
CREATE TABLE "z_Item_on_hand_comment_file_____ITEMONCM" (
    "z_Item_on_hand_comment_file_____ITEMONCM_ID" INT,
    "z_Item_on_hand_comment_file_____ITEMONCM" VARCHAR(255),
    PRIMARY KEY ("z_Item_on_hand_comment_file_____ITEMONCM_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_Item_on_hand_comment_file_____ITEMONCM") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: I5DIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST')
);

-- Table: "z_Item_on_Hand_File_____ITEMONHD" (Code: ITEMONHD)
CREATE TABLE "z_Item_on_Hand_File_____ITEMONHD" (
    "z_Item_on_Hand_File_____ITEMONHD_ID" INT,
    "z_Item_on_Hand_File_____ITEMONHD" VARCHAR(255),
    "z_Item_on_Hand_File_____ITEMONHD" VARCHAR(255),
    PRIMARY KEY ("z_Item_on_Hand_File_____ITEMONHD_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_Item_on_Hand_File_____ITEMONHD") REFERENCES "z_Customer_Master_File_____ARCUST" ("z_Customer_Master_File_____ARCUST") -- Inferred FK (Codes: IOCUST->ARCUST.CCUST, Suffix: 'CUST'),
    FOREIGN KEY ("z_Item_on_Hand_File_____ITEMONHD") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: IODIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST')
);

-- Table: "z_Tag_Master_File_____ITEMTAG" (Code: ITEMTAG)
CREATE TABLE "z_Tag_Master_File_____ITEMTAG" (
    "z_Tag_Master_File_____ITEMTAG_ID" INT,
    "z_Tag_Master_File_____ITEMTAG" VARCHAR(255),
    "z_Tag_Master_File_____ITEMTAG" VARCHAR(255),
    "z_Tag_Master_File_____ITEMTAG" VARCHAR(255),
    "z_Tag_Master_File_____ITEMTAG" VARCHAR(255),
    "z_Tag_Master_File_____ITEMTAG" VARCHAR(255),
    "z_Tag_Master_File_____ITEMTAG" VARCHAR(255),
    "z_Tag_Master_File_____ITEMTAG" VARCHAR(255),
    "z_Tag_Master_File_____ITEMTAG" VARCHAR(255),
    "z_Tag_Master_File_____ITEMTAG" VARCHAR(255),
    "z_Tag_Master_File_____ITEMTAG" VARCHAR(255),
    "z_Tag_Master_File_____ITEMTAG" VARCHAR(255),
    PRIMARY KEY ("z_Tag_Master_File_____ITEMTAG_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_Tag_Master_File_____ITEMTAG") REFERENCES "z_Customer_Master_File_____ARCUST" ("z_Customer_Master_File_____ARCUST") -- Inferred FK (Codes: ITCUST->ARCUST.CCUST, Suffix: 'CUST'),
    FOREIGN KEY ("z_Tag_Master_File_____ITEMTAG") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: ITDIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST'),
    FOREIGN KEY ("z_Tag_Master_File_____ITEMTAG") REFERENCES "z_List_/_Heat_Number_____LISTHEAT" ("z_List_/_Heat_Number_____LISTHEAT_ID") -- Inferred FK (Codes: ITHEAT->LISTHEAT._LISTHEAT_GENERIC_PK_, Suffix: 'HEAT')
);

-- Table: "z_Tag_Process_History_File_____ITEMTPHS" (Code: ITEMTPHS)
CREATE TABLE "z_Tag_Process_History_File_____ITEMTPHS" (
    "z_Tag_Process_History_File_____ITEMTPHS_ID" INT,
    "z_Tag_Process_History_File_____ITEMTPHS" VARCHAR(255),
    PRIMARY KEY ("z_Tag_Process_History_File_____ITEMTPHS_ID") -- Generic PK (NEEDS VALIDATION!)
);

-- Table: "z_line_comment_changes_____LINECCHG" (Code: LINECCHG)
CREATE TABLE "z_line_comment_changes_____LINECCHG" (
    "z_line_comment_changes_____LINECCHG_ID" INT,
    "z_line_comment_changes_____LINECCHG" VARCHAR(255),
    "z_line_comment_changes_____LINECCHG" VARCHAR(255),
    "z_line_comment_changes_____LINECCHG" VARCHAR(255),
    PRIMARY KEY ("z_line_comment_changes_____LINECCHG_ID") -- Generic PK (NEEDS VALIDATION!)
);

-- Table: "z_Line_Related_Comments_____LINECMNT" (Code: LINECMNT)
CREATE TABLE "z_Line_Related_Comments_____LINECMNT" (
    "z_Line_Related_Comments_____LINECMNT_ID" INT,
    "z_Line_Related_Comments_____LINECMNT" VARCHAR(255),
    "z_Line_Related_Comments_____LINECMNT" VARCHAR(255),
    PRIMARY KEY ("z_Line_Related_Comments_____LINECMNT_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_Line_Related_Comments_____LINECMNT") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: LCDIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST')
);

-- Table: "z_Line_Comment_Code_Constants_____LINECNST" (Code: LINECNST)
CREATE TABLE "z_Line_Comment_Code_Constants_____LINECNST" (
    "z_Line_Comment_Code_Constants_____LINECNST_ID" INT,
    "z_Line_Comment_Code_Constants_____LINECNST" VARCHAR(255),
    "z_Line_Comment_Code_Constants_____LINECNST" VARCHAR(255),
    "z_Line_Comment_Code_Constants_____LINECNST" VARCHAR(255),
    "z_Line_Comment_Code_Constants_____LINECNST" VARCHAR(255),
    "z_Line_Comment_Code_Constants_____LINECNST" VARCHAR(255),
    "z_Line_Comment_Code_Constants_____LINECNST" VARCHAR(255),
    PRIMARY KEY ("z_Line_Comment_Code_Constants_____LINECNST_ID") -- Generic PK (NEEDS VALIDATION!)
);

-- Table: "z_List_/_Heat_Number_____LISTHEAT" (Code: LISTHEAT)
CREATE TABLE "z_List_/_Heat_Number_____LISTHEAT" (
    "z_List_/_Heat_Number_____LISTHEAT_ID" INT,
    "z_List_/_Heat_Number_____LISTHEAT" VARCHAR(255),
    "z_List_/_Heat_Number_____LISTHEAT" VARCHAR(255),
    PRIMARY KEY ("z_List_/_Heat_Number_____LISTHEAT_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_List_/_Heat_Number_____LISTHEAT") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: LHDIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST')
);

-- Table: "z_Material_Processing_Order_Detail_____MPDETAIL" (Code: MPDETAIL)
CREATE TABLE "z_Material_Processing_Order_Detail_____MPDETAIL" (
    "z_Material_Processing_Order_Detail_____MPDETAIL_ID" INT,
    "z_Material_Processing_Order_Detail_____MPDETAIL" VARCHAR(255),
    "z_Material_Processing_Order_Detail_____MPDETAIL" VARCHAR(255),
    "z_Material_Processing_Order_Detail_____MPDETAIL" VARCHAR(255),
    "z_Material_Processing_Order_Detail_____MPDETAIL" VARCHAR(255),
    "z_Material_Processing_Order_Detail_____MPDETAIL" VARCHAR(255),
    "z_Material_Processing_Order_Detail_____MPDETAIL" VARCHAR(255),
    PRIMARY KEY ("z_Material_Processing_Order_Detail_____MPDETAIL_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_Material_Processing_Order_Detail_____MPDETAIL") REFERENCES "z_Customer_Master_File_____ARCUST" ("z_Customer_Master_File_____ARCUST") -- Inferred FK (Codes: MDCUST->ARCUST.CCUST, Suffix: 'CUST'),
    FOREIGN KEY ("z_Material_Processing_Order_Detail_____MPDETAIL") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: MDDIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST')
);

-- Table: "z_Material_Processing_Order_Header_____MPHDRORD" (Code: MPHDRORD)
CREATE TABLE "z_Material_Processing_Order_Header_____MPHDRORD" (
    "z_Material_Processing_Order_Header_____MPHDRORD" VARCHAR(255),
    "z_Material_Processing_Order_Header_____MPHDRORD" INT,
    "z_Material_Processing_Order_Header_____MPHDRORD" VARCHAR(255),
    "z_Material_Processing_Order_Header_____MPHDRORD" VARCHAR(255),
    "z_Material_Processing_Order_Header_____MPHDRORD" VARCHAR(255),
    "z_Material_Processing_Order_Header_____MPHDRORD" VARCHAR(255),
    "z_Material_Processing_Order_Header_____MPHDRORD" VARCHAR(255),
    PRIMARY KEY ("z_Material_Processing_Order_Header_____MPHDRORD"),
    FOREIGN KEY ("z_Material_Processing_Order_Header_____MPHDRORD") REFERENCES "z_Customer_Master_File_____ARCUST" ("z_Customer_Master_File_____ARCUST") -- Inferred FK (Codes: MHCUST->ARCUST.CCUST, Suffix: 'CUST'),
    FOREIGN KEY ("z_Material_Processing_Order_Header_____MPHDRORD") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: MHDIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST')
);

-- Table: "z_M/P_Final_Detail_____MPHSTDET" (Code: MPHSTDET)
CREATE TABLE "z_M/P_Final_Detail_____MPHSTDET" (
    "z_M/P_Final_Detail_____MPHSTDET_ID" INT,
    "z_M/P_Final_Detail_____MPHSTDET" VARCHAR(255),
    "z_M/P_Final_Detail_____MPHSTDET" VARCHAR(255),
    "z_M/P_Final_Detail_____MPHSTDET" VARCHAR(255),
    "z_M/P_Final_Detail_____MPHSTDET" VARCHAR(255),
    "z_M/P_Final_Detail_____MPHSTDET" VARCHAR(255),
    "z_M/P_Final_Detail_____MPHSTDET" VARCHAR(255),
    PRIMARY KEY ("z_M/P_Final_Detail_____MPHSTDET_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_M/P_Final_Detail_____MPHSTDET") REFERENCES "z_Customer_Master_File_____ARCUST" ("z_Customer_Master_File_____ARCUST") -- Inferred FK (Codes: MDCUST->ARCUST.CCUST, Suffix: 'CUST'),
    FOREIGN KEY ("z_M/P_Final_Detail_____MPHSTDET") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: MDDIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST')
);

-- Table: "z_M/P_Final_Header_____MPHSTHDR" (Code: MPHSTHDR)
CREATE TABLE "z_M/P_Final_Header_____MPHSTHDR" (
    "z_M/P_Final_Header_____MPHSTHDR" VARCHAR(255),
    "z_M/P_Final_Header_____MPHSTHDR" INT,
    "z_M/P_Final_Header_____MPHSTHDR" VARCHAR(255),
    "z_M/P_Final_Header_____MPHSTHDR" VARCHAR(255),
    "z_M/P_Final_Header_____MPHSTHDR" VARCHAR(255),
    "z_M/P_Final_Header_____MPHSTHDR" VARCHAR(255),
    PRIMARY KEY ("z_M/P_Final_Header_____MPHSTHDR"),
    FOREIGN KEY ("z_M/P_Final_Header_____MPHSTHDR") REFERENCES "z_Customer_Master_File_____ARCUST" ("z_Customer_Master_File_____ARCUST") -- Inferred FK (Codes: MHCUST->ARCUST.CCUST, Suffix: 'CUST'),
    FOREIGN KEY ("z_M/P_Final_Header_____MPHSTHDR") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: MHDIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST')
);

-- Table: "z_M/P_Final_Processing_Charges_____MPHSTPRC" (Code: MPHSTPRC)
CREATE TABLE "z_M/P_Final_Processing_Charges_____MPHSTPRC" (
    "z_M/P_Final_Processing_Charges_____MPHSTPRC_ID" INT,
    "z_M/P_Final_Processing_Charges_____MPHSTPRC" VARCHAR(255),
    "z_M/P_Final_Processing_Charges_____MPHSTPRC" VARCHAR(255),
    "z_M/P_Final_Processing_Charges_____MPHSTPRC" VARCHAR(255),
    PRIMARY KEY ("z_M/P_Final_Processing_Charges_____MPHSTPRC_ID") -- Generic PK (NEEDS VALIDATION!)
);

-- Table: "z_M/P_Final_Restock_____MPHSTRSK" (Code: MPHSTRSK)
CREATE TABLE "z_M/P_Final_Restock_____MPHSTRSK" (
    "z_M/P_Final_Restock_____MPHSTRSK" INT,
    "z_M/P_Final_Restock_____MPHSTRSK" VARCHAR(255),
    "z_M/P_Final_Restock_____MPHSTRSK" VARCHAR(255),
    "z_M/P_Final_Restock_____MPHSTRSK" VARCHAR(255),
    PRIMARY KEY ("z_M/P_Final_Restock_____MPHSTRSK"),
    FOREIGN KEY ("z_M/P_Final_Restock_____MPHSTRSK") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: RLDIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST')
);

-- Table: "z_M/P_Final_Used_____MPHSTUSE" (Code: MPHSTUSE)
CREATE TABLE "z_M/P_Final_Used_____MPHSTUSE" (
    "z_M/P_Final_Used_____MPHSTUSE_ID" INT,
    "z_M/P_Final_Used_____MPHSTUSE" VARCHAR(255),
    "z_M/P_Final_Used_____MPHSTUSE" VARCHAR(255),
    "z_M/P_Final_Used_____MPHSTUSE" VARCHAR(255),
    "z_M/P_Final_Used_____MPHSTUSE" VARCHAR(255),
    "z_M/P_Final_Used_____MPHSTUSE" VARCHAR(255),
    "z_M/P_Final_Used_____MPHSTUSE" VARCHAR(255),
    "z_M/P_Final_Used_____MPHSTUSE" VARCHAR(255),
    "z_M/P_Final_Used_____MPHSTUSE" VARCHAR(255),
    "z_M/P_Final_Used_____MPHSTUSE" VARCHAR(255),
    "z_M/P_Final_Used_____MPHSTUSE" VARCHAR(255),
    "z_M/P_Final_Used_____MPHSTUSE" DECIMAL(18, 4),
    "z_M/P_Final_Used_____MPHSTUSE" VARCHAR(255),
    "z_M/P_Final_Used_____MPHSTUSE" VARCHAR(255),
    "z_M/P_Final_Used_____MPHSTUSE" VARCHAR(255),
    "z_M/P_Final_Used_____MPHSTUSE" VARCHAR(255),
    "z_M/P_Final_Used_____MPHSTUSE" VARCHAR(255),
    "z_M/P_Final_Used_____MPHSTUSE" VARCHAR(255),
    "z_M/P_Final_Used_____MPHSTUSE" VARCHAR(255),
    "z_M/P_Final_Used_____MPHSTUSE" DECIMAL(18, 4),
    "z_M/P_Final_Used_____MPHSTUSE" VARCHAR(255),
    PRIMARY KEY ("z_M/P_Final_Used_____MPHSTUSE_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_M/P_Final_Used_____MPHSTUSE") REFERENCES "z_Customer_Master_File_____ARCUST" ("z_Customer_Master_File_____ARCUST") -- Inferred FK (Codes: ULCUST->ARCUST.CCUST, Suffix: 'CUST'),
    FOREIGN KEY ("z_M/P_Final_Used_____MPHSTUSE") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: ULDIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST')
);

-- Table: "z_Material_Process_Profile_File_____MPPROFIL" (Code: MPPROFIL)
CREATE TABLE "z_Material_Process_Profile_File_____MPPROFIL" (
    "z_Material_Process_Profile_File_____MPPROFIL_ID" INT,
    "z_Material_Process_Profile_File_____MPPROFIL" VARCHAR(255),
    "z_Material_Process_Profile_File_____MPPROFIL" VARCHAR(255),
    "z_Material_Process_Profile_File_____MPPROFIL" VARCHAR(255),
    PRIMARY KEY ("z_Material_Process_Profile_File_____MPPROFIL_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_Material_Process_Profile_File_____MPPROFIL") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: MFDIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST')
);

-- Table: "z_M/P_Final_Processing_Tracking_File_____MPTRCK" (Code: MPTRCK)
CREATE TABLE "z_M/P_Final_Processing_Tracking_File_____MPTRCK" (
    "z_M/P_Final_Processing_Tracking_File_____MPTRCK_ID" INT,
    "z_M/P_Final_Processing_Tracking_File_____MPTRCK" VARCHAR(255),
    PRIMARY KEY ("z_M/P_Final_Processing_Tracking_File_____MPTRCK_ID") -- Generic PK (NEEDS VALIDATION!)
);

-- Table: "z_M/P_Order_Tracking_History_____MPTRKHST" (Code: MPTRKHST)
CREATE TABLE "z_M/P_Order_Tracking_History_____MPTRKHST" (
    "z_M/P_Order_Tracking_History_____MPTRKHST_ID" INT,
    "z_M/P_Order_Tracking_History_____MPTRKHST" VARCHAR(255),
    "z_M/P_Order_Tracking_History_____MPTRKHST" VARCHAR(255),
    "z_M/P_Order_Tracking_History_____MPTRKHST" VARCHAR(255),
    PRIMARY KEY ("z_M/P_Order_Tracking_History_____MPTRKHST_ID") -- Generic PK (NEEDS VALIDATION!)
);

-- Table: "z_BOL_Master_File_____MWRESET" (Code: MWRESET)
CREATE TABLE "z_BOL_Master_File_____MWRESET" (
    "z_BOL_Master_File_____MWRESET" INT,
    PRIMARY KEY ("z_BOL_Master_File_____MWRESET")
);

-- Table: "z_Sales_Order_Detail_File_____OEDETAIL" (Code: OEDETAIL)
CREATE TABLE "z_Sales_Order_Detail_File_____OEDETAIL" (
    "z_Sales_Order_Detail_File_____OEDETAIL_ID" INT,
    "z_Sales_Order_Detail_File_____OEDETAIL" VARCHAR(255),
    "z_Sales_Order_Detail_File_____OEDETAIL" VARCHAR(255),
    "z_Sales_Order_Detail_File_____OEDETAIL" VARCHAR(255),
    "z_Sales_Order_Detail_File_____OEDETAIL" VARCHAR(255),
    "z_Sales_Order_Detail_File_____OEDETAIL" VARCHAR(255),
    "z_Sales_Order_Detail_File_____OEDETAIL" VARCHAR(255),
    PRIMARY KEY ("z_Sales_Order_Detail_File_____OEDETAIL_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_Sales_Order_Detail_File_____OEDETAIL") REFERENCES "z_Customer_Master_File_____ARCUST" ("z_Customer_Master_File_____ARCUST") -- Inferred FK (Codes: ODCUST->ARCUST.CCUST, Suffix: 'CUST'),
    FOREIGN KEY ("z_Sales_Order_Detail_File_____OEDETAIL") REFERENCES "z_List_/_Heat_Number_____LISTHEAT" ("z_List_/_Heat_Number_____LISTHEAT_ID") -- Inferred FK (Codes: ODHEAT->LISTHEAT._LISTHEAT_GENERIC_PK_, Suffix: 'HEAT')
);

-- Table: "z_Sales_History_Detail_File_____OEHISTRD" (Code: OEHISTRD)
CREATE TABLE "z_Sales_History_Detail_File_____OEHISTRD" (
    "z_Sales_History_Detail_File_____OEHISTRD_ID" INT,
    "z_Sales_History_Detail_File_____OEHISTRD" VARCHAR(255),
    "z_Sales_History_Detail_File_____OEHISTRD" VARCHAR(255),
    "z_Sales_History_Detail_File_____OEHISTRD" VARCHAR(255),
    "z_Sales_History_Detail_File_____OEHISTRD" VARCHAR(255),
    PRIMARY KEY ("z_Sales_History_Detail_File_____OEHISTRD_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_Sales_History_Detail_File_____OEHISTRD") REFERENCES "z_Customer_Master_File_____ARCUST" ("z_Customer_Master_File_____ARCUST") -- Inferred FK (Codes: DHCUST->ARCUST.CCUST, Suffix: 'CUST'),
    FOREIGN KEY ("z_Sales_History_Detail_File_____OEHISTRD") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: DHDIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST')
);

-- Table: "z_Sales_History_Header_File_____OEHISTRY" (Code: OEHISTRY)
CREATE TABLE "z_Sales_History_Header_File_____OEHISTRY" (
    "z_Sales_History_Header_File_____OEHISTRY_ID" INT,
    "z_Sales_History_Header_File_____OEHISTRY" VARCHAR(255),
    "z_Sales_History_Header_File_____OEHISTRY" VARCHAR(255),
    "z_Sales_History_Header_File_____OEHISTRY" VARCHAR(255),
    "z_Sales_History_Header_File_____OEHISTRY" VARCHAR(255),
    PRIMARY KEY ("z_Sales_History_Header_File_____OEHISTRY_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_Sales_History_Header_File_____OEHISTRY") REFERENCES "z_Customer_Master_File_____ARCUST" ("z_Customer_Master_File_____ARCUST") -- Inferred FK (Codes: OHCUST->ARCUST.CCUST, Suffix: 'CUST'),
    FOREIGN KEY ("z_Sales_History_Header_File_____OEHISTRY") REFERENCES "z_Sales_Order_Header_File_____OEOPNORD" ("z_Sales_Order_Header_File_____OEOPNORD") -- Inferred FK (Codes: OHORDR->OEOPNORD.OOORDR, Suffix: 'ORDR')
);

-- Table: "z_Sales_Order_Header_File_____OEOPNORD" (Code: OEOPNORD)
CREATE TABLE "z_Sales_Order_Header_File_____OEOPNORD" (
    "z_Sales_Order_Header_File_____OEOPNORD" VARCHAR(255),
    "z_Sales_Order_Header_File_____OEOPNORD" VARCHAR(255),
    "z_Sales_Order_Header_File_____OEOPNORD" VARCHAR(255),
    "z_Sales_Order_Header_File_____OEOPNORD" VARCHAR(255),
    "z_Sales_Order_Header_File_____OEOPNORD" VARCHAR(255),
    "z_Sales_Order_Header_File_____OEOPNORD" VARCHAR(255),
    PRIMARY KEY ("z_Sales_Order_Header_File_____OEOPNORD"),
    FOREIGN KEY ("z_Sales_Order_Header_File_____OEOPNORD") REFERENCES "z_Customer_Master_File_____ARCUST" ("z_Customer_Master_File_____ARCUST") -- Inferred FK (Codes: OOCUST->ARCUST.CCUST, Suffix: 'CUST')
);

-- Table: "z_Sales_Order_Profile_File_____OEPROFIL" (Code: OEPROFIL)
CREATE TABLE "z_Sales_Order_Profile_File_____OEPROFIL" (
    "z_Sales_Order_Profile_File_____OEPROFIL_ID" INT,
    "z_Sales_Order_Profile_File_____OEPROFIL" VARCHAR(255),
    "z_Sales_Order_Profile_File_____OEPROFIL" VARCHAR(255),
    PRIMARY KEY ("z_Sales_Order_Profile_File_____OEPROFIL_ID") -- Generic PK (NEEDS VALIDATION!)
);

-- Table: "z_Sales_Order_Tracking_File_____ORDTRCK" (Code: ORDTRCK)
CREATE TABLE "z_Sales_Order_Tracking_File_____ORDTRCK" (
    "z_Sales_Order_Tracking_File_____ORDTRCK_ID" INT,
    "z_Sales_Order_Tracking_File_____ORDTRCK" VARCHAR(255),
    "z_Sales_Order_Tracking_File_____ORDTRCK" VARCHAR(255),
    "z_Sales_Order_Tracking_File_____ORDTRCK" VARCHAR(255),
    PRIMARY KEY ("z_Sales_Order_Tracking_File_____ORDTRCK_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_Sales_Order_Tracking_File_____ORDTRCK") REFERENCES "z_Customer_Master_File_____ARCUST" ("z_Customer_Master_File_____ARCUST") -- Inferred FK (Codes: OTCUST->ARCUST.CCUST, Suffix: 'CUST'),
    FOREIGN KEY ("z_Sales_Order_Tracking_File_____ORDTRCK") REFERENCES "z_Sales_Order_Header_File_____OEOPNORD" ("z_Sales_Order_Header_File_____OEOPNORD") -- Inferred FK (Codes: OTORDR->OEOPNORD.OOORDR, Suffix: 'ORDR')
);

-- Table: "z_Order_Tracking_History_File_____ORDTRHST" (Code: ORDTRHST)
CREATE TABLE "z_Order_Tracking_History_File_____ORDTRHST" (
    "z_Order_Tracking_History_File_____ORDTRHST_ID" INT,
    "z_Order_Tracking_History_File_____ORDTRHST" VARCHAR(255),
    "z_Order_Tracking_History_File_____ORDTRHST" VARCHAR(255),
    "z_Order_Tracking_History_File_____ORDTRHST" VARCHAR(255),
    PRIMARY KEY ("z_Order_Tracking_History_File_____ORDTRHST_ID") -- Generic PK (NEEDS VALIDATION!)
);

-- Table: "z_P/O_Change_Log_____POCHGLOG" (Code: POCHGLOG)
CREATE TABLE "z_P/O_Change_Log_____POCHGLOG" (
    "z_P/O_Change_Log_____POCHGLOG_ID" INT,
    "z_P/O_Change_Log_____POCHGLOG" VARCHAR(255),
    PRIMARY KEY ("z_P/O_Change_Log_____POCHGLOG_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_P/O_Change_Log_____POCHGLOG") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: LGDIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST')
);

-- Table: "z_P/O_Complete_Summary_File_____POCMPSMO" (Code: POCMPSMO)
CREATE TABLE "z_P/O_Complete_Summary_File_____POCMPSMO" (
    "z_P/O_Complete_Summary_File_____POCMPSMO_ID" INT,
    "z_P/O_Complete_Summary_File_____POCMPSMO" VARCHAR(255),
    "z_P/O_Complete_Summary_File_____POCMPSMO" VARCHAR(255),
    PRIMARY KEY ("z_P/O_Complete_Summary_File_____POCMPSMO_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_P/O_Complete_Summary_File_____POCMPSMO") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: P4DIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST')
);

-- Table: "z_P/O_Detail_File_____PODETAIL" (Code: PODETAIL)
CREATE TABLE "z_P/O_Detail_File_____PODETAIL" (
    "z_P/O_Detail_File_____PODETAIL_ID" INT,
    "z_P/O_Detail_File_____PODETAIL" VARCHAR(255),
    "z_P/O_Detail_File_____PODETAIL" VARCHAR(255),
    "z_P/O_Detail_File_____PODETAIL" VARCHAR(255),
    "z_P/O_Detail_File_____PODETAIL" VARCHAR(255),
    "z_P/O_Detail_File_____PODETAIL" VARCHAR(255),
    "z_P/O_Detail_File_____PODETAIL" VARCHAR(255),
    "z_P/O_Detail_File_____PODETAIL" VARCHAR(255),
    PRIMARY KEY ("z_P/O_Detail_File_____PODETAIL_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_P/O_Detail_File_____PODETAIL") REFERENCES "z_Customer_Master_File_____ARCUST" ("z_Customer_Master_File_____ARCUST") -- Inferred FK (Codes: BDCUST->ARCUST.CCUST, Suffix: 'CUST'),
    FOREIGN KEY ("z_P/O_Detail_File_____PODETAIL") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: BDDIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST')
);

-- Table: "z_P/O_Header_File_____POHEADER" (Code: POHEADER)
CREATE TABLE "z_P/O_Header_File_____POHEADER" (
    "z_P/O_Header_File_____POHEADER" INT,
    "z_P/O_Header_File_____POHEADER" VARCHAR(255),
    "z_P/O_Header_File_____POHEADER" VARCHAR(255),
    PRIMARY KEY ("z_P/O_Header_File_____POHEADER"),
    FOREIGN KEY ("z_P/O_Header_File_____POHEADER") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: BHDIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST')
);

-- Table: "z_P/O_Header_Before_Batch_Update_____POHEADERBH" (Code: POHEADERBH)
CREATE TABLE "z_P/O_Header_Before_Batch_Update_____POHEADERBH" (
    "z_P/O_Header_Before_Batch_Update_____POHEADERBH" INT,
    "z_P/O_Header_Before_Batch_Update_____POHEADERBH" VARCHAR(255),
    "z_P/O_Header_Before_Batch_Update_____POHEADERBH" VARCHAR(255),
    PRIMARY KEY ("z_P/O_Header_Before_Batch_Update_____POHEADERBH"),
    FOREIGN KEY ("z_P/O_Header_Before_Batch_Update_____POHEADERBH") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: BHDIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST')
);

-- Table: "z_P/O_Posting_File_____POSTPRD" (Code: POSTPRD)
CREATE TABLE "z_P/O_Posting_File_____POSTPRD" (
    "z_P/O_Posting_File_____POSTPRD_ID" INT,
    "z_P/O_Posting_File_____POSTPRD" VARCHAR(255),
    PRIMARY KEY ("z_P/O_Posting_File_____POSTPRD_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_P/O_Posting_File_____POSTPRD") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: PPDIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST')
);

-- Table: "z_Purchase_Order_Tracking_File_____POTRCK" (Code: POTRCK)
CREATE TABLE "z_Purchase_Order_Tracking_File_____POTRCK" (
    "z_Purchase_Order_Tracking_File_____POTRCK_ID" INT,
    "z_Purchase_Order_Tracking_File_____POTRCK" VARCHAR(255),
    "z_Purchase_Order_Tracking_File_____POTRCK" VARCHAR(255),
    "z_Purchase_Order_Tracking_File_____POTRCK" VARCHAR(255),
    PRIMARY KEY ("z_Purchase_Order_Tracking_File_____POTRCK_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_Purchase_Order_Tracking_File_____POTRCK") REFERENCES "z_Customer_Master_File_____ARCUST" ("z_Customer_Master_File_____ARCUST") -- Inferred FK (Codes: PTCUST->ARCUST.CCUST, Suffix: 'CUST')
);

-- Table: "z_P/O_Tracking_History_File_____POTRKHST" (Code: POTRKHST)
CREATE TABLE "z_P/O_Tracking_History_File_____POTRKHST" (
    "z_P/O_Tracking_History_File_____POTRKHST_ID" INT,
    "z_P/O_Tracking_History_File_____POTRKHST" VARCHAR(255),
    "z_P/O_Tracking_History_File_____POTRKHST" VARCHAR(255),
    "z_P/O_Tracking_History_File_____POTRKHST" VARCHAR(255),
    PRIMARY KEY ("z_P/O_Tracking_History_File_____POTRKHST_ID") -- Generic PK (NEEDS VALIDATION!)
);

-- Table: "z_Processing_History_Charges_File_____PRCHCHRG" (Code: PRCHCHRG)
CREATE TABLE "z_Processing_History_Charges_File_____PRCHCHRG" (
    "z_Processing_History_Charges_File_____PRCHCHRG_ID" INT,
    "z_Processing_History_Charges_File_____PRCHCHRG" VARCHAR(255),
    "z_Processing_History_Charges_File_____PRCHCHRG" VARCHAR(255),
    PRIMARY KEY ("z_Processing_History_Charges_File_____PRCHCHRG_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_Processing_History_Charges_File_____PRCHCHRG") REFERENCES "z_Sales_Order_Header_File_____OEOPNORD" ("z_Sales_Order_Header_File_____OEOPNORD") -- Inferred FK (Codes: PJORDR->OEOPNORD.OOORDR, Suffix: 'ORDR')
);

-- Table: "z_Processing_Charges_File_____PRCTCHRG" (Code: PRCTCHRG)
CREATE TABLE "z_Processing_Charges_File_____PRCTCHRG" (
    "z_Processing_Charges_File_____PRCTCHRG_ID" INT,
    "z_Processing_Charges_File_____PRCTCHRG" VARCHAR(255),
    "z_Processing_Charges_File_____PRCTCHRG" VARCHAR(255),
    PRIMARY KEY ("z_Processing_Charges_File_____PRCTCHRG_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_Processing_Charges_File_____PRCTCHRG") REFERENCES "z_Sales_Order_Header_File_____OEOPNORD" ("z_Sales_Order_Header_File_____OEOPNORD") -- Inferred FK (Codes: PKORDR->OEOPNORD.OOORDR, Suffix: 'ORDR')
);

-- Table: "z_Processing_Dimensions_File_____PRCTDIM" (Code: PRCTDIM)
CREATE TABLE "z_Processing_Dimensions_File_____PRCTDIM" (
    "z_Processing_Dimensions_File_____PRCTDIM_ID" INT,
    "z_Processing_Dimensions_File_____PRCTDIM" VARCHAR(255),
    "z_Processing_Dimensions_File_____PRCTDIM" VARCHAR(255),
    "z_Processing_Dimensions_File_____PRCTDIM" VARCHAR(255),
    PRIMARY KEY ("z_Processing_Dimensions_File_____PRCTDIM_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_Processing_Dimensions_File_____PRCTDIM") REFERENCES "z_Sales_Order_Header_File_____OEOPNORD" ("z_Sales_Order_Header_File_____OEOPNORD") -- Inferred FK (Codes: PDORDR->OEOPNORD.OOORDR, Suffix: 'ORDR')
);

-- Table: "z_Receiving_Costing_File_____RCPTCOST" (Code: RCPTCOST)
CREATE TABLE "z_Receiving_Costing_File_____RCPTCOST" (
    "z_Receiving_Costing_File_____RCPTCOST_ID" INT,
    "z_Receiving_Costing_File_____RCPTCOST" VARCHAR(255),
    PRIMARY KEY ("z_Receiving_Costing_File_____RCPTCOST_ID") -- Generic PK (NEEDS VALIDATION!)
);

-- Table: "z_Receiving_History_File_____RCPTHIST" (Code: RCPTHIST)
CREATE TABLE "z_Receiving_History_File_____RCPTHIST" (
    "z_Receiving_History_File_____RCPTHIST_ID" INT,
    "z_Receiving_History_File_____RCPTHIST" VARCHAR(255),
    "z_Receiving_History_File_____RCPTHIST" VARCHAR(255),
    "z_Receiving_History_File_____RCPTHIST" VARCHAR(255),
    PRIMARY KEY ("z_Receiving_History_File_____RCPTHIST_ID") -- Generic PK (NEEDS VALIDATION!)
);

-- Table: "z_Restock_File_____RESTOCK" (Code: RESTOCK)
CREATE TABLE "z_Restock_File_____RESTOCK" (
    "z_Restock_File_____RESTOCK_ID" INT,
    "z_Restock_File_____RESTOCK" VARCHAR(255),
    PRIMARY KEY ("z_Restock_File_____RESTOCK_ID") -- Generic PK (NEEDS VALIDATION!)
);

-- Table: "z_Sales_Analysis_Daily_Update_____SADAILY" (Code: SADAILY)
CREATE TABLE "z_Sales_Analysis_Daily_Update_____SADAILY" (
    "z_Sales_Analysis_Daily_Update_____SADAILY_ID" INT,
    "z_Sales_Analysis_Daily_Update_____SADAILY" VARCHAR(255),
    "z_Sales_Analysis_Daily_Update_____SADAILY" VARCHAR(255),
    "z_Sales_Analysis_Daily_Update_____SADAILY" VARCHAR(255),
    PRIMARY KEY ("z_Sales_Analysis_Daily_Update_____SADAILY_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_Sales_Analysis_Daily_Update_____SADAILY") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: AYDIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST')
);

-- Table: "z_Sales_Analysis_Month_To_Date_____SAMTHLY" (Code: SAMTHLY)
CREATE TABLE "z_Sales_Analysis_Month_To_Date_____SAMTHLY" (
    "z_Sales_Analysis_Month_To_Date_____SAMTHLY_ID" INT,
    "z_Sales_Analysis_Month_To_Date_____SAMTHLY" VARCHAR(255),
    "z_Sales_Analysis_Month_To_Date_____SAMTHLY" VARCHAR(255),
    "z_Sales_Analysis_Month_To_Date_____SAMTHLY" VARCHAR(255),
    PRIMARY KEY ("z_Sales_Analysis_Month_To_Date_____SAMTHLY_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_Sales_Analysis_Month_To_Date_____SAMTHLY") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: AMDIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST')
);

-- Table: "z_Ship_To_Address_File_____SHIPADR" (Code: SHIPADR)
CREATE TABLE "z_Ship_To_Address_File_____SHIPADR" (
    "z_Ship_To_Address_File_____SHIPADR_ID" INT,
    "z_Ship_To_Address_File_____SHIPADR" VARCHAR(255),
    "z_Ship_To_Address_File_____SHIPADR" VARCHAR(255),
    "z_Ship_To_Address_File_____SHIPADR" VARCHAR(255),
    "z_Ship_To_Address_File_____SHIPADR" VARCHAR(255),
    "z_Ship_To_Address_File_____SHIPADR" VARCHAR(255),
    "z_Ship_To_Address_File_____SHIPADR" VARCHAR(255),
    "z_Ship_To_Address_File_____SHIPADR" VARCHAR(255),
    "z_Ship_To_Address_File_____SHIPADR" VARCHAR(255),
    "z_Ship_To_Address_File_____SHIPADR" TIMESTAMP,
    PRIMARY KEY ("z_Ship_To_Address_File_____SHIPADR_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_Ship_To_Address_File_____SHIPADR") REFERENCES "z_Customer_Master_File_____ARCUST" ("z_Customer_Master_File_____ARCUST") -- Inferred FK (Codes: SACUST->ARCUST.CCUST, Suffix: 'CUST')
);

-- Table: "z_Backup_of_Shipping_File_____SHIPBCKG" (Code: SHIPBCKG)
CREATE TABLE "z_Backup_of_Shipping_File_____SHIPBCKG" (
    "z_Backup_of_Shipping_File_____SHIPBCKG_ID" INT,
    "z_Backup_of_Shipping_File_____SHIPBCKG" VARCHAR(255),
    PRIMARY KEY ("z_Backup_of_Shipping_File_____SHIPBCKG_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_Backup_of_Shipping_File_____SHIPBCKG") REFERENCES "z_Customer_Master_File_____ARCUST" ("z_Customer_Master_File_____ARCUST") -- Inferred FK (Codes: SBCUST->ARCUST.CCUST, Suffix: 'CUST')
);

-- Table: "z_Shipping_Dispatch_File_____SHIPDISP" (Code: SHIPDISP)
CREATE TABLE "z_Shipping_Dispatch_File_____SHIPDISP" (
    "z_Shipping_Dispatch_File_____SHIPDISP_ID" INT,
    "z_Shipping_Dispatch_File_____SHIPDISP" VARCHAR(255),
    "z_Shipping_Dispatch_File_____SHIPDISP" VARCHAR(255),
    PRIMARY KEY ("z_Shipping_Dispatch_File_____SHIPDISP_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_Shipping_Dispatch_File_____SHIPDISP") REFERENCES "z_Customer_Master_File_____ARCUST" ("z_Customer_Master_File_____ARCUST") -- Inferred FK (Codes: SPCUST->ARCUST.CCUST, Suffix: 'CUST'),
    FOREIGN KEY ("z_Shipping_Dispatch_File_____SHIPDISP") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: SPDIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST')
);

-- Table: "z_Shipping_File_____SHIPMAST" (Code: SHIPMAST)
CREATE TABLE "z_Shipping_File_____SHIPMAST" (
    "z_Shipping_File_____SHIPMAST_ID" INT,
    "z_Shipping_File_____SHIPMAST" VARCHAR(255),
    "z_Shipping_File_____SHIPMAST" VARCHAR(255),
    "z_Shipping_File_____SHIPMAST" VARCHAR(255),
    "z_Shipping_File_____SHIPMAST" VARCHAR(255),
    "z_Shipping_File_____SHIPMAST" VARCHAR(255),
    "z_Shipping_File_____SHIPMAST" VARCHAR(255),
    "z_Shipping_File_____SHIPMAST" VARCHAR(255),
    "z_Shipping_File_____SHIPMAST" VARCHAR(255),
    PRIMARY KEY ("z_Shipping_File_____SHIPMAST_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_Shipping_File_____SHIPMAST") REFERENCES "z_Customer_Master_File_____ARCUST" ("z_Customer_Master_File_____ARCUST") -- Inferred FK (Codes: SHCUST->ARCUST.CCUST, Suffix: 'CUST'),
    FOREIGN KEY ("z_Shipping_File_____SHIPMAST") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: SHDIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST')
);

-- Table: "z_Shipping_Instruction_File_____SHPINST" (Code: SHPINST)
CREATE TABLE "z_Shipping_Instruction_File_____SHPINST" (
    "z_Shipping_Instruction_File_____SHPINST_ID" INT,
    "z_Shipping_Instruction_File_____SHPINST" VARCHAR(255),
    PRIMARY KEY ("z_Shipping_Instruction_File_____SHPINST_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_Shipping_Instruction_File_____SHPINST") REFERENCES "z_Customer_Master_File_____ARCUST" ("z_Customer_Master_File_____ARCUST") -- Inferred FK (Codes: CICUST->ARCUST.CCUST, Suffix: 'CUST')
);

-- Table: "z_Shipping_Summary_File_____SHSUMM" (Code: SHSUMM)
CREATE TABLE "z_Shipping_Summary_File_____SHSUMM" (
    "z_Shipping_Summary_File_____SHSUMM_ID" INT,
    "z_Shipping_Summary_File_____SHSUMM" VARCHAR(255),
    "z_Shipping_Summary_File_____SHSUMM" VARCHAR(255),
    "z_Shipping_Summary_File_____SHSUMM" VARCHAR(255),
    "z_Shipping_Summary_File_____SHSUMM" VARCHAR(255),
    PRIMARY KEY ("z_Shipping_Summary_File_____SHSUMM_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_Shipping_Summary_File_____SHSUMM") REFERENCES "z_Customer_Master_File_____ARCUST" ("z_Customer_Master_File_____ARCUST") -- Inferred FK (Codes: SUCUST->ARCUST.CCUST, Suffix: 'CUST'),
    FOREIGN KEY ("z_Shipping_Summary_File_____SHSUMM") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: SUDIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST')
);

-- Table: "z_Salesman_Commission_Rate_File_____SLMNRCAP" (Code: SLMNRCAP)
CREATE TABLE "z_Salesman_Commission_Rate_File_____SLMNRCAP" (
    "z_Salesman_Commission_Rate_File_____SLMNRCAP" VARCHAR(255),
    "z_Salesman_Commission_Rate_File_____SLMNRCAP" VARCHAR(255),
    "z_Salesman_Commission_Rate_File_____SLMNRCAP" INT,
    PRIMARY KEY ("z_Salesman_Commission_Rate_File_____SLMNRCAP")
);

-- Table: "z_Salesman_Summary_File_____SLMNSUM" (Code: SLMNSUM)
CREATE TABLE "z_Salesman_Summary_File_____SLMNSUM" (
    "z_Salesman_Summary_File_____SLMNSUM_ID" INT,
    "z_Salesman_Summary_File_____SLMNSUM" VARCHAR(255),
    "z_Salesman_Summary_File_____SLMNSUM" VARCHAR(255),
    PRIMARY KEY ("z_Salesman_Summary_File_____SLMNSUM_ID") -- Generic PK (NEEDS VALIDATION!)
);

-- Table: "z_Sales_Analysis_File_Mth_____SLSASMT" (Code: SLSASMT)
CREATE TABLE "z_Sales_Analysis_File_Mth_____SLSASMT" (
    "z_Sales_Analysis_File_Mth_____SLSASMT_ID" INT,
    "z_Sales_Analysis_File_Mth_____SLSASMT" VARCHAR(255),
    PRIMARY KEY ("z_Sales_Analysis_File_Mth_____SLSASMT_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_Sales_Analysis_File_Mth_____SLSASMT") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: MODIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST')
);

-- Table: "z_Sales_Analysis_File_Year_____SLSASYT" (Code: SLSASYT)
CREATE TABLE "z_Sales_Analysis_File_Year_____SLSASYT" (
    "z_Sales_Analysis_File_Year_____SLSASYT_ID" INT,
    "z_Sales_Analysis_File_Year_____SLSASYT" VARCHAR(255),
    PRIMARY KEY ("z_Sales_Analysis_File_Year_____SLSASYT_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_Sales_Analysis_File_Year_____SLSASYT") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: YODIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST')
);

-- Table: "z_Sales_Discount_File_____SLSDSCOV" (Code: SLSDSCOV)
CREATE TABLE "z_Sales_Discount_File_____SLSDSCOV" (
    "z_Sales_Discount_File_____SLSDSCOV_ID" INT,
    "z_Sales_Discount_File_____SLSDSCOV" VARCHAR(255),
    "z_Sales_Discount_File_____SLSDSCOV" VARCHAR(255),
    PRIMARY KEY ("z_Sales_Discount_File_____SLSDSCOV_ID") -- Generic PK (NEEDS VALIDATION!)
);

-- Table: "z_P/O_Split_Detail_File_____SPDETAIL" (Code: SPDETAIL)
CREATE TABLE "z_P/O_Split_Detail_File_____SPDETAIL" (
    "z_P/O_Split_Detail_File_____SPDETAIL_ID" INT,
    "z_P/O_Split_Detail_File_____SPDETAIL" VARCHAR(255),
    PRIMARY KEY ("z_P/O_Split_Detail_File_____SPDETAIL_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_P/O_Split_Detail_File_____SPDETAIL") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: BTDIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST')
);

-- Table: "z_P/O_Split_Header_File_____SPHEADER" (Code: SPHEADER)
CREATE TABLE "z_P/O_Split_Header_File_____SPHEADER" (
    "z_P/O_Split_Header_File_____SPHEADER" INT,
    "z_P/O_Split_Header_File_____SPHEADER" VARCHAR(255),
    "z_P/O_Split_Header_File_____SPHEADER" VARCHAR(255),
    "z_P/O_Split_Header_File_____SPHEADER" VARCHAR(255),
    PRIMARY KEY ("z_P/O_Split_Header_File_____SPHEADER"),
    FOREIGN KEY ("z_P/O_Split_Header_File_____SPHEADER") REFERENCES "z_General_Ledger_Master_File_____GLMAST" ("z_General_Ledger_Master_File_____GLMAST_ID") -- Inferred FK (Codes: BSDIST->GLMAST._GLMAST_GENERIC_PK_, Suffix: 'DIST')
);

-- Table: "z_Split_P/O_Tracking_File_____SPOTRCK" (Code: SPOTRCK)
CREATE TABLE "z_Split_P/O_Tracking_File_____SPOTRCK" (
    "z_Split_P/O_Tracking_File_____SPOTRCK_ID" INT,
    "z_Split_P/O_Tracking_File_____SPOTRCK" VARCHAR(255),
    "z_Split_P/O_Tracking_File_____SPOTRCK" VARCHAR(255),
    PRIMARY KEY ("z_Split_P/O_Tracking_File_____SPOTRCK_ID") -- Generic PK (NEEDS VALIDATION!),
    FOREIGN KEY ("z_Split_P/O_Tracking_File_____SPOTRCK") REFERENCES "z_Sales_Order_Header_File_____OEOPNORD" ("z_Sales_Order_Header_File_____OEOPNORD") -- Inferred FK (Codes: SPORDR->OEOPNORD.OOORDR, Suffix: 'ORDR')
);

-- Table: "z_Vendor_Ship_From_File_____VENDSHIP" (Code: VENDSHIP)
CREATE TABLE "z_Vendor_Ship_From_File_____VENDSHIP" (
    "z_Vendor_Ship_From_File_____VENDSHIP_ID" INT,
    "z_Vendor_Ship_From_File_____VENDSHIP" VARCHAR(255),
    PRIMARY KEY ("z_Vendor_Ship_From_File_____VENDSHIP_ID") -- Generic PK (NEEDS VALIDATION!)
);

-- Table: "z_Vendor_Request_Header_File_____VNDREQHD" (Code: VNDREQHD)
CREATE TABLE "z_Vendor_Request_Header_File_____VNDREQHD" (
    "z_Vendor_Request_Header_File_____VNDREQHD_ID" INT,
    "z_Vendor_Request_Header_File_____VNDREQHD" VARCHAR(255),
    PRIMARY KEY ("z_Vendor_Request_Header_File_____VNDREQHD_ID") -- Generic PK (NEEDS VALIDATION!)
);

-- Table: "z_OE895_Work_File_____WFOE895" (Code: WFOE895)
CREATE TABLE "z_OE895_Work_File_____WFOE895" (
    "z_OE895_Work_File_____WFOE895_ID" INT,
    "z_OE895_Work_File_____WFOE895" VARCHAR(255),
    "z_OE895_Work_File_____WFOE895" VARCHAR(255),
    PRIMARY KEY ("z_OE895_Work_File_____WFOE895_ID") -- Generic PK (NEEDS VALIDATION!)
);

-- Table: "z_P/O_History_Detail_File_____POHSTDET" (Code: _POHSTDET)
CREATE TABLE "z_P/O_History_Detail_File_____POHSTDET" (
    "z_P/O_History_Detail_File_____POHSTDET_ID" INT,
    "z_P/O_History_Detail_File_____POHSTDET" VARCHAR(255),
    "z_P/O_History_Detail_File_____POHSTDET" VARCHAR(255),
    "z_P/O_History_Detail_File_____POHSTDET" VARCHAR(255),
    PRIMARY KEY ("z_P/O_History_Detail_File_____POHSTDET_ID") -- Generic PK (NEEDS VALIDATION!)
);