# FILE: my_pyfun_sql_generator.py
# =============================================================================
# 🔍 FUNCTIONAL MODULE: SQL Query Generator from File
# DESCRIPTION:
#     Reads a text file, extracts table and column codes based on prefix,
#     and generates a SQL SELECT statement string preserving column order.
#     Optionally saves the output. Adheres to specific project naming conventions.
# =============================================================================

# 📦 IMPORTS
import re
import os
import datetime # Required for timestamp

# =============================================================================
# 🧩 FUNCTION: create_sql_query_from_file
# =============================================================================
def create_sql_query_from_file(myVar_strInputDir, myVar_strInputFilename, myVar_strColumnPrefix, myVar_booSaveToFile=False):
    """
    Reads a text file line by line, extracts table and column codes,
    generates a SQL SELECT statement string preserving column order,
    and optionally saves it to a file.

    Args:
        myVar_strInputDir (str): The directory path containing the input file.
        myVar_strInputFilename (str): The name of the input text file.
        myVar_strColumnPrefix (str): The two-letter prefix for column codes (e.g., "GL", "SH").
        myVar_booSaveToFile (bool): If True, save the output SQL to a timestamped file
                                    in myVar_strInputDir. Defaults to False.

    Returns:
        str: The generated SQL query string, or an error message starting with "Error:".
    """
    # 🧠 Internal variables following convention
    myVar_strTableCode = None            # Stores the found table code
    # Use a dictionary to store unique columns while preserving insertion order
    myVar_dictOrderedColumnCodes = {}
    myVar_strFullInputPath = os.path.join(myVar_strInputDir, myVar_strInputFilename) # Construct full path

    # --- Input Validation ---
    # Check if the prefix is valid according to requirements
    if not (isinstance(myVar_strColumnPrefix, str) and len(myVar_strColumnPrefix) == 2 and myVar_strColumnPrefix.isalpha()):
         # Return error if validation fails
         return "Error: column_prefix must be exactly two alphabetic characters."

    # --- File Processing ---
    try:
        # Open the input file for reading
        with open(myVar_strFullInputPath, 'r') as myVar_filInputFile:
            # Process each line in the file
            for myVar_strLine in myVar_filInputFile:
                myVar_strLine = myVar_strLine.strip() # Remove leading/trailing whitespace
                if not myVar_strLine:
                    continue # Skip empty lines

                # --- Find Table Code (using the first one found) ---
                # Only search if table code hasn't been found yet
                if myVar_strTableCode is None:
                    # Use regex to find "TABLE: " followed by non-space characters
                    myVar_objTableMatch = re.search(r"TABLE:\s*(\S+)", myVar_strLine, re.IGNORECASE)
                    if myVar_objTableMatch:
                        # Store the captured table code (group 1 of the match)
                        myVar_strTableCode = myVar_objTableMatch.group(1)

                # --- Find Column Codes starting with the specified prefix ---
                # Use regex to find words starting with the prefix
                # \b ensures it's a word boundary
                myVar_lstColumnMatches = re.findall(rf"\b{re.escape(myVar_strColumnPrefix)}\S*", myVar_strLine, re.IGNORECASE)
                # Add all found codes to the dictionary
                for myVar_strCode in myVar_lstColumnMatches:
                    # Add code as key (preserves order, handles duplicates automatically)
                    # The value (True) doesn't really matter here, just needs to be present
                    myVar_dictOrderedColumnCodes[myVar_strCode] = True

    except FileNotFoundError:
        # Return specific error if file doesn't exist
        return f"Error: File not found at '{myVar_strFullInputPath}'"
    except Exception as myVar_errException:
        # Return generic error for other file processing issues
        # Include filename and the exception details for better debugging
        return f"Error processing file '{myVar_strFullInputPath}': {myVar_errException}"

    # --- Check if necessary codes were found after processing the file ---
    if not myVar_strTableCode:
        # Return error if no table code was extracted
        return f"Error: No 'TABLE: ' code found in file '{myVar_strInputFilename}'."
    # Check if the dictionary holding column codes is empty
    if not myVar_dictOrderedColumnCodes:
        # Return error if no column codes matching the prefix were found
        return f"Error: No column codes starting with '{myVar_strColumnPrefix}' found in file '{myVar_strInputFilename}'."

    # --- Construct the SQL String ---
    # Get the column names (keys) from the dictionary in their insertion order
    myVar_lstOrderedColumns = list(myVar_dictOrderedColumnCodes.keys())
    # Create the column selection part, e.g., "[Table].[Col1], [Table].[Col2]" using the ordered list
    myVar_strSelectColumnsPart = ", ".join([f"[{myVar_strTableCode}].[{myVar_strCol}]" for myVar_strCol in myVar_lstOrderedColumns])
    # Get the appropriate newline character for the OS
    myVar_strNewline = os.linesep

    # Assemble the final SQL query string
    myVar_strSQLQuery = f"SELECT TOP(100) {myVar_strSelectColumnsPart}{myVar_strNewline}"
    myVar_strSQLQuery += f"FROM [{myVar_strTableCode}]"

    # --- Optionally save the result to a file ---
    # Proceed only if the flag is set and query generation was successful
    if myVar_booSaveToFile:
        try:
            # Generate timestamp string for the filename
            myVar_strTimestamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
            # Create the output filename
            myVar_strOutputFilename = f"{myVar_strTimestamp}_{myVar_strInputFilename}_SQL_Output.txt"
            # Create the full path for the output file in the input directory
            myVar_strFullOutputPath = os.path.join(myVar_strInputDir, myVar_strOutputFilename)

            # Write the generated SQL query to the output file
            with open(myVar_strFullOutputPath, 'w') as myVar_filOutputFile:
                myVar_filOutputFile.write(myVar_strSQLQuery)
            # Note: Confirmation print is handled in the main script

        except Exception as myVar_errException:
            # Print a warning if saving fails, but don't stop the script
            # The generated SQL query will still be returned
            print(f"⚠️ Warning: Could not save SQL query to file '{myVar_strFullOutputPath}'. Error: {myVar_errException}")

    # --- Return the generated SQL string (or error message from earlier steps) ---
    return myVar_strSQLQuery

