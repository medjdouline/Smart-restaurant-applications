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
from django.conf import settings
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
import firebase_admin
import firebase_admin.auth


logger = logging.getLogger(__name__)
db = firebase_config.get_db()

ALLOWED_PREFERENCES = [
    'Soupes et Potages', 'Salades et Crudités', 'Poissons et Fruits de mer',
    'Cuisine traditionnelle', 'Viandes', 'Sandwichs et burgers', 'Végétariens',
    'Crémes et Mousses', 'Pâtisseries', 'Fruits et Sorbets'
]

ALLOWED_ALLERGIES = [
    'Fraise', 'Fruit exotique', 'Gluten', 'Arachides', 'Noix', 'Lupin',
    'Champignons', 'Moutarde', 'Soja', 'Crustacés', 'Poissons', 'Lactose', 'Oeuf'
]

ALLOWED_RESTRICTIONS = [
    'Végétarien', 'Végétalien', 'Keto', 'Sans lactose', 'Sans gluten'
]

def ensure_utf8_string(text):
    """Fonction pour s'assurer que le texte est correctement encodé en UTF-8"""
    if isinstance(text, str):
        # Si c'est déjà une string, on la renvoie telle quelle
        return text
    elif isinstance(text, bytes):
        # Si c'est des bytes, on les décode en UTF-8
        try:
            return text.decode('utf-8')
        except UnicodeDecodeError:
            # Si le décodage UTF-8 échoue, essayer latin-1 puis encoder en UTF-8
            return text.decode('latin-1').encode('utf-8').decode('utf-8')
    else:
        return str(text)

def clean_list_encoding(items_list):
    """Nettoie une liste de strings pour l'encodage UTF-8"""
    if not isinstance(items_list, list):
        return items_list
    
    cleaned_list = []
    for item in items_list:
        cleaned_item = ensure_utf8_string(item)
        cleaned_list.append(cleaned_item)
    
    return cleaned_list

def validate_and_process_allergies(allergies):
    """Valide et traite les allergies, permettant les nouvelles entrées personnalisées"""
    if not allergies:
        return [], []
    
    processed_allergies = []
    custom_allergies = []
    
    for allergy in allergies:
        allergy_clean = allergy.strip()
        if not allergy_clean:
            continue
            
        # Vérifier si c'est une allergie prédéfinie
        if allergy_clean in ALLOWED_ALLERGIES:
            processed_allergies.append(allergy_clean)
        else:
            # Tentative de correspondance approximative pour les problèmes d'encodage
            found_match = False
            for allowed_allergy in ALLOWED_ALLERGIES:
                # Comparaison insensible aux accents et espaces
                if (allergy_clean.lower().replace('é', 'e').replace('è', 'e') == 
                    allowed_allergy.lower().replace('é', 'e').replace('è', 'e')):
                    found_match = True
                    processed_allergies.append(allowed_allergy)
                    break
            
            if not found_match:
                # C'est une allergie personnalisée
                if len(allergy_clean) > 50:  # Limite de longueur
                    return None, f"L'allergie '{allergy_clean}' est trop longue (max 50 caractères)"
                custom_allergies.append(allergy_clean)
                processed_allergies.append(allergy_clean)
    
    return processed_allergies, custom_allergies

def validate_and_process_restrictions(restrictions):
    """Valide et traite les restrictions alimentaires, permettant les nouvelles entrées personnalisées"""
    if not restrictions:
        return [], []
    
    processed_restrictions = []
    custom_restrictions = []
    
    for restriction in restrictions:
        restriction_clean = restriction.strip()
        if not restriction_clean:
            continue
            
        # Vérifier si c'est une restriction prédéfinie
        if restriction_clean in ALLOWED_RESTRICTIONS:
            processed_restrictions.append(restriction_clean)
        else:
            # Tentative de correspondance approximative pour les problèmes d'encodage
            found_match = False
            for allowed_restriction in ALLOWED_RESTRICTIONS:
                # Comparaison insensible aux accents et espaces
                if (restriction_clean.lower().replace('é', 'e').replace('è', 'e') == 
                    allowed_restriction.lower().replace('é', 'e').replace('è', 'e')):
                    found_match = True
                    processed_restrictions.append(allowed_restriction)
                    break
            
            if not found_match:
                # C'est une restriction personnalisée
                if len(restriction_clean) > 50:  # Limite de longueur
                    return None, f"La restriction '{restriction_clean}' est trop longue (max 50 caractères)"
                custom_restrictions.append(restriction_clean)
                processed_restrictions.append(restriction_clean)
    
    return processed_restrictions, custom_restrictions

