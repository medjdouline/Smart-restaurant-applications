from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from datetime import datetime
from firebase_admin import auth, firestore
from .firebase_utils import firebase_config
from .authentication import FirebaseUser, get_firebase_user, set_custom_claims
from .permissions import IsClient, IsGuest, IsStaff, IsManager
import logging
import uuid

logger = logging.getLogger(__name__)
db = firebase_config.get_db()

#client

@api_view(['POST'])
@permission_classes([AllowAny])
def client_login(request):
    """
    Client login with Firebase token
    Expected JSON: {"token": "firebase_id_token"}
    """
    try:
        token = request.data.get('token')
        if not token:
            return Response(
                {'error': 'Token is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

       
        decoded = auth.verify_id_token(token)
        uid = decoded['uid']

        
        client_ref = db.collection('clients').document(uid)
        client = client_ref.get()

        if not client.exists:
            return Response(
                {'error': 'Client not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        client_data = client.to_dict()
        return Response({
            'uid': uid,
            'username': client_data.get('username'),
            'email': client_data.get('email'),
            'is_guest': client_data.get('is_guest', False)
        })

    except Exception as e:
        logger.error(f"Client login failed: {str(e)}")
        return Response(
            {'error': str(e)},
            status=status.HTTP_401_UNAUTHORIZED
        )

@api_view(['POST'])
@permission_classes([AllowAny])
def client_signup(request):
    """
    Client registration
    Expected JSON: {
        "email": "user@example.com",
        "password": "securepassword",
        "username": "username",
        "birthdate": "2000-01-01"  
    }
    """
    try:
        email = request.data.get('email')
        password = request.data.get('password')
        username = request.data.get('username')
        birthdate = request.data.get('birthdate') 

        
        if not all([email, password, username, birthdate]):  
            return Response(
                {'error': 'Email, password, username and birthdate are required'},  
                status=status.HTTP_400_BAD_REQUEST
            )

        # Validate birthdate format and age (13+)
        try:
            birthdate_dt = datetime.strptime(birthdate, '%Y-%m-%d').date()
            if (datetime.now().date() - birthdate_dt).days < 13 * 365:  
                return Response(
                    {'error': 'You must be at least 13 years old'},
                    status=status.HTTP_403_FORBIDDEN
                )
        except ValueError:
            return Response(
                {'error': 'Invalid birthdate format (use YYYY-MM-DD)'},
                status=status.HTTP_400_BAD_REQUEST
            )

        
        user = auth.create_user(
            email=email,
            password=password,
            display_name=username
        )

        
        set_custom_claims(user.uid, {
            'role': 'client',
            'is_guest': False,
            'birthdate': birthdate  
        })

        
        client_data = {
            'username': username,
            'email': email,
            'is_guest': False,
            'fidelity_points': 0,
            'created_at': firestore.SERVER_TIMESTAMP,
            'birthdate': birthdate  
        }
        db.collection('clients').document(user.uid).set(client_data)

        return Response({
            'uid': user.uid,
            'email': user.email,
            'username': username,
            'birthdate': birthdate  
        }, status=status.HTTP_201_CREATED)

    except auth.EmailAlreadyExistsError:
        return Response(
            {'error': 'Email already registered'},
            status=status.HTTP_400_BAD_REQUEST
        )
    except Exception as e:
        logger.error(f"Client signup failed: {str(e)}")
        return Response(
            {'error': 'Registration failed'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['POST'])
@permission_classes([AllowAny])
def guest_login(request):
    """
    Anonymous guest login
    Returns: Guest user credentials
    """
    try:
        
        user = auth.create_user()

       
        set_custom_claims(user.uid, {
            'role': 'guest',
            'is_guest': True
        })

       
        guest_data = {
            'username': f'guest_{uuid.uuid4().hex[:6]}',
            'is_guest': True,
            'created_at': firestore.SERVER_TIMESTAMP
        }
        db.collection('clients').document(user.uid).set(guest_data)

        return Response({
            'uid': user.uid,
            'is_guest': True,
            'username': guest_data['username']
        }, status=status.HTTP_201_CREATED)

    except Exception as e:
        logger.error(f"Guest login failed: {str(e)}")
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

#staff

@api_view(['POST'])
@permission_classes([AllowAny])
def staff_login(request):
    """
    Staff login with Firebase token
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
        
        
        decoded = auth.verify_id_token(token)
        uid = decoded['uid']
        logger.info(f"Token decoded for UID: {uid}")
        
       
        user = auth.get_user(uid)
        claims = user.custom_claims or {}
        logger.info(f"User claims: {claims}")
        
        
        all_employees = [doc.to_dict() for doc in db.collection('employes').stream()]
        logger.info(f"All employes in database: {all_employees}")
        
       
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
        return Response({
            'uid': uid,
            'role': claims.get('role', 'unknown'),
            'first_name': employes.get('prenomE'),
            'last_name': employes.get('nomE'),
            'email': user.email
        })
    
    except auth.InvalidIdTokenError as e:
        logger.error(f"Invalid token: {str(e)}")
        return Response(
            {'error': 'Invalid authentication token'},
            status=status.HTTP_401_UNAUTHORIZED
        )
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
            'role': 'manager',
            'firebase_uid': user.uid,
            'dateEmbauche': firestore.SERVER_TIMESTAMP
        }
        employes_ref = db.collection('employes').document()
        employes_ref.set(employes_data)
        logger.info(f"Employes record created: {employes_ref.id}")

        logger.info("Creating manager record...")
        db.collection('managers').document().set({
            'employes_id': employes_ref.id
        })

        return Response({
            'uid': user.uid,
            'email': user.email,
            'employee_id': employes_ref.id
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
        required_fields = ['email', 'password', 'first_name', 'last_name', 'role']
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
            'role': role,
             'adresseE': request.data.get('address') , 
            'firebase_uid': user.uid,  
            'dateEmbauche': firestore.SERVER_TIMESTAMP
        }
        
        # create employe
        employes_ref = db.collection('employes').document()
        employes_ref.set(employes_data)
        logger.info(f"Employes record created with ID: {employes_ref.id}")
        
        # Create role record
        role_data = {
            'idE': employes_ref.id,
            'dateEmbauche': firestore.SERVER_TIMESTAMP
        }
        
        if role == 'server':
            # Create server
            serveur_ref = db.collection('serveurs').document()
            serveur_ref.set(role_data)
            logger.info(f"Server record created with ID: {serveur_ref.id}")
            role_record_id = serveur_ref.id
        elif role == 'chef':
            # Create chef
            cuisinier_ref = db.collection('cuisiniers').document()
            cuisinier_ref.set(role_data)
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
    # Add to views.py

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
        
        
        manager_ref = db.collection('managers').where('employes_id', '==', employes_docs[0].id).limit(1)
        manager_docs = list(manager_ref.stream())
        
        if not manager_docs:
            logger.error(f"No manager record found for employee ID: {employes_docs[0].id}")
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


