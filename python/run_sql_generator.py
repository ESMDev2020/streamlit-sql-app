# Main script to run the SQL generator
from my_pyfun_sql_generator import create_sql_query_from_file

# Database connection parameters
DB_SERVER = "database-1.cduyeeawahjc.us-east-2.rds.amazonaws.com"
DB_DATABASE = "SigmaTB"
DB_USERNAME = "admin"
DB_PASSWORD = "Er1c41234$"

# File parameters
INPUT_DIR = "/Users/erick/Documents/GitHub/SigmaTB_LocalRepo/data/"
INPUT_FILENAME = "ColumnsToQuery.txt"
COLUMN_PREFIX = "SH"  # The prefix for columns in your file

# Run the function
result = create_sql_query_from_file(
    INPUT_DIR,
    INPUT_FILENAME,
    COLUMN_PREFIX,
    DB_SERVER,
    DB_DATABASE,
    DB_USERNAME,
    DB_PASSWORD
)

# Print the result
if result.startswith("Error:"):
    print(f"❌ Error: {result}")
else:
    print(f"✅ Success! Generated SQL query: {result}") 