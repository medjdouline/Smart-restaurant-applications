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

# Ajoutez cette fonction à votre views.py après la fonction get_all_plats

@api_view(['POST'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsStaff])
@csrf_exempt
def add_plat(request):
    """
    Ajouter un nouveau plat avec ses ingrédients
    Crée un document dans 'plats' et un document dans 'plat_ingredients'
    """
    try:
        data = json.loads(request.body)
        
        # Validation des données requises
        required_fields = ['nom', 'description', 'prix', 'categorie', 'sous_categorie']
        for field in required_fields:
            if field not in data or not data[field]:
                return JsonResponse({'error': f'Le champ {field} est requis'}, status=400)
        
        ingredients_data = data.get('ingredients', [])
        if not ingredients_data:
            return JsonResponse({'error': 'Au moins un ingrédient est requis'}, status=400)
        
        # Validation des ingrédients
        for ingredient in ingredients_data:
            if not isinstance(ingredient, dict):
                return JsonResponse({'error': 'Format d\'ingrédient invalide'}, status=400)
            if 'nom' not in ingredient or 'quantite' not in ingredient or 'unite' not in ingredient:
                return JsonResponse({'error': 'Chaque ingrédient doit avoir un nom, une quantité et une unité'}, status=400)
        
        # Générer un nouvel ID pour le plat
        plats_ref = db.collection('plats')
        new_plat_ref = plats_ref.document()  # Génère automatiquement un ID
        plat_id = new_plat_ref.id
        
        # Préparer les données du plat
        plat_data = {
            'nom': data['nom'].strip(),
            'description': data['description'].strip(),
            'prix': float(data['prix']),
            'idCat': data['categorie'],
            'idSousCat': data['sous_categorie'],
            'note': 0,  # Note initiale
            'estimation': 0,  # Estimation initiale (temps de préparation)
            'quantite': 0,  # Quantité disponible initiale
            'createdAt': firestore.SERVER_TIMESTAMP
        }
        
        # Créer le document plat
        new_plat_ref.set(plat_data)
        logger.info(f"Plat créé avec l'ID: {plat_id}")
        
        # Préparer les données des ingrédients pour plat_ingredients
        ingredients_for_plat = []
        for ingredient in ingredients_data:
            ingredients_for_plat.append({
                'nom': ingredient['nom'],
                'quantite_g': float(ingredient['quantite']),
                'unite': ingredient['unite']
            })
        
        # Créer le document plat_ingredients
        plat_ingredients_data = {
            'idP': plat_id,
            'ingredients': ingredients_for_plat,
            'nom_du_plat': data['nom'].strip(),
            'createdAt': firestore.SERVER_TIMESTAMP
        }
        
        plat_ingredients_ref = db.collection('plat_ingredients').document(plat_id)
        plat_ingredients_ref.set(plat_ingredients_data)
        logger.info(f"Ingrédients du plat créés pour l'ID: {plat_id}")
        
        # Retourner la réponse de succès avec les données du plat créé
        response_data = {
            'message': 'Plat ajouté avec succès',
            'plat_id': plat_id,
            'plat': {
                'id': plat_id,
                'nom': plat_data['nom'],
                'description': plat_data['description'],
                'prix': plat_data['prix'],
                'categorie': plat_data['idCat'],
                'sous_categorie': plat_data['idSousCat'],
                'ingredients': ingredients_for_plat
            }
        }
        
        return JsonResponse(response_data, status=201)
        
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Format JSON invalide'}, status=400)
    except ValueError as e:
        return JsonResponse({'error': f'Erreur de validation: {str(e)}'}, status=400)
    except Exception as e:
        logger.error(f"Erreur lors de l'ajout du plat: {str(e)}", exc_info=True)
        return JsonResponse({'error': f'Erreur serveur: {str(e)}'}, status=500)
    
