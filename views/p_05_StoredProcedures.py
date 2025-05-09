# ════════════════════════════════════════════════════════════════════════════
# 🗄️ STREAMLIT MODULE - STORED PROCEDURES MANAGER
# DESCRIPTION:
#   This module provides functionality to organize, execute, and view results 
#   from stored procedures directly in the Streamlit interface.
#   - Follows standard naming conventions: myVar_, myCon_, sub_, fun_, Com_
#   - Includes section headers, documentation, and error handling
# ════════════════════════════════════════════════════════════════════════════

# 📦 Required Imports
import streamlit as Com_st
import pandas as Com_pd
import json
import os
from datetime import datetime
import traceback
import re
import base64
import io

# ────────────────────────────────────────────────────────────────────────────
# 📜 CONSTANTS
# ────────────────────────────────────────────────────────────────────────────
myCon_strProceduresJsonPath = "assets/procedures.json"
myCon_strDefaultCategory = "SQL Translation"

# ────────────────────────────────────────────────────────────────────────────
# 🔧 UTILITY FUNCTIONS
# ────────────────────────────────────────────────────────────────────────────
def fun_loadProcedures():
    """
    Loads stored procedures from JSON file.
    
    Returns:
        dict: Dictionary of procedures by category, or empty dict if file not found
    """
    try:
        # Create directory if it doesn't exist
        os.makedirs(os.path.dirname(myCon_strProceduresJsonPath), exist_ok=True)
        
        # Create file with empty structure if it doesn't exist
        if not os.path.exists(myCon_strProceduresJsonPath):
            with open(myCon_strProceduresJsonPath, 'w') as myVar_fileOut:
                json.dump({}, myVar_fileOut)
            return {}
        
        # Load procedures from file
        with open(myCon_strProceduresJsonPath, 'r') as myVar_fileIn:
            return json.load(myVar_fileIn)
    except Exception as myVar_objException:
        Com_st.error(f"❌ Error loading procedures: {myVar_objException}")
        return {}

def fun_saveProcedures(myPar_dictProcedures):
    """
    Saves procedures to JSON file.
    
    Args:
        myPar_dictProcedures (dict): Dictionary of procedures by category
    
    Returns:
        bool: True if successful, False otherwise
    """
    try:
        # Create directory if it doesn't exist
        os.makedirs(os.path.dirname(myCon_strProceduresJsonPath), exist_ok=True)
        
        # Save procedures to file
        with open(myCon_strProceduresJsonPath, 'w') as myVar_fileOut:
            json.dump(myPar_dictProcedures, myVar_fileOut, indent=2)
        return True
    except Exception as myVar_objException:
        Com_st.error(f"❌ Error saving procedures: {myVar_objException}")
        return False

def fun_executeProcedure(myPar_objDbEngine, myPar_strQuery, myPar_dictParams=None):
    """
    Executes a SQL query or procedure with optional parameters.
    
    Args:
        myPar_objDbEngine: SQLAlchemy database engine
        myPar_strQuery (str): SQL query or procedure call
        myPar_dictParams (dict, optional): Parameters to substitute in the query
    
    Returns:
        dict: Dictionary with keys 'success', 'data', and 'error' (if applicable)
    """
    try:
        myVar_strProcessedQuery = myPar_strQuery
        
        # Apply parameter substitutions if provided
        if myPar_dictParams:
            for myVar_strParam, myVar_strValue in myPar_dictParams.items():
                # Handle the special case for SQL query translation
                if myVar_strParam == "SQLQuery" and "@SQLQuery" in myVar_strProcessedQuery:
                    myVar_strProcessedQuery = myVar_strProcessedQuery.replace("@SQLQuery", myVar_strValue)
                    continue
                
                # Pattern to match parameter declarations, capturing relevant parts for replacement
                myVar_strPattern = r'(@\s*' + re.escape(myVar_strParam) + r'\s*=\s*)[^,\s)]+(\s*)'
                
                # Perform replacement with proper type handling
                if myVar_strValue.strip().startswith("'") or myVar_strValue.strip().startswith("N'"):
                    # Already formatted as string
                    myVar_strProcessedQuery = re.sub(myVar_strPattern, r'\1' + myVar_strValue + r'\2', myVar_strProcessedQuery)
                elif myVar_strValue.strip().isnumeric():
                    # Numeric value
                    myVar_strProcessedQuery = re.sub(myVar_strPattern, r'\1' + myVar_strValue + r'\2', myVar_strProcessedQuery)
                else:
                    # Default to string with N prefix for Unicode support
                    myVar_strProcessedQuery = re.sub(myVar_strPattern, r'\1N\'' + myVar_strValue + r'\'\2', myVar_strProcessedQuery)
        
        # Execute query
        myVar_pdResult = Com_pd.read_sql(myVar_strProcessedQuery, myPar_objDbEngine)
        
        return {
            "success": True,
            "data": myVar_pdResult
        }
    except Exception as myVar_objException:
        return {
            "success": False,
            "error": str(myVar_objException),
            "traceback": traceback.format_exc()
        }

