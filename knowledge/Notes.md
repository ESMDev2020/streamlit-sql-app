# Programming Learning Notes Classification

## 1. Programming Languages

* **Python:** Interpreted, high-level language.
    * **Streamlit:** Python library for web app development (ML/Data Science).
        * `streamlit run <script.py>`: Executes a Streamlit application.
        * `streamlit cache clear`: Clears the Streamlit app's cache.
    * **Pandas:** Python library for data manipulation and analysis (DataFrames).
        * `import pandas as pd`: Imports the Pandas library.
        * `pd.DataFrame(data)`: Creates a Pandas DataFrame.
        * `df.head()`: Displays the first few rows of a DataFrame.
        * `df['column_name']`: Accesses a specific column in a DataFrame.
    * **Matplotlib:** Python 2D plotting library.
        * `import matplotlib.pyplot as plt`: Imports the Matplotlib plotting module.
        * `plt.plot(x, y)`: Creates a line plot.
        * `plt.scatter(x, y)`: Creates a scatter plot.
        * `plt.show()`: Displays the plot.
    * **Seaborn:** Python statistical data visualization library (built on Matplotlib).
        * `import seaborn as sns`: Imports the Seaborn library.
        * `sns.histplot(data['column'])`: Creates a histogram.
        * `sns.scatterplot(x='col1', y='col2', data=df)`: Creates a scatter plot.
    * **JSON:** Lightweight data-interchange format (text-based).
        * `import json`: Imports the `json` module in Python.
        * `json.loads(json_string)`: Parses a JSON string into a Python object.
        * `json.dumps(python_object)`: Serializes a Python object into a JSON string.

* **SQL:** Domain-specific language for RDBMS management.
    * **SELECT <columns> FROM <table> WHERE <condition>**: Retrieves data from a database.
    * **INSERT INTO <table> (<columns>) VALUES (<values>)**: Adds new data to a table.
    * **UPDATE <table> SET <column> = <value> WHERE <condition>**: Modifies existing data in a table.
    * **DELETE FROM <table> WHERE <condition>**: Removes data from a table.
    * **CREATE TABLE <table_name> (<column_definition>)**: Creates a new table.
    * **ALTER TABLE <table_name> <action>**: Modifies an existing table.
    * **DROP TABLE <table_name>**: Deletes a table.
    * **JOIN (INNER, LEFT, RIGHT) ON <join_condition>**: Combines data from multiple tables.

## 2. Application Packages

* **DBeaver:** Universal database client; supports various SQL/NoSQL DBMS.
    * **SQL Editor:** Writing and executing SQL queries.
    * **Data Editor:** Browsing and modifying table data.
    * **ER Diagram Viewer:** Visualizing database schemas.
    * **Database Navigator:** Exploring database objects (schemas, tables, etc.).
    * **Connection Manager:** Configuring and managing database connections.

* **VS Studio:** Comprehensive IDE supporting multiple languages.
    * **Code Editor:** Writing and editing source code (syntax highlighting, autocompletion).
    * **Debugger:** Stepping through code to identify and fix errors.
    * **Terminal:** Integrated command-line interface.
    * **Version Control (Git):** Built-in Git integration for managing repositories.
    * **Extensions:** Adding functionality for specific languages and tools.

* **Web Storm:** JavaScript IDE (JetBrains); provides coding assistance for web technologies.
    * **Code Editor (JavaScript, HTML, CSS):** Intelligent code completion, navigation, and refactoring.
    * **Debugger (JavaScript):** Inspecting and debugging JavaScript code.
    * **Terminal:** Integrated command-line interface.
    * **Version Control (Git):** Seamless Git integration.
    * **Build Tools Integration (npm, yarn):** Managing project dependencies and running tasks.

* **anvil.works:** Python web app development platform (GUI-based).
    * **Drag and Drop UI Builder:** Visually designing the application interface.
    * **Python Code Editor (Server-side and Client-side):** Writing Python logic.
    * **Data Tables:** Built-in database for storing application data.
    * **Deployment:** One-click deployment of web applications.

