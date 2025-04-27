# -*- coding: utf-8 -*-
"""
COMPLETE DATABASE SYNCHRONIZATION SCRIPT
DOCUMENTATION: Synchronizes data between AS400 and MSSQL using year-based partitioning
               with automatic fiscal year column detection.
"""

# =============================================
# IMPORTS SECTION
# =============================================
import pyodbc
from tqdm import tqdm
import threading
from datetime import datetime
import traceback
from decimal import Decimal
import winsound
import time
from queue import Queue, Empty

# =============================================
# CONSTANTS SECTION
# =============================================
# Configuration dictionary
myDictConfig = {
    # AS400 settings
    'AS400': {
        'DSN': "METALNET",
        'UID': "ESAAVEDR",
        'PWD': "ESM25",
        'TIMEOUT': 30,
        'LIBRARY': "MW4FILE"
    },
    # SQL Server settings
    'SQL_SERVER': {
        'DRIVER': "{ODBC Driver 17 for SQL Server}",
        'SERVER': "database-3.c67ymu6q22o1.us-east-1.rds.amazonaws.com,1433",
        'DB': "SigmaTB",
        'UID': "admin",
        'PWD': "Er1c41234$",
        'SCHEMA': "mrs"
    },
    # Operation settings
    'BATCH_SIZE': 10000,
    'MAX_THREADS': 20,
    'MAX_RETRIES': 3,
    'RETRY_DELAY': 5,
    'LOG_FILE': "failed_inserts.log",
    'REPORT_FILE': "migration_report.csv"
}

# System constants
myConStrVbCrLf = "\r\n"
myConStrTimestampFormat = '%Y-%m-%d %H:%M:%S'

# =============================================
# CLASSES SECTION
# =============================================
class clsConnectionPool:
    """
    Thread-safe connection pool implementation.
    DOCUMENTATION: Manages database connections with pooling for efficient reuse.
    """
    def __init__(self, funCreator, varIntMaxSize=5):
        """
        Initialize connection pool
        INPUT: 
            funCreator - Function to create new connections
            varIntMaxSize - Maximum pool size
        """
        self.objQueuePool = Queue(varIntMaxSize)
        self.funCreateConnection = funCreator
        self.varIntMaxSize = varIntMaxSize
        self.objLockThread = threading.Lock()
        self.varIntConnectionsCreated = 0
        
        # Initialize pool with connections
        for _ in range(varIntMaxSize):
            self.sub_CreateAndAddConnection()

    def sub_CreateAndAddConnection(self):
        """Create a new connection and add it to the pool"""
        try:
            objNewConn = self.funCreateConnection()
            self.objQueuePool.put(objNewConn)
            with self.objLockThread:
                self.varIntConnectionsCreated += 1
        except Exception as varExcError:
            print(f"Failed to create connection: {str(varExcError)}")
            raise

    def fun_GetConnection(self):
        """Retrieve a connection from the pool with timeout"""
        try:
            return self.objQueuePool.get(timeout=30)
        except Empty:
            with self.objLockThread:
                if self.varIntConnectionsCreated < self.varIntMaxSize:
                    self.sub_CreateAndAddConnection()
                    return self.objQueuePool.get(timeout=30)
            raise Exception("Connection pool exhausted and max size reached")

    def sub_ReturnConnection(self, objConn):
        """Return a connection to the pool"""
        if objConn:
            try:
                objConn.rollback()
                self.objQueuePool.put(objConn)
            except Exception as varExcError:
                print(f"Error returning connection to pool: {str(varExcError)}")
                try:
                    objConn.close()
                except:
                    pass
                self.sub_CreateAndAddConnection()

    def sub_CloseAllConnections(self):
        """Close all connections in the pool"""
        while not self.objQueuePool.empty():
            try:
                objConn = self.objQueuePool.get_nowait()
                objConn.close()
            except:
                pass

# Global connection pool variables
myObjAs400Pool = None
myObjSqlPool = None

# =============================================
# FUNCTIONS SECTION
# =============================================
def fun_InitializeConnectionPools():
    """
    Initialize connection pools for AS400 and SQL Server.
    DOCUMENTATION: Creates thread-safe connection pools for both database systems.
    """
    global myObjAs400Pool, myObjSqlPool
    
    def fun_CreateAs400Connection():
        """Create a new AS400 connection"""
        fun_PrintStatus("", "Creating AS400 connection", "process")
        varStrConnString = f"DSN={myDictConfig['AS400']['DSN']};UID={myDictConfig['AS400']['UID']};PWD={myDictConfig['AS400']['PWD']};Timeout={myDictConfig['AS400']['TIMEOUT']}"
        return pyodbc.connect(varStrConnString, autocommit=False)
    
    def fun_CreateSqlConnection():
        """Create a new SQL Server connection"""
        fun_PrintStatus("", "Creating SQL connection", "process")
        varStrConnString = (
            f"DRIVER={myDictConfig['SQL_SERVER']['DRIVER']};"
            f"SERVER={myDictConfig['SQL_SERVER']['SERVER']};"
            f"DATABASE={myDictConfig['SQL_SERVER']['DB']};"
            f"UID={myDictConfig['SQL_SERVER']['UID']};"
            f"PWD={myDictConfig['SQL_SERVER']['PWD']};"
            "Encrypt=yes;TrustServerCertificate=yes;Connection Timeout=30;"
        )
        return pyodbc.connect(varStrConnString, autocommit=False)
    
    myObjAs400Pool = clsConnectionPool(fun_CreateAs400Connection, myDictConfig['MAX_THREADS'])
    myObjSqlPool = clsConnectionPool(fun_CreateSqlConnection, myDictConfig['MAX_THREADS'])

def fun_PrintStatus(varStrTableName, varStrStatus, varStrIcon):
    """
    Print formatted status message with timestamp and icon.
    INPUT:
        varStrTableName - Name of table being processed
        varStrStatus - Status message to display
        varStrIcon - Icon type for visual indication
    """
    varStrTimestamp = datetime.now().strftime(myConStrTimestampFormat)
    
    dictIcons = {
        "process":  "      ⚙️",
        "download": "   ⬇️",
        "insert":   "      ➕",
        "drop"  :   "   🗑️",
        "update":   "🔄",
        "success":  "✅",
        "failure":  "❌",
        "warning":  "⚠️",
        "info":     "ℹ️"  # Add this line for info messages
    }
    
    varStrIcon = dictIcons.get(varStrIcon, "❓")
    print(f"[{varStrTimestamp}] {varStrIcon} {varStrTableName.ljust(20)}: {varStrStatus}")

