# -*- coding: utf-8 -*-
"""
OPTIMIZED MIGRATION SCRIPT WITH THREADING SUPPORT
FIXED PARAMETER MISMATCH ISSUE
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
# Configuration dictionary with optimized settings
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
    'MAX_THREADS': 1,
    'MAX_RETRIES': 3,
    'RETRY_DELAY': 5,
    'LOG_FILE': "failed_inserts.log",
    'REPORT_FILE': "migration_report.csv"
}

VBCRLF = "\r\n"

# =============================================
# CLASSES SECTION
# =============================================
class ConnectionPool:
    """
    Thread-safe connection pool implementation.
    """
    def __init__(self, creator, max_size=5):
        self._pool = Queue(max_size)
        self.creator = creator
        self.max_size = max_size
        self._lock = threading.Lock()
        self._connections_created = 0
        
        for _ in range(max_size):
            self._create_and_add_connection()

    def _create_and_add_connection(self):
        """Create a new connection and add it to the pool"""
        try:
            conn = self.creator()
            self._pool.put(conn)
            with self._lock:
                self._connections_created += 1
        except Exception as e:
            print(f"Failed to create connection: {str(e)}")
            raise

    def get_connection(self):
        """Retrieve a connection from the pool with timeout"""
        try:
            return self._pool.get(timeout=30)
        except Empty:
            with self._lock:
                if self._connections_created < self.max_size:
                    self._create_and_add_connection()
                    return self._pool.get(timeout=30)
            raise Exception("Connection pool exhausted and max size reached")

    def return_connection(self, conn):
        """Return a connection to the pool"""
        if conn:
            try:
                conn.rollback()
                self._pool.put(conn)
            except Exception as e:
                print(f"Error returning connection to pool: {str(e)}")
                try:
                    conn.close()
                except:
                    pass
                self._create_and_add_connection()

    def close_all(self):
        """Close all connections in the pool"""
        while not self._pool.empty():
            try:
                conn = self._pool.get_nowait()
                conn.close()
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
    
    myObjAs400Pool = ConnectionPool(fun_CreateAs400Connection, myDictConfig['MAX_THREADS'])
    myObjSqlPool = ConnectionPool(fun_CreateSqlConnection, myDictConfig['MAX_THREADS'])

def fun_GetTableRowCount(myObjCursor, myStrSchema, myStrTable):
    """
    Get row count for a table with error handling.
    """
    try:
        if myStrSchema == myDictConfig['AS400']['LIBRARY']:
            myObjCursor.execute(f"SELECT COUNT(*) FROM {myStrSchema}.{myStrTable}")
        else:
            myObjCursor.execute(f"SELECT COUNT(*) FROM [{myStrSchema}].[{myStrTable}]")
        return myObjCursor.fetchone()[0]
    except Exception as myErr:
        fun_PrintStatus(myStrTable, (f"    Row count error: {str(myErr)}"), "failure")
        return -1

def fun_PrintStatus(myStrTableName, myStrStatus, myStrIcon):
    """
    Print formatted status message with timestamp and icon.
    """
    varStrTimestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    
    icons = {
        "process":  "      ⚙️",
        "download": "   ⬇️",
        "insert":   "      ➕",
        "drop"  :   "   🗑️",
        "update":   "🔄",
        "success":  "✅",
        "failure":  "❌"
    }
    
    icon = icons.get(myStrIcon, "❓")
    print(f"[{varStrTimestamp}] CODE {myStrTableName.rsplit('_____', 1)[-1].ljust(9)} {icon} {myStrTableName.ljust(9)}: {myStrStatus}")

def fun_ProcessBatch(myObjSqlCursor, myStrInsertSql, myListBatch, myStrTableName, myIntRetryCount=0):
    """
    Process batch of records with retries and parameter validation.
    """
    try:
        # Verify parameter count matches
        expected_params = myStrInsertSql.count('?')
        actual_params = len(myListBatch[0]) if myListBatch else 0
        
        if expected_params != actual_params: raise ValueError(f"Parameter mismatch: SQL expects {expected_params} but got {actual_params}")

        myObjSqlCursor.connection.timeout = 60
        myObjSqlCursor.fast_executemany = True

        #fun_PrintStatus(myStrTableName, f"Inserting batch of {len(myListBatch)}", "insert")
        
        # Debug output (comment out in production)
        # print(f"Sample row: {myListBatch[0] if myListBatch else 'Empty batch'}")
        # print(f"Insert SQL: {myStrInsertSql}")

        myObjSqlCursor.executemany(myStrInsertSql, myListBatch)
        return True
    except pyodbc.Error as myErr:
        if myIntRetryCount < myDictConfig['MAX_RETRIES']:
            print(f"Retrying batch for {myStrTableName} (attempt {myIntRetryCount + 1})")
            time.sleep(myDictConfig['RETRY_DELAY'] * (myIntRetryCount + 1))
            return fun_ProcessBatch(myObjSqlCursor, myStrInsertSql, myListBatch, myStrTableName, myIntRetryCount + 1)
        print(f"Failed batch for {myStrTableName} after {myDictConfig['MAX_RETRIES']} retries: {str(myErr)}")
        return False
    except Exception as myErr:
        print(f"Unexpected error processing batch for {myStrTableName}: {str(myErr)}")
        return False

def fun_GetActualColumnNames(myObjCursor, myStrSchema, myStrTable):
    """
    Get actual column names from table structure.
    """
    try:
        myObjCursor.execute(f"SELECT * FROM {myStrSchema}.{myStrTable} WHERE 1=0")
        return [column[0] for column in myObjCursor.description]
    except Exception as e:
        print(f"Error getting actual columns: {str(e)}")
        return []

def fun_GetOneColumnMetadata(varObjAS400Cursor, varObjMSSQLCursor, myStrSchema, myStrTable):
    """
    Retrieve column names and descriptions with fallback to actual structure.
    """
    try:
        # First try to get metadata
        varObjAS400Cursor.execute(f"""
            SELECT COLUMN_NAME, COLUMN_TEXT FROM QSYS2.SYSCOLUMNS
            WHERE TABLE_SCHEMA = '{myStrSchema}' AND TABLE_NAME = '{myStrTable}'
            ORDER BY ORDINAL_POSITION
        """)
        metadata_cols = [(col[0].strip(), (col[1] or "").strip().replace(" ", "_").replace("'", "_").replace(']', ']]').replace('?', 'q')) 
        for col in varObjAS400Cursor.fetchall()]
        
        # Get actual columns to verify
        actual_cols = fun_GetActualColumnNames(varObjAS400Cursor, myStrSchema, myStrTable)
        
        if len(metadata_cols) != len(actual_cols):
            print(f"Metadata mismatch: Using actual column names instead")
            return [(col, col) for col in actual_cols]
        
        return metadata_cols
    except Exception as e:
        print(f"Metadata query failed: {str(e)} - Using actual column names")
        actual_cols = fun_GetActualColumnNames(varObjAS400Cursor, myStrSchema, myStrTable)
        return [(col, col) for col in actual_cols]

def fun_NormalizeBatch(myListBatch):
    """
    Normalize batch data by converting Decimals to floats.
    """
    return [
        tuple(
            float(myVal) if isinstance(myVal, Decimal) 
            else myVal 
            for myVal in myRow
        )
        for myRow in myListBatch
    ]

def myfunRebuildTable(varObjAs400Cursor, varObjMSSQLCursor, varStrSqlTable, myDictConfig):
    """
    Rebuild destination table with verified column structure.
    """
    # Get source table name by removing prefix
    varStrAs400Table = varStrSqlTable.rsplit('_____', 1)[-1]
    
    # Get verified column metadata
    varListCols = fun_GetOneColumnMetadata(varObjAs400Cursor, varObjMSSQLCursor, 
                                         myDictConfig['AS400']['LIBRARY'], varStrAs400Table)
    
    # Verify against actual structure
    actual_cols = fun_GetActualColumnNames(varObjAs400Cursor, myDictConfig['AS400']['LIBRARY'], varStrAs400Table)
    if len(varListCols) != len(actual_cols):
        print(f"Column count mismatch in rebuild: Using actual columns")
        varListCols = [(col, col) for col in actual_cols]
    
    # Here we need to modify
    #   varIntAs400Count and varIntSqlCount do not match, so we can
    #       a) either drop the destination table and copy all from scratch
    #       b) compare rowcount by year, to verify that the difference on rowcount 
    #       is due only to this year work, and avoiding copying previous years
    #   So, we will query  
    #            fun_GetTableRowCount(varObjAs400Cursor, myDictConfig['AS400']['LIBRARY'], varStrAs400Table)
    #                per year  
    #       Years:  
    #           2012 or less                -- Beginning of operations
    #           2013 to (this year - 1)     -- Beginning to last year. Should no have change
    #           (this year + 1)             -- This year and future. May have changes 
    #
    #       Algorithm 
    #           if fun_GetTableRowCount(varObjAs400Cursor, myDictConfig['AS400']['LIBRARY'], varStrAs400Table) 
    #               (varIntAs400Count = varIntSqlCount) No change on year, then skip to next year 
    #               (varIntAs400Count < varIntSqlCount) Destination has more than source. Rebuild the table 
    #               (varIntAs400Count < varIntSqlCount)
    #
    #
    #
    #
    #
    #
    #

    # Drop destination table
    varObjMSSQLCursor.execute(f"DROP TABLE IF EXISTS [{myDictConfig['SQL_SERVER']['SCHEMA']}].[{varStrSqlTable}]")
    
    # Build column definitions
    varStrColList = ", ".join([f"[{col[1]}_____{col[0]}]" for col in varListCols])
    varStrPlaceholders = ", ".join(["?"] * len(varListCols))
    
    # Create new table
    #fun_PrintStatus(varStrSqlTable, "Creating destination table", "process")
    varStrCreateTableSql = f"""
    CREATE TABLE [{myDictConfig['SQL_SERVER']['SCHEMA']}].[{varStrSqlTable}] (
        {', '.join([f'[{col[1]}_____{col[0]}] NVARCHAR(MAX)' for col in varListCols])}
    )
    """
    varObjMSSQLCursor.execute(varStrCreateTableSql)
    varObjMSSQLCursor.connection.commit()

    return varStrSqlTable, varStrColList, varStrPlaceholders

def fun_ProcessTable(myTupleTableInfo, myObjLogLock, myObjReportLock):
    """
    Process table migration with parameter validation.
    """
    varObjAs400Conn = None
    varObjSqlConn = None
    
    try:
        varStrAs400Table, varStrSqlTable = myTupleTableInfo
        
        # Get connections
        varObjAs400Conn = myObjAs400Pool.get_connection()
        varObjSqlConn = myObjSqlPool.get_connection()
        
        #with myObjLogLock:
            #fun_PrintStatus(varStrSqlTable, f"Processing {varStrAs400Table} -> {varStrSqlTable}", "process")
        
        # Get cursors
        varObjAs400Cursor = varObjAs400Conn.cursor()
        varObjMSSQLCursor = varObjSqlConn.cursor()
        
        # Get verified column metadata
        varListCols = fun_GetOneColumnMetadata(varObjAs400Cursor, varObjMSSQLCursor, 
                                             myDictConfig['AS400']['LIBRARY'], varStrAs400Table)
        
        # Verify against actual structure
        actual_cols = fun_GetActualColumnNames(varObjAs400Cursor, myDictConfig['AS400']['LIBRARY'], varStrAs400Table)
        if len(varListCols) != len(actual_cols):
            with myObjLogLock:
                fun_PrintStatus(varStrAs400Table, 
                              f"Column count mismatch: metadata={len(varListCols)} vs actual={len(actual_cols)}", 
                              "failure")
            varListCols = [(col, col) for col in actual_cols]
        
        # Get row counts
        varIntAs400Count = fun_GetTableRowCount(varObjAs400Cursor, myDictConfig['AS400']['LIBRARY'], varStrAs400Table)
        varIntSqlCount = fun_GetTableRowCount(varObjMSSQLCursor, myDictConfig['SQL_SERVER']['SCHEMA'], varStrSqlTable)
        
        # Skip if counts match
        if varIntAs400Count == varIntSqlCount:
            with myObjLogLock:
                fun_PrintStatus(varStrAs400Table, f"Skipping - counts match {varIntAs400Count} = {varIntSqlCount}", "success")
            return
        else    #Rows dont match
                fun_PrintStatus(varStrAs400Table, f"Counts don't match {varIntAs400Count} = {varIntSqlCount}", "success")

        # Rebuild table if counts don't match
        #with myObjLogLock:
            #fun_PrintStatus(varStrSqlTable, f"Rebuilding table (AS400={varIntAs400Count} vs SQL={varIntSqlCount})", "drop")
        
        varStrDestTable, varStrColList, varStrPlaceholders = myfunRebuildTable(
            varObjAs400Cursor, varObjMSSQLCursor, varStrSqlTable, myDictConfig
        )

        # Verify parameter count
        varIntParamCount = varStrPlaceholders.count('?')
        if varIntParamCount != len(actual_cols):
            with myObjLogLock:
                fun_PrintStatus(varStrAs400Table, 
                              f"Parameter count mismatch: {varIntParamCount} placeholders vs {len(actual_cols)} columns", 
                              "failure")
            return

        varStrInsertSql = f"INSERT INTO [{myDictConfig['SQL_SERVER']['SCHEMA']}].[{varStrDestTable}] ({varStrColList}) VALUES ({varStrPlaceholders})"
        
        # Process data in batches
        varObjAs400Cursor.execute(f"SELECT * FROM {myDictConfig['AS400']['LIBRARY']}.{varStrAs400Table}")
        varIntTotalInserted = 0
        
        with tqdm(total=varIntAs400Count, desc=f"                      Transfering {varStrAs400Table}") as pbar:
            while True:
                varListBatch = varObjAs400Cursor.fetchmany(myDictConfig['BATCH_SIZE'])
                if not varListBatch:
                    break
                
                # Validate each row
                for row in varListBatch:
                    if len(row) != len(actual_cols):
                        with myObjLogLock:
                            fun_PrintStatus(varStrAs400Table, 
                                          f"Row has {len(row)} columns but expected {len(actual_cols)}", 
                                          "failure")
                        raise ValueError("Column count mismatch in data row")
                
                varListNormalizedBatch = fun_NormalizeBatch(varListBatch)
                
                if fun_ProcessBatch(varObjMSSQLCursor, varStrInsertSql, varListNormalizedBatch, varStrAs400Table):
                    varIntTotalInserted += len(varListBatch)
                    varObjSqlConn.commit()
                    pbar.update(len(varListBatch))
                else:
                    varObjSqlConn.rollback()
                    break
        
        with myObjLogLock:
            fun_PrintStatus(varStrAs400Table, f"Completed - Inserted {varIntTotalInserted} rows", "success")
        
    except Exception as myErr:
        with myObjLogLock:
            fun_PrintStatus(varStrAs400Table, f"Error: {str(myErr)}", "failure")
            traceback.print_exc()
        if varObjSqlConn:
            varObjSqlConn.rollback()
    finally:
        if varObjAs400Conn:
            myObjAs400Pool.return_connection(varObjAs400Conn)
        if varObjSqlConn:
            myObjSqlPool.return_connection(varObjSqlConn)

# =============================================
# MAIN EXECUTION SECTION
# =============================================
if __name__ == "__main__":
    try:
        # Initialize
        fun_PrintStatus("SYSTEM", "Starting migration process", "process")
        fun_InitializeConnectionPools()
        
        # Get list of tables to process from both sources
        varObjSqlConn = myObjSqlPool.get_connection()
        try:
            varObjCursor = varObjSqlConn.cursor()
            # Initialize list
            varListAllTables = []
            
            try:
                # Query only the equivalents table
                varObjCursor.execute(
                    f"SELECT MSSQL_TableName, AS400_TableName "
                    f"FROM [{myDictConfig['SQL_SERVER']['SCHEMA']}].[01_AS400_MSSQL_Equivalents]"
                )
                
                for mssql_table, as400_table in varObjCursor.fetchall():
                    # Standardize table name format if needed
                    standardized_name = f"z_____{as400_table}" if not mssql_table.startswith('z_') else mssql_table
                    varListAllTables.append(standardized_name)
            except Exception as e:
                fun_PrintStatus("SYSTEM", f"Could not query 01_AS400_MSSQL_Equivalents: {str(e)}", "failure")

            print(f"Found {len(varListAllTables)} tables to process from equivalents table")

        finally:
            myObjSqlPool.return_connection(varObjSqlConn)
        
        # Process tables with threading
        varObjLogLock = threading.Lock()
        varObjReportLock = threading.Lock()
        work_queue = Queue()
        
        # Populate work queue
        for varThisStr_MSSQL_Table in varListAllTables:
            # Extract AS400 table name - handles both "z_____{AS400NAME}" format and other formats
            if varThisStr_MSSQL_Table.startswith('z_'):
                varStrAs400Table = varThisStr_MSSQL_Table.rsplit('_____', 1)[-1]
            else:
                varStrAs400Table = varThisStr_MSSQL_Table  # or use a different extraction method if needed
                
            work_queue.put((varStrAs400Table, varThisStr_MSSQL_Table))
        
        # Rest of your existing code remains the same...
        # Worker function
        def worker():
            while True:
                try:
                    table_info = work_queue.get_nowait()
                    fun_ProcessTable(table_info, varObjLogLock, varObjReportLock)
                    work_queue.task_done()
                except Empty:
                    break
                except Exception as e:
                    with varObjLogLock:
                        fun_PrintStatus("WORKER", f"Thread failed: {str(e)}", "failure")
                    break
        
        # Start worker threads
        varListActiveThreads = []
        for _ in range(myDictConfig['MAX_THREADS']):
            thread = threading.Thread(target=worker, daemon=True)
            thread.start()
            varListActiveThreads.append(thread)
        
        # Wait for completion
        work_queue.join()
        for thread in varListActiveThreads:
            thread.join()
        
        # Clean up
        myObjAs400Pool.close_all()
        myObjSqlPool.close_all()
        fun_PrintStatus("SYSTEM", "Migration completed successfully", "success")
        
    except Exception as myErr:
        fun_PrintStatus("SYSTEM", f"Migration failed: {str(myErr)}", "failure")
        traceback.print_exc()
        winsound.Beep(1000, 1000)
    finally:
        if myObjAs400Pool:
            myObjAs400Pool.close_all()
        if myObjSqlPool:
            myObjSqlPool.close_all()
        if myObjAs400Pool:
            myObjAs400Pool.close_all()
        if myObjSqlPool:
            myObjSqlPool.close_all()