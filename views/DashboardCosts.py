import streamlit as st
import pandas as pd
from sqlalchemy import create_engine
import matplotlib.pyplot as plt
import plotly.express as px
import plotly.graph_objects as go




# --- DB Connection ---
server = "database-1.cduyeeawahjc.us-east-2.rds.amazonaws.com"
database = "SigmaTB"
username = "admin"
password = "Er1c41234$"
engine = create_engine(f"mssql+pytds://{username}:{password}@{server}:1433/{database}")

#****************************************************************************
#-- COST BY ORDER - ARCUST, OEDETAIL
#****************************************************************************
st.title("💰 Cost Dashboard by Order")
order_number = st.text_input("Enter Order Number", value="965943", key="cost_order_input")

if st.button("Run Cost Report"):
    query = f"""
    SELECT 
        OEDETAIL.ODDIST * 1000000 + OEDETAIL.ODORDR AS OrderID,
        SALESMAN.SMNAME AS SalesmanName,
        OEOPNORD.OOTYPE AS OrderType,
        OEOPNORD.OOCDIS * 100000 + OEOPNORD.OOCUST AS DistributorCustomer,
        ARCUST.CALPHA AS CustomerName,
        OEOPNORD.OOICC * 1000000 + OEOPNORD.OOIYY * 10000 + OEOPNORD.OOIMM * 100 + OEOPNORD.OOIDD AS OrderDateKey,
        OEDETAIL.ODITEM,
        OEDETAIL.ODSIZ1,
        OEDETAIL.ODSIZ2,
        OEDETAIL.ODSIZ3,
        OEDETAIL.ODCRTD AS [Size],
        SLSDSCOV.DXDSC2 AS [Specification],
        OEDETAIL.ODTFTS AS Feet,
        OEDETAIL.ODTLBS AS Pounds,
        OEDETAIL.ODTPCS AS Pieces,
        OEDETAIL.ODSLSX AS TotalSales,
        OEDETAIL.ODFRTS AS FreightCharges,
        OEDETAIL.ODCSTX AS MaterialCost,
        OEDETAIL.ODPRCC AS UNKNOWNPrice,
        OEDETAIL.ODADCC AS AdditionalCharges,
        OEDETAIL.ODWCCS AS WeightCost,
        ARCUST.CSTAT AS CustomerState,
        ARCUST.CCTRY AS CustomerCountry
    FROM 
        ARCUST
    INNER JOIN OEOPNORD ON 
        OEOPNORD.OOCDIS = ARCUST.CDIST AND 
        OEOPNORD.OOCUST = ARCUST.CCUST
    INNER JOIN SALESMAN ON 
        OEOPNORD.OOISMD = SALESMAN.SMDIST AND 
        OEOPNORD.OOISMN = SALESMAN.SMSMAN
    INNER JOIN OEDETAIL ON 
        OEDETAIL.ODDIST = OEOPNORD.OODIST AND 
        OEDETAIL.ODORDR = OEOPNORD.OOORDR
    INNER JOIN SLSDSCOV ON 
        OEDETAIL.ODDIST = SLSDSCOV.DXDIST AND 
        OEDETAIL.ODORDR = SLSDSCOV.DXORDR AND 
        OEDETAIL.ODMLIN = SLSDSCOV.DXMLIN
    WHERE 
        OEDETAIL.ODORDR = {order_number}
    """

    try:
        with engine.begin() as conn:
            df = pd.read_sql(query, conn)

        if df.empty:
            st.warning("⚠️ No results found for this order number.")
        else:
            st.success("✅ Data loaded successfully.")
            st.dataframe(df)

    except Exception as e:
        st.error(f"❌ Error retrieving data: {e}")

#****************************************************************************
#-- SHIPMENT - SHIPMAST
#****************************************************************************
st.title("📦 Shipment Dashboard by Order")
order_number_ship = st.text_input("Enter Order Number", value="965943", key="shipping_order_input")

