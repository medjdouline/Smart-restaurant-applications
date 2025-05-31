#client_table/views.py
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from core.permissions import IsClient, IsGuest, IsTableClient
from core.firebase_crud import firebase_crud
from firebase_admin import firestore
from firebase_admin import firestore
import logging
from django.utils import timezone
from datetime import datetime
from firebase_admin import auth  # Add this import at the top
from core.firebase_crud import firebase_crud
import logging


logger = logging.getLogger(__name__)

# ==================
# Profile Endpoints
# ==================

@api_view(['GET'])
@permission_classes([IsClient])
def view_client_profile(request):
    """Get client profile information"""
    try:
        client_id = request.user.uid
        client_data = firebase_crud.get_doc('clients', client_id)
        
        if not client_data:
            return Response({'error': 'Client profile not found'}, status=status.HTTP_404_NOT_FOUND)
            
        # Filter sensitive information
        profile = {
            'username': client_data.get('username', ''),
            'email': client_data.get('email', ''),
            'birthdate': client_data.get('birthdate', ''),
            'gender': client_data.get('gender', ''),
            'phone_number' : client_data.get('phone_number',''),
            'fidelityPoints': client_data.get('fidelityPoints', 0),
            'preferences': client_data.get('preferences', []),
            'allergies': client_data.get('allergies', []),
            'restrictions': client_data.get('restrictions', [])
        }
        
        return Response(profile)
    except Exception as e:
        logger.error(f"Error getting client profile: {str(e)}")
        return Response({'error': 'Failed to retrieve profile'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['PUT'])
@permission_classes([IsClient])
def update_client_profile(request):
    try:
        client_id = request.user.uid
        update_data = {}

        # Normalise les noms de champs
        if 'phoneNumber' in request.data:
            update_data['phone_number'] = request.data['phoneNumber']
        elif 'phone_number' in request.data:
            update_data['phone_number'] = request.data['phone_number']

        if not update_data:
            return Response({'error': 'No valid fields to update'}, status=400)
            
        firebase_crud.update_doc('clients', client_id, update_data)
        return Response({'message': 'Profile updated successfully'})
    except Exception as e:
        return Response({'error': str(e)}, status=500)

# ==================
# Orders Endpoints
# ==================


# 1. Django View Fix - Add proper encoding handling
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_orders_history(request):
    """
    Get order history for the authenticated client
    URL: /api/table/orders/
    """
    try:
        # Get the client's UID
        if hasattr(request.user, 'uid'):
            client_id = request.user.uid
        elif hasattr(request.user, 'firebase_uid'):
            client_id = request.user.firebase_uid
        else:
            client_id = str(request.user.pk)
            
        logger.info(f"Using client_id: {client_id}")
        
        # Query Firebase for orders belonging to this client
        orders = firebase_crud.query_collection('commandes', 'idC', '==', client_id)
        logger.info(f"Found {len(orders)} orders for client {client_id}")
        
        order_history = []
        for order in orders:
            order_id = order.get('id') if isinstance(order, dict) else getattr(order, 'id', None)
            
            # Get order items from commandes_plat collection
            order_items_query = firebase_crud.query_collection('commandes_plat', 'idCmd', '==', order_id)
            
            items = []
            for item_data in order_items_query:
                # Get dish details from plats collection
                plat_id = item_data.get('idP')
                plat_details = firebase_crud.get_doc('plats', plat_id)
                
                if plat_details:
                    # FIX: Clean up the dish name encoding
                    dish_name = plat_details.get('nom', 'Plat inconnu')
                    # Handle common encoding issues
                    dish_name = dish_name.replace('â', "'")  # Fix corrupted apostrophe
                    dish_name = dish_name.replace('Ã¢', "'")  # Another encoding variant
                    dish_name = dish_name.replace('â€™', "'")  # UTF-8 encoding issue
                    
                    items.append({
                        'id': plat_id,
                        'nom': dish_name,
                        'prix': float(plat_details.get('prix', 0)),
                        'quantite': int(item_data.get('quantité', 1)),
                        'pointsFidelite': 0
                    })
            
            # Process each order
            order_data = {
                'id': order_id,
                'date': order.get('dateCreation', datetime.now().isoformat()),
                'montant': float(order.get('montant', 0)),
                'etat': order.get('etat', 'en_attente'),
                'confirmation': order.get('confirmation', False),
                'items': items,
                'reductionAppliquee': False,
                'montantReduction': 0,
                'pointsUtilises': 0,
                'firebaseOrderId': order_id,
                'djangoOrderId': order.get('djangoOrderId'),
            }
            
            order_history.append(order_data)
            
        # Sort by date descending
        try:
            order_history.sort(key=lambda x: datetime.fromisoformat(x['date'].replace('Z', '+00:00')), reverse=True)
        except:
            order_history.reverse()
        
        logger.info(f"Returning {len(order_history)} orders")
        return Response(order_history, status=200)
        
    except Exception as e:
        logger.error(f"Error in get_orders_history: {str(e)}")
        return Response({'error': str(e)}, status=500)


# 2. Alternative: Create a utility function for text cleaning
def clean_text_encoding(text):
    """Clean common encoding issues in text"""
    if not text:
        return text
    
    # Common encoding fixes
    replacements = {
        'â': "'",           # Most common apostrophe corruption
        'Ã¢': "'",          # UTF-8 double encoding
        'â€™': "'",         # Smart quote corruption
        'Ã©': 'é',          # e with accent
        'Ã¨': 'è',          # e with grave accent
        'Ã ': 'à',          # a with grave accent
        'Ã§': 'ç',          # c with cedilla
        'â€œ': '"',         # Opening quote
        'â€': '"',          # Closing quote
        'â€"': '—',         # Em dash
        'â€"': '–',         # En dash
    }
    
    cleaned_text = text
    for corrupted, correct in replacements.items():
        cleaned_text = cleaned_text.replace(corrupted, correct)
    
    return cleaned_text



# File encoding
FILE_CHARSET = 'utf-8'
DEFAULT_CHARSET = 'utf-8'

# Locale settings
USE_I18N = True
USE_L10N = True
USE_TZ = True
    
@api_view(['GET'])
@permission_classes([IsClient])
def get_order_details(request, order_id):
    """Get detailed information for a specific order"""
    try:
        client_id = request.user.uid
        
        # Get order document
        order = firebase_crud.get_doc('commandes', order_id)
        if not order or order.get('idC') != client_id:
            return Response({'error': 'Order not found'}, status=status.HTTP_404_NOT_FOUND)
        
        # Get order items from commande_plat collection
        order_items = firebase_crud.query_collection(
            'commande_plat',
            'idCmd',
            '==',
            order_id
        )
        
        # Get details for each item
        items_details = []
        total = 0
        
        for item in order_items:
            plat_id = item.get('idP')
            plat = firebase_crud.get_doc('plats', plat_id)
            
            if plat:
                quantity = item.get('quantité', 1)
                price = plat.get('prix', 0)
                item_total = quantity * price
                
                items_details.append({
                    'plat_id': plat_id,
                    'nom': plat.get('nom', ''),
                    'prix': price,
                    'quantity': quantity,
                    'total': item_total
                })
                
                total += item_total
        
        # Compile complete order details
        order_details = {
            'id': order_id,
            'date': order.get('dateCreation', ''),
            'etat': order.get('etat', ''),
            'items': items_details,
            'total': total,
            'confirmation': order.get('confirmation', False)
        }
        
        return Response(order_details)
    except Exception as e:
        logger.error(f"Error getting order details: {str(e)}")
        return Response({'error': 'Failed to retrieve order details'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['DELETE'])
@permission_classes([IsClient])
def delete_order_history(request, order_id):
    """Remove an order from client's history"""
    try:
        client_id = request.user.uid
        
        # Check if order exists and belongs to this client
        order = firebase_crud.get_doc('commandes', order_id)
        if not order or order.get('idC') != client_id:
            return Response({'error': 'Order not found'}, status=status.HTTP_404_NOT_FOUND)
        
        # We don't actually delete the order, just mark it as hidden from history
        firebase_crud.update_doc('commandes', order_id, {'hidden_from_history': True})
        
        return Response({'message': 'Order removed from history'})
    except Exception as e:
        logger.error(f"Error deleting order from history: {str(e)}")
        return Response({'error': 'Failed to delete order'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# ==================
# Favorites Endpoints
# ==================
@api_view(['POST'])
@permission_classes([AllowAny])
def create_assistance_request(request):
    """Create a new assistance request for both authenticated and guest clients"""
    try:
        # Validate required fields
        if 'table_id' not in request.data:
            return Response({'error': 'Table ID is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        table_id = request.data['table_id']
        user_type = request.data.get('user_type', 'registered')
        
        # Check if table exists
        table = firebase_crud.get_doc('tables', table_id)
        if not table:
            return Response({'error': 'Table not found'}, status=status.HTTP_404_NOT_FOUND)
        
        # Handle different user types
        if user_type == 'guest':
            # For guest users
            guest_name = request.data.get('guest_name', 'Guest User')
            
            assistance_data = {
                'idC': None,  # No client ID for guests
                'guestName': guest_name,
                'userType': 'guest',
                'idTable': table_id,
                'etat': 'non traitee',
                'createdAt': firestore.SERVER_TIMESTAMP
            }
            
            logger.info(f"Creating assistance request for guest: {guest_name} at table {table_id}")
            
        else:
            # For authenticated users
            if not hasattr(request.user, 'uid') or not request.user.uid:
                return Response({'error': 'Authentication required for registered users'}, 
                              status=status.HTTP_401_UNAUTHORIZED)
            
            client_id = request.user.uid
            
            assistance_data = {
                'idC': client_id,
                'guestName': None,
                'userType': 'registered',
                'idTable': table_id,
                'etat': 'non traitee',
                'createdAt': firestore.SERVER_TIMESTAMP
            }
            
            logger.info(f"Creating assistance request for client {client_id} at table {table_id}")
        
        # Create assistance request in Firestore
        assistance_id = firebase_crud.create_doc('demandeAssistance', assistance_data)
        
        logger.info(f"Assistance request created successfully with ID: {assistance_id}")
        
        return Response({
            'id': assistance_id,
            'message': 'Assistance request created successfully',
            'user_type': user_type
        }, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        logger.error(f"Error creating assistance request: {str(e)}")
        return Response({
            'error': 'Failed to create assistance request',
            'details': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsClient])
def get_favorites(request):
    """Get client's favorite dishes"""
    try:
        client_id = request.user.uid
        
        # Query favoris collection for this client
        favoris_docs = firebase_crud.query_collection('favoris', 'client_id', '==', client_id)
        
        # Get details for each favorite dish
        favorite_dishes = []
        for favoris_doc in favoris_docs:
            plat_id = favoris_doc.get('plat_id')
            if plat_id:
                plat = firebase_crud.get_doc('plats', plat_id)
                if plat:
                    favorite_dishes.append({
                        'id': plat_id,
                        'favoris_id': favoris_doc.get('id'),  # Include favoris document ID for deletion
                        'nom': plat.get('nom', ''),
                        'description': plat.get('description', ''),
                        'prix': plat.get('prix', 0),
                        'note': plat.get('note', 0),
                        'ingredients': plat.get('ingredients', ''),  # Add ingredients field
                        'pointsFidelite': plat.get('pointsFidelite', 0)  # Add loyalty points if available
                    })
        
        return Response(favorite_dishes)
    except Exception as e:
        logger.error(f"Error getting favorites: {str(e)}")
        return Response({'error': 'Failed to retrieve favorites'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([IsClient])
def add_favorite(request, plat_id):
    """Add a dish to client's favorites"""
    try:
        client_id = request.user.uid
        
        # Check if dish exists
        plat = firebase_crud.get_doc('plats', plat_id)
        if not plat:
            return Response({'error': 'Dish not found'}, status=status.HTTP_404_NOT_FOUND)
        
        # Check if already in favorites using the additional where parameters
        existing_favoris = firebase_crud.query_collection(
            'favoris', 
            'client_id', '==', client_id,
            where_field='plat_id', 
            where_op='==', 
            where_value=plat_id
        )
        
        if existing_favoris:
            return Response({'message': 'Dish already in favorites'})
        
        # Add to favoris collection
        favoris_data = {
            'client_id': client_id,
            'plat_id': plat_id,
            'created_at': firestore.SERVER_TIMESTAMP
        }
        
        favoris_id = firebase_crud.create_doc('favoris', favoris_data)
        
        return Response({
            'message': 'Dish added to favorites',
            'favoris_id': favoris_id
        }, status=status.HTTP_201_CREATED)
    except Exception as e:
        logger.error(f"Error adding favorite: {str(e)}")
        return Response({'error': 'Failed to add favorite'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['DELETE'])
@permission_classes([IsClient])
def remove_favorite(request, plat_id):
    """Remove a dish from client's favorites"""
    try:
        client_id = request.user.uid
        
        # Find the favoris document to delete using the additional where parameters
        favoris_docs = firebase_crud.query_collection(
            'favoris', 
            'client_id', '==', client_id,
            where_field='plat_id', 
            where_op='==', 
            where_value=plat_id
        )
        
        if not favoris_docs:
            return Response({'error': 'Dish not in favorites'}, status=status.HTTP_404_NOT_FOUND)
        
        # Delete the favoris document (should only be one)
        favoris_doc = favoris_docs[0]
        favoris_id = favoris_doc.get('id')
        
        firebase_crud.delete_doc('favoris', favoris_id)
        
        return Response({'message': 'Dish removed from favorites'}, status=status.HTTP_204_NO_CONTENT)
    except Exception as e:
        logger.error(f"Error removing favorite: {str(e)}")
        return Response({'error': 'Failed to remove favorite'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ==================
# Menu Endpoints
# ==================



@api_view(['GET'])
@permission_classes([AllowAny])
def get_new_plats(request):
    print("=== get_new_plats function called ===")
    """
    Get all plats with isNew attribute set to true
    Returns:
        - List of plats where isNew = true
        - Empty list if no new plats found
    """
    
    try:
        print("Querying firebase for new plats...")
        # Query all plats where isNew = true
        new_plats = firebase_crud.query_collection(
            'plats',
            'isNew',
            '==',
            True
        )
        
        # Format the response with proper UTF-8 handling
        plats_list = []
        for plat in new_plats:
            plats_list.append({
                'id': plat.get('id'),
                'nom': plat.get('nom', ''),
                'description': plat.get('description', ''),
                'prix': plat.get('prix', 0),
                'categorie': plat.get('idCat', ''),
                'sous_categorie': plat.get('idSousCat', ''),
                'note': plat.get('note', 0),
                'image_url': plat.get('image_url', '')
            })
        
        # Create response with explicit UTF-8 encoding
        response = Response(plats_list)
        response['Content-Type'] = 'application/json; charset=utf-8'
        return response
        
    except Exception as e:
        logger.error(f"Error getting new plats: {str(e)}")
        error_response = Response(
            {'error': 'Failed to retrieve new plats'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
        error_response['Content-Type'] = 'application/json; charset=utf-8'
        return error_response


    
@api_view(['GET'])
@permission_classes([AllowAny])
def get_plat_details(request, plat_id):
    """Get detailed information for a specific dish"""
    try:
        plat = firebase_crud.get_doc('plats', plat_id)
        if not plat:
            return Response({'error': 'Dish not found'}, status=status.HTTP_404_NOT_FOUND)
        
        # Get ingredients details
        ingredients = plat.get('ingrédients', [])
        
        # Compile plat details
        plat_details = {
            'id': plat_id,
            'nom': plat.get('nom', ''),
            'description': plat.get('description', ''),
            'prix': plat.get('prix', 0),
            'estimation': plat.get('estimation', 0),
            'note': plat.get('note', 0),
            'ingredients': ingredients,
            'quantité': plat.get('quantité', 0),
            'idCat': plat.get('idCat', '')
        }
        
        return Response(plat_details)
    except Exception as e:
        logger.error(f"Error getting plat details: {str(e)}")
        return Response({'error': 'Failed to retrieve dish details'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


    
# ==================
# Preferences Endpoints
# ==================

@api_view(['GET'])
@permission_classes([IsClient])
def get_preferences(request):
    """Get client's food preferences"""
    try:
        client_id = request.user.uid
        client = firebase_crud.get_doc('clients', client_id)
        
        if not client:
            return Response({'error': 'Client not found'}, status=status.HTTP_404_NOT_FOUND)
        
        preferences = client.get('preferences', [])
        return Response({'preferences': preferences})
    except Exception as e:
        logger.error(f"Error getting preferences: {str(e)}")
        return Response({'error': 'Failed to retrieve preferences'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['PUT'])
@permission_classes([IsClient])
def update_preferences(request):
    """Update client's food preferences"""
    try:
        client_id = request.user.uid
        
        # Validate request data
        if 'preferences' not in request.data or not isinstance(request.data['preferences'], list):
            return Response({'error': 'Preferences must be a list'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Update preferences
        firebase_crud.update_doc('clients', client_id, {'preferences': request.data['preferences']})
        
        return Response({'message': 'Preferences updated successfully'})
    except Exception as e:
        logger.error(f"Error updating preferences: {str(e)}")
        return Response({'error': 'Failed to update preferences'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsClient])
def get_allergies(request):
    """Get client's food allergies"""
    try:
        client_id = request.user.uid
        client = firebase_crud.get_doc('clients', client_id)
        
        if not client:
            return Response({'error': 'Client not found'}, status=status.HTTP_404_NOT_FOUND)
        
        allergies = client.get('allergies', [])
        return Response({'allergies': allergies})
    except Exception as e:
        logger.error(f"Error getting allergies: {str(e)}")
        return Response({'error': 'Failed to retrieve allergies'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['PUT'])
@permission_classes([IsClient])
def update_allergies(request):
    """Update client's food allergies"""
    try:
        client_id = request.user.uid
        
        # Validate request data
        if 'allergies' not in request.data or not isinstance(request.data['allergies'], list):
            return Response({'error': 'Allergies must be a list'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Update allergies
        firebase_crud.update_doc('clients', client_id, {'allergies': request.data['allergies']})
        
        return Response({'message': 'Allergies updated successfully'})
    except Exception as e:
        logger.error(f"Error updating allergies: {str(e)}")
        return Response({'error': 'Failed to update allergies'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsClient])
def get_restrictions(request):
    """Get client's dietary restrictions"""
    try:
        client_id = request.user.uid
        client = firebase_crud.get_doc('clients', client_id)
        
        if not client:
            return Response({'error': 'Client not found'}, status=status.HTTP_404_NOT_FOUND)
        
        restrictions = client.get('restrictions', [])
        return Response({'restrictions': restrictions})
    except Exception as e:
        logger.error(f"Error getting restrictions: {str(e)}")
        return Response({'error': 'Failed to retrieve restrictions'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['PUT'])
@permission_classes([IsClient])
def update_restrictions(request):
    """Update client's dietary restrictions"""
    try:
        client_id = request.user.uid
        
        # Validate request data
        if 'restrictions' not in request.data or not isinstance(request.data['restrictions'], list):
            return Response({'error': 'Restrictions must be a list'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Update restrictions
        firebase_crud.update_doc('clients', client_id, {'restrictions': request.data['restrictions']})
        
        return Response({'message': 'Dietary restrictions updated successfully'})
    except Exception as e:
        logger.error(f"Error updating restrictions: {str(e)}")
        return Response({'error': 'Failed to update restrictions'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# ==================
# Recommendations Endpoints
# ==================

@api_view(['GET'])
@permission_classes([IsClient])
def get_recommendations(request):
    """
    Get recommendations for the authenticated client
    Based purely on user preferences mapped to subcategories
    """
    try:
        client_id = request.user.uid
        logger.info(f"Getting recommendations for client: {client_id}")
        
        # Get client data
        current_client = firebase_crud.get_doc('clients', client_id)
        if not current_client:
            return Response({'error': 'Client not found'}, status=status.HTTP_404_NOT_FOUND)
        
        current_preferences = current_client.get('preferences', [])
        if not current_preferences:
            logger.info(f"Client {client_id} has no preferences set - using fallback")
            return _get_fallback_recommendations('no_preferences')
        
        logger.info(f"Client {client_id} preferences: {current_preferences}")
        
        # Generate preference-based recommendations
        recommendations = _generate_preference_based_recommendations(current_preferences, client_id)
        
        return Response({
            'dish_ids': recommendations['dish_ids'],
            'source': 'preference_based',
            'count': len(recommendations['dish_ids']),
            'based_on_preferences': current_preferences,
            'subcategories_used': recommendations['subcategories_used']
        })
        
    except Exception as e:
        logger.error(f"Error getting recommendations for client {client_id}: {str(e)}")
        import traceback
        traceback.print_exc()
        return Response({
            'error': f'Failed to get recommendations: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


def _generate_preference_based_recommendations(preferences, client_id):
    """
    Generate recommendations based on user preferences mapped to subcategories
    Returns exactly 8 recommendations distributed based on number of preferences
    """
    import random
    from datetime import datetime
    
    # Preference to subcategory mapping (using actual idSousCat values)
    PREFERENCE_MAPPING = {
        'Soupes et Potages': ['scat_soupe'],
        'Salades et Crudités': ['scat_salade'],
        'Poissons et Fruits de mer': ['scat_poisson'],
        'Cuisine traditionnelle': ['scat_couscous', 'scat_tagine'],
        'Viandes': ['scat_viande'],
        'Sandwichs et burgers': ['scat_feuillete'],
        'Végétariens': ['scat_vegetarien'],
        'Crémes et Mousses': ['scat_gateau'],
        'Pâtisseries': ['scat_patisserie'],
        'Fruits et Sorbets': ['scat_froid']
    }
    
    # Determine distribution based on number of preferences
    num_preferences = len(preferences)
    if num_preferences == 1:
        distribution = [8]
    elif num_preferences == 2:
        distribution = [4, 4]
    else:  # 3 or more preferences
        distribution = [3, 3, 2]
        preferences = preferences[:3]  # Only use first 3 preferences
    
    recommended_dish_ids = []
    subcategories_used = []
    
    # Use client_id and current time to create seed for randomization
    # This ensures different results for same client on different calls
    random_seed = hash(f"{client_id}_{datetime.now().strftime('%Y%m%d%H')}") % 10000
    random.seed(random_seed)
    
    for i, preference in enumerate(preferences):
        if i >= len(distribution):
            break
            
        needed_count = distribution[i]
        subcategories = PREFERENCE_MAPPING.get(preference, [])
        
        if not subcategories:
            logger.warning(f"No subcategory mapping found for preference: {preference}")
            continue
        
        # Handle special case for 'Cuisine traditionnelle' with multiple subcategories
        if len(subcategories) > 1 and preference == 'Cuisine traditionnelle':
            # Split between Couscous and Tagine (2 each for most cases)
            couscous_count = needed_count // 2
            tagine_count = needed_count - couscous_count
            
            # Get dishes from Couscous
            couscous_dishes = _get_dishes_from_subcategory('scat_couscous', couscous_count)
            recommended_dish_ids.extend(couscous_dishes)
            if couscous_dishes:
                subcategories_used.append('scat_couscous')
            
            # Get dishes from Tagine
            tagine_dishes = _get_dishes_from_subcategory('scat_tagine', tagine_count)
            recommended_dish_ids.extend(tagine_dishes)
            if tagine_dishes:
                subcategories_used.append('scat_tagine')
        else:
            # Single subcategory
            subcat = subcategories[0]
            dishes = _get_dishes_from_subcategory(subcat, needed_count)
            recommended_dish_ids.extend(dishes)
            if dishes:
                subcategories_used.append(subcat)
    
    # Remove duplicates while preserving order
    seen = set()
    unique_dish_ids = []
    for dish_id in recommended_dish_ids:
        if dish_id not in seen:
            seen.add(dish_id)
            unique_dish_ids.append(dish_id)
    
    # If we don't have enough recommendations (less than 8), pad with random dishes
    if len(unique_dish_ids) < 8:
        logger.info(f"Only found {len(unique_dish_ids)} recommendations, padding with random dishes")
        remaining_needed = 8 - len(unique_dish_ids)
        additional_dishes = _get_random_dishes(remaining_needed, exclude_ids=set(unique_dish_ids))
        unique_dish_ids.extend(additional_dishes)
    
    # Ensure we have exactly 8 recommendations
    unique_dish_ids = unique_dish_ids[:8]
    
    logger.info(f"Generated {len(unique_dish_ids)} preference-based recommendations")
    
    return {
        'dish_ids': unique_dish_ids,
        'subcategories_used': subcategories_used
    }


def _get_dishes_from_subcategory(subcategory, count):
    """
    Get random dishes from a specific subcategory
    """
    import random
    
    try:
        logger.info(f"Fetching {count} dishes from subcategory: {subcategory}")
        
        # Query dishes from 'plats' collection by 'idSousCat'
        dishes = firebase_crud.query_collection(
            'plats',
            'idSousCat',
            '==',
            subcategory
        )
        
        if not dishes:
            logger.warning(f"No dishes found for subcategory: {subcategory}")
            return []
        
        # Extract dish IDs
        dish_ids = []
        for dish in dishes:
            dish_id = dish.get('id')
            if dish_id:
                dish_ids.append(str(dish_id))
        
        if not dish_ids:
            logger.warning(f"No valid dish IDs found for subcategory: {subcategory}")
            return []
        
        # Randomly select the requested number of dishes
        selected_count = min(count, len(dish_ids))
        selected_dishes = random.sample(dish_ids, selected_count)
        
        logger.info(f"Selected {len(selected_dishes)} dishes from {len(dish_ids)} available in {subcategory}")
        return selected_dishes
        
    except Exception as e:
        logger.error(f"Error fetching dishes from subcategory {subcategory}: {str(e)}")
        return []


def _get_random_dishes(count, exclude_ids=None):
    """
    Get random dishes from any category to pad recommendations
    """
    import random
    
    if exclude_ids is None:
        exclude_ids = set()
    
    try:
        logger.info(f"Fetching {count} random dishes for padding")
        
        # Get all dishes
        all_dishes = firebase_crud.get_all_docs('plats')
        
        if not all_dishes:
            return []
        
        # Extract dish IDs, excluding already selected ones
        available_dish_ids = []
        for dish in all_dishes:
            dish_id = dish.get('id')
            if dish_id and str(dish_id) not in exclude_ids:
                available_dish_ids.append(str(dish_id))
        
        if not available_dish_ids:
            return []
        
        # Randomly select dishes
        selected_count = min(count, len(available_dish_ids))
        selected_dishes = random.sample(available_dish_ids, selected_count)
        
        logger.info(f"Selected {len(selected_dishes)} random padding dishes")
        return selected_dishes
        
    except Exception as e:
        logger.error(f"Error fetching random dishes: {str(e)}")
        return []


def _get_fallback_recommendations(reason):
    """
    Provide fallback recommendations when no preferences are available
    """
    try:
        logger.info(f"Using fallback recommendations due to: {reason}")
        
        # Get 8 random dishes from popular categories
        fallback_subcategories = ['scat_viande', 'scat_salade', 'scat_poisson', 'scat_couscous']
        fallback_dishes = []
        
        for subcat in fallback_subcategories:
            dishes = _get_dishes_from_subcategory(subcat, 2)
            fallback_dishes.extend(dishes)
        
        # Remove duplicates and ensure we have 8
        fallback_dishes = list(set(fallback_dishes))[:8]
        
        # If still not enough, pad with random dishes
        if len(fallback_dishes) < 8:
            additional_dishes = _get_random_dishes(8 - len(fallback_dishes), exclude_ids=set(fallback_dishes))
            fallback_dishes.extend(additional_dishes)
        
        fallback_dishes = fallback_dishes[:8]
        
        return Response({
            'dish_ids': fallback_dishes,
            'source': f'fallback_{reason}',
            'count': len(fallback_dishes),
            'message': 'Showing popular dishes as recommendations',
            'based_on_preferences': []
        })
        
    except Exception as e:
        logger.error(f"Error getting fallback recommendations: {str(e)}")
        return Response({
            'dish_ids': [],
            'source': f'fallback_{reason}_error',
            'count': 0,
            'message': 'Unable to load recommendations at this time'
        })

@api_view(['GET'])
@permission_classes([IsClient])
def get_recommendation_details(request, recommendation_id):
    """Get detailed information for a specific recommendation"""
    try:
        client_id = request.user.uid
        
        # Check if recommendation exists and belongs to this client
        recommendation = firebase_crud.get_doc('recommandations', recommendation_id)
        if not recommendation or recommendation.get('idC') != client_id:
            return Response({'error': 'Recommendation not found'}, status=status.HTTP_404_NOT_FOUND)
        
        # Get recommended dishes
        recommended_plats = firebase_crud.query_collection(
            'recommandation_plat',
            'idR',
            '==',
            recommendation_id
        )
        
        # Get details for each recommended dish
        plats_details = []
        for rec_plat in recommended_plats:
            plat_id = rec_plat.get('idP')
            plat = firebase_crud.get_doc('plats', plat_id)
            
            if plat:
                # Get category name
                category_id = plat.get('idCat', '')
                category = firebase_crud.get_doc('categories', category_id)
                category_name = category.get('nomCat', '') if category else ''
                
                plats_details.append({
                    'id': plat_id,
                    'nom': plat.get('nom', ''),
                    'description': plat.get('description', ''),
                    'prix': plat.get('prix', 0),
                    'note': plat.get('note', 0),
                    'estimation': plat.get('estimation', 0),
                    'category': category_name,
                    'ingredients': plat.get('ingrédients', [])
                })
                
        return Response({
            'recommendation_id': recommendation_id,
            'date_generated': recommendation.get('date_generation', ''),
            'plats': plats_details,
            'recommendation_type': recommendation.get('recommendation_type', 'personalized')
        })
    except Exception as e:
        logger.error(f"Error getting recommendation details: {str(e)}")
        return Response({'error': 'Failed to retrieve recommendation details'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# ==================
# Notifications Endpoints
# ==================

@api_view(['GET'])
@permission_classes([IsClient])
def get_notifications(request):
    """Get client's notifications"""
    try:
        client_id = request.user.uid

        # Update this query to match your database structure
        notifications = firebase_crud.query_collection(
            'notifications',
            'recipient_id',  # Change from 'client_id' to match setup_firebase_db.py
            '==',
            client_id,
            order_by='created_at',
            desc=True
        )

        # Format the response
        notifications_list = []
        for notification in notifications:
            notifications_list.append({
                'id': notification['id'],  # Changé de .id à ['id']
                'title': notification.get('title', ''),
                'message': notification.get('message', ''),
                'created_at': notification.get('created_at', ''),
                'read': notification.get('read', False),
                'type': notification.get('type', 'general')
            })

        return Response(notifications_list)
    except Exception as e:
        logger.error(f"Error getting notifications: {str(e)}")  # This will show the actual error
        return Response({'error': f'Failed to retrieve notifications: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    

@api_view(['PATCH'])
@permission_classes([IsClient])
def mark_notification_as_read(request, notification_id):
    """Mark a specific notification as read"""
    try:
        client_id = request.user.uid
        
        # First, check if the notification exists and belongs to the client
        notification = firebase_crud.get_document('notifications', notification_id)
        
        if not notification:
            return Response({'error': 'Notification not found'}, status=status.HTTP_404_NOT_FOUND)
        
        # Check if the notification belongs to the current user
        if notification.get('recipient_id') != client_id:
            return Response({'error': 'Unauthorized access to notification'}, status=status.HTTP_403_FORBIDDEN)
        
        # Update the notification to mark as read
        update_data = {
            'read': True,
            'read_at': datetime.now().isoformat()
        }
        
        success = firebase_crud.update_document('notifications', notification_id, update_data)
        
        if success:
            return Response({'message': 'Notification marked as read successfully'})
        else:
            return Response({'error': 'Failed to update notification'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            
    except Exception as e:
        logger.error(f"Error marking notification as read: {str(e)}")
        return Response({'error': f'Failed to mark notification as read: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['PATCH'])
@permission_classes([IsClient])
def mark_all_notifications_as_read(request):
    """Mark all notifications as read for the current client"""
    try:
        client_id = request.user.uid
        
        # Get all unread notifications for the client
        unread_notifications = firebase_crud.query_collection(
            'notifications',
            'recipient_id',
            '==',
            client_id,
            additional_filters=[('read', '==', False)]
        )
        
        # Update each unread notification
        updated_count = 0
        for notification in unread_notifications:
            update_data = {
                'read': True,
                'read_at': datetime.now().isoformat()
            }
            
            success = firebase_crud.update_document('notifications', notification['id'], update_data)
            if success:
                updated_count += 1
        
        return Response({
            'message': f'Successfully marked {updated_count} notifications as read',
            'updated_count': updated_count
        })
        
    except Exception as e:
        logger.error(f"Error marking all notifications as read: {str(e)}")
        return Response({'error': f'Failed to mark all notifications as read: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['DELETE'])
@permission_classes([IsClient])
def delete_notification(request, notification_id):
    """Delete a specific notification"""
    try:
        client_id = request.user.uid
        
        # First, check if the notification exists and belongs to the client
        notification = firebase_crud.get_document('notifications', notification_id)
        
        if not notification:
            return Response({'error': 'Notification not found'}, status=status.HTTP_404_NOT_FOUND)
        
        # Check if the notification belongs to the current user
        if notification.get('recipient_id') != client_id:
            return Response({'error': 'Unauthorized access to notification'}, status=status.HTTP_403_FORBIDDEN)
        
        # Delete the notification
        success = firebase_crud.delete_document('notifications', notification_id)
        
        if success:
            return Response({'message': 'Notification deleted successfully'}, status=status.HTTP_200_OK)
        else:
            return Response({'error': 'Failed to delete notification'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            
    except Exception as e:
        logger.error(f"Error deleting notification: {str(e)}")
        return Response({'error': f'Failed to delete notification: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


    
@api_view(['GET'])
@permission_classes([IsClient])
def get_notification_details(request, notification_id):
    """Get detailed information for a specific notification"""
    try:
        client_id = request.user.uid
        
        # Get notification document
        notification = firebase_crud.get_doc('notifications', notification_id)
        if not notification or notification.get('recipient_id') != client_id:  # Changed to recipient_id
            return Response({'error': 'Notification not found'}, status=status.HTTP_404_NOT_FOUND)
        
        # Mark as read
        if not notification.get('read', False):
            firebase_crud.update_doc('notifications', notification_id, {'read': True})
        
        # Return notification details (this was missing)
        notification['id'] = notification_id  # Add the ID to the response
        
        return Response(notification)  # Return the notification object
    except Exception as e:
        logger.error(f"Error getting notification details: {str(e)}")
        return Response({'error': 'Failed to retrieve notification details'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


    
@api_view(['GET'])
@permission_classes([IsClient])
def get_similar_dishes(request, plat_id):
    """Get similar dishes (same sous-category) for a specific plat"""
    try:
        # Get the current dish details
        plat = firebase_crud.get_doc('plats', plat_id)
        if not plat:
            return Response({'error': 'Dish not found'}, status=status.HTTP_404_NOT_FOUND)
        
        # Get the category of the current dish
        category_id = plat.get('idCat')
        
        # Get all dishes in the same category
        similar_plats = firebase_crud.query_collection(
            'plats',
            'idCat',
            '==',
            category_id
        )
        
        # Remove the current dish from results and limit to 5
        similar_plats = [p for p in similar_plats if p['id'] != plat_id]
        similar_plats = similar_plats[:5]  # Limit to 5 dishes
        
        # Format the response
        result = []
        for p in similar_plats:
            result.append({
                'id': p['id'],
                'nom': p.get('nom', ''),
                'description': p.get('description', ''),
                'prix': p.get('prix', 0),
                'note': p.get('note', 0),
                'image_url': p.get('image_url', '')  # Include image if available
            })
        
        return Response(result)
    except Exception as e:
        logger.error(f"Error getting similar dishes: {str(e)}")
        return Response({'error': 'Failed to retrieve similar dishes'}, 
                       status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    #table ++
# ==================
# Table/Assistance Endpoints - Allow both guests and clients
# ==================



# ==================
# Order Endpoints - Allow both guests and clients
# ==================

@api_view(['POST'])
@permission_classes([AllowAny])  
def create_order(request):
    """Create a new order with proper client ID handling"""

    if request.method != 'POST':
        return Response({"detail": "Only POST method is allowed."}, status=405)
    
    try:
        
        print("=== CREATE ORDER API ===")
        print(f"Received data: {request.data}")
        
        # STEP 1: Extract client_id from multiple sources with priority
        client_id = None
        
        # Priority 1: Direct client_id from request data (most reliable)
        if 'client_id' in request.data and request.data['client_id']:
            client_id = request.data['client_id']
            print(f"✓ Got client_id from request data: {client_id}")
        
        # Priority 2: Extract from Authorization header if available
        elif request.META.get('HTTP_AUTHORIZATION'):
            auth_header = request.META.get('HTTP_AUTHORIZATION')
            if auth_header.startswith('Bearer '):
                token = auth_header.split(' ')[1]
                try:
                    decoded_token = auth.verify_id_token(token)
                    client_id = decoded_token['uid']
                    print(f"✓ Got client_id from token: {client_id}")
                except Exception as e:
                    print(f"⚠ Token verification failed: {e}")
        
        # Priority 3: Extract from Firebase order if provided
        elif 'firebase_order_id' in request.data:
            firebase_order_id = request.data['firebase_order_id']
            firebase_order = firebase_crud.get_doc('commandes', firebase_order_id)
            if firebase_order:
                client_id = firebase_order.get('user_id')
                print(f"✓ Got client_id from Firebase order: {client_id}")
        
        print(f"Final client_id: {client_id}")
        
        # STEP 2: Validate required fields
        if 'items' not in request.data or not isinstance(request.data['items'], list):
            return Response({'error': 'Order items are required and must be a list'}, status=status.HTTP_400_BAD_REQUEST)
        
        if 'table_id' not in request.data:
            return Response({'error': 'Table ID is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        table_id = request.data['table_id']
        items = request.data['items']
        
        if not items:
            return Response({'error': 'Order must contain at least one item'}, status=status.HTTP_400_BAD_REQUEST)
        
        # STEP 3: Validate table exists
        table = firebase_crud.get_doc('tables', table_id)
        if not table:
            return Response({'error': 'Table not found'}, status=status.HTTP_404_NOT_FOUND)
        
        # STEP 4: Calculate total and validate items
        total = 0
        valid_items = []
        
        for item in items:
            if 'plat_id' not in item or 'quantity' not in item:
                return Response({'error': 'Each item must have plat_id and quantity'}, status=status.HTTP_400_BAD_REQUEST)
            
            plat_id = item['plat_id']
            quantity = int(item['quantity'])
            
            if quantity <= 0:
                return Response({'error': 'Quantity must be positive'}, status=status.HTTP_400_BAD_REQUEST)
            
            plat = firebase_crud.get_doc('plats', plat_id)
            if not plat:
                return Response({'error': f'Dish {plat_id} not found'}, status=status.HTTP_404_NOT_FOUND)
            
            price = plat.get('prix', 0)
            total += price * quantity
            
            valid_items.append({
                'plat_id': plat_id,
                'quantity': quantity
            })
        
        print(f"Calculated total: {total}")
        
        # STEP 5: Handle loyalty points (only if we have a valid client_id)
        discount_applied = False
        loyalty_points = 0
        original_total = total
        
        if client_id and client_id != 'null' and not client_id.startswith('guest_'):
            print(f"Processing loyalty points for client: {client_id}")
            
            # Get client's loyalty points
            client = firebase_crud.get_doc('clients', client_id)
            if client:
                loyalty_points = client.get('pointsFidelite', 0)  # Note: using 'pointsFidelite' as in your Firestore
                print(f"Client loyalty points: {loyalty_points}")
                
                # Check if client has enough loyalty points for discount
                if loyalty_points >= 10:
                    # Apply 50% discount
                    total = total * 0.5
                    discount_applied = True
                    print(f"✓ Applied 50% discount. New total: {total}")
                    
                    # Reset loyalty points
                    firebase_crud.update_doc('clients', client_id, {'pointsFidelite': 0})
                else:
                    # Add 2 loyalty points for this order
                    new_loyalty_points = loyalty_points + 2
                    firebase_crud.update_doc('clients', client_id, {'pointsFidelite': new_loyalty_points})
                    print(f"✓ Added 2 loyalty points. New total: {new_loyalty_points}")
            else:
                print(f"⚠ Client document not found for ID: {client_id}")
        else:
            print("⚠ No client_id or guest user - skipping loyalty points")
        
        # STEP 6: Create order document
        order_data = {
            'montant': total,
            'dateCreation': firestore.SERVER_TIMESTAMP,
            'etat': 'en_attente',
            'confirmation': False,
            'idC': client_id,  # This is the key field that was null before
            'idTable': table_id,
            'discount_applied': discount_applied
        }
        
        # Add additional fields if provided
        if 'firebase_order_id' in request.data:
            order_data['firebase_order_id'] = request.data['firebase_order_id']
        
        if 'client_email' in request.data:
            order_data['client_email'] = request.data['client_email']
            
        if 'is_guest' in request.data:
            order_data['is_guest'] = request.data['is_guest']
        
        print(f"Creating order with data: {order_data}")
        
        order_id = firebase_crud.create_doc('commandes', order_data)
        print(f"✓ Order created with ID: {order_id}")
        
        # STEP 7: Create order items
        for item in valid_items:
            order_item_data = {
                'idCmd': order_id,
                'idP': item['plat_id'],
                'quantité': item['quantity']
            }
            firebase_crud.create_doc('commandes_plat', order_item_data)  # Note the correct spelling
        
        print(f"✓ Created {len(valid_items)} order items")
        
        # STEP 8: Prepare response
        response_data = {
            'order_id': order_id,
            'total': total,
            'message': 'Order created successfully',
            'client_id': client_id  # Include client_id in response for debugging
        }
        
        # Add loyalty information to response (only if we have client info)
        if client_id and client_id != 'null' and not client_id.startswith('guest_'):
            if discount_applied:
                response_data.update({
                    'discount_applied': True,
                    'original_total': original_total,
                    'savings': original_total - total,
                    'loyalty_points_remaining': 0
                })
            else:
                client = firebase_crud.get_doc('clients', client_id)
                if client:
                    current_points = client.get('pointsFidelite', 0)
                    response_data.update({
                        'loyalty_points_earned': 2,
                        'loyalty_points_total': current_points,
                        'points_needed_for_discount': max(0, 10 - current_points)
                    })
        
        # THIS WAS MISSING! Return the response
        return Response(response_data, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        print(f"❌ Error creating order: {str(e)}")
        import traceback
        traceback.print_exc()
        return Response({'error': f'Failed to create order: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
@api_view(['GET'])
@permission_classes([IsClient])
def get_fidelity_points(request):
    """Get client's fidelity points"""
    try:
        client_id = request.user.uid
        logger.info(f"Retrieving fidelity points for client ID: {client_id}")
        
        # Récupérer le document client
        client = firebase_crud.get_doc('clients', client_id)
        
        if not client:
            logger.warning(f"Client not found: {client_id}")
            return Response({'error': 'Client not found'}, status=status.HTTP_404_NOT_FOUND)
        
        # Retourner uniquement les points pour l'instant
        # Si 'points_fidelite' n'existe pas, essayez 'fidelity_points', puis 'fidelityPoints', sinon 0
        points = client.get('points_fidelite', 
                  client.get('fidelity_points', 
                  client.get('fidelityPoints', 0)))
        
        # Réponse simplifiée avec uniquement les points
        return Response({
            'points': points
        })
    except Exception as e:
        logger.error(f"Error in get_fidelity_points: {str(e)}", exc_info=True)
        # Renvoyer des informations sur l'erreur pour le débogage
        return Response({
            'error': 'Failed to retrieve fidelity points',
            'error_message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
# Ajouter cette fonction dans views.py

# NOUVELLES ROUTES À AJOUTER DANS urls.py :
# path('orders/<str:order_id>/cancel/', views.cancel_order, name='cancel_order'),
# path('cancellation-requests/', views.get_cancellation_requests, name='get_cancellation_requests'),

@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def cancel_order(request, order_id):
    """
    Cancel an order based on its current status
    - If status is 'en_attente': automatically cancel and notify kitchen
    - If status is 'pret' or 'en_preparation': create cancellation request and notify both kitchen and manager
    """
    try:
        # Get client ID
        if hasattr(request.user, 'uid'):
            client_id = request.user.uid
        elif hasattr(request.user, 'firebase_uid'):
            client_id = request.user.firebase_uid
        else:
            client_id = str(request.user.pk)
        
        logger.info(f"Cancel order request from client: {client_id} for order: {order_id}")
        
        # Get the order
        order = firebase_crud.get_doc('commandes', order_id)
        if not order:
            return Response({'error': 'Commande non trouvée'}, status=status.HTTP_404_NOT_FOUND)
        
        # Verify the order belongs to the client
        if order.get('idC') != client_id:
            return Response({'error': 'Accès non autorisé à cette commande'}, status=status.HTTP_403_FORBIDDEN)
        
        current_status = order.get('etat', '')
        manager_id = "Fxjzqt9DWCnIiGJDBc4q"
        
        # SCENARIO 1: Order is 'en_attente' - Automatic cancellation
        if current_status == 'en_attente':
            logger.info(f"Order {order_id} is 'en_attente' - proceeding with automatic cancellation")
            
            # Update order status to 'annulee'
            firebase_crud.update_doc('commandes', order_id, {
                'etat': 'annulee',
                'cancelled_at': firestore.SERVER_TIMESTAMP,
                'cancelled_by': client_id,
                'cancellation_type': 'automatic'
            })
            
            # Send notification to kitchen (chef)
            kitchen_notification = {
                'recipient_id': 'kitchen',
                'recipient_type': 'chef',
                'title': 'Commande annulée',
                'message': f'La commande #{order_id} a été annulée par le client',
                'type': 'order_cancellation',
                'created_at': firestore.SERVER_TIMESTAMP,
                'read': False,
                'priority': 'normal',
                'order_id': order_id,
                'client_id': client_id
            }
            firebase_crud.create_doc('notifications', kitchen_notification)
            
            logger.info(f"Order {order_id} cancelled automatically and kitchen notified")
            
            return Response({
                'message': 'Commande annulée avec succès',
                'order_id': order_id,
                'status': 'annulee',
                'cancellation_type': 'automatic'
            })
        
        # SCENARIO 2: Order is 'pret' or 'en_preparation' - Create cancellation request
        elif current_status in ['pret', 'en_preparation']:
            logger.info(f"Order {order_id} is '{current_status}' - creating cancellation request")
            
            # Get client info for the request
            client = firebase_crud.get_doc('clients', client_id)
            client_name = client.get('username', 'Client inconnu') if client else 'Client inconnu'
            
            # Create cancellation request
            cancellation_request = {
                'idClient': client_id,
                'idCommande': order_id,
                'idServeur': manager_id,
                'motif': request.data.get('motif', 'Demande d\'annulation par client'),
                'statut': 'en_attente',
                'createdAt': firestore.SERVER_TIMESTAMP
            }
            
            cancellation_id = firebase_crud.create_doc('DemandeAnnulation', cancellation_request)
            
            # Send notification to kitchen (chef)
            kitchen_notification = {
                'recipient_id': 'kitchen',
                'recipient_type': 'chef',
                'title': 'Demande d\'annulation',
                'message': f'Demande d\'annulation pour la commande #{order_id} (statut: {current_status})',
                'type': 'cancellation_request',
                'created_at': firestore.SERVER_TIMESTAMP,
                'read': False,
                'priority': 'normal',
                'order_id': order_id,
                'client_id': client_id,
                'cancellation_request_id': cancellation_id
            }
            firebase_crud.create_doc('notifications', kitchen_notification)
            
            # Send notification to manager (only with recipient_type)
            manager_notification = {
                'recipient_type': 'manager',
                'title': 'Demande d\'annulation en attente',
                'message': f'Le client {client_name} demande l\'annulation de la commande #{order_id}',
                'type': 'cancellation_request',
                'created_at': firestore.SERVER_TIMESTAMP,
                'read': False,
                'priority': 'high',
                'order_id': order_id,
                'client_id': client_id,
                'cancellation_request_id': cancellation_id
            }
            firebase_crud.create_doc('notifications', manager_notification)
            
            logger.info(f"Cancellation request created for order {order_id}, manager and kitchen notified")
            
            return Response({
                'message': 'Demande d\'annulation envoyée au manager',
                'order_id': order_id,
                'cancellation_request_id': cancellation_id,
                'status': 'cancellation_requested',
                'current_order_status': current_status
            })
        
        # SCENARIO 3: Order status doesn't allow cancellation
        else:
            return Response({
                'error': f'Impossible d\'annuler une commande avec le statut: {current_status}',
                'current_status': current_status,
                'allowed_statuses': ['en_attente', 'pret', 'en_preparation']
            }, status=status.HTTP_400_BAD_REQUEST)
    
    except Exception as e:
        logger.error(f"Error cancelling order {order_id}: {str(e)}")
        import traceback
        traceback.print_exc()
        return Response({
            'error': f'Erreur lors de l\'annulation: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_cancellation_requests(request):
    """Get cancellation requests for the current client"""
    try:
        if hasattr(request.user, 'uid'):
            client_id = request.user.uid
        elif hasattr(request.user, 'firebase_uid'):
            client_id = request.user.firebase_uid
        else:
            client_id = str(request.user.pk)
        
        # Query cancellation requests for this client
        requests_data = firebase_crud.query_collection(
            'DemandeAnnulation',
            'idClient',
            '==',
            client_id,
            order_by='createdAt',
            desc=True
        )
        
        cancellation_requests = []
        for req in requests_data:
            # Get order details
            order = firebase_crud.get_doc('commandes', req.get('idCommande', ''))
            
            cancellation_requests.append({
                'id': req.get('id'),
                'order_id': req.get('idCommande'),
                'motif': req.get('motif', ''),
                'statut': req.get('statut', ''),
                'created_at': req.get('createdAt', ''),
                'order_amount': order.get('montant', 0) if order else 0,
                'order_status': order.get('etat', '') if order else ''
            })
        
        return Response(cancellation_requests)
    
    except Exception as e:
        logger.error(f"Error getting cancellation requests: {str(e)}")
        return Response({'error': 'Erreur lors de la récupération des demandes'}, 
                       status=status.HTTP_500_INTERNAL_SERVER_ERROR)