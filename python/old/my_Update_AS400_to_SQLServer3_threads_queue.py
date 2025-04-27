# -*- coding: utf-8 -*-
"""
OPTIMIZED MIGRATION SCRIPT WITH THREADING SUPPORT
MAJOR IMPROVEMENTS:
1. Fixed SQL Server connection string with explicit port
2. Added proper transaction management
3. Implemented connection pooling
4. Optimized batch processing
5. Added detailed error handling
6. FIXED MULTITHREADING by separating DDL (single-threaded) from Data Migration (multi-threaded)
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
import winsound  # Note: Only works on Windows
import time
from queue import Queue
import sys # For flushing print output if needed

# =============================================
# CONSTANTS SECTION
# =============================================
# Configuration dictionary with optimized settings
myDictConfig = {
    # AS400 settings
    'AS400': {
        'DSN': "METALNET",
        'UID': "ESAAVEDR",
        'PWD': "ESM25",  # Consider securing credentials
        'TIMEOUT': 30,
        'LIBRARY': "MW4FILE"
    },
    # SQL Server settings
    'SQL_SERVER': {
        'DRIVER': "{ODBC Driver 17 for SQL Server}",
        'SERVER': "database-3.c67ymu6q22o1.us-east-1.rds.amazonaws.com,1433", # Fixed with port
        'DB': "SigmaTB",
        'UID': "admin",
        'PWD': "Er1c41234$", # Consider securing credentials
        'SCHEMA': "mrs"
    },
    # Operation settings
    'BATCH_SIZE': 10000,
    'MAX_THREADS': 20, # Set desired number of threads (e.g., 5, 10, 20)
    'MAX_RETRIES': 3,
    'RETRY_DELAY': 5,
    'LOG_FILE': "failed_inserts.log", # Currently unused
    'REPORT_FILE': "migration_report.csv" # Currently unused
}

VBCRLF = "\r\n"

# Global connection pool variables
myObjAs400Pool = None
myObjSqlPool = None

# Global lock for printing to prevent garbled output from threads
print_lock = threading.Lock()

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
        if max_size <= 0:
             raise ValueError("Connection pool size must be positive")
        self._pool = Queue(max_size)
        self.creator = creator
        self.max_size = max_size
        # Initialize pool
        try:
            for i in range(max_size):
                with print_lock:
                     print(f"    Initializing connection {i+1}/{max_size} for pool...")
                     sys.stdout.flush()
                conn = self.creator()
                self._pool.put(conn)
        except Exception as e:
            print(f"\nERROR: Failed to create initial connections for pool: {e}")
            traceback.print_exc()
            raise # Stop if pool cannot be initialized

    def get_connection(self):
        """Retrieve a connection from the pool"""
        # Blocks until a connection is available
        return self._pool.get()

    def return_connection(self, conn):
        """Return a connection to the pool"""
        # Basic check: ensure we don't put more connections than max_size back
        if self._pool.qsize() < self.max_size:
             self._pool.put(conn)
        else:
             # Pool is full (unexpected state), close the connection instead of putting it back
             try:
                 conn.close()
             except Exception: pass

    def close_all(self):
        """Attempt to close all connections currently in the pool."""
        closed_count = 0
        while not self._pool.empty():
            try:
                conn = self._pool.get_nowait() # Don't block if empty
                conn.close()
                closed_count += 1
            except Queue.Empty:
                break # Pool is empty
            except Exception as e:
                 with print_lock:
                     print(f"    Error closing connection during pool cleanup: {e}")
                     sys.stdout.flush()
        with print_lock:
             print(f"    Connection pool cleanup: Closed {closed_count} connections.")
             sys.stdout.flush()


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
        """Create a new AS400 connection (called by pool)"""
        # print statement moved to pool init for clarity
        varStrConnString = f"DSN={myDictConfig['AS400']['DSN']};UID={myDictConfig['AS400']['UID']};PWD={myDictConfig['AS400']['PWD']};Timeout={myDictConfig['AS400']['TIMEOUT']}"
        return pyodbc.connect(varStrConnString, autocommit=False)
    
    def fun_CreateSqlConnection():
        """Create a new SQL Server connection (called by pool)"""
        # print statement moved to pool init for clarity
        varStrConnString = (
            f"DRIVER={myDictConfig['SQL_SERVER']['DRIVER']};"
            f"SERVER={myDictConfig['SQL_SERVER']['SERVER']};"
            f"DATABASE={myDictConfig['SQL_SERVER']['DB']};"
            f"UID={myDictConfig['SQL_SERVER']['UID']};"
            f"PWD={myDictConfig['SQL_SERVER']['PWD']};"
            "Encrypt=yes;TrustServerCertificate=yes;Connection Timeout=30;"
        )
        return pyodbc.connect(varStrConnString, autocommit=False)
    
    fun_PrintStatus("SYSTEM", f"Initializing Connection Pools (Size: {myDictConfig['MAX_THREADS']})", "process")
    myObjAs400Pool = ConnectionPool(fun_CreateAs400Connection, myDictConfig['MAX_THREADS'])
    myObjSqlPool = ConnectionPool(fun_CreateSqlConnection, myDictConfig['MAX_THREADS'])
    fun_PrintStatus("SYSTEM", "Connection Pools Initialized", "success")

def fun_PrintStatus(myStrTableName, myStrStatus, myStrIcon):
    """
    Print formatted status message with timestamp and icon, using a lock for thread safety.
    """
    varStrTimestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    
    icons = {
        "process": "⚙️", "download": "⬇️", "insert": "➕", "drop": "🗑️",
        "update": "🔄", "success": "✅", "failure": "❌", "warning": "⚠️"
    }
    icon_char = icons.get(myStrIcon, "❓") 

    # Simplify label logic
    label_prefix = f"{icon_char} {myStrTableName}"

    log_message = f"[{varStrTimestamp}] {label_prefix}.......{myStrStatus}"
    
    # Use lock to prevent interleaved output from multiple threads
    with print_lock:
        print(log_message)
        sys.stdout.flush() # Force output immediately

def fun_GetTableRowCount(myObjCursor, myStrSchema, myStrTable):
    """
    Get row count for a table with error handling.
    Returns: Integer count of rows, 0 if table not found, -1 on other errors.
    """
    try:
        if myStrSchema == myDictConfig['AS400']['LIBRARY']:
            sql = f"SELECT COUNT(*) FROM {myStrSchema}.{myStrTable}"
        else:
            sql = f"SELECT COUNT(*) FROM [{myStrSchema}].[{myStrTable}]"

        myObjCursor.execute(sql)
        result = myObjCursor.fetchone()
        return result[0] if result else 0
        
    except pyodbc.ProgrammingError as pe:
         sqlstate = pe.args[0] if len(pe.args) > 0 else ''
         err_msg = str(pe)
         # Check for common 'table not found' indicators (adjust codes if needed for AS400)
         if sqlstate == '42S02' or "Invalid object name" in err_msg or "not found" in err_msg:
              # Log warning but return 0, allowing rebuild logic to proceed
              fun_PrintStatus(myStrTable, f"Table not found (Schema: {myStrSchema}). Assuming 0 rows.", "warning")
              return 0
         else: # Other programming error
              fun_PrintStatus(myStrTable, f"ProgrammingError getting row count: {err_msg}", "failure")
              return -1
    except Exception as myErr: # Catch other errors
         fun_PrintStatus(myStrTable, f"General error getting row count: {str(myErr)}", "failure")
         return -1

def fun_ProcessBatch(myObjSqlCursor, myStrInsertSql, myListBatch, myStrTableName, myIntRetryCount=0):
    """
    Process batch of records with retries. Commits are handled by the caller.
    """
    try:
        # Consider setting timeout on connection creation instead of per batch call
        # myObjSqlCursor.connection.timeout = 60 
        myObjSqlCursor.fast_executemany = True # Check compatibility if issues arise

        # fun_PrintStatus(myStrTableName, f"Executing batch insert ({len(myListBatch)} rows)...", "insert") # Verbose log

        myObjSqlCursor.executemany(myStrInsertSql, myListBatch)
        return True # Indicate success

    except pyodbc.Error as myErr:
        sqlstate = myErr.args[0] if len(myErr.args) > 0 else ''
        err_msg = str(myErr)
        # Basic check for potentially retryable errors
        is_retryable = 'timeout' in err_msg.lower() or 'deadlock' in err_msg.lower()

        if is_retryable and myIntRetryCount < myDictConfig['MAX_RETRIES']:
            fun_PrintStatus(myStrTableName, f"Retryable DB error ({sqlstate}). Retrying batch (attempt {myIntRetryCount + 1}/{myDictConfig['MAX_RETRIES']})", "warning")
            time.sleep(myDictConfig['RETRY_DELAY'] * (myIntRetryCount + 1))
            # Rollback before retry is crucial if the transaction is affected
            try:
                myObjSqlCursor.connection.rollback()
                fun_PrintStatus(myStrTableName, f"Rollback successful before retry attempt {myIntRetryCount + 1}.", "process")
            except Exception as rb_err:
                 fun_PrintStatus(myStrTableName, f"Rollback FAILED before retry attempt {myIntRetryCount + 1}: {rb_err}", "failure")
                 return False # Don't retry if rollback failed
            # Recursive call for retry
            return fun_ProcessBatch(myObjSqlCursor, myStrInsertSql, myListBatch, myStrTableName, myIntRetryCount + 1)
        else:
            # Non-retryable error or max retries reached
            fun_PrintStatus(myStrTableName, f"Failed batch insert after {myIntRetryCount} attempts: {err_msg} (SQLState: {sqlstate})", "failure")
            # Optional: Log first few rows of failed batch for debugging (requires fast_executemany=False)
            # try:
            #     first_rows = str(myListBatch[:3])
            #     fun_PrintStatus(myStrTableName, f"First few rows of failed batch: {first_rows}", "failure")
            # except: pass
            return False # Indicate failure

    except Exception as myErr:
        fun_PrintStatus(myStrTableName, f"Unexpected error processing batch: {str(myErr)}", "failure")
        traceback.print_exc()
        return False # Indicate failure


def fun_GetOneColumnMetadata(varObjAS400Cursor, myStrSchema, myStrTable):
    """
    Retrieve column names and descriptions from AS/400.
    Returns: List of tuples (original_as400_name, generated_sql_name)
             Returns empty list on error.
    """
    metadata = []
    try:
        # Parameterized query & Order by position
        sql = """
            SELECT COLUMN_NAME, COLUMN_TEXT 
            FROM QSYS2.SYSCOLUMNS
            WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?
            ORDER BY ORDINAL_POSITION 
        """ 
        varObjAS400Cursor.execute(sql, (myStrSchema, myStrTable))
        
        results = varObjAS400Cursor.fetchall()
        if not results:
             fun_PrintStatus(myStrTable, f"No columns found for {myStrSchema}.{myStrTable}", "warning")
             return [] # Return empty list, handled by caller

        # Sanitize column description (COLUMN_TEXT) to create valid SQL Server column names
        generated_names_set = set()
        for i, col in enumerate(results):
             col_name = col[0].strip()
             col_desc = (col[1] or f"COLUMN_{i}").strip() # Use default if None or empty

             # Basic sanitization - replace common problematic chars
             safe_desc = col_desc.replace(" ", "_").replace("'", "").replace("#", "Num").replace("/", "_").replace(".", "")
             safe_desc = "".join(c for c in safe_desc if c.isalnum() or c == '_') 
             
             # Handle empty descriptions or starting with non-alpha after sanitization
             if not safe_desc or not safe_desc[0].isalpha():
                 safe_desc = "Col_" + safe_desc 
             
             # Combine sanitized description and original name for uniqueness and context
             # Ensure final length is within SQL Server limits (usually 128)
             final_col_name_base = f"{safe_desc}_____{col_name}"
             final_col_name = final_col_name_base[:128] # Truncate if too long

             # Ensure uniqueness (extremely unlikely with name appended, but good practice)
             counter = 1
             temp_name = final_col_name
             while temp_name in generated_names_set:
                  suffix = f"_{counter}"
                  truncate_len = 128 - len(suffix)
                  temp_name = final_col_name_base[:truncate_len] + suffix
                  counter += 1
             final_col_name = temp_name
             generated_names_set.add(final_col_name)
             
             metadata.append((col_name, final_col_name)) # Store original and new name

        return metadata

    except Exception as e:
        fun_PrintStatus(myStrTable, f"Error getting metadata for {myStrSchema}.{myStrTable}: {e}", "failure")
        traceback.print_exc()
        return [] # Return empty list on error


def fun_NormalizeBatch(myListBatch):
    """
    Normalize batch data: Convert Decimals to floats, trim strings.
    """
    normalized_batch = []
    for myRow in myListBatch:
        new_row = []
        for myVal in myRow:
            if isinstance(myVal, Decimal):
                # Consider precision if needed, float conversion can lose precision
                new_row.append(float(myVal)) 
            elif isinstance(myVal, str):
                new_row.append(myVal.strip()) # Trim whitespace
            else:
                new_row.append(myVal)
        normalized_batch.append(tuple(new_row))
    return normalized_batch

# --- Phase 1 Function ---
def myfunRebuildTable(varObjAs400Cursor, varObjMSSQLCursor, varStrSqlTable, varStrAs400TableForMetadata, myDictConfig):
    """
    MODIFIED: Drops and recreates the SQL Server table based on AS400 metadata.
    Called sequentially by fun_PrepareTables. Commits after DROP and CREATE.
    Returns: True on success, False on failure.
    """
    sql_schema = myDictConfig['SQL_SERVER']['SCHEMA']
    as400_schema = myDictConfig['AS400']['LIBRARY']
    success = False
    
    fun_PrintStatus(varStrSqlTable, f"Attempting DROP IF EXISTS [{sql_schema}].[{varStrSqlTable}]", "drop")
    try:
        varObjMSSQLCursor.execute(f"DROP TABLE IF EXISTS [{sql_schema}].[{varStrSqlTable}]")
        varObjMSSQLCursor.connection.commit() # Commit the DROP immediately
        fun_PrintStatus(varStrSqlTable, "DROP successful (or table did not exist).", "success")
    except Exception as drop_err:
         fun_PrintStatus(varStrSqlTable, f"Error during DROP: {drop_err}", "failure")
         # Attempt rollback if drop failed mid-transaction (might be redundant but safe)
         try: varObjMSSQLCursor.connection.rollback()
         except Exception: pass
         return False # Cannot proceed if DROP fails unexpectedly

    # Prepare destination table info using the correct AS400 table name for metadata
    fun_PrintStatus(varStrSqlTable, f"Fetching metadata from AS400 table: {varStrAs400TableForMetadata}", "process")
    varListColsMeta = fun_GetOneColumnMetadata(varObjAs400Cursor, as400_schema, varStrAs400TableForMetadata)
    
    if not varListColsMeta:
         fun_PrintStatus(varStrSqlTable, f"Failed to get column metadata from AS400. Cannot create SQL table.", "failure")
         return False # Cannot proceed without metadata

    # Build the CREATE TABLE statement using generated SQL names
    # Using NVARCHAR(MAX) for all columns as per original code
    sql_column_definitions = [f"[{col_meta[1]}] NVARCHAR(MAX)" for col_meta in varListColsMeta] # Use generated names
    
    # Create the destination table SQL (IF NOT EXISTS is belt-and-suspenders after DROP IF EXISTS)
    varStrCreateTableSql = f"""
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = '{varStrSqlTable}' AND schema_id = SCHEMA_ID('{sql_schema}'))
    BEGIN
        CREATE TABLE [{sql_schema}].[{varStrSqlTable}] (
            {', '.join(sql_column_definitions)} 
        )
    END
    """

    fun_PrintStatus(varStrSqlTable, f"Attempting CREATE TABLE [{sql_schema}].[{varStrSqlTable}]", "process")
    try:
        varObjMSSQLCursor.execute(varStrCreateTableSql)
        varObjMSSQLCursor.connection.commit() # Commit the CREATE immediately
        fun_PrintStatus(varStrSqlTable, "CREATE TABLE successful.", "success")
        success = True
    except Exception as create_err:
         fun_PrintStatus(varStrSqlTable, f"ERROR during CREATE TABLE: {create_err}", "failure")
         traceback.print_exc()
         # Attempt rollback
         try: varObjMSSQLCursor.connection.rollback()
         except Exception: pass
         success = False # Failed

    # Return True if CREATE succeeded, False otherwise
    return success


# --- Phase 1 Function ---
def fun_PrepareTables(table_list, config):
    """
    MODIFIED: Single-threaded phase to check and prepare all destination table structures.
    Performs DROP/CREATE sequentially if row counts don't match or SQL table missing.
    """
    fun_PrintStatus("SYSTEM", "Starting Phase 1: Preparing Table Structures (Single-Threaded)", "process")
    
    prep_as400_conn = None
    prep_sql_conn = None
    prep_as400_cursor = None
    prep_sql_cursor = None
    
    prepared_count = 0
    skipped_count = 0
    error_count = 0
    total_tables = len(table_list)
    overall_success = True

    try:
        # Borrow ONE connection from each pool for this sequential phase
        prep_as400_conn = myObjAs400Pool.get_connection()
        prep_sql_conn = myObjSqlPool.get_connection()
        prep_as400_cursor = prep_as400_conn.cursor()
        prep_sql_cursor = prep_sql_conn.cursor()

        fun_PrintStatus("SYSTEM", f"Checking/Rebuilding {total_tables} tables sequentially...", "process")

        # Use tqdm for visual progress
        for index, sql_table_name in enumerate(tqdm(table_list, desc="Preparing Tables", unit="table")):
            as400_table_name = sql_table_name.rsplit('_____', 1)[-1]
            progress_prefix = f"[{index+1}/{total_tables}] {sql_table_name}" # For logging clarity

            try:
                # Get counts
                as400_count = fun_GetTableRowCount(prep_as400_cursor, config['AS400']['LIBRARY'], as400_table_name)
                sql_count = fun_GetTableRowCount(prep_sql_cursor, config['SQL_SERVER']['SCHEMA'], sql_table_name)

                # Check for errors getting counts
                if as400_count == -1:
                    fun_PrintStatus(progress_prefix, f"Skipping - Error getting AS400 row count.", "failure")
                    error_count += 1
                    continue # Skip this table

                # If SQL count is 0, it could be empty or non-existent. Rebuild if AS400 has rows.
                # If sql_count is -1 (error other than not found), log and skip.
                if sql_count == -1:
                    fun_PrintStatus(progress_prefix, f"Skipping - Error getting SQL Server row count.", "failure")
                    error_count += 1
                    continue # Skip this table

                # Decision logic: Rebuild if counts don't match
                if as400_count == sql_count:
                    # fun_PrintStatus(progress_prefix, f"Counts match ({as400_count}). Skipping rebuild.", "success") # Can be verbose
                    skipped_count += 1
                else:
                    fun_PrintStatus(progress_prefix, f"Counts mismatch (AS400:{as400_count} != SQL:{sql_count}). Rebuilding...", "process")
                    rebuild_success = myfunRebuildTable(prep_as400_cursor, prep_sql_cursor, sql_table_name, as400_table_name, config)
                    if rebuild_success:
                         prepared_count += 1
                    else:
                         fun_PrintStatus(progress_prefix, f"Rebuild failed. Migration for this table may fail.", "failure")
                         error_count += 1
            
            except Exception as table_err:
                fun_PrintStatus(progress_prefix, f"Unexpected ERROR during preparation for this table: {str(table_err)}", "failure")
                traceback.print_exc()
                error_count += 1
                # Attempt rollback on SQL connection for safety
                try:
                    prep_sql_conn.rollback()
                except Exception as rb_err:
                    fun_PrintStatus(progress_prefix, f"Rollback failed after error: {rb_err}", "failure")

    except Exception as phase_err:
        fun_PrintStatus("SYSTEM", f"FATAL ERROR during Table Preparation Phase: {phase_err}", "failure")
        traceback.print_exc()
        overall_success = False # Mark phase as failed

    finally:
        # Ensure cursors are closed before returning connections
        if prep_as400_cursor:
            try: prep_as400_cursor.close()
            except Exception: pass
        if prep_sql_cursor:
            try: prep_sql_cursor.close()
            except Exception: pass
        # Return connections to the pool
        if prep_as400_conn:
            myObjAs400Pool.return_connection(prep_as400_conn)
        if prep_sql_conn:
            myObjSqlPool.return_connection(prep_sql_conn)

    final_phase1_status = "success" if error_count == 0 and overall_success else "failure" if not overall_success else "warning"
    fun_PrintStatus("SYSTEM", f"Finished Phase 1: {prepared_count} rebuilt, {skipped_count} skipped, {error_count} errors.", final_phase1_status)
    if not overall_success:
        raise Exception("Table preparation phase failed catastrophically. Aborting migration.") # Stop script
    elif error_count > 0:
         print(f"\nWARNING: {error_count} tables encountered errors during preparation. Phase 2 will proceed but these tables might fail.")


# --- Phase 2 Function ---
def fun_ProcessTable(myTupleTableInfo, myObjLogLock, myObjReportLock):
    """
    MODIFIED FOR PHASE 2: Process DATA MIGRATION ONLY for a single table.
    Assumes table structure already exists correctly. Executed by threads.
    """
    varObjAs400Conn = None
    varObjSqlConn = None
    varObjAs400Cursor = None
    varObjMSSQLCursor = None
    # Unpack AS400 and SQL table names passed via args
    varStrAs400Table, varStrSqlTable = myTupleTableInfo 

    try:
        # Borrow connections from pool for this thread
        varObjAs400Conn = myObjAs400Pool.get_connection()
        varObjSqlConn = myObjSqlPool.get_connection()
        # Create cursors for this thread
        varObjAs400Cursor = varObjAs400Conn.cursor()
        varObjMSSQLCursor = varObjSqlConn.cursor()

        fun_PrintStatus(varStrSqlTable, f"Starting data migration -> AS400[{varStrAs400Table}]", "download")
        
        # --- Get metadata and build INSERT SQL dynamically within the thread ---
        varListColsMeta = fun_GetOneColumnMetadata(varObjAs400Cursor, myDictConfig['AS400']['LIBRARY'], varStrAs400Table)
        if not varListColsMeta:
             fun_PrintStatus(varStrSqlTable, f"Could not retrieve column metadata from AS400 table {varStrAs400Table}. Aborting migration for this table.", "failure")
             # Clean up resources for this thread before returning
             if varObjAs400Cursor: varObjAs400Cursor.close()
             if varObjMSSQLCursor: varObjMSSQLCursor.close()
             if varObjAs400Conn: myObjAs400Pool.return_connection(varObjAs400Conn)
             if varObjSqlConn: myObjSqlPool.return_connection(varObjSqlConn)
             return # Exit thread's work for this table

        # Use the GENERATED SQL names (index 1) for the INSERT statement
        varStrColList = ", ".join([f"[{col_meta[1]}]" for col_meta in varListColsMeta])
        varStrPlaceholders = ", ".join(["?"] * len(varListColsMeta))
        varStrDestTable = varStrSqlTable # Destination table name is the SQL table name
        varStrInsertSql = f"INSERT INTO [{myDictConfig['SQL_SERVER']['SCHEMA']}].[{varStrDestTable}] ({varStrColList}) VALUES ({varStrPlaceholders})"
        # --- End Metadata/SQL build ---

        # Get AS400 row count for progress bar (optional)
        as400_count_for_progress = None
        try:
            # Use a separate cursor execute; don't interfere with main data fetch cursor state
             count_cursor = varObjAs400Conn.cursor()
             as400_count_for_progress = fun_GetTableRowCount(count_cursor, myDictConfig['AS400']['LIBRARY'], varStrAs400Table)
             count_cursor.close()
             if as400_count_for_progress == -1: as400_count_for_progress = None
        except Exception as count_err:
             fun_PrintStatus(varStrSqlTable, f"Warning: could not get AS400 row count for progress bar: {count_err}", "warning")

        # Process data in batches using the main AS400 cursor
        select_sql = f"SELECT * FROM {myDictConfig['AS400']['LIBRARY']}.{varStrAs400Table}"
        try:
             varObjAs400Cursor.execute(select_sql)
        except Exception as select_err:
              fun_PrintStatus(varStrSqlTable, f"Error executing SELECT on AS400 table {varStrAs400Table}: {select_err}", "failure")
              raise # Re-raise to be caught by the main try/except in this function

        varIntTotalInserted = 0
        batch_num = 0
        migration_failed = False

        # Setup progress bar specific to this thread
        # Note: tqdm in threads might interleave output; consider alternatives if too messy
        pbar_desc = f"Migrating {varStrSqlTable}"
        pbar = tqdm(total=as400_count_for_progress, desc=pbar_desc, leave=False, unit="rows", position=threading.get_ident() % 10) # Position helps layout slightly

        while True:
            batch_num += 1
            varListBatch = varObjAs400Cursor.fetchmany(myDictConfig['BATCH_SIZE'])
            if not varListBatch:
                break # End of data
                
            varListNormalizedBatch = fun_NormalizeBatch(varListBatch)
            
            # Process the batch (includes retries)
            batch_success = fun_ProcessBatch(varObjMSSQLCursor, varStrInsertSql, varListNormalizedBatch, varStrSqlTable)
            
            if batch_success:
                # Commit this successful batch
                try:
                     varObjSqlConn.commit()
                     varIntTotalInserted += len(varListBatch)
                     pbar.update(len(varListBatch))
                except Exception as commit_err:
                     fun_PrintStatus(varStrSqlTable, f"ERROR committing batch {batch_num}: {commit_err}. Rolling back.", "failure")
                     try: varObjSqlConn.rollback()
                     except Exception: pass
                     migration_failed = True
                     break # Stop processing this table
            else:
                # Batch failed after retries, rollback and stop for this table
                # Error message already printed by fun_ProcessBatch
                try:
                    varObjSqlConn.rollback()
                except Exception as rb_err:
                     fun_PrintStatus(varStrSqlTable, f"Rollback failed after batch failure: {rb_err}", "failure")
                migration_failed = True
                break # Stop processing this table
        
        pbar.close() # Close the progress bar for this thread

        # Final status check for this table
        if not migration_failed:
             final_sql_count = -1
             try: # Verify final count
                 final_sql_count = fun_GetTableRowCount(varObjMSSQLCursor, myDictConfig['SQL_SERVER']['SCHEMA'], varStrSqlTable)
             except Exception: pass

             status_msg = f"Finished - Inserted {varIntTotalInserted} rows."
             final_status = "success"
             if as400_count_for_progress is not None and varIntTotalInserted != as400_count_for_progress:
                  status_msg += f" WARNING: Expected {as400_count_for_progress} rows!"
                  final_status = "warning"
             elif final_sql_count >= 0 and varIntTotalInserted != final_sql_count:
                   status_msg += f" WARNING: Final SQL count ({final_sql_count}) differs from inserted count!"
                   final_status = "warning"
             elif final_sql_count >= 0:
                    status_msg += f" Final SQL count: {final_sql_count}."

             fun_PrintStatus(varStrSqlTable, status_msg, final_status)
        # else: Failure message already printed

    except Exception as myErr:
        # Catch any unexpected error during the thread's processing
        fun_PrintStatus(varStrSqlTable, f"UNEXPECTED THREAD ERROR: {str(myErr)}", "failure")
        traceback.print_exc()
        # Attempt rollback if connection exists
        if varObjSqlConn:
            try: varObjSqlConn.rollback()
            except Exception as rb_err:
                 fun_PrintStatus(varStrSqlTable, f"Rollback failed after thread error: {rb_err}", "failure")
                 
    finally:
        # --- Crucial: Ensure resources are released in the finally block ---
        if pbar: # Ensure pbar is closed if loop exited unexpectedly
             try: pbar.close()
             except Exception: pass
        # Close cursors
        if varObjAs400Cursor:
            try: varObjAs400Cursor.close()
            except Exception: pass
        if varObjMSSQLCursor:
            try: varObjMSSQLCursor.close()
            except Exception: pass
        # Return connections to their respective pools
        if varObjAs400Conn:
            myObjAs400Pool.return_connection(varObjAs400Conn)
        if varObjSqlConn:
            myObjSqlPool.return_connection(varObjSqlConn)

# =============================================
# MAIN EXECUTION SECTION
# =============================================
if __name__ == "__main__":
    script_start_time = time.time()
    final_exit_code = 0 # 0 for success, 1 for failure

    try:
        fun_PrintStatus("SYSTEM", f"Starting migration process at {datetime.now()}", "process")
        
        # == Initialize Connection Pools ==
        # Based on MAX_THREADS config setting
        fun_InitializeConnectionPools() 
        
        # == Get list of tables to process from SQL Server ==
        varListMSSQLTablesfromSYS_SCHEMA = []
        conn_for_list = None 
        cursor_for_list = None
        try:
            fun_PrintStatus("SYSTEM", f"Fetching table list from SQL Server Schema '{myDictConfig['SQL_SERVER']['SCHEMA']}'...", "process")
            conn_for_list = myObjSqlPool.get_connection() # Borrow one connection
            cursor_for_list = conn_for_list.cursor()
            sql_query = f"""
                SELECT TABLE_NAME 
                FROM INFORMATION_SCHEMA.TABLES 
                WHERE TABLE_SCHEMA = ? 
                  AND TABLE_NAME LIKE 'z\\_%' ESCAPE '\\'
                ORDER BY TABLE_NAME 
            """ 
            cursor_for_list.execute(sql_query, myDictConfig['SQL_SERVER']['SCHEMA'])
            varListMSSQLTablesfromSYS_SCHEMA = [row[0] for row in cursor_for_list.fetchall()] # Use fetchall
            
            fun_PrintStatus("SYSTEM", f"Found {len(varListMSSQLTablesfromSYS_SCHEMA)} tables matching 'z_%'", "success")
            if not varListMSSQLTablesfromSYS_SCHEMA:
                 print("No tables found to process. Exiting.")
                 sys.exit(0) # Clean exit if no tables

        except Exception as list_err:
             fun_PrintStatus("SYSTEM", f"CRITICAL ERROR retrieving table list: {list_err}", "failure")
             traceback.print_exc()
             final_exit_code = 1
             raise # Stop script execution
        finally:
             # Ensure resources are released
             if cursor_for_list:
                 try: cursor_for_list.close()
                 except Exception: pass
             if conn_for_list:
                 myObjSqlPool.return_connection(conn_for_list)

        # == PHASE 1: Prepare table structures (Single-Threaded) ==
        # This function now handles errors internally and raises exception on catastrophic failure
        fun_PrepareTables(varListMSSQLTablesfromSYS_SCHEMA, myDictConfig)
        
        # == PHASE 2: Process data migration (Multi-Threaded) ==
        fun_PrintStatus("SYSTEM", f"Starting Phase 2: Migrating Data ({myDictConfig['MAX_THREADS']} threads)", "process")
        
        # Locks are defined but currently unused by print function
        # They could be used for shared reporting data structures if needed later
        varObjLogLock = threading.Lock()      
        varObjReportLock = threading.Lock()   
        
        threads = [] # List to keep track of running threads

        # Loop through the list of SQL tables determined earlier
        for varThisStr_MSSQL_Table in varListMSSQLTablesfromSYS_SCHEMA:
            
            # --- Thread Management: Wait if max threads are running ---
            # This is a simple way; ThreadPoolExecutor is often cleaner for managing workers
            while threading.active_count() > myDictConfig['MAX_THREADS']: 
                 # Optional: More sophisticated cleanup of finished threads could go here
                 # Or just wait for *any* thread to finish
                 time.sleep(0.5) 

            # Derive AS400 table name from the SQL table name
            try:
                 # Assuming the part after the last '_____' is the AS400 name
                 varStrAs400Table = varThisStr_MSSQL_Table.rsplit('_____', 1)[-1] 
            except Exception as name_err:
                 fun_PrintStatus(varThisStr_MSSQL_Table, f"Could not derive AS400 name. Skipping. Error: {name_err}", "failure")
                 continue # Skip starting a thread for this table

            # Prepare arguments for the thread function
            table_info_tuple = (varStrAs400Table, varThisStr_MSSQL_Table)

            # Create and start the thread
            thread = threading.Thread(
                target=fun_ProcessTable, # Target the MODIFIED data migration function
                args=(table_info_tuple, varObjLogLock, varObjReportLock),
                daemon=True # Allows main program to exit even if daemons are running (use carefully)
            )
            thread.start()
            threads.append(thread) # Add to list
        
        # --- Wait for all data migration threads to complete ---
        fun_PrintStatus("SYSTEM", f"All {len(threads)} data migration threads started. Waiting for completion...", "process")
        
        # Use tqdm to show progress waiting for threads
        for thread in tqdm(threads, desc="Waiting for Threads", unit="thread"):
            thread.join() # Wait for this specific thread to finish

        # == Final Summary ==
        script_end_time = time.time()
        duration = script_end_time - script_start_time
        fun_PrintStatus("SYSTEM", f"Migration process finished in {duration:.2f} seconds.", "success")
        
    except Exception as myErr:
        # Catch any unhandled exceptions in the main block
        fun_PrintStatus("SYSTEM", f"Migration failed with unhandled exception in main block: {str(myErr)}", "failure")
        traceback.print_exc()
        final_exit_code = 1 # Mark as failure
        try:
             winsound.Beep(1000, 1000) # Alert on failure (Windows only)
        except ImportError:
             print("Note: winsound is not available on this system for beep alert.")
        except Exception: pass # Ignore other winsound errors

    finally:
         # == Cleanup Connection Pools ==
         fun_PrintStatus("SYSTEM", "Closing database connections in pools...", "process")
         if myObjAs400Pool:
              myObjAs400Pool.close_all()
         if myObjSqlPool:
              myObjSqlPool.close_all()
         fun_PrintStatus("SYSTEM", "Script execution finished.", "process")
         # Exit with appropriate code if needed for scripting
         # sys.exit(final_exit_code)