@api_view(['PUT'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsStaff])
@csrf_exempt
def update_plat(request, plat_id):
    """
    Modifier les informations de base d'un plat (nom, description, prix, catégorie, sous-catégorie)
    """
    try:
        data = json.loads(request.body)
        
        # Vérifier que le plat existe
        plat_ref = db.collection('plats').document(plat_id)
        plat_doc = plat_ref.get()
        
        if not plat_doc.exists:
            return JsonResponse({'error': 'Plat non trouvé'}, status=404)
        
        # Préparer les données à mettre à jour
        update_data = {}
        
        if 'nom' in data:
            update_data['nom'] = data['nom'].strip()
        if 'description' in data:
            update_data['description'] = data['description'].strip()
        if 'prix' in data:
            update_data['prix'] = float(data['prix'])
        if 'categorie' in data:
            update_data['idCat'] = data['categorie']
        if 'sous_categorie' in data:
            update_data['idSousCat'] = data['sous_categorie']
        
        if not update_data:
            return JsonResponse({'error': 'Aucune donnée à mettre à jour'}, status=400)
        
        # Ajouter la date de modification
        update_data['updatedAt'] = firestore.SERVER_TIMESTAMP
        
        # Mettre à jour le plat
        plat_ref.update(update_data)
        
        # Mettre à jour le nom dans plat_ingredients si le nom a changé
        if 'nom' in update_data:
            plat_ingredients_ref = db.collection('plat_ingredients').document(plat_id)
            plat_ingredients_doc = plat_ingredients_ref.get()
            if plat_ingredients_doc.exists:
                plat_ingredients_ref.update({
                    'nom_du_plat': update_data['nom'],
                    'updatedAt': firestore.SERVER_TIMESTAMP
                })
        
        logger.info(f"Plat {plat_id} mis à jour avec succès")
        
        return JsonResponse({
            'message': 'Plat mis à jour avec succès',
            'plat_id': plat_id,
            'updated_fields': list(update_data.keys())
        })
        
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Format JSON invalide'}, status=400)
    except ValueError as e:
        return JsonResponse({'error': f'Erreur de validation: {str(e)}'}, status=400)
    except Exception as e:
        logger.error(f"Erreur lors de la mise à jour du plat: {str(e)}", exc_info=True)
        return JsonResponse({'error': f'Erreur serveur: {str(e)}'}, status=500)


# 2. Modifier/Ajouter/Supprimer des ingrédients d'un plat
@api_view(['PUT'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsStaff])
@csrf_exempt
def update_plat_ingredients(request, plat_id):
    """
    Modifier la liste des ingrédients d'un plat
    Format attendu: {
        "action": "add|update|delete",
        "ingredient": {
            "nom": "nom_ingredient",
            "quantite": 100,
            "unite": "g"
        }
    }
    Ou pour remplacer toute la liste:
    {
        "action": "replace",
        "ingredients": [...]
    }
    """
    try:
        data = json.loads(request.body)
        action = data.get('action')
        
        if action not in ['add', 'update', 'delete', 'replace']:
            return JsonResponse({'error': 'Action non valide. Utilisez: add, update, delete, replace'}, status=400)
        
        # Vérifier que le plat existe
        plat_ref = db.collection('plats').document(plat_id)
        plat_doc = plat_ref.get()
        
        if not plat_doc.exists:
            return JsonResponse({'error': 'Plat non trouvé'}, status=404)
        
        # Récupérer le document plat_ingredients
        plat_ingredients_ref = db.collection('plat_ingredients').document(plat_id)
        plat_ingredients_doc = plat_ingredients_ref.get()
        
        if not plat_ingredients_doc.exists:
            # Créer le document s'il n'existe pas
            plat_data = plat_doc.to_dict()
            plat_ingredients_ref.set({
                'idP': plat_id,
                'nom_du_plat': plat_data.get('nom', 'Unknown'),
                'ingredients': [],
                'createdAt': firestore.SERVER_TIMESTAMP
            })
            current_ingredients = []
        else:
            plat_ingredients_data = plat_ingredients_doc.to_dict()
            current_ingredients = plat_ingredients_data.get('ingredients', [])
        
        if action == 'replace':
            # Remplacer toute la liste
            new_ingredients = data.get('ingredients', [])
            for ingredient in new_ingredients:
                if not all(key in ingredient for key in ['nom', 'quantite', 'unite']):
                    return JsonResponse({'error': 'Chaque ingrédient doit avoir nom, quantite et unite'}, status=400)
            
            plat_ingredients_ref.update({
                'ingredients': new_ingredients,
                'updatedAt': firestore.SERVER_TIMESTAMP
            })
            
            return JsonResponse({
                'message': 'Liste des ingrédients remplacée avec succès',
                'ingredients_count': len(new_ingredients)
            })
        
        # Pour les autres actions, traiter un ingrédient à la fois
        ingredient_data = data.get('ingredient')
        if not ingredient_data:
            return JsonResponse({'error': 'Données d\'ingrédient requises'}, status=400)
        
        ingredient_name = ingredient_data.get('nom')
        if not ingredient_name:
            return JsonResponse({'error': 'Nom d\'ingrédient requis'}, status=400)
        
        # Trouver l'ingrédient existant
        ingredient_index = -1
        for i, ing in enumerate(current_ingredients):
            if ing.get('nom') == ingredient_name:
                ingredient_index = i
                break
        
        if action == 'add':
            if ingredient_index >= 0:
                return JsonResponse({'error': 'Ingrédient déjà existant. Utilisez update pour le modifier'}, status=400)
            
            if not all(key in ingredient_data for key in ['quantite', 'unite']):
                return JsonResponse({'error': 'Quantité et unité requises pour ajouter un ingrédient'}, status=400)
            
            new_ingredient = {
                'nom': ingredient_name,
                'quantite_g': float(ingredient_data['quantite']),
                'unite': ingredient_data['unite']
            }
            current_ingredients.append(new_ingredient)
            
        elif action == 'update':
            if ingredient_index < 0:
                return JsonResponse({'error': 'Ingrédient non trouvé. Utilisez add pour l\'ajouter'}, status=400)
            
            # Mettre à jour les champs fournis
            if 'quantite' in ingredient_data:
                current_ingredients[ingredient_index]['quantite_g'] = float(ingredient_data['quantite'])
            if 'unite' in ingredient_data:
                current_ingredients[ingredient_index]['unite'] = ingredient_data['unite']
            
        elif action == 'delete':
            if ingredient_index < 0:
                return JsonResponse({'error': 'Ingrédient non trouvé'}, status=404)
            
            current_ingredients.pop(ingredient_index)
        
        # Mettre à jour le document
        plat_ingredients_ref.update({
            'ingredients': current_ingredients,
            'updatedAt': firestore.SERVER_TIMESTAMP
        })
        
        logger.info(f"Ingrédients du plat {plat_id} mis à jour: {action} - {ingredient_name}")
        
        return JsonResponse({
            'message': f'Ingrédient {action} avec succès',
            'ingredient': ingredient_name,
            'total_ingredients': len(current_ingredients)
        })
        
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Format JSON invalide'}, status=400)
    except ValueError as e:
        return JsonResponse({'error': f'Erreur de validation: {str(e)}'}, status=400)
    except Exception as e:
        logger.error(f"Erreur lors de la mise à jour des ingrédients: {str(e)}", exc_info=True)
        return JsonResponse({'error': f'Erreur serveur: {str(e)}'}, status=500)