* **VERTABELLO:** ERD modeling tool.
    * **Entity Creation:** Defining tables and their attributes.
    * **Relationship Definition:** Specifying connections between entities (one-to-many, many-to-many).
    * **Diagram Layout:** Arranging entities and relationships visually.
    * **Export to SQL:** Generating SQL scripts from the diagram.

* **DBSCHEMA:** Database schema visualization tool.
    * **Reverse Engineering:** Generating diagrams from existing databases.
    * **Schema Browsing:** Exploring database objects.
    * **Diagram Customization:** Adjusting the visual representation of the schema.

* **Teamviewer:** Remote desktop/sharing application.
    * **Remote Control:** Controlling another computer's desktop.
    * **File Transfer:** Sending and receiving files between computers.
    * **Meetings and Collaboration:** Online meetings and screen sharing.

* **Cisco Secure Client:** VPN client for secure network connections.
    * **Connect/Disconnect:** Establishing and terminating VPN connections.
    * **Profile Selection:** Choosing different VPN connection profiles.
    * **Connection Status:** Monitoring the status of the VPN connection.

* **Obsidian:** Local Markdown-based knowledge base application (linking capabilities).
    * **Markdown Editor:** Creating and editing notes in Markdown format.
    * **Internal Linking:** Creating links between notes using `[[note title]]`.
    * **Graph View:** Visualizing the connections between your notes.
    * **Plugins:** Extending functionality with community or core plugins.

* **XCODE:** Apple's IDE for macOS, iOS, etc., development.
    * **Interface Builder:** Visually designing the application UI (storyboards, nibs).
    * **Code Editor (Swift, Objective-C):** Syntax highlighting, autocompletion.
    * **Debugger:** Debugging application code.
    * **Simulator:** Testing applications on virtual devices.
    * **Build and Run:** Compiling and executing applications.

## 3. Application Commands

* **Terminal/Command Line:** Text-based OS interface for command execution.
    * **Navigation:**
        * `cd <directory>`: Change the current directory.
        * `pwd`: Print the current working directory.
        * `mkdir <directory>`: Create a new directory.
        * `rm <file>`: Remove a file.
        * `rm -r <directory>`: Remove a directory and its contents recursively.
        * `cp <source> <destination>`: Copy files or directories.
        * `mv <source> <destination>`: Move or rename files or directories.
    * **File Inspection:**
        * `cat <file>`: Display the contents of a file.
        * `less <file>`: View file contents page by page.
        * `head <file>`: Display the first few lines of a file.
        * `tail <file>`: Display the last few lines of a file.
        * `grep <pattern> <file>`: Search for a pattern within a file.
    * **Process Management:**
        * `ps aux`: Display a list of running processes.
        * `kill <PID>`: Terminate a process by its Process ID.
        * `top` or `htop`: Display real-time system resource usage and processes.
    * **Network:**
        * `ping <hostname>` or `<IP address>`: Test network connectivity.
        * `ifconfig` (Linux/macOS) or `ipconfig` (Windows): Display network interface configuration.
        * `netstat -an`: Display network connections, listening ports, routing tables, etc.

* **PIP (Python Package Installer):** Python's package management system.
    * `pip install <package_name>`: Install a Python package from PyPI.
    * `pip uninstall <package_name>`: Uninstall a Python package.
    * `pip list`: Display a list of installed Python packages.
    * `pip show <package_name>`: Display information about an installed package.
    * `pip freeze > requirements.txt`: Generate a list of installed packages and their versions.
    * `pip install -r requirements.txt`: Install packages from a `requirements.txt` file.
    * `pip update <package_name>`: Upgrade a specific package to the latest version.

## 4. Version Control (Git)**

Distributed VCS for tracking file changes.