@api_view(['POST'])
@permission_classes([AllowAny])
def client_signup_step1(request):
    try:
        # Récupération des données avec nettoyage d'encodage
        email = ensure_utf8_string(request.data.get('email', ''))
        password = ensure_utf8_string(request.data.get('password', ''))
        password_confirmation = ensure_utf8_string(request.data.get('password_confirmation', ''))
        username = ensure_utf8_string(request.data.get('username', ''))
        phone_number = ensure_utf8_string(request.data.get('phone_number', ''))

        if not all([email, password, password_confirmation, username, phone_number]):
            return Response(
                {'error': 'All fields are required'},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        # Check if passwords match
        if password != password_confirmation:
            return Response(
                {'error': 'Passwords do not match'},
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
            'step': 1
        })

        # Temporary claims (not fully authenticated)
        auth.set_custom_user_claims(user.uid, {
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
            {'error': f'Registration failed: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['POST'])
@permission_classes([AllowAny])
def client_signup_step2(request):
    try:
        uid = ensure_utf8_string(request.data.get('uid', ''))
        birthdate = ensure_utf8_string(request.data.get('birthdate', ''))
        gender = ensure_utf8_string(request.data.get('gender', ''))

        if not all([uid, birthdate, gender]):
            return Response(
                {'error': 'All fields are required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check if temp signup exists
        temp_doc = db.collection('temp_signups').document(uid).get()
        if not temp_doc.exists:
            return Response(
                {'error': 'Invalid UID or session expired'},
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

        return Response({
            'uid': uid,
            'message': 'Proceed to Step 3: Allergies'
        })

    except ValueError:
        return Response(
            {'error': 'Invalid birthdate format (YYYY-MM-DD)'},
            status=status.HTTP_400_BAD_REQUEST
        )
    except Exception as e:
        logger.error(f"Signup Step 2 failed: {str(e)}")
        return Response(
            {'error': f'Step 2 failed: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['POST'])
@permission_classes([AllowAny])
def client_signup_step3(request):
    try:
        uid = ensure_utf8_string(request.data.get('uid', ''))
        allergies_raw = request.data.get('allergies', [])
        
        # Nettoie l'encodage des allergies
        allergies = clean_list_encoding(allergies_raw)
        
        # Debug pour voir ce qui est reçu
        logger.info(f"UID reçu: {uid}")
        logger.info(f"Allergies brutes reçues: {allergies_raw}")
        logger.info(f"Allergies nettoyées: {allergies}")

        if not uid:
            return Response(
                {'error': 'UID is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check if temp signup exists
        temp_doc = db.collection('temp_signups').document(uid).get()
        if not temp_doc.exists:
            return Response(
                {'error': 'Invalid UID or session expired'},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        # Valider et traiter les allergies (permet les nouvelles allergies personnalisées)
        processed_allergies, custom_allergies = validate_and_process_allergies(allergies)
        
        if processed_allergies is None:  # Erreur de validation
            return Response(
                {'error': custom_allergies},  # custom_allergies contient le message d'erreur
                status=status.HTTP_400_BAD_REQUEST
            )

        # Sauvegarder les données
        update_data = {
            'allergies': processed_allergies,
            'step': 3
        }
        
        # Si il y a des allergies personnalisées, les sauvegarder séparément pour tracking
        if custom_allergies:
            update_data['custom_allergies'] = custom_allergies
            logger.info(f"Nouvelles allergies personnalisées ajoutées: {custom_allergies}")

        db.collection('temp_signups').document(uid).update(update_data)

        response_data = {
            'uid': uid,
            'message': 'Proceed to Step 4: Dietary Restrictions',
            'processed_allergies': processed_allergies
        }
        
        if custom_allergies:
            response_data['new_allergies_added'] = custom_allergies

        return Response(response_data)

    except Exception as e:
        logger.error(f"Signup Step 3 (Allergies) failed: {str(e)}")
        return Response(
            {'error': f'Step 3 failed: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['POST'])
@permission_classes([AllowAny])
def client_signup_step4(request):
    try:
        uid = ensure_utf8_string(request.data.get('uid', ''))
        restrictions_raw = request.data.get('restrictions', [])
        
        # Nettoie l'encodage des restrictions
        restrictions = clean_list_encoding(restrictions_raw)
        
        # Debug pour voir ce qui est reçu
        logger.info(f"UID reçu: {uid}")
        logger.info(f"Restrictions brutes reçues: {restrictions_raw}")
        logger.info(f"Restrictions nettoyées: {restrictions}")

        if not uid:
            return Response(
                {'error': 'UID is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check if temp signup exists
        temp_doc = db.collection('temp_signups').document(uid).get()
        if not temp_doc.exists:
            return Response(
                {'error': 'Invalid UID or session expired'},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        # Valider et traiter les restrictions (permet les nouvelles restrictions personnalisées)
        processed_restrictions, custom_restrictions = validate_and_process_restrictions(restrictions)
        
        if processed_restrictions is None:  # Erreur de validation
            return Response(
                {'error': custom_restrictions},  # custom_restrictions contient le message d'erreur
                status=status.HTTP_400_BAD_REQUEST
            )

        # Sauvegarder les données
        update_data = {
            'restrictions': processed_restrictions,
            'step': 4
        }
        
        # Si il y a des restrictions personnalisées, les sauvegarder séparément pour tracking
        if custom_restrictions:
            update_data['custom_restrictions'] = custom_restrictions
            logger.info(f"Nouvelles restrictions personnalisées ajoutées: {custom_restrictions}")

        db.collection('temp_signups').document(uid).update(update_data)

        response_data = {
            'uid': uid,
            'message': 'Proceed to Step 5: Preferences',
            'processed_restrictions': processed_restrictions
        }
        
        if custom_restrictions:
            response_data['new_restrictions_added'] = custom_restrictions

        return Response(response_data)

    except Exception as e:
        logger.error(f"Signup Step 4 (Restrictions) failed: {str(e)}")
        return Response(
            {'error': f'Step 4 failed: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['POST'])
@permission_classes([AllowAny])
def client_signup_step5(request):
    try:
        uid = ensure_utf8_string(request.data.get('uid', ''))
        preferences_raw = request.data.get('preferences', [])
        
        # Nettoie l'encodage des préférences
        preferences = clean_list_encoding(preferences_raw)
        
        # Debug pour voir ce qui est reçu
        logger.info(f"UID reçu: {uid}")
        logger.info(f"Préférences brutes reçues: {preferences_raw}")
        logger.info(f"Préférences nettoyées: {preferences}")
        logger.info(f"Préférences autorisées: {ALLOWED_PREFERENCES}")

        if not uid:
            return Response(
                {'error': 'UID is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        if len(preferences) < 1:
            return Response(
                {'error': 'Select at least 1 preference'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check if temp signup exists
        temp_doc = db.collection('temp_signups').document(uid).get()
        if not temp_doc.exists:
            return Response(
                {'error': 'Invalid UID or session expired'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Validate preferences avec correction d'encodage
        invalid_prefs = []
        for preference in preferences:
            # Comparaison stricte ET comparaison sans accents comme fallback
            if preference not in ALLOWED_PREFERENCES:
                # Tentative de correspondance approximative pour les problèmes d'encodage
                found_match = False
                for allowed_pref in ALLOWED_PREFERENCES:
                    # Comparaison insensible aux accents et espaces
                    if (preference.lower().strip().replace('é', 'e').replace('è', 'e').replace('ê', 'e') == 
                        allowed_pref.lower().strip().replace('é', 'e').replace('è', 'e').replace('ê', 'e')):
                        found_match = True
                        # Remplace par la version correcte
                        preferences[preferences.index(preference)] = allowed_pref
                        break
                
                if not found_match:
                    invalid_prefs.append(preference)
        
        if invalid_prefs:
            return Response(
                {
                    'error': f'Invalid preferences: {", ".join(invalid_prefs)}',
                    'received_preferences': preferences,
                    'allowed_preferences': ALLOWED_PREFERENCES
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # Récupérer les données temporaires
        temp_data = temp_doc.to_dict()
        if not temp_data:
            return Response(
                {'error': 'Temporary data not found'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Créer le document final
        client_data = {
            'username': temp_data['username'],
            'email': temp_data['email'],
            'phone_number': temp_data['phone_number'],
            'birthdate': temp_data['birthdate'],
            'gender': temp_data['gender'],
            'preferences': preferences,
            'allergies': temp_data.get('allergies', []),
            'restrictions': temp_data.get('restrictions', []),
            'is_guest': False,
            'fidelity_points': 0,
            'created_at': firestore.SERVER_TIMESTAMP
        }

        db.collection('clients').document(uid).set(client_data)
        db.collection('temp_signups').document(uid).delete()

        # Marquer l'utilisateur comme vérifié
        auth.set_custom_user_claims(uid, {
            'role': 'client',
            'signup_complete': True
        })

        # Générer un ID token directement
        # 1. Créer un custom token
        custom_token = auth.create_custom_token(uid)
        
        # 2. Échanger contre un ID token via l'API Firebase
        import requests
        API_KEY = "AIzaSyAYqym7Dcr1k_VhyP54L8mxpzT7QctiCQ8"  # À récupérer dans les paramètres du projet Firebase
        
        response = requests.post(
            f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key={API_KEY}",
            json={
                'token': custom_token.decode('utf-8'),
                'returnSecureToken': True
            }
        )
        
        if response.status_code != 200:
            raise Exception("Failed to get ID token")
            
        id_token = response.json().get('idToken')
        refresh_token = response.json().get('refreshToken')

        return Response({
            'message': 'Account created successfully',
            'id_token': id_token,
            'refresh_token': refresh_token,
            'uid': uid
        }, status=status.HTTP_201_CREATED)

    except Exception as e:
        logger.error(f"Signup Step 5 (Preferences) failed: {str(e)}")
        return Response(
            {'error': f'Step 5 failed: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
    
@api_view(['POST'])
@permission_classes([AllowAny])
def client_login(request):
    import traceback
    import sys
    
    try:
        # Log toutes les données reçues (sanitize les mots de passe dans un environnement réel)
        print("Received data:", request.data)
        
        identifier = request.data.get('identifier')
        password = request.data.get('password')

        if not identifier or not password:
            return Response(
                {'success': False, 'error': 'Identifier and password required'},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        # Log avant les opérations Firebase
        print("Starting Firebase operations")
            
        # Test basique de connexion à Firebase
        try:
            # Test si db est initialisé
            print("Testing Firestore connection")
            clients_ref = db.collection('clients').limit(1).stream()
            print("Firestore connection successful")
            
            # Test si auth est initialisé
            print("Testing Firebase Auth connection")
            list_users = auth.list_users(max_results=1)
            print("Firebase Auth connection successful")
        except Exception as conn_error:
            print(f"Firebase connection test failed: {str(conn_error)}")
            traceback.print_exc(file=sys.stdout)
            return Response(
                {'success': False, 'error': f'Firebase connection error: {str(conn_error)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

        print("Attempting to find user")
        # Find user by email or username
        user = None
        if '@' in identifier:
            try:
                user = auth.get_user_by_email(identifier)
                print(f"Found user by email: {user.uid}")
            except auth.UserNotFoundError:
                print("User not found by email")
                pass
        else:
            print("Looking up user by username in Firestore")
            clients_ref = db.collection('clients')
            query = clients_ref.where('username', '==', identifier).limit(1)
            docs = query.stream()
            try:
                doc = next(docs)
                print(f"Found user document with ID: {doc.id}")
                user = auth.get_user(doc.id)
                print(f"Found user in Auth: {user.uid}")
            except StopIteration:
                print("User not found by username")
                pass
            except Exception as lookup_error:
                print(f"Error looking up user: {str(lookup_error)}")
                traceback.print_exc(file=sys.stdout)

        if not user:
            return Response(
                {'success': False, 'error': 'Invalid credentials'},
                status=status.HTTP_401_UNAUTHORIZED
            )

        # Check signup completion
        print("Checking user claims")
        claims = auth.get_user(user.uid).custom_claims or {}
        if not claims.get('signup_complete'):
            return Response(
                {'success': False, 'error': 'Complete signup first'},
                status=status.HTTP_403_FORBIDDEN
            )

        # Authentification directe avec Firebase Auth REST API pour obtenir un ID token
        print("Authenticating with Firebase REST API")
        import requests
        
        try:
            # Utiliser l'API REST Firebase Auth pour obtenir directement un ID token
            API_KEY = "AIzaSyAYqym7Dcr1k_VhyP54L8mxpzT7QctiCQ8"  # À récupérer dans les paramètres du projet Firebase
            
            response = requests.post(
                f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={API_KEY}",
                json={
                    "email": user.email,
                    "password": password,
                    "returnSecureToken": True
                }
            )
            
            print(f"Firebase Auth API response: {response.status_code}")
            if response.status_code != 200:
                print(f"Auth response error: {response.text}")
                return Response(
                    {'success': False, 'error': 'Invalid credentials'},
                    status=status.HTTP_401_UNAUTHORIZED
                )
                
            # Récupérer l'ID token et le refresh token de la réponse
            auth_data = response.json()
            id_token = auth_data.get('idToken')
            refresh_token = auth_data.get('refreshToken')
                
        except Exception as auth_error:
            print(f"Authentication error: {str(auth_error)}")
            traceback.print_exc(file=sys.stdout)
            return Response(
                {'success': False, 'error': f'Authentication error: {str(auth_error)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

        return Response({
            'success': True,
            'id_token': id_token,
            'refresh_token': refresh_token,
            'uid': user.uid
        })

    except Exception as e:
        print(f"Unexpected error in client_login: {str(e)}")
        traceback.print_exc(file=sys.stdout)
        return Response(
            {'success': False, 'error': f'Login failed: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
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
    Staff login with email/username and password (for servers and chefs only)
    Expected JSON: {"email": "user@example.com", "password": "mypassword"} or {"username": "username", "password": "mypassword"}
    Returns: User data + Firebase ID token
    """
    try:
        logger.info("Staff login attempt")
        
        # Get credentials from request
        email = request.data.get('email')
        username = request.data.get('username')
        password = request.data.get('password')
        
        if not password:
            return Response(
                {'error': 'Password is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        if not (email or username):
            return Response(
                {'error': 'Email or username is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Configuration Firebase pour l'API REST
        FIREBASE_API_KEY = settings.FIREBASE_API_KEY
        
        # Tentative d'authentification directe avec Firebase REST API
        try:
            import requests
            
            # Si un email est fourni, essayez de l'utiliser directement
            auth_email = email
            
            # Si seulement un username est fourni, essayez de trouver l'email correspondant
            if not auth_email and username:
                # Recherchez l'utilisateur dans Firestore
                users_ref = db.collection('employes').where('username', '==', username).limit(1)
                user_docs = list(users_ref.stream())
                if user_docs:
                    user_data = user_docs[0].to_dict()
                    auth_email = user_data.get('email')
            
            if not auth_email:
                logger.error("No valid email found for authentication")
                return Response(
                    {'error': 'Invalid credentials'},
                    status=status.HTTP_401_UNAUTHORIZED
                )
            
            # Tentative d'authentification avec Firebase
            logger.info(f"Attempting Firebase authentication for email: {auth_email}")
            auth_response = requests.post(
                f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={FIREBASE_API_KEY}",
                json={
                    "email": auth_email,
                    "password": password,
                    "returnSecureToken": True
                }
            )
            
            # Vérification de la réponse de Firebase
            if auth_response.status_code != 200:
                logger.error(f"Firebase auth failed with status {auth_response.status_code}: {auth_response.text}")
                return Response(
                    {'error': 'Invalid credentials'},
                    status=status.HTTP_401_UNAUTHORIZED
                )
            
            # Extraction des données d'authentification
            auth_data = auth_response.json()
            token = auth_data['idToken']
            uid = auth_data['localId']
            
            # Vérification du jeton pour obtenir les claims
            decoded_token = firebase_admin.auth.verify_id_token(token)
            claims = decoded_token.get('claims', {})
            
            # Si claims est vide, récupérez les claims depuis l'utilisateur Firebase
            if not claims or claims == {}:
                user = firebase_admin.auth.get_user(uid)
                claims = user.custom_claims or {}
            
            # Vérification du rôle
            role = claims.get('role')
            if role == 'manager':
                logger.error(f"Manager attempting staff login: {uid}")
                return Response(
                    {'error': 'Managers must use manager login'},
                    status=status.HTTP_403_FORBIDDEN
                )
                
            if role not in ['server', 'chef']:
                logger.error(f"User is not staff: {uid}, role: {role}")
                return Response(
                    {'error': 'Staff permissions required. Current role: ' + (role or 'none')},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Récupération des données employé depuis Firestore
            employes_ref = db.collection('employes').where('firebase_uid', '==', uid).limit(1)
            employes_docs = list(employes_ref.stream())
            
            if not employes_docs:
                logger.error(f"No employee record found for uid: {uid}")
                return Response(
                    {'error': 'Employee record not found in database'},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Récupération des données de l'employé
            employe_doc = employes_docs[0]
            employe_id = employe_doc.id
            employe_data = employe_doc.to_dict()
            
            # Récupération des données spécifiques au rôle
            role_id = None
            if role == 'server':
                serveur_ref = db.collection('serveurs').where('idE', '==', employe_id).limit(1)
                role_docs = list(serveur_ref.stream())
                if role_docs:
                    role_id = role_docs[0].id
            elif role == 'chef':
                cuisinier_ref = db.collection('cuisiniers').where('idE', '==', employe_id).limit(1)
                role_docs = list(cuisinier_ref.stream())
                if role_docs:
                    role_id = role_docs[0].id
            
            # Préparation de la réponse
            response_data = {
                'uid': uid,
                'role': role,
                'first_name': employe_data.get('prenomE'),
                'last_name': employe_data.get('nomE'),
                'email': auth_email,
                'employee_id': employe_id,
                'role_id': role_id,
                'token': token
            }
            
            return Response(response_data)
            
        except requests.RequestException as e:
            logger.error(f"Firebase API request failed: {str(e)}")
            return Response(
                {'error': 'Authentication service unavailable', 'details': str(e)},
                status=status.HTTP_503_SERVICE_UNAVAILABLE
            )
        except firebase_admin.auth.InvalidIdTokenError as e:
            logger.error(f"Invalid Firebase token: {str(e)}")
            return Response(
                {'error': 'Invalid authentication token'},
                status=status.HTTP_401_UNAUTHORIZED
            )
        except Exception as e:
            logger.error(f"Authentication process failed: {str(e)}")
            return Response(
                {'error': 'Authentication failed', 'details': str(e)},
                status=status.HTTP_401_UNAUTHORIZED
            )
            
    except Exception as e:
        logger.error(f"Staff login failed with unexpected error: {str(e)}")
        return Response(
            {'error': 'Login failed due to server error', 'details': str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
#manager

@api_view(['POST'])
@permission_classes([AllowAny])
def manager_signup(request):
    logger.info("Manager signup request received")
    try:
        logger.info(f"Request data: {request.data}")
        required_fields = ['email', 'password', 'password_confirmation', 'first_name', 'last_name', 'username']
        
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

        # Generate custom token and ID token
        logger.info("Generating custom token...")
        custom_token = auth.create_custom_token(user.uid)
        logger.info("Custom token generated successfully")

        logger.info("Creating employee record...")
        employes_data = {
            'prenomE': request.data['first_name'],
            'nomE': request.data['last_name'],
            'usernameE': request.data['username'],
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
            'idE': employes_ref.id,
            'idRapport': None
        }
        manager_ref.set(manager_data)
        
        logger.info(f"Manager record created with ID: {manager_ref.id}")
        logger.info(f"Manager data: {manager_data}")

        return Response({
            'uid': user.uid,
            'email': user.email,
            'employee_id': employes_ref.id,
            'manager_id': manager_ref.id,
            'custom_token': custom_token.decode('utf-8'),  # Convert bytes to string
            'message': 'Manager account created successfully. Use the custom_token to authenticate on the client side.'
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
@permission_classes([AllowAny])  # Change this from IsManager since we're authenticating
def manager_login(request):
    """
    Manager login with email and password
    Expected JSON: {"email": "manager@example.com", "password": "password"}
    """
    try:
        logger.info("Manager login attempt")
        email = request.data.get('email')
        password = request.data.get('password')
        
        if not email or not password:
            logger.error("Email or password not provided")
            return Response(
                {'error': 'Email and password are required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Authenticate with Firebase using email/password
        try:
            user = auth.get_user_by_email(email)
            # Note: Firebase Admin SDK can't sign in with password
            # We'll need to use a custom token or call Firebase Auth REST API
            # For this example, we'll use a workaround
            
            # Option 1: Use Firebase Auth REST API (in production)
            # import requests
            # response = requests.post(
            #     'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword',
            #     params={'key': 'your-web-api-key'},
            #     json={'email': email, 'password': password, 'returnSecureToken': True}
            # )
            # if response.status_code != 200:
            #     return Response({'error': 'Invalid credentials'}, status=status.HTTP_401_UNAUTHORIZED)
            # firebase_user = response.json()
            # uid = firebase_user['localId']
            
            # Option 2: For development, just get user by email and assume password is correct
            uid = user.uid
            
            # Check if user is a manager
            claims = user.custom_claims or {}
            logger.info(f"User claims: {claims}")
            
            if claims.get('role') != 'manager':
                logger.error(f"User with UID {uid} is not a manager")
                return Response(
                    {'error': 'Manager permissions required'},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Get employee details
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
            
            # Get manager details
            manager_ref = db.collection('managers').where('idE', '==', employes_docs[0].id).limit(1)
            manager_docs = list(manager_ref.stream())
            
            if not manager_docs:
                logger.error(f"No manager record found for employee ID: {employes_docs[0].id}")
                return Response(
                    {'error': 'Manager record not found'},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Create a custom token that the client can use
            custom_token = auth.create_custom_token(uid)
            
            return Response({
                'uid': uid,
                'token': custom_token.decode('utf-8'),  # Include this token for the frontend
                'role': 'manager',
                'first_name': employes.get('prenomE'),
                'last_name': employes.get('nomE'),
                'email': user.email,
                'employee_id': employes_docs[0].id,
                'manager_id': manager_docs[0].id
            })
            
        except auth.UserNotFoundError:
            logger.error(f"No user found with email: {email}")
            return Response(
                {'error': 'Invalid email or password'},
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