if st.button("Run Shipment Report"):
    try:
        query = f"""
        SELECT S.SHDIST as "District Number",
            S.SHORDN as "Sales Order",
            S.SHCORD as "Customer Order",
            S.SHITEM as "Item",
            S.SHIPCC as "Shipment Century",
            S.SHIPYY,
            S.SHIPMM,
            S.SHIPDD,
            S.SHBQTY as "Base quantity",
            S.SHTLBS,
            S.SHCUST as "Customer number",
            S.SHORYY as "Original order year",
            S.SHORMM,
            S.SHORDD,
            S.SHIVYY as "Invoice year",
            S.SHIVMM,
            S.SHIVDD,
            S.SHMSLS as "Material sales",
            S.SHMSLD as "Final sales",
            S.SHFSLS as "Final issued sales",
            S.SHMCSS as "Material cost",
            S.SHSLSS as "Sales ledger",
            S.SHSWGS as "swaged sales",
            S.SHADPC as "additional processing",
            S.SHFRGH as "freight cost",
            S.SHTRCK as "truck route",
            S.SHSHTO as "customer ship to",
            S.SHBCTY as "Bill to country",
            S.SHSCTY as "Ship to country",
            S.SHTMPS as "temp ship to",
            S.SHDSTO as "Orig cust dist",
            S.SHCSTO as "Orig cust",
            S.SHSMDO as "Orig sism dist",
            S.SHSLMO as "Orig Slsmn",
            S.SHICMP as "Inv comp",
            S.SHADR1 as "Address 1",
            S.SHADR2,
            S.SHADR3,
            S.SHCITY as "City 25 pos",
            S.SHSTAT as "State",
            S.SHZIP as "Zip"
        FROM 
            [dbo].[SHIPMAST] S
        WHERE
            S.SHORDN = {order_number_ship}
        """

        with engine.begin() as conn:
            df = pd.read_sql(query, conn)

        if df.empty:
            st.warning("⚠️ No results found for this order number.")
        else:
            st.success("✅ Data loaded successfully.")

            with st.expander("📦 View Shipment Details", expanded=True):
                def show_fields_in_rows(data, cols_per_row=5):
                    if len(data) == 1:
                        record = data.iloc[0].to_dict()
                        keys = list(record.keys())
                        for i in range(0, len(keys), cols_per_row):
                            cols = st.columns(cols_per_row)
                            for j, key in enumerate(keys[i:i+cols_per_row]):
                                with cols[j]:
                                    st.markdown(f"**{key}**")
                                    st.text(record[key])
                    else:
                        st.dataframe(data)

                show_fields_in_rows(df, cols_per_row=5)

    except Exception as e:
        st.error(f"❌ Error retrieving data: {e}")


#****************************************************************************
#-- MATERIAL PROCESSING GLTRANS, GLACCT
#****************************************************************************


st.title("📦 MP Dashboard by Order")
order_number_MP = st.text_input("Enter Order Number", value="965943", key="MP_order_input")
st.write(f"Searching for GLREF like: '%{order_number_MP}%'")

