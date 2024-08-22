import os

class AppConfig:
    DEBUG = os.getenv('FLASK_ENV') == 'development'
    OLLAMA_API_BASE_URL = os.getenv('OLLAMA_API_BASE_URL', 'http://localhost:11434')
    SECRET_KEY = os.getenv('SECRET_KEY', 'your-secret-key-here')
