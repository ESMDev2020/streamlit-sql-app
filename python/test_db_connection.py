from sqlalchemy import create_engine, text

# Database connection parameters
DB_SERVER = "database-1.cduyeeawahjc.us-east-2.rds.amazonaws.com"
DB_DATABASE = "SigmaTB"
DB_USERNAME = "admin"
DB_PASSWORD = "Er1c41234$"

try:
    print("Attempting to connect to database...")
    connection_url = f"mssql+pymssql://{DB_USERNAME}:{DB_PASSWORD}@{DB_SERVER}/{DB_DATABASE}"
    engine = create_engine(connection_url)
    
    with engine.connect() as conn:
        print("Connected successfully!")
        result = conn.execute(text("SELECT 1"))
        print("Test query executed successfully!")
        print(f"Result: {result.fetchone()}")
        
except Exception as e:
    print(f"Error: {str(e)}")
finally:
    if 'engine' in locals():
        engine.dispose() 