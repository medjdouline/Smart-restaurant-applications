import os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()  # Load .env file

BASE_DIR = Path(__file__).resolve().parent.parent

# Security settings
SECRET_KEY = os.getenv('DJANGO_SECRET_KEY')
DEBUG = os.getenv('DJANGO_DEBUG') == 'True'
ALLOWED_HOSTS = ['*']

DEFAULT_CHARSET = 'utf-8'

# File charset (if reading files)
FILE_CHARSET = 'utf-8'
# Applications
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'corsheaders',
    'core',
    'kitchen_app',
    'manager_app',
    'server_app',
    'client_mobile',
    'client_table',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

# REST Framework
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'core.authentication.FirebaseAuthentication',
        'rest_framework.authentication.SessionAuthentication',  # Optional - for browsable API
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
    'DEFAULT_RENDERER_CLASSES': [
        'rest_framework.renderers.JSONRenderer',
    ],
    'UNICODE_JSON': True, 
    
}

CORS_ALLOW_ALL_ORIGINS = True
CORS_ALLOW_CREDENTIALS = True
CORS_ORIGIN_ALLOW_ALL = True
ROOT_URLCONF = 'restaurant_system.urls'

# Templates
TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'restaurant_system.wsgi.application'
DATABASES = {}

# Firebase Configuration
FIREBASE_CREDENTIALS_PATH = os.path.abspath(os.getenv('FIREBASE_CREDENTIALS_PATH'))
if not os.path.exists(FIREBASE_CREDENTIALS_PATH):
    raise FileNotFoundError(f"Firebase credentials missing at {FIREBASE_CREDENTIALS_PATH}")
FIREBASE_API_KEY = "AIzaSyAYqym7Dcr1k_VhyP54L8mxpzT7QctiCQ8"
# Security
AUTH_PASSWORD_VALIDATORS = []
AUTHENTICATION_BACKENDS = []

# Internationalization
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

# Static files
STATIC_URL = 'static/'
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
ALLOWED_HOSTS = ['192.168.100.13',
                 'localhost', '127.0.0.1']

FIREBASE_CONFIG = {
  "apiKey": "AIzaSyAh_qXAMGvuayCYU0Dany2RIgC5Z4NQg1M",
  "authDomain": "pferestau25.firebaseapp.com",
  "projectId": "pferestau25",
  "storageBucket": "pferestau25.firebasestorage.app",
  "messagingSenderId": "180090883215",
  "appId": "1:180090883215:web:c1dabc61a8a3ab8a4e34fa"
}
