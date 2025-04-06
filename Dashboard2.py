import streamlit as st
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import altair as alt
from sqlalchemy import create_engine

# ---------- Titles for each query result ----------
query_titles = [
    "🔍 Item Being Reviewed",
    "📈 IA / MP / SO Summary (Last 13 Months)",
    "📦 Inventory On Hand vs Reserved",
    "🔪 Usage and Vendor",
    "🗓 Depletion Forecast",
    "🧪 Family Breakdown (if any)"
]

# ---------- Database connection ----------
server = "database-1.cduyeeawahjc.us-east-2.rds.amazonaws.com"
database = "SigmaTB"
username = "admin"
password = "Er1c41234$"
engine = create_engine(f"mssql+pytds://{username}:{password}@{server}:1433/{database}")

# ---------- SESSION STATE for interactive item click ----------
if "selected_item" not in st.session_state:
    st.session_state.selected_item = "50002"

# ---------- DASHBOARD TOP SECTION ----------
st.title("📊 Inventory Dashboard")

# Load main inventory data
try:
    with engine.begin() as conn:
        df = pd.read_sql("SELECT * FROM ROPData", conn)

    df = df.rename(columns={
        "OnHand": "In Stock (ft)",
        "OnPO": "PO Incoming (ft)",
        "#/ft": "Feet per Unit",
        "con/wk": "Usage/Week",
        "FastPathSort": "Grade"
    })

    df = df[df["Usage/Week"].notnull() & (df["Usage/Week"] != 0)]
    df["Weeks Left"] = (df["In Stock (ft)"].astype(float) / df["Usage/Week"].astype(float)).round(1)

    df["Reorder Flag"] = df["Weeks Left"].apply(
        lambda w: "✅ No" if w > 26 else ("⚠️ Caution" if 12 < w <= 26 else "❌ Yes")
    )

    df["Origin"] = df["Description"].apply(lambda x: "China" if "++" in str(x) else "Other")

    # Summary tiles
    st.write("## Summary")
    col1, col2, col3 = st.columns(3)
    col1.metric("Total Active Items", f"{int(len(df)):,}")
    col2.metric("Items < 12 Weeks", f"{int((df['Weeks Left'] < 12).sum()):,}")
    col3.metric("Avg Inventory Weeks", f"{df['Weeks Left'].astype(float).mean():,.1f}")

    col4, col5 = st.columns(2)
    col4.metric("Feet On Hand", f"{df['In Stock (ft)'].astype(float).sum():,.0f}")
    col5.metric("PO Feet In Transit", f"{df['PO Incoming (ft)'].astype(float).sum():,.0f}")

    # Filters
    st.write("## Inventory Weeks by Item")
    reorder_filter = st.selectbox("Filter by Reorder Flag", ["All"] + sorted(df["Reorder Flag"].dropna().unique().tolist()))
    grade_filter = st.selectbox("Filter by Grade", ["All"] + sorted(df["Grade"].dropna().unique().tolist()))

    filtered_df = df.copy()
    if reorder_filter != "All":
        filtered_df = filtered_df[filtered_df["Reorder Flag"] == reorder_filter]
    if grade_filter != "All":
        filtered_df = filtered_df[filtered_df["Grade"] == grade_filter]

    st.write(f"Displaying {len(filtered_df)} items")

    # Altair Chart
    highlight = alt.selection_single(on='mouseover', fields=['Item'], nearest=True)
    alt_chart = alt.Chart(filtered_df).mark_bar().encode(
        x=alt.X("Item:N", sort='-y', title="Item"),
        y=alt.Y("Weeks Left:Q", title="Weeks Left"),
        color=alt.Color("Reorder Flag:N",
                       scale=alt.Scale(domain=["❌ Yes", "⚠️ Caution", "✅ No"],
                                       range=["red", "orange", "green"]),
                       legend=alt.Legend(title="Reorder Flag")),
        tooltip=["Item", "Weeks Left", "Reorder Flag"]
    ).add_selection(
        highlight
    ).properties(
        width='container', height=400
    ).interactive()

    st.altair_chart(alt_chart, use_container_width=True)

    # Show interactive dataframe
    st.write("## Full Inventory Data (Based on Filters Above)")
    all_columns = list(filtered_df.columns)
    default_columns = [col for col in [
        "Item", "In Stock (ft)", "Rsrv", "Level", "Weeks Left", "Reorder Flag",
        "PO Incoming (ft)", "TotCons", "Usage/Week", "Size Text", "Description",
        "Vndr", "Comment", "$/ft", "Origin"
    ] if col in all_columns]

    st.dataframe(filtered_df[default_columns])

    # ---------- Input and Report by Item Button ----------
    item_id = st.text_input("Enter Item Number", value=st.session_state.selected_item)
    if st.button("Report by ITEM"):
        full_report_query = f"""
            SELECT [Size Text], Description, SMO FROM ROPData WHERE Item = {item_id};
            WITH Months AS (
                SELECT FORMAT(DATEADD(MONTH, -n, CAST(GETDATE() AS DATE)), 'yyyy-MM') AS Month
                FROM (SELECT TOP 13 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n FROM sys.all_objects) AS x
            ),
            Aggregated AS (
                SELECT
                    FORMAT(DATEFROMPARTS(2000 + IHTRYY, IHTRMM, 1), 'yyyy-MM') AS Month,
                    CASE WHEN CONVERT(VARCHAR(10), IHTRNT) = 'IA' THEN IHTQTY
                         WHEN CONVERT(VARCHAR(10), IHTRNT) IN ('OW', 'OR') THEN IHTQTY
                         WHEN CONVERT(VARCHAR(10), IHTRNT) = 'IN' THEN IHTQTY
                         ELSE 0 END AS Qty,
                    CONVERT(VARCHAR(10), IHTRNT) AS Type
                FROM UsageData
                WHERE IHITEM = {item_id}
                  AND DATEFROMPARTS(2000 + IHTRYY, IHTRMM, 1) >= DATEADD(MONTH, -13, CAST(GETDATE() AS DATE))
            )
            SELECT 
                m.Month,
                CASE WHEN SUM(CASE WHEN a.Type = 'IA' THEN a.Qty ELSE 0 END) = 0 THEN '-' ELSE FORMAT(SUM(CASE WHEN a.Type = 'IA' THEN a.Qty ELSE 0 END), 'N2') END AS [IA (Inventory Adjustments)],
                CASE WHEN SUM(CASE WHEN a.Type IN ('OW', 'OR') THEN a.Qty ELSE 0 END) = 0 THEN '-' ELSE FORMAT(SUM(CASE WHEN a.Type IN ('OW', 'OR') THEN a.Qty ELSE 0 END), 'N2') END AS [MP (Material Processed)],
                CASE WHEN SUM(CASE WHEN a.Type = 'IN' THEN a.Qty ELSE 0 END) = 0 THEN '-' ELSE FORMAT(SUM(CASE WHEN a.Type = 'IN' THEN a.Qty ELSE 0 END), 'N2') END AS [SO (Sales Orders)]
            FROM Months m
            LEFT JOIN Aggregated a ON m.Month = a.Month
            GROUP BY m.Month
            ORDER BY m.Month;

            SELECT [OnHand], [Rsrv], [OnHand] - [Rsrv] AS [Available Inv] FROM ROPData WHERE Item = {item_id};

            SELECT 'Usage and Vendor' AS [Title], [#/ft], [UOM], [$/ft], [con/wk], [Vndr] FROM ROPData WHERE Item = {item_id};

            SELECT 'When and how much' AS [Question],
                [OnHand] - [Rsrv] AS [Available Inv],
                ([#/ft] * ([OnHand] - [Rsrv])) AS [Pounds],
                [$/ft] * ([OnHand] - [Rsrv]) AS [Dollars],
                ([OnHand] - [Rsrv]) / [con/wk] AS [Weeks],
                DATEADD(WEEK, ([OnHand] - [Rsrv]) / [con/wk], CAST(GETDATE() AS DATE)) AS [Expected Depletion Date]
            FROM ROPData WHERE Item = {item_id};

            SELECT ropdata.Item,
                   (ropdata.OnHand - ropdata.Rsrv) AS [Available],
                   ropdata.OnPO,
                   ropdata.[#/ft],
                   ropdata.[#/ft] + (
                       SELECT -SUM(usagedata.IHTQTY)
                       FROM usagedata
                       WHERE usagedata.IHITEM = ropdata.Item
                       AND CAST(usagedata.column4 AS VARCHAR(10)) = CAST(ropdata.Item AS VARCHAR(10))
                   ) AS net_consumption,
                   (ropdata.TotCons / 26.1428571428571) AS [wk use],
                   (
                       SELECT -SUM(usagedata.IHTQTY)
                       FROM usagedata
                       WHERE usagedata.IHITEM = ropdata.Item
                       AND CAST(usagedata.column4 AS VARCHAR(10)) = CAST(ropdata.Item AS VARCHAR(10))
                   ) AS total_usage,
                   ropdata.description, ropdata.[Size Text] as "Size"
            FROM (
                SELECT CAST(comment AS VARCHAR(MAX)) AS comment, Item
                FROM ROPData WHERE Item = {item_id}
            ) base
            OUTER APPLY (
                SELECT TRIM(value) AS val FROM STRING_SPLIT(base.comment, '!') WHERE value <> ''
            ) RawParts
            CROSS APPLY (
                SELECT TRY_CAST(LEFT(val, CHARINDEX(':', val + ':') - 1) AS INT) AS Item
            ) Parsed
            JOIN ROPData ropdata ON ropdata.Item = Parsed.Item;
        """

        try:
            result_sets = []
            with engine.begin() as conn:
                for i, sql in enumerate(full_report_query.strip().split(";")):
                    if sql.strip():
                        df = pd.read_sql(sql, conn)
                        result_sets.append(df)

            st.success("✅ All data loaded successfully!")

            for i, df in enumerate(result_sets):
                title = query_titles[i] if i < len(query_titles) else f"Result {i + 1}"
                st.subheader(title)
                st.dataframe(df)

            if len(result_sets) >= 3 and not result_sets[2].empty:
                inventory_df = result_sets[2]
                chart_data = pd.DataFrame({
                    "Metric": ["OnHand", "Reserved", "Available"],
                    "Value": [
                        float(inventory_df.at[0, "OnHand"]),
                        float(-inventory_df.at[0, "Rsrv"]),
                        float(inventory_df.at[0, "Available Inv"])
                    ]
                })

                st.subheader(f"🌍 Item {item_id} Overview Chart")
                bar_chart = alt.Chart(chart_data).mark_bar().encode(
                    x=alt.X("Metric", title="Metric"),
                    y=alt.Y("Value", title="Feet", scale=alt.Scale(zero=True)),
                    color=alt.Color("Metric", legend=None)
                ).properties(width=500, height=300)

                st.altair_chart(bar_chart)

        except Exception as e:
            st.error(f"❌ Failed to run the report: {e}")

    # Pie Chart: Origin Distribution — moved to bottom
    st.write("## Stock by Origin")
    fig_origin, ax_origin = plt.subplots(figsize=(6, 6))
    origin_counts = filtered_df['Origin'].value_counts()
    ax_origin.pie(origin_counts, labels=origin_counts.index, autopct='%1.1f%%', startangle=90)
    ax_origin.set_title('Stock by Origin')
    st.pyplot(fig_origin)

except Exception as e:
    st.error(f"❌ Failed to load dashboard: {e}")

# Update item_id from hyperlink if clicked
query_params = st.query_params
if "selected_item" in query_params:
    st.session_state.selected_item = query_params["selected_item"]