# 3. Obtenir tous les ingrédients du stock
@api_view(['GET'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsStaff])
def get_all_ingredients_stock(request):
    """
    Obtenir tous les ingrédients du stock avec nom, catégorie, quantité, date d'expiration
    """
    try:
        ingredients_ref = db.collection('ingredients')
        all_ingredients = []
        
        for doc in ingredients_ref.stream():
            ingredient_data = doc.to_dict()
            
            # Extraire les informations pertinentes
            ingredient_info = {
                'id': doc.id,
                'nom': ingredient_data.get('nom', 'Unknown'),
                'categorie': ingredient_data.get('categorie', 'Unknown'),
                'quantite': ingredient_data.get('quantite', 0),
                'unite': ingredient_data.get('unite', ''),
                'date_expiration': ingredient_data.get('date_expiration', ''),
                'seuil_alerte': ingredient_data.get('seuil_alerte', 0),
                'cout_par_unite': ingredient_data.get('cout_par_unite', 0),
                'createdAt': ingredient_data.get('createdAt', ''),
                # Déterminer le statut basé sur la quantité et le seuil d'alerte
                'statut': 'Disponible'
            }
            
            # Calculer le statut
            current_quantity = ingredient_info['quantite']
            alert_threshold = ingredient_info['seuil_alerte']
            
            if current_quantity <= 0:
                ingredient_info['statut'] = 'Rupture de stock'
            elif current_quantity <= alert_threshold:
                ingredient_info['statut'] = 'Stock bas'
            else:
                ingredient_info['statut'] = 'Disponible'
            
            # Vérifier la date d'expiration si elle existe
            if ingredient_info['date_expiration']:
                try:
                    from datetime import datetime, timedelta
                    
                    # Convertir la date d'expiration en objet datetime
                    if isinstance(ingredient_info['date_expiration'], str):
                        exp_date = datetime.fromisoformat(ingredient_info['date_expiration'].replace('Z', '+00:00'))
                    else:
                        exp_date = ingredient_info['date_expiration']
                    
                    # Vérifier si l'ingrédient expire bientôt (dans les 7 jours)
                    now = datetime.now()
                    if exp_date < now:
                        ingredient_info['statut'] = 'Expiré'
                    elif (exp_date - now).days <= 7:
                        if ingredient_info['statut'] == 'Disponible':
                            ingredient_info['statut'] = 'Expire bientôt'
                            
                except Exception as date_error:
                    logger.warning(f"Erreur de parsing de date pour {ingredient_info['nom']}: {str(date_error)}")
            
            all_ingredients.append(ingredient_info)
        
        # Trier par nom pour un affichage cohérent
        all_ingredients.sort(key=lambda x: x['nom'].lower())
        
        # Statistiques
        total_ingredients = len(all_ingredients)
        available_count = sum(1 for ing in all_ingredients if ing['statut'] == 'Disponible')
        low_stock_count = sum(1 for ing in all_ingredients if ing['statut'] == 'Stock bas')
        out_of_stock_count = sum(1 for ing in all_ingredients if ing['statut'] == 'Rupture de stock')
        expiring_count = sum(1 for ing in all_ingredients if ing['statut'] == 'Expire bientôt')
        expired_count = sum(1 for ing in all_ingredients if ing['statut'] == 'Expiré')
        
        return JsonResponse({
            'ingredients': all_ingredients,
            'statistics': {
                'total': total_ingredients,
                'disponible': available_count,
                'stock_bas': low_stock_count,
                'rupture_stock': out_of_stock_count,
                'expire_bientot': expiring_count,
                'expire': expired_count
            }
        }, safe=False)
        
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des ingrédients: {str(e)}", exc_info=True)
        return JsonResponse({'error': str(e)}, status=500)
    
