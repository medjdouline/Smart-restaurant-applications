from django.shortcuts import render
from django.http import JsonResponse
from django.views.decorators.http import require_http_methods
from django.views.decorators.csrf import csrf_exempt
from rest_framework.decorators import api_view, authentication_classes, permission_classes
import json
from firebase_admin import firestore
from core.firebase_utils import firebase_config
from core.authentication import authenticate_firebase_user, FirebaseAuthentication
from core.orders_utils import get_all_orders, get_orders_by_status
from core.permissions import IsServer
import logging
from datetime import datetime

logger = logging.getLogger(__name__)

# Get Firestore db instance
db = firebase_config.get_db()

@api_view(['GET'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsServer])
def get_server_profile(request):
    """Get server profile information"""
    try:
        # User is already authenticated by FirebaseAuthentication
        user = request.user
        user_id = user.uid
        
        # First, check if the user ID directly matches a document ID
        server_ref = db.collection('employes').document(user_id)
        server_doc = server_ref.get()
        
        if not server_doc.exists:
            # If not, try to query by firebase_uid field
            employees_ref = db.collection('employes').where('firebase_uid', '==', user_id).limit(1)
            employees_docs = list(employees_ref.stream())
            
            if not employees_docs:
                return JsonResponse({'error': 'Server profile not found'}, status=404)
                
            server_doc = employees_docs[0]
            employee_id = server_doc.id
        else:
            employee_id = user_id
            
        server_data = server_doc.to_dict()
        
        # Don't return sensitive data like password
        if 'motDePasseE' in server_data:
            del server_data['motDePasseE']
        
        # Fetch additional info from serveurs collection if exists
        serveur_ref = db.collection('serveurs').where('idE', '==', employee_id).limit(1)
        serveur_docs = serveur_ref.stream()
        serveur_info = next((doc.to_dict() for doc in serveur_docs), {})
        
        # Count orders handled
        serveur_commande_ref = db.collection('serveur_commande').where('idE', '==', employee_id)
        commandes_count = len(list(serveur_commande_ref.stream()))
        
        response = {
            'profile': server_data,

        }
        return JsonResponse(response, safe=False)
    except Exception as e:
        logger.error(f"Error fetching server profile: {str(e)}")
        return JsonResponse({'error': str(e)}, status=500)


@api_view(['PUT'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsServer])
@csrf_exempt
def update_password(request):
    """Update user password in Firebase Authentication"""
    try:
        data = json.loads(request.body)
        user_id = request.user.uid
        current_password = data.get('current_password')
        new_password = data.get('new_password')
        
        logger.info(f"Attempting password update for Firebase UID: {user_id}")
        
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
            
        logger.info(f"Retrieved email for user: {user_email}")
        
        # Since Firebase Admin SDK doesn't provide password verification,
        # we directly update the password
        try:
            from firebase_admin import auth
            
            # Update the user's password
            auth.update_user(
                user_id,
                password=new_password
            )
            logger.info(f"Password updated successfully for user: {user_id}")
            
            return JsonResponse({'message': 'Password updated successfully'})
            
        except auth.FirebaseError as auth_error:
            logger.error(f"Firebase Auth error: {str(auth_error)}")
            return JsonResponse({'error': f'Password update error: {str(auth_error)}'}, status=500)
    except Exception as e:
        logger.error(f"Error updating password: {str(e)}")
        return JsonResponse({'error': str(e)}, status=500)
# Helper function to get orders with proper filtering

@api_view(['GET'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsServer])
def get_all_orders_view(request):
    """Get all orders"""
    try:
        orders = get_all_orders(db)
        return JsonResponse(orders, safe=False)
    except Exception as e:
        logger.error(f"Error in get_all_orders_view: {str(e)}", exc_info=True)
        return JsonResponse({'error': str(e)}, status=500)

