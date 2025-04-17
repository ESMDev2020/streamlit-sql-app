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



    NOTES FOR DOCUMENTATION
    
1.- Documentation
	Add comments describing what execution block does 
2.- Naming convention
    All variables and constants must be explicity defined
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
REARRANGING IN FUNCTIONS AND SUBPROCEDURES
- IMPORTS
- CONSTANTS
- FUNCTIONS
- Function 1
- Function 2
- Function 3...n
- if has a GUI like STREAMLIT UI, leave the code (for local testing) 
- 
------------------------

email when finish
add progress bar, messages and error control and description
---------------------------


rearrange it like it is the file "01_SigmaTBMain2.py", meaning:




---------------------------------------------------------


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

CURSOR APP FOR PROGRAMMING


This expanded document now includes common and important commands or functionalities associated with each application or concept in your list. Remember that the specific commands and options can be extensive, so this focuses on the most fundamental ones to get you started.