def fun_GetOneColumnMetadata(varObjAs400Cursor, varObjMSSQLCursor, varStrSchema, varStrTable):
    """
    Retrieve column names and descriptions with fallback to actual structure.
    INPUT:
        varObjAs400Cursor - AS400 cursor
        varObjMSSQLCursor - MSSQL cursor
        varStrSchema - Schema name
        varStrTable - Table name
    OUTPUT:
        List of tuples (column_name, column_description)
    """
    try:
        # First try to get metadata
        varObjAs400Cursor.execute(f"""
            SELECT COLUMN_NAME, COLUMN_TEXT FROM QSYS2.SYSCOLUMNS
            WHERE TABLE_SCHEMA = '{varStrSchema}' AND TABLE_NAME = '{varStrTable}'
            ORDER BY ORDINAL_POSITION
        """)
        varListMetadataCols = [
            (col[0].strip(), (col[1] or "").strip().replace(" ", "_").replace("'", "_").replace(']', ']]').replace('?', 'q')) 
            for col in varObjAs400Cursor.fetchall()
        ]
        
        # Get actual columns to verify
        varListActualCols = fun_GetActualColumnNames(varObjAs400Cursor, varStrSchema, varStrTable)
        
        if len(varListMetadataCols) != len(varListActualCols):
            fun_PrintStatus(varStrTable, "Metadata mismatch - Using actual column names", "warning")
            return [(col, col) for col in varListActualCols]
        
        return varListMetadataCols
    except Exception as varExcError:
        fun_PrintStatus(varStrTable, f"Metadata query failed: {str(varExcError)} - Using actual names", "warning")
        varListActualCols = fun_GetActualColumnNames(varObjAs400Cursor, varStrSchema, varStrTable)
        return [(col, col) for col in varListActualCols]

def fun_GetActualColumnNames(varObjCursor, varStrSchema, varStrTable):
    """
    Get actual column names from table structure.
    INPUT:
        varObjCursor - Database cursor
        varStrSchema - Schema name
        varStrTable - Table name
    OUTPUT:
        List of column names
    """
    try:
        varObjCursor.execute(f"SELECT * FROM {varStrSchema}.{varStrTable} WHERE 1=0")
        return [column[0] for column in varObjCursor.description]
    except Exception as varExcError:
        fun_PrintStatus(varStrTable, f"Error getting actual columns: {str(varExcError)}", "failure")
        return []

def fun_DetectFiscalYearColumn(varObjAs400Cursor, varStrSchema, varStrTable):
    """
    Detect fiscal year column by finding the first column ending with 'YY'
    INPUT:
        varObjAs400Cursor - AS400 database cursor
        varStrSchema - Schema name
        varStrTable - Table name
    OUTPUT:
        String - Name of fiscal year column or None if not found
    """
    try:
        varObjAs400Cursor.execute(f"""
            SELECT COLUMN_NAME 
            FROM QSYS2.SYSCOLUMNS 
            WHERE TABLE_SCHEMA = '{varStrSchema}' 
              AND TABLE_NAME = '{varStrTable}'
              AND COLUMN_NAME LIKE '%YY'
            ORDER BY ORDINAL_POSITION
        """)
        varObjResult = varObjAs400Cursor.fetchone()
        return varObjResult[0] if varObjResult else None
    except Exception as varExcError:
        fun_PrintStatus(varStrTable, f"Error detecting fiscal year column: {str(varExcError)}", "failure")
        return None

def fun_GetTableRowCountWithCondition(varObjCursor, varStrSchema, varStrTable, varStrCondition):
    """
    Get row count for a table with a specific condition.
    Handles MSSQL type conversion with proper column bracketing.
    """
    try:
        if varStrSchema == myDictConfig['AS400']['LIBRARY']:
            # AS400 query - no special handling needed
            varStrQuery = f"SELECT COUNT(*) FROM {varStrSchema}.{varStrTable} WHERE {varStrCondition}"
        else:
            # MSSQL query - parse condition and apply proper formatting
            varStrQuery = f"SELECT COUNT(*) FROM [{varStrSchema}].[{varStrTable}] WHERE "
            
            # Split compound conditions
            varListConditions = varStrCondition.split(" AND ")
            varListProcessedConditions = []
            
            for varStrSingleCondition in varListConditions:
                # Find comparison operator
                varStrOperator = None
                for op in ['<=', '>=', '<>', '!=', '=', '<', '>']:
                    if op in varStrSingleCondition:
                        varStrOperator = op
                        break
                
                if varStrOperator:
                    # Split into column and value parts
                    varStrCol, varStrValue = varStrSingleCondition.split(varStrOperator, 1)
                    varStrCol = varStrCol.strip()
                    
                    # Ensure column is properly bracketed
                    #if not varStrCol.startswith('['):
                    #    varStrCol = f"[{varStrCol.replace('.', '].[')}]"
                    
                    # Apply TRY_CAST to column
                    #varStrProcessedCondition = f"TRY_CAST({varStrCol} AS DECIMAL(18,2)) {varStrOperator} {varStrValue.strip()}"
                    varStrProcessedCondition = f"{varStrCol}  {varStrOperator} {varStrValue.strip()}"
                    varListProcessedConditions.append(varStrProcessedCondition)
                else:
                    # Keep non-comparison conditions as-is (with proper bracketing)
                    if '=' in varStrSingleCondition or ' ' in varStrSingleCondition:
                        parts = varStrSingleCondition.split(None, 1)
                        if not parts[0].startswith('['):
                            parts[0] = f"[{parts[0].replace('.', '].[')}]"
                        varStrSingleCondition = f"{parts[0]} {parts[1]}" if len(parts) > 1 else parts[0]
                    varListProcessedConditions.append(varStrSingleCondition)
            
            varStrQuery += " AND ".join(varListProcessedConditions)
        
        varObjCursor.execute(varStrQuery)
        return varObjCursor.fetchone()[0]
    except Exception as varExcError:
        fun_PrintStatus(varStrTable, f"Row count error for condition '{varStrCondition}': {str(varExcError)}", "failure")
        return -1


