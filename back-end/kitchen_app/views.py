from django.shortcuts import render
from django.views.decorators.http import require_http_methods
from firebase_admin import firestore
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from rest_framework.decorators import api_view, authentication_classes, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from core.firebase_utils import firebase_config
from core.authentication import FirebaseAuthentication
from core.permissions import IsChef, IsStaff
from core.orders_utils import get_all_orders, get_orders_by_status
from core.permissions import IsServer
import json
import logging

logger = logging.getLogger(__name__)
db = firebase_config.get_db()

# 1. Get ingredients with low stock
@api_view(['GET'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsStaff])
def get_low_stock_ingredients(request):
    """
    Get ingredients that are at or below their alert threshold
    Returns ingredients with current quantity <= seuil_alerte
    """
    try:
        ingredients_ref = db.collection('ingredients')
        low_stock_ingredients = []
        
        for doc in ingredients_ref.stream():
            ingredient_data = doc.to_dict()
            ingredient_data['id'] = doc.id
            
            # Get current quantity and alert threshold
            current_quantity = ingredient_data.get('quantite', 0)
            alert_threshold = ingredient_data.get('seuil_alerte', 0)
            
            # Check if ingredient is at or below alert threshold
            if current_quantity <= alert_threshold:
                low_stock_ingredients.append({
                    'id': doc.id,
                    'nom': ingredient_data.get('nom', 'Unknown'),
                    'categorie': ingredient_data.get('categorie', 'Unknown'),
                    'quantite_actuelle': current_quantity,
                    'seuil_alerte': alert_threshold,
                    'unite': ingredient_data.get('unite', ''),
                    'date_expiration': ingredient_data.get('date_expiration', ''),
                    'cout_par_unite': ingredient_data.get('cout_par_unite', 0)
                })
        
        # Sort by urgency (lowest quantity first)
        low_stock_ingredients.sort(key=lambda x: x['quantite_actuelle'])
        
        return JsonResponse(low_stock_ingredients, safe=False)
        
    except Exception as e:
        logger.error(f"Error fetching low stock ingredients: {str(e)}", exc_info=True)
        return JsonResponse({'error': str(e)}, status=500)

# 2. Get active orders (en_attente and en_preparation)
@api_view(['GET'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsStaff])
def get_active_orders(request):
    """
    Get orders with status 'en_attente' or 'en_preparation'
    These are the orders that chefs need to work on
    """
    try:
        # Handle all active status variants
        status_values = ['en_attente', 'en attente', 'pending', 'en_preparation', 'en preparation', 'preparing']
        orders = get_orders_by_status(status_values, db)
        return JsonResponse(orders, safe=False)
    except Exception as e:
        logger.error(f"Error in get_active_orders: {str(e)}", exc_info=True)
        return JsonResponse({'error': str(e)}, status=500)

# 3. Chef-specific order views (adapted from server views)
@api_view(['GET'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsStaff])
def get_all_orders_view(request):
    """Get all orders for chef"""
    try:
        orders = get_all_orders(db)
        return JsonResponse(orders, safe=False)
    except Exception as e:
        logger.error(f"Error in get_all_orders_view: {str(e)}", exc_info=True)
        return JsonResponse({'error': str(e)}, status=500)

@api_view(['GET'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsStaff])
def get_pending_orders_view(request):
    """Get orders with status 'en attente' for chef"""
    try:
        # Handle all waiting status variants
        status_values = ['en_attente', 'en attente', 'pending']
        orders = get_orders_by_status(status_values, db)
        return JsonResponse(orders, safe=False)
    except Exception as e:
        logger.error(f"Error in get_pending_orders_view: {str(e)}", exc_info=True)
        return JsonResponse({'error': str(e)}, status=500)

@api_view(['GET'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsStaff])
def get_preparing_orders_view(request):
    """Get orders with status 'en preparation' for chef"""
    try:
        # Handle all preparing status variants
        status_values = ['en_preparation', 'en preparation', 'preparing']
        orders = get_orders_by_status(status_values, db)
        return JsonResponse(orders, safe=False)
    except Exception as e:
        logger.error(f"Error in get_preparing_orders_view: {str(e)}", exc_info=True)
        return JsonResponse({'error': str(e)}, status=500)