* **Basic Operations:**
    * `git init`: Initialize a new Git repository.
    * `git clone <repository_url>`: Clone a remote repository to your local machine.
    * `git add <file(s)>`: Stage changes for the next commit.
    * `git commit -m "<commit message>"`: Record staged changes with a descriptive message.
    * `git status`: Display the status of your working directory and staging area.
    * `git log`: View commit history.
    * `git show <commit_hash>`: Display details of a specific commit.
* **Branching and Merging:**
    * `git branch`: List your local branches.
    * `git branch <new_branch_name>`: Create a new branch.
    * `git checkout <branch_name>`: Switch to an existing branch.
    * `git merge <branch_to_merge>`: Integrate changes from another branch into the current branch.
    * `git branch -d <branch_to_delete>`: Delete a local branch.
* **Remote Repositories:**
    * `git remote add <name> <url>`: Add a new remote repository.
    * `git remote -v`: List configured remote repositories.
    * `git fetch <remote_name>`: Download commits and objects from a remote repository.
    * `git pull <remote_name> <branch_name>`: Fetch from and integrate with a remote branch.
    * `git push <remote_name> <branch_name>`: Upload local commits to a remote repository.

## 5. Database Concepts

* **ERD Tool:** Software for visual database schema modeling. (Commands are UI-driven for entity/relationship creation and manipulation).
* **SQL:** (See Programming Languages - SQL Commands).

## 6. Development Concepts

* **Python interpreter:** Program executing Python code. (Commands involve running Python scripts: `python <script.py>`).
* **Command Palette:** UI element for accessing IDE/editor commands (accessed via keyboard shortcuts like `Ctrl+Shift+P` or `Cmd+Shift+P`).
* **Palette:** Collection of tools/options within an application (UI-dependent).
* **JSON:** Standard data serialization format. (Operations typically done via programming language libraries like Python's `json` module).
* **Markdown format:** Lightweight markup language. (Formatting achieved through specific syntax in text files).
* **Virtual Environment:** Isolated Python environment for dependency management.
    * `python -m venv <venv_name>`: Create a new virtual environment.
    * `source <venv_name>/bin/activate` (Linux/macOS): Activate a virtual environment.
    * `<venv_name>\Scripts\activate` (Windows): Activate a virtual environment.
    * `deactivate`: Exit the current virtual environment.

## 7. Application Specific Notes

* **Sigma Data:** (Details regarding Sigma application data fields and calculations)
* **Freight Processes:** (Workflow and data related to freight operations)

## 8. Server/Cloud/Login Information (Sensitive - Use Caution)**

* **Passwords, Login Info:** (Details redacted for security - **Use a Password Manager**)
    * ...
* **Server/Cloud Information:** (Access and management often through web consoles or CLI tools specific to the provider - e.g., AWS CLI).
    * **AWS CLI (`aws <service> <command> --<option> <value>`):** Command-line interface for interacting with AWS services.
        * `aws ec2 describe-instances`: List EC2 instances.
        * `aws s3 ls <bucket_name>`: List objects in an S3 bucket.
        * `aws rds describe-db-instances`: List RDS database instances.
    * **SSH (`ssh <user>@<host>`):** Secure Shell for remote server access.

* save this
mv sql/01_SigmaTBMain2.py .     - moves before
 mkdir python   
  move *.py python      

* **new, to sort
mkdir               - make a directory
mv *.csv data/      - move all csv files to the directory
SPECIFY FUNCTION, SYNTAX, EXAMPLE

  function name, functionality, syntax, example

fold- unfold comments
Open the Command Palette:

    Press Ctrl + Shift + P (Windows/Linux)

    Or Cmd + Shift + P (Mac)
    Fold All
    Unfold All}

STREAMLIT
    - Clear cache - deletes variables
    - Rerun         - runs code from the beginning (stupid, it should always do it)


    
SAVE GIT 
git add .
git commit -m "Your commit message"
git push vssafe SigmaGit


GITHUB
My repository is SigmaTB_GitRepo
    -1 branches
        - SigmaBranch

    LOCAL machine
        Mac - SigmaTB_LocalRepo
        

   

CURSOR APP FOR PROGRAMMING

