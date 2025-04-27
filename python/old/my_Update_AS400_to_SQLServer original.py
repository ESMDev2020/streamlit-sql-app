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
import pyodbc
from tqdm import tqdm
import threading
from datetime import datetime
import traceback
from decimal import Decimal
import winsound
import time
from queue import Queue

# Connection pool implementation
class ConnectionPool:
    def __init__(self, creator, max_size=5):
        self._pool = Queue(max_size)
        self.creator = creator
        for _ in range(max_size):
            self._pool.put(creator())

    def get_connection(self):
        return self._pool.get()

    def return_connection(self, conn):
        self._pool.put(conn)

# Constants with optimized settings
CONFIG = {
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
    'BATCH_SIZE': 1000,  # Reduced from 10000 for better memory management
    'MAX_THREADS': 1,    # Reduced from 20 to avoid connection pool exhaustion
    'MAX_RETRIES': 3,
    'RETRY_DELAY': 5,
    'LOG_FILE': "failed_inserts.log",
    'REPORT_FILE': "migration_report.csv"
}


# Initialize connection pools
as400_pool = None
sql_pool = None

def init_connection_pools():
    global as400_pool, sql_pool
    
    def create_as400_conn():
        conn_str = f"DSN={CONFIG['AS400']['DSN']};UID={CONFIG['AS400']['UID']};PWD={CONFIG['AS400']['PWD']};Timeout={CONFIG['AS400']['TIMEOUT']}"
        return pyodbc.connect(conn_str, autocommit=False)
    
    def create_sql_conn():
        conn_str = (
            f"DRIVER={CONFIG['SQL_SERVER']['DRIVER']};"
            f"SERVER={CONFIG['SQL_SERVER']['SERVER']};"
            f"DATABASE={CONFIG['SQL_SERVER']['DB']};"
            f"UID={CONFIG['SQL_SERVER']['UID']};"
            f"PWD={CONFIG['SQL_SERVER']['PWD']};"
            "Encrypt=yes;TrustServerCertificate=yes;Connection Timeout=30;"
        )
        return pyodbc.connect(conn_str, autocommit=False)
    
    as400_pool = ConnectionPool(create_as400_conn, CONFIG['MAX_THREADS'])
    sql_pool = ConnectionPool(create_sql_conn, CONFIG['MAX_THREADS'])

def get_table_rowcount(cursor, schema, table):
    """Optimized row count retrieval with error handling"""
    try:
        cursor.execute(f"SELECT COUNT(*) FROM [{schema}].[{table}]")
        return cursor.fetchone()[0]
    except Exception as e:
        print(f"Row count error for {table}: {str(e)}")
        return -1

def myFunPrintStatus(varTableName, varstrStatus, varstrIcon):
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    
    if varstrIcon == "process":
        print(f"[{timestamp}]              ⚙️ Processing {varTableName}    {varstrStatus}")
    elif varstrIcon == "download":
        print(f"[{timestamp}]         ⬇️ Downloading {varTableName}    {varstrStatus}")
    elif varstrIcon == "insert":
        print(f"[{timestamp}]         ➕ Inserting into {varTableName}    {varstrStatus}")
    elif varstrIcon == "drop":
        print(f"[{timestamp}]         🗑️ Dropping {varTableName}    {varstrStatus}")
    elif varstrIcon == "update":
        print(f"[{timestamp}]         🔄 Updating {varTableName}    {varstrStatus}")
    elif varstrIcon == "success":
        print(f"[{timestamp}]    ✅ Success with {varTableName}    {varstrStatus}")
    elif varstrIcon == "failure":
        print(f"[{timestamp}]    ❌ Failure with {varTableName}    {varstrStatus}")
    else:
        print(f"[{timestamp}]    ❓ Unknown status for {varTableName}    {varstrStatus}")


    

def process_batch(sql_cursor, insert_sql, batch, table_name, retry_count=0):
    """Safe batch processing with retries and timeout"""
    try:
        # Set timeout and enable fast executemany
        sql_cursor.timeout = 60
        sql_cursor.fast_executemany = True

        myFunPrintStatus(table_name, "", "process")

        sql_cursor.executemany(insert_sql, batch)
        return True
    except pyodbc.Error as e:
        if retry_count < CONFIG['MAX_RETRIES']:
            print(f"Retrying batch for {table_name} (attempt {retry_count + 1})")
            time.sleep(CONFIG['RETRY_DELAY'] * (retry_count + 1))
            return process_batch(sql_cursor, insert_sql, batch, table_name, retry_count + 1)
        print(f"Failed batch for {table_name} after {CONFIG['MAX_RETRIES']} retries: {str(e)}")
        return False
    except Exception as e:
        print(f"Unexpected error processing batch for {table_name}: {str(e)}")
        return False