@api_view(['GET'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsServer])
def get_pending_orders_view(request):
    """Get orders with status 'en attente'"""
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
@permission_classes([IsServer])
def get_preparing_orders_view(request):
    """Get orders with status 'en preparation'"""
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
@permission_classes([IsServer])
def get_ready_orders_view(request):
    """Get orders with status 'pret'"""
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
@permission_classes([IsServer])
def get_served_orders_view(request):
    """Get orders with status 'servi' or 'servie'"""
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
@permission_classes([IsServer])
def get_cancelled_orders_view(request):
    """Get orders with status 'annulee'"""
    try:
        # Handle all cancelled status variants
        status_values = ['annule', 'annulee', 'cancelled']
        orders = get_orders_by_status(status_values, db)
        return JsonResponse(orders, safe=False)
    except Exception as e:
        logger.error(f"Error in get_cancelled_orders_view: {str(e)}", exc_info=True)
        return JsonResponse({'error': str(e)}, status=500)
    
@api_view(['PUT'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsServer])
def update_order_status(request, order_id):
    """Update the status of an order"""
    try:
        # Get the order document
        order_ref = db.collection('commandes').document(order_id)
        order_doc = order_ref.get()
        
        if not order_doc.exists:
            return JsonResponse({'error': 'Order not found'}, status=404)
        
        # Get the new status from request data
        data = json.loads(request.body)
        new_status = data.get('status')
        
        if not new_status:
            return JsonResponse({'error': 'Status is required'}, status=400)
        
        # Update the order status
        order_ref.update({'etat': new_status})
        
        # Return success response
        return JsonResponse({'message': 'Order status updated successfully'})
    except Exception as e:
        logger.error(f"Error updating order status: {str(e)}")
        return JsonResponse({'error': str(e)}, status=500)
    
@api_view(['POST'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsServer])
@csrf_exempt
def cancel_order(request, order_id):
    """Cancel an order if its status is 'en_attente'"""
    try:
        # Get the order document
        order_ref = db.collection('commandes').document(order_id)
        order_doc = order_ref.get()
        
        if not order_doc.exists:
            return JsonResponse({'error': 'Order not found'}, status=404)
        
        order_data = order_doc.to_dict()
        
        # Check if order status is "en_attente"
        if order_data.get('etat') not in ['en_attente', 'en attente', 'pending']:
            return JsonResponse({
                'error': 'Only orders with status "en_attente" can be directly cancelled'
            }, status=400)
        
        # Update the order status to "annulee"
        order_ref.update({'etat': 'annulee'})
        
        # Log the cancellation
        logger.info(f"Order {order_id} cancelled by server {request.user.uid}")
        
        # Return success response
        return JsonResponse({
            'message': 'Order cancelled successfully',
            'order_id': order_id
        })
    except Exception as e:
        logger.error(f"Error cancelling order: {str(e)}")
        return JsonResponse({'error': str(e)}, status=500)

@api_view(['POST'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsServer])
@csrf_exempt
def request_cancel_order(request, order_id):
    """Request cancellation for an order if its status is 'en_preparation' or 'pret'"""
    try:
        # Get the order document
        order_ref = db.collection('commandes').document(order_id)
        order_doc = order_ref.get()
        
        if not order_doc.exists:
            return JsonResponse({'error': 'Order not found'}, status=404)
        
        order_data = order_doc.to_dict()
        
        # Check if order status is eligible for cancellation request
        valid_statuses = ['en_preparation', 'en preparation', 'preparing', 'pret', 'prete', 'ready']
        if order_data.get('etat') not in valid_statuses:
            return JsonResponse({
                'error': 'Only orders with status "en_preparation" or "pret" can request cancellation'
            }, status=400)
        
        # Create a cancellation request in the DemandeAnnulation collection
        demande_ref = db.collection('DemandeAnnulation').document()
        demande_ref.set({
            'idClient': order_data.get('idC'),
            'idServeur': request.user.uid,
            'idCommande': order_id,
            'motif': 'Demande d\'annulation par serveur',  # Défaut sans corps
            'statut': 'en_attente',
            'createdAt': firestore.SERVER_TIMESTAMP
        })
        
        # Create notification for manager - nous ciblons tous les managers
        notification_ref = db.collection('notifications').document()
        notification_ref.set({
            'recipient_type': 'manager',  # Tous les managers verront cette notification
            'title': 'Nouvelle demande d\'annulation',
            'message': f'Demande d\'annulation pour la commande {order_id}',
            'created_at': firestore.SERVER_TIMESTAMP,
            'read': False,
            'type': 'cancellation_request',
            'priority': 'high',
            'related_id': demande_ref.id
        })
        
        # Log the cancellation request
        logger.info(f"Cancellation request for order {order_id} created by server {request.user.uid}")
        
        # Return success response
        return JsonResponse({
            'message': 'Cancellation request submitted successfully',
            'request_id': demande_ref.id,
            'order_id': order_id
        })
    except Exception as e:
        logger.error(f"Error creating cancellation request: {str(e)}")
        return JsonResponse({'error': str(e)}, status=500)