def fun_parseParameters(myPar_strQuery):
    """
    Parses declared parameters from a SQL query.
    
    Args:
        myPar_strQuery (str): SQL query with parameter declarations
    
    Returns:
        dict: Dictionary of parameter names and default values
    """
    myVar_dictParams = {}
    
    # Pattern to match DECLARE statements with parameter name and value
    myVar_strPattern = r'DECLARE\s+(@\w+)\s+[^=]+=\s+([^;\n]+)'
    myVar_listMatches = re.findall(myVar_strPattern, myPar_strQuery, re.IGNORECASE)
    
    for myVar_strParam, myVar_strValue in myVar_listMatches:
        # Extract just the parameter name without the @ symbol
        myVar_strParamName = myVar_strParam.strip('@')
        myVar_dictParams[myVar_strParamName] = myVar_strValue.strip()
    
    return myVar_dictParams

def fun_getDownloadLink(myPar_strText, myPar_strFileName="result.txt", myPar_strLinkText="Download"):
    """
    Creates a download link for text content.
    
    Args:
        myPar_strText (str): The text content to download
        myPar_strFileName (str): The name of the downloaded file
        myPar_strLinkText (str): The text to display for the download link
    
    Returns:
        str: HTML for the download link
    """
    # Create a BytesIO object
    myVar_objBuffer = io.BytesIO()
    myVar_objBuffer.write(myPar_strText.encode())
    myVar_objBuffer.seek(0)
    
    # Base64 encode the BytesIO content
    myVar_strB64 = base64.b64encode(myVar_objBuffer.read()).decode()
    
    # Create the download link
    myVar_strHref = f'<a href="data:file/txt;base64,{myVar_strB64}" download="{myPar_strFileName}">{myPar_strLinkText}</a>'
    
    return myVar_strHref

