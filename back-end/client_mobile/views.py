from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework import status
from django.utils import timezone
from datetime import datetime
from core.permissions import IsClient
from core.firebase_crud import firebase_crud
from firebase_admin import firestore
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
def get_orders_history(request):
    """Get client's order history"""
    try:
        client_id = request.user.uid
        
        # Query orders for this client, excluding hidden ones
        orders = firebase_crud.query_collection(
            'commandes',
            'idC',
            '==',
            client_id
        )
        
        # Filter out hidden orders
        orders = [order for order in orders if not order.get('hidden_from_history', False)]
        
        # Format the response
        order_history = []
        for order in orders:
            order_data = {
                'id': order.get('id'),  # Changed from order.id to order.get('id')
                'date': order.get('dateCreation', ''),
                'montant': order.get('montant', 0),
                'etat': order.get('etat', ''),
                'confirmation': order.get('confirmation', False),
                'table_number': order.get('tableNumber', ''),
                'items': order.get('items', []),
            }
            order_history.append(order_data)
            
        # Sort by date (newest first)
        order_history.sort(key=lambda x: x['date'], reverse=True)
        
        return Response(order_history)
    except Exception as e:
        logger.error(f"Error getting order history: {str(e)}")
        return Response({'error': 'Failed to retrieve order history'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


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
        
        # Don't actually delete the order, just mark it as hidden from history
        firebase_crud.update_doc('commandes', order_id, {'hidden_from_history': True})
        
        return Response({'message': 'Order removed from history'})
    except Exception as e:
        logger.error(f"Error deleting order from history: {str(e)}")
        return Response({'error': 'Failed to delete order'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ==================
# Favorites Endpoints
# ==================

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
# Reservations Endpoints
# ==================

@api_view(['GET'])
@permission_classes([IsClient])
def get_reservations(request):
    try:
        client_id = request.user.uid
        logger.info(f"Trying to get reservations for client_id: {client_id}")

        reservations = firebase_crud.query_collection(
            'reservations',
            'client_id',
            '==',
            client_id
        )

        logger.info(f"Found reservations: {reservations}")

        if not reservations:
            return Response([], status=status.HTTP_200_OK)  # Return empty list instead of 404

        reservations_list = []
        for res in reservations:
            table_id = res.get('table_id')
            logger.info(f"Processing reservation with table_id: {table_id}")
            
            # Get table info with error handling
            table = None
            table_number = "1"  # Default fallback
            
            if table_id:
                try:
                    table = firebase_crud.get_doc('tables', table_id)
                    logger.info(f"Table info for table_id {table_id}: {table}")
                    
                    if table:
                        # Extract actual table number - adjust this based on your table document structure
                        # Option 1: If table_id is like "table3", extract the number
                        if table_id.startswith('table'):
                            table_number = table_id.replace('table', '')
                        # Option 2: If table document has a 'number' field
                        elif 'number' in table:
                            table_number = str(table['number'])
                        # Option 3: If table document has a 'name' field
                        elif 'name' in table:
                            table_number = str(table['name'])
                        else:
                            # Fallback: use table_id as is
                            table_number = table_id
                            
                except Exception as table_error:
                    logger.error(f"Error getting table {table_id}: {table_error}")
                    table_number = table_id or "1"

            reservations_list.append({
                'id': res['id'],
                'date_time': res.get('date_time', ''),
                'party_size': res.get('party_size', 0),
                'status': res.get('status', 'pending'),
                'table': {
                    'id': table_id,
                    'number': table_number,  # This should be the actual table number, not capacity
                    'capacity': table.get('nbrPersonne', 0) if table else 0  # Keep capacity separate
                }
            })

        # Sort by date_time, most recent first
        reservations_list.sort(key=lambda x: x['date_time'], reverse=True)

        logger.info(f"Returning {len(reservations_list)} reservations")
        return Response(reservations_list, status=status.HTTP_200_OK)

    except Exception as e:
        logger.error(f"Error getting reservations: {str(e)}")
        logger.error(f"Full traceback: ", exc_info=True)
        return Response(
            {'error': f'Failed to retrieve reservations: {str(e)}'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
    
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
    

@api_view(['GET'])
@permission_classes([IsClient])
def get_reservation_details(request, reservation_id):
    """Get detailed information for a specific reservation"""
    try:
        client_id = request.user.uid
        
        # Get reservation document
        reservation = firebase_crud.get_doc('reservations', reservation_id)
        if not reservation or reservation.get('client_id') != client_id:
            return Response({'error': 'Reservation not found'}, status=status.HTTP_404_NOT_FOUND)
        
        # Get table information
        table_id = reservation.get('table_id')
        table = firebase_crud.get_doc('tables', table_id)
        
        # Compile reservation details
        reservation_details = {
            'id': reservation_id,
            'date': reservation.get('date_time', '').split('T')[0] if 'T' in reservation.get('date_time', '') else '',
            'time': reservation.get('date_time', '').split('T')[1] if 'T' in reservation.get('date_time', '') else '',
            'party_size': reservation.get('party_size', 0),
            'status': reservation.get('status', ''),
            'table': {
                'id': table_id,
                'number': table.get('number', 0) if table else None,
                'capacity': table.get('nbrPersonne', 0) if table else None
            },
            'created_at': reservation.get('created_at', '')
        }
        
        return Response(reservation_details)
    except Exception as e:
        logger.error(f"Error getting reservation details: {str(e)}")
        return Response({'error': 'Failed to retrieve reservation details'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([IsClient])
def create_reservation(request):
    print("=== DONNEES RECUES ===")
    print("Table ID:", request.data.get('table_id'))  # Doit afficher "table1", "table2", etc.
    
    try:
        client_id = request.user.uid
        
        # Validate required fields
        required_fields = ['date', 'time', 'party_size', 'table_id']
        for field in required_fields:
            if field not in request.data:
                return Response({'error': f'Missing required field: {field}'}, status=status.HTTP_400_BAD_REQUEST)
        
        date = request.data['date']
        time = request.data['time']
        party_size = int(request.data['party_size'])
        table_id = request.data['table_id']
        
        # Check if party size is valid (max 8)
        if party_size <= 0 or party_size > 8:
            return Response({'error': 'Party size must be between 1 and 8'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if table exists
        table = firebase_crud.get_doc('tables', table_id)
        if not table:
            print(f"ERREUR: Table {table_id} non trouvée dans Firestore")
            return Response({'error': 'Table not found'}, status=status.HTTP_404_NOT_FOUND)
        else:
            print(f"Table trouvée: {table}")
        
        # NOUVELLE VERIFICATION : Vérifier si la table est déjà réservée
        table_state = table.get('etatTable', '').lower()
        if table_state == 'reservee':
            print(f"ERREUR: Table {table_id} est déjà réservée (état: {table_state})")
            return Response({
                'error': 'Table déjà réservée', 
                'message': 'Cette table est déjà réservée. Veuillez choisir une autre table.'
            }, status=status.HTTP_409_CONFLICT)
        
        # Check if table capacity is sufficient
        if table.get('nbrPersonne', 0) < party_size:
            return Response({'error': 'Table capacity is insufficient for the party size'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Format date_time for Firestore
        date_time = f"{date}T{time}"
        
        # Create reservation
        reservation_data = {
            'client_id': client_id,
            'table_id': table_id,
            'date_time': date_time,
            'party_size': party_size,
            'status': 'en_attente',
            'created_at': firestore.SERVER_TIMESTAMP
        }
        
        reservation_id = firebase_crud.create_doc('reservations', reservation_data)
        
        # Update table status to 'reservee'
        firebase_crud.update_doc('tables', table_id, {'etatTable': 'reservee'})
        
        print(f"Réservation créée avec succès: {reservation_id}")
        return Response({
            'id': reservation_id,
            'message': 'Reservation created successfully'
        })
        
    except Exception as e:
        logger.error(f"Error creating reservation: {str(e)}")
        return Response({'error': 'Failed to create reservation'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['DELETE'])
@permission_classes([IsClient])
def cancel_reservation(request, reservation_id):
    """Cancel a pending reservation"""
    try:
        client_id = request.user.uid
        
        # Check if reservation exists and belongs to this client
        reservation = firebase_crud.get_doc('reservations', reservation_id)
        if not reservation or reservation.get('client_id') != client_id:
            return Response({'error': 'Reservation not found'}, status=status.HTTP_404_NOT_FOUND)
        
        # Check if reservation is still pending/confirmed
        if reservation.get('status') not in ['confirmed', 'pending']:
            return Response({'error': 'Only pending reservations can be cancelled'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Update reservation status
        firebase_crud.update_doc('reservations', reservation_id, {'status': 'cancelled'})
        
        return Response({'message': 'Reservation cancelled successfully'})
    except Exception as e:
        logger.error(f"Error cancelling reservation: {str(e)}")
        return Response({'error': 'Failed to cancel reservation'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsClient])
def get_available_tables(request):
    """Get available tables for reservation"""
    try:
        # Get all tables from Firebase
        tables = firebase_crud.get_all_docs('tables')
        
        # Filter tables with status 'libre'
        available_tables = []
        for table in tables:
            if table.get('etatTable') == 'libre':
                available_tables.append({
                    'id': table['id'],
                    'number': table.get('number'),
                    'capacity': table.get('nbrPersonne', 0),
                    'type': table.get('type', 'Standard'),
                    'status': table.get('etatTable', 'libre')
                })
        
        return Response({'tables': available_tables})
    except Exception as e:
        logger.error(f"Error getting available tables: {str(e)}")
        return Response({'error': 'Failed to retrieve available tables'}, 
                       status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# ==================
# Menu Endpoints
# ==================

@api_view(['GET'])
@permission_classes([IsClient])
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
@permission_classes([IsClient])
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
@permission_classes([IsClient])
def get_subcategories(request, category_id):
    """Get subcategories for a specific category"""
    try:
        subcategories = firebase_crud.query_collection(
            'sous_categories',
            'idCat',
            '==',
            category_id
        )
        
        subcategory_list = [{
            'id': subcat.id,
            'nomSousCat': subcat.get('nomSousCat', ''),
            'idCat': subcat.get('idCat', '')
        } for subcat in subcategories]
        
        return Response(subcategory_list)
    except Exception as e:
        logger.error(f"Error getting subcategories: {str(e)}")
        return Response({'error': 'Failed to retrieve subcategories'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsClient])
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

@api_view(['GET'])
@permission_classes([IsClient])
def get_subcategories(request, category_id):
    try:
        subcategories = firebase_crud.query_collection(
            'sous_categories',
            'idCat',
            '==',
            category_id
        )

        logger.info(f"Found {len(subcategories)} subcategories")
        subcategory_list = [{
            'id': subcat['id'],  # Changez subcat.id en subcat['id']
            'nomSousCat': subcat.get('nomSousCat', ''),
            'idCat': subcat.get('idCat', '')
        } for subcat in subcategories]

        return Response(subcategory_list)
    except Exception as e:
        logger.error(f"Error getting subcategories: {str(e)}")
        return Response({'error': 'Failed to retrieve subcategories'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
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
    
@api_view(['PUT'])
@permission_classes([IsClient])
def mark_notification_as_read(request, id):
    """Mark a notification as read"""
    try:
        client_id = request.user.uid
        
        # Get the notification
        notification = firebase_crud.get_document('notifications', id)
        
        if not notification:
            return Response({'error': 'Notification not found'}, status=status.HTTP_404_NOT_FOUND)
        
        # Verify the notification belongs to the client
        if notification.get('recipient_id') != client_id:
            return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
        # Update the notification
        firebase_crud.update_document('notifications', id, {'read': True})
        
        return Response({'success': True})
    except Exception as e:
        logger.error(f"Error marking notification as read: {str(e)}")
        return Response({'error': f'Failed to mark notification as read: {str(e)}'}, 
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
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

# ==================
# Dashboard Endpoint
# ==================


@api_view(['GET'])
@permission_classes([IsClient])
def get_dashboard(request):
    """Get client dashboard with recommendations, reservations, and notifications"""
    try:
        client_id = request.user.uid
        dashboard_data = {}

        # Get top recommended dish without sorting in the query
        recommendations = firebase_crud.query_collection(
            'recommandations',
            'idC',
            '==',
            client_id
        )
        
        # Sort in memory
        recommendations = sorted(recommendations, key=lambda x: x.get('date_generation', ''), reverse=True)
        
        if recommendations:
            recommendation_id = recommendations[0]['id']
            recommended_plats = firebase_crud.query_collection(
                'recommandation_plat',
                'idR',
                '==',
                recommendation_id,
                limit=1
            )

            if recommended_plats:
                plat_id = recommended_plats[0].get('idP')
                plat = firebase_crud.get_doc('plats', plat_id)

                if plat:
                    dashboard_data['top_recommendation'] = {
                        'id': plat_id,
                        'nom': plat.get('nom', ''),
                        'description': plat.get('description', ''),
                        'prix': plat.get('prix', 0),
                        'note': plat.get('note', 0)
                    }

        # Get upcoming reservation without sorting in the query
        reservations = firebase_crud.query_collection(
            'reservations',
            'client_id',
            '==',
            client_id
        )
        
        # Sort in memory
        reservations = sorted(reservations, key=lambda x: x.get('date_time', ''))
        
        if reservations:
            res = reservations[0]
            # Only include reservation if it's in the future and not cancelled
            if res.get('status') != 'cancelled':
                table_id = res.get('table_id')
                table = firebase_crud.get_doc('tables', table_id)

                dashboard_data['upcoming_reservation'] = {
                    'id': res['id'],
                    'date_time': res.get('date_time', ''),
                    'party_size': res.get('party_size', 0),
                    'status': res.get('status', ''),
                    'table': {
                        'id': table_id,
                        'number': table.get('number', 0) if table else None
                    }
                }

        # Get unread notifications count
        notifications = firebase_crud.query_collection(
            'notifications',
            'recipient_id',
            '==',
            client_id,
            where_field='read',
            where_op='==',
            where_value=False
        )

        dashboard_data['unread_notifications'] = len(notifications)

        # Get latest 3 notifications without sorting in the query
        recent_notifications = firebase_crud.query_collection(
            'notifications',
            'recipient_id',
            '==',
            client_id
        )
        
        # Sort in memory and limit to 3
        recent_notifications = sorted(recent_notifications, key=lambda x: x.get('created_at', ''), reverse=True)[:3]

        dashboard_data['recent_notifications'] = [{
            'id': n['id'],
            'title': n.get('title', ''),
            'message': n.get('message', ''),
            'created_at': n.get('created_at', ''),
            'read': n.get('read', False)
        } for n in recent_notifications]

        # Get fidelity points
        client = firebase_crud.get_doc('clients', client_id)
        if client:
            dashboard_data['fidelity_points'] = client.get('fidelityPoints', 0)

        return Response(dashboard_data)
    except Exception as e:
        logger.error(f"Error getting dashboard: {str(e)}")
        return Response({'error': 'Failed to retrieve dashboard'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
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