@api_view(['GET'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsStaff])
def get_ready_orders_view(request):
    """Get orders with status 'pret' for chef"""
    try:
        # Handle all ready status variants
        status_values = ['pret', 'prete', 'ready']
        orders = get_orders_by_status(status_values, db)
        return JsonResponse(orders, safe=False)
    except Exception as e:
        logger.error(f"Error in get_ready_orders_view: {str(e)}", exc_info=True)
        return JsonResponse({'error': str(e)}, status=500)

@api_view(['GET'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsStaff])
def get_served_orders_view(request):
    """Get orders with status 'servi' or 'servie' for chef"""
    try:
        # Handle all served status variants
        status_values = ['servi', 'servie', 'en_service', 'served']
        orders = get_orders_by_status(status_values, db)
        return JsonResponse(orders, safe=False)
    except Exception as e:
        logger.error(f"Error in get_served_orders_view: {str(e)}", exc_info=True)
        return JsonResponse({'error': str(e)}, status=500)

@api_view(['GET'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsStaff])
def get_cancelled_orders_view(request):
    """Get orders with status 'annulee' for chef"""
    try:
        # Handle all cancelled status variants
        status_values = ['annule', 'annulee', 'cancelled']
        orders = get_orders_by_status(status_values, db)
        return JsonResponse(orders, safe=False)
    except Exception as e:
        logger.error(f"Error in get_cancelled_orders_view: {str(e)}", exc_info=True)
        return JsonResponse({'error': str(e)}, status=500)

# 4. Get chef profile information
@api_view(['GET'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsStaff])
def get_chef_profile(request):
    """Get chef profile information"""
    try:
        # User is already authenticated by FirebaseAuthentication
        user = request.user
        user_id = user.uid
        
        # First, check if the user ID directly matches a document ID
        chef_ref = db.collection('employes').document(user_id)
        chef_doc = chef_ref.get()
        
        if not chef_doc.exists:
            # If not, try to query by firebase_uid field
            employees_ref = db.collection('employes').where('firebase_uid', '==', user_id).limit(1)
            employees_docs = list(employees_ref.stream())
            
            if not employees_docs:
                return JsonResponse({'error': 'Chef profile not found'}, status=404)
                
            chef_doc = employees_docs[0]
            employee_id = chef_doc.id
        else:
            employee_id = user_id
            
        chef_data = chef_doc.to_dict()
        
        # Don't return sensitive data like password
        if 'motDePasseE' in chef_data:
            del chef_data['motDePasseE']
        
        # Fetch additional info from cuisiniers collection if exists
        cuisinier_ref = db.collection('cuisiniers').where('idE', '==', employee_id).limit(1)
        cuisinier_docs = cuisinier_ref.stream()
        cuisinier_info = next((doc.to_dict() for doc in cuisinier_docs), {})
        
        # Count orders handled/prepared
        # This could be tracked in a separate collection or calculated from order history
        orders_prepared = 0  # You might want to implement this based on your tracking needs
        
        response = {
            'profile': chef_data,
            'chef_info': cuisinier_info,
            'orders_prepared': orders_prepared,
            'employee_id': employee_id
        }
        return JsonResponse(response, safe=False)
    except Exception as e:
        logger.error(f"Error fetching chef profile: {str(e)}")
        return JsonResponse({'error': str(e)}, status=500)

# 5. Update password (adapted from server version)
@api_view(['PUT'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsStaff])
@csrf_exempt
def update_password(request):
    """Update chef password in Firebase Authentication"""
    try:
        data = json.loads(request.body)
        user_id = request.user.uid
        current_password = data.get('current_password')
        new_password = data.get('new_password')
        
        logger.info(f"Attempting password update for Chef Firebase UID: {user_id}")
        
        # Validate inputs
        if not current_password or not new_password:
            return JsonResponse({'error': 'Current and new passwords are required'}, status=400)
        
        # Get user email from Firestore using firebase_uid
        user_email = None
        employees_ref = db.collection('employes').where('firebase_uid', '==', user_id).limit(1)
        employees_docs = list(employees_ref.stream())
        
        if employees_docs:
            employee_data = employees_docs[0].to_dict()
            user_email = employee_data.get('emailE')
        
        if not user_email:
            logger.error(f"User email not found for Firebase UID: {user_id}")
            return JsonResponse({'error': 'Could not retrieve user email'}, status=404)
            
        logger.info(f"Retrieved email for chef: {user_email}")
        
        # Since Firebase Admin SDK doesn't provide password verification,
        # we directly update the password
        try:
            from firebase_admin import auth
            
            # Update the user's password
            auth.update_user(
                user_id,
                password=new_password
            )
            logger.info(f"Password updated successfully for chef: {user_id}")
            
            return JsonResponse({'message': 'Password updated successfully'})
            
        except auth.FirebaseError as auth_error:
            logger.error(f"Firebase Auth error: {str(auth_error)}")
            return JsonResponse({'error': f'Password update error: {str(auth_error)}'}, status=500)
    except Exception as e:
        logger.error(f"Error updating password: {str(e)}")
        return JsonResponse({'error': str(e)}, status=500)