Print the names and values of an array in the debug console
[print("\r\n".join(f"{k}: {v}" for k, v in item.items()) + "\r\n") for item in myListRelationships]

terminal - pwd - local directory


------------------------------------------------------------------
    NOTES FOR DOCUMENTATION
------------------------------------------------------------------
    
    
1.- Documentation
	Add comments describing what execution block does 
2.- Naming convention
    All variables and constants must be explicity defined
    All variables and constants must be declared at the beginning of the file, and at the beginning of each sub or function as well as initial values
    when assigning number to variables, you need to comment what are you doing for
	Rename variables. They should start with "my" & "var" & datatype & name
	Rename constants. They should start with "my" & "con" & datatype & name
	Subprocedures and functions should start with "sub_" & name of subprocedure.
    all subprocedures and functions must have a description comment inside the procedure summarizing the procedure and variables used and returned, and a note before the procedure narrating the steps we are executing. local variables (inside the sub or function) must be declared. 
	Functions should start with "fun_" and the name of the function. 
	Commands. they should start with "Com_" and the name of the command.
    Control loops, cycles, cases, if, must include a comment section inside describing the logic, conditions, variables and exit data.  
3.- Progress
	 Before starting execution print a timestamp "starting execution", and another one when finishing. 
     Add progress bar & messages when running cycles or multiple commands. 
4.- Error handling
	Add error control and description
-----------------------
REARRANGING IN FUNCTIONS AND SUBPROCEDURES WNEN USING PYTON
- IMPORTS
- CONSTANTS
- FUNCTIONS
- Function 1
- Function 2
- Function 3...n
- if has a GUI like STREAMLIT UI, leave the code (for local testing) 
- 
------------------------
-----------------------
WHEN USING SQL 
- Add documentation at the beginning about the stored procedure
   - Name
   - Description of functionality
   - Input: Parameters
   - Output: If any table or SP is created, list the names
   - Whatever other detail, such as author, creation date, version, etc. 

- Examples: 
    - At the end add commented examples about how to use it
- Examples: 
    - At the end add commented an example of the resultset (column names, column values)
- Debug: 
    - Add an input parameter @DebugMode. 1 means debug, 0 means "no debug".    
    - Debug means print progress of the SP. no debug means silent execution
    - All the queries you execute must be stored into a variabe. On debug mode, you should print that variable in terminal
- Data integrity
  - No destructive functions should be included without advise (like drop tables)
- Safety
  - When possible, use transactions, to roll back if errors occur
- Name conventions
  - all table names, schema names, column names should be enclosed in []
- Error avoidance
    - have attention with the use of ";"
    - Do not use "rowcount" to name columns because causes an error. Rowcount is a reserved word in SQL Server
    - When creating cursors, have precaution to check if they exist before to avoid an error of "existing cursor "16915


    --CONNECTION STRING
        - # ────────────────────────────────────────────────────────────────────────────
        # 📜 CONSTANTS (Defined directly in the main script)
        # ────────────────────────────────────────────────────────────────────────────
        myCon_strDbServer = "database-3.c67ymu6q22o1.us-east-1.rds.amazonaws.com"
        myCon_strDbDatabase = "SigmaTB"
        myCon_strDbUsername = "admin"
        myCon_strDbPassword = "Er1c41234$" # !! Use secrets !!


    - SERVER
        - - Database: SigmaTB
        - Schema: mrs
        - SQL Server version: 
        - ServerName	EC2AMAZ-7QANEJ3
        - FullServerName	EC2AMAZ-7QANEJ3
        - InstanceName	    NULL
        - CurrentLogin	    admin
        - CurrentDatabase	SigmaTB
        - SystemUser	    admin
        - SessionUser	    admin
        - OriginalLogin	    admin
        - ServerIPAddress	172.31.90.187
        - Protocol	        TSQL
        - AuthScheme	    SQL
        - SQLVersionMicrosoft SQL Server 2019 (RTM-CU31) (KB5049296) - 15.0.4420.2 (X64)   Jan 25 2025 12:20:14   Copyright (C) 2019 Microsoft Corporation  Standard Edition (64-bit) on Windows Server 2016 Datacenter 10.0 <X64> (Build 14393: ) (Hypervisor) 
			


