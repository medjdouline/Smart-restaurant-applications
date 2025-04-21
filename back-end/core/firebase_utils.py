import os
import firebase_admin
from firebase_admin import credentials, firestore, auth
from dotenv import load_dotenv
import logging

# Load environment variables from .env file
load_dotenv()

logger = logging.getLogger(__name__)

class FirebaseConfig:
    _instance = None
    _app = None
    _db = None
    _auth = None

    def __new__(cls):
        if not cls._instance:
            cls._instance = super(FirebaseConfig, cls).__new__(cls)
            cls._initialize_firebase()
        return cls._instance

    @classmethod
    def _initialize_firebase(cls):
        """Initialize Firebase connection"""
        try:
            if not firebase_admin._apps:
                cred_path = os.getenv('FIREBASE_CREDENTIALS_PATH')
                
                if not cred_path:
                    raise ValueError("FIREBASE_CREDENTIALS_PATH not set in .env")
                    
                if not os.path.exists(cred_path):
                    raise FileNotFoundError(f"Firebase credentials missing: {cred_path}")

                cred = credentials.Certificate(cred_path)
                cls._app = firebase_admin.initialize_app(cred)
                cls._db = firestore.client()
                cls._auth = auth
            
            logger.info("Firebase initialized successfully")
        
        except Exception as e:
            logger.error(f"Firebase initialization failed: {str(e)}")
            raise RuntimeError(f"Firebase initialization failed: {str(e)}")

    @classmethod
    def get_db(cls):
        """Get Firestore database client"""
        if not cls._db:
            raise ConnectionError("Firestore not initialized")
        return cls._db

    @classmethod
    def get_auth(cls):
        """Get Firebase Auth instance"""
        if not cls._app:
            raise ConnectionError("Firebase not initialized")
        return cls._auth

    @classmethod
    def verify_token(cls, token: str) -> dict:
        """Verify and decode Firebase ID token"""
        try:
            decoded = auth.verify_id_token(token)
            user = auth.get_user(decoded['uid'])
            return {
                'uid': user.uid,
                'email': user.email,
                'email_verified': user.email_verified,
                'claims': user.custom_claims or {},
                'is_active': not user.disabled
            }
        except ValueError as e:
            logger.error(f"Invalid token: {str(e)}")
            raise AuthenticationFailed('Invalid token format')
        except auth.InvalidIdTokenError:
            logger.error("Invalid ID token")
            raise AuthenticationFailed('Invalid token')
        except auth.ExpiredIdTokenError:
            logger.error("Expired ID token")
            raise AuthenticationFailed('Expired token')
        except auth.RevokedIdTokenError:
            logger.error("Revoked ID token")
            raise AuthenticationFailed('Revoked token')
        except auth.UserDisabledError:
            logger.error("Disabled user")
            raise AuthenticationFailed('User disabled')
        except Exception as e:
            logger.error(f"Token verification failed: {str(e)}")
            raise AuthenticationFailed('Token verification failed')

# Singleton instance
firebase_config = FirebaseConfig()