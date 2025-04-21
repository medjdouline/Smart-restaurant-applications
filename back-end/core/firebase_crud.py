from firebase_admin import firestore
from core.firebase_utils import firebase_config
from datetime import datetime
from typing import Dict, List, Any, Optional
import logging

logger = logging.getLogger(__name__)

class FirebaseCRUD:
    """Complete Firebase CRUD operations matching the MLD"""
    
    def __init__(self):
        self.db = firebase_config.get_db()
    
    # ========================
    # Generic CRUD Operations
    # ========================
    def create_doc(self, collection: str, data: Dict, doc_id: Optional[str] = None) -> str:
        """Create document with optional ID"""
        try:
            col_ref = self.db.collection(collection)
            if doc_id:
                doc_ref = col_ref.document(doc_id)
                doc_ref.set(data)
                return doc_id
            doc_ref = col_ref.add(data)
            return doc_ref[1].id
        except Exception as e:
            logger.error(f"Create failed: {str(e)}")
            raise

    def get_doc(self, collection: str, doc_id: str) -> Dict:
        """Get document by ID"""
        try:
            doc = self.db.collection(collection).document(doc_id).get()
            return doc.to_dict() if doc.exists else None
        except Exception as e:
            logger.error(f"Get failed: {str(e)}")
            raise

    def update_doc(self, collection: str, doc_id: str, updates: Dict) -> None:
        """Update document fields"""
        try:
            self.db.collection(collection).document(doc_id).update(updates)
        except Exception as e:
            logger.error(f"Update failed: {str(e)}")
            raise

    def delete_doc(self, collection: str, doc_id: str) -> None:
        """Delete document"""
        try:
            self.db.collection(collection).document(doc_id).delete()
        except Exception as e:
            logger.error(f"Delete failed: {str(e)}")
            raise

    def query_collection(self, collection: str, field: str, operator: str, value: Any) -> List[Dict]:
        """Query collection with conditions"""
        try:
            docs = self.db.collection(collection).where(field, operator, value).stream()
            return [doc.to_dict() for doc in docs]
        except Exception as e:
            logger.error(f"Query failed: {str(e)}")
            raise

    # ======================
    # Client Operations
    # ======================
    def create_client(self, client_data: Dict) -> str:
        """Create client record"""
        required_fields = ['username', 'email', 'isGuest']
        if not all(field in client_data for field in required_fields):
            raise ValueError("Missing required client fields")
            
        data = {
            'username': client_data['username'],
            'email': client_data['email'],
            'isGuest': client_data['isGuest'],
            'createdAt': firestore.SERVER_TIMESTAMP,
            'favorites': client_data.get('favorites', []),
            'history': client_data.get('history', [])
        }
        return self.create_doc('clients', data)

    def update_client_fidelity(self, client_id: str, points: int) -> None:
        """Update client fidelity points"""
        self.update_doc('clients', client_id, {'fidelityPoints': points})

    # ======================
    # Employee Operations
    # ======================
    def create_employes(self, employes_data: Dict) -> str:
        """Create employee record"""
        required_fields = ['first_name', 'last_name', 'email', 'role']
        if not all(field in employes_data for field in required_fields):
            raise ValueError("Missing required employee fields")
            
        data = {
            'first_name': employes_data['first_name'],
            'last_name': employes_data['last_name'],
            'email': employes_data['email'],
            'role': employes_data['role'],
            'firebase_uid': employes_data.get('firebase_uid'),
            'hire_date': firestore.SERVER_TIMESTAMP
        }
        return self.create_doc('employes', data)

    def create_server(self, employes_id: str) -> str:
        """Create server-specific record"""
        return self.create_doc('serveurs', {
            'employes_id': employes_id,
            'hire_date': firestore.SERVER_TIMESTAMP
        })

    def create_chef(self, employes_id: str) -> str:
        """Create chef-specific record"""
        return self.create_doc('cuisiniers', {
            'employes_id': employes_id,
            'specialties': [],
            'hire_date': firestore.SERVER_TIMESTAMP
        })

    def create_manager(self, employes_id: str) -> str:
        """Create manager-specific record"""
        return self.create_doc('manager', {
            'employes_id': employes_id,
            'permissions': ['manage_staff', 'view_reports']
        })

    # ======================
    # Table Operations
    # ======================
    def create_table(self, table_data: Dict) -> str:
        """Create table record"""
        required_fields = ['number', 'capacity', 'status']
        if not all(field in table_data for field in required_fields):
            raise ValueError("Missing required table fields")
            
        return self.create_doc('tables', {
            'number': table_data['number'],
            'capacity': table_data['capacity'],
            'status': table_data['status'],
            'location': table_data.get('location', 'main')
        })

    def update_table_status(self, table_id: str, status: str) -> None:
        """Update table status"""
        valid_statuses = ['available', 'occupied', 'reserved', 'cleaning']
        if status not in valid_statuses:
            raise ValueError(f"Invalid status. Must be one of: {valid_statuses}")
        self.update_doc('tables', table_id, {'status': status})

    # ======================
    # Reservation Operations
    # ======================
    def create_reservation(self, reservation_data: Dict) -> str:
        """Create reservation record"""
        required_fields = ['client_id', 'table_id', 'date_time', 'party_size']
        if not all(field in reservation_data for field in required_fields):
            raise ValueError("Missing required reservation fields")
            
        return self.create_doc('reservations', {
            'client_id': reservation_data['client_id'],
            'table_id': reservation_data['table_id'],
            'date_time': reservation_data['date_time'],
            'party_size': reservation_data['party_size'],
            'status': 'confirmed',
            'created_at': firestore.SERVER_TIMESTAMP
        })

    def update_reservation_status(self, reservation_id: str, status: str) -> None:
        """Update reservation status"""
        valid_statuses = ['confirmed', 'seated', 'completed', 'cancelled']
        if status not in valid_statuses:
            raise ValueError(f"Invalid status. Must be one of: {valid_statuses}")
        self.update_doc('reservations', reservation_id, {'status': status})

    # ======================
    # Menu & Dish Operations
    # ======================
    def create_dish(self, dish_data: Dict) -> str:
        """Create dish record"""
        required_fields = ['name', 'category', 'price', 'prep_time']
        if not all(field in dish_data for field in required_fields):
            raise ValueError("Missing required dish fields")
            
        return self.create_doc('dishes', {
            'name': dish_data['name'],
            'category': dish_data['category'],
            'price': dish_data['price'],
            'prep_time': dish_data['prep_time'],
            'ingredients': dish_data.get('ingredients', []),
            'is_available': dish_data.get('is_available', True),
            'created_at': firestore.SERVER_TIMESTAMP
        })

    def update_dish_availability(self, dish_id: str, is_available: bool) -> None:
        """Update dish availability"""
        self.update_doc('dishes', dish_id, {'is_available': is_available})

    # ======================
    # Order Operations
    # ======================
    def create_order(self, order_data: Dict) -> str:
        """Create order record"""
        required_fields = ['client_id', 'table_id', 'items', 'total']
        if not all(field in order_data for field in required_fields):
            raise ValueError("Missing required order fields")
            
        return self.create_doc('orders', {
            'client_id': order_data['client_id'],
            'table_id': order_data['table_id'],
            'items': order_data['items'],
            'total': order_data['total'],
            'status': 'received',
            'created_at': firestore.SERVER_TIMESTAMP,
            'server_id': order_data.get('server_id'),
            'notes': order_data.get('notes', '')
        })

    def update_order_status(self, order_id: str, status: str) -> None:
        """Update order status"""
        valid_statuses = ['received', 'preparing', 'ready', 'served', 'paid']
        if status not in valid_statuses:
            raise ValueError(f"Invalid status. Must be one of: {valid_statuses}")
        self.update_doc('orders', order_id, {'status': status})

    # ======================
    # Inventory Operations
    # ======================
    def update_inventory(self, item_id: str, quantity: int) -> None:
        """Update inventory quantity"""
        self.update_doc('inventory', item_id, {'quantity': quantity})

    # ======================
    # Report Operations
    # ======================
    def create_daily_report(self) -> str:
        """Create daily sales report"""
        # This would be enhanced with actual data aggregation
        return self.create_doc('reports', {
            'date': firestore.SERVER_TIMESTAMP,
            'total_sales': 0,
            'total_orders': 0,
            'most_popular_dish': None,
            'created_at': firestore.SERVER_TIMESTAMP
        })
    
    def get_all_docs(self, collection: str) -> List[Dict]:
        """Get all documents in a collection"""
        try:
            docs = self.db.collection(collection).stream()
            result = []
            for doc in docs:
                data = doc.to_dict()
                data['id'] = doc.id
                result.append(data)
            return result
        except Exception as e:
            logger.error(f"Get all docs failed: {str(e)}")
            raise


# Singleton instance
firebase_crud = FirebaseCRUD()