@api_view(['POST'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsStaff])
@csrf_exempt
def commencer_commande(request, order_id):
    """
    Commencer une commande : 
    - Change l'état de 'en_attente' à 'en_preparation'
    - Diminue les quantités d'ingrédients selon les plats commandés
    - Crée une notification pour le client
    """
    try:
        # 1. Vérifier que la commande existe et est en attente
        commande_ref = db.collection('commandes').document(order_id)
        commande_doc = commande_ref.get()
        
        if not commande_doc.exists:
            return JsonResponse({'error': 'Commande non trouvée'}, status=404)
        
        commande_data = commande_doc.to_dict()
        
        if commande_data.get('etat') != 'en_attente':
            return JsonResponse({
                'error': f'La commande doit être en attente pour être commencée. État actuel: {commande_data.get("etat")}'
            }, status=400)
        
        # 2. Récupérer les plats de la commande depuis commandes_plat
        commandes_plat_query = db.collection('commandes_plat').where('idCmd', '==', order_id)
        commandes_plat_docs = commandes_plat_query.stream()
        
        plats_commandes = []
        for doc in commandes_plat_docs:
            plat_data = doc.to_dict()
            plats_commandes.append({
                'idP': plat_data.get('idP'),
                'quantite': plat_data.get('quantite', 1)
            })
        
        if not plats_commandes:
            return JsonResponse({'error': 'Aucun plat trouvé pour cette commande'}, status=400)
        
        # 3. Pour chaque plat, récupérer ses ingrédients et calculer les quantités totales nécessaires
        ingredients_totaux = {}  # {nom_ingredient: quantite_totale_necessaire}
        
        for plat_commande in plats_commandes:
            plat_id = plat_commande['idP']
            quantite_plat = plat_commande['quantite']
            
            # Récupérer les ingrédients du plat
            plat_ingredients_ref = db.collection('plat_ingredients').document(plat_id)
            plat_ingredients_doc = plat_ingredients_ref.get()
            
            if plat_ingredients_doc.exists:
                plat_ingredients_data = plat_ingredients_doc.to_dict()
                ingredients_plat = plat_ingredients_data.get('ingredients', [])
                
                for ingredient in ingredients_plat:
                    nom_ingredient = ingredient.get('nom')
                    quantite_unitaire = ingredient.get('quantite_g', 0)
                    
                    if nom_ingredient:
                        quantite_totale = quantite_unitaire * quantite_plat
                        
                        if nom_ingredient in ingredients_totaux:
                            ingredients_totaux[nom_ingredient] += quantite_totale
                        else:
                            ingredients_totaux[nom_ingredient] = quantite_totale
        
        # 4. Récupérer tous les ingrédients disponibles pour comparaison par nom
        ingredients_collection = db.collection('ingredients').stream()
        ingredients_disponibles = {}  # {nom_ingredient: {ref: doc_ref, data: doc_data}}
        
        for ingredient_doc in ingredients_collection:
            ingredient_data = ingredient_doc.to_dict()
            nom_ingredient = ingredient_data.get('nom')
            if nom_ingredient:
                ingredients_disponibles[nom_ingredient] = {
                    'ref': ingredient_doc.reference,
                    'data': ingredient_data
                }
        
        # 5. Vérifier la disponibilité des ingrédients avant de les diminuer
        ingredients_insuffisants = []
        
        for nom_ingredient, quantite_necessaire in ingredients_totaux.items():
            if nom_ingredient in ingredients_disponibles:
                quantite_disponible = ingredients_disponibles[nom_ingredient]['data'].get('quantite', 0)
                
                if quantite_disponible < quantite_necessaire:
                    ingredients_insuffisants.append({
                        'nom': nom_ingredient,
                        'disponible': quantite_disponible,
                        'necessaire': quantite_necessaire
                    })
            else:
                ingredients_insuffisants.append({
                    'nom': nom_ingredient,
                    'disponible': 0,
                    'necessaire': quantite_necessaire
                })
        
        if ingredients_insuffisants:
            return JsonResponse({
                'error': 'Stock insuffisant pour certains ingrédients',
                'ingredients_insuffisants': ingredients_insuffisants
            }, status=400)
        
        # 6. Commencer une transaction pour garantir la cohérence
        batch = db.batch()
        
        # 6a. Changer l'état de la commande
        batch.update(commande_ref, {
            'etat': 'en_preparation',
            'dateModification': firestore.SERVER_TIMESTAMP
        })
        
        # 6b. Diminuer les quantités d'ingrédients (comparaison par nom)
        for nom_ingredient, quantite_necessaire in ingredients_totaux.items():
            if nom_ingredient in ingredients_disponibles:
                ingredient_ref = ingredients_disponibles[nom_ingredient]['ref']
                ingredient_data = ingredients_disponibles[nom_ingredient]['data']
                nouvelle_quantite = ingredient_data.get('quantite', 0) - quantite_necessaire
                
                batch.update(ingredient_ref, {
                    'quantite': max(0, nouvelle_quantite),  # S'assurer que la quantité ne soit pas négative
                    'updatedAt': firestore.SERVER_TIMESTAMP
                })
        
        # 6c. Créer une notification pour le client
        client_id = commande_data.get('idC')  # ID du client depuis la commande
        
        if client_id:
            notification_ref = db.collection('notifications').document()
            notification_data = {
                'title': 'Commande en préparation',
                'message': f'Votre commande #{order_id} est maintenant en cours de préparation. Nos chefs s\'en occupent !',
                'type': 'order_preparation',
                'priority': 'normal',
                'read': False,
                'recipient_id': client_id,
                'recipient_type': 'client',
                'created_at': firestore.SERVER_TIMESTAMP,
                'order_id': order_id
            }
            batch.set(notification_ref, notification_data)
        
        # 7. Exécuter toutes les opérations
        batch.commit()
        
        logger.info(f"Commande {order_id} commencée avec succès")
        
        # 8. Préparer la réponse
        response_data = {
            'message': 'Commande commencée avec succès',
            'order_id': order_id,
            'etat': 'en_preparation',
            'ingredients_utilises': [
                {
                    'nom': nom,
                    'quantite_utilisee': quantite
                }
                for nom, quantite in ingredients_totaux.items()
            ]
        }
        
        if client_id:
            response_data['notification_envoyee'] = True
            response_data['client_id'] = client_id
        
        return JsonResponse(response_data, status=200)
        
    except Exception as e:
        logger.error(f"Erreur lors du commencement de la commande {order_id}: {str(e)}", exc_info=True)
        return JsonResponse({'error': f'Erreur serveur: {str(e)}'}, status=500)