# 6. Get notifications for chef
@api_view(['GET'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsStaff])
def get_chef_notifications(request):
    """
    Get notifications for the authenticated chef
    Returns notifications where recipient_type is 'cuisinier' or 'chef' and recipient_id matches
    """
    try:
        user = request.user
        user_id = user.uid
        
        # Get employee ID from firebase_uid
        employee_id = None
        employees_ref = db.collection('employes').where('firebase_uid', '==', user_id).limit(1)
        employees_docs = list(employees_ref.stream())
        
        if employees_docs:
            employee_id = employees_docs[0].id
        else:
            # Fallback: try using user_id directly
            employee_id = user_id
        
        # Query notifications for this chef
        notifications_ref = db.collection('notifications').where('recipient_id', '==', employee_id)
        notifications = []
        
        for doc in notifications_ref.stream():
            notification_data = doc.to_dict()
            notification_data['id'] = doc.id
            
            # Filter by recipient type (cuisinier or chef)
            recipient_type = notification_data.get('recipient_type', '')
            if recipient_type in ['cuisinier', 'chef']:
                notifications.append({
                    'id': doc.id,
                    'title': notification_data.get('title', ''),
                    'message': notification_data.get('message', ''),
                    'type': notification_data.get('type', ''),
                    'priority': notification_data.get('priority', 'normal'),
                    'read': notification_data.get('read', False),
                    'created_at': notification_data.get('created_at'),
                    'related_id': notification_data.get('related_id', '')
                })
        
        # Sort by creation date (most recent first)
        notifications.sort(key=lambda x: x.get('created_at') or '', reverse=True)
        
        return JsonResponse(notifications, safe=False)
        
    except Exception as e:
        logger.error(f"Error fetching chef notifications: {str(e)}", exc_info=True)
        return JsonResponse({'error': str(e)}, status=500)

# Mark notification as read
@api_view(['PUT'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsStaff])
@csrf_exempt
def mark_notification_read(request, notification_id):
    """Mark a specific notification as read"""
    try:
        notification_ref = db.collection('notifications').document(notification_id)
        notification_doc = notification_ref.get()
        
        if not notification_doc.exists:
            return JsonResponse({'error': 'Notification not found'}, status=404)
        
        # Update the read status
        notification_ref.update({'read': True})
        
        return JsonResponse({'message': 'Notification marked as read'})
        
    except Exception as e:
        logger.error(f"Error marking notification as read: {str(e)}")
        return JsonResponse({'error': str(e)}, status=500)
