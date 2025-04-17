"""
Column Relationship Finder
This script analyzes database tables to find relationships between columns based on matching codes.
It processes the GLTRANS table and its target columns to find matching columns in other tables.
"""

# ===================================================
# IMPORTS
# ===================================================
import pyodbc
import logging
from typing import List, Dict, Tuple
from collections import defaultdict
import sys
from datetime import datetime
import time

# ===================================================
# CONSTANTS
# ===================================================
# Database Constants
myConStrConnectionString: str = (
    "Driver={ODBC Driver 17 for SQL Server};"
    "Server=database-1.cduyeeawahjc.us-east-2.rds.amazonaws.com;"
    "Database=SigmaTB;"
    "UID=admin;"
    "PWD=Er1c41234$;"
)

# Table Constants
myConStrSourceTable: str = 'z_General_Ledger_Transaction_File_____GLTRANS'
myConStrSeparator: str = '_____'

# Target Columns Constants
myConListTargetColumns: List[str] = [
    'GLACCT',
    'GLBTCH',
    'GLREF',
    'GLTRNT',
    'GLTRN#',
    'GLAMT',
    'GLAMTQ'
]

# ===================================================
# FUNCTIONS
# ===================================================

def fun_initialize_logging() -> None:
    """
    Initializes logging configuration for the application.
    Sets up both file and console logging with debug level.
    """
    logging.basicConfig(
        level=logging.DEBUG,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler('column_relationships.log'),
            logging.StreamHandler(sys.stdout)
        ]
    )

def fun_get_column_code(myStrColumnName: str, myStrSeparator: str) -> str:
    """
    Extracts the code part from a column name after the separator.
    
    Args:
        myStrColumnName: The full column name
        myStrSeparator: The separator used in column names
        
    Returns:
        The extracted code part of the column name
    """
    #logging.debug(f"Extracting code from column: {myStrColumnName}")
    if myStrSeparator not in myStrColumnName:
        #logging.debug(f"No separator found, returning full name: {myStrColumnName}")
        return myStrColumnName
    myStrCode: str = myStrColumnName.split(myStrSeparator)[-1]
    #logging.debug(f"Extracted code: {myStrCode}")
    return myStrCode

def fun_get_table_columns(myObjCursor, myStrTableName: str, myStrSeparator: str) -> List[Tuple[str, str, int]]:
    """
    Retrieves all columns for a given table with their codes.
    
    Args:
        myObjCursor: Database cursor
        myStrTableName: Name of the table to get columns from
        myStrSeparator: Separator used in column names
        
    Returns:
        List of tuples containing (column_name, column_code, column_id)
    """
    #logging.debug(f"Getting columns for table: {myStrTableName}")
    myStrQuery: str = """
    SELECT c.name, c.column_id
    FROM sys.columns c
    WHERE c.object_id = OBJECT_ID(?)
    """
    myObjCursor.execute(myStrQuery, (myStrTableName,))
    myListColumns: List[Tuple[str, str, int]] = []
    
    # Process each column
    for myStrName, myIntColumnId in myObjCursor.fetchall():
        myStrCode: str = fun_get_column_code(myStrName, myStrSeparator)
        myListColumns.append((myStrName, myStrCode, myIntColumnId))
        #logging.debug(f"Found column: {myStrName} (ID: {myIntColumnId}, Code: {myStrCode})")
    
    #logging.debug(f"Total columns found: {len(myListColumns)}")
    return myListColumns

def fun_get_table_description(myObjCursor, myStrTableName: str) -> str:
    """
    Retrieves the description of a table from extended properties.
    
    Args:
        myObjCursor: Database cursor
        myStrTableName: Name of the table
        
    Returns:
        Table description or table name if no description exists
    """
    #logging.debug(f"Getting description for table: {myStrTableName}")
    myStrQuery: str = """
    SELECT CAST(value AS NVARCHAR(MAX))
    FROM sys.extended_properties 
    WHERE major_id = OBJECT_ID(?) 
    AND minor_id = 0
    """
    myObjCursor.execute(myStrQuery, (myStrTableName,))
    myObjResult = myObjCursor.fetchone()
    myStrDescription: str = myObjResult[0] if myObjResult else myStrTableName
    #logging.debug(f"Table description: {myStrDescription}")
    return myStrDescription

def fun_get_column_description(myObjCursor, myStrTableName: str, myIntColumnId: int) -> str:
    """
    Retrieves the description of a column from extended properties.
    
    Args:
        myObjCursor: Database cursor
        myStrTableName: Name of the table
        myIntColumnId: ID of the column
        
    Returns:
        Column description or empty string if no description exists
    """
    logging.debug(f"Getting description for column ID {myIntColumnId} in table {myStrTableName}")
    myStrQuery: str = """
    SELECT CAST(value AS NVARCHAR(MAX))
    FROM sys.extended_properties 
    WHERE major_id = OBJECT_ID(?) 
    AND minor_id = ?
    """
    myObjCursor.execute(myStrQuery, (myStrTableName, myIntColumnId))
    myObjResult = myObjCursor.fetchone()
    myStrDescription: str = myObjResult[0] if myObjResult else ''
    logging.debug(f"Column description: {myStrDescription}")
    return myStrDescription

