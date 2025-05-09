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
        dict: Complete order details
    """
    # Get base order data
    order = order_doc.to_dict()
    order['id'] = order_doc.id
    
    # Get associated order items
    items = []
    order_plat_ref = db.collection('commande_plat').where('idCmd', '==', order_doc.id)
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
                'prix': plat_data.get('prix', 0)
            })
    
    order['items'] = items
    
    # Get client info if available
    if 'idC' in order:
        client_ref = db.collection('clients').document(order['idC'])
        client_doc = client_ref.get()
        if client_doc.exists:
            client_data = client_doc.to_dict()
            order['client'] = {
                'username': client_data.get('username', 'Unknown'),
                'id': order['idC']
            }
    
    # Get table info
    table_found = False
    
    # First try to get table from order data
    if 'idTable' in order:
        table_ref = db.collection('tables').document(order['idTable'])
        table_doc = table_ref.get()
        if table_doc.exists:
            table_data = table_doc.to_dict()
            order['table'] = {
                'id': order['idTable'],
                'nbrPersonne': table_data.get('nbrPersonne', 0)
            }
            table_found = True
    
    # If no table in order, try to find through reservations
    if not table_found and 'idC' in order:
        reservations_ref = db.collection('reservations').where('client_id', '==', order['idC']).limit(1)
        for res_doc in reservations_ref.stream():
            res_data = res_doc.to_dict()
            if 'table_id' in res_data:
                table_ref = db.collection('tables').document(res_data['table_id'])
                table_doc = table_ref.get()
                if table_doc.exists:
                    table_data = table_doc.to_dict()
                    order['table'] = {
                        'id': res_data['table_id'],
                        'nbrPersonne': table_data.get('nbrPersonne', 0)
                    }
                    table_found = True
                    break
    
    # If still no table found, assign a default one for demo purposes
    if not table_found:
        tables_ref = db.collection('tables').limit(1)
        for table_doc in tables_ref.stream():
            table_data = table_doc.to_dict()
            order['table'] = {
                'id': table_doc.id,
                'nbrPersonne': table_data.get('nbrPersonne', 2)
            }
            break
    
    return order

def get_orders_by_status(status_values, db):
    """
    Get orders with specified status values.
    
    Args:
        status_values: List of status values to filter by
        db: Firestore database instance
        
    Returns:
        list: List of orders matching the status criteria
    """
    try:
        if len(status_values) == 1:
            # If only one status value, use equality operator
            commandes_ref = db.collection('commandes').where('etat', '==', status_values[0])
        else:
            # If multiple status values, use 'in' operator
            commandes_ref = db.collection('commandes').where('etat', 'in', status_values)
        
        commandes = []
        for doc in commandes_ref.stream():
            commande = get_order_details(doc, db)
            commandes.append(commande)
            
        return commandes
    except Exception as e:
        logger.error(f"Error fetching orders by status: {str(e)}", exc_info=True)
        raise e

def get_all_orders(db):
    """
    Get all orders regardless of status.
    
    Args:
        db: Firestore database instance
        
    Returns:
        list: List of all orders
    """
    try:
        commandes_ref = db.collection('commandes').order_by('dateCreation', direction=firestore.Query.DESCENDING)
        commandes = []
        
        for doc in commandes_ref.stream():
            commande = get_order_details(doc, db)
            commandes.append(commande)
            
        return commandes
    except Exception as e:
        logger.error(f"Error fetching all orders: {str(e)}", exc_info=True)
        raise e