@api_view(['POST'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsStaff])
@csrf_exempt
def terminer_commande(request, order_id):
    """
    Terminer une commande :
    - Change l'état de 'en_preparation' à 'pret'
    - Envoie une notification au client que la commande est prête
    - Envoie une notification au serveur pour le service
    - Vérifie les alertes d'ingrédients (expiration, stock faible)
    """
    try:
        # 1. Vérifier que la commande existe et est en préparation
        commande_ref = db.collection('commandes').document(order_id)
        commande_doc = commande_ref.get()
        
        if not commande_doc.exists:
            return JsonResponse({'error': 'Commande non trouvée'}, status=404)
        
        commande_data = commande_doc.to_dict()
        
        if commande_data.get('etat') != 'en_preparation':
            return JsonResponse({
                'error': f'La commande doit être en préparation pour être terminée. État actuel: {commande_data.get("etat")}'
            }, status=400)
        
        client_id = commande_data.get('idC')
        table_id = commande_data.get('idTable')
        
        # 2. Commencer une transaction
        batch = db.batch()
        
        # 2a. Changer l'état de la commande à 'pret'
        batch.update(commande_ref, {
            'etat': 'pret',
            'dateModification': firestore.SERVER_TIMESTAMP
        })
        
        # 2b. Créer une notification pour le client
        if client_id:
            client_notification_ref = db.collection('notifications').document()
            client_notification_data = {
                'title': 'Commande prête !',
                'message': f'Votre commande est prête ! Un serveur va bientôt vous l\'apporter.',
                'type': 'order_ready',
                'priority': 'high',
                'read': False,
                'recipient_id': client_id,
                'recipient_type': 'client',
                'created_at': firestore.SERVER_TIMESTAMP,
                'related_id': order_id
            }
            batch.set(client_notification_ref, client_notification_data)
        
        # 2c. Créer une notification pour le serveur
        serveur_notification_ref = db.collection('notifications').document()
        serveur_notification_data = {
            'title': 'Commande prête',
            'message': f'La commande pour la table {table_id} est prête à être servie.',
            'type': 'order_ready',
            'priority': 'high',
            'read': False,
            'recipient_id': 'employe1',  # Vous pouvez adapter selon votre système
            'recipient_type': 'serveur',
            'created_at': firestore.SERVER_TIMESTAMP,
            'related_id': order_id
        }
        batch.set(serveur_notification_ref, serveur_notification_data)
        
        # 3. Exécuter la transaction
        batch.commit()
        
        # 4. Vérifier les alertes d'ingrédients après la commande
        alertes_ingredients = []
        
        # Récupérer tous les ingrédients pour vérification
        ingredients_query = db.collection('ingredients').stream()
        
        for ingredient_doc in ingredients_query:
            ingredient_data = ingredient_doc.to_dict()
            nom_ingredient = ingredient_doc.id
            
            quantite = ingredient_data.get('quantite', 0)
            seuil_alerte = ingredient_data.get('seuil_alerte', 1)
            date_expiration_str = ingredient_data.get('date_expiration')
            
            # Vérifier le stock faible
            if quantite <= seuil_alerte:
                alertes_ingredients.append({
                    'nom': nom_ingredient,
                    'type': 'stock_faible',
                    'quantite_actuelle': quantite,
                    'seuil': seuil_alerte
                })
            
            # Vérifier la date d'expiration
            if date_expiration_str:
                try:
                    from datetime import datetime, timedelta
                    date_expiration = datetime.strptime(date_expiration_str, '%Y-%m-%d')
                    aujourd_hui = datetime.now()
                    difference = (date_expiration - aujourd_hui).days
                    
                    if difference < 0:
                        alertes_ingredients.append({
                            'nom': nom_ingredient,
                            'type': 'expire',
                            'date_expiration': date_expiration_str,
                            'jours_expires': abs(difference)
                        })
                    elif difference <= 2:  # Proche d'expirer (2 jours ou moins)
                        alertes_ingredients.append({
                            'nom': nom_ingredient,
                            'type': 'proche_expiration',
                            'date_expiration': date_expiration_str,
                            'jours_restants': difference
                        })
                except ValueError:
                    pass  # Format de date invalide, ignorer
        
        # 5. Envoyer des notifications d'alerte au cuisinier si nécessaire
        if alertes_ingredients:
            for alerte in alertes_ingredients:
                alerte_notification_ref = db.collection('notifications').document()
                
                if alerte['type'] == 'stock_faible':
                    message = f"Stock faible pour {alerte['nom']}: {alerte['quantite_actuelle']} restant(s) (seuil: {alerte['seuil']})"
                    title = "Alerte stock faible"
                elif alerte['type'] == 'expire':
                    message = f"Ingrédient expiré: {alerte['nom']} (expiré depuis {alerte['jours_expires']} jour(s))"
                    title = "Ingrédient expiré"
                else:  # proche_expiration
                    message = f"Ingrédient bientôt expiré: {alerte['nom']} (expire dans {alerte['jours_restants']} jour(s))"
                    title = "Expiration proche"
                
                alerte_notification_data = {
                    'title': title,
                    'message': message,
                    'type': 'ingredient_alert',
                    'priority': 'high' if alerte['type'] == 'expire' else 'normal',
                    'read': False,
                    'recipient_id': request.user.uid,  # Le cuisinier actuel
                    'recipient_type': 'chef',
                    'created_at': firestore.SERVER_TIMESTAMP
                }
                alerte_notification_ref.set(alerte_notification_data)
        
        logger.info(f"Commande {order_id} terminée avec succès")
        
        # 6. Préparer la réponse
        response_data = {
            'message': 'Commande terminée avec succès',
            'order_id': order_id,
            'etat': 'pret',
            'notifications_envoyees': {
                'client': bool(client_id),
                'serveur': True
            }
        }
        
        if alertes_ingredients:
            response_data['alertes_ingredients'] = alertes_ingredients
            response_data['alertes_envoyees'] = len(alertes_ingredients)
        
        return JsonResponse(response_data, status=200)
        
    except Exception as e:
        logger.error(f"Erreur lors de la finalisation de la commande {order_id}: {str(e)}", exc_info=True)
        return JsonResponse({'error': f'Erreur serveur: {str(e)}'}, status=500)