if st.button("Run MP Report"):
    try:
        # 👇 Escape % using double %% inside f-string
        st.write(f"Searching for GLREF like: '%{order_number_MP}%'")

        query = f"""
        SELECT
            GLDESC AS Title_GLDESC, 
            GLAMT,
            GLA.GARP3 as GARP3_FS,
            GLAPPL AS GLAPPL_APP,
            GLA.GACDES AS GACDES_AccountDescription,
            FORMAT(GLCOMP, '00') + ' ' + FORMAT(GLDIST, '00') + ' ' + FORMAT(GLCSTC, '00') AS [CO DS CS],
            GLT.GLACCT AS GLAccount_GLACCT,
            GLREF AS GLREF_Reference,
            GLAPPL + RIGHT('00000000' + CAST(GLBTCH AS VARCHAR), 8) + '-0001' AS Reference,
            FORMAT(GLPPYY, '00') + ' ' + FORMAT(GLPERD, '00') AS Period,
            GLDESC AS Transaction_GLDESC,
            GLPGM AS GLPGM_Prgm,
            GLUSER AS GLUSER,
            GLAPTR AS GLAPTR_Related,
            GLTRN# AS [GLTRN#],
            GLTRNT AS [GLTRNT_Tran],
            GLTYPE AS GLTYPE,
            GLDIST AS GLDIST,
            GLREF AS GLREF_Document,
            GLCRDB,
            GLT.GLACCT AS GLACCT_FS,
            GLRECD AS Ext,
            TRY_CAST(
                CAST(GLRFYY AS VARCHAR(4)) + '-' + 
                RIGHT('00' + CAST(GLRFMM AS VARCHAR(2)), 2) + '-' + 
                RIGHT('00' + CAST(GLRFDD AS VARCHAR(2)), 2) 
            AS DATE) AS Posting,
            NULL AS System,
            FORMAT(GLCUST, '00 00000') AS Custmr
        FROM GLTRANS GLT
        LEFT JOIN GLACCT GLA ON GLT.GLACCT = GLA.GACCT
        WHERE GLREF LIKE '%%{order_number_MP}%%' AND GLA.GARP3 IN (500,600)
        GROUP BY
            GLRECD, GLCOMP, GLDIST, GLCSTC, GLT.GLACCT, GLDESC, GLPPYY, GLPERD, GLAPPL, GLBTCH, GLPGM,
            GLUSER, GLAPTR, GLTRN#, GLTRNT, GLTYPE, GLREF, GLRFYY, GLRFMM, GLRFDD, GLCUST, GLCRDB, GLAMT,
            GLA.GACDES, GLA.GARP3
        ORDER BY GLTRN#;
        """

        with engine.begin() as conn:
            df = pd.read_sql(query, conn)

        if df.empty:
            st.warning("⚠️ No results found for this order number.")
        else:
            st.success("✅ Data loaded successfully.")
            st.dataframe(df)

    except Exception as e:
        st.error(f"❌ Error retrieving data: {e}")

###############################################################
# Where are the 25k of credits on the income statement
###############################################################
# --- Streamlit UI ---
st.title("💰 Credit memos by Customer and by Order")

if st.button("Run Credit Memos Report"):
    query = f"""
        SELECT 
        ARCUST.CALPHA AS CustomerName,
        COUNT(DISTINCT GLT.GLTRN#) AS CreditOrderCount,
        SUM(GLT.GLAMT) AS TotalCredits,
        ISNULL(Sales.TotalSales, 0) AS TotalSales,
        CASE 
            WHEN ISNULL(Sales.TotalSales, 0) = 0 THEN NULL
            ELSE ROUND(SUM(GLT.GLAMT) * 1.0 / Sales.TotalSales, 2)
        END AS CreditRatio
    FROM GLTRANS GLT
    LEFT JOIN GLACCT GLA 
        ON GLT.GLACCT = GLA.GACCT
    LEFT JOIN ARCUST 
        ON GLT.GLCUST = ARCUST.CCUST
    -- Join to pull in total sales per customer
    LEFT JOIN (
        SELECT 
            GLCUST,
            SUM(GLAMT) AS TotalSales
        FROM GLTRANS
        LEFT JOIN GLACCT ON GLTRANS.GLACCT = GLACCT.GACCT
        WHERE 
            GLAPPL IN ('IN') 
            AND GARP3 BETWEEN 500 AND 599
            AND GLPYY = 25 AND GLPMM = 2
        GROUP BY GLCUST
    ) AS Sales ON GLT.GLCUST = Sales.GLCUST
    WHERE 
        GLT.GLAPPL IN ('CR') 
        AND GLA.GARP3 IN (500, 600) 
        AND GLT.GLPYY = 25 
        AND GLT.GLPMM = 2
    GROUP BY 
        ARCUST.CALPHA, Sales.TotalSales
    ORDER BY 
        TotalCredits DESC;
    """

    try:
        with engine.begin() as conn:
            df = pd.read_sql(query, conn)

        if df.empty:
            st.warning("⚠️ No results found for this period.")
        else:
            st.success("✅ February data loaded successfully.")
            st.dataframe(df)

            # Pie chart for total credits by customer
            if "CustomerName" in df.columns and "TotalCredits" in df.columns:
                st.subheader("💰 Interactive Credit Distribution by Customer")

                fig = px.pie(
                    df,
                    names="CustomerName",
                    values="TotalCredits",
                    title="Credit % by Customer",
                    hole=0.3  # optional, makes it a donut
                )

                fig.update_traces(textinfo='percent+label', hovertemplate='%{label}: $%{value:,.2f}')
                st.plotly_chart(fig, use_container_width=True)
            else:
                st.info("Pie chart could not be generated: missing 'CustomerName' or 'TotalCredits' columns.")

    except Exception as e:
        st.error(f"❌ Error retrieving data: {e}")


