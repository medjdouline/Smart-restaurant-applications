import os
import json
import logging
import firebase_admin
from firebase_admin import credentials, firestore, auth
from django.conf import settings
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

logger = logging.getLogger(__name__)

class FirebaseConfig:
    _app = None
    _db = None
    _auth = None
    _credentials_path = None
    _last_modified = None

    @classmethod
    def _get_credentials_info(cls):
        """Get current credentials file info"""
        firebase_credentials = os.getenv('FIREBASE_CREDENTIALS_PATH')
        if not firebase_credentials:
            raise ValueError("FIREBASE_CREDENTIALS_PATH not found in environment variables")
        
        abs_path = os.path.abspath(firebase_credentials)
        if not os.path.exists(abs_path):
            raise FileNotFoundError(f"Firebase credentials file not found: {abs_path}")
            
        # Get file modification time
        mod_time = os.path.getmtime(abs_path)
        
        return abs_path, mod_time

    @classmethod
    def _should_reload(cls):
        """Check if Firebase should be reloaded (new credentials file)"""
        try:
            current_path, current_mod_time = cls._get_credentials_info()
            
            # If path changed or file was modified, reload
            if (cls._credentials_path != current_path or 
                cls._last_modified != current_mod_time or 
                cls._app is None):
                return True, current_path, current_mod_time
                
            return False, current_path, current_mod_time
        except Exception as e:
            logger.error(f"Error checking credentials: {str(e)}")
            return True, None, None  # Force reload on error

    @classmethod
    def _initialize_firebase(cls):
        """Initialize Firebase with current credentials"""
        try:
            # Clear existing Firebase apps
            try:
                firebase_admin.get_app()
                firebase_admin.delete_app(firebase_admin.get_app())
            except ValueError:
                pass  # No app to delete

            # Get credentials
            credentials_path, mod_time = cls._get_credentials_info()
            
            # Initialize with new credentials
            cred = credentials.Certificate(credentials_path)
            cls._app = firebase_admin.initialize_app(cred)
            cls._db = firestore.client()
            cls._auth = auth
            
            # Store current info
            cls._credentials_path = credentials_path
            cls._last_modified = mod_time
            
            logger.info(f"Firebase initialized successfully with credentials: {credentials_path}")
            
        except Exception as e:
            logger.error(f"Firebase initialization failed: {str(e)}")
            raise

    @classmethod
    def get_db(cls):
        """Get Firestore database instance (auto-reload if needed)"""
        should_reload, path, mod_time = cls._should_reload()
        
        if should_reload:
            logger.info("Reloading Firebase due to credentials change...")
            cls._initialize_firebase()
        
        if cls._db is None:
            cls._initialize_firebase()
            
        return cls._db

    @classmethod
    def get_auth(cls):
        """Get Firebase Auth instance (auto-reload if needed)"""
        should_reload, path, mod_time = cls._should_reload()
        
        if should_reload:
            logger.info("Reloading Firebase due to credentials change...")
            cls._initialize_firebase()
            
        if cls._auth is None:
            cls._initialize_firebase()
            
        return cls._auth

    @classmethod
    def get_app(cls):
        """Get Firebase App instance (auto-reload if needed)"""
        should_reload, path, mod_time = cls._should_reload()
        
        if should_reload:
            logger.info("Reloading Firebase due to credentials change...")
            cls._initialize_firebase()
            
        if cls._app is None:
            cls._initialize_firebase()
            
        return cls._app

    @classmethod
    def reload_firebase(cls):
        """Force reload Firebase with new credentials"""
        try:
            # Reset all instances
            cls._app = None
            cls._db = None
            cls._auth = None
            firebase_admin._apps.clear()  # Clear all apps
            
            # Reinitialize
            cls._initialize_firebase()
            logger.info("Firebase reloaded successfully")
        except Exception as e:
            logger.error(f"Firebase reload failed: {str(e)}")
            raise

# Global instance
firebase_config = FirebaseConfig()

# Initialize on first import
try:
    firebase_config._initialize_firebase()
except Exception as e:
    logger.error(f"Initial Firebase setup failed: {str(e)}")

# Convenience functions for backward compatibility
def get_firestore_db():
    return firebase_config.get_db()

def get_firebase_auth():
    return firebase_config.get_auth()

def get_firebase_app():
    return firebase_config.get_app()