# =============================================================================
# 🧪 Optional Direct Execution Block (for testing this file alone)
# =============================================================================
# This code only runs if you execute `python my_pyfun_sql_generator.py` directly
if __name__ == "__main__":
    # Use convention within the test block as well
    myVar_strTestDir = '.' # Current directory for test
    myVar_strTestFile = 'temp_test_input.txt'
    myVar_strTestPrefix = 'GL'

    print("🩺 Testing sql_generator module directly...")
    print(f"Creating temporary test file: {myVar_strTestFile}")
    # Create a dummy file for the test using 'with open'
    try:
        with open(myVar_strTestFile, 'w') as myVar_filTestFile:
            myVar_filTestFile.write("TABLE: MyTestData\n")
            myVar_filTestFile.write("Some text GLCodeZ\n") # Added one before others
            myVar_filTestFile.write("Line: GLCodeA OtherData SHCodeA\n")
            myVar_filTestFile.write("Another GLCodeB value\n")
            myVar_filTestFile.write("Ignore this SHCodeB\n")
            myVar_filTestFile.write("GLCodeA again\n") # Test duplicate handling
            myVar_filTestFile.write("Final one GLCodeC\n")
    except Exception as myVar_errException:
        print(f"🔴 Error creating test file: {myVar_errException}")
        # Exit if test file cannot be created
        exit()

    # Call the function directly using test variables
    myVar_strTestResult = create_sql_query_from_file(
        myVar_strTestDir,
        myVar_strTestFile,
        myVar_strTestPrefix,
        myVar_booSaveToFile=False # Test without saving
    )

    print("\n📝 Test Result (Order should be GLCodeZ, GLCodeA, GLCodeB, GLCodeC):")
    print(myVar_strTestResult)

    # Clean up dummy file
    try:
        os.remove(myVar_strTestFile)
        print(f"\n🗑️ Removed temporary test file: {myVar_strTestFile}")
    except OSError as myVar_errException:
        print(f"\n⚠️ Could not remove temporary test file: {myVar_errException}")