@api_view(['POST'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsStaff])
@csrf_exempt
def notifier_commande_annulee(request, order_id):
    """
    Notifier le cuisinier qu'une commande a été annulée
    Cette API est appelée quand l'état d'une commande passe à 'annulee'
    """
    try:
        # 1. Vérifier que la commande existe et est annulée
        commande_ref = db.collection('commandes').document(order_id)
        commande_doc = commande_ref.get()
        
        if not commande_doc.exists:
            return JsonResponse({'error': 'Commande non trouvée'}, status=404)
        
        commande_data = commande_doc.to_dict()
        
        if commande_data.get('etat') != 'annulee':
            return JsonResponse({
                'error': f'La commande doit être annulée. État actuel: {commande_data.get("etat")}'
            }, status=400)
        
        table_id = commande_data.get('idTable')
        client_id = commande_data.get('idC')
        
        # 2. Créer une notification pour le cuisinier
        notification_ref = db.collection('notifications').document()
        notification_data = {
            'title': 'Commande annulée',
            'message': f'La commande #{order_id} pour la table {table_id} a été annulée par le client.',
            'type': 'order_cancelled',
            'priority': 'normal',
            'read': False,
            'recipient_id': 'chef1',  # Adapter selon votre système d'identification des chefs
            'recipient_type': 'chef',
            'created_at': firestore.SERVER_TIMESTAMP,
            'related_id': order_id
        }
        
        notification_ref.set(notification_data)
        
        logger.info(f"Notification d'annulation envoyée pour la commande {order_id}")
        
        return JsonResponse({
            'message': 'Notification d\'annulation envoyée au cuisinier',
            'order_id': order_id,
            'notification_envoyee': True
        }, status=200)
        
    except Exception as e:
        logger.error(f"Erreur lors de l'envoi de la notification d'annulation pour {order_id}: {str(e)}", exc_info=True)
        return JsonResponse({'error': f'Erreur serveur: {str(e)}'}, status=500)