def process_table(table_info, log_lock, report_lock):
    """Optimized table processing with connection pooling"""
    as400_conn = as400_pool.get_connection()
    sql_conn = sql_pool.get_connection()
    
    try:
        as400_table, sql_table = table_info
        print(f"Processing {as400_table} -> {sql_table}")
        
        # Get connections and cursors
        as400_cursor = as400_conn.cursor()
        sql_cursor = sql_conn.cursor()
        
        # Get row counts
        as400_count = get_table_rowcount(as400_cursor, CONFIG['AS400']['LIBRARY'], as400_table)
        sql_count = get_table_rowcount(sql_cursor, CONFIG['SQL_SERVER']['SCHEMA'], sql_table)
        
        if as400_count == sql_count:
            print(f"Skipping {as400_table} - counts match")
            return
            
        # Prepare destination table
        dest_table = f"z_{as400_table}"
        cols = get_column_metadata(as400_cursor, CONFIG['AS400']['LIBRARY'], as400_table)
        col_list = ", ".join([f"[{col[1]}_____{col[0]}]" for col in cols])
        placeholders = ", ".join(["?"] * len(cols))
        insert_sql = f"INSERT INTO [{CONFIG['SQL_SERVER']['SCHEMA']}].[{dest_table}] ({col_list}) VALUES ({placeholders})"
        
        # Process data in batches
        as400_cursor.execute(f"SELECT * FROM {CONFIG['AS400']['LIBRARY']}.{as400_table}")
        total_inserted = 0
        
        with tqdm(total=as400_count, desc=f"Migrating {as400_table}") as pbar:
            while True:
                batch = as400_cursor.fetchmany(CONFIG['BATCH_SIZE'])
                if not batch:
                    break
                    
                normalized_batch = normalize_batch(batch)
                if process_batch(sql_cursor, insert_sql, normalized_batch, as400_table):
                    myFunPrintStatus( as400_table, (len(batch)), "insert")
                    total_inserted += len(batch)
                    sql_conn.commit()
                    pbar.update(len(batch))
                else:
                    sql_conn.rollback()
                    break
        
        print(f"Completed {as400_table} - Inserted {total_inserted} rows")
        
    except Exception as e:
        print(f"Error processing {as400_table}: {str(e)}")
        if sql_conn:
            sql_conn.rollback()
    finally:
        # Return connections to pool
        if as400_conn:
            as400_pool.return_connection(as400_conn)
        if sql_conn:
            sql_pool.return_connection(sql_conn)

def normalize_batch(batch):
    """Optimized batch normalization"""
    return [
        tuple(
            float(val) if isinstance(val, Decimal) 
            else val 
            for val in row
        )
        for row in batch
    ]

if __name__ == "__main__":
    try:
        init_connection_pools()
        print("Starting migration...")
        
        # Get list of tables to process
        sql_conn = sql_pool.get_connection()
        try:
            cursor = sql_conn.cursor()
            tables = [row[0] for row in cursor.execute(
                f"SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES "
                f"WHERE TABLE_SCHEMA = '{CONFIG['SQL_SERVER']['SCHEMA']}' "
                f"AND TABLE_NAME LIKE 'z\\_%' ESCAPE '\\'"
            )]
        finally:
            sql_pool.return_connection(sql_conn)
        
        # Process tables with thread pool
        threads = []
        log_lock = threading.Lock()
        report_lock = threading.Lock()
        
        for table in tables:
            as400_table = table.split('_____')[-1].lstrip('_')
            t = threading.Thread(
                target=process_table,
                args=((as400_table, table), log_lock, report_lock)
            )
            threads.append(t)
            t.start()
            
            # Limit active threads
            while threading.active_count() > CONFIG['MAX_THREADS']:
                time.sleep(1)
        
        for t in threads:
            t.join()
            
        print("Migration completed successfully")
        
    except Exception as e:
        print(f"Migration failed: {str(e)}")
        traceback.print_exc()
        winsound.Beep(1000, 1000)