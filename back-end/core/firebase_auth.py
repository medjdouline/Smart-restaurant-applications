from .firebase_utils import firebase_config

class FirebaseAuth:
    def __init__(self):
        self.auth = firebase_config.get_auth()

    def verify_token(self, id_token):
        """
        Verify Firebase ID token
        
        Args:
            id_token (str): Firebase ID token to verify
        
        Returns:
            dict: Decoded token information or None
        """
        try:
            decoded_token = self.auth.verify_id_token(id_token)
            return decoded_token
        except Exception as e:
            print(f"Token verification error: {e}")
            return None

    def get_user(self, uid):
        """
        Get user information by UID
        
        Args:
            uid (str): Firebase user ID
        
        Returns:
            dict: User information
        """
        try:
            user = self.auth.get_user(uid)
            return {
                'uid': user.uid,
                'email': user.email,
                'display_name': user.display_name,
                'photo_url': user.photo_url
            }
        except Exception as e:
            print(f"Error fetching user: {e}")
            return None

# Create a singleton instance
firebase_auth = FirebaseAuth()