def fun_CompareRowCountPerYear(varObjAs400Cursor, varObjMSSQLCursor, varStrAs400Table, varStrSqlTable):
    """
    Compare row counts between AS400 and MSSQL tables per fiscal year.
    Returns dictionary with separate conditions for AS400 and MSSQL.
    
    INPUT:
        varObjAs400Cursor - AS400 database cursor
        varObjMSSQLCursor - MSSQL database cursor
        varStrAs400Table - Source table name in AS400
        varStrSqlTable - Destination table name in MSSQL
        
    OUTPUT:
        Dictionary with structure:
        {
            'Historical': {
                'as400_count': int,
                'mssql_count': int,
                'as400_condition': str,
                'mssql_condition': str,
                'needs_sync': bool,
                'as400_fiscal_col': str,
                'mssql_fiscal_col': str
            },
            'MidTerm': { ... },
            'Current': { ... }
        }
    """
    # Detect fiscal year column in AS400
    varStrAs400FiscalCol = fun_DetectFiscalYearColumn(
        varObjAs400Cursor,
        myDictConfig['AS400']['LIBRARY'],
        varStrAs400Table
    )
    
    if not varStrAs400FiscalCol:
        fun_PrintStatus(varStrAs400Table, "No fiscal year column found - using full table comparison", "warning")
        return {'FullTable': {'needs_sync': True}}
    
    # Find corresponding MSSQL column name
    varStrMssqlFiscalCol = None
    try:
        varObjMSSQLCursor.execute(f"""
            SELECT COLUMN_NAME 
            FROM INFORMATION_SCHEMA.COLUMNS 
            WHERE TABLE_SCHEMA = '{myDictConfig['SQL_SERVER']['SCHEMA']}'
              AND TABLE_NAME = '{varStrSqlTable}'
              AND COLUMN_NAME LIKE '%{varStrAs400FiscalCol}'
        """)
        varObjResult = varObjMSSQLCursor.fetchone()
        varStrMssqlFiscalCol = varObjResult[0] if varObjResult else None
    except Exception as varExcError:
        fun_PrintStatus(varStrSqlTable, f"Error finding MSSQL fiscal column: {str(varExcError)}", "failure")
    
    if not varStrMssqlFiscalCol:
        fun_PrintStatus(varStrSqlTable, f"No matching MSSQL column found for {varStrAs400FiscalCol}", "warning")
        return {'FullTable': {'needs_sync': True}}
    
    varIntCurrentYear = datetime.now().year

    listYearRanges = [
        ("Historical", 
        f"{varStrAs400FiscalCol} <= 12",
        f"TRY_CAST([{varStrMssqlFiscalCol}] AS DECIMAL(18,2)) <= 12")
    ]

    # Add individual years from 2012 to 2025 (or current year - 1)
    for year in range(2012, varIntCurrentYear):
        listYearRanges.append(
            (str(year),
            f"{varStrAs400FiscalCol} = {year - 2000}",  # AS400 uses 2-digit years
            f"TRY_CAST([{varStrMssqlFiscalCol}] AS DECIMAL(18,2)) = {year}")  # MSSQL uses 4-digit
        )

    # Add current year and beyond
    listYearRanges.append(
        ("Current and Future", 
        f"{varStrAs400FiscalCol} >= {varIntCurrentYear - 2000}",
        f"TRY_CAST([{varStrMssqlFiscalCol}] AS DECIMAL(18,2)) >= {varIntCurrentYear}")
    )    
    dictResults = {}
    for varStrLabel, varStrAs400Condition, varStrMssqlCondition in listYearRanges:
        # Get AS400 count
        varIntAs400Count = fun_GetTableRowCountWithCondition(
            varObjAs400Cursor, 
            myDictConfig['AS400']['LIBRARY'], 
            varStrAs400Table,
            varStrAs400Condition
        )
        
        # Get MSSQL count
        varIntMssqlCount = fun_GetTableRowCountWithCondition(
            varObjMSSQLCursor,
            myDictConfig['SQL_SERVER']['SCHEMA'],
            varStrSqlTable,
            varStrMssqlCondition
        )
        
        dictResults[varStrLabel] = {
            'as400_count': varIntAs400Count,
            'mssql_count': varIntMssqlCount,
            'as400_condition': varStrAs400Condition,
            'mssql_condition': varStrMssqlCondition,
            'needs_sync': varIntAs400Count != varIntMssqlCount,
            'as400_fiscal_col': varStrAs400FiscalCol,
            'mssql_fiscal_col': varStrMssqlFiscalCol
        }
    
    return dictResults

def fun_FullTableSync(varObjAs400Cursor, varObjMSSQLCursor, varStrAs400Table, varStrSqlTable, dictResults):
    """
    Perform full table sync when fiscal year column is not found
    """
    try:
        fun_PrintStatus(varStrAs400Table, "Starting full table sync", "process")
        
        # Get total count for progress bar
        varObjCountCursor = varObjAs400Cursor.connection.cursor()
        varObjCountCursor.execute(f"SELECT COUNT(*) FROM {myDictConfig['AS400']['LIBRARY']}.{varStrAs400Table}")
        varIntTotalRecords = varObjCountCursor.fetchone()[0]
        varObjCountCursor.close()
        
        # Truncate destination table
        varObjMSSQLCursor.execute(f"TRUNCATE TABLE [{myDictConfig['SQL_SERVER']['SCHEMA']}].[{varStrSqlTable}]")
        dictResults['rows_deleted'] = dictResults['initial_mssql_count']
        
        # Get column metadata
        varListColumns = fun_GetOneColumnMetadata(varObjAs400Cursor, varObjMSSQLCursor,
                                               myDictConfig['AS400']['LIBRARY'], varStrAs400Table)
        
        # Prepare for bulk insert
        varStrColNames = ", ".join([f"[{varTupleCol[1]}_____{varTupleCol[0]}]" for varTupleCol in varListColumns])
        varStrPlaceholders = ", ".join(["?"] * len(varListColumns))
        varIntBatchSize = myDictConfig['BATCH_SIZE']
        varIntTotalInserted = 0

        # Execute source query
        varObjAs400Cursor.execute(f"SELECT * FROM {myDictConfig['AS400']['LIBRARY']}.{varStrAs400Table}")

        with tqdm(total=varIntTotalRecords, desc=f"Inserting {varStrAs400Table}") as varObjProgressBar:
            while True:
                varListBatch = varObjAs400Cursor.fetchmany(varIntBatchSize)
                if not varListBatch:
                    break
                
                # Convert Decimal to float for MSSQL
                varListNormalizedBatch = [
                    tuple(
                        float(val) if isinstance(val, Decimal) else val
                        for val in row
                    )
                    for row in varListBatch
                ]
                
                # Bulk insert
                varObjMSSQLCursor.fast_executemany = True
                varObjMSSQLCursor.executemany(
                    f"""
                    INSERT INTO [{myDictConfig['SQL_SERVER']['SCHEMA']}].[{varStrSqlTable}]
                    ({varStrColNames}) VALUES ({varStrPlaceholders})
                    """,
                    varListNormalizedBatch
                )
                
                varIntTotalInserted += len(varListBatch)
                varObjProgressBar.update(len(varListBatch))
                
                # Commit periodically
                if varIntTotalInserted % (varIntBatchSize * 10) == 0:
                    varObjMSSQLCursor.connection.commit()
                    fun_PrintStatus(varStrAs400Table, 
                                   f"Inserted {varIntTotalInserted} of {varIntTotalRecords} records", 
                                   "update")

        # Final commit and update results
        varObjMSSQLCursor.connection.commit()
        dictResults['rows_inserted'] = varIntTotalInserted
        dictResults['final_as400_count'] = dictResults['initial_as400_count']
        dictResults['final_mssql_count'] = varIntTotalInserted
        
        # Print summary
        fun_PrintSyncSummary(dictResults)
        
        fun_PrintStatus(varStrAs400Table, "Full table sync completed", "success")
        return dictResults
        
    except Exception as varExcError:
        fun_PrintStatus(varStrAs400Table, f"Full sync failed: {str(varExcError)}", "failure")
        varObjMSSQLCursor.connection.rollback()
        dictResults['error'] = str(varExcError)
        return dictResults

