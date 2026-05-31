import os
from dotenv import load_dotenv

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
load_dotenv(os.path.join(BASE_DIR, ".env"))


def _resolve_database_url(raw_url: str) -> str:
    if raw_url.startswith("postgres://"):
        return raw_url.replace("postgres://", "postgresql://", 1)

    if not raw_url.startswith("sqlite:///"):
        return raw_url

    sqlite_path = raw_url.replace("sqlite:///", "", 1)
    if sqlite_path == ":memory:" or os.path.isabs(sqlite_path):
        return raw_url

    absolute_path = os.path.abspath(os.path.join(BASE_DIR, sqlite_path))
    return "sqlite:///" + absolute_path.replace("\\", "/")


# Database
DATABASE_URL = _resolve_database_url(
    os.getenv("DATABASE_URL", "sqlite:///restaurant.db")
)

# Firebase
FIREBASE_PROJECT_ID = os.getenv("FIREBASE_PROJECT_ID")
FIREBASE_PRIVATE_KEY = os.getenv("FIREBASE_PRIVATE_KEY")
FIREBASE_CLIENT_EMAIL = os.getenv("FIREBASE_CLIENT_EMAIL")

# Other configs
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key")
DEBUG = os.getenv("DEBUG", "False").lower() == "true"
