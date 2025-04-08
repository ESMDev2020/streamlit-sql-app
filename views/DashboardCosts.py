import streamlit as st
import pandas as pd
from sqlalchemy import create_engine

# --- DB Connection ---
server = "database-1.cduyeeawahjc.us-east-2.rds.amazonaws.com"
database = "SigmaTB"
username = "admin"
password = "Er1c41234$"
engine = create_engine(f"mssql+pymssql://{username}:{password}@{server}:1433/{database}")

# --- Streamlit UI ---
st.title("💰 Cost Dashboard by Order")
order_number = st.text_input("Enter Order Number", value="965943")

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

#-- Look for shipment
st.title("📦 Shipment Dashboard by Order")
order_number = st.text_input("Enter Order Number", value="965943")
if st.button("Run Shipment Report"):
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
    S.SHORDN = {order_number}
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