def fun_CompareAndSyncTables(varObjAs400Cursor, varObjMSSQLCursor, varStrAs400Table, varStrSqlTable):
    """
    Compare and sync tables year by year with detailed reporting
    """
    # Initialize results dictionary with additional table_created flag
    dictResults = {
        'table_name': varStrAs400Table,
        'mssql_table': varStrSqlTable,
        'years': {},
        'initial_as400_count': 0,
        'initial_mssql_count': 0,
        'final_as400_count': 0,
        'final_mssql_count': 0,
        'rows_deleted': 0,
        'rows_inserted': 0,
        'table_created': False
    }

    try:
        # First check if MSSQL table exists
        fun_PrintStatus(varStrAs400Table, "Checking if destination table exists", "process")
        try:
            varObjMSSQLCursor.execute(f"""
                SELECT 1 FROM INFORMATION_SCHEMA.TABLES 
                WHERE TABLE_SCHEMA = '{myDictConfig['SQL_SERVER']['SCHEMA']}'
                AND TABLE_NAME = '{varStrSqlTable}'
            """)
            table_exists = varObjMSSQLCursor.fetchone() is not None
        except Exception as e:
            table_exists = False

        if not table_exists:
            fun_PrintStatus(varStrAs400Table, "Destination table not found - creating it", "process")
            
            # Get AS400 table structure (using numeric indices for compatibility)
            varObjAs400Cursor.execute(f"""
                SELECT COLUMN_NAME, DATA_TYPE, LENGTH 
                FROM QSYS2.SYSCOLUMNS 
                WHERE TABLE_SCHEMA = '{myDictConfig['AS400']['LIBRARY']}' 
                AND TABLE_NAME = '{varStrAs400Table}'
                ORDER BY ORDINAL_POSITION
            """)
            columns = varObjAs400Cursor.fetchall()
        
            # Create new table
        
            try:

                # Get verified column metadata
                varListCols = fun_GetOneColumnMetadata(varObjAs400Cursor, varObjMSSQLCursor, 
                                                    myDictConfig['AS400']['LIBRARY'], varStrAs400Table)
                
                # Verify against actual structure
                varListActualCols = fun_GetActualColumnNames(varObjAs400Cursor, myDictConfig['AS400']['LIBRARY'], varStrAs400Table)
                if len(varListCols) != len(varListActualCols):
                    fun_PrintStatus(varStrAs400Table, "Column count mismatch in rebuild - Using actual columns", "warning")
                    varListCols = [(col, col) for col in varListActualCols]
                    
                fun_PrintStatus(varStrSqlTable, "Creating destination table", "process")
                varStrCreateTableSql = f"""
                    CREATE TABLE [{myDictConfig['SQL_SERVER']['SCHEMA']}].[{varStrSqlTable}] (
                        {', '.join([f'[{col[1]}_____{col[0]}] NVARCHAR(MAX)' for col in varListCols])}
                    )
                    """
                varObjMSSQLCursor.execute(varStrCreateTableSql)
                varObjMSSQLCursor.connection.commit()

                # Execute creation and commit immediately
                dictResults['table_created'] = True
                fun_PrintStatus(varStrAs400Table, "Destination table created successfully", "success")
            except Exception as create_error:
                # If table was created by another process between our check and creation attempt
                if "already an object named" in str(create_error):
                    fun_PrintStatus(varStrAs400Table, "Table already exists (possibly created by another process)", "warning")
                else:
                    raise create_error  # Re-raise other errors

        # Get initial total counts
        #fun_PrintStatus(varStrAs400Table, "Getting initial row counts", "process")
        
        # AS400 total count
        varObjAs400Cursor.execute(f"SELECT COUNT(*) FROM {myDictConfig['AS400']['LIBRARY']}.{varStrAs400Table}")
        dictResults['initial_as400_count'] = varObjAs400Cursor.fetchone()[0]
        
        # MSSQL total count (will be 0 if table was just created)
        varObjMSSQLCursor.execute(f"SELECT COUNT(*) FROM [{myDictConfig['SQL_SERVER']['SCHEMA']}].[{varStrSqlTable}]")
        dictResults['initial_mssql_count'] = varObjMSSQLCursor.fetchone()[0]
        
        fun_PrintStatus(varStrAs400Table, 
                       f"Initial counts - AS400: {dictResults['initial_as400_count']}, MSSQL: {dictResults['initial_mssql_count']}", 
                       "info")

        ## If rowcount is equal, we skip
        if (dictResults['initial_as400_count'] == dictResults['initial_mssql_count']):
            fun_PrintStatus(varStrAs400Table, 
                        f"Initial counts are equal......... skipping...", 
                        "info")
            return dictResults

        # Rest of your original function remains unchanged...
        # Detect fiscal year column
        varStrFiscalYearCol = fun_DetectFiscalYearColumn(
            varObjAs400Cursor,
            myDictConfig['AS400']['LIBRARY'],
            varStrAs400Table
        )
        
        if not varStrFiscalYearCol:
            fun_PrintStatus(varStrAs400Table, "No fiscal year column found - performing full table sync", "warning")
            return fun_FullTableSync(varObjAs400Cursor, varObjMSSQLCursor, varStrAs400Table, varStrSqlTable, dictResults)

        # Find corresponding MSSQL fiscal year column
        varStrMssqlFiscalCol = None
        try:
            varObjMSSQLCursor.execute(f"""
                SELECT COLUMN_NAME 
                FROM INFORMATION_SCHEMA.COLUMNS 
                WHERE TABLE_SCHEMA = '{myDictConfig['SQL_SERVER']['SCHEMA']}'
                  AND TABLE_NAME = '{varStrSqlTable}'
                  AND COLUMN_NAME LIKE '%{varStrFiscalYearCol}'
            """)
            varObjResult = varObjMSSQLCursor.fetchone()
            varStrMssqlFiscalCol = varObjResult[0] if varObjResult else None
        except Exception as varExcError:
            fun_PrintStatus(varStrSqlTable, f"Error finding MSSQL fiscal column: {str(varExcError)}", "warning")

        # Define year ranges to process
        varIntCurrentYear = datetime.now().year
        listYearRanges = [
            ("Historical", f"{varStrFiscalYearCol} < 12"),  # Before 2012 (11 = 2011, 10 = 2010, etc.)
            ("2012", f"{varStrFiscalYearCol} = 12"),
            ("2013", f"{varStrFiscalYearCol} = 13"), 
            ("2014", f"{varStrFiscalYearCol} = 14"),
            ("2015", f"{varStrFiscalYearCol} = 15"),
            ("2016", f"{varStrFiscalYearCol} = 16"),
            ("2017", f"{varStrFiscalYearCol} = 17"),
            ("2018", f"{varStrFiscalYearCol} = 18"),
            ("2019", f"{varStrFiscalYearCol} = 19"),
            ("2020", f"{varStrFiscalYearCol} = 20"),
            ("2021", f"{varStrFiscalYearCol} = 21"),
            ("2022", f"{varStrFiscalYearCol} = 22"),
            ("2023", f"{varStrFiscalYearCol} = 23"),
            ("2024", f"{varStrFiscalYearCol} = 24"),
            ("Current", f"{varStrFiscalYearCol} = {varIntCurrentYear - 2000}"),  # Just current year
            ("Future", f"{varStrFiscalYearCol} > {varIntCurrentYear - 2000}")   # Future years
        ]

        # Process each year range
        for varStrLabel, varStrYearCondition in listYearRanges:
            # Get row counts for this year range
            varIntAs400Count = fun_GetTableRowCountWithCondition(
                varObjAs400Cursor,
                myDictConfig['AS400']['LIBRARY'],
                varStrAs400Table,
                varStrYearCondition
            )
            
            if varStrMssqlFiscalCol:
                varStrMssqlCondition = varStrYearCondition.replace(varStrFiscalYearCol, f"TRY_CAST([{varStrMssqlFiscalCol}] AS DECIMAL(18,2))")
            else:
                varStrMssqlCondition = "1=1"  # Fallback to all records if we can't map the column
            
            varIntMssqlCount = fun_GetTableRowCountWithCondition(
                varObjMSSQLCursor,
                myDictConfig['SQL_SERVER']['SCHEMA'],
                varStrSqlTable,
                varStrMssqlCondition
            )
            
            # Store year results
            dictResults['years'][varStrLabel] = {
                'as400_count': varIntAs400Count,
                'mssql_count': varIntMssqlCount,
                'synced': False
            }
            
            fun_PrintStatus(
                varStrAs400Table,
                f"{varStrLabel} {varStrYearCondition} year range - AS400: {varIntAs400Count}, MSSQL: {varIntMssqlCount}",
                "info"
            )

            # Only sync if counts differ
            if varIntAs400Count != varIntMssqlCount:
                fun_PrintStatus(varStrAs400Table, f"Counts differ - syncing {varStrLabel} year range", "failure")
                
                # Delete existing data for this year range in MSSQL
                if varStrMssqlFiscalCol:
                    varObjMSSQLCursor.execute(f"""
                        DELETE FROM [{myDictConfig['SQL_SERVER']['SCHEMA']}].[{varStrSqlTable}]
                        WHERE {varStrMssqlCondition}
                    """)
                    dictResults['rows_deleted'] += varIntMssqlCount

                # Commit after delete
                varObjMSSQLCursor.connection.commit()    
                
                # Insert fresh data from AS400
                varIntInserted = fun_BulkInsertYearRange(
                    varObjAs400Cursor,
                    varObjMSSQLCursor,
                    varStrAs400Table,
                    varStrSqlTable,
                    varStrYearCondition,
                    varStrFiscalYearCol
                )
                
                # Commit after insert
                varObjMSSQLCursor.connection.commit()
                dictResults['rows_inserted'] += varIntInserted
                dictResults['years'][varStrLabel]['synced'] = True
                dictResults['years'][varStrLabel]['rows_inserted'] = varIntInserted

        # Get final total counts
        fun_PrintStatus(varStrAs400Table, "Getting final row counts", "process")
        
        # AS400 total count
        varObjAs400Cursor.execute(f"SELECT COUNT(*) FROM {myDictConfig['AS400']['LIBRARY']}.{varStrAs400Table}")
        dictResults['final_as400_count'] = varObjAs400Cursor.fetchone()[0]
        
        # MSSQL total count
        varObjMSSQLCursor.execute(f"SELECT COUNT(*) FROM [{myDictConfig['SQL_SERVER']['SCHEMA']}].[{varStrSqlTable}]")
        dictResults['final_mssql_count'] = varObjMSSQLCursor.fetchone()[0]
        
        fun_PrintStatus(varStrAs400Table, 
                       f"Final counts - AS400: {dictResults['final_as400_count']}, MSSQL: {dictResults['final_mssql_count']}", 
                       "info")

        return dictResults

    except Exception as varExcError:
        fun_PrintStatus(varStrAs400Table, f"Sync failed: {str(varExcError)}", "failure")
        varObjMSSQLCursor.connection.rollback()
        dictResults['error'] = str(varExcError)
        return dictResults
    

