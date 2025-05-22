import logging
from firebase_admin import auth, firestore
from firebase_admin.exceptions import FirebaseError
from core.firebase_utils import firebase_config
from core.firebase_crud import firebase_crud
from typing import Optional, Dict, Union

logger = logging.getLogger(__name__)

class FirebaseAuth:
    """Complete authentication service matching MLD requirements"""
    
    def __init__(self):
        self.auth = auth
        self.db = firebase_config.get_db()

    # ======================
# Core Authentication
# ======================
def verify_token(self, id_token: str) -> Dict:
    """Enhanced token verification with MLD-specific checks and signup completion validation"""
    try:
        decoded = auth.verify_id_token(id_token)
        user = auth.get_user(decoded['uid'])
        claims = user.custom_claims or {}
        
        # Block access for incomplete client signups
        if claims.get('role') == 'client' and not claims.get('signup_complete', False):
            logger.warning(f"Incomplete signup attempt by {user.uid}")
            raise AuthenticationFailed('Complete your signup process first')
            
        # Get additional user data from Firestore based on role
        user_data = self._get_user_data(user)
        
        return {
            'uid': user.uid,
            'email': user.email,
            'claims': claims,
            'signup_complete': claims.get('signup_complete', False),  # New field
            **user_data
        }
        
    except ValueError as e:
        logger.error(f"Invalid token format: {str(e)}")
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
        logger.error("Disabled user account")
        raise AuthenticationFailed('Account disabled')
    except Exception as e:
        logger.error(f"Token verification failed: {str(e)}")
        raise AuthenticationFailed('Authentication failed')

def _get_user_data(self, user) -> Dict:
    """Get MLD-specific user data based on role with signup status"""
    claims = user.custom_claims or {}
    role = claims.get('role', 'guest')
    
    if role in ['client', 'guest']:
        client = firebase_crud.get_doc('clients', user.uid)
        if not client:
            return {'role': 'guest'}  # Fallback if document missing
            
        return {
            'role': role,
            'username': client.get('username'),
            'is_guest': client.get('is_guest', False),
            'fidelity_points': client.get('fidelity_points', 0),
            'signup_complete': not client.get('is_guest', True) and claims.get('signup_complete', False),
            'preferences': client.get('preferences', []),
            'allergies': client.get('allergies', []),
            'restrictions': client.get('restrictions', [])
        }
        
    elif role in ['server', 'chef', 'manager']:
        employee = firebase_crud.query_collection(
            'employees', 
            'firebase_uid', 
            '==', 
            user.uid
        )
        if employee:
            return {
                'role': role,
                'first_name': employee[0].get('first_name'),
                'last_name': employee[0].get('last_name'),
                'employee_id': employee[0].id,
                'signup_complete': True  # Staff accounts are always complete
            }
            
    # Default for guests/unrecognized roles
    return {
        'role': 'guest',
        'signup_complete': False
    }

    # ======================
    # User Registration
    # ======================
    def register_client(self, email: str, password: str, username: str) -> Dict:
        """Complete client registration flow per MLD"""
        try:
            user = auth.create_user(
                email=email,
                password=password,
                display_name=username
            )
            
            # Set custom claims
            auth.set_custom_user_claims(user.uid, {
                'role': 'client',
                'is_guest': False
            })
            
            # Create Firestore record
            client_data = {
                'username': username,
                'email': email,
                'is_guest': False,
                'fidelity_points': 0,
                'created_at': firestore.SERVER_TIMESTAMP
            }
            firebase_crud.create_doc('clients', client_data, user.uid)
            
            return {
                'uid': user.uid,
                'email': user.email,
                'username': username
            }
        except auth.EmailAlreadyExistsError:
            raise AuthenticationFailed('Email already registered')
        except Exception as e:
            logger.error(f"Client registration failed: {str(e)}")
            raise AuthenticationFailed('Registration failed')

    def create_guest_session(self) -> Dict:
        """Anonymous guest session per MLD"""
        try:
            user = auth.create_user()
            auth.set_custom_user_claims(user.uid, {
                'role': 'guest',
                'is_guest': True
            })
            
            guest_data = {
                'username': f'guest_{user.uid[:6]}',
                'is_guest': True,
                'created_at': firestore.SERVER_TIMESTAMP,
                'temp_session': True
            }
            firebase_crud.create_doc('clients', guest_data, user.uid)
            
            return {
                'uid': user.uid,
                'is_guest': True,
                'username': guest_data['username']
            }
        except Exception as e:
            logger.error(f"Guest session creation failed: {str(e)}")
            raise AuthenticationFailed('Guest login failed')

    # ======================
    # Staff Authentication
    # ======================
    def authenticate_staff(self, email: str, password: str) -> Dict:
        """Complete staff authentication per MLD"""
        try:
            user = auth.get_user_by_email(email)
            
            # Verify staff role
            claims = user.custom_claims or {}
            if claims.get('role') not in ['server', 'chef', 'manager']:
                raise AuthenticationFailed('Invalid staff credentials')
            
            # Get employee record
            employee = firebase_crud.query_collection(
                'employees',
                'firebase_uid',
                '==',
                user.uid
            )
            
            if not employee:
                raise AuthenticationFailed('Employee record not found')
                
            return {
                'uid': user.uid,
                'role': claims['role'],
                'employee_id': employee[0].id,
                'first_name': employee[0].get('first_name'),
                'last_name': employee[0].get('last_name')
            }
        except auth.UserNotFoundError:
            raise AuthenticationFailed('Staff member not found')
        except Exception as e:
            logger.error(f"Staff auth failed: {str(e)}")
            raise AuthenticationFailed('Staff authentication failed')

    # ======================
    # Role Management
    # ======================
    def assign_role(self, uid: str, role: str) -> bool:
        """Assign role with MLD validation"""
        valid_roles = ['client', 'guest', 'server', 'chef', 'manager']
        if role not in valid_roles:
            raise ValueError(f"Invalid role. Must be one of: {valid_roles}")
            
        try:
            auth.set_custom_user_claims(uid, {'role': role})
            
            # Update Firestore if needed
            if role in ['server', 'chef', 'manager']:
                firebase_crud.update_doc(
                    'employees',
                    uid,  # Assuming employee doc ID matches UID
                    {'role': role}
                )
            return True
        except Exception as e:
            logger.error(f"Role assignment failed: {str(e)}")
            return False

    # ======================
    # Session Management
    # ======================
    def revoke_sessions(self, uid: str) -> bool:
        """Revoke all user sessions per MLD"""
        try:
            auth.revoke_refresh_tokens(uid)
            return True
        except Exception as e:
            logger.error(f"Session revocation failed: {str(e)}")
            return False

# Singleton instance
firebase_auth = FirebaseAuth()