# ────────────────────────────────────────────────────────────────────────────
# 🎨 UI COMPONENTS & FUNCTIONS
# ────────────────────────────────────────────────────────────────────────────
def sub_displayProcedureEditor(myPar_strProcedureName=None, myPar_dictProcedure=None, myPar_strCategory=None):
    """
    Displays the procedure editor form.
    
    Args:
        myPar_strProcedureName (str, optional): Name of procedure to edit
        myPar_dictProcedure (dict, optional): Procedure data if editing
        myPar_strCategory (str, optional): Category if adding new procedure
    """
    myVar_strFormMode = "Edit" if myPar_dictProcedure else "Add"
    myVar_strCategory = myPar_strCategory or myCon_strDefaultCategory
    
    with Com_st.form(f"{myVar_strFormMode.lower()}-procedure-form"):
        Com_st.subheader(f"{myVar_strFormMode} Stored Procedure")
        
        # Category field
        myVar_strCategory = Com_st.text_input(
            "Category", 
            value=myPar_strCategory if myPar_strCategory else myVar_strCategory,
            key="sp_category"
        )
        
        # Name field
        myVar_strName = Com_st.text_input(
            "Procedure Name", 
            value=myPar_strProcedureName if myPar_strProcedureName else "",
            key="sp_name"
        )
        
        # Description field
        myVar_strDescription = Com_st.text_area(
            "Description",
            value=myPar_dictProcedure.get("description", "") if myPar_dictProcedure else "",
            key="sp_description"
        )
        
        # SQL Code field
        myVar_strCode = Com_st.text_area(
            "SQL Code",
            value=myPar_dictProcedure.get("code", "") if myPar_dictProcedure else "",
            height=300,
            key="sp_code"
        )
        
        # Auto-detect parameters option
        myVar_boolAutoDetectParams = Com_st.checkbox(
            "Auto-detect parameters from SQL Code", 
            value=True,
            key="sp_auto_detect"
        )
        
        # Parameter field (only shown if not auto-detecting)
        myVar_strParameters = "{}"
        if not myVar_boolAutoDetectParams:
            myVar_strParameters = Com_st.text_area(
                "Parameters (JSON format)",
                value=json.dumps(myPar_dictProcedure.get("parameters", {}), indent=2) if myPar_dictProcedure else "{}",
                height=150,
                key="sp_parameters"
            )
        
        # Submit button
        myVar_boolSubmitted = Com_st.form_submit_button(f"{myVar_strFormMode} Procedure")
        
        if myVar_boolSubmitted:
            # Validate form
            if not myVar_strName:
                Com_st.error("❌ Procedure name is required.")
                return False
            
            if not myVar_strCode:
                Com_st.error("❌ SQL Code is required.")
                return False
            
            # Auto-detect parameters if enabled
            myVar_dictParameters = {}
            if myVar_boolAutoDetectParams:
                myVar_dictParameters = fun_parseParameters(myVar_strCode)
            else:
                try:
                    myVar_dictParameters = json.loads(myVar_strParameters)
                except json.JSONDecodeError:
                    Com_st.error("❌ Invalid JSON in parameters field.")
                    return False
            
            # Load existing procedures
            myVar_dictProcedures = fun_loadProcedures()
            
            # Create category if it doesn't exist
            if myVar_strCategory not in myVar_dictProcedures:
                myVar_dictProcedures[myVar_strCategory] = []
            
            # Create or update procedure
            myVar_dictNewProcedure = {
                "name": myVar_strName,
                "description": myVar_strDescription,
                "code": myVar_strCode,
                "parameters": myVar_dictParameters
            }
            
            # If editing, remove old version
            if myPar_dictProcedure:
                myVar_dictProcedures[myVar_strCategory] = [
                    p for p in myVar_dictProcedures[myVar_strCategory] 
                    if p["name"] != myPar_strProcedureName
                ]
            
            # Add new procedure
            myVar_dictProcedures[myVar_strCategory].append(myVar_dictNewProcedure)
            
            # Save procedures
            if fun_saveProcedures(myVar_dictProcedures):
                Com_st.success(f"✅ Procedure '{myVar_strName}' {myVar_strFormMode.lower()}ed successfully.")
                return True
            else:
                Com_st.error(f"❌ Failed to {myVar_strFormMode.lower()} procedure.")
                return False
    
    return False