def fun_BulkInsertYearRange(varObjAs400Cursor, varObjMSSQLCursor, varStrAs400Table, varStrSqlTable, varStrYearCondition, varStrFiscalYearCol):
    """
    Bulk insert data for a specific year range
    """
    # Get column metadata
    varListColumns = fun_GetOneColumnMetadata(varObjAs400Cursor, varObjMSSQLCursor,
                                           myDictConfig['AS400']['LIBRARY'], varStrAs400Table)
    
    # Get count for progress bar
    varObjCountCursor = varObjAs400Cursor.connection.cursor()
    varObjCountCursor.execute(f"""
        SELECT COUNT(*) 
        FROM {myDictConfig['AS400']['LIBRARY']}.{varStrAs400Table}
        WHERE {varStrYearCondition}
    """)
    varIntTotalRecords = varObjCountCursor.fetchone()[0]
    varObjCountCursor.close()

    # Prepare for bulk insert
    varStrColNames = ", ".join([f"[{varTupleCol[1]}_____{varTupleCol[0]}]" for varTupleCol in varListColumns])
    varStrPlaceholders = ", ".join(["?"] * len(varListColumns))
    varIntBatchSize = myDictConfig['BATCH_SIZE']
    varIntTotalInserted = 0

    # Execute source query
    varObjAs400Cursor.execute(f"""
        SELECT * 
        FROM {myDictConfig['AS400']['LIBRARY']}.{varStrAs400Table}
        WHERE {varStrYearCondition}
    """)

    with tqdm(total=varIntTotalRecords, desc=f"Inserting {varStrAs400Table} {varStrYearCondition}") as varObjProgressBar:
        while True:
            varListBatch = varObjAs400Cursor.fetchmany(varIntBatchSize)
            if not varListBatch:
                break
            
            # Convert Decimal to float for MSSQL
            varListNormalizedBatch = [
                tuple(
                    float(val) if isinstance(val, Decimal) else val
                    for val in row
                )
                for row in varListBatch
            ]
            
            # Bulk insert
            varObjMSSQLCursor.fast_executemany = True
            varObjMSSQLCursor.executemany(
                f"""
                INSERT INTO [{myDictConfig['SQL_SERVER']['SCHEMA']}].[{varStrSqlTable}]
                ({varStrColNames}) VALUES ({varStrPlaceholders})
                """,
                varListNormalizedBatch
            )
            
            varIntTotalInserted += len(varListBatch)
            varObjProgressBar.update(len(varListBatch))
            
            # Commit periodically
            if varIntTotalInserted % (varIntBatchSize * 10) == 0:
                varObjMSSQLCursor.connection.commit()
                fun_PrintStatus(varStrAs400Table, 
                              f"Inserted {varIntTotalInserted} of {varIntTotalRecords} records for {varStrYearCondition}", 
                              "update")

    # Final commit
    varObjMSSQLCursor.connection.commit()
    return varIntTotalInserted

