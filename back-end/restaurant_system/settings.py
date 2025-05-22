import os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()  # Load .env file

BASE_DIR = Path(__file__).resolve().parent.parent

# Security settings
SECRET_KEY = os.getenv('DJANGO_SECRET_KEY')
DEBUG = os.getenv('DJANGO_DEBUG') == 'True'
ALLOWED_HOSTS = ['*']

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
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',  # Fixed typo (WhiteNoiseMiddleware)
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

CORS_ALLOW_ALL_ORIGINS = True

# REST Framework
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'core.authentication.FirebaseAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
}

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

# Firebase Configuration
FIREBASE_CREDENTIALS_PATH = os.path.abspath(os.getenv('FIREBASE_CREDENTIALS_PATH'))
if not os.path.exists(FIREBASE_CREDENTIALS_PATH):
    raise FileNotFoundError(f"Firebase credentials missing at {FIREBASE_CREDENTIALS_PATH}")

FIREBASE_CONFIG = {
    "apiKey": os.getenv('FIREBASE_API_KEY', "AIzaSyAh_qXAMGvuayCYU0Dany2RIgC5Z4NQg1M"),  # Now using env var
    "authDomain": os.getenv('FIREBASE_AUTH_DOMAIN', "pferestau25.firebaseapp.com"),
    "projectId": os.getenv('FIREBASE_PROJECT_ID', "pferestau25"),
    "storageBucket": os.getenv('FIREBASE_STORAGE_BUCKET', "pferestau25.firebasestorage.app"),
    "messagingSenderId": os.getenv('FIREBASE_SENDER_ID', "180090883215"),
    "appId": os.getenv('FIREBASE_APP_ID', "1:180090883215:android:c8385ed9ed2b65934e34fa")
}

# Security
AUTH_PASSWORD_VALIDATORS = []
AUTHENTICATION_BACKENDS = []

# Internationalization
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

# Static files
STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.dummy',  # Disables database
    }
}