def fun_find_relationships(myStrConnectionString: str) -> List[Dict]:
    """
    Main function to find relationships between columns.
    Processes the source table and finds matching columns in other tables.
    
    Args:
        myStrConnectionString: Database connection string
        
    Returns:
        List of dictionaries containing found relationships
    """
    # Initialize variables
    myObjConn = pyodbc.connect(myStrConnectionString)
    myObjCursor = myObjConn.cursor()
    myListRelationships: List[Dict] = []
    
    try:
        # Get source table information
        logging.info(f"Starting relationship analysis for table {myConStrSourceTable}")
        myListSourceColumns = fun_get_table_columns(myObjCursor, myConStrSourceTable, myConStrSeparator)
        myStrSourceTableDesc = fun_get_table_description(myObjCursor, myConStrSourceTable)
        
        # Filter source columns
        logging.debug("Filtering source columns")
        myListSourceColumns = [(myStrName, myStrCode, myIntColId) 
                              for myStrName, myStrCode, myIntColId in myListSourceColumns 
                              if myStrCode in myConListTargetColumns]
        logging.debug(f"Filtered source columns: {myListSourceColumns}")
        
        # Get all tables
        logging.debug("Getting all tables in database")
        myStrQuery: str = """
        SELECT TABLE_SCHEMA + '.' + TABLE_NAME
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_TYPE = 'BASE TABLE'
        AND TABLE_NAME != ?
        """
        myObjCursor.execute(myStrQuery, (myConStrSourceTable,))
        myListAllTables = [myStrRow[0] for myStrRow in myObjCursor.fetchall()]
        logging.debug(f"Found {len(myListAllTables)} tables to analyze")
        
        # Initialize counters
        myIntTotalColumns: int = 0
        myIntCurrentColumn: int = 0
        
        # Process each source column
        for myStrSourceName, myStrSourceCode, myIntSourceColId in myListSourceColumns:
            logging.debug(f"\nAnalyzing source column: {myStrSourceName} (Code: {myStrSourceCode})")
            myStrSourceDesc = fun_get_column_description(myObjCursor, myConStrSourceTable, myIntSourceColId)
            
            # Process each target table
            for myStrTableName in myListAllTables:
                #logging.debug(f"Checking table: {myStrTableName}")
                myListTargetColumns = fun_get_table_columns(myObjCursor, myStrTableName, myConStrSeparator)
                myStrTableDesc = fun_get_table_description(myObjCursor, myStrTableName)
                
                # Update total columns count
                myIntTotalColumns += len(myListTargetColumns)
                
                # Check each target column
                for myStrTargetName, myStrTargetCode, myIntTargetColId in myListTargetColumns:
                    myIntCurrentColumn += 1
                    
                    # Log progress every 100 columns
                    if myIntCurrentColumn % 1000 == 0:
                        logging.info(f"Processing column {myIntCurrentColumn} of {myIntTotalColumns} ({(myIntCurrentColumn/myIntTotalColumns)*100:.1f}%)")
                    
                    # Check for code match
                    if myStrSourceCode == myStrTargetCode:
                        logging.debug(f"MATCH FOUND: {myStrSourceCode} == {myStrTargetCode}")
                        myStrTargetDesc = fun_get_column_description(myObjCursor, myStrTableName, myIntTargetColId)
                        
                        # Create relationship record
                        myDictRelationship = {
                            'SourceTableName': myStrSourceTableDesc,
                            'ForeignTableName': myStrTableDesc,
                            'SourceColumnName': myStrSourceDesc,
                            'ForeignColumnName': myStrTargetDesc,
                            'SourceTableCode': myConStrSourceTable,
                            'ForeignTableCode': myStrTableName,
                            'SourceColumnCode': myStrSourceName,
                            'ForeignColumnCode': myStrTargetName
                        }
                        myListRelationships.append(myDictRelationship)
                        logging.info(f"Found relationship: {myStrSourceName} -> {myStrTargetName}")
                    #else:
                        #logging.debug(f"No match: {myStrSourceCode} != {myStrTargetCode}")
        
        logging.info(f"Total relationships found: {len(myListRelationships)}")
        return myListRelationships
        
    except Exception as myObjError:
        logging.error(f"Error in relationship finding: {str(myObjError)}", exc_info=True)
        raise
    finally:
        myObjCursor.close()
        myObjConn.close()

def sub_print_relationships(myListRelationships: List[Dict]) -> None:
    """
    Prints the found relationships in a formatted way.
    
    Args:
        myListRelationships: List of relationship dictionaries to print
    """
    print("\nFound Relationships:")
    print("=" * 100)
    for myDictRel in myListRelationships:
        print(f"Source: {myDictRel['SourceTableName']}.{myDictRel['SourceColumnName']} ({myDictRel['SourceColumnCode']})")
        print(f"Target: {myDictRel['ForeignTableName']}.{myDictRel['ForeignColumnName']} ({myDictRel['ForeignColumnCode']})")
        print("-" * 100)

def main():
    """
    Main execution function.
    Initializes logging, finds relationships, and prints results.
    """
    try:
        # Initialize logging
        fun_initialize_logging()
        
        # Record start time
        myDtStartTime = datetime.now()
        logging.info(f"Starting execution at {myDtStartTime}")
        
        # Find relationships
        myListRelationships = fun_find_relationships(myConStrConnectionString)
        
        # Print results
        sub_print_relationships(myListRelationships)
        
        # Record end time and duration
        myDtEndTime = datetime.now()
        myFltDuration = (myDtEndTime - myDtStartTime).total_seconds()
        logging.info(f"Execution completed at {myDtEndTime}")
        logging.info(f"Total execution time: {myFltDuration:.2f} seconds")
        
    except Exception as myObjError:
        logging.error(f"Error in main execution: {str(myObjError)}", exc_info=True)
        raise

if __name__ == "__main__":
    main() 