@api_view(['GET'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsServer])
def get_assistance_requests(request):
    """Get all assistance requests"""
    try:
        # Use the correct collection name from your schema
        assistance_requests = []
        # Query the demandeAssistance collection, ordering by creation time
        assistance_ref = db.collection('demandeAssistance').order_by('createdAt', direction=firestore.Query.DESCENDING)
        
        for doc in assistance_ref.stream():
            assistance_data = doc.to_dict()
            assistance_data['id'] = doc.id
            
            # Get client info if it exists
            if 'idC' in assistance_data:
                client_ref = db.collection('clients').document(assistance_data['idC'])
                client_doc = client_ref.get()
                if client_doc.exists:
                    client_data = client_doc.to_dict()
                    assistance_data['client'] = {
                        'username': client_data.get('username', 'Unknown')
                    }
            
            # Get table info if it exists
            if 'idTable' in assistance_data:
                table_ref = db.collection('tables').document(assistance_data['idTable'])
                table_doc = table_ref.get()
                if table_doc.exists:
                    table_data = table_doc.to_dict()
                    assistance_data['table'] = {
                        'id': assistance_data['idTable'],
                        'nbrPersonne': table_data.get('nbrPersonne', 0)
                    }
            
            # Map the fields to match the expected format in the app
            formatted_request = {
                'id': doc.id,
                'tableId': assistance_data.get('idTable', ''),
                'userId': assistance_data.get('idC', ''),
                'createdAt': assistance_data.get('createdAt', firestore.SERVER_TIMESTAMP),
                'status': assistance_data.get('etat', 'non traitee'),
                'client': assistance_data.get('client', {'username': 'Unknown'}),
                'table': assistance_data.get('table', {'id': '', 'nbrPersonne': 0})
            }
            
            assistance_requests.append(formatted_request)
        
        return JsonResponse(assistance_requests, safe=False)
    except Exception as e:
        logger.error(f"Error fetching assistance requests: {str(e)}")
        return JsonResponse({'error': str(e)}, status=500)

@api_view(['PUT'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsServer])
@csrf_exempt
def complete_assistance_request(request, request_id):
    """Mark an assistance request as completed"""
    try:
        assistance_ref = db.collection('demandeAssistance').document(request_id)
        assistance_doc = assistance_ref.get()
        
        if not assistance_doc.exists:
            return JsonResponse({'error': 'Assistance request not found'}, status=404)
        
        # Update request status - using etat field to match your schema
        assistance_ref.update({
            'etat': 'traitee',
            'completedBy': request.user.uid,
            'completedAt': firestore.SERVER_TIMESTAMP
        })
        
        return JsonResponse({
            'message': 'Assistance request marked as completed',
            'id': request_id
        })
    except Exception as e:
        logger.error(f"Error completing assistance request: {str(e)}")
        return JsonResponse({'error': str(e)}, status=500)

