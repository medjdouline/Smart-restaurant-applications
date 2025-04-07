import os
import firebase_admin
from firebase_admin import credentials, firestore, auth

class FirebaseConfig:
    _instance = None
    _app = None
    _db = None

    def __new__(cls):
        if not cls._instance:
            cls._instance = super(FirebaseConfig, cls).__new__(cls)
            cls._initialize_firebase()
        return cls._instance

    @classmethod
    def _initialize_firebase(cls):
        """Initialize Firebase connection"""
        try:
            # Check if Firebase app is already initialized
            if not firebase_admin._apps:
                # Path to Firebase credentials
                cred_path = os.environ.get(
                    'FIREBASE_CREDENTIALS_PATH', 
                    r'C:\Users\21355\pferestau25-firebase-adminsdk-fbsvc-ba2388677e.json'
                )
                
                # Load credentials and initialize app
                cred = credentials.Certificate(cred_path)
                cls._app = firebase_admin.initialize_app(cred)
            
            # Create Firestore client
            cls._db = firestore.client()
        
        except Exception as e:
            print(f"Firebase initialization error: {e}")
            cls._db = None
            cls._app = None

    @classmethod
    def get_db(cls):
        """Get Firestore database client"""
        return cls._db

    @classmethod
    def get_auth(cls):
        """Get Firebase Auth instance"""
        return auth

# Create a singleton instance
firebase_config = FirebaseConfig()