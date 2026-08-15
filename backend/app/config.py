import os
from dotenv import load_dotenv

load_dotenv()

class Settings:
    # Default: SQLite so the project runs instantly with zero setup.
    # For MySQL (as described in the abstract), set DATABASE_URL, e.g.:
    # mysql+pymysql://user:password@localhost:3306/property_verification
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./property_verification.db")

    SECRET_KEY: str = os.getenv("SECRET_KEY", "CHANGE_THIS_SECRET_KEY_IN_PRODUCTION_env_var")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24

    APP_NAME: str = "AI Property Legal Verification & Litigation Risk Assessment System"
    
    

settings = Settings()