###############################################################
# SALES REPORT FROM OEDETAIL AND OEOPNORD
###############################################################
import plotly.graph_objects as go

st.title("💰 Sales Report by Sales Department")

if st.button("Run Sales Report by Sales Department"):
    query = f"""
        SELECT 
            ARCUST.CALPHA AS CustomerName,
            SALESMAN.SMNAME AS SalesmanName,
            SUM(OEDETAIL.ODSLSX) AS TotalSales,
            SUM(OEDETAIL.ODFRTS) AS TotalFreightCharges,
            SUM(OEDETAIL.ODCSTX) AS TotalMaterialCost,
            SUM(OEDETAIL.ODPRCC) AS TotalProcessingPrice,
            SUM(OEDETAIL.ODADCC) AS TotalAdditionalCharges,
            SUM(OEDETAIL.ODWCCS) AS TotalWeightCost
        FROM ARCUST
        INNER JOIN OEOPNORD ON 
            OEOPNORD.OOCDIS = ARCUST.CDIST AND 
            OEOPNORD.OOCUST = ARCUST.CCUST
        INNER JOIN SALESMAN ON 
            OEOPNORD.OOISMD = SALESMAN.SMDIST AND 
            OEOPNORD.OOISMN = SALESMAN.SMSMAN
        INNER JOIN OEDETAIL ON 
            OEDETAIL.ODDIST = OEOPNORD.OODIST AND 
            OEDETAIL.ODORDR = OEOPNORD.OOORDR
        INNER JOIN SLSDSCOV ON 
            OEDETAIL.ODDIST = SLSDSCOV.DXDIST AND 
            OEDETAIL.ODORDR = SLSDSCOV.DXORDR AND 
            OEDETAIL.ODMLIN = SLSDSCOV.DXMLIN
        WHERE 
            OEOPNORD.OOIYY = 25 AND OEOPNORD.OOIMM = 2
        GROUP BY ARCUST.CALPHA, SALESMAN.SMNAME
    """

    try:
        with engine.begin() as conn:
            df = pd.read_sql(query, conn)

        if df.empty:
            st.warning("⚠️ No results found for this period.")
        else:
            st.success("✅ Global totals loaded.")
            st.dataframe(df)

            # Extract totals
            totals = df.iloc[0].fillna(0)

            # Values
            sales = float(totals["TotalSales"])
            freight = float(totals["TotalFreightCharges"])
            material = float(totals["TotalMaterialCost"])
            processing = float(totals["TotalProcessingPrice"])
            additional = float(totals["TotalAdditionalCharges"])
            weight = float(totals["TotalWeightCost"])

            net = sales - freight - material - processing - additional - weight

            # Waterfall chart
            st.subheader("📊 Company-Wide Sales Waterfall From Sales Report")

            fig = go.Figure(go.Waterfall(
                name="Total",
                orientation="v",
                measure=["relative", "relative", "relative", "relative", "relative", "relative", "total"],
                x=["Sales", "Freight", "Material", "Processing", "Additional", "Weight", "Net"],
                y=[sales, -freight, -material, -processing, -additional, -weight, net],
                textposition="outside"
            ))

            fig.update_layout(
                title="💰 Net Sales Breakdown",
                waterfallgap=0.3
            )

            st.plotly_chart(fig, use_container_width=True)

    except Exception as e:
        st.error(f"❌ Error retrieving data: {e}")