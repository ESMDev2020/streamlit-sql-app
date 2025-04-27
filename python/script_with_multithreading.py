# -*- coding: utf-8 -*-
import pyodbc
from tqdm import tqdm
import sys
import traceback
from decimal import Decimal
from datetime import datetime
import threading
from queue import Queue

# --------------------------------------------
# CONFIGURATION BLOCK
# --------------------------------------------

# AS400 connection settings
myStrAS400Dsn = "METALNET"
myStrAS400Uid = "ESAAVEDR"
myStrAS400Pwd = "ESM25"
myIntAS400Timeout = 30

# SQL Server connection settings
myStrSQLDriver = "{ODBC Driver 17 for SQL Server}"
myStrSQLServer = "database-1.cduyeeawahjc.us-east-2.rds.amazonaws.com,1433"
myStrSQLDb = "SigmaTB"
myStrSQLUid = "admin"
myStrSQLPwd = "Er1c41234$"

# AS400 and SQL Server schema
myStrAS400Library = "MW4FILE"
myStrSQLSchema = "mrs"

# Optional flags
myBoolClearTargetTables = False
myIntBatchSize = 1000
myStrLogFilePath = "failed_inserts.log"
myIntMaxThreads = 5

# --------------------------------------------
# FUNCTION DEFINITIONS
# --------------------------------------------

def connect_as400():
    conn_str = f"DSN={myStrAS400Dsn};UID={myStrAS400Uid};PWD={myStrAS400Pwd};Timeout={myIntAS400Timeout}"
    return pyodbc.connect(conn_str, autocommit=False)

def connect_sql_server():
    conn_str = (
        f"DRIVER={myStrSQLDriver};SERVER={myStrSQLServer};DATABASE={myStrSQLDb};UID={myStrSQLUid};PWD={myStrSQLPwd};"
        "Encrypt=yes;TrustServerCertificate=yes;Connection Timeout=30;"
    )
    return pyodbc.connect(conn_str, autocommit=False)

def get_table_description(cursor, schema, table):
    cursor.execute(f"SELECT TABLE_TEXT FROM QSYS2.SYSTABLES WHERE TABLE_SCHEMA = '{schema}' AND TABLE_NAME = '{table}'")
    row = cursor.fetchone()
    return row[0].strip().replace(" ", "_") if row else table

def get_column_metadata(cursor, schema, table):
    cursor.execute(f"SELECT COLUMN_NAME, COLUMN_TEXT FROM QSYS2.SYSCOLUMNS WHERE TABLE_SCHEMA = '{schema}' AND TABLE_NAME = '{table}'")
    return [(col[0].strip(), (col[1] or "").strip().replace(" ", "_")) for col in cursor.fetchall()]

def normalize_batch(batch):
    return [tuple(float(val) if isinstance(val, Decimal) else val for val in row) for row in batch]

def get_z_tables_from_sqlserver(cursor, schema):
    cursor.execute(fr"SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = '{schema}' AND TABLE_NAME LIKE 'z\_%' ESCAPE '\'")
    return [row[0] for row in cursor.fetchall()]

def process_table(table_info, log_lock):
    as400_table, sql_table, index, total = table_info
    conn_as400 = connect_as400()
    conn_sql = connect_sql_server()
    cur_as400 = conn_as400.cursor()
    cur_sql = conn_sql.cursor()
    cur_sql.fast_executemany = True
    log_file = open(myStrLogFilePath, "a", encoding="utf-8")

    try:
        qualified_source = f'{myStrAS400Library}."{as400_table}"'
        try:
            cur_as400.execute(f"SELECT COUNT(*) FROM {qualified_source}")
            total_records = cur_as400.fetchone()[0]
        except Exception as ex:
            total_records = "UNKNOWN"

        print(f"▶️ Processing table {index} of {total}: {as400_table} with a total number of records of: {total_records}")
        start_time = datetime.now()

        table_desc = get_table_description(cur_as400, myStrAS400Library, as400_table)
        columns = get_column_metadata(cur_as400, myStrAS400Library, as400_table)

        if not columns:
            with log_lock:
                log_file.write(f"[{as400_table}] Skipped: No columns found or not a real table")
            return

        dest_table = f"z_{table_desc}_____{as400_table}"
        dest_table_escaped = dest_table.replace(']', ']]')
        dest_columns = [f"[{desc}_____{name}]" for name, desc in columns]
        placeholder_str = ", ".join(["?"] * len(columns))
        dest_col_list = ", ".join(dest_columns)
        insert_sql = f"INSERT INTO [{myStrSQLSchema}].[{dest_table_escaped}] ({dest_col_list}) VALUES ({placeholder_str})"

        cur_as400.execute(f"SELECT * FROM {qualified_source}")
        batch = cur_as400.fetchmany(myIntBatchSize)
        total_inserted = 0

        while batch:
            try:
                batch = normalize_batch(batch)
                cur_sql.executemany(insert_sql, batch)
                total_inserted += len(batch)
                print(f"    📦 Table {index} / {total}: {as400_table} Rows: {total_inserted} / {total_records}")
                batch = cur_as400.fetchmany(myIntBatchSize)
            except Exception as ex:
                with log_lock:
                    log_file.write(f"[{as400_table}] Batch insert failed: {ex}")
                conn_sql.rollback()
                break

        conn_sql.commit()
        end_time = datetime.now()
        print(f"  ✅ Completed table: {as400_table} | Rows: {total_inserted} | Time: {end_time - start_time}")
    except Exception as ex:
        with log_lock:
            log_file.write(f"[{as400_table}] Table processing failed: {ex}")
        traceback.print_exc()
        conn_sql.rollback()
    finally:
        cur_as400.close()
        cur_sql.close()
        conn_as400.close()
        conn_sql.close()
        log_file.close()

# --------------------------------------------
# MAIN EXECUTION BLOCK
# --------------------------------------------

conn_sql_main = connect_sql_server()
cur_sql_main = conn_sql_main.cursor()
tables_to_copy = []
for sql_table in get_z_tables_from_sqlserver(cur_sql_main, myStrSQLSchema):
    if "_____" in sql_table:
        as400_table = sql_table.split("_____")[-1].lstrip("_")
        tables_to_copy.append((as400_table, sql_table))

total_tables = len(tables_to_copy)
queue = Queue()
log_mutex = threading.Lock()

for idx, (as400_table, sql_table) in enumerate(tables_to_copy, 1):
    queue.put((as400_table, sql_table, idx, total_tables))

def worker():
    while not queue.empty():
        task = queue.get()
        try:
            process_table(task, log_mutex)
        finally:
            queue.task_done()

threads = []
for _ in range(min(myIntMaxThreads, total_tables)):
    thread = threading.Thread(target=worker)
    thread.start()
    threads.append(thread)

queue.join()
for thread in threads:
    thread.join()

print("✅ All tables processed with multi-threading.")
