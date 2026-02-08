import mysql.connector

CONFIG = {
    'user': 'root',
    'password': 'LEtcQCNoTgSZOoHbWKFZVSfQhjIIjrYT',
    'host': 'turntable.proxy.rlwy.net',
    'port': 13082,
    'database': 'railway', 
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