def fun_PrintSyncSummary(dictResults):
    """
    Print detailed sync summary report
    """
    print("\n" + "="*80)
    print(f"SYNC SUMMARY REPORT - {dictResults['table_name']}")
    print("="*80)
    print(f"Source Table (AS400): {dictResults['table_name']}")
    print(f"Target Table (MSSQL): {dictResults['mssql_table']}")
    print("-"*80)
    print(f"Initial AS400 Count: {dictResults['initial_as400_count']}")
    print(f"Initial MSSQL Count: {dictResults['initial_mssql_count']}")
    print("-"*80)
    
    # Year range details
    print("\nYEAR RANGE SYNC DETAILS:")
    for varStrYearRange, dictYearData in dictResults['years'].items():
        print(f"\n{varStrYearRange}:")
        print(f"  AS400 Count: {dictYearData['as400_count']}")
        print(f"  MSSQL Count: {dictYearData['mssql_count']}")
        if dictYearData.get('synced', False):
            print(f"  ACTION: Synced ({dictYearData.get('rows_inserted', 0)} rows inserted)")
        else:
            print("  ACTION: No sync needed (counts matched)")
    
    print("\n" + "-"*80)
    print(f"Total Rows Deleted: {dictResults.get('rows_deleted', 0)}")
    print(f"Total Rows Inserted: {dictResults.get('rows_inserted', 0)}")
    print("-"*80)
    print(f"Final AS400 Count: {dictResults['final_as400_count']}")
    print(f"Final MSSQL Count: {dictResults['final_mssql_count']}")
    print("="*80 + "\n")

def fun_SyncTableByYear(varObjAs400Cursor, varObjMSSQLCursor, varStrAs400Table, varStrSqlTable, varStrSyncCondition, varStrFiscalYearCol):
    """
    Full year replacement approach - drops and recreates data for each year
    """
    try:
        # Get column metadata
        varListColumns = fun_GetOneColumnMetadata(varObjAs400Cursor, varObjMSSQLCursor,
                                               myDictConfig['AS400']['LIBRARY'], varStrAs400Table)
        
        # Get total count for progress bar
        varObjCountCursor = varObjAs400Cursor.connection.cursor()
        varObjCountCursor.execute(f"""
            SELECT COUNT(*) 
            FROM {myDictConfig['AS400']['LIBRARY']}.{varStrAs400Table}
            WHERE {varStrSyncCondition}
        """)
        varIntTotalRecords = varObjCountCursor.fetchone()[0]
        varObjCountCursor.close()

        # Delete existing data for this year range
        fun_PrintStatus(varStrAs400Table, "Clearing existing data for year range", "drop")
        
        # Find the fiscal year column in MSSQL
        varStrMssqlFiscalCol = None
        try:
            varObjMSSQLCursor.execute(f"""
                SELECT COLUMN_NAME 
                FROM INFORMATION_SCHEMA.COLUMNS 
                WHERE TABLE_SCHEMA = '{myDictConfig['SQL_SERVER']['SCHEMA']}'
                  AND TABLE_NAME = '{varStrSqlTable}'
                  AND COLUMN_NAME LIKE '%{varStrFiscalYearCol}'
            """)
            varObjResult = varObjMSSQLCursor.fetchone()
            varStrMssqlFiscalCol = varObjResult[0] if varObjResult else None
        except Exception as varExcError:
            fun_PrintStatus(varStrSqlTable, f"Error finding MSSQL fiscal column: {str(varExcError)}", "warning")
        
        if varStrMssqlFiscalCol:
            # Delete using the fiscal year condition
            varObjMSSQLCursor.execute(f"""
                DELETE FROM [{myDictConfig['SQL_SERVER']['SCHEMA']}].[{varStrSqlTable}]
                WHERE TRY_CAST([{varStrMssqlFiscalCol}] AS DECIMAL(18,2)) {
                    varStrSyncCondition.split(varStrFiscalYearCol)[1].strip()
                }
            """)
        else:
            # If we can't find the column, delete everything (full refresh)
            fun_PrintStatus(varStrSqlTable, "Fiscal column not found - performing full refresh", "warning")
            varObjMSSQLCursor.execute(f"""
                TRUNCATE TABLE [{myDictConfig['SQL_SERVER']['SCHEMA']}].[{varStrSqlTable}]
            """)

        # Insert fresh data for this year range
        fun_PrintStatus(varStrAs400Table, "Loading new data", "insert")
        varObjAs400Cursor.execute(f"""
            SELECT * 
            FROM {myDictConfig['AS400']['LIBRARY']}.{varStrAs400Table}
            WHERE {varStrSyncCondition}
        """)

        # Prepare for bulk insert
        varStrColNames = ", ".join([f"[{varTupleCol[1]}_____{varTupleCol[0]}]" for varTupleCol in varListColumns])
        varStrPlaceholders = ", ".join(["?"] * len(varListColumns))
        varIntBatchSize = myDictConfig['BATCH_SIZE']
        varIntTotalInserted = 0

        with tqdm(total=varIntTotalRecords, desc=f"Loading {varStrAs400Table}") as varObjProgressBar:
            while True:
                varListBatch = varObjAs400Cursor.fetchmany(varIntBatchSize)
                if not varListBatch:
                    break
                
                # Convert Decimal to float for MSSQL
                varListNormalizedBatch = [
                    tuple(
                        float(val) if isinstance(val, Decimal) else val
                        for val in row
                    )
                    for row in varListBatch
                ]
                
                # Bulk insert
                varObjMSSQLCursor.fast_executemany = True
                varObjMSSQLCursor.executemany(
                    f"""
                    INSERT INTO [{myDictConfig['SQL_SERVER']['SCHEMA']}].[{varStrSqlTable}]
                    ({varStrColNames}) VALUES ({varStrPlaceholders})
                    """,
                    varListNormalizedBatch
                )
                
                varIntTotalInserted += len(varListBatch)
                varObjProgressBar.update(len(varListBatch))
                
                # Commit periodically
                if varIntTotalInserted % (varIntBatchSize * 10) == 0:
                    varObjMSSQLCursor.connection.commit()
                    fun_PrintStatus(varStrAs400Table, 
                                  f"Inserted {varIntTotalInserted} of {varIntTotalRecords} records", 
                                  "update")

        # Final commit
        varObjMSSQLCursor.connection.commit()
        fun_PrintStatus(varStrAs400Table, 
                      f"Completed year range sync - Inserted {varIntTotalInserted} records", 
                      "success")
        
        return True
        
    except Exception as varExcError:
        fun_PrintStatus(varStrAs400Table, f"Sync failed: {str(varExcError)}", "failure")
        varObjMSSQLCursor.connection.rollback()
        return False    