- LOCAL
		ServerName:         STB-LT-ES
		FullServerName:     STB-LT-ES
		InstanceName:       NULL
		CurrentUser:        dbo
		CurrentDatabase:    master
		SystemUser:         sa
		SessionUser:        dbo
		OriginalLogin:      sa
		ServerIPAddress:    NULL
		Protocol:           TSQL
		AuthScheme:         SQL
		SQLVersion:         Microsoft SQL Server 2019 (RTM) - 15.0.2000.5 (X64)  Sep 24 2019 13:48:23  Copyright (C) 2019 Microsoft Corporation  Developer Edition (64-bit) on Windows 10 Pro 10.0 <X64> (Build 22631: ) (Hypervisor)
	
     cd ~/Documents/GitHub/SigmaTB_LocalRepo
        git init
        git remote add origin https://github.com/ESMDev2020/SigmaTB_GitRepo.git
        git remote -v
        Branches:   https://github.com/ESMDev2020/SigmaTB_GitRepo/branches

        update local clone
        git branch -m SigmaGit SigmaBranch
        git fetch origin
        git branch -u origin/SigmaBranch SigmaBranch
        git remote set-head origin -a

    DOCUWARE
       	User:			esaavedra
	        Pwd:			Sigmatb2013
	        Database:		dwdata
	        TCP/IP Server	stb-app02
	        Port			3306
	



OUR PROJECT
-- We differenciate AS400 names and MSSQL names. Both names refer to the same table, but one is in code, the other is human readable
- in our MSSQL database, the structure is:
-   Table 
  -     - has a Table name
  -  Table name is composed of 
     - "z_" - Identifies the tables of our project
     - "?????????" - Identifies the description of the table
     - "_____" - Separates the description from the code
     - "?????" - table code
     - for example: "z_Customer_Master_File_____ARCUST"
  -     - on extended properties, it has
  -      property name = table code
  -       property value = table descrition = table name
  - 

    columns
  -     has a Column name
     - does not start with "z_" because it belong to a table previously identified
     - "?????????" - Identifies the description of the column
     - "_____" - Separates the description from the code
     - "?????" - column code
     - for example: "CUSTOMER_NUMBER_____CCUST"

  -     on extended properties, it has
  -      property name = column code
  -      property value = column descrition = column name
 
 - Tables that contain information
 - Start with "z_". Every query that executes a "for each table" has to query only tables with "z_" prefix. 
 - The tables that does not start with "z_" are programming tables, for queries, but does not contain ERP information
 - 



email when finish
add progress bar, messages and error control and description
---------------------------


rearrange it like it is the file "01_SigmaTBMain2.py", meaning:




---------------------------------------------------------

Okay, here's an organized version of your AI tool documentation notes, followed by suggestions.

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

**Suggestions for Improvement**

1.  **Consistency:** The key is applying these rules *consistently* across all code generated or modified with AI tools.
2.  **Simplify Naming (Optional):** While your naming convention (`my_var_datatype_name`) is explicit, it can become verbose. Consider if a simpler convention (e.g., `var_name`, `CONST_NAME`, relying on type hints in Python, or standard SQL conventions) might improve readability without losing clarity, especially in languages with strong typing or good IDE support.
3.  **Readability Focus:** Aim for code that is as self-documenting as possible through clear naming and structure. Comments should explain the *why*, not just the *what*, if the *what* is already clear from the code.
4.  **Version Control:** Use Git or another version control system. Commit messages should clearly state the changes made, including any AI assistance.
5.  **Code Review:** Have peers (or yourself, after a break) review AI-generated code against these standards before finalizing.
6.  **Tooling:** Use linters (like Pylint/Flake8 for Python) and code formatters (like Black for Python, SQL formatters) to automatically enforce some style consistency.