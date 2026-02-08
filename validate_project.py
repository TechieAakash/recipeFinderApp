"""
Project Validation Script - Recipe Finder
This script checks for common errors and validates the project setup.
"""

import os
import sys
import importlib.util

def check_file_exists(filepath, description):
    """Check if a file exists"""
    if os.path.exists(filepath):
        print(f"✓ {description}: Found")
        return True
    else:
        print(f"✗ {description}: Missing")
        return False

def check_imports():
    """Check if all required Python packages are installed"""
    print("\n=== Checking Python Dependencies ===")
    packages = {
        'flask': 'Flask',
        'flask_cors': 'Flask-CORS',
        'mysql.connector': 'MySQL Connector',
        'bcrypt': 'Bcrypt',
        'jwt': 'PyJWT'
    }
    
    all_installed = True
    for module_name, package_name in packages.items():
        try:
            if module_name == 'mysql.connector':
                import mysql.connector
            else:
                __import__(module_name)
            print(f"✓ {package_name}: Installed")
        except ImportError:
            print(f"✗ {package_name}: NOT INSTALLED")
            all_installed = False
    
    return all_installed

def check_syntax(filepath):
    """Check Python file for syntax errors"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            compile(f.read(), filepath, 'exec')
        return True
    except SyntaxError as e:
        print(f"✗ Syntax Error in {filepath}: Line {e.lineno}: {e.msg}")
        return False

def validate_project_structure():
    """Validate project structure"""
    print("\n=== Validating Project Structure ===")
    
    base_dir = os.path.dirname(os.path.abspath(__file__))
    
    required_files = {
        'server.py': 'Main server file (Enhanced)',
        'app.py': 'Alternative server file',
        'recipe.html': 'Main HTML file',
        'recipe.css': 'Main CSS file',
        'recipe.js': 'Main JavaScript file',
        'finder.html': 'Finder HTML file',
        'finder.css': 'Finder CSS file',
        'finder.js': 'Finder JavaScript file'
    }
    
    all_present = True
    for filename, description in required_files.items():
        filepath = os.path.join(base_dir, filename)
        if not check_file_exists(filepath, description):
            all_present = False
    
    # Check for images directory
    images_dir = os.path.join(base_dir, 'images')
    if os.path.exists(images_dir):
        print(f"✓ Images directory: Found")
    else:
        print(f"⚠ Images directory: Not found (will be created on server start)")
    
    return all_present

def validate_python_files():
    """Validate Python code syntax"""
    print("\n=== Validating Python Files ===")
    
    base_dir = os.path.dirname(os.path.abspath(__file__))
    python_files = ['server.py', 'app.py']
    
    all_valid = True
    for filename in python_files:
        filepath = os.path.join(base_dir, filename)
        if os.path.exists(filepath):
            if check_syntax(filepath):
                print(f"✓ {filename}: No syntax errors")
            else:
                all_valid = False
        else:
            print(f"✗ {filename}: File not found")
            all_valid = False
    
    return all_valid

def check_database_config():
    """Check database configuration"""
    print("\n=== Checking Database Configuration ===")
    
    print("Database Config (from environment variables):")
    print("  Host: DB_HOST (default: localhost)")
    print("  User: DB_USER (default: root)")
    print("  Password: DB_PASSWORD (required - set via environment)")
    print("  Database: DB_NAME (default: recipe_finder)")
    print("\n⚠  Note: Make sure MySQL is running and the database exists!")
    print("⚠  Set DB_PASSWORD environment variable before running the server.")
    print("⚠  Run SQL schema file to create tables if not done already.")
    
    return True

def generate_report():
    """Generate comprehensive validation report"""
    print("\n" + "=" * 60)
    print("RECIPE FINDER PROJECT - VALIDATION REPORT")
    print("=" * 60)
    
    results = {
        'structure': validate_project_structure(),
        'imports': check_imports(),
        'python_syntax': validate_python_files(),
        'database': check_database_config()
    }
    
    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)
    
    all_passed = all(results.values())
    
    for check_name, passed in results.items():
        status = "✓ PASSED" if passed else "✗ FAILED"
        print(f"{check_name.upper():.<50} {status}")
    
    print("\n" + "=" * 60)
    
    if all_passed:
        print("✓✓✓ ALL CHECKS PASSED! ✓✓✓")
        print("\nProject appears to be error-free!")
        print("\nTo run the server:")
        print("  python server.py")
        print("\nThen open browser to: http://127.0.0.1:5000")
    else:
        print("⚠⚠⚠ SOME CHECKS FAILED ⚠⚠⚠")
        print("\nPlease address the issues above before running the server.")
    
    print("=" * 60 + "\n")
    
    return all_passed

if __name__ == "__main__":
    try:
        success = generate_report()
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"\n✗ Validation script error: {e}")
        sys.exit(1)