@api_view(['GET'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsStaff])
def get_order_details(request, order_id):
    """Get detailed information for a specific order"""
    try:
        # Get the main order document
        order_ref = db.collection('commandes').document(order_id)
        order_doc = order_ref.get()
        
        if not order_doc.exists:
            return JsonResponse({'error': 'Order not found'}, status=404)
        
        order_data = order_doc.to_dict()
        
        # Get client information
        client_info = None
        if 'idC' in order_data:
            client_ref = db.collection('clients').document(order_data['idC'])
            client_doc = client_ref.get()
            if client_doc.exists:
                client_data = client_doc.to_dict()
                client_info = {
                    'id': order_data['idC'],
                    'username': client_data.get('username', 'Unknown'),
                    'email': client_data.get('email', 'Unknown')
                }
        
        # Get table information
        table_info = None
        if 'idTable' in order_data:
            table_ref = db.collection('tables').document(order_data['idTable'])
            table_doc = table_ref.get()
            if table_doc.exists:
                table_data = table_doc.to_dict()
                table_info = {
                    'id': order_data['idTable'],
                    'nbrPersonne': table_data.get('nbrPersonne', 0),
                    'etatTable': table_data.get('etatTable', 'Unknown')
                }
        
        # Get order items from commandes_plat collection
        order_items = []
        total_calculated = 0.0
        
        order_items_ref = db.collection('commandes_plat').where('idCmd', '==', order_id)
        for item_doc in order_items_ref.stream():
            item_data = item_doc.to_dict()
            
            # Get dish information - FIXED: Better error handling and logging
            dish_info = None
            dish_price = 0.0
            if 'idP' in item_data:
                dish_id = str(item_data['idP'])  # Ensure it's a string
                logger.info(f"Looking for dish with ID: {dish_id}")
                
                try:
                    # Try different possible ID formats
                    dish_ref = db.collection('plats').document(dish_id)
                    dish_doc = dish_ref.get()
                    
                    if dish_doc.exists:
                        dish_data = dish_doc.to_dict()
                        dish_price = float(dish_data.get('prix', 0.0))
                        dish_info = {
                            'id': dish_id,
                            'nom': dish_data.get('nom', f'Plat {dish_id}'),
                            'prix': dish_price,
                            'description': dish_data.get('description', ''),
                            'note': dish_data.get('note', 0),
                            'estimation': dish_data.get('estimation', 0)
                        }
                        logger.info(f"Found dish: {dish_info}")
                    else:
                        # If not found, try to search by different field or log all available dishes
                        logger.warning(f"Dish with ID '{dish_id}' not found in plats collection")
                        
                        # Optional: Search through all plats to find a match
                        all_plats = db.collection('plats').stream()
                        found_alternative = False
                        for plat_doc in all_plats:
                            plat_data = plat_doc.to_dict()
                            plat_doc_id = plat_doc.id
                            
                            # Check if the document ID matches (in case of type mismatch)
                            if str(plat_doc_id) == dish_id or plat_doc_id == dish_id:
                                dish_price = float(plat_data.get('prix', 0.0))
                                dish_info = {
                                    'id': plat_doc_id,
                                    'nom': plat_data.get('nom', f'Plat {plat_doc_id}'),
                                    'prix': dish_price,
                                    'description': plat_data.get('description', ''),
                                    'note': plat_data.get('note', 0),
                                    'estimation': plat_data.get('estimation', 0)
                                }
                                found_alternative = True
                                logger.info(f"Found dish by alternative search: {dish_info}")
                                break
                        
                        if not found_alternative:
                            # Create a placeholder dish info
                            dish_info = {
                                'id': dish_id,
                                'nom': f'Plat non trouvé (ID: {dish_id})',
                                'prix': 0.0,
                                'description': 'Plat non trouvé dans la base de données',
                                'note': 0,
                                'estimation': 0
                            }
                            logger.error(f"Could not find dish with ID '{dish_id}' anywhere")
                            
                except Exception as e:
                    logger.error(f"Error fetching dish {dish_id}: {str(e)}")
                    dish_info = {
                        'id': dish_id,
                        'nom': f'Erreur chargement plat {dish_id}',
                        'prix': 0.0,
                        'description': f'Erreur: {str(e)}',
                        'note': 0,
                        'estimation': 0
                    }
            
            quantity = item_data.get('quantité', 1)
            item_total = dish_price * quantity
            total_calculated += item_total
            
            order_items.append({
                'dish': dish_info,
                'quantity': quantity,
                'unit_price': dish_price,
                'total_price': round(item_total, 2)
            })
        
        # Get server information if available
        server_info = None
        serveur_commande_ref = db.collection('serveur_commande').where('idCmd', '==', order_id).limit(1)
        serveur_commande_docs = list(serveur_commande_ref.stream())
        
        if serveur_commande_docs:
            serveur_commande_data = serveur_commande_docs[0].to_dict()
            if 'idE' in serveur_commande_data:
                employee_ref = db.collection('employes').document(serveur_commande_data['idE'])
                employee_doc = employee_ref.get()
                if employee_doc.exists:
                    employee_data = employee_doc.to_dict()
                    server_info = {
                        'id': serveur_commande_data['idE'],
                        'nom': employee_data.get('nomE', 'Unknown'),
                        'prenom': employee_data.get('prenomE', 'Unknown'),
                        'username': employee_data.get('usernameE', 'Unknown')
                    }
        
        # Format the response
        detailed_order = {
            'id': order_id,
            'montant': order_data.get('montant', 0.0),
            'calculated_total': round(total_calculated, 2),
            'dateCreation': order_data.get('dateCreation'),
            'etat': order_data.get('etat', 'Unknown'),
            'confirmation': order_data.get('confirmation', False),
            'client': client_info,
            'table': table_info,
            'server': server_info,
            'items': order_items,
            'items_count': len(order_items),
            'total_quantity': sum(item['quantity'] for item in order_items)
        }
        
        return JsonResponse(detailed_order, safe=False)
        
    except Exception as e:
        logger.error(f"Error fetching order details: {str(e)}")
        return JsonResponse({'error': str(e)}, status=500)

