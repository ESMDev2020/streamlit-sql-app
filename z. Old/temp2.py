# 01_SigmaTBMain2.py (REVISED - Standard Multi-Page)

import streamlit as st # Use standard alias
from datetime import datetime

# --- Page Config (Keep at top) ---
st.set_page_config(
    page_title="Sigma Dashboard - Home",
    layout="wide",
    page_icon="🏠" # Example icon
)

# --- Sidebar (Keep general items) ---
st.sidebar.image("assets/SigmaTube-Bar.jpeg", use_container_width=True)
st.sidebar.markdown("---")
st.sidebar.info("Select a report from the main list above.") # Streamlit adds pages above this

# --- Main Page Content ---
st.title("Welcome to the Sigma Dashboard!")
st.markdown("---")
st.write(f"🟢 Application started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

st.header("Overview")
st.write("""
    This is the main hub for the Sigma Tube analysis tools.
    Please use the navigation panel on the left (automatically generated)
    to explore the available reports and dashboards:

    * **p 02 ROP:** Analyze Reorder Point data.
    * **p 03 Dashboard:** View key performance indicators.
    * **p 04 DashboardCosts:** Analyze cost data.

    *(Note: Page names are based on filenames in the 'pages' directory)*
""")

st.success("👈 Choose a page from the sidebar menu to begin.")

# --- IMPORTANT: REMOVED ---
# - Imports of p_02_ROP, p_03_Dashboard, p_04_DashboardCosts
# - st.sidebar.selectbox for "Main Section"
# - st.sidebar.radio for "Subsection"
# - The entire if/elif block calling functions like show_summary(), generate_item_report(), etc.