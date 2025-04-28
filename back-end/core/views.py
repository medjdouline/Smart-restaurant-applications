from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from datetime import datetime
from firebase_admin import auth, firestore
from .firebase_utils import firebase_config
from .authentication import set_custom_claims
from firebase_admin import auth
from .permissions import IsManager, IsClient, IsGuest, IsTableClient, IsStaff
import logging

logger = logging.getLogger(__name__)
db = firebase_config.get_db()

# Predefined options
ALLOWED_PREFERENCES = [
    'Soupes et Potages', 'Salades et Crudités', 'Poissons et Fruit de mer',
    'Cuisine traditionnelle', 'Viandes', 'Sandwichs et burgers', 'Végétarien',
    'Crémes et Mousses', 'Pâtisseries', 'Fruits et Sorbets'
]

ALLOWED_ALLERGIES = [
    'Fraise', 'Fruit exotique', 'Gluten', 'Arachides', 'Noix', 'Lupin',
    'Champignons', 'Moutarde', 'Soja', 'Crustacés', 'Poisson', 'Lactose', 'Œufs'
]

ALLOWED_RESTRICTIONS = [
    'Végétarien', 'Végétalien', 'Keto', 'Sans lactose', 'Sans gluten'
]
#client

@api_view(['POST'])
@permission_classes([AllowAny])
def client_signup_step1(request):
    try:
        email = request.data.get('email')
        password = request.data.get('password')
        username = request.data.get('username')
        phone_number = request.data.get('phone_number')

        if not all([email, password, username, phone_number]):
            return Response(
                {'error': 'All fields are required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Create Firebase user (incomplete signup)
        user = auth.create_user(
            email=email,
            password=password,
            display_name=username
        )

        # Store temporary data
        db.collection('temp_signups').document(user.uid).set({
            'email': email,
            'username': username,
            'phone_number': phone_number,
            'password': password,  # Note: Only for demo. Hash it in production.
            'step': 1
        })

        # Temporary claims (not fully authenticated)
        set_custom_claims(user.uid, {
            'role': 'unverified_client',
            'signup_complete': False
        })

        return Response({
            'uid': user.uid,
            'message': 'Proceed to Step 2: Personal Information'
        })

    except auth.EmailAlreadyExistsError:
        return Response(
            {'error': 'Email already registered'},
            status=status.HTTP_400_BAD_REQUEST
        )
    except Exception as e:
        logger.error(f"Signup Step 1 failed: {str(e)}")
        return Response(
            {'error': 'Registration failed'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['POST'])
@permission_classes([AllowAny])
def client_signup_step2(request):
    try:
        uid = request.data.get('uid')
        birthdate = request.data.get('birthdate')
        gender = request.data.get('gender')

        if not all([uid, birthdate, gender]):
            return Response(
                {'error': 'All fields are required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Validate birthdate (13+ years)
        birthdate_dt = datetime.strptime(birthdate, '%Y-%m-%d').date()
        if (datetime.now().date() - birthdate_dt).days < 13 * 365:
            return Response(
                {'error': 'You must be at least 13 years old'},
                status=status.HTTP_403_FORBIDDEN
            )

        # Update temp data
        db.collection('temp_signups').document(uid).update({
            'birthdate': birthdate,
            'gender': gender,
            'step': 2
        })

        return Response({'message': 'Proceed to Step 3: Preferences'})

    except ValueError:
        return Response(
            {'error': 'Invalid birthdate format (YYYY-MM-DD)'},
            status=status.HTTP_400_BAD_REQUEST
        )
    except Exception as e:
        logger.error(f"Signup Step 2 failed: {str(e)}")
        return Response(
            {'error': 'Step 2 failed'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['POST'])
@permission_classes([AllowAny])
def client_signup_step3(request):
    try:
        uid = request.data.get('uid')
        preferences = request.data.get('preferences', [])

        if not uid or len(preferences) < 3:
            return Response(
                {'error': 'Select at least 3 preferences'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Validate preferences
        invalid_prefs = [p for p in preferences if p not in ALLOWED_PREFERENCES]
        if invalid_prefs:
            return Response(
                {'error': f'Invalid preferences: {", ".join(invalid_prefs)}'},
                status=status.HTTP_400_BAD_REQUEST
            )

        db.collection('temp_signups').document(uid).update({
            'preferences': preferences,
            'step': 3
        })

        return Response({'message': 'Proceed to Step 4: Allergies/Restrictions'})

    except Exception as e:
        logger.error(f"Signup Step 3 failed: {str(e)}")
        return Response(
            {'error': 'Step 3 failed'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['POST'])
@permission_classes([AllowAny])
def client_signup_step4(request):
    try:
        uid = request.data.get('uid')
        allergies = request.data.get('allergies', [])
        restrictions = request.data.get('restrictions', [])

        if not uid:
            return Response(
                {'error': 'UID required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Get all temp data
        temp_data = db.collection('temp_signups').document(uid).get().to_dict()

        # Create final client document
        client_data = {
            'username': temp_data['username'],
            'email': temp_data['email'],
            'phone_number': temp_data['phone_number'],
            'birthdate': temp_data['birthdate'],
            'gender': temp_data['gender'],
            'preferences': temp_data['preferences'],
            'allergies': allergies,
            'restrictions': restrictions,
            'is_guest': False,
            'fidelity_points': 0,
            'created_at': firestore.SERVER_TIMESTAMP
        }

        db.collection('clients').document(uid).set(client_data)
        db.collection('temp_signups').document(uid).delete()

        # Mark as fully authenticated
        set_custom_claims(uid, {
            'role': 'client',
            'signup_complete': True
        })

        # Generate token for immediate login
        custom_token = auth.create_custom_token(uid)

        return Response({
            'message': 'Account created successfully',
            'custom_token': custom_token.decode('utf-8')
        }, status=status.HTTP_201_CREATED)

    except Exception as e:
        logger.error(f"Signup Step 4 failed: {str(e)}")
        return Response(
            {'error': 'Account creation failed'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['POST'])
@permission_classes([AllowAny])
def client_login(request):
    try:
        identifier = request.data.get('identifier')
        password = request.data.get('password')

        if not identifier or not password:
            return Response(
                {'error': 'Identifier and password required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Find user by email or username
        if '@' in identifier:
            user = auth.get_user_by_email(identifier)
        else:
            clients = db.collection('clients').where('username', '==', identifier).limit(1).stream()
            client = next(clients, None)
            if not client:
                return Response(
                    {'error': 'User not found'},
                    status=status.HTTP_404_NOT_FOUND
                )
            user = auth.get_user(client.id)

        # Verify account is fully set up
        claims = user.custom_claims or {}
        if not claims.get('signup_complete'):
            return Response(
                {'error': 'Complete your signup process first'},
                status=status.HTTP_403_FORBIDDEN
            )

        # Generate login token
        custom_token = auth.create_custom_token(user.uid)

        return Response({
            'uid': user.uid,
            'custom_token': custom_token.decode('utf-8'),
            'is_guest': False
        })

    except auth.UserNotFoundError:
        return Response(
            {'error': 'User not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        logger.error(f"Login failed: {str(e)}")
        return Response(
            {'error': 'Login failed'},
            status=status.HTTP_401_UNAUTHORIZED
        )



import uuid
import logging

logger = logging.getLogger(__name__)

@api_view(['POST'])
@permission_classes([AllowAny])
def guest_login(request):
    """
    Anonymous guest login
    Returns: 
        - uid: Firebase user ID
        - custom_token: Token to exchange for ID token client-side
        - username: Generated guest username
    """
    try:
        # Create a new anonymous Firebase user
        user = auth.create_user()

        # Set custom claims for the guest user
        auth.set_custom_user_claims(user.uid, {
            'role': 'guest',
            'is_guest': True
        })

        # Create guest data for Firestore
        guest_data = {
            'username': f'guest_{uuid.uuid4().hex[:6]}',
            'is_guest': True,
            'created_at': firestore.SERVER_TIMESTAMP
        }
        db.collection('clients').document(user.uid).set(guest_data)

        # Generate a custom token for client-side authentication
        custom_token = auth.create_custom_token(user.uid)

        return Response({
            'uid': user.uid,
            'custom_token': custom_token.decode('utf-8'),  # Convert bytes to string
            'username': guest_data['username'],
            'is_guest': True
        }, status=status.HTTP_201_CREATED)

    except Exception as e:
        logger.error(f"Guest login failed: {str(e)}", exc_info=True)
        return Response(
            {'error': 'Failed to create guest account'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

#staff

@api_view(['POST'])
@permission_classes([AllowAny])
def staff_login(request):
    """
    Staff login with Firebase token (for servers and chefs only, not managers)
    Expected JSON: {"token": "firebase_id_token"}
    """
    try:
        logger.info("Staff login attempt")
        token = request.data.get('token')
        if not token:
            logger.error("No token provided")
            return Response(
                {'error': 'Token is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Simple token cleaning - just trim whitespace
        token = token.strip()
        
        try:
            # Verify the token directly
            decoded = auth.verify_id_token(token)
            uid = decoded['uid']
            logger.info(f"Token decoded successfully for UID: {uid}")
        except auth.InvalidIdTokenError as e:
            logger.error(f"Invalid ID token: {str(e)}")
            return Response(
                {'error': 'Invalid ID token. Make sure you are using an ID token, not a custom token.'},
                status=status.HTTP_401_UNAUTHORIZED
            )
        except Exception as e:
            logger.error(f"Token verification failed: {str(e)}")
            return Response(
                {'error': f'Token verification failed: {str(e)}'},
                status=status.HTTP_401_UNAUTHORIZED
            )
        
        user = auth.get_user(uid)
        claims = user.custom_claims or {}
        logger.info(f"User claims: {claims}")
        
        # Check if user is a manager - managers should use manager_login
        if claims.get('role') == 'manager':
            logger.error(f"User with UID {uid} is a manager trying to use staff login")
            return Response(
                {'error': 'Managers should use the manager login endpoint'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Check if user is staff (server or chef)
        if claims.get('role') not in ['server', 'chef']:
            logger.error(f"User with UID {uid} is not staff (server or chef)")
            return Response(
                {'error': 'Staff permissions required'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        employes_ref = db.collection('employes').where('firebase_uid', '==', uid).limit(1)
        employes_docs = list(employes_ref.stream())
        logger.info(f"Found employes with UID {uid}: {len(employes_docs)}")
        
        if not employes_docs:
            logger.error(f"No employes record found for UID: {uid}")
            return Response(
                {'error': 'Employee not found', 'uid': uid},
                status=status.HTTP_404_NOT_FOUND
            )
        
        employes = employes_docs[0].to_dict()
        
        # Get role-specific data
        role_id = None
        if claims.get('role') == 'server':
            serveur_ref = db.collection('serveurs').where('idE', '==', employes_docs[0].id).limit(1)
            role_docs = list(serveur_ref.stream())
            if role_docs:
                role_id = role_docs[0].id
        elif claims.get('role') == 'chef':
            cuisinier_ref = db.collection('cuisiniers').where('idE', '==', employes_docs[0].id).limit(1)
            role_docs = list(cuisinier_ref.stream())
            if role_docs:
                role_id = role_docs[0].id
                
        return Response({
            'uid': uid,
            'role': claims.get('role', 'unknown'),
            'first_name': employes.get('prenomE'),
            'last_name': employes.get('nomE'),
            'email': employes.get('emailE'),
            'employee_id': employes_docs[0].id,
            'role_id': role_id
        })
    
    except Exception as e:
        logger.error(f"Staff login failed: {str(e)}")
        return Response(
            {'error': f"Authentication failed: {str(e)}"},
            status=status.HTTP_401_UNAUTHORIZED
        )
#manager

@api_view(['POST'])
@permission_classes([AllowAny])
def manager_signup(request):
    logger.info("Manager signup request received")
    try:
        logger.info(f"Request data: {request.data}")
        required_fields = ['email', 'password', 'first_name', 'last_name']
        if request.data.get('password') != request.data.get('password_confirmation'):
            return Response(
                {'error': 'Password and confirmation must match'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if not all(field in request.data for field in required_fields):
            missing = [f for f in required_fields if f not in request.data]
            logger.error(f"Missing fields: {missing}")
            return Response(
                {'error': f'Missing required fields: {missing}'},
                status=status.HTTP_400_BAD_REQUEST
            )

        logger.info("Creating Firebase user...")
        user = auth.create_user(
            email=request.data['email'],
            password=request.data['password']
        )
        logger.info(f"Firebase user created: {user.uid}")

        logger.info("Setting custom claims...")
        set_custom_claims(user.uid, {
            'role': 'manager',
            'is_guest': False
        })

        logger.info("Creating employee record...")
        employes_data = {
            'prenomE': request.data['first_name'],
            'nomE': request.data['last_name'],
            'usernameE': request.data['email'].split('@')[0],
            'emailE': request.data['email'],
            'numeroE': request.data.get('phone_number', ''),
            'salaire': request.data.get('salaire', 0),
            'role': 'manager',
            'firebase_uid': user.uid,
            'dateEmbauche': firestore.SERVER_TIMESTAMP
        }
        employes_ref = db.collection('employes').document()
        employes_ref.set(employes_data)
        logger.info(f"Employes record created: {employes_ref.id}")

        logger.info("Creating manager record...")
        manager_ref = db.collection('managers').document()
        manager_data = {
            'idE': employes_ref.id,  # Use idE to match schema
            'idRapport': None  # Initialize without a report
        }
        manager_ref.set(manager_data)
        
        # Log details to verify correct data
        logger.info(f"Manager record created with ID: {manager_ref.id}")
        logger.info(f"Manager data: {manager_data}")

        return Response({
            'uid': user.uid,
            'email': user.email,
            'employee_id': employes_ref.id,
            'manager_id': manager_ref.id
        }, status=status.HTTP_201_CREATED)

    except auth.EmailAlreadyExistsError as e:
        logger.error(f"Email already exists: {str(e)}")
        return Response(
            {'error': 'Email already registered'},
            status=status.HTTP_400_BAD_REQUEST
        )
    except Exception as e:
        logger.error(f"Manager signup failed: {str(e)}", exc_info=True)
        return Response(
            {'error': 'Internal server error'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
@api_view(['POST'])
@permission_classes([IsManager])  
def create_employes(request):
    try:
        logger.info(f"Creating employes with data: {request.data}")
        
        # Validation
        required_fields = ['email', 'password', 'first_name', 'last_name', 'role', 'phone_number', 'salary']
        for field in required_fields:
            if field not in request.data:
                return Response(
                    {'error': f'Missing required field: {field}'},
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        role = request.data['role']
        if role not in ['server', 'chef']:
            return Response(
                {'error': 'Invalid role. Must be "server" or "chef". Use manager_signup for manager role.'},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        if not request.user or not request.user.is_authenticated:
            return Response(
                {'error': 'Authentication required'},
                status=status.HTTP_401_UNAUTHORIZED
            )
        
        claims = getattr(request.user, 'claims', {})
        if claims.get('role') != 'manager':
            return Response(
                {'error': 'Manager permissions required'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        user = auth.create_user(
            email=request.data['email'],
            password=request.data['password']
        )
        logger.info(f"Firebase user created with UID: {user.uid}")
        
        auth.set_custom_user_claims(user.uid, {
            'role': role,
            'is_guest': False
        })
        logger.info(f"Custom claims set for UID: {user.uid}")
        
        employes_data = {
            'prenomE': request.data['first_name'],
            'nomE': request.data['last_name'],
            'usernameE': request.data['email'].split('@')[0],
            'emailE': request.data['email'],  # Added missing emailE field
            'numeroE': request.data['phone_number'],  # Added missing numeroE field
            'role': role,
            'adresseE': request.data.get('address', ''),
            'salaire': request.data['salary'],  # Added missing salaire field
            'firebase_uid': user.uid,
            'dateEmbauche': firestore.SERVER_TIMESTAMP
        }
        
        # Create employe
        employes_ref = db.collection('employes').document()
        employes_ref.set(employes_data)
        logger.info(f"Employes record created with ID: {employes_ref.id}")
        
        # Create role record
        if role == 'server':
            # Create server
            serveur_ref = db.collection('serveurs').document()
            serveur_ref.set({
                'idE': employes_ref.id,
                'dateEmbauche': firestore.SERVER_TIMESTAMP
            })
            logger.info(f"Server record created with ID: {serveur_ref.id}")
            role_record_id = serveur_ref.id
        elif role == 'chef':
            # Create chef
            cuisinier_ref = db.collection('cuisiniers').document()
            cuisinier_ref.set({
                'idE': employes_ref.id,
                'dateEmbauche': firestore.SERVER_TIMESTAMP
            })
            logger.info(f"Chef record created with ID: {cuisinier_ref.id}")
            role_record_id = cuisinier_ref.id
        
        # Return success response
        return Response({
            'uid': user.uid,
            'employee_id': employes_ref.id,
            'role': role,
            'role_record_id': role_record_id,
            'message': f'{role.capitalize()} created successfully'
        }, status=status.HTTP_201_CREATED)
    
    except auth.EmailAlreadyExistsError:
        logger.error(f"Email already exists: {request.data.get('email')}")
        return Response(
            {'error': 'Email already registered'},
            status=status.HTTP_400_BAD_REQUEST
        )
    except Exception as e:
        logger.error(f"Employes creation failed: {str(e)}")
        return Response(
            {'error': f"Failed to create employes: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
    
@api_view(['POST'])
@permission_classes([IsManager])
def manager_login(request):
    """
    Manager login with Firebase token
    Expected JSON: {"token": "firebase_id_token"}
    """
    try:
        logger.info("Manager login attempt")
        token = request.data.get('token')
        if not token:
            logger.error("No token provided")
            return Response(
                {'error': 'Token is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        decoded = auth.verify_id_token(token)
        uid = decoded['uid']
        logger.info(f"Token decoded for UID: {uid}")
        
        user = auth.get_user(uid)
        claims = user.custom_claims or {}
        logger.info(f"User claims: {claims}")
        
        if claims.get('role') != 'manager':
            logger.error(f"User with UID {uid} is not a manager")
            return Response(
                {'error': 'Manager permissions required'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        employes_ref = db.collection('employes').where('firebase_uid', '==', uid).limit(1)
        employes_docs = list(employes_ref.stream())
        logger.info(f"Found employees with UID {uid}: {len(employes_docs)}")
        
        if not employes_docs:
            logger.error(f"No employee record found for UID: {uid}")
            return Response(
                {'error': 'Manager not found', 'uid': uid},
                status=status.HTTP_404_NOT_FOUND
            )
        
        employes = employes_docs[0].to_dict()
        
        # Fixed this line - changed 'employes_id' to 'idE'
        manager_ref = db.collection('managers').where('idE', '==', employes_docs[0].id).limit(1)
        manager_docs = list(manager_ref.stream())
        
        if not manager_docs:
            # Enhanced logging to help debug
            logger.error(f"No manager record found for employee ID: {employes_docs[0].id}")
            
            # Let's check what records exist in the managers collection
            all_managers = [doc.to_dict() for doc in db.collection('managers').stream()]
            logger.info(f"All manager records: {all_managers}")
            
            return Response(
                {'error': 'Manager record not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        return Response({
            'uid': uid,
            'role': 'manager',
            'first_name': employes.get('prenomE'),
            'last_name': employes.get('nomE'),
            'email': user.email,
            'employee_id': employes_docs[0].id,
            'manager_id': manager_docs[0].id
        })
    
    except auth.InvalidIdTokenError as e:
        logger.error(f"Invalid token: {str(e)}")
        return Response(
            {'error': 'Invalid authentication token'},
            status=status.HTTP_401_UNAUTHORIZED
        )
    except Exception as e:
        logger.error(f"Manager login failed: {str(e)}")
        return Response(
            {'error': f"Authentication failed: {str(e)}"},
            status=status.HTTP_401_UNAUTHORIZED
        )
#en commun

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_current_user(request):
    """
    Get current authenticated user info
    """
    try:
        if not isinstance(request.user, FirebaseUser):
            return Response(
                {'error': 'Invalid user type'},
                status=status.HTTP_400_BAD_REQUEST
            )

        user_data = {
            'uid': request.user.uid,
            'email': request.user.email,
            'role': request.user.role,
            'is_guest': request.user.is_guest
        }

        
        if request.user.role in ['client', 'guest']:
            client_ref = db.collection('clients').document(request.user.uid)
            client = client_ref.get()
            if client.exists:
                client_data = client.to_dict()
                user_data.update({
                    'username': client_data.get('username'),
                    'fidelity_points': client_data.get('fidelity_points', 0)
                })

        elif request.user.role in ['server', 'chef', 'manager']:
            employes_ref = db.collection('employes').where('firebase_uid', '==', request.user.uid).limit(1)
            employes = [doc.to_dict() for doc in employee_ref.stream()]
            
            if employes:
                employes = employes[0]
                user_data.update({
                    'first_name': employes.get('prenomE'),
                    'last_name': employes.get('nomE'),
                    'employee_id': employes_ref[0].id if employes_ref else None
                })

        return Response(user_data)

    except Exception as e:
        logger.error(f"Failed to get current user: {str(e)}")
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout(request):
    auth.revoke_refresh_tokens(request.user.uid)  
    return Response({'message': 'Logged out successfully'})


