"""
Utility functions for order operations.
This module provides functions for fetching and processing orders data.
"""
from firebase_admin import firestore
from rest_framework.response import Response
from rest_framework import status
import logging

logger = logging.getLogger(__name__)

def get_order_details(order_doc, db):
    """
    Get comprehensive order details including items, client and table info.
    This function processes a single order document and returns a complete order object.
    
    Args:
        order_doc: Firestore document reference for an order
        db: Firestore database instance
        
    Returns:
        dict: Complete order details with consistent structure
    """
    if not order_doc.exists:
        return None

    # Get base order data with proper error handling
    try:
        order = order_doc.to_dict()
        order['id'] = order_doc.id
        
        # Initialize items list
        items = []
        order_plat_ref = db.collection('commande_plat').where('idCmd', '==', order_doc.id)
        
        # Process order items
        for cp_doc in order_plat_ref.stream():
            cp_data = cp_doc.to_dict()
            plat_ref = db.collection('plats').document(cp_data['idP'])
            plat_doc = plat_ref.get()
            
            if plat_doc.exists:
                plat_data = plat_doc.to_dict()
                items.append({
                    'plat_id': cp_data['idP'],
                    'nom': plat_data.get('nom', 'Unknown'),
                    'quantite': cp_data.get('quantité', 1),
                    'prix': plat_data.get('prix', 0),
                    'statut': cp_data.get('statut', 'non préparé')
                })
        
        order['items'] = items
        
        # Process client info with null checks
        if 'idC' in order and order['idC']:
            client_ref = db.collection('clients').document(order['idC'])
            client_doc = client_ref.get()
            if client_doc.exists:
                client_data = client_doc.to_dict()
                order['client'] = {
                    'username': client_data.get('username', 'Unknown'),
                    'id': order['idC']
                }
            else:
                order['client'] = {
                    'username': 'Client inconnu',
                    'id': order['idC']
                }
        
        # Process table info with robust handling
        table_info = None
        
        # First try direct table reference
        if 'idTable' in order and order['idTable']:
            table_id = order['idTable']
            table_ref = db.collection('tables').document(table_id)
            table_doc = table_ref.get()
            
            if table_doc.exists:
                table_data = table_doc.to_dict()
                table_info = {
                    'id': table_id,
                    'nbrPersonne': table_data.get('nbrPersonne', 0),
                    'nom': table_data.get('nom', f"Table {table_id}")
                }
            else:
                table_info = {
                    'id': table_id,
                    'nbrPersonne': 0,
                    'nom': f"Table {table_id} (inconnue)"
                }
        
        # Fallback to reservation if no direct table reference
        if not table_info and 'idC' in order and order['idC']:
            reservations_ref = db.collection('reservations').where('client_id', '==', order['idC']).limit(1)
            for res_doc in reservations_ref.stream():
                res_data = res_doc.to_dict()
                if 'table_id' in res_data and res_data['table_id']:
                    table_ref = db.collection('tables').document(res_data['table_id'])
                    table_doc = table_ref.get()
                    if table_doc.exists:
                        table_data = table_doc.to_dict()
                        table_info = {
                            'id': res_data['table_id'],
                            'nbrPersonne': table_data.get('nbrPersonne', 0),
                            'nom': table_data.get('nom', f"Table {res_data['table_id']}")
                        }
        
        order['table'] = table_info if table_info else None
        
        return order

    except Exception as e:
        logger.error(f"Error processing order {order_doc.id}: {str(e)}", exc_info=True)
        return None

def get_orders_by_status(status_values, db):
    """
    Get orders with specified status values.
    
    Args:
        status_values: List of status values to filter by
        db: Firestore database instance
        
    Returns:
        list: List of orders matching the status criteria or empty list on error
    """
    try:
        if not status_values:
            return []
            
        if len(status_values) == 1:
            commandes_ref = db.collection('commandes').where('etat', '==', status_values[0])
        else:
            commandes_ref = db.collection('commandes').where('etat', 'in', status_values)
        
        commandes = []
        for doc in commandes_ref.stream():
            commande = get_order_details(doc, db)
            if commande:  # Only add if order processing succeeded
                commandes.append(commande)
                
        return commandes
        
    except Exception as e:
        logger.error(f"Error fetching orders by status: {str(e)}", exc_info=True)
        return []

def get_all_orders(db):
    """
    Get all orders regardless of status.
    
    Args:
        db: Firestore database instance
        
    Returns:
        list: List of all orders or empty list on error
    """
    try:
        commandes_ref = db.collection('commandes').order_by('dateCreation', direction=firestore.Query.DESCENDING)
        commandes = []
        
        for doc in commandes_ref.stream():
            commande = get_order_details(doc, db)
            if commande:  # Only add if order processing succeeded
                commandes.append(commande)
                
        return commandes
        
    except Exception as e:
        logger.error(f"Error fetching all orders: {str(e)}", exc_info=True)
        return []