def fun_RebuildTable(varObjAs400Cursor, varObjMSSQLCursor, varStrSqlTable, myDictConfig):
    """
    Rebuild destination table with verified column structure.
    INPUT:
        varObjAs400Cursor - AS400 cursor
        varObjMSSQLCursor - MSSQL cursor
        varStrSqlTable - Destination table name
        myDictConfig - Configuration dictionary
    OUTPUT:
        Tuple (table_name, column_list, placeholders) or None on failure
    """
    # Get source table name by removing prefix
    varStrAs400Table = varStrSqlTable.rsplit('_____', 1)[-1]
    
    try:
        # Get verified column metadata
        varListCols = fun_GetOneColumnMetadata(varObjAs400Cursor, varObjMSSQLCursor, 
                                             myDictConfig['AS400']['LIBRARY'], varStrAs400Table)
        
        # Verify against actual structure
        varListActualCols = fun_GetActualColumnNames(varObjAs400Cursor, myDictConfig['AS400']['LIBRARY'], varStrAs400Table)
        if len(varListCols) != len(varListActualCols):
            fun_PrintStatus(varStrAs400Table, "Column count mismatch in rebuild - Using actual columns", "warning")
            varListCols = [(col, col) for col in varListActualCols]
        
        # Drop destination table
        varObjMSSQLCursor.execute(f"DROP TABLE IF EXISTS [{myDictConfig['SQL_SERVER']['SCHEMA']}].[{varStrSqlTable}]")
        
        # Build column definitions
        varStrColList = ", ".join([f"[{col[1]}_____{col[0]}]" for col in varListCols])
        varStrPlaceholders = ", ".join(["?"] * len(varListCols))
        
        # Create new table
        fun_PrintStatus(varStrSqlTable, "Creating destination table", "process")
        varStrCreateTableSql = f"""
        CREATE TABLE [{myDictConfig['SQL_SERVER']['SCHEMA']}].[{varStrSqlTable}] (
            {', '.join([f'[{col[1]}_____{col[0]}] NVARCHAR(MAX)' for col in varListCols])}
        )
        """
        varObjMSSQLCursor.execute(varStrCreateTableSql)
        varObjMSSQLCursor.connection.commit()

        return varStrSqlTable, varStrColList, varStrPlaceholders
        
    except Exception as varExcError:
        fun_PrintStatus(varStrAs400Table, f"Rebuild failed: {str(varExcError)}", "failure")
        return None

def fun_ProcessTable(varTupleTableInfo, varObjLogLock, varObjReportLock):
    varObjAs400Conn = None
    varObjSqlConn = None
    
    try:
        varStrAs400Table, varStrSqlTable = varTupleTableInfo

        # Get connections
        varObjAs400Conn = myObjAs400Pool.fun_GetConnection()
        varObjSqlConn = myObjSqlPool.fun_GetConnection()
        
        with varObjLogLock:
            fun_PrintStatus(varStrSqlTable, f"\r\n\r\n===>Processing {varStrAs400Table} -> {varStrSqlTable}", "process")
        
        # Get cursors
        varObjAs400Cursor = varObjAs400Conn.cursor()
        varObjMSSQLCursor = varObjSqlConn.cursor()


        
        dictResults = fun_CompareAndSyncTables(
            varObjAs400Cursor,
            varObjMSSQLCursor,
            varStrAs400Table,
            varStrSqlTable)

##STOP HERE####################


#
#        # First try year-based sync
#        varDictYearResults = fun_CompareRowCountPerYear(
#            varObjAs400Cursor, 
#            varObjMSSQLCursor,
#            varStrAs400Table,
#            varStrSqlTable
#        )
#        
#        varBoolNeedsFullRebuild = False
#        
#        # Process each year range
#        for varStrLabel, varDictResult in varDictYearResults.items():
#            if varDictResult.get('needs_sync', True):
#                with varObjLogLock:
#                    fun_PrintStatus(varStrSqlTable, f"Syncing {varStrLabel} data", "update")
#                
#                # Use the correct condition based on the system
#                if not fun_SyncTableByYear(
#                    varObjAs400Cursor,
#                    varObjMSSQLCursor,
#                    varStrAs400Table,
#                    varStrSqlTable,
#                    varDictResult['as400_condition'],  # Use AS400 condition here
#                    varDictResult.get('as400_fiscal_col')
#                ):
#                    varBoolNeedsFullRebuild = True
#                    break
#        
#        # Fallback to full rebuild if needed
#        if varBoolNeedsFullRebuild:
#            with varObjLogLock:
#                fun_PrintStatus(varStrSqlTable, "Performing full table rebuild", "process")
#            
#            varTupleRebuildResult = fun_RebuildTable(
#                varObjAs400Cursor,
#                varObjMSSQLCursor,
#                varStrSqlTable,
#                myDictConfig
#            )
#            
#            if varTupleRebuildResult:
##                varStrDestTable, varStrColList, varStrPlaceholders = varTupleRebuildResult
 #               
 #               # Verify parameter count
 #               varIntParamCount = varStrPlaceholders.count('?')
 #               if varIntParamCount != len(fun_GetActualColumnNames(varObjAs400Cursor, myDictConfig['AS400']['LIBRARY'], varStrAs400Table)):
 #                   with varObjLogLock:
 #                       fun_PrintStatus(varStrAs400Table, 
 #                                     f"Parameter count mismatch: {varIntParamCount} vs expected", 
 #                                     "failure")
 ##                   return
  #              
  #              varStrInsertSql = f"INSERT INTO [{myDictConfig['SQL_SERVER']['SCHEMA']}].[{varStrDestTable}] ({varStrColList}) VALUES ({varStrPlaceholders})"
  #              
  #              # Process data in batches
  #              varObjAs400Cursor.execute(f"SELECT * FROM {myDictConfig['AS400']['LIBRARY']}.{varStrAs400Table}")
