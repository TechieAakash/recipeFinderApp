import mysql.connector
import sys

CONFIG = {
    'user': 'root',
    'password': 'LEtcQCNoTgSZOoHbWKFZVSfQhjIIjrYT',
    'host': 'turntable.proxy.rlwy.net',
    'port': 13082,
    'database': 'railway',  # Connect to default DB first
    'autocommit': True
}

def execute_sql_file(filename):
    print(f"Connecting to database at {CONFIG['host']}...")
    try:
        cnx = mysql.connector.connect(**CONFIG)
        cursor = cnx.cursor()
        
        print("Connected! Processing SQL script...")
        
        with open(filename, 'r', encoding='utf-8') as f:
            sql_content = f.read()

        # Robust parser for the specific structure of init_db.sql
        # Structure:
        # 1. Standard SQL (CREATE TABLE, INSERT, etc.) separated by ;
        # 2. DELIMITER //
        # 3. Procedures separated by //
        # 4. DELIMITER ;
        # 5. Standard SQL (INSERT, SELECT) separated by ;
        
        statements = []
        
        # Split by DELIMITER commands
        parts = sql_content.split('DELIMITER //')
        
        # Part 1: Before procedures
        pre_procedure_sql = parts[0]
        for stmt in pre_procedure_sql.split(';'):
            if stmt.strip():
                statements.append(stmt.strip())
                
        if len(parts) > 1:
            # We have procedures
            proc_section = parts[1]
            # Split by DELIMITER ; to find end of procedures
            proc_parts = proc_section.split('DELIMITER ;')
            
            procs = proc_parts[0]
            # Split individual procedures by //
            for stmt in procs.split('//'):
                if stmt.strip():
                    statements.append(stmt.strip())
            
            # Post procedure SQL
            if len(proc_parts) > 1:
                post_proc_sql = proc_parts[1]
                for stmt in post_proc_sql.split(';'):
                    if stmt.strip():
                        statements.append(stmt.strip())

        print(f"Found {len(statements)} statements to execute.")
        
        for i, stmt in enumerate(statements):
            try:
                # Skip empty statements
                if not stmt.strip():
                    continue
                    
                print(f"Executing statement {i+1}/{len(statements)}...")
                print(f"SQL Start: {stmt[:50]}...")
                cursor.execute(stmt)
            except mysql.connector.Error as err:
                print(f"Error executing statement {i+1}: {err}")
                print(f"Statement: {stmt[:100]}...")
                raise err # Stop on error
                
        cnx.commit()
        cnx.close()
        print("Script executed successfully!")
        
    except mysql.connector.Error as err:
        print(f"Connection Error: {err}")
    except Exception as e:
        print(f"General Error: {e}")

if __name__ == "__main__":
    execute_sql_file("init_db.sql")
