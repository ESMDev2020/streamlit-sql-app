

# -*- coding: utf-8 -*-
"""
MIGRATION SCRIPT WITH MULTITHREADING SUPPORT
VERSION: 1.18
LAST UPDATED: 2024-03-14
CHANGES:
    - Added error beeping for failed tables
    - Added retry mechanism (3 attempts)
    - Added smart synchronization for mismatched tables
    - Added version control
DESCRIPTION:
    This script migrates data from AS400 to SQL Server using multiple threads.
    It specifically:
    1. Reads table information from SQL Server
    2. For each table:
       - Gets initial row counts from both databases
       - Truncates the destination table
       - Copies data from AS400 to SQL Server
       - Verifies final row counts match
    3. Generates a detailed report of the migration process
"""
# --------------------------------------------
# IMPORTS
# --------------------------------------------
import pyodbc  # For database connections
from tqdm import tqdm  # For progress bars
import sys  # For system operations
import traceback  # For error tracing
from decimal import Decimal  # For decimal number handling
from datetime import datetime  # For timing operations
import threading  # For multi-threading support
from queue import Queue  # For thread-safe queue operations
import pandas as pd  # For data manipulation
import os  # For file operations
import winsound  # For Windows beep sound
import time  # For retry delays
import threading
import re   # For regular expressions
from concurrent.futures import ThreadPoolExecutor

print_lock = threading.Lock()
output_lock = threading.Lock()

# --------------------------------------------
# CONSTANTS
# --------------------------------------------
# AS400 connection settings
myCon_strAS400Dsn = "METALNET"  # AS400 DSN name
myCon_strAS400Uid = "ESAAVEDR"  # AS400 user ID
myCon_strAS400Pwd = "ESM25"  # AS400 password
myCon_intAS400Timeout = 30  # AS400 connection timeout in seconds
# SQL Server connection settings
myCon_strSQLDriver = "{ODBC Driver 17 for SQL Server}"  # SQL Server driver
#myCon_strSQLServer = "database-3.c67ymu6q22o1.us-east-1.rds.amazonaws.com,1433"  # SQL Server address
myCon_strSQLServer = "database-3.c67ymu6q22o1.us-east-1.rds.amazonaws.com,1433"  # SQL Server address
myCon_strSQLDb = "SigmaTB"  # SQL Server database name
myCon_strSQLUid = "admin"  # SQL Server user ID
myCon_strSQLPwd = "Er1c41234$"  # SQL Server password
# Schema settings
myCon_strAS400Library = "MW4FILE"  # AS400 library name
myCon_strSQLSchema = "mrs"  # SQL Server schema name
# Operation settings
myCon_boolClearTargetTables = False  # Flag to clear target tables
myCon_intBatchSize = 1000  # Batch size for data processing. Higher values improve performance but require more memory.
                            # Consider system resources and database limits when adjusting this value.
                            # Current value: 50,000 rows per batch
myCon_strLogFilePath = "failed_inserts.log"  # Path for error logging
myCon_intMaxThreads = 1  # Set to 1 for debugging purposes
myCon_strReportPath = "migration_report.csv"  # Path for migration report
myCon_intMaxRetries = 3  # Maximum number of retries for failed tables
myCon_intRetryDelay = 5  # Delay between retries in seconds
# --------------------------------------------
# FUNCTION DEFINITIONS
# --------------------------------------------
def fun_connect_as400():
    """
    Establishes connection to AS400 database
    Returns:
        pyodbc.Connection: AS400 database connection
    """
    #print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Starting fun_connect_as400")
    # Variable declarations
    my_var_strConnStr = ""  # Will store connection string
    my_var_objConn = None  # Will store connection object
    try:
        # Build connection string
        my_var_strConnStr = f"DSN={myCon_strAS400Dsn};UID={myCon_strAS400Uid};PWD={myCon_strAS400Pwd};Timeout={myCon_intAS400Timeout}"
        
        #print(f"Connecting to AS400: {my_var_strConnStr}")
        # Create connection
        my_var_objConn = pyodbc.connect(my_var_strConnStr, autocommit=False)
        return my_var_objConn
    except Exception as my_var_errException:
        with print_lock:(f"Error connecting to AS400: {str(my_var_errException)}")
        return None
def fun_connect_sql_server():
    """
    Establishes connection to SQL Server database
    Returns:
        pyodbc.Connection: SQL Server database connection
    """
    #with print_lock:print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Starting fun_connect_sql_server")
    # Variable declarations
    my_var_strConnStr = ""  # Will store connection string
    my_var_objConn = None  # Will store connection object
    try:
        # Build connection string
        my_var_strConnStr = (
            f"DRIVER={myCon_strSQLDriver};SERVER={myCon_strSQLServer};DATABASE={myCon_strSQLDb};UID={myCon_strSQLUid};PWD={myCon_strSQLPwd};"
            "Encrypt=yes;TrustServerCertificate=yes;Connection Timeout=30;"
        )
        
        #print(f"Connecting to SQL Server: {my_var_strConnStr}")
        # Create connection
        my_var_objConn = pyodbc.connect(my_var_strConnStr, autocommit=False)
        return my_var_objConn
    except Exception as my_var_errException:
        with print_lock:(f"Error connecting to SQL Server: {str(my_var_errException)}")
        return None
def fun_sanitize_table_name(my_var_strName):
    """
    Sanitizes table names by replacing spaces with underscores
    Args:
        my_var_strName: Table name to sanitize
    Returns:
        str: Sanitized table name
    """
    return my_var_strName.replace(" ", "_")
def fun_get_table_rowcount(my_var_objCursor, my_var_strSchema, my_var_strTable):
    """
    Gets the row count for a specific table
    Args:
        my_var_objCursor: Database cursor
        my_var_strSchema: Schema name
        my_var_strTable: Table name
    Returns:
        int: Row count or -1 if error
    """
    try:
        my_var_strSanitizedTable = fun_sanitize_table_name(my_var_strTable)
        my_var_strSQL = f"SELECT COUNT(*) FROM [{my_var_strSchema}].[{my_var_strSanitizedTable}]"
        my_var_objCursor.execute(my_var_strSQL)
        return my_var_objCursor.fetchone()[0]
    except Exception as e:
        with print_lock:(f"Error getting row count: {str(e)}")
        return -1
def fun_get_table_description(my_var_objCursor, my_var_strSchema, my_var_strTable):
    """
    Gets the description of a table from AS400
    Args:
        my_var_objCursor: AS400 cursor
        my_var_strSchema: Schema name
        my_var_strTable: Table name
    Returns:
        str: Table description
    """
    try:
        my_var_strSanitizedTable = my_var_strTable.replace(" ", "_")
        my_var_objCursor.execute(
            f"SELECT TABLE_TEXT FROM QSYS2.SYSTABLES WHERE TABLE_SCHEMA = '{my_var_strSchema}' AND TABLE_NAME = '{my_var_strSanitizedTable}'"
        )
        my_var_objRow = my_var_objCursor.fetchone()
        if my_var_objRow:
            return my_var_objRow[0].strip().replace("'", "_")
        else:
            return my_var_strTable
    except Exception as e:
        with print_lock:(f"Error getting table description: {str(e)}")
        return my_var_strTable
def fun_get_column_metadata(my_var_objCursor, my_var_strSchema, my_var_strTable):
    """
    Gets column metadata from AS400 table
    Args:
        my_var_objCursor: AS400 cursor
        my_var_strSchema: Schema name
        my_var_strTable: Table name
    Returns:
        list: List of (column_name, column_description) tuples
    """
    try:
        my_var_strSanitizedTable = my_var_strTable.replace(" ", "_")
        my_var_objCursor.execute(
            f"SELECT COLUMN_NAME, COLUMN_TEXT FROM QSYS2.SYSCOLUMNS WHERE TABLE_SCHEMA = '{my_var_strSchema}' AND TABLE_NAME = '{my_var_strSanitizedTable}'"
        )
        return [
            (col[0].strip(), (col[1] or "").strip().replace(" ", "_").replace("'", "_"))
            for col in my_var_objCursor.fetchall()
        ]
    except Exception as e:
        with print_lock:(f"Error getting column metadata: {str(e)}")
        return []
    
def fun_get_z_tables_from_sqlserver(my_var_objCursor, my_var_strSchema):
    """
    Gets list of z-prefixed tables from SQL Server
    Args:
        my_var_objCursor: SQL Server cursor
        my_var_strSchema: Schema name
    Returns:
        list: List of table names
    """
    try:
        my_var_objCursor.execute(fr"SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = '{my_var_strSchema}' AND TABLE_NAME LIKE 'z\_%' ESCAPE '\'")
        return [fun_sanitize_table_name(row[0]) for row in my_var_objCursor.fetchall()]
    except Exception as e:
        with print_lock:(f"Error getting tables from SQL Server: {str(e)}")
        return []
