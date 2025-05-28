#client_table/views.py
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from core.permissions import IsClient, IsGuest, IsTableClient
from core.firebase_crud import firebase_crud
from firebase_admin import firestore
import logging
from django.utils import timezone
from datetime import datetime
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


# 3. Django Settings Fix - Add to settings.py
# Ensure proper UTF-8 handling in Django settings
DATABASES = {
    'default': {
        # ... your database config
        'OPTIONS': {
            'charset': 'utf8mb4',
            'use_unicode': True,
        },
    }
}

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
@permission_classes([AllowAny])  # Changed from IsClient to IsTableClient
def create_assistance_request(request):
    """Create a new assistance request"""
    try:
        client_id = request.user.uid
        
        # Validate required fields
        if 'table_id' not in request.data:
            return Response({'error': 'Table ID is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        table_id = request.data['table_id']
        
        # Check if table exists
        table = firebase_crud.get_doc('tables', table_id)
        if not table:
            return Response({'error': 'Table not found'}, status=status.HTTP_404_NOT_FOUND)
        
        # Create assistance request
        assistance_data = {
            'idC': client_id,
            'idTable': table_id,
            'etat': 'non traitee',
            'createdAt': firestore.SERVER_TIMESTAMP
        }
        
        assistance_id = firebase_crud.create_doc('demandeAssistance', assistance_data)
        
        return Response({
            'id': assistance_id,
            'message': 'Assistance request created successfully'
        })
    except Exception as e:
        logger.error(f"Error creating assistance request: {str(e)}")
        return Response({'error': 'Failed to create assistance request'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsClient])
def get_favorites(request):
    """Get client's favorite dishes"""
    try:
        client_id = request.user.uid
        
        # Get client document
        client = firebase_crud.get_doc('clients', client_id)
        if not client:
            return Response({'error': 'Client not found'}, status=status.HTTP_404_NOT_FOUND)
        
        # Get favorites list
        favorites = client.get('favorites', [])
        
        # Get details for each favorite dish
        favorite_dishes = []
        for plat_id in favorites:
            plat = firebase_crud.get_doc('plats', plat_id)
            if plat:
                favorite_dishes.append({
                    'id': plat_id,
                    'nom': plat.get('nom', ''),
                    'description': plat.get('description', ''),
                    'prix': plat.get('prix', 0),
                    'note': plat.get('note', 0)
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
        
        # Get client's current favorites
        client = firebase_crud.get_doc('clients', client_id)
        if not client:
            return Response({'error': 'Client not found'}, status=status.HTTP_404_NOT_FOUND)
        
        favorites = client.get('favorites', [])
        
        # Check if already in favorites
        if plat_id in favorites:
            return Response({'message': 'Dish already in favorites'})
        
        # Add to favorites
        favorites.append(plat_id)
        firebase_crud.update_doc('clients', client_id, {'favorites': favorites})
        
        return Response({'message': 'Dish added to favorites'})
    except Exception as e:
        logger.error(f"Error adding favorite: {str(e)}")
        return Response({'error': 'Failed to add favorite'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['DELETE'])
@permission_classes([IsClient])
def remove_favorite(request, plat_id):
    """Remove a dish from client's favorites"""
    try:
        client_id = request.user.uid
        
        # Get client's current favorites
        client = firebase_crud.get_doc('clients', client_id)
        if not client:
            return Response({'error': 'Client not found'}, status=status.HTTP_404_NOT_FOUND)
        
        favorites = client.get('favorites', [])
        
        # Check if in favorites
        if plat_id not in favorites:
            return Response({'error': 'Dish not in favorites'}, status=status.HTTP_404_NOT_FOUND)
        
        # Remove from favorites
        favorites.remove(plat_id)
        firebase_crud.update_doc('clients', client_id, {'favorites': favorites})
        
        return Response({'message': 'Dish removed from favorites'})
    except Exception as e:
        logger.error(f"Error removing favorite: {str(e)}")
        return Response({'error': 'Failed to remove favorite'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)




# ==================
# Menu Endpoints
# ==================

@api_view(['GET'])
@permission_classes([AllowAny])
def get_menus(request):
    """Get all menus"""
    try:
        menus = firebase_crud.get_all_docs('menus')
        
        # Get dishes for each menu
        menu_list = []
        for menu in menus:
            # Get menu-plat relations
            menu_plats = firebase_crud.query_collection(
                'menu_plat',
                'idM',
                '==',
                menu['id']
            )
            
            # Get plat details
            dishes = []
            for mp in menu_plats:
                plat_id = mp.get('idP')
                plat = firebase_crud.get_doc('plats', plat_id)
                if plat:
                    dishes.append({
                        'id': plat_id,
                        'nom': plat.get('nom', ''),
                        'description': plat.get('description', ''),
                        'prix': plat.get('prix', 0)  
                    })
            
            menu_list.append({
                'id': menu['id'],
                'nomMenu': menu.get('nomMenu', ''),
                'dishes': dishes
            })
        
        return Response(menu_list)
    except Exception as e:
        logger.error(f"Error getting menus: {str(e)}")
        return Response({'error': 'Failed to retrieve menus'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([AllowAny])
def get_categories(request):
    """Get all dish categories"""
    try:
        categories = firebase_crud.get_all_docs('categories')
        category_list = [{
            'id': cat['id'],
            'nomCat': cat.get('nomCat', '')
        } for cat in categories]
        
        return Response(category_list)
    except Exception as e:
        logger.error(f"Error getting categories: {str(e)}")
        return Response({'error': 'Failed to retrieve categories'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    


@api_view(['GET'])
@permission_classes([AllowAny])
def get_subcategory_items(request, subcategory_id):
    """Get all dishes/items for a specific subcategory"""
    try:
        # Verify subcategory exists
        subcategory = firebase_crud.get_doc('sous_categories', subcategory_id)
        if not subcategory:
            return Response({'error': 'Subcategory not found'}, status=404)
        
        # Get dishes for this subcategory
        dishes = firebase_crud.query_collection(
            'plats',
            'idSousCat',
            '==',
            subcategory_id
        )
        
        # Format dishes
        dishes_list = []
        for dish in dishes:
            dishes_list.append({
                'id': dish.get('id'),
                'nom': dish.get('nom', ''),
                'description': dish.get('description', ''),
                'prix': dish.get('prix', 0),
                'ingredients': dish.get('ingredients', []),
                'pointsFidelite': dish.get('pointsFidelite', 0)
            })
        
        return Response({
            'subcategory': {
                'id': subcategory_id,
                'nom': subcategory.get('nomSousCat', '')
            },
            'items': dishes_list
        })
        
    except Exception as e:
        logger.error(f"Error getting items: {str(e)}")
        return Response({'error': str(e)}, status=500)


@api_view(['GET'])
@permission_classes([AllowAny])
def get_new_plats(request):
    print("=== get_new_plats function called ===")  # Add this line
    """
    Get all plats with isNew attribute set to true
    Returns:
        - List of plats where isNew = true
        - Empty list if no new plats found
    """
    
    try:
        print("Querying firebase for new plats...")  # Add this line
        # Query all plats where isNew = true
        new_plats = firebase_crud.query_collection(
            'plats',
            'isNew',
            '==',
            True
        )
        
        # Format the response
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
                'image_url': plat.get('image_url', '')  # Include if available
            })
        
        return Response(plats_list)
    
    except Exception as e:
        logger.error(f"Error getting new plats: {str(e)}")
        return Response(
            {'error': 'Failed to retrieve new plats'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
@permission_classes([AllowAny])
def get_category_subcategories(request, category_id):
    try:
        # Vérifiez que la catégorie existe
        category = firebase_crud.get_doc('categories', category_id)
        if not category:
            return Response({'error': 'Catégorie non trouvée'}, status=404)
        
        # Récupérez les sous-catégories
        subcategories = firebase_crud.query_collection(
            'sous_categories',
            'idCat',
            '==',
            category_id
        )
        
        # Formatage de la réponse
        response_data = {
            'category': {
                'id': category_id,
                'name': category.get('nomCat', '')
            },
            'subcategories': [
                {
                    'id': subcat.get('id'),
                    'name': subcat.get('nomSousCat', ''),
                    'category_id': subcat.get('idCat', '')
                }
                for subcat in subcategories
            ]
        }
        
        return Response(response_data)
        
    except Exception as e:
        return Response({'error': str(e)}, status=500)
    
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
    try:
        client_id = request.user.uid
        # Query for recommandations without sorting in the query
        recommendations = firebase_crud.query_collection(
            'recommandations',
            'idC',
            '==',
            client_id
        )
        
        # Sort in memory
        recommendations = sorted(recommendations, key=lambda x: x.get('date_generation', ''), reverse=True)

        if not recommendations:
            return Response({'message': 'No recommendations found'}, status=status.HTTP_404_NOT_FOUND)

        recommendation_id = recommendations[0]['id']

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
                plats_details.append({
                    'id': plat_id,
                    'nom': plat.get('nom', ''),
                    'description': plat.get('description', ''),
                    'prix': plat.get('prix', 0),
                    'note': plat.get('note', 0)
                })

        return Response({
            'recommendation_id': recommendation_id,
            'date_generated': recommendations[0].get('date_generation', ''),
            'plats': plats_details
        })
    except Exception as e:
        logger.error(f"Error getting recommendations: {str(e)}")
        return Response({'error': 'Failed to retrieve recommendations'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

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
@permission_classes([IsTableClient])  
def create_order(request):
    """Create a new order"""

    if request.method != 'POST':
            return Response({"detail": "Only POST method is allowed."}, status=405)
    try:
        client_id = request.user.uid
        
        # Validate required fields
        if 'items' not in request.data or not isinstance(request.data['items'], list):
            return Response({'error': 'Order items are required and must be a list'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Table ID is now required
        if 'table_id' not in request.data:
            return Response({'error': 'Table ID is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        table_id = request.data['table_id']
        
        # Check if table exists
        table = firebase_crud.get_doc('tables', table_id)
        if not table:
            return Response({'error': 'Table not found'}, status=status.HTTP_404_NOT_FOUND)
        
        items = request.data['items']
        if not items:
            return Response({'error': 'Order must contain at least one item'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Calculate total amount and validate items
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
        
        # Get client's loyalty points
        client = firebase_crud.get_doc('clients', client_id)
        loyalty_points = client.get('points_fidelite', 0) if client else 0
        
        # Check if client has enough loyalty points for discount
        discount_applied = False
        if loyalty_points >= 10:
            # Apply 50% discount
            original_total = total
            total = total * 0.5
            discount_applied = True
            # Reset loyalty points
            firebase_crud.update_doc('clients', client_id, {'points_fidelite': 0})
        else:
            # Add 2 loyalty points for this order
            new_loyalty_points = loyalty_points + 2
            firebase_crud.update_doc('clients', client_id, {'points_fidelite': new_loyalty_points})
        
        # Create order document with table_id
        order_data = {
            'montant': total,
            'dateCreation': firestore.SERVER_TIMESTAMP,
            'etat': 'en_attente',
            'confirmation': False,
            'idC': client_id,
            'idTable': table_id,  # Added table ID to the order
            'discount_applied': discount_applied  # Track if discount was applied
        }
        
        order_id = firebase_crud.create_doc('commandes', order_data)
        
        # Create order items
        for item in valid_items:
            order_item_data = {
                'idCmd': order_id,
                'idP': item['plat_id'],
                'quantité': item['quantity']
            }
            firebase_crud.create_doc('commande_plat', order_item_data)
        
        # Prepare response
        response_data = {
            'order_id': order_id,
            'total': total,
            'message': 'Order created successfully'
        }
        
        # Add loyalty information to response
        if discount_applied:
            response_data.update({
                'discount_applied': True,
                'original_total': original_total,
                'savings': original_total - total,
                'loyalty_points_remaining': 0
            })
        else:
            response_data.update({
                'loyalty_points_earned': 2,
                'loyalty_points_total': new_loyalty_points,
                'points_needed_for_discount': 10 - new_loyalty_points
            })
            
        return Response(response_data, status=status.HTTP_201_CREATED)
    except Exception as e:
        logger.error(f"Error creating order: {str(e)}")
        return Response({'error': 'Failed to create order'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
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