@api_view(['GET'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsServer])
def get_dashboard(request):
    """Get dashboard information"""
    try:
        # Get all assistance requests count
        assistance_ref = db.collection('assistance_requests').where('status', '==', 'pending')
        assistance_count = len(list(assistance_ref.stream()))
        
        # Get notifications count
        notifications_ref = db.collection('notifications').where('recipient_type', '==', 'serveur').where('read', '==', False)
        notifications_count = len(list(notifications_ref.stream()))
        
        # Get ready orders count
        ready_orders_ref = db.collection('commandes').where('etat', '==', 'prete')
        ready_orders_count = len(list(ready_orders_ref.stream()))
        
        # Get active tables count
        active_tables_ref = db.collection('tables').where('etatTable', '==', 'occupee')
        active_tables_count = len(list(active_tables_ref.stream()))
        
        # Get pending orders count
        pending_orders_ref = db.collection('commandes').where('etat', '==', 'en_attente')
        pending_orders_count = len(list(pending_orders_ref.stream()))
        
        dashboard_data = {
            'assistance_requests': assistance_count,
            'notifications': notifications_count,
            'ready_orders': ready_orders_count,
            'active_tables': active_tables_count,
            'pending_orders': pending_orders_count
        }
        
        return JsonResponse(dashboard_data)
    except Exception as e:
        logger.error(f"Error fetching dashboard data: {str(e)}")
        return JsonResponse({'error': str(e)}, status=500)

@api_view(['GET'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsServer])
def get_all_tables(request):
    """Get all tables"""
    try:
        tables = []
        tables_ref = db.collection('tables')
        
        for doc in tables_ref.stream():
            table_data = doc.to_dict()
            table_data['id'] = doc.id
            
            # Get active orders for this table
            orders = []
            reservations_ref = db.collection('reservations').where('table_id', '==', doc.id)
            for res_doc in reservations_ref.stream():
                res_data = res_doc.to_dict()
                if 'client_id' in res_data:
                    orders_ref = db.collection('commandes').where('idC', '==', res_data['client_id'])
                    for order_doc in orders_ref.stream():
                        order_data = order_doc.to_dict()
                        if order_data.get('etat') not in ['servie', 'annulee']:
                            orders.append({
                                'id': order_doc.id,
                                'etat': order_data.get('etat', 'Unknown'),
                                'montant': order_data.get('montant', 0)
                            })
            
            table_data['orders'] = orders
            tables.append(table_data)
        
        return JsonResponse(tables, safe=False)
    except Exception as e:
        logger.error(f"Error fetching tables: {str(e)}")
        return JsonResponse({'error': str(e)}, status=500)

@api_view(['PUT'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsServer])
@csrf_exempt
def update_table_status(request, table_id):
    """Update table status"""
    try:
        data = json.loads(request.body)
        new_status = data.get('status')
        
        if not new_status:
            return JsonResponse({'error': 'New status is required'}, status=400)
        
        # Validate that the new status is valid
        valid_statuses = ['libre', 'occupee', 'reservee']
        if new_status not in valid_statuses:
            return JsonResponse({'error': 'Invalid status'}, status=400)
        
        table_ref = db.collection('tables').document(table_id)
        table_doc = table_ref.get()
        
        if not table_doc.exists:
            return JsonResponse({'error': 'Table not found'}, status=404)
        
        # Update table status
        table_ref.update({'etatTable': new_status})
        
        return JsonResponse({'message': 'Table status updated successfully'})
    except Exception as e:
        logger.error(f"Error updating table status: {str(e)}")
        return JsonResponse({'error': str(e)}, status=500)

