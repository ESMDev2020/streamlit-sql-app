import streamlit as st
import pandas as pd
import altair as alt

import pyodbc

st.title("📦 Full Inventory Report for Item 50002")

# ODBC connection string
conn_str = (
    "DRIVER={ODBC Driver 18 for SQL Server};"
    "SERVER=database-1.cduyeeawahjc.us-east-2.rds.amazonaws.com,1433;"
    "DATABASE=SigmaTB;"
    "UID=admin;"
    "PWD=Er1c41234$;"
    "TrustServerCertificate=yes;"
)

if st.button("Run Full Report"):
    try:
        with pyodbc.connect(conn_str) as conn:
            cursor = conn.cursor()
            query = """
            -- 1. Item being reviewed
            SELECT [Size Text], Description, SMO
            FROM ROPData
            WHERE Item = 50002;

            -- 2. IA, MP, SO Summary by Month
            WITH Months AS (
                SELECT FORMAT(DATEADD(MONTH, -n, CAST(GETDATE() AS DATE)), 'yyyy-MM') AS Month
                FROM (SELECT TOP 13 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n FROM sys.all_objects) AS x
            ),
            Aggregated AS (
                SELECT
                    FORMAT(DATEFROMPARTS(2000 + IHTRYY, IHTRMM, 1), 'yyyy-MM') AS Month,
                    CASE 
                        WHEN CONVERT(VARCHAR(10), IHTRNT) = 'IA' THEN IHTQTY
                        WHEN CONVERT(VARCHAR(10), IHTRNT) IN ('OW', 'OR') THEN IHTQTY
                        WHEN CONVERT(VARCHAR(10), IHTRNT) = 'IN' THEN IHTQTY
                        ELSE 0
                    END AS Qty,
                    CONVERT(VARCHAR(10), IHTRNT) AS Type
                FROM UsageData
                WHERE IHITEM = 50002
                  AND DATEFROMPARTS(2000 + IHTRYY, IHTRMM, 1) >= DATEADD(MONTH, -13, CAST(GETDATE() AS DATE))
            )
            SELECT 
                m.Month,
                FORMAT(SUM(CASE WHEN a.Type = 'IA' THEN a.Qty ELSE 0 END), 'N2') AS [IA (Inventory Adjustments)],
                FORMAT(SUM(CASE WHEN a.Type IN ('OW', 'OR') THEN a.Qty ELSE 0 END), 'N2') AS [MP (Material Processed)],
                FORMAT(SUM(CASE WHEN a.Type = 'IN' THEN a.Qty ELSE 0 END), 'N2') AS [SO (Sales Orders)]
            FROM Months m
            LEFT JOIN Aggregated a ON m.Month = a.Month
            GROUP BY m.Month
            ORDER BY m.Month;

            -- 3. Inventory Availability
            SELECT [OnHand], [Rsrv], [OnHand] - [Rsrv] AS [Available Inv]
            FROM ROPData
            WHERE Item = 50002;

            -- 4. Usage and Vendor
            SELECT 'Usage and Vendor' AS [Title], [#/ft], [UOM], [$/ft], [con/wk], [Vndr]
            FROM ROPData
            WHERE Item = 50002;

            -- 5. Depletion Forecast
            SELECT 'When do we need to purchase and how much' AS [Question],
                [OnHand] - [Rsrv] AS [Available Inv],
                ([#/ft] * ([OnHand] - [Rsrv])) AS [Pounds],
                [$/ft] * ([OnHand] - [Rsrv]) AS [Dollars],
                ([OnHand] - [Rsrv]) / [con/wk] AS [Weeks],
                DATEADD(WEEK, ([OnHand] - [Rsrv]) / [con/wk], CAST(GETDATE() AS DATE)) AS [Expected Depletion Date]
            FROM ROPData
            WHERE Item = 50002;
            """

            result_sets = []
            while True:
                try:
                    rows = cursor.fetchall()
                    columns = [column[0] for column in cursor.description]
                    df = pd.DataFrame.from_records(rows, columns=columns)
                    result_sets.append(df)
                except:
                    pass
                if not cursor.nextset():
                    break

            st.success("✅ All data loaded successfully!")

            titles = [
                "🔍 Item Being Reviewed",
                "📈 IA / MP / SO Summary (Last 13 Months)",
                "📦 Inventory On Hand vs Reserved",
                "🧪 Usage and Vendor",
                "📅 Depletion Forecast",
            ]

            for i, df in enumerate(result_sets):
                st.subheader(titles[i] if i < len(titles) else f"Result {i + 1}")
                st.dataframe(df)

            # Chart
            inventory_df = result_sets[2]
            if not inventory_df.empty:
                chart_data = pd.DataFrame({
                    "Metric": ["OnHand", "Reserved", "Available"],
                    "Value": [
                        float(inventory_df.at[0, "OnHand"]),
                        float(-inventory_df.at[0, "Rsrv"]),
                        float(inventory_df.at[0, "Available Inv"])
                    ]
                })

                st.subheader("📊 Inventory Overview Chart")

                bar_chart = alt.Chart(chart_data).mark_bar().encode(
                    x=alt.X("Metric", title="Metric", sort=["OnHand", "Reserved", "Available"]),
                    y=alt.Y("Value", title="Feet", scale=alt.Scale(zero=True)),
                    color=alt.Color("Metric", legend=None)
                ).properties(width=500, height=300)

                st.altair_chart(bar_chart)

    except Exception as e:
        st.error(f"❌ Failed to run the report: {e}")