#                varIntTotalInserted = 0
#                
#                with tqdm(total=fun_GetTableRowCountWithCondition(varObjAs400Cursor, myDictConfig['AS400']['LIBRARY'], varStrAs400Table, "1=1"), 
#                      desc=f"Transferring {varStrAs400Table}") as varObjProgressBar:
#                    while True:
#                        varListBatch = varObjAs400Cursor.fetchmany(myDictConfig['BATCH_SIZE'])
#                        if not varListBatch:
#                            break
#                        
#                        # Normalize batch data
#                        varListNormalizedBatch = [
#                            tuple(
#                                float(varVal) if isinstance(varVal, Decimal) 
#                                else varVal 
#                                for varVal in varRow
##                            )
 #                           for varRow in varListBatch
 #                       ]
 #                       
 #                       # Process batch
 #                       varObjMSSQLCursor.fast_executemany = True
 #                       varObjMSSQLCursor.executemany(varStrInsertSql, varListNormalizedBatch)
 #                       varIntTotalInserted += len(varListBatch)
 #                       varObjSqlConn.commit()
 #                       varObjProgressBar.update(len(varListBatch))
 #               
 #               with varObjLogLock:
 #                   fun_PrintStatus(varStrAs400Table, f"Completed full rebuild - Inserted {varIntTotalInserted} rows", "success")
    
    except Exception as varExcError:
        with varObjLogLock:
            fun_PrintStatus(varStrAs400Table, f"Error: {str(varExcError)}", "failure")
            traceback.print_exc()
        if varObjSqlConn:
            varObjSqlConn.rollback()
    finally:
        if varObjAs400Conn:
            myObjAs400Pool.sub_ReturnConnection(varObjAs400Conn)
        if varObjSqlConn:
            myObjSqlPool.sub_ReturnConnection(varObjSqlConn)

# =============================================
# MAIN EXECUTION SECTION
# =============================================
if __name__ == "__main__":
    try:
        # Initialize
        varStrStartTime = datetime.now().strftime(myConStrTimestampFormat)
        print(f"[{varStrStartTime}] Starting execution")
        fun_PrintStatus("SYSTEM", "Starting migration process", "process")
        
        fun_InitializeConnectionPools()
        
        # Get list of tables to process
        varObjSqlConn = myObjSqlPool.fun_GetConnection()
        try:
            varObjCursor = varObjSqlConn.cursor()
            varListAllTables = []
            
            try:
                # Query the equivalents table
                varObjCursor.execute(
                    f"SELECT MSSQL_TableName, AS400_TableName "
                    f"FROM [{myDictConfig['SQL_SERVER']['SCHEMA']}].[01_AS400_MSSQL_Equivalents]"
                )
                
                for varTupleRow in varObjCursor.fetchall():
                    # Standardize table name format
                    varStrStandardizedName = f"z_____{varTupleRow[1]}" if not varTupleRow[0].startswith('z_') else varTupleRow[0]
                    varListAllTables.append((varTupleRow[1], varStrStandardizedName))
                    
                fun_PrintStatus("SYSTEM", f"Found {len(varListAllTables)} tables to process", "success")
                
            except Exception as varExcError:
                fun_PrintStatus("SYSTEM", f"Could not query equivalents table: {str(varExcError)}", "failure")
                varListAllTables = []

        finally:
            myObjSqlPool.sub_ReturnConnection(varObjSqlConn)
        
        # Process tables with threading
        varObjLogLock = threading.Lock()
        varObjReportLock = threading.Lock()
        varObjWorkQueue = Queue()
        
        # Populate work queue
        for varTupleTableInfo in varListAllTables:
            varObjWorkQueue.put(varTupleTableInfo)
        
        # Worker function - Improved version
        from queue import Empty

        def fun_Worker():
            while not varObjWorkQueue.empty():  # Check queue first
                try:
                    # Safely get item with timeout
                    varTupleTableInfo = varObjWorkQueue.get(block=True, timeout=0.5)  # Shorter timeout
                    
                    try:
                        fun_ProcessTable(varTupleTableInfo, varObjLogLock, varObjReportLock)
                    except Exception as e:
                        with varObjLogLock:
                            fun_PrintStatus("WORKER", f"Processing error: {str(e)}", "failure")
                    finally:
                        varObjWorkQueue.task_done()
                        del varTupleTableInfo  # Clean up
                        
                except Empty:
                    return  # Silent exit - no exception raised
                except Exception as e:
                    with varObjLogLock:
                        fun_PrintStatus("WORKER", f"Critical error: {str(e)}", "failure")
                    return
        
        # Start worker threads with improved error handling
        varListActiveThreads = []
        try:
            for _ in range(min(myDictConfig['MAX_THREADS'], len(varListAllTables))):
                varObjThread = threading.Thread(target=fun_Worker, daemon=True)
                varObjThread.start()
                varListActiveThreads.append(varObjThread)
            
            # Wait for completion with timeout
            varObjWorkQueue.join()
            
            # Additional check for thread completion
            for varObjThread in varListActiveThreads:
                varObjThread.join(timeout=5)  # 5 second timeout per thread
                
        except Exception as e:
            fun_PrintStatus("SYSTEM", f"Thread management error: {str(e)}", "failure")
        
        # Clean up with additional safety checks
        try:
            myObjAs400Pool.sub_CloseAllConnections()
            myObjSqlPool.sub_CloseAllConnections()
        except Exception as e:
            fun_PrintStatus("SYSTEM", f"Cleanup error: {str(e)}", "failure")
        
        varStrEndTime = datetime.now().strftime(myConStrTimestampFormat)
        print(f"[{varStrEndTime}] Execution completed")
        fun_PrintStatus("SYSTEM", "Migration completed successfully", "success")
        
    except Exception as varExcError:
        fun_PrintStatus("SYSTEM", f"Migration failed: {str(varExcError)}", "failure")
        traceback.print_exc()
        winsound.Beep(1000, 1000)
    finally:
        try:
            if 'myObjAs400Pool' in globals() and myObjAs400Pool:
                myObjAs400Pool.sub_CloseAllConnections()
            if 'myObjSqlPool' in globals() and myObjSqlPool:
                myObjSqlPool.sub_CloseAllConnections()
        except Exception as e:
            print(f"Final cleanup error: {str(e)}")