@api_view(['GET'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsServer])
def get_table_orders(request, table_id):
    """Get orders for a specific table"""
    try:
        orders = []
        reservations_ref = db.collection('reservations').where('table_id', '==', table_id)
        
        for res_doc in reservations_ref.stream():
            res_data = res_doc.to_dict()
            if 'client_id' in res_data:
                orders_ref = db.collection('commandes').where('idC', '==', res_data['client_id'])
                for order_doc in orders_ref.stream():
                    order_data = order_doc.to_dict()
                    order_data['id'] = order_doc.id
                    
                    # Get items in the order
                    order_items = []
                    order_items_ref = db.collection('commande_plat').where('idCmd', '==', order_doc.id)
                    for item_doc in order_items_ref.stream():
                        item_data = item_doc.to_dict()
                        plat_ref = db.collection('plats').document(item_data['idP'])
                        plat_doc = plat_ref.get()
                        if plat_doc.exists:
                            plat_data = plat_doc.to_dict()
                            order_items.append({
                                'idP': item_data['idP'],
                                'nom': plat_data.get('nom', 'Unknown'),
                                'quantite': item_data.get('quantité', 1),
                                'prix': plat_data.get('prix', 0)
                            })
                    
                    order_data['items'] = order_items
                    orders.append(order_data)
        
        return JsonResponse(orders, safe=False)
    except Exception as e:
        logger.error(f"Error fetching table orders: {str(e)}")
        return JsonResponse({'error': str(e)}, status=500)

@api_view(['GET'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsServer])
def get_notifications(request):
    """Get all notifications for the server"""
    try:
        notifications = []
        notifications_ref = db.collection('notifications').where('recipient_type', '==', 'serveur').order_by('created_at', direction=firestore.Query.DESCENDING)
        
        for doc in notifications_ref.stream():
            notification_data = doc.to_dict()
            notification_data['id'] = doc.id
            notifications.append(notification_data)
        
        return JsonResponse(notifications, safe=False)
    except Exception as e:
        logger.error(f"Error fetching notifications: {str(e)}")
        return JsonResponse({'error': str(e)}, status=500)

@api_view(['GET'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsServer])
def get_notification_details(request, notification_id):
    """Get detailed information about a specific notification"""
    try:
        notification_ref = db.collection('notifications').document(notification_id)
        notification_doc = notification_ref.get()
        
        if not notification_doc.exists:
            return JsonResponse({'error': 'Notification not found'}, status=404)
        
        notification_data = notification_doc.to_dict()
        notification_data['id'] = notification_doc.id
        
        # Mark as read if not already
        if not notification_data.get('read', False):
            notification_ref.update({'read': True})
            notification_data['read'] = True
        
        # Get related entity details if it exists
        if 'related_id' in notification_data and notification_data.get('type') == 'order_ready':
            order_ref = db.collection('commandes').document(notification_data['related_id'])
            order_doc = order_ref.get()
            if order_doc.exists:
                order_data = order_doc.to_dict()
                notification_data['related_entity'] = {
                    'type': 'order',
                    'data': {
                        'id': notification_data['related_id'],
                        'etat': order_data.get('etat', 'Unknown'),
                        'montant': order_data.get('montant', 0)
                    }
                }
        
        return JsonResponse(notification_data)
    except Exception as e:
        logger.error(f"Error fetching notification details: {str(e)}")
        return JsonResponse({'error': str(e)}, status=500)
@api_view(['POST'])
@authentication_classes([FirebaseAuthentication])
@permission_classes([IsServer])
def mark_all_notifications_read(request):
    """Mark all notifications as read for the current server"""
    try:
        # Get server ID from authenticated user
        server_id = request.user.uid
        
        # Get all unread notifications for this server
        notifications_ref = db.collection('notifications')\
            .where('recipient_type', '==', 'serveur')\
            .where('read', '==', False)\
            .stream()
        
        batch = db.batch()
        count = 0
        
        for doc in notifications_ref:
            batch.update(doc.reference, {
                'read': True,
                'read_at': datetime.now().isoformat()
            })
            count += 1
        
        # Execute batch update
        batch.commit()
        
        return JsonResponse({
            'success': True,
            'message': f'{count} notifications ont été marquées comme lues'
        })
    except Exception as e:
        logger.error(f"Error marking all notifications as read: {str(e)}")
        return JsonResponse({'error': str(e)}, status=500)