# Fonction utilitaire pour vérifier les alertes d'ingrédients (peut être appelée séparément)
@api_view(['GET'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsStaff])
def verifier_alertes_ingredients(request):
    """
    API pour vérifier manuellement toutes les alertes d'ingrédients
    """
    try:
        alertes = []
        ingredients_query = db.collection('ingredients').stream()
        
        for ingredient_doc in ingredients_query:
            ingredient_data = ingredient_doc.to_dict()
            nom_ingredient = ingredient_doc.id
            
            quantite = ingredient_data.get('quantite', 0)
            seuil_alerte = ingredient_data.get('seuil_alerte', 1)
            date_expiration_str = ingredient_data.get('date_expiration')
            
            # Vérifier le stock faible
            if quantite <= seuil_alerte:
                alertes.append({
                    'nom': nom_ingredient,
                    'type': 'stock_faible',
                    'quantite_actuelle': quantite,
                    'seuil': seuil_alerte,
                    'severity': 'high' if quantite == 0 else 'medium'
                })
            
            # Vérifier la date d'expiration
            if date_expiration_str:
                try:
                    from datetime import datetime
                    date_expiration = datetime.strptime(date_expiration_str, '%Y-%m-%d')
                    aujourd_hui = datetime.now()
                    difference = (date_expiration - aujourd_hui).days
                    
                    if difference < 0:
                        alertes.append({
                            'nom': nom_ingredient,
                            'type': 'expire',
                            'date_expiration': date_expiration_str,
                            'jours_expires': abs(difference),
                            'severity': 'critical'
                        })
                    elif difference <= 2:
                        alertes.append({
                            'nom': nom_ingredient,
                            'type': 'proche_expiration',
                            'date_expiration': date_expiration_str,
                            'jours_restants': difference,
                            'severity': 'medium'
                        })
                except ValueError:
                    pass
        
        return JsonResponse({
            'alertes': alertes,
            'nombre_total': len(alertes),
            'critique': len([a for a in alertes if a.get('severity') == 'critical']),
            'important': len([a for a in alertes if a.get('severity') == 'high']),
            'moyen': len([a for a in alertes if a.get('severity') == 'medium'])
        })
        
    except Exception as e:
        logger.error(f"Erreur lors de la vérification des alertes: {str(e)}", exc_info=True)
        return JsonResponse({'error': f'Erreur serveur: {str(e)}'}, status=500)
    

