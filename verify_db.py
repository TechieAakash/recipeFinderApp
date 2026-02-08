import mysql.connector
import os

CONFIG = {
    'user': os.environ.get('DB_USER', 'root'),
    'password': os.environ.get('DB_PASSWORD', ''),  # Required: Set via environment variable
    'host': os.environ.get('DB_HOST', 'localhost'),
    'port': int(os.environ.get('DB_PORT', 3306)),
    'database': os.environ.get('DB_NAME', 'recipe_finder'),
    'autocommit': True
}

def verify():
    try:
        print("Connecting to recipe_finder database...")
        cnx = mysql.connector.connect(**CONFIG)
        cursor = cnx.cursor()
        
        cursor.execute("SHOW TABLES")
        tables = cursor.fetchall()
        print("Tables in recipe_finder:")
        for (table_name,) in tables:
            print(f"- {table_name}")
            
        cursor.execute("SELECT COUNT(*) FROM recipes")
        count = cursor.fetchone()[0]
        print(f"Total recipes: {count}")
        
        cnx.close()
        
    except mysql.connector.Error as err:
        print(f"Error: {err}")

if __name__ == "__main__":
    verify()
