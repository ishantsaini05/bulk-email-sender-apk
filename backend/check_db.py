# backend/check_db.py
import os
import sys
from sqlalchemy import create_engine, text
from sqlalchemy.exc import OperationalError

def check_database_connection():
    print("🔍 DATABASE CONNECTION DIAGNOSIS")
    print("="*50)
    
    # Read .env file
    env_path = os.path.join(os.path.dirname(__file__), '.env')
    
    if not os.path.exists(env_path):
        print("❌ .env file not found!")
        print(f"Expected at: {env_path}")
        return False
    
    print(f"✅ .env file found at: {env_path}")
    
    # Read DATABASE_URL from .env
    with open(env_path, 'r') as f:
        env_content = f.read()
        print("\n📄 .env content:")
        print("-"*30)
        print(env_content)
        print("-"*30)
    
    # Try to parse DATABASE_URL (simplified)
    for line in env_content.split('\n'):
        if line.startswith('DATABASE_URL='):
            db_url = line.split('=', 1)[1].strip()
            print(f"\n🔗 Database URL: {db_url}")
            
            # Mask password for display
            if ':@' in db_url:
                display_url = db_url
            elif ':' in db_url and '@' in db_url:
                # Hide password
                parts = db_url.split('@')
                user_pass = parts[0].split(':')
                if len(user_pass) == 2:
                    display_url = f"{user_pass[0]}:****@{parts[1]}"
                else:
                    display_url = db_url
            else:
                display_url = db_url
            
            print(f"🔗 Display URL: {display_url}")
            
            # Test connection
            try:
                print("\n🔌 Testing database connection...")
                engine = create_engine(db_url)
                with engine.connect() as connection:
                    # Simple query to test
                    result = connection.execute(text("SELECT 1"))
                    print("✅ Database connection SUCCESSFUL!")
                    
                    # Try to check our database
                    try:
                        result = connection.execute(text("SHOW DATABASES"))
                        databases = [row[0] for row in result]
                        print(f"\n📊 Available databases: {databases}")
                        
                        if 'premium_email_app' in databases:
                            print("✅ Database 'premium_email_app' exists!")
                            
                            # Check tables
                            connection.execute(text("USE premium_email_app"))
                            result = connection.execute(text("SHOW TABLES"))
                            tables = [row[0] for row in result]
                            print(f"📋 Tables in database: {tables}")
                            
                            required_tables = ['users', 'user_secrets', 'email_logs']
                            missing = [t for t in required_tables if t not in tables]
                            if missing:
                                print(f"⚠️ Missing tables: {missing}")
                            else:
                                print("✅ All required tables exist!")
                        else:
                            print("❌ Database 'premium_email_app' NOT FOUND!")
                            print("Run: CREATE DATABASE premium_email_app;")
                            
                    except Exception as e:
                        print(f"⚠️ Could not list databases: {e}")
                    
                    return True
                    
            except OperationalError as e:
                print(f"❌ Database connection FAILED!")
                print(f"Error: {e}")
                
                # Common error messages and solutions
                error_msg = str(e).lower()
                if "access denied" in error_msg:
                    print("\n💡 SOLUTION: Wrong MySQL username/password")
                    print("1. Check if MySQL has a password")
                    print("2. Update DATABASE_URL in .env file")
                    print("   Format: mysql+pymysql://username:password@localhost/database")
                elif "unknown database" in error_msg:
                    print("\n💡 SOLUTION: Database doesn't exist")
                    print("Run: CREATE DATABASE premium_email_app;")
                elif "can't connect" in error_msg:
                    print("\n💡 SOLUTION: MySQL service not running")
                    print("1. Open Services (services.msc)")
                    print("2. Find 'MySQL80' or 'MySQL'")
                    print("3. Start the service")
                elif "2003" in error_msg or "10061" in error_msg:
                    print("\n💡 SOLUTION: MySQL not running on localhost")
                    print("1. Start MySQL service")
                    print("2. Check if MySQL is on different port (default: 3306)")
                return False
            except Exception as e:
                print(f"❌ Unexpected error: {e}")
                return False
    
    print("❌ DATABASE_URL not found in .env file!")
    return False

def check_fastapi_db_connection():
    print("\n" + "="*50)
    print("🔗 TESTING FASTAPI DATABASE MODULE")
    print("="*50)
    
    try:
        # Import your actual database module
        from app.database import engine
        
        print("✅ Successfully imported database module")
        
        # Test connection through your module
        with engine.connect() as conn:
            result = conn.execute(text("SELECT 1"))
            print("✅ FastAPI database connection works!")
            return True
    except ImportError as e:
        print(f"❌ Cannot import database module: {e}")
        print("Check if you're in the correct directory (backend folder)")
        return False
    except Exception as e:
        print(f"❌ FastAPI database error: {e}")
        return False

if __name__ == "__main__":
    print("🚀 DATABASE CONNECTION TROUBLESHOOTER")
    print("="*60)
    
    # Check current directory
    print(f"📁 Current directory: {os.getcwd()}")
    
    # Run checks
    db_ok = check_database_connection()
    fastapi_ok = check_fastapi_db_connection()
    
    print("\n" + "="*60)
    print("📊 DIAGNOSIS SUMMARY")
    print("="*60)
    
    if db_ok and fastapi_ok:
        print("✅ All database checks PASSED!")
        print("\n💡 Next: Run the test again or check API logic")
    elif db_ok and not fastapi_ok:
        print("⚠️ Database works but FastAPI can't connect")
        print("Check app/database.py configuration")
    elif not db_ok and fastapi_ok:
        print("⚠️ FastAPI connects but direct test fails")
        print("Check .env file vs database.py configuration")
    else:
        print("❌ Database connection FAILED on all tests")
        print("\n🔧 COMMON SOLUTIONS:")
        print("1. Ensure MySQL service is running")
        print("2. Check username/password in .env file")
        print("3. Create database: CREATE DATABASE premium_email_app;")
        print("4. Create tables using SQL script from earlier")
    
    print("\n🔗 Test API manually: http://localhost:8000/docs")
    