@api_view(['PUT'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsStaff])
@csrf_exempt
def annuler_commande(request, order_id):
    """
    Annuler une commande par le chef
    La commande doit être en statut 'en_attente' ou 'en_preparation'
    Envoie une notification au client
    """
    try:
        data = json.loads(request.body)
        motif_annulation = data.get('motif', 'Annulée par la cuisine')
        
        # Récupérer la commande
        order_ref = db.collection('commandes').document(order_id)
        order_doc = order_ref.get()
        
        if not order_doc.exists:
            return JsonResponse({'error': 'Commande non trouvée'}, status=404)
        
        order_data = order_doc.to_dict()
        current_status = order_data.get('etat', '').lower()
        
        # Vérifier si la commande peut être annulée
        allowed_statuses = ['en_attente', 'en attente', 'pending', 'en_preparation', 'en preparation', 'preparing']
        if current_status not in allowed_statuses:
            return JsonResponse({
                'error': f'Impossible d\'annuler une commande avec le statut: {current_status}. '
                         'Seules les commandes en attente ou en préparation peuvent être annulées.'
            }, status=400)
        
        # Mettre à jour le statut de la commande
        order_ref.update({
            'etat': 'annulee',
            'date_annulation': firestore.SERVER_TIMESTAMP,
            'motif_annulation': motif_annulation,
            'annulee_par': 'cuisine'
        })
        
        # Récupérer les informations du client
        client_id = order_data.get('idC')
        if not client_id:
            logger.warning(f"Aucun client trouvé pour la commande {order_id}")
            return JsonResponse({
                'message': 'Commande annulée avec succès',
                'warning': 'Impossible d\'envoyer la notification: client non trouvé'
            })
        
        # Créer la notification pour le client
        try:
            notification_data = {
                'title': 'Commande annulée',
                'message': f'Votre commande #{order_id} a été annulée par la cuisine. '
                          f'Motif: {motif_annulation}. '
                          'Veuillez demander de l\'assistance pour plus d\'informations.',
                'type': 'order_cancelled',
                'priority': 'high',
                'recipient_type': 'client',
                'recipient_id': client_id,
                'related_id': order_id,
                'read': False,
                'created_at': firestore.SERVER_TIMESTAMP
            }
            
            # Ajouter la notification à la collection
            db.collection('notifications').add(notification_data)
            logger.info(f"Notification d'annulation envoyée au client {client_id} pour la commande {order_id}")
            
        except Exception as e:
            logger.error(f"Erreur lors de l'envoi de la notification: {str(e)}")
            return JsonResponse({
                'message': 'Commande annulée avec succès',
                'warning': f'Erreur lors de l\'envoi de la notification: {str(e)}'
            })
        
        # Libérer la table si elle est associée
        try:
            table_id = order_data.get('idTable')
            if table_id:
                table_ref = db.collection('tables').document(table_id)
                table_doc = table_ref.get()
                if table_doc.exists:
                    table_ref.update({'etatTable': 'libre'})
                    logger.info(f"Table {table_id} libérée suite à l'annulation de la commande {order_id}")
        except Exception as e:
            logger.warning(f"Erreur lors de la libération de la table: {str(e)}")
        
        # Enregistrer l'action du chef
        try:
            user = request.user
            chef_id = user.uid
            
            # Récupérer l'ID employé du chef
            employees_ref = db.collection('employes').where('firebase_uid', '==', chef_id).limit(1)
            employees_docs = list(employees_ref.stream())
            
            if employees_docs:
                employee_id = employees_docs[0].id
                
                # Enregistrer l'action dans un log (optionnel)
                action_log = {
                    'action': 'annulation_commande',
                    'order_id': order_id,
                    'chef_id': employee_id,
                    'motif': motif_annulation,
                    'timestamp': firestore.SERVER_TIMESTAMP,
                    'previous_status': current_status
                }
                db.collection('chef_actions').add(action_log)
                
        except Exception as e:
            logger.warning(f"Erreur lors de l'enregistrement de l'action: {str(e)}")
        
        # Réponse de succès
        return JsonResponse({
            'message': 'Commande annulée avec succès',
            'order_id': order_id,
            'previous_status': current_status,
            'new_status': 'annulee',
            'motif': motif_annulation,
            'notification_sent': True
        })
        
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Format JSON invalide'}, status=400)
    except Exception as e:
        logger.error(f"Erreur lors de l'annulation de la commande {order_id}: {str(e)}", exc_info=True)
        return JsonResponse({'error': str(e)}, status=500)
    
@api_view(['GET'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsStaff])
def get_plats_by_categorie(request, categorie_id):
    """
    Récupérer tous les plats d'une catégorie spécifique
    """
    try:
        # Vérifier que la catégorie existe
        categorie_ref = db.collection('categories').document(categorie_id)
        categorie_doc = categorie_ref.get()
        
        if not categorie_doc.exists:
            return JsonResponse({'error': 'Catégorie non trouvée'}, status=404)
        
        # Récupérer les plats de cette catégorie
        plats_ref = db.collection('plats').where('idCat', '==', categorie_id)
        plats = []
        
        for plat_doc in plats_ref.stream():
            plat_data = plat_doc.to_dict()
            plat_data['id'] = plat_doc.id
            plats.append(plat_data)
        
        # Récupérer le nom de la catégorie
        categorie_data = categorie_doc.to_dict()
        
        return JsonResponse({
            'categorie_id': categorie_id,
            'categorie_nom': categorie_data.get('nom', 'Unknown'),
            'plats': plats,
            'count': len(plats)
        }, safe=False)
        
    except Exception as e:
        logger.error(f"Error fetching plats by categorie: {str(e)}", exc_info=True)
        return JsonResponse({'error': str(e)}, status=500)

@api_view(['GET'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsStaff])
def get_plats_by_sous_categorie(request, sous_categorie_id):
    """
    Récupérer tous les plats d'une sous-catégorie spécifique
    """
    try:
        # Vérifier que la sous-catégorie existe
        sous_categorie_ref = db.collection('sous_categories').document(sous_categorie_id)
        sous_categorie_doc = sous_categorie_ref.get()
        
        if not sous_categorie_doc.exists:
            return JsonResponse({'error': 'Sous-catégorie non trouvée'}, status=404)
        
        # Récupérer les plats de cette sous-catégorie
        plats_ref = db.collection('plats').where('idSousCat', '==', sous_categorie_id)
        plats = []
        
        for plat_doc in plats_ref.stream():
            plat_data = plat_doc.to_dict()
            plat_data['id'] = plat_doc.id
            plats.append(plat_data)
        
        # Récupérer le nom de la sous-catégorie
        sous_categorie_data = sous_categorie_doc.to_dict()
        
        return JsonResponse({
            'sous_categorie_id': sous_categorie_id,
            'sous_categorie_nom': sous_categorie_data.get('nom', 'Unknown'),
            'plats': plats,
            'count': len(plats)
        }, safe=False)
        
    except Exception as e:
        logger.error(f"Error fetching plats by sous-categorie: {str(e)}", exc_info=True)
        return JsonResponse({'error': str(e)}, status=500)