def sub_displayExecuteProcedure(myPar_objDbEngine, myPar_dictProcedure, myPar_strCategory):
    """
    Displays the execute procedure form.
    
    Args:
        myPar_objDbEngine: SQLAlchemy database engine
        myPar_dictProcedure (dict): Procedure data
        myPar_strCategory (str): Category name
    """
    myVar_strProcedureName = myPar_dictProcedure["name"]
    myVar_strCode = myPar_dictProcedure["code"]
    myVar_dictParameters = myPar_dictProcedure.get("parameters", {})
    
    Com_st.subheader(f"🚀 Execute: {myVar_strProcedureName}")
    
    # Display description if available
    if myPar_dictProcedure.get("description"):
        Com_st.info(myPar_dictProcedure["description"])
    
    # SQL Code editor - Only for non-translation procedures
    if myVar_strProcedureName != "Translate Query":
        myVar_strEditedCode = Com_st.text_area(
            "SQL Code (Editable)",
            value=myVar_strCode,
            height=250,
            key=f"exec_code_{myVar_strProcedureName}"
        )
    else:
        # For SQL translation, we don't need to show the code
        myVar_strEditedCode = myVar_strCode
    
    # Parameter inputs
    myVar_dictParamValues = {}
    
    # Special handling for "Translate Query" procedure
    if myVar_strProcedureName == "Translate Query":
        # Input query - larger text area for SQL to translate
        myVar_dictParamValues["SQLQuery"] = Com_st.text_area(
            "SQL Query to Translate",
            value=myVar_dictParameters.get("SQLQuery", ""),
            height=200,
            key="translate_query_input"
        )
        
        # Debug and Execution options in columns
        myVar_colDM, myVar_colEM = Com_st.columns(2)
        
        with myVar_colDM:
            myVar_dictParamValues["DebugMode"] = "1" if Com_st.checkbox(
                "Debug Mode",
                value=myVar_dictParameters.get("DebugMode", "0") == "1",
                key="debug_mode"
            ) else "0"
            Com_st.caption("Shows detailed processing info")
        
        with myVar_colEM:
            myVar_dictParamValues["Execution"] = "1" if Com_st.checkbox(
                "Execution Mode",
                value=myVar_dictParameters.get("Execution", "0") == "1",
                key="execution_mode"
            ) else "0"
            Com_st.caption("Execute the translated query")
    
    # Standard parameters for other procedures
    elif myVar_dictParameters:
        Com_st.subheader("Parameters")
        
        # Create columns for parameters (3 columns per row)
        myVar_intNumParams = len(myVar_dictParameters)
        myVar_intNumRows = (myVar_intNumParams + 2) // 3  # Ceiling division
        
        myVar_listParams = list(myVar_dictParameters.items())
        
        for myVar_intRow in range(myVar_intNumRows):
            myVar_listColumns = Com_st.columns(3)
            
            for myVar_intCol in range(3):
                myVar_intIndex = myVar_intRow * 3 + myVar_intCol
                
                if myVar_intIndex < myVar_intNumParams:
                    myVar_strParamName, myVar_strDefaultValue = myVar_listParams[myVar_intIndex]
                    
                    # Clean default value for display
                    myVar_strCleanDefault = myVar_strDefaultValue.strip()
                    if myVar_strCleanDefault.startswith("N'") and myVar_strCleanDefault.endswith("'"):
                        myVar_strCleanDefault = myVar_strCleanDefault[2:-1]  # Remove N' and '
                    elif myVar_strCleanDefault.startswith("'") and myVar_strCleanDefault.endswith("'"):
                        myVar_strCleanDefault = myVar_strCleanDefault[1:-1]  # Remove ' and '
                    
                    # Input field for parameter
                    myVar_dictParamValues[myVar_strParamName] = myVar_listColumns[myVar_intCol].text_input(
                        f"{myVar_strParamName}",
                        value=myVar_strCleanDefault,
                        key=f"param_{myVar_strProcedureName}_{myVar_strParamName}"
                    )
    
    # Execute button
    if Com_st.button("▶️ Execute", key=f"execute_btn_{myVar_strProcedureName}"):
        with Com_st.spinner("Executing..."):
            # Execute the procedure
            myVar_dictResult = fun_executeProcedure(
                myPar_objDbEngine,
                myVar_strEditedCode,
                myVar_dictParamValues
            )
            
            if myVar_dictResult["success"]:
                # Display results
                Com_st.success(f"✅ Execution completed at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
                
                # Special handling for "Translate Query" procedure
                if myVar_strProcedureName == "Translate Query" and "TranslatedQuery" in myVar_dictResult["data"].columns:
                    myVar_strTranslatedQuery = myVar_dictResult["data"].iloc[0]['TranslatedQuery']
                    
                    # Display translated query
                    Com_st.subheader("Translated Query")
                    Com_st.code(myVar_strTranslatedQuery, language="sql")
                    
                    # Download options
                    myVar_colCopy, myVar_colDownloadSQL, myVar_colDownloadCSV = Com_st.columns(3)
                    
                    # Copy to clipboard button
                    with myVar_colCopy:
                        Com_st.markdown("""
                        <button onclick="navigator.clipboard.writeText(document.getElementById('translated-query-text').innerText); alert('Copied to clipboard!');" 
                                style="background-color: #007BFF; color: white; border: none; padding: 0.5em 1em; border-radius: 4px; cursor: pointer;">
                            📋 Copy to Clipboard
                        </button>
                        
                        <div id="translated-query-text" style="display: none;">
                        {}
                        </div>
                        """.format(myVar_strTranslatedQuery.replace('\n', '\\n').replace('"', '\\"')), unsafe_allow_html=True)
                    
                    # Download as SQL file
                    with myVar_colDownloadSQL:
                        Com_st.download_button(
                            label="💾 Download as SQL",
                            data=myVar_strTranslatedQuery,
                            file_name="translated_query.sql",
                            mime="text/plain",
                            key="download_sql"
                        )
                    
                    # Download as CSV file
                    with myVar_colDownloadCSV:
                        myVar_pdDf = Com_pd.DataFrame({'TranslatedQuery': [myVar_strTranslatedQuery]})
                        Com_st.download_button(
                            label="📊 Download as CSV",
                            data=myVar_pdDf.to_csv(index=False),
                            file_name="translated_query.csv",
                            mime="text/csv",
                            key="download_csv"
                        )
                
                # Standard results display for other procedures
                elif len(myVar_dictResult["data"]) > 0:
                    Com_st.subheader("Results")
                    
                    # Show results in interactive data table
                    Com_st.dataframe(
                        myVar_dictResult["data"],
                        use_container_width=True
                    )
                    
                    # Download button for results
                    myVar_strCsv = myVar_dictResult["data"].to_csv(index=False)
                    Com_st.download_button(
                        label="📥 Download Results as CSV",
                        data=myVar_strCsv,
                        file_name=f"{myVar_strProcedureName}_results_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv",
                        mime="text/csv",
                        key=f"download_{myVar_strProcedureName}"
                    )
                else:
                    Com_st.info("Query executed successfully, but returned no results.")
            else:
                # Display error
                Com_st.error(f"❌ Execution failed: {myVar_dictResult['error']}")
                Com_st.expander("Error Details").code(myVar_dictResult.get("traceback", "No traceback available"))

# ────────────────────────────────────────────────────────────────────────────
# 🖥️ MAIN VIEW FUNCTIONS
# ────────────────────────────────────────────────────────────────────────────
def sub_displayStoredProceduresView(myPar_objDbEngine):
    """
    Main entry point for the Stored Procedures module.
    
    Args:
        myPar_objDbEngine: SQLAlchemy database engine
    """
    # Header and description
    Com_st.title("🗄️ Stored Procedures Manager")
    Com_st.markdown("""
    This tool allows you to manage and execute SQL stored procedures directly from the web interface.
    Organize procedures by category, provide parameters, and view results instantly.
    """)
    
    # Load procedures
    myVar_dictProcedures = fun_loadProcedures()
    
    # Create tabs for categories, management
    myVar_listTabs = ["📋 Procedures"]
    
    # Add category tabs if they exist
    if myVar_dictProcedures:
        myVar_listTabs.extend([f"📁 {category}" for category in myVar_dictProcedures.keys()])
    
    myVar_listTabs.append("➕ Add New")
    
    myVar_strSelectedTab = Com_st.tabs(myVar_listTabs)
    
    # "Procedures" tab - Overview of all procedures
    if myVar_strSelectedTab[0].selectbox(
        "View procedures by category",
        options=["All Categories"] + list(myVar_dictProcedures.keys()),
        key="overview_category"
    ) == "All Categories":
        # Display all procedures
        for myVar_strCategory, myVar_listCategoryProcedures in myVar_dictProcedures.items():
            with myVar_strSelectedTab[0].expander(f"📁 {myVar_strCategory} ({len(myVar_listCategoryProcedures)})"):
                for myVar_dictProcedure in myVar_listCategoryProcedures:
                    Com_st.markdown(f"**{myVar_dictProcedure['name']}**")
                    if myVar_dictProcedure.get("description"):
                        Com_st.markdown(myVar_dictProcedure["description"])
                    Com_st.markdown("---")
    else:
        # Display selected category
        myVar_strCategory = myVar_strSelectedTab[0].session_state.overview_category
        with myVar_strSelectedTab[0].expander(f"📁 {myVar_strCategory} ({len(myVar_dictProcedures[myVar_strCategory])})"):
            for myVar_dictProcedure in myVar_dictProcedures[myVar_strCategory]:
                Com_st.markdown(f"**{myVar_dictProcedure['name']}**")
                if myVar_dictProcedure.get("description"):
                    Com_st.markdown(myVar_dictProcedure["description"])
                Com_st.markdown("---")
    
    # Category tabs - Display procedures in each category
    myVar_intTabIndex = 1
    for myVar_strCategory in myVar_dictProcedures.keys():
        with myVar_strSelectedTab[myVar_intTabIndex]:
            # Display procedures in this category
            for myVar_dictProcedure in myVar_dictProcedures[myVar_strCategory]:
                with Com_st.expander(f"📝 {myVar_dictProcedure['name']}", expanded=False):
                    # Two columns: Details and Actions
                    myVar_colDetails, myVar_colActions = Com_st.columns([3, 1])
                    
                    # Display procedure details
                    with myVar_colDetails:
                        if myVar_dictProcedure.get("description"):
                            Com_st.info(myVar_dictProcedure["description"])
                        
                        # Show parameter summary if they exist
                        if myVar_dictProcedure.get("parameters"):
                            Com_st.markdown("**Parameters:**")
                            for myVar_strParam, myVar_strDefault in myVar_dictProcedure["parameters"].items():
                                Com_st.markdown(f"- `{myVar_strParam}`: {myVar_strDefault}")
                    
                    # Action buttons
                    with myVar_colActions:
                        myVar_colButtons1, myVar_colButtons2 = Com_st.columns(2)
                        
                        # Edit button
                        if myVar_colButtons1.button("✏️ Edit", key=f"edit_{myVar_dictProcedure['name']}"):
                            Com_st.session_state.edit_procedure = {
                                "category": myVar_strCategory,
                                "name": myVar_dictProcedure["name"],
                                "data": myVar_dictProcedure
                            }
                        
                        # Delete button
                        if myVar_colButtons2.button("🗑️ Delete", key=f"delete_{myVar_dictProcedure['name']}"):
                            if Com_st.warning(f"Are you sure you want to delete '{myVar_dictProcedure['name']}'?"):
                                myVar_dictUpdatedProcedures = fun_loadProcedures()
                                myVar_dictUpdatedProcedures[myVar_strCategory] = [
                                    p for p in myVar_dictUpdatedProcedures[myVar_strCategory] 
                                    if p["name"] != myVar_dictProcedure["name"]
                                ]
                                
                                if fun_saveProcedures(myVar_dictUpdatedProcedures):
                                    Com_st.success(f"✅ Procedure '{myVar_dictProcedure['name']}' deleted successfully.")
                                    Com_st.rerun()
                    
                    # Procedure execution section
                    Com_st.markdown("---")
                    sub_displayExecuteProcedure(myPar_objDbEngine, myVar_dictProcedure, myVar_strCategory)
        
        myVar_intTabIndex += 1
    
    # "Add New" tab - Form to add new procedure
    with myVar_strSelectedTab[-1]:
        if sub_displayProcedureEditor():
            Com_st.rerun()
    
    # Handle editing a procedure if one is selected
    if hasattr(Com_st.session_state, 'edit_procedure'):
        myVar_dictEditProcedure = Com_st.session_state.edit_procedure
        
        Com_st.subheader(f"Edit Procedure: {myVar_dictEditProcedure['name']}")
        
        if sub_displayProcedureEditor(
            myVar_dictEditProcedure["name"],
            myVar_dictEditProcedure["data"],
            myVar_dictEditProcedure["category"]
        ):
            # Clear the edit session state and refresh
            del Com_st.session_state.edit_procedure
            Com_st.rerun()
        
        # Cancel button
        if Com_st.button("Cancel Edit"):
            del Com_st.session_state.edit_procedure
            Com_st.rerun()

# ════════════════════════════════════════════════════════════════════════════
#  EOF
# ════════════════════════════════════════════════════════════════════════════
