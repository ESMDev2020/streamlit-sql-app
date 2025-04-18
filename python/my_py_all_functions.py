# =============================================================================
# 🎯 ALL PHYTON FUNCTIONS
# DESCRIPTION:
#     Wrapper script to call a function that generates SQL queries from a file.
#     Applies naming conventions, error control, and execution progress tracking.
# =============================================================================

# 📦 IMPORTS
import os
from datetime import datetime
from my_pyfun_sql_generator import create_sql_query_from_file  # External function

# 🔒 CONSTANTS
myCon_strDataDirectory = '/Users/erick/Documents/GitHub/SigmaTB_LocalRepo/data/'
myCon_strFilename = 'ColumnsToQuery.txt'
myCon_strPrefix = 'SH'
myCon_booShouldSave = True

# 🧠 VARIABLES
myVar_strGeneratedSQL = ""
myVar_strFilePath = os.path.join(myCon_strDataDirectory, myCon_strFilename)

# =============================================================================
# 🚀 MAIN EXECUTION
# =============================================================================
try:
    # 🕓 Start timestamp
    print(f"🟢 Starting execution at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # 🛠️ Print processing info
    print(f"📄 Processing file: {myVar_strFilePath}")
    
    # 📞 Call the external function
    myVar_strGeneratedSQL = create_sql_query_from_file(
        myCon_strDataDirectory,
        myCon_strFilename,
        myCon_strPrefix,
        myCon_booShouldSave
    )
    
    # 🧪 Evaluate result
    if myVar_strGeneratedSQL.startswith("Error:"):
        print(f"❌ An error occurred: {myVar_strGeneratedSQL}")
    else:
        print("\n📜 Generated SQL:")
        print(myVar_strGeneratedSQL)
        if myCon_booShouldSave:
            print(f"\n💾 SQL output was saved to: {myCon_strDataDirectory}")

    # 🕓 End timestamp
    print(f"✅ Finished execution at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

except Exception as myVar_errException:
    # ❌ Error control block
    print("🔴 Execution failed with error:", str(myVar_errException))
