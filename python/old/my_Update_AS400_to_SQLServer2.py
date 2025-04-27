# -*- coding: utf-8 -*-
"""
OPTIMIZED MIGRATION SCRIPT WITH THREADING SUPPORT
MAJOR IMPROVEMENTS:
1. Fixed SQL Server connection string with explicit port
2. Added proper transaction management
3. Implemented connection pooling
4. Optimized batch processing
5. Added detailed error handling
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
from queue import Queue

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
        'SERVER': "database-3.c67ymu6q22o1.us-east-1.rds.amazonaws.com,1433",  # Fixed with port
        'DB': "SigmaTB",
        'UID': "admin",
        'PWD': "Er1c41234$",
        'SCHEMA': "mrs"
    },
    # Operation settings
    'BATCH_SIZE': 10000,  # Reduced from 10000 for better memory management
    'MAX_THREADS': 1,    # Reduced from 20 to avoid connection pool exhaustion
    'MAX_RETRIES': 3,
    'RETRY_DELAY': 5,
    'LOG_FILE': "failed_inserts.log",
    'REPORT_FILE': "migration_report.csv"
}

VBCRLF = "\r\n"

# Global connection pool variables
myObjAs400Pool = None
myObjSqlPool = None

# =============================================
# CLASSES SECTION
# =============================================
class ConnectionPool:
    """
    Connection pool implementation for managing database connections.
    Variables:
        _pool (Queue): Queue holding the connections
        creator (function): Function to create new connections
    """
    def __init__(self, creator, max_size=5):
        self._pool = Queue(max_size)
        self.creator = creator
        for _ in range(max_size):
            self._pool.put(creator())

    def get_connection(self):
        """Retrieve a connection from the pool"""
        return self._pool.get()

    def return_connection(self, conn):
        """Return a connection to the pool"""
        self._pool.put(conn)

# =============================================
# FUNCTIONS SECTION
# =============================================
def fun_InitializeConnectionPools():
    """
    Initialize connection pools for AS400 and SQL Server.
    No parameters.
    Returns: None
    """
    global myObjAs400Pool, myObjSqlPool
    
    def fun_CreateAs400Connection():
        """Create a new AS400 connection"""
        print(f"...AS400")
        varStrConnString = f"DSN={myDictConfig['AS400']['DSN']};UID={myDictConfig['AS400']['UID']};PWD={myDictConfig['AS400']['PWD']};Timeout={myDictConfig['AS400']['TIMEOUT']}"
        return pyodbc.connect(varStrConnString, autocommit=False)
    
    def fun_CreateSqlConnection():
        """Create a new SQL Server connection"""
        print(f"...MSSQL")
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
    Parameters:
        myObjCursor: Database cursor object
        myStrSchema: Schema name
        myStrTable: Table name
    Returns: Integer count of rows or -1 on error
    """
    try:
        # Check if we're querying AS/400 (MW4FILE) or SQL Server (mrs)
        if myStrSchema == myDictConfig['AS400']['LIBRARY']:
            # AS/400 syntax
            #print(f"Checking values for AS400 schema.table {myStrSchema}.{myStrTable}")
            myObjCursor.execute(f"SELECT COUNT(*) FROM {myStrSchema}.{myStrTable}")
        else:
            # SQL Server syntax
            #print(f"Checking values for MSSQL schema.table {myStrSchema}.{myStrTable}")
            myObjCursor.execute(f"SELECT COUNT(*) FROM [{myStrSchema}].[{myStrTable}]")
        return myObjCursor.fetchone()[0]
    except Exception as myErr:
        fun_PrintStatus({myStrTable}, (f"    Row count error: {str(myErr)}"), "failure" )
        return -1

