
**Organized Documentation Guidelines**

**I. General Best Practices (Apply to all code)**

1.  **Commenting:**
    * Add comments describing the purpose of each execution block, loop (if, case, etc.), or complex logic section.
    * Comment variable/constant assignments if the purpose isn't immediately obvious from the name/context.
2.  **Variable & Constant Handling:**
    * Explicitly define/declare all variables and constants.
    * Declare them at the beginning of the file and/or function/subprocedure scope.
    * Assign initial values where appropriate.
3.  **Progress Indication:**
    * Print start and end timestamps for script execution.
    * Use progress messages or bars for long-running loops or processes.
4.  **Error Handling:**
    * Implement error control mechanisms (e.g., try-except blocks).
    * Provide descriptive error messages.

**II. Python Specific Guidelines**

1.  **File Structure:**
    * Imports
    * Constants
    * Functions (Define all functions before main execution logic)
    * Main execution block (potentially under `if __name__ == "__main__":`)
    * Keep GUI code (like Streamlit UI) separate or clearly marked for local testing if applicable.
2.  **Naming Conventions:**
    * **Variables:** `my_var_datatype_name`
    * **Constants:** `my_con_datatype_name`
    * **Functions:** `fun_function_name`
    * **Subprocedures (if applicable):** `sub_subprocedure_name` (Note: Python primarily uses functions)
    * **Commands (if custom command objects):** `Com_command_name`
3.  **Function/Subprocedure Documentation:**
    * Include a docstring (using `"""Docstring goes here"""`) inside each function summarizing its purpose, parameters (variables used), and return values.
    * Declare local variables at the start of the function.

**III. SQL Specific Guidelines (Stored Procedures, Queries)**

1.  **Header Documentation (Beginning of Stored Procedure):**
    * `Name:` Stored Procedure name.
    * `Description:` Functionality overview.
    * `Input:` List parameters and their purpose.
    * `Output:` Describe tables created/modified or result sets returned.
    * `Metadata:` Author, Creation Date, Version, Target Server/DB details (SQL Server Version, ServerName, Database, Schema).
    * `Example Usage:` Commented examples of how to execute the procedure.
    * `Example Resultset:` Commented example showing expected output columns and sample data.
2.  **Debugging:**
    * Include an `@DebugMode` input parameter (e.g., `BIT` or `INT`, 1=Debug, 0=Normal).
    * Store dynamic SQL queries in variables.
    * In Debug Mode (`@DebugMode = 1`), `PRINT` the query variable before execution and add progress messages.
3.  **Safety & Integrity:**
    * Use transactions (`BEGIN TRANSACTION`, `COMMIT`, `ROLLBACK`) for operations that modify data, especially multiple steps.
    * Avoid destructive commands (like `DROP TABLE`) without clear warnings or conditional checks (e.g., only in specific modes or if objects exist).
4.  **Naming Conventions:**
    * Enclose all schema, table, and column names in square brackets `[]` (e.g., `[schema_name].[table_name]`).
5.  **Error Avoidance:**
    * Be mindful of semicolon `;` placement, especially with CTEs or multiple statements.
    * Do not use reserved words like `rowcount` as column aliases.
    * Check if cursors exist (`IF CURSOR_STATUS('global','cursor_name') >= -1 ...`) before declaring them to avoid errors.

**IV. Project Specific SQL Conventions (SigmaTB Database, 'mrs' Schema)**

1.  **Table Identification:**
    * Use prefix `z_` for tables containing primary ERP data originating from AS400.
    * Tables *without* `z_` are considered programming/utility tables. Queries iterating through ERP data should filter for `WHERE name LIKE 'z_%'`.
2.  **Table Naming Structure:**
    * Format: `z_Description_____Code` (e.g., `z_Customer_Master_File_____ARCUST`)
    * `Description`: Human-readable name.
    * `Code`: Corresponding AS400 table/file name.
3.  **Column Naming Structure:**
    * Format: `Description_____Code` (e.g., `CUSTOMER_NUMBER_____CCUST`)
    * (No `z_` prefix for columns).
4.  **Extended Properties:**
    * **Tables:** Store `property_name = table_code`, `property_value = table_description`.
    * **Columns:** Store `property_name = column_code`, `property_value = column_description`.

---