def fun_compare_samples(my_var_tplAS400Sample, my_var_tplSQLSample):
    """
    Compares sample data from AS400 and SQL Server
    Args:
        my_var_tplAS400Sample: AS400 sample data tuple
        my_var_tplSQLSample: SQL Server sample data tuple
    Returns:
        bool: True if samples match, False otherwise
    """
    with print_lock:(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Starting fun_compare_samples")
    # Variable declarations
    if len(my_var_tplAS400Sample) != len(my_var_tplSQLSample):
        with print_lock:(f"Length mismatch: AS400={len(my_var_tplAS400Sample)}, SQL={len(my_var_tplSQLSample)}")
        return False
    for my_var_intIdx, (my_var_valAS400, my_var_valSQL) in enumerate(zip(my_var_tplAS400Sample, my_var_tplSQLSample)):
        if my_var_valAS400 != my_var_valSQL:
            with print_lock:(f"Value mismatch at index {my_var_intIdx}:")
            with print_lock:(f"  AS400: {my_var_valAS400} ({type(my_var_valAS400)})")
            with print_lock:(f"  SQL:   {my_var_valSQL} ({type(my_var_valSQL)})")
            return False
            
    return True
def fun_verify_table_migration(my_var_objAS400Cursor, my_var_objSQLCursor, my_var_strAS400Table, my_var_strSQLTable):
    """
    Verifies the migration of a single table by comparing row counts and sample data
    Args:
        my_var_objAS400Cursor: AS400 cursor
        my_var_objSQLCursor: SQL Server cursor
        my_var_strAS400Table: AS400 table name
        my_var_strSQLTable: SQL Server table name
    Returns:
        tuple: (bool success, str message, int as400_count, int sql_count)
    """
    try:
        my_var_strSanitizedAS400Table = fun_sanitize_table_name(my_var_strAS400Table)
        my_var_strSanitizedSQLTable = fun_sanitize_table_name(my_var_strSQLTable)
        
        my_var_strQualifiedSource = f'{myCon_strAS400Library}.{my_var_strSanitizedAS400Table}'
        my_var_objAS400Cursor.execute(f"SELECT COUNT(*) FROM {my_var_strQualifiedSource}")
        my_var_intAS400Count = my_var_objAS400Cursor.fetchone()[0]
        
        my_var_intSQLCount = fun_get_table_rowcount(my_var_objSQLCursor, myCon_strSQLSchema, my_var_strSanitizedSQLTable)
        
        # Get column names from both databases
        my_var_objAS400Cursor.execute(f"SELECT COLUMN_NAME FROM QSYS2.SYSCOLUMNS WHERE TABLE_SCHEMA = '{myCon_strAS400Library}' AND TABLE_NAME = '{my_var_strSanitizedAS400Table}'")
        my_var_lstAS400Columns = [col[0] for col in my_var_objAS400Cursor.fetchall()]
        
        my_var_objSQLCursor.execute(f"""
            SELECT COLUMN_NAME 
            FROM INFORMATION_SCHEMA.COLUMNS 
            WHERE TABLE_SCHEMA = '{myCon_strSQLSchema}' 
            AND TABLE_NAME = '{my_var_strSanitizedSQLTable}'
        """)
        my_var_lstSQLColumns = [col[0] for col in my_var_objSQLCursor.fetchall()]
        
        # Create mapping of AS400 to SQL Server column names
        my_var_dictColumnMap = {}
        for my_var_strSQLCol in my_var_lstSQLColumns:
            if "_____" in my_var_strSQLCol:
                my_var_strAS400Col = my_var_strSQLCol.split("_____")[-1]
                my_var_dictColumnMap[my_var_strAS400Col] = my_var_strSQLCol
        
        # Get sample data for comparison
        my_var_objAS400Cursor.execute(f"SELECT * FROM {my_var_strQualifiedSource} FETCH FIRST ROW ONLY")
        my_var_tplAS400Sample = my_var_objAS400Cursor.fetchone()
        
        my_var_objSQLCursor.execute(f"SELECT TOP 1 * FROM [{myCon_strSQLSchema}].[{my_var_strSanitizedSQLTable}]")
        my_var_tplSQLSample = my_var_objSQLCursor.fetchone()
        
        if my_var_tplAS400Sample and my_var_tplSQLSample:
            if my_var_tplAS400Sample == my_var_tplSQLSample:
                return True, "Verification successful", my_var_intAS400Count, my_var_intSQLCount
            else:
                return False, "Sample data mismatch", my_var_intAS400Count, my_var_intSQLCount
        else:
            return False, "Could not get sample data", my_var_intAS400Count, my_var_intSQLCount
            
    except Exception as e:
        return False, f"Verification error: {str(e)}", -1, -1
def fun_verify_all_tables(my_var_lstTablesToCopy):
    """
    Verifies all tables after migration is complete
    Args:
        my_var_lstTablesToCopy: List of (as400_table, sql_table) tuples
    Returns:
        tuple: (bool all_success, list failed_tables)
    """
    with print_lock:(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Starting fun_verify_all_tables")
    # Variable declarations
    my_var_objAS400Conn = None  # Will store AS400 connection
    my_var_objSQLConn = None  # Will store SQL Server connection
    my_var_objAS400Cursor = None  # Will store AS400 cursor
    my_var_objSQLCursor = None  # Will store SQL Server cursor
    my_var_lstFailedTables = []  # Will store list of failed tables
    my_var_boolAllSuccess = True  # Will store overall success status
    my_var_intTotalAS400Rows = 0  # Will store total AS400 rows
    my_var_intTotalSQLRows = 0  # Will store total SQL Server rows
    try:
        # Create connections
        my_var_objAS400Conn = fun_connect_as400()
        my_var_objSQLConn = fun_connect_sql_server()
        my_var_objAS400Cursor = my_var_objAS400Conn.cursor()
        my_var_objSQLCursor = my_var_objSQLConn.cursor()
        with print_lock:("\n🔍 Starting final verification of all tables...")
        
        # Verify each table
        for my_var_strAS400Table, my_var_strSQLTable in my_var_lstTablesToCopy:
            my_var_boolSuccess, my_var_strMessage, my_var_intAS400Count, my_var_intSQLCount = fun_verify_table_migration(
                my_var_objAS400Cursor,
                my_var_objSQLCursor,
                my_var_strAS400Table,
                my_var_strSQLTable
            )
            my_var_intTotalAS400Rows += my_var_intAS400Count
            my_var_intTotalSQLRows += my_var_intSQLCount
            if not my_var_boolSuccess:
                my_var_boolAllSuccess = False
                my_var_lstFailedTables.append((my_var_strAS400Table, my_var_strMessage))
                with print_lock:(f"  ❌ {my_var_strAS400Table}: {my_var_strMessage}")
            else:
                with print_lock:(f"  ✅ {my_var_strAS400Table}: {my_var_strMessage}")
        # Print summary
        with print_lock:("\n📊 Final Verification Summary:")
        with print_lock:(f"Total AS400 Rows: {my_var_intTotalAS400Rows}")
        with print_lock:(f"Total SQL Server Rows: {my_var_intTotalSQLRows}")
        with print_lock:(f"Total Tables Verified: {len(my_var_lstTablesToCopy)}")
        with print_lock:(f"Failed Tables: {len(my_var_lstFailedTables)}")
        
        if my_var_lstFailedTables:
            with print_lock:("\nFailed Tables Details:")
            for my_var_strTable, my_var_strMessage in my_var_lstFailedTables:
                with print_lock:(f"  - {my_var_strTable}: {my_var_strMessage}")
        return my_var_boolAllSuccess, my_var_lstFailedTables
    except Exception as my_var_errException:
        with print_lock:(f"Error during final verification: {str(my_var_errException)}")
        return False, [("ALL", f"Verification error: {str(my_var_errException)}")]
    finally:
        # Clean up
        if my_var_objAS400Cursor:
            my_var_objAS400Cursor.close()
        if my_var_objSQLCursor:
            my_var_objSQLCursor.close()
        if my_var_objAS400Conn:
            my_var_objAS400Conn.close()
        if my_var_objSQLConn:
            my_var_objSQLConn.close()
def fun_beep_error():
    """Plays an error beep sound"""
    with print_lock:(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Starting fun_beep_error")
    try:
        winsound.Beep(1000, 1000)  # 1000Hz for 1 second
    except:
        pass  # Ignore if beep fails (e.g., on non-Windows systems)
def fun_normalize_decimal_values(my_var_lstRows, my_var_dictDecimalDefs=None):
    """
    Normalizes decimal values in a list of rows to prevent precision loss
    Args:
        my_var_lstRows: List of rows containing decimal values
        my_var_dictDecimalDefs: Optional dictionary of column names to decimal definitions
    Returns:
        list: Rows with normalized decimal values
    """
    try:
        my_var_lstNormalizedRows = []
        for my_var_row in my_var_lstRows:
            my_var_lstNormalizedRow = []
            for my_var_intIdx, my_var_val in enumerate(my_var_row):
                if isinstance(my_var_val, Decimal):
                    if my_var_dictDecimalDefs and my_var_intIdx < len(my_var_dictDecimalDefs):
                        # If we have decimal definitions, use them to determine scale
                        my_var_strDef = my_var_dictDecimalDefs[my_var_intIdx]
                        if "decimal" in my_var_strDef:
                            # Extract scale from definition (e.g., "decimal(10,4)" -> 4)
                            my_var_intScale = int(my_var_strDef.split(",")[1].strip(")"))
                            my_var_lstNormalizedRow.append(float(round(my_var_val, my_var_intScale)))
                        else:
                            my_var_lstNormalizedRow.append(float(round(my_var_val, 4)))
                    else:
                        # Default to 4 decimal places if no definition
                        my_var_lstNormalizedRow.append(float(round(my_var_val, 4)))
                else:
                    my_var_lstNormalizedRow.append(my_var_val)
            my_var_lstNormalizedRows.append(tuple(my_var_lstNormalizedRow))
        return my_var_lstNormalizedRows
    except Exception as e:
        with print_lock:(f"Error normalizing decimal values: {str(e)}")
        return my_var_lstRows
import re
from datetime import datetime
def fun_get_column_types(my_var_objAS400Cursor, my_var_strSchema, my_var_strTable):
    """
    Gets column data types from AS400 table
    Args:
        my_var_objAS400Cursor: AS400 cursor
        my_var_strSchema: Schema name
        my_var_strTable: Table name
    Returns:
        dict: Dictionary mapping column names to their data types
    """
    with print_lock:(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Starting fun_get_column_types for {my_var_strSchema}.{my_var_strTable}")
    try:
        my_var_strSanitizedTable = my_var_strTable.replace(" ", "_")
        my_var_objAS400Cursor.execute(f"""
            SELECT COLUMN_NAME, DATA_TYPE, NUMERIC_PRECISION, NUMERIC_SCALE
            FROM QSYS2.SYSCOLUMNS
            WHERE TABLE_SCHEMA = '{my_var_strSchema}'
            AND TABLE_NAME = '{my_var_strSanitizedTable}'
        """)
        return {
            row[0].replace(" ", "_").replace("'", "_"): (row[1], row[2], row[3])
            for row in my_var_objAS400Cursor.fetchall()
        }
    except Exception as e:
        with print_lock:(f"Error getting column types: {str(e)}")
        return {}
    
def fun_convert_value(my_var_val, my_var_strType, my_var_intPrecision=None, my_var_intScale=None):
    """
    Converts a value to the appropriate type based on column definition
    Args:
        my_var_val: Value to convert
        my_var_strType: AS400 data type
        my_var_intPrecision: Numeric precision (if applicable)
        my_var_intScale: Numeric scale (if applicable)
    Returns:
        Converted value
    """
    with print_lock:(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Starting fun_convert_value")
    if my_var_val is None:
        return None
        
    try:
        if my_var_strType in ('DECIMAL', 'NUMERIC'):
            if isinstance(my_var_val, (int, float, Decimal)):
                return float(round(my_var_val, my_var_intScale if my_var_intScale is not None else 4))
            elif isinstance(my_var_val, str):
                # Try to convert string to float
                try:
                    return float(round(float(my_var_val), my_var_intScale if my_var_intScale is not None else 4))
                except ValueError:
                    return None
        elif my_var_strType in ('INTEGER', 'SMALLINT', 'BIGINT'):
            if isinstance(my_var_val, (int, float, Decimal)):
                return int(my_var_val)
            elif isinstance(my_var_val, str):
                try:
                    return int(float(my_var_val))
                except ValueError:
                    return None
        elif my_var_strType in ('CHAR', 'VARCHAR', 'GRAPHIC', 'VARGRAPHIC'):
            return str(my_var_val).strip()
        else:
            return my_var_val
    except Exception as e:
        with print_lock:(f"Error converting value {my_var_val} to type {my_var_strType}: {str(e)}")
        return None
def fun_normalize_row(my_var_row, my_var_lstColumns, my_var_dictColTypes):
    """
    Normalizes a row of data based on column types
    Args:
        my_var_row: Row of data
        my_var_lstColumns: List of (name, desc) tuples
        my_var_dictColTypes: Dictionary of column types
    Returns:
        tuple: Normalized row
    """
    with print_lock:(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Starting fun_normalize_row")
    try:
        my_var_lstNormalized = []
        for my_var_intIdx, (my_var_strName, _) in enumerate(my_var_lstColumns):
            if my_var_intIdx < len(my_var_row):
                my_var_val = my_var_row[my_var_intIdx]
                if my_var_strName in my_var_dictColTypes:
                    my_var_strType, my_var_intPrecision, my_var_intScale = my_var_dictColTypes[my_var_strName]
                    my_var_lstNormalized.append(fun_convert_value(my_var_val, my_var_strType, my_var_intPrecision, my_var_intScale))
                else:
                    my_var_lstNormalized.append(my_var_val)
            else:
                my_var_lstNormalized.append(None)
        return tuple(my_var_lstNormalized)
    except Exception as e:
        with print_lock:(f"Error normalizing row: {str(e)}")
        return my_var_row
import re
def fun_sanitize_column_name(my_var_strName):
    """
    Sanitizes column names by replacing special characters and whitespace with underscores
    Args:
        my_var_strName: Column name to sanitize
    Returns:
        str: Sanitized column name
    """
    my_var_strName = my_var_strName.replace(" ", "_")  # Replace spaces
    return my_var_strName.replace("'", "_").replace("]", "]]")  # Replace other special chars
def fun_sync_table_data(my_var_objAS400Cursor, my_var_objSQLCursor, my_var_strAS400Table, my_var_strSQLTable, my_var_intAS400Count, my_var_intSQLCount):
    """
    Synchronizes table data between AS400 and SQL Server
    Args:
        my_var_objAS400Cursor: AS400 cursor
        my_var_objSQLCursor: SQL Server cursor
        my_var_strAS400Table: AS400 table name
        my_var_strSQLTable: SQL Server table name
        my_var_intAS400Count: AS400 row count
        my_var_intSQLCount: SQL Server row count
    Returns:
        tuple: (bool success, str message)
    """
    try:
        my_var_strSanitizedAS400Table = fun_sanitize_table_name(my_var_strAS400Table)
        my_var_strSanitizedSQLTable = fun_sanitize_table_name(my_var_strSQLTable)
        
        # Get column information from SQL Server to determine decimal definitions
        my_var_objSQLCursor.execute(f"""
            SELECT COLUMN_NAME, DATA_TYPE, NUMERIC_PRECISION, NUMERIC_SCALE
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = '{myCon_strSQLSchema}'
            AND TABLE_NAME = '{my_var_strSanitizedSQLTable}'
            AND DATA_TYPE IN ('decimal', 'numeric')
        """)
        my_var_dictDecimalDefs = {}
        for row in my_var_objSQLCursor.fetchall():
            col_name, data_type, precision, scale = row
            my_var_dictDecimalDefs[col_name] = f"{data_type}({precision},{scale})"
        # Add pause for ARCUST table
        if my_var_strSanitizedAS400Table.upper() == "ARCUST":
            with print_lock:(f"\n[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ⏸️  Pausing for ARCUST table. Press Enter to continue...")
            input()
        # Get table metadata
        with print_lock:(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}]       get table metadata")
        my_var_strTableDesc = fun_get_table_description(my_var_objAS400Cursor, myCon_strAS400Library, my_var_strAS400Table)
        with print_lock:(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}]           description: {my_var_strTableDesc}")
        # Get columns from AS400 in order with their descriptions
        my_var_strTimestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        with print_lock:(f"[{my_var_strTimestamp}] Reading AS400 table columns...")
        my_var_objAS400Cursor.execute(f"""
            SELECT COLUMN_NAME, COLUMN_TEXT, ORDINAL_POSITION
            FROM QSYS2.SYSCOLUMNS
            WHERE TABLE_SCHEMA = '{myCon_strAS400Library}'
            AND TABLE_NAME = '{my_var_strAS400Table}'
            ORDER BY ORDINAL_POSITION
        """)
        my_var_lstAS400Columns = [(fun_sanitize_column_name(row[0]), fun_sanitize_column_name(row[1]), row[2]) for row in my_var_objAS400Cursor.fetchall()]
        my_var_strTimestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        with print_lock:(f"[{my_var_strTimestamp}] AS400 columns read completed, found {len(my_var_lstAS400Columns)} columns")
        
        if not my_var_lstAS400Columns:
            with print_lock:(f"[{my_var_strTimestamp}]   ❌ No columns found in AS400 table")
            return False, "No columns found in AS400 table"
        # Get columns from SQL Server in order
        my_var_intRetryCount = 0
        my_var_intMaxRetries = 3
        my_var_intRetryDelay = 5  # seconds
        while my_var_intRetryCount < my_var_intMaxRetries:
            try:
  
                with print_lock:(f"[{my_var_strTimestamp}] Reading SQL Server table columns...")
                my_var_objSQLCursor.execute(f"""                            --Get the SQL server columns
                    SELECT COLUMN_NAME, ORDINAL_POSITION
                    FROM INFORMATION_SCHEMA.COLUMNS
                    WHERE TABLE_SCHEMA = '{myCon_strSQLSchema}'
                    AND TABLE_NAME = '{my_var_strSQLTable}'
                    ORDER BY ORDINAL_POSITION
                """)
                my_var_lstSQLColumns = [(row[0], row[1]) for row in my_var_objSQLCursor.fetchall()]
                my_var_strTimestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                with print_lock:(f"[{my_var_strTimestamp}] SQL Server columns read completed, found {len(my_var_lstSQLColumns)} columns")
                break
            except Exception as e:
                my_var_intRetryCount += 1
                my_var_strTimestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                with print_lock:(f"[{my_var_strTimestamp}]   ⚠️ SQL Server error (attempt {my_var_intRetryCount}/{my_var_intMaxRetries}): {str(e)}")
                if my_var_intRetryCount < my_var_intMaxRetries:
                    with print_lock:(f"[{my_var_strTimestamp}]   ⏳ Retrying in {my_var_intRetryDelay} seconds...")
                    time.sleep(my_var_intRetryDelay)
                else:
                    with print_lock:(f"[{my_var_strTimestamp}]   ❌ Failed to get SQL Server columns after {my_var_intMaxRetries} attempts")
                    return False, f"Failed to get SQL Server columns: {str(e)}"
        if not my_var_lstSQLColumns:
            with print_lock:(f"[{my_var_strTimestamp}]   ❌ No columns found in SQL Server table")
            return False, "No columns found in SQL Server table"
        # Create mapping of AS400 to SQL Server columns
        my_var_lstColumnMapping = []
        for my_var_intIdx, (my_var_strAS400Name, my_var_strAS400Desc, _) in enumerate(my_var_lstAS400Columns):
            # Find matching SQL Server column by position
            my_var_strSQLCol = next((col[0] for col in my_var_lstSQLColumns if col[1] == my_var_intIdx + 1), None)
            if my_var_strSQLCol:
                my_var_lstColumnMapping.append({
                    'as400_name': my_var_strAS400Name,
                    'sql_name': fun_sanitize_column_name(my_var_strSQLCol),
                    'description': my_var_strAS400Desc,
                    'position': my_var_intIdx + 1
                })
        if not my_var_lstColumnMapping:
            with print_lock:(f"[{my_var_strTimestamp}]   ❌ No matching columns found between AS400 and SQL Server")
            return False, "No matching columns found"
        # Find year column
        my_var_strYearColumn = None
        for col in my_var_lstColumnMapping:
            if col['as400_name'].upper().endswith('YY'):
                my_var_strYearColumn = col['as400_name']
                #print(f"[{my_var_strTimestamp}]   Found year column: {my_var_strYearColumn}")
                break
        # Prepare destination table
        with print_lock:(f"[{my_var_strTimestamp}]    prepare destination table")
        my_var_strDestTable = f"z_{my_var_strTableDesc}_____{my_var_strAS400Table}"
        my_var_strDestTable = my_var_strDestTable.replace(" ", "_")  # Sanitize table name
        my_var_strDestTableEscaped = my_var_strDestTable.replace(']', ']]')
        
        # Create column lists using the mapping, ordered by position
        my_var_lstColumnMapping.sort(key=lambda x: x['position'])
        my_var_lstAS400Cols = [col['as400_name'].replace(" ", "_") for col in my_var_lstColumnMapping]  # Sanitize AS400 column names
        my_var_lstSQLCols = [f"[{col['sql_name'].replace(' ', '_').replace(']', ']]')}]" for col in my_var_lstColumnMapping]
        
        my_var_strAS400ColList = ", ".join(my_var_lstAS400Cols)
        my_var_strSQLColList = ", ".join(my_var_lstSQLCols)
        my_var_strPlaceholders = ", ".join(["?"] * len(my_var_lstColumnMapping))
        # Print detailed column information
        with print_lock:(f"\n[{my_var_strTimestamp}] 🔍 Column Mapping:")
        for col in my_var_lstColumnMapping:
            with print_lock:(f"[{my_var_strTimestamp}]   AS400: {col['as400_name']} -> SQL: {col['sql_name']} (Position: {col['position']})")
        with print_lock:(f"[{my_var_strTimestamp}]   Total columns: {len(my_var_lstColumnMapping)}")
        # Case 1: Source has data, destination is empty
        if my_var_intAS400Count > 0 and my_var_intSQLCount == 0:
            with print_lock:(f"[{my_var_strTimestamp}]   📥 Case 1: Copying all data from source to empty destination...")
            try:
                # Define year ranges
                my_var_lstYearRanges = [
                    ("<=2012", "2012"),
                    ("2013", "2013"),
                    ("2014", "2014"),
                    ("2015", "2015"),
                    ("2016", "2016"),
                    ("2017", "2017"),
                    ("2018", "2018"),
                    ("2019", "2019"),
                    ("2020", "2020"),
                    ("2021", "2021"),
                    ("2022", "2022"),
                    ("2023", "2023"),
                    ("2024", "2024"),
                    ("2025", "2025"),
                    (">=2026", "2026")
                ]
                # If no year column found, process all data at once
                if not my_var_strYearColumn:
                    with print_lock:(f"[{my_var_strTimestamp}]   ⚠️ No year column found, processing all data at once")
                    my_var_lstYearRanges = [("ALL", None)]
                my_var_intTotalInserted = 0
                
                for my_var_strYearRange, my_var_strYear in my_var_lstYearRanges:
                    my_var_strTimestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                    with print_lock:(f"\n[{my_var_strTimestamp}]   🔄 {my_var_strDestTableEscaped} Processing year range: {my_var_strYearRange}")
                    
                    # Build WHERE clause for year range
                    my_var_strWhereClause = ""
                    if my_var_strYearColumn:
                        if my_var_strYearRange == "<=2012":
                            my_var_strWhereClause = f"WHERE {my_var_strYearColumn} <= 12"
                        elif my_var_strYearRange == ">=2026":
                            my_var_strWhereClause = f"WHERE {my_var_strYearColumn} >= 26"
                        else:
                            my_var_strWhereClause = f"WHERE {my_var_strYearColumn} = {my_var_strYear[2:]}"
                    
                    # Get data from AS400 for this year range
                    #print(f"[{my_var_strTimestamp}]       fetching data from AS400...")
                    my_var_objAS400Cursor.execute(f"SELECT {my_var_strAS400ColList} FROM {myCon_strAS400Library}.\"{my_var_strAS400Table}\" {my_var_strWhereClause}")
                    my_var_lstAS400Rows = my_var_objAS400Cursor.fetchall()
                    
                    if my_var_lstAS400Rows:
                        with print_lock:(f"[{my_var_strTimestamp}]       on {my_var_strAS400Table}    found {len(my_var_lstAS400Rows)} rows for {my_var_strYearRange}")
                        #print(f"[{my_var_strTimestamp}]       Batch size: {myCon_intBatchSize} rows")
                        
                        # Build and validate the insert query
                        my_var_strInsertSQL = f"INSERT INTO [{myCon_strSQLSchema}].[{my_var_strDestTableEscaped}] ({my_var_strSQLColList}) VALUES ({my_var_strPlaceholders})"
                        
                        # Insert into destination table in smaller batches
                        with print_lock:(f"[{my_var_strTimestamp}]       inserting {len(my_var_lstAS400Rows)} rows into destination table... {my_var_strDestTableEscaped}")
                        
                        # Start transaction
                        my_var_intRetryCount = 0
                        while my_var_intRetryCount < my_var_intMaxRetries:
                            try:
                                my_var_objSQLCursor.execute("BEGIN TRANSACTION")
                                break
                            except Exception as e:
                                my_var_intRetryCount += 1
                                my_var_strTimestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                                with print_lock:(f"[{my_var_strTimestamp}]   ⚠️ SQL Server error starting transaction (attempt {my_var_intRetryCount}/{my_var_intMaxRetries}): {str(e)}")
                                if my_var_intRetryCount < my_var_intMaxRetries:
                                    with print_lock:(f"[{my_var_strTimestamp}]   ⏳ Retrying in {my_var_intRetryDelay} seconds...")
                                    time.sleep(my_var_intRetryDelay)
                                else:
                                    with print_lock:(f"[{my_var_strTimestamp}]   ❌ Failed to start transaction after {my_var_intMaxRetries} attempts")
                                    return False, f"Failed to start transaction: {str(e)}"
                        
                        for my_var_intStart in range(0, len(my_var_lstAS400Rows), myCon_intBatchSize):
                            my_var_strTimestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                            my_var_intEnd = min(my_var_intStart + myCon_intBatchSize, len(my_var_lstAS400Rows))
                            my_var_lstBatch = my_var_lstAS400Rows[my_var_intStart:my_var_intEnd]
                            
                            # Print progress every 1000 rows
                            #if my_var_intStart % 10000 == 0:
                                #print(f"[{my_var_strTimestamp}]       inserted {my_var_intStart} of {len(my_var_lstAS400Rows)} rows...")
                            
                            my_var_intRetryCount = 0
                            while my_var_intRetryCount < my_var_intMaxRetries:
                                try:
                                    my_var_objSQLCursor.executemany(my_var_strInsertSQL, my_var_lstBatch)
                                    my_var_intTotalInserted += len(my_var_lstBatch)
                                    
                                    # Add a small delay between batches to allow memory cleanup
                                    if my_var_intStart % 1000 == 0:
                                        time.sleep(1)
                                    break
                                except Exception as e:
                                    my_var_intRetryCount += 1
                                    my_var_strTimestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                                    with print_lock:(f"[{my_var_strTimestamp}]   ⚠️ SQL Server error during batch insert (attempt {my_var_intRetryCount}/{my_var_intMaxRetries}): {str(e)}")
                                    if my_var_intRetryCount < my_var_intMaxRetries:
                                        with print_lock:(f"[{my_var_strTimestamp}]   ⏳ Retrying in {my_var_intRetryDelay} seconds...")
                                        time.sleep(my_var_intRetryDelay)
                                    else:
                                        with print_lock:(f"[{my_var_strTimestamp}]   ❌ Failed to insert batch after {my_var_intMaxRetries} attempts")
                                        my_var_objSQLCursor.execute("ROLLBACK TRANSACTION")
                                        return False, f"Failed to insert batch: {str(e)}"
                        
                        # Commit transaction
                        my_var_intRetryCount = 0
                        while my_var_intRetryCount < my_var_intMaxRetries:
                            try:
                                my_var_objSQLCursor.execute("COMMIT TRANSACTION")
                                with print_lock:(f"[{my_var_strTimestamp}]   ✅ Copied {len(my_var_lstAS400Rows)} rows for {my_var_strYearRange}")
                                break
                            except Exception as e:
                                my_var_intRetryCount += 1
                                my_var_strTimestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                                with print_lock:(f"[{my_var_strTimestamp}]   ⚠️ SQL Server error committing transaction (attempt {my_var_intRetryCount}/{my_var_intMaxRetries}): {str(e)}")
                                if my_var_intRetryCount < my_var_intMaxRetries:
                                    with print_lock:(f"[{my_var_strTimestamp}]   ⏳ Retrying in {my_var_intRetryDelay} seconds...")
                                    time.sleep(my_var_intRetryDelay)
                                else:
                                    with print_lock:(f"[{my_var_strTimestamp}]   ❌ Failed to commit transaction after {my_var_intMaxRetries} attempts")
                                    my_var_objSQLCursor.execute("ROLLBACK TRANSACTION")
                                    return False, f"Failed to commit transaction: {str(e)}"
                    else:
                        with print_lock:(f"[{my_var_strTimestamp}]   ⚠️ No rows found for {my_var_strYearRange}")
                
                with print_lock:(f"[{my_var_strTimestamp}]   ✅ Total rows copied: {my_var_intTotalInserted}")
                return True, "Full copy completed"
            except Exception as e:
                my_var_strTimestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                with print_lock:(f"[{my_var_strTimestamp}]   ❌ Error in full copy: {str(e)}")
                return False, f"Error in full copy: {str(e)}"
        # Case 3: Source has more rows than destination
        elif my_var_intAS400Count > my_var_intSQLCount and my_var_intSQLCount > 0:
            with print_lock:(f"[{my_var_strTimestamp}]   🔍 Case 3: Finding and inserting missing rows...")
            try:
                # Define year ranges
                my_var_lstYearRanges = [
                    ("<=2012", "2012"),
                    ("2013", "2013"),
                    ("2014", "2014"),
                    ("2015", "2015"),
                    ("2016", "2016"),
                    ("2017", "2017"),
                    ("2018", "2018"),
                    ("2019", "2019"),
                    ("2020", "2020"),
                    ("2021", "2021"),
                    ("2022", "2022"),
                    ("2023", "2023"),
                    ("2024", "2024"),
                    ("2025", "2025"),
                    (">=2026", "2026")
                ]
                # If no year column found, process all data at once
                if not my_var_strYearColumn:
                    with print_lock:(f"[{my_var_strTimestamp}]   ⚠️ No year column found, processing all data at once")
                    my_var_lstYearRanges = [("ALL", None)]
                my_var_intTotalInserted = 0
                
                for my_var_strYearRange, my_var_strYear in my_var_lstYearRanges:
                    my_var_strTimestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                    with print_lock:(f"\n[{my_var_strTimestamp}]   🔄 Processing year range: {my_var_strYearRange}")
                    
                    # Build WHERE clause for year range
                    my_var_strWhereClause = ""
                    if my_var_strYearColumn:
                        if my_var_strYearRange == "<=2012":
                            my_var_strWhereClause = f"WHERE {my_var_strYearColumn} <= 12"
                        elif my_var_strYearRange == ">=2026":
                            my_var_strWhereClause = f"WHERE {my_var_strYearColumn} >= 26"
                        else:
                            my_var_strWhereClause = f"WHERE {my_var_strYearColumn} = {my_var_strYear[2:]}"
                    
                    # Get data from AS400 for this year range
                    #print(f"[{my_var_strTimestamp}]       fetching data from AS400...")
                    my_var_objAS400Cursor.execute(f"SELECT {my_var_strAS400ColList} FROM {myCon_strAS400Library}.\"{my_var_strAS400Table}\" {my_var_strWhereClause}")
                    my_var_lstAS400Rows = my_var_objAS400Cursor.fetchall()
                    
                    if my_var_lstAS400Rows:
                        with print_lock:(f"[{my_var_strTimestamp}]       found {len(my_var_lstAS400Rows)} rows for {my_var_strYearRange}")
                        with print_lock:(f"[{my_var_strTimestamp}]       Batch size: {myCon_intBatchSize} rows")
                        
                        # Build and validate the insert query
                        my_var_strInsertSQL = f"INSERT INTO [{myCon_strSQLSchema}].[{my_var_strDestTableEscaped}] ({my_var_strSQLColList}) VALUES ({my_var_strPlaceholders})"
                        
                        # Insert into destination table in smaller batches
                        with print_lock:(f"[{my_var_strTimestamp}]       inserting {len(my_var_lstAS400Rows)} rows into destination table...")
                        
                        # Start transaction
                        my_var_intRetryCount = 0
                        while my_var_intRetryCount < my_var_intMaxRetries:
                            try:
                                my_var_objSQLCursor.execute("BEGIN TRANSACTION")
                                break
                            except Exception as e:
                                my_var_intRetryCount += 1
                                my_var_strTimestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                                with print_lock:(f"[{my_var_strTimestamp}]   ⚠️ SQL Server error starting transaction (attempt {my_var_intRetryCount}/{my_var_intMaxRetries}): {str(e)}")
                                if my_var_intRetryCount < my_var_intMaxRetries:
                                    with print_lock:(f"[{my_var_strTimestamp}]   ⏳ Retrying in {my_var_intRetryDelay} seconds...")
                                    time.sleep(my_var_intRetryDelay)
                                else:
                                    with print_lock:(f"[{my_var_strTimestamp}]   ❌ Failed to start transaction after {my_var_intMaxRetries} attempts")
                                    return False, f"Failed to start transaction: {str(e)}"
                        
                        for my_var_intStart in range(0, len(my_var_lstAS400Rows), myCon_intBatchSize):
                            my_var_strTimestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                            my_var_intEnd = min(my_var_intStart + myCon_intBatchSize, len(my_var_lstAS400Rows))
                            my_var_lstBatch = my_var_lstAS400Rows[my_var_intStart:my_var_intEnd]
                            
                            # Print progress every 1000 rows
                            if my_var_intStart % 100 == 0:
                                with print_lock:(f"[{my_var_strTimestamp}]       on {my_var_strDestTableEscaped}...inserted {my_var_intStart} of {len(my_var_lstAS400Rows)} rows...")
                            
                            my_var_intRetryCount = 0
                            while my_var_intRetryCount < my_var_intMaxRetries:
                                try:
                                    my_var_objSQLCursor.executemany(my_var_strInsertSQL, my_var_lstBatch)
                                    my_var_intTotalInserted += len(my_var_lstBatch)
                                    
                                    # Add a small delay between batches to allow memory cleanup
                                    if my_var_intStart % 1000 == 0:
                                        time.sleep(1)
                                    break
                                except Exception as e:
                                    my_var_intRetryCount += 1
                                    my_var_strTimestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                                    with print_lock:(f"[{my_var_strTimestamp}]   ⚠️ SQL Server error during batch insert (attempt {my_var_intRetryCount}/{my_var_intMaxRetries}): {str(e)}")
                                    if my_var_intRetryCount < my_var_intMaxRetries:
                                        with print_lock:(f"[{my_var_strTimestamp}]   ⏳ Retrying in {my_var_intRetryDelay} seconds...")
                                        time.sleep(my_var_intRetryDelay)
                                    else:
                                        with print_lock:(f"[{my_var_strTimestamp}]   ❌ Failed to insert batch after {my_var_intMaxRetries} attempts")
                                        my_var_objSQLCursor.execute("ROLLBACK TRANSACTION")
                                        return False, f"Failed to insert batch: {str(e)}"
                        
                        # Commit transaction
                        my_var_intRetryCount = 0
                        while my_var_intRetryCount < my_var_intMaxRetries:
                            try:
                                my_var_objSQLCursor.execute("COMMIT TRANSACTION")
                                with print_lock:(f"[{my_var_strTimestamp}]   ✅ Copied {len(my_var_lstAS400Rows)} rows for {my_var_strYearRange}")
                                break
                            except Exception as e:
                                my_var_intRetryCount += 1
                                my_var_strTimestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                                with print_lock:(f"[{my_var_strTimestamp}]   ⚠️ SQL Server error committing transaction (attempt {my_var_intRetryCount}/{my_var_intMaxRetries}): {str(e)}")
                                if my_var_intRetryCount < my_var_intMaxRetries:
                                    with print_lock:(f"[{my_var_strTimestamp}]   ⏳ Retrying in {my_var_intRetryDelay} seconds...")
                                    time.sleep(my_var_intRetryDelay)
                                else:
                                    with print_lock:(f"[{my_var_strTimestamp}]   ❌ Failed to commit transaction after {my_var_intMaxRetries} attempts")
                                    my_var_objSQLCursor.execute("ROLLBACK TRANSACTION")
                                    return False, f"Failed to commit transaction: {str(e)}"
                    else:
                        with print_lock:(f"[{my_var_strTimestamp}]   ⚠️ No rows found for {my_var_strYearRange}")
                
                with print_lock:(f"[{my_var_strTimestamp}]   ✅ Total rows copied: {my_var_intTotalInserted}")
                return True, "Missing rows inserted"
            except Exception as e:
                my_var_strTimestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                with print_lock:(f"[{my_var_strTimestamp}]   ❌ Error inserting missing rows: {str(e)}")
                return False, f"Error inserting missing rows: {str(e)}"
        # Case 2: Destination has more rows than source
        elif my_var_intAS400Count < my_var_intSQLCount:
            with print_lock:(f"[{my_var_strTimestamp}]   🔍 Case 2: Destination has more rows than source...")
            try:
                # Try to identify excess rows using a key column
                my_var_strKeyCol = None
                for name, desc, _ in my_var_lstAS400Columns:
                    if name.upper() in ['ID', 'KEY', 'CODE', 'NUMBER', 'NO']:
                        my_var_strKeyCol = name
                        break
                if my_var_strKeyCol:
                    with print_lock:(f"[{my_var_strTimestamp}]   Using key column '{my_var_strKeyCol}' to identify excess rows...")
                    # Get list of keys from source
                    my_var_objAS400Cursor.execute(f"SELECT {my_var_strKeyCol} FROM {myCon_strAS400Library}.\"{my_var_strAS400Table}\"")
                    my_var_lstSourceKeys = [row[0] for row in my_var_objAS400Cursor.fetchall()]
                    
                    # Delete rows not in source
                    my_var_strSQLKeyCol = f"[{my_var_lstAS400Columns[[n for n, _ in my_var_lstAS400Columns].index(my_var_strKeyCol)][1]}_____{my_var_strKeyCol}]"
                    my_var_intRetryCount = 0
                    while my_var_intRetryCount < my_var_intMaxRetries:
                        try:
                            my_var_objSQLCursor.execute(f"""
                                DELETE FROM [{myCon_strSQLSchema}].[{my_var_strDestTableEscaped}]
                                WHERE {my_var_strSQLKeyCol} NOT IN ({','.join(['?' for _ in my_var_lstSourceKeys])})
                            """, my_var_lstSourceKeys)
                            my_var_objSQLCursor.commit()
                            with print_lock:(f"[{my_var_strTimestamp}]   ✅ Deleted excess rows using key column")
                            break
                        except Exception as e:
                            my_var_intRetryCount += 1
                            my_var_strTimestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                            with print_lock:(f"[{my_var_strTimestamp}]   ⚠️ SQL Server error deleting excess rows (attempt {my_var_intRetryCount}/{my_var_intMaxRetries}): {str(e)}")
                            if my_var_intRetryCount < my_var_intMaxRetries:
                                with print_lock:(f"[{my_var_strTimestamp}]   ⏳ Retrying in {my_var_intRetryDelay} seconds...")
                                time.sleep(my_var_intRetryDelay)
                            else:
                                with print_lock:(f"[{my_var_strTimestamp}]   ❌ Failed to delete excess rows after {my_var_intMaxRetries} attempts")
                                return False, f"Failed to delete excess rows: {str(e)}"
                else:
                    with print_lock:(f"[{my_var_strTimestamp}]   No key column found, truncating and reloading...")
                    # Truncate and reload
                    my_var_intRetryCount = 0
                    while my_var_intRetryCount < my_var_intMaxRetries:
                        try:
                            my_var_objSQLCursor.execute(f"TRUNCATE TABLE [{myCon_strSQLSchema}].[{my_var_strDestTableEscaped}]")
                            my_var_objSQLCursor.commit()
                            break
                        except Exception as e:
                            my_var_intRetryCount += 1
                            my_var_strTimestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                            with print_lock:(f"[{my_var_strTimestamp}]   ⚠️ SQL Server error truncating table (attempt {my_var_intRetryCount}/{my_var_intMaxRetries}): {str(e)}")
                            if my_var_intRetryCount < my_var_intMaxRetries:
                                with print_lock:(f"[{my_var_strTimestamp}]   ⏳ Retrying in {my_var_intRetryDelay} seconds...")
                                time.sleep(my_var_intRetryDelay)
                            else:
                                with print_lock:(f"[{my_var_strTimestamp}]   ❌ Failed to truncate table after {my_var_intMaxRetries} attempts")
                                return False, f"Failed to truncate table: {str(e)}"
                    
                    # Copy all data from source
                    my_var_objAS400Cursor.execute(f"SELECT * FROM {myCon_strAS400Library}.\"{my_var_strAS400Table}\"")
                    my_var_objAS400Cursor.execute(f"SELECT {my_var_strAS400ColList} FROM {myCon_strAS400Library}.\"{my_var_strAS400Table}\"")
                    my_var_lstAS400Rows = my_var_objAS400Cursor.fetchall()
                    
                    if my_var_lstAS400Rows:
                        my_var_strInsertSQL = f"INSERT INTO [{myCon_strSQLSchema}].[{my_var_strDestTableEscaped}] ({my_var_strSQLColList}) VALUES ({my_var_strPlaceholders})"
                        my_var_intRetryCount = 0
                        while my_var_intRetryCount < my_var_intMaxRetries:
                            try:
                                my_var_objSQLCursor.executemany(my_var_strInsertSQL, my_var_lstAS400Rows)
                                my_var_objSQLCursor.commit()
                                with print_lock:(f"[{my_var_strTimestamp}]   ✅ Reloaded {len(my_var_lstAS400Rows)} rows")
                                break
                            except Exception as e:
                                my_var_intRetryCount += 1
                                my_var_strTimestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                                with print_lock:(f"[{my_var_strTimestamp}]   ⚠️ SQL Server error reloading data (attempt {my_var_intRetryCount}/{my_var_intMaxRetries}): {str(e)}")
                                if my_var_intRetryCount < my_var_intMaxRetries:
                                    with print_lock:(f"[{my_var_strTimestamp}]   ⏳ Retrying in {my_var_intRetryDelay} seconds...")
                                    time.sleep(my_var_intRetryDelay)
                                else:
                                    with print_lock:(f"[{my_var_strTimestamp}]   ❌ Failed to reload data after {my_var_intMaxRetries} attempts")
                                    return False, f"Failed to reload data: {str(e)}"
                return True, "Excess rows handled"
            except Exception as e:
                my_var_strTimestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                with print_lock:(f"[{my_var_strTimestamp}]   ❌ Error handling excess rows: {str(e)}")
                return False, f"Error handling excess rows: {str(e)}"
        # Case 4: Counts match
        else:
            with print_lock:(f"[{my_var_strTimestamp}]   ✅ Row counts match, no synchronization needed")
            return True, "Row counts match"
    except Exception as my_var_errException:
        my_var_strTimestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        with print_lock:(f"[{my_var_strTimestamp}]   ❌ Unexpected error in sync_table_data: {str(my_var_errException)}")
        with print_lock:(f"[{my_var_strTimestamp}]   Error type: {type(my_var_errException)}")
        import traceback
        with print_lock:(f"[{my_var_strTimestamp}]   Stack trace: {traceback.format_exc()}")
        return False, f"Synchronization error: {str(my_var_errException)}"
def myFunStructureVerification(my_var_objAS400Cursor, my_var_objSQLCursor):
    """
    Verifies and fixes decimal precision/scale differences between AS400 and SQL Server tables
    Args:
        my_var_objAS400Cursor: AS400 cursor
        my_var_objSQLCursor: SQL Server cursor
    Returns:
        tuple: (bool success, str message)
    """
    with print_lock:(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Starting myFunStructureVerification")
    try:
        with print_lock:("\n🔍 Starting structure verification...")
        
        # Get all tables and their decimal columns from SQL Server schema 'mrs' in a single query
        my_var_objSQLCursor.execute("""
            SELECT 
                t.TABLE_NAME,
                c.COLUMN_NAME,
                c.DATA_TYPE,
                c.NUMERIC_PRECISION,
                c.NUMERIC_SCALE
            FROM INFORMATION_SCHEMA.TABLES t
            LEFT JOIN INFORMATION_SCHEMA.COLUMNS c 
                ON t.TABLE_NAME = c.TABLE_NAME 
                AND t.TABLE_SCHEMA = c.TABLE_SCHEMA
                AND c.DATA_TYPE IN ('decimal', 'numeric')
            WHERE t.TABLE_SCHEMA = 'mrs'
            AND t.TABLE_TYPE = 'BASE TABLE'
        """)
        
        # Create a dictionary to store SQL Server decimal columns by table
        with print_lock:(f" {datetime.now().strftime('%Y-%m-%d %H:%M:%S   ')} - Create a dictionary to store SQL Server decimal columns by table")
        my_var_dictSQLTableColumns = {}
        for row in my_var_objSQLCursor.fetchall():
            table_name, col_name, data_type, precision, scale = row
            if table_name not in my_var_dictSQLTableColumns:
                my_var_dictSQLTableColumns[table_name] = []
            if col_name:  # Only add if decimal column exists
                my_var_dictSQLTableColumns[table_name].append((col_name, data_type, precision, scale))
        
        with print_lock:(f"      verification....Found {len(my_var_dictSQLTableColumns)} tables in SQL Server schema 'mrs'")
        
        # Get all AS400 decimal columns in a single query
        my_var_objAS400Cursor.execute(f"""
            SELECT 
                TABLE_NAME,
                COLUMN_NAME,
                DATA_TYPE,
                NUMERIC_PRECISION,
                NUMERIC_SCALE
            FROM QSYS2.SYSCOLUMNS
            WHERE TABLE_SCHEMA = '{myCon_strAS400Library}'
            AND DATA_TYPE IN ('DECIMAL', 'NUMERIC')
        """)
        # Create a dictionary to store AS400 decimal columns by table
        with print_lock:(f"         {datetime.now().strftime('%Y-%m-%d %H:%M:%S   ')} - Create a dictionary to store AS400 decimal columns by table")
        my_var_dictAS400TableColumns = {}
        for row in my_var_objAS400Cursor.fetchall():
            table_name = row[0].replace(" ", "_").replace("'", "_")
            col_name = row[1].replace(" ", "_").replace("'", "_")
            table_name, col_name, data_type, precision, scale = row
            if table_name not in my_var_dictAS400TableColumns:
                my_var_dictAS400TableColumns[table_name] = []
            my_var_dictAS400TableColumns[table_name].append((col_name, data_type, precision, scale))
        
        my_var_dtEndTime = datetime.now()
        
        # Compare tables and their decimal columns
        with print_lock:(f" Compare tables and their decimal columns")
        for my_var_strSQLTable in my_var_dictSQLTableColumns:
            if "_____" not in my_var_strSQLTable:
                continue
                
            my_var_strAS400Table = my_var_strSQLTable.split("_____")[-1]
            
            # Skip if table has no decimal columns in either database
            if (my_var_strSQLTable not in my_var_dictSQLTableColumns or 
                my_var_strAS400Table not in my_var_dictAS400TableColumns):
                continue
            
            my_var_lstSQLDecimals = my_var_dictSQLTableColumns[my_var_strSQLTable]
            my_var_lstAS400Decimals = my_var_dictAS400TableColumns[my_var_strAS400Table]
            
            # Create mapping of original column names to SQL Server columns
            my_var_dictSQLColMap = {}
            for my_var_tplSQLCol in my_var_lstSQLDecimals:
                my_var_strSQLCol = my_var_tplSQLCol[0]
                if "_____" in my_var_strSQLCol:
                    my_var_strOriginalCol = my_var_strSQLCol.split("_____")[-1]
                    my_var_dictSQLColMap[my_var_strOriginalCol] = my_var_tplSQLCol
            
            # Compare decimal columns
            #print(f"{my_var_dtEndTime.strftime('%Y-%m-%d %H:%M:%S')} - Checking decimal columns in {my_var_strAS400Table}")
            for my_var_tplAS400Col in my_var_lstAS400Decimals:
                my_var_strAS400Col = my_var_tplAS400Col[0]
                my_var_intAS400Precision = my_var_tplAS400Col[2]
                my_var_intAS400Scale = my_var_tplAS400Col[3]
                
                my_var_tplSQLCol = my_var_dictSQLColMap.get(my_var_strAS400Col)
                
                if my_var_tplSQLCol:
                    my_var_intSQLPrecision = my_var_tplSQLCol[2]
                    my_var_intSQLScale = my_var_tplSQLCol[3]
                    
                    if my_var_intSQLScale < my_var_intAS400Scale:
                        with print_lock:(f"\n⚠️ Scale mismatch found in {my_var_strSQLTable}.{my_var_strAS400Col}:")
                        with print_lock:(f"  AS400: precision={my_var_intAS400Precision}, scale={my_var_intAS400Scale}")
                        with print_lock:(f"  SQL:   precision={my_var_intSQLPrecision}, scale={my_var_intSQLScale}")
                        
                        my_var_strAlterSQL = f"""
                            ALTER TABLE [mrs].[{my_var_strSQLTable}]
                            ALTER COLUMN [{my_var_tplSQLCol[0]}] decimal({my_var_intAS400Precision}, {my_var_intAS400Scale})
                        """
                        
                        with print_lock:(f"\nWill execute:\n{my_var_strAlterSQL}")
                        my_var_objSQLCursor.execute(my_var_strAlterSQL)
                        my_var_objSQLCursor.commit()
                        with print_lock:("  ✅ Column scale updated successfully")
        
        return True, "Structure verification completed"
        
    except Exception as e:
        with print_lock:(f"❌ Error in structure verification: {str(e)}")
        import traceback
        with print_lock:(f"Stack trace: {traceback.format_exc()}")
        return False, f"Structure verification error: {str(e)}"
def fun_process_table(my_var_tplTableInfo, my_var_objLogLock, my_var_objReportLock):
    """
    Processes a single table migration with retry mechanism
    Args:
        my_var_tplTableInfo: Tuple of (as400_table, sql_table)
        my_var_objLogLock: Lock for log file access
        my_var_objReportLock: Lock for report file access
    """
    # Initialize variables
    my_var_objAS400Conn = None
    my_var_objSQLConn = None
    my_var_objAS400Cursor = None
    my_var_objSQLCursor = None
    my_var_intTotalInserted = 0  # Initialize total inserted counter
    
    # Get thread ID for logging
    my_var_intThreadId = threading.get_ident()
    
    try:
        my_var_strTimestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        #print(f"\n[{my_var_strTimestamp}] 🚀 Starting table processing (Thread {my_var_strAS400Table})...")
        
        my_var_strAS400Table = my_var_tplTableInfo[0].lstrip('_')  # AS400 table name with leading underscores removed
        my_var_strSQLTable = my_var_tplTableInfo[1]  # SQL Server table name
        with print_lock: print(f"[{my_var_strTimestamp}]   🚀 Processing table: AS400={my_var_strAS400Table}, SQL={my_var_strSQLTable} (Thread {my_var_intThreadId})")
        
        # Check if table was previously processed
        # my_var_strReportPath = "migration_report.csv"
        # if os.path.exists(my_var_strReportPath):
        #     with open(my_var_strReportPath, 'r') as my_var_objReportFile:
        #         my_var_lstLines = my_var_objReportFile.readlines()
        #         for my_var_strLine in my_var_lstLines:
        #             if my_var_strAS400Table in my_var_strLine:
        #                 with print_lock:(f"[{my_var_strTimestamp}]   ⚠️ Table {my_var_strAS400Table} was previously processed. Skipping...")
        #                 return
        
        # Sanitize table names
        #print(f"[{my_var_strTimestamp}]   Sanitizing table names...")
        my_var_strSanitizedAS400Table = my_var_strAS400Table.replace(" ", "_")
        my_var_strSanitizedSQLTable = my_var_strSQLTable.replace(" ", "_")
        #print(f"[{my_var_strTimestamp}]     Sanitized names: AS400={my_var_strSanitizedAS400Table}, SQL={my_var_strSanitizedSQLTable}")
        
        # Create connections
        #print(f"[{my_var_strTimestamp}]   Establishing database connections...")
        my_var_objAS400Conn = fun_connect_as400()
        my_var_objSQLConn = fun_connect_sql_server()
        my_var_objAS400Cursor = my_var_objAS400Conn.cursor()
        my_var_objSQLCursor = my_var_objSQLConn.cursor()
        #with print_lock:print(f"[{my_var_strTimestamp}]     Connections established successfully")
        
        # Get initial row counts
        with print_lock:print(f"[{my_var_strTimestamp}]   Getting initial row counts...{my_var_strSanitizedAS400Table}")
        
        #AS400 count
        my_var_strQualifiedSource = f'{myCon_strAS400Library}.{my_var_strSanitizedAS400Table}'
        my_var_objAS400Cursor.execute(f"SELECT COUNT(*) FROM {my_var_strQualifiedSource}")
        my_var_intAS400Count = my_var_objAS400Cursor.fetchone()[0]

        #SQL Server count
        my_var_intSQLCount = fun_get_table_rowcount(my_var_objSQLCursor, myCon_strSQLSchema, my_var_strSanitizedSQLTable)
 
 
         # Check if row counts match
        if my_var_intAS400Count == my_var_intSQLCount:
            with print_lock: print(f"[{my_var_strTimestamp}]   ✅✅{myCon_strAS400Library}.{my_var_strAS400Table} {my_var_intSQLCount} ok...skipped")
            return

        #########################################################
        #print(f"  AS400 Count: {my_var_intAS400Count}")
        #print(f"  SQL Count: {my_var_intSQLCount}")
        '''''''''
        # Process the table
        my_var_boolSuccess, my_var_strMessage = fun_sync_table_data(
            my_var_objAS400Cursor,
            my_var_objSQLCursor,
            my_var_strAS400Table,
            my_var_strSQLTable,
            my_var_intAS400Count,
            my_var_intSQLCount
        )
        
        if not my_var_boolSuccess:
            with print_lock:(f"  ❌ Error processing table: {my_var_strMessage}")
            return  # Return from the function instead of using continue
            
        # Get total count from AS400
        my_var_objAS400Cursor.execute(f"SELECT COUNT(*) FROM {my_var_strQualifiedSource}")
        my_var_intAS400Count = my_var_objAS400Cursor.fetchone()[0]
        
        # Get total count from SQL Server
        my_var_objSQLCursor.execute(f"SELECT COUNT(*) FROM [{myCon_strSQLSchema}].[{my_var_strDestTableEscaped}]")
        my_var_intSQLCount = my_var_objSQLCursor.fetchone()[0]
  
        
        #########################################################
'''''''''
        
        # Check if row counts match
        if my_var_intAS400Count == my_var_intSQLCount:
            with print_lock: print(f"[{my_var_strTimestamp}]   ✅✅{myCon_strAS400Library}.{my_var_strAS400Table} {my_var_intSQLCount} ok...skipped")
            return
        
        # Get table metadata
        my_var_strTableDesc = fun_get_table_description(my_var_objAS400Cursor, myCon_strAS400Library, my_var_strSanitizedAS400Table)        
        my_var_lstColumns = fun_get_column_metadata(my_var_objAS400Cursor, myCon_strAS400Library, my_var_strSanitizedAS400Table)
        #with print_lock: print(f"[{my_var_strTimestamp}]     On my_var_strSanitizedAS400Table      Found {len(my_var_lstColumns)} columns")
        
        if not my_var_lstColumns:
            with print_lock: print(f"[{my_var_strTimestamp}]   ❌ Table {my_var_strSanitizedAS400Table} skipped: No columns found or not a real table")
            with my_var_objLogLock:
                with open(myCon_strLogFilePath, "a") as my_var_objLogFile:
                    my_var_objLogFile.write(f"[{my_var_strSanitizedAS400Table}] Skipped: No columns found or not a real table\n")
            return
        
        # Check if table is empty
        if my_var_intAS400Count == 0:
            with print_lock: print(f"[{my_var_strTimestamp}]   ⚠️ Table {my_var_strSanitizedAS400Table} skipped: Source table is empty")
            with my_var_objLogLock:
                with open(myCon_strLogFilePath, "a") as my_var_objLogFile:
                    my_var_objLogFile.write(f"[{my_var_strSanitizedAS400Table}] Skipped: Source table is empty\n")
            return
        
        # Prepare destination table
        #with print_lock: print(f"[{my_var_strTimestamp}]   Preparing destination table...")
        my_var_strDestTable = f"z_{my_var_strTableDesc}_____{my_var_strSanitizedAS400Table}"
        my_var_strDestTable = my_var_strDestTable.replace(" ", "_")  # Sanitize table name
        my_var_strDestTableEscaped = my_var_strDestTable.replace(']', ']]')
        #with print_lock: print(f"[{my_var_strTimestamp}]     Destination table: {my_var_strDestTableEscaped}")
        
        # Create column lists
        #with print_lock:(f"[{my_var_strTimestamp}]   on {my_var_strDestTableEscaped} Creating column lists...")
        my_var_lstAS400Cols = [col[0] for col in my_var_lstColumns]
        my_var_lstSQLCols = [f"[{col[1]}_____{col[0]}]" for col in my_var_lstColumns]
        my_var_strAS400ColList = ", ".join(my_var_lstAS400Cols)
        my_var_strSQLColList = ", ".join(my_var_lstSQLCols)
        my_var_strPlaceholders = ", ".join(["?"] * len(my_var_lstColumns))
        
        # Create column mapping
        my_var_lstColumnMapping = []
        for my_var_intIdx, (my_var_strAS400Name, my_var_strAS400Desc) in enumerate(my_var_lstColumns):
            my_var_lstColumnMapping.append({
                'as400_name': my_var_strAS400Name,
                'sql_name': f"{my_var_strAS400Desc}_____{my_var_strAS400Name}",
                'description': my_var_strAS400Desc,
                'position': my_var_intIdx + 1
            })
        
        # Truncate destination table
        with print_lock:  (f"[{my_var_strTimestamp}]    🗑️ on {my_var_strDestTableEscaped} Truncating destination table...")
        my_var_strTruncateSQL = f"TRUNCATE TABLE [{myCon_strSQLSchema}].[{my_var_strDestTableEscaped}]"
        #print(f"[{my_var_strTimestamp}]     Executing SQL: {my_var_strTruncateSQL}")
        my_var_objSQLCursor.execute(my_var_strTruncateSQL)
        my_var_objSQLConn.commit()
        with print_lock:(f"[{my_var_strTimestamp}]     {my_var_strDestTableEscaped}        Table truncated successfully")
        
        # Prepare insert statement
        with print_lock:(f"[{my_var_strTimestamp}]   ➕ {my_var_strDestTableEscaped}     Preparing insert statement...")
        my_var_strInsertSQL = f"INSERT INTO [{myCon_strSQLSchema}].[{my_var_strDestTableEscaped}] ({my_var_strSQLColList}) VALUES ({my_var_strPlaceholders})"
        with print_lock:(f"[{my_var_strTimestamp}]     Insert SQL prepared: {my_var_strInsertSQL}")
        
        # Process data in batches
        with print_lock: print(f"[{my_var_strTimestamp}]   ⬇️ Loading table {my_var_strSanitizedAS400Table}...")
        
        # Get total count from AS400
        my_var_objAS400Cursor.execute(f"SELECT COUNT(*) FROM {my_var_strQualifiedSource}")
        my_var_intAS400Count = my_var_objAS400Cursor.fetchone()[0]
        
        # Get total count from SQL Server
        my_var_objSQLCursor.execute(f"SELECT COUNT(*) FROM [{myCon_strSQLSchema}].[{my_var_strDestTableEscaped}]")
        my_var_intSQLCount = my_var_objSQLCursor.fetchone()[0]
        
        # Create progress bar
        with output_lock:
            my_var_objProgressBar = tqdm(
                total=my_var_intAS400Count,
                desc=f"Thread {my_var_intThreadId} - {my_var_strSanitizedAS400Table}",
                position=my_var_intThreadId % 10,
                leave=True,
                lock_args=(output_lock,)
            )
        
        # Get all data
        my_var_strSelectSQL = f"SELECT {my_var_strAS400ColList} FROM {my_var_strQualifiedSource}"
        print(f"[{my_var_strTimestamp}]     ⚙️⚙️data received.. inserting: {my_var_strQualifiedSource}")
        my_var_objAS400Cursor.execute(my_var_strSelectSQL)
        my_var_lstBatch = my_var_objAS400Cursor.fetchmany(myCon_intBatchSize)
        
        while my_var_lstBatch:
            try:
                my_var_lstBatch = fun_normalize_batch(my_var_lstBatch)
                with print_lock: print(f"   ➕ {my_var_strDestTableEscaped}     Inserting {len(my_var_lstBatch)} rows...", flush=True)

                with print_lock: print(f"[{my_var_strTimestamp}]     ⚙️⚙️ execute many: ", flush=True)
                my_var_objSQLCursor.timeout = 30  # 30 second timeout
                my_var_objSQLCursor.executemany(my_var_strInsertSQL, my_var_lstBatch)
                my_var_intTotalInserted += len(my_var_lstBatch)  # Update total inserted counter

                with print_lock: print(f"[{my_var_strTimestamp}]     ⚙️⚙️ commit: {my_var_strQualifiedSource}", flush=True)
                my_var_objSQLConn.commit()  # Commit the transaction after each batch
                with output_lock:
                    my_var_objProgressBar.update(len(my_var_lstBatch))
                my_var_lstBatch = my_var_objAS400Cursor.fetchmany(myCon_intBatchSize)
            except Exception as e:
                with print_lock:(f"[{my_var_strTimestamp}]     ❌ Error in batch: {str(e)}")
                raise
        
        # Close progress bar
        with output_lock:
            my_var_objProgressBar.close()
        
        # Get final row counts
        #print(f"[{my_var_strTimestamp}]   Getting final row counts...")
        # Select count from AS400
        my_var_objAS400Cursor.execute(f"SELECT COUNT(*) FROM {my_var_strQualifiedSource}")
        my_var_intFinalAS400Count = my_var_objAS400Cursor.fetchone()[0]
        
        # Select count from SQL Server
        my_var_intFinalSQLCount = fun_get_table_rowcount(my_var_objSQLCursor, myCon_strSQLSchema, my_var_strSanitizedSQLTable)
        
        # Check if row counts match and print appropriate icon
        if my_var_intFinalAS400Count == my_var_intFinalSQLCount:
            with print_lock:    print(f"[{my_var_strTimestamp}] ✅ {my_var_strSanitizedAS400Table}: Final Row counts match: AS400={my_var_intFinalAS400Count}, SQL={my_var_intFinalSQLCount}", flush=True)

        else:
            with my_var_objLogLock:
                with print_lock:(f"[{my_var_strTimestamp}]     ❌ {my_var_strSanitizedAS400Table}: Row count mismatch: AS400={my_var_intFinalAS400Count}, SQL={my_var_intFinalSQLCount}")
                with open(myCon_strLogFilePath, "a") as my_var_objLogFile:
                    my_var_objLogFile.write(f"[{my_var_strSanitizedAS400Table}] Row count mismatch: AS400={my_var_intFinalAS400Count}, SQL={my_var_intFinalSQLCount}\n")
            return
        
        # Update report
        #print(f"[{my_var_strTimestamp}]   Updating report...")
        with my_var_objReportLock:
            with open(myCon_strReportPath, "a") as my_var_objReportFile:
                my_var_objReportFile.write(f"{my_var_strSanitizedAS400Table},{my_var_strSanitizedSQLTable},{my_var_intAS400Count},{my_var_intSQLCount},{my_var_intFinalAS400Count},{my_var_intFinalSQLCount},{my_var_intTotalInserted}\n")
        #print(f"[{my_var_strTimestamp}]   Report updated successfully")
        
        #print(f"[{my_var_strTimestamp}]  ✅ Table {my_var_strSanitizedAS400Table} processing completed successfully")
        
    except Exception as e:
        my_var_strTimestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        with print_lock:(f"[{my_var_strTimestamp}] ❌ Table processing failed: {str(e)}")
        with my_var_objLogLock:
            with open(myCon_strLogFilePath, "a") as my_var_objLogFile:
                my_var_objLogFile.write(f"[{my_var_strSanitizedAS400Table}] Table processing failed: {str(e)}\n")
        if my_var_objSQLConn:
            my_var_objSQLConn.rollback()
    finally:
        #print(f"[{my_var_strTimestamp}]   Cleaning up resources...")
        if my_var_objAS400Cursor:
            my_var_objAS400Cursor.close()
        if my_var_objSQLCursor:
            my_var_objSQLCursor.close()
        if my_var_objAS400Conn:
            my_var_objAS400Conn.close()
        if my_var_objSQLConn:
            my_var_objSQLConn.close()
        #print(f"[{my_var_strTimestamp}]   Resources cleaned up")

def fun_normalize_batch(my_var_lstBatch):
    """
    Normalizes a batch of data for SQL Server insertion
    Args:
        my_var_lstBatch: List of tuples containing row data
    Returns:
        list: Normalized batch data
    """
    my_var_lstNormalized = []
    for my_var_row in my_var_lstBatch:
        my_var_lstNewRow = []
        for my_var_val in my_var_row:
            if isinstance(my_var_val, Decimal):
                my_var_lstNewRow.append(float(my_var_val))
            else:
                my_var_lstNewRow.append(my_var_val)
        my_var_lstNormalized.append(tuple(my_var_lstNewRow))
    return my_var_lstNormalized


if __name__ == "__main__":
    try:
        with print_lock:("\n🚀 Starting AS400 to SQL Server Migration")
        with print_lock:(f"📅 Start Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        
        # Create locks for thread safety
        my_var_objLogLock = threading.Lock()
        my_var_objReportLock = threading.Lock()
        
        # Open log file
        with open(myCon_strLogFilePath, "w", encoding="utf-8") as my_var_objLogFile:
            my_var_objLogFile.write(f"Migration started at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        
        # Create connections
        with print_lock:("\n🔌 Establishing database connections...")
        my_var_objAS400Conn = fun_connect_as400()
        my_var_objSQLConn = fun_connect_sql_server()
        
        if not my_var_objAS400Conn or not my_var_objSQLConn:
            raise Exception("Failed to establish database connections")
        
        # Create cursors
        my_var_objAS400Cursor = my_var_objAS400Conn.cursor()
        my_var_objSQLCursor = my_var_objSQLConn.cursor()
        
        # Run structure verification once before starting threads
        with print_lock:("\n🔍 Running structure verification...")
        my_var_boolStructSuccess, my_var_strStructMessage = myFunStructureVerification(
            my_var_objAS400Cursor,
            my_var_objSQLCursor
        )
        if not my_var_boolStructSuccess:
            raise Exception(f"Structure verification failed: {my_var_strStructMessage}")
        
        # Get list of tables to process
        with print_lock:("\n📋 Getting list of tables to process...")
        my_var_lstSQLTables = fun_get_z_tables_from_sqlserver(my_var_objSQLCursor, myCon_strSQLSchema)
        my_var_intTotalTables = len(my_var_lstSQLTables)
        
        if not my_var_lstSQLTables:
            raise Exception("No tables found to process")
        
        with print_lock:(f"Found {my_var_intTotalTables} tables to process")
        
        # Close initial connections as they will be created per thread
        my_var_objAS400Cursor.close()
        my_var_objSQLCursor.close()
        my_var_objAS400Conn.close()
        my_var_objSQLConn.close()
        
        # Create ThreadPoolExecutor
        with ThreadPoolExecutor(max_workers=myCon_intMaxThreads) as executor:
            # Submit all tables for processing
            futures = []
            for my_var_strSQLTable in my_var_lstSQLTables:
                # Remove z_ prefix to get AS400 table name and remove leading underscores
                my_var_strAS400Table = my_var_strSQLTable.split('_____')[-1].lstrip('_')
                my_var_tplTableInfo = (my_var_strAS400Table, my_var_strSQLTable)
                
                # Submit task to thread pool
                future = executor.submit(fun_process_table, my_var_tplTableInfo, my_var_objLogLock, my_var_objReportLock)
                futures.append(future)
            
            # Wait for all tasks to complete
            for future in futures:
                try:
                    future.result()  # This will raise any exceptions that occurred in the thread
                except Exception as e:
                    with print_lock:(f"\n❌ Error in table processing: {str(e)}")
                    fun_beep_error()
        
        with print_lock:("\n✅ Migration completed successfully!")
        with print_lock:(f"📅 End Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        
    except Exception as my_var_errException:
        with print_lock:(f"\n❌ Error during migration: {str(my_var_errException)}")
        traceback.print_exc()
        fun_beep_error()

