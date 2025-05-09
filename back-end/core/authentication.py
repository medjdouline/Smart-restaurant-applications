from firebase_admin import auth
from rest_framework import authentication
from rest_framework.exceptions import AuthenticationFailed
from core.firebase_utils import firebase_config
from firebase_admin import firestore
import logging

logger = logging.getLogger(__name__)

class FirebaseUser:
    def __init__(self, uid, email, claims):
        self.uid = uid
        self.email = email
        self.claims = claims or {}
        self.is_authenticated = True
        
    @property
    def role(self):
        return self.claims.get('role', 'guest')
        
    @property
    def is_guest(self):
        return self.claims.get('is_guest', False)
        
    @property  # Add this new property
    def is_signup_complete(self):
        return self.claims.get('signup_complete', False)

class FirebaseAuthentication(authentication.BaseAuthentication):
    """Complete authentication for all roles"""
    
    def authenticate(self, request):
        auth_header = request.META.get('HTTP_AUTHORIZATION', '')
        
        if not auth_header.startswith('Bearer '):
            return None
            
        token = auth_header.split(' ').pop()
        if not token:
            return None
            
        try:
            decoded = auth.verify_id_token(token)
            user = auth.get_user(decoded['uid'])
            
            return (
                FirebaseUser(
                    uid=user.uid,
                    email=user.email,
                    claims=user.custom_claims or {}
                ),
                None
            )
        except Exception as e:
            logger.error(f"Authentication failed: {str(e)}")
            raise AuthenticationFailed(str(e))
    
    def authenticate_header(self, request):
        return 'Bearer realm="api"'

def authenticate_firebase_user(request):
    """
    Authenticate a Firebase user from the request.
    This is a wrapper around FirebaseAuthentication for use in regular Django views.
    """
    try:
        auth = FirebaseAuthentication()
        user, _ = auth.authenticate(request)
        return user
    except Exception as e:
        logger.error(f"Firebase authentication failed: {str(e)}")
        return None
    
# Add the missing utility functions
def get_firebase_user(uid: str) -> FirebaseUser:
    """Get Firebase user by UID"""
    try:
        user = auth.get_user(uid)
        return FirebaseUser(
            uid=user.uid,
            email=user.email,
            claims=user.custom_claims or {}
        )
    except Exception as e:
        logger.error(f"Failed to get Firebase user: {str(e)}")
        return None

def set_custom_claims(uid: str, claims: dict) -> bool:
    """Set custom claims for a Firebase user"""
    try:
        auth.set_custom_user_claims(uid, claims)
        return True
    except Exception as e:
        logger.error(f"Failed to set custom claims: {str(e)}")
        return False

def create_manager_account(email: str, password: str, first_name: str, last_name: str) -> dict:
    """Complete manager registration"""
    try:
        db = firebase_config.get_db()
        
        # Create Firebase user
        user = auth.create_user(
            email=email,
            password=password,
            display_name=f"{first_name} {last_name}"
        )

        # Set manager claims
        auth.set_custom_user_claims(user.uid, {
            'role': 'manager',
            'is_guest': False
        })
        
        # Create employee record
        employes_data = {
            'nomE': last_name,
            'prenomE': first_name,
            'usernameE': email.split('@')[0],
            'role': 'manager',
            'adresseE': '',
            'dateEmbauche': firestore.SERVER_TIMESTAMP
        }
        employes_ref = db.collection('employes').document()
        employes_ref.set(employes_data)
        
        # Create manager record
        db.collection('managers').document().set({
            'employes_id': employes_ref.id
        })
        
        return {
            'uid': user.uid,
            'email': user.email,
            'employes_id': employes_ref.id
        }
    except Exception as e:
        logger.error(f"Manager creation failed: {str(e)}")
        raise