def fun_PrintStatus(myStrTableName, myStrStatus, myStrIcon):
    """
    Print formatted status message with timestamp and icon.
    Parameters:
        myStrTableName: Name of table being processed
        myStrStatus: Status message text
        myStrIcon: Icon type (process, download, insert, etc.)
    Returns: None
    """
    varStrTimestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    
    if myStrIcon == "process":
        print(f"[{varStrTimestamp}]              ⚙️ Processing {myStrTableName}.......{myStrStatus}")
    elif myStrIcon == "download":
        print(f"[{varStrTimestamp}]         ⬇️ Downloading {myStrTableName}.......{myStrStatus}")
    elif myStrIcon == "insert":
        print(f"[{varStrTimestamp}]         ➕ Inserting into {myStrTableName}.......{myStrStatus}")
    elif myStrIcon == "drop":
        print(f"[{varStrTimestamp}]         🗑️ Dropping {myStrTableName}.......{myStrStatus}")
    elif myStrIcon == "update":
        print(f"[{varStrTimestamp}]         🔄 Updating {myStrTableName}.......{myStrStatus}")
    elif myStrIcon == "success":
        print(f"[{varStrTimestamp}]    ✅ Success with {myStrTableName}.......{myStrStatus}")
    elif myStrIcon == "failure":
        print(f"[{varStrTimestamp}]    ❌ Failure with {myStrTableName}.......{myStrStatus}")
    else:
        print(f"[{varStrTimestamp}]    ❓ Unknown status for {myStrTableName}.......{myStrStatus}")

def fun_ProcessBatch(myObjSqlCursor, myStrInsertSql, myListBatch, myStrTableName, myIntRetryCount=0):
    """
    Process batch of records with retries and timeout.
    Parameters:
        myObjSqlCursor: SQL Server cursor object
        myStrInsertSql: SQL insert statement
        myListBatch: List of records to insert
        myStrTableName: Name of table being processed
        myIntRetryCount: Current retry attempt (default 0)
    Returns: Boolean indicating success
    """
    try:
        # Set timeout on the connection
        myObjSqlCursor.connection.timeout = 60
        myObjSqlCursor.fast_executemany = True

        fun_PrintStatus(myStrTableName, f"inserted {len(myListBatch)}", "process")

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

def fun_GetOneColumnMetadata(varObjAS400Cursor, varObjMSSQLCursor, myStrSchema, myStrTable):
    """
    Retrieve column names and descriptions from AS/400.
    Parameters:
        myObjCursor: AS400 cursor object
        myStrSchema: Schema name
        myStrTable: Table name
    Returns: List of tuples (column_name, column_description)
    """
    varObjAS400Cursor.execute(f"""
        SELECT COLUMN_NAME, COLUMN_TEXT FROM QSYS2.SYSCOLUMNS
        WHERE TABLE_SCHEMA = '{myStrSchema}' AND TABLE_NAME = '{myStrTable}'
    """)
    return [(col[0].strip(), (col[1] or "").strip().replace(" ", "_").replace("'", "_").replace(']', ']]')) for col in varObjAS400Cursor.fetchall()]