@api_view(['GET'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsStaff])
def get_all_plats(request):
    """
    Get all dishes (plats) with their ingredients and quantities
    Returns complete dish information including ingredients from plat_ingredients collection
    """
    try:
        plats_ref = db.collection('plats')
        all_plats = []
        
        for plat_doc in plats_ref.stream():
            plat_data = plat_doc.to_dict()
            plat_id = plat_doc.id
            
            # Get basic dish information
            plat_info = {
                'id': plat_id,
                'nom': plat_data.get('nom', 'Unknown'),
                'description': plat_data.get('description', ''),
                'prix': plat_data.get('prix', 0),
                'idCat': plat_data.get('idCat', ''),
                'idSousCat': plat_data.get('idSousCat', ''),
                'note': plat_data.get('note', 0),
                'estimation': plat_data.get('estimation', 0),
                'quantite': plat_data.get('quantite', 0),
                'ingredients': []
            }
            
            # Get category name
            if plat_info['idCat']:
                try:
                    cat_ref = db.collection('categories').document(plat_info['idCat'])
                    cat_doc = cat_ref.get()
                    if cat_doc.exists:
                        cat_data = cat_doc.to_dict()
                        plat_info['categorie'] = cat_data.get('nom', plat_info['idCat'])
                    else:
                        plat_info['categorie'] = plat_info['idCat']
                except Exception as e:
                    logger.warning(f"Error fetching category {plat_info['idCat']}: {str(e)}")
                    plat_info['categorie'] = plat_info['idCat']
            else:
                plat_info['categorie'] = 'Unknown'
            
            # Get subcategory name
            if plat_info['idSousCat']:
                try:
                    sous_cat_ref = db.collection('sous_categories').document(plat_info['idSousCat'])
                    sous_cat_doc = sous_cat_ref.get()
                    if sous_cat_doc.exists:
                        sous_cat_data = sous_cat_doc.to_dict()
                        plat_info['sous_categorie'] = sous_cat_data.get('nom', plat_info['idSousCat'])
                    else:
                        plat_info['sous_categorie'] = plat_info['idSousCat']
                except Exception as e:
                    logger.warning(f"Error fetching subcategory {plat_info['idSousCat']}: {str(e)}")
                    plat_info['sous_categorie'] = plat_info['idSousCat']
            else:
                plat_info['sous_categorie'] = 'Unknown'
            
            # Get ingredients from plat_ingredients collection
            try:
                plat_ingredients_ref = db.collection('plat_ingredients').where('idP', '==', plat_id)
                
                for ingredient_doc in plat_ingredients_ref.stream():
                    ingredient_data = ingredient_doc.to_dict()
                    
                    # Get ingredients array from the document
                    ingredients_array = ingredient_data.get('ingredients', [])
                    
                    for ingredient_item in ingredients_array:
                        if isinstance(ingredient_item, dict):
                            ingredient_name = ingredient_item.get('nom', 'Unknown')
                            ingredient_quantity = ingredient_item.get('quantite_g', 0)
                            
                            plat_info['ingredients'].append({
                                'nom': ingredient_name,
                                'quantite_g': ingredient_quantity
                            })
                        
            except Exception as e:
                logger.warning(f"Error fetching ingredients for plat {plat_id}: {str(e)}")
                plat_info['ingredients'] = []
            
            all_plats.append(plat_info)
        
        # Sort by name for consistent ordering
        all_plats.sort(key=lambda x: x['nom'])
        
        return JsonResponse({
            'plats': all_plats,
            'total_count': len(all_plats)
        }, safe=False)
        
    except Exception as e:
        logger.error(f"Error fetching all plats: {str(e)}", exc_info=True)
        return JsonResponse({'error': str(e)}, status=500)
    
