import os
from dotenv import load_dotenv
from datetime import timedelta

load_dotenv()

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-secret-key-change-in-prod'
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or 'sqlite:///triade.db'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    JSON_SORT_KEYS = False
    
    # JWT Configuration
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY') or 'jwt-super-secret-key-change-in-prod'
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(days=30)  # Token válido por 30 dias
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=90)  # Refresh token válido por 90 dias
    
    # Upload Configuration
    MAX_CONTENT_LENGTH = 2 * 1024 * 1024  # 2MB max para upload de foto