def fun_NormalizeBatch(myListBatch):
    """
    Normalize batch data by converting Decimals to floats.
    Parameters:
        myListBatch: List of records to normalize
    Returns: Normalized batch data
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
    # Drop destination table if counts don't match
    
    varObjMSSQLCursor.execute(f"DROP TABLE IF EXISTS [{myDictConfig['SQL_SERVER']['SCHEMA']}].[{varStrSqlTable}]")
    #varObjSqlConn.commit()
            
    # Prepare destination table
    varStrDestTable = f"{varStrSqlTable}"
    varListCols = fun_GetOneColumnMetadata(varObjAs400Cursor, varObjMSSQLCursor, myDictConfig['AS400']['LIBRARY'], varStrAs400Table)
    varStrColList = ", ".join([f"[{col[1]}_____{col[0]}]" for col in varListCols])
    varStrPlaceholders = ", ".join(["?"] * len(varListCols))
        
    # Create the destination table
    fun_PrintStatus({varStrDestTable}, "Creating destination table", "process")
    varStrCreateTableSql = f"""
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = '{varStrDestTable}' AND schema_id = SCHEMA_ID('{myDictConfig['SQL_SERVER']['SCHEMA']}'))
    BEGIN
        CREATE TABLE [{myDictConfig['SQL_SERVER']['SCHEMA']}].[{varStrDestTable}] (
            {', '.join([f'[{col[1]}_____{col[0]}] NVARCHAR(MAX)' for col in varListCols])}
        )
    END
    """
    varObjMSSQLCursor.execute(varStrCreateTableSql)
    varObjSqlConn.commit()

    return varStrDestTable, varStrColList, varStrPlaceholders
                                                        

def fun_ProcessTable(myTupleTableInfo, myObjLogLock, myObjReportLock):
    """
    Process table migration with connection pooling.
    Parameters:
        myTupleTableInfo: Tuple of (source_table, dest_table)
        myObjLogLock: Threading lock for logging
        myObjReportLock: Threading lock for reporting
    Returns: None
    """
    varObjAs400Conn = myObjAs400Pool.get_connection()
    varObjSqlConn = myObjSqlPool.get_connection()
    
    try:
        varStrAs400Table, varStrSqlTable = myTupleTableInfo
        fun_PrintStatus({varStrSqlTable},  f"Processing TABLE AS400 [{varStrAs400Table}] into -> MSSQL TABLE [{varStrSqlTable}]", "process")
        
        # Get connections and cursors
        varObjAs400Cursor = varObjAs400Conn.cursor()
        varObjMSSQLCursor = varObjSqlConn.cursor()
        
        # Get row counts
        #print(f"we will get the row count for AS400 [{varStrAs400Table}] and [{varStrSqlTable}]")
        varIntAs400Count = fun_GetTableRowCount(varObjAs400Cursor, myDictConfig['AS400']['LIBRARY'], varStrAs400Table)
        varIntSqlCount = fun_GetTableRowCount(varObjMSSQLCursor, myDictConfig['SQL_SERVER']['SCHEMA'], varStrSqlTable)
        
        # Verify row counts - skip if same, process if different
        if varIntAs400Count == varIntSqlCount:
            fun_PrintStatus(varStrAs400Table, f"Skipping - counts match {varIntAs400Count} = {varIntSqlCount}", "success")
            return
        else:
            fun_PrintStatus(varStrSqlTable, f"Dropping table - counts don't match: AS400={varIntAs400Count} vs SQL={varIntSqlCount}", "drop")
            varStrDestTable, varStrColList, varStrPlaceholders = myfunRebuildTable(varObjAs400Cursor, varObjMSSQLCursor, varStrSqlTable, myDictConfig)  #we drop, rebuild and return the new table


        varStrInsertSql = f"INSERT INTO [{myDictConfig['SQL_SERVER']['SCHEMA']}].[{varStrDestTable}] ({varStrColList}) VALUES ({varStrPlaceholders})"
        
        # Process data in batches
        varObjAs400Cursor.execute(f"SELECT * FROM {myDictConfig['AS400']['LIBRARY']}.{varStrAs400Table}")
        varIntTotalInserted = 0
        
        with tqdm(total=varIntAs400Count, desc=f"Migrating {varStrAs400Table}") as pbar:
            while True:
                varListBatch = varObjAs400Cursor.fetchmany(myDictConfig['BATCH_SIZE'])
                if not varListBatch:
                    break
                    
                varListNormalizedBatch = fun_NormalizeBatch(varListBatch)
                if fun_ProcessBatch(varObjMSSQLCursor, varStrInsertSql, varListNormalizedBatch, varStrAs400Table):
                    fun_PrintStatus(varStrAs400Table, (len(varListBatch)), "insert")
                    varIntTotalInserted += len(varListBatch)
                    varObjSqlConn.commit()
                    pbar.update(len(varListBatch))
                else:
                    varObjSqlConn.rollback()
                    break
        
        print(f"Completed {varStrAs400Table} - Inserted {varIntTotalInserted} rows")
        
    except Exception as myErr:
        print(f"Error processing {varStrAs400Table}: {str(myErr)}")
        if varObjSqlConn:
            varObjSqlConn.rollback()
    finally:
        # Return connections to pool
        if varObjAs400Conn:
            myObjAs400Pool.return_connection(varObjAs400Conn)
        if varObjSqlConn:
            myObjSqlPool.return_connection(varObjSqlConn)

# =============================================
# MAIN EXECUTION SECTION
# =============================================
if __name__ == "__main__":
    try:
        # Initialize with timestamp
        fun_PrintStatus("SYSTEM", "Starting migration process", "process")
        fun_InitializeConnectionPools()
        
        # Get list of tables to process
        varObjSqlConn = myObjSqlPool.get_connection()
        
        #Get varObjCursor, get varListTables, prints all the rows from MSSQL SCHEMA TABLES
        try:
            varObjCursor = varObjSqlConn.cursor()
            varListMSSQLTablesfromSYS_SCHEMA = [row[0] for row in varObjCursor.execute(
                f"SELECT TABLE_NAME AS CleanName "
                f"FROM INFORMATION_SCHEMA.TABLES "
                f"WHERE TABLE_SCHEMA = '{myDictConfig['SQL_SERVER']['SCHEMA']}' "
                f"AND TABLE_NAME LIKE 'z\\_%' ESCAPE '\\'"
            )]

            print(f"Found {len(varListMSSQLTablesfromSYS_SCHEMA)} tables to process")
        
        finally:
            myObjSqlPool.return_connection(varObjSqlConn)
            #print("Printing all the rows MSSQL from the query SYSTABLES******************************************************************")
            #for myObjThisRow in varListMSSQLTablesfromSYS_SCHEMA: print(f"row for TABLE from query:[{myObjThisRow}]")
        
        # Process MSSQL tables with controlled threading
            varObjLogLock = threading.Lock()  # wait for the lock and lock it
            varObjReportLock = threading.Lock() # wait for the lock and lock it
            varListActiveThreads = []
        
        #We process MSSQL table by table
            for varThisStr_MSSQL_TableinRowCount in varListMSSQLTablesfromSYS_SCHEMA:
                # Wait until we have an available thread slot
                while len(varListActiveThreads) >= myDictConfig['MAX_THREADS']:
                    # Clean up finished threads
                    for varObjThread in varListActiveThreads[:]:
                        if not varObjThread.is_alive():
                            varObjThread.join()
                            varListActiveThreads.remove(varObjThread)
                    time.sleep(0.1)
                
                # Start new thread
                #varStrAs400Table = varThisStrTableinRowCount.split('_____')[-1].lstrip('_')
                #print("Printing all the rows MSSQL. same object. ******************************************************************")
                #for myObjThisRow in varListMSSQLTablesfromSYS_SCHEMA: print(f"row for TABLE:[{myObjThisRow}]")

                varStrAs400Table = varThisStr_MSSQL_TableinRowCount.rsplit('_____', 1)[-1]
                #print(f"{VBCRLF} splitted AS400 TABLE [{varStrAs400Table}] from row:[{myObjThisRow}]")
                #print(f"    TABLE string formatting on MSSQL TABLE cycle [{varThisStr_MSSQL_TableinRowCount}]    resulting in VarStrAs400TABLE: ***[{varStrAs400Table}]", flush=True)

                varObjThread = threading.Thread(
                    target=fun_ProcessTable,
                    args=((varStrAs400Table, varThisStr_MSSQL_TableinRowCount), varObjLogLock, varObjReportLock),
                    daemon=True
                )
                #print(f"    fun_process_table: AS400 [{varStrAs400Table}]  MSSQL [{varThisStr_MSSQL_TableinRowCount}]    and VarStrAs400Table: [{varStrAs400Table}]", flush=True)
                varObjThread.start()
                varListActiveThreads.append(varObjThread)
        
        # Wait for all remaining threads to complete
            for varObjThread in varListActiveThreads:
                varObjThread.join()

        #we print the status    
        fun_PrintStatus("SYSTEM", "Migration completed successfully", "success")
        
    except Exception as myErr:
        fun_PrintStatus("SYSTEM", f"Migration failed: {str(myErr)}", "failure")
        traceback.print_exc()
        winsound.Beep(1000, 1000)