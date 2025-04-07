from firebase_admin import firestore
from core.firebase_utils import firebase_config
from typing import Dict, List, Any, Optional, Union

class FirebaseCRUD:
    """Class for Firebase CRUD operations"""
    
    def __init__(self):
        """Initialize with Firebase database connection"""
        self.db = firebase_config.get_db()
    
    # Generic CRUD 
    def create_document(self, collection: str, data: Dict[str, Any], doc_id: Optional[str] = None) -> str:
        """
        Create a new document in a collection
        
        Args:
            collection: Collection name
            data: Document data
            doc_id: Optional document ID (auto-generated if not provided)
            
        Returns:
            Document ID
        """
        try:
            if doc_id:
                doc_ref = self.db.collection(collection).document(doc_id)
                doc_ref.set(data)
                return doc_id
            else:
                doc_ref = self.db.collection(collection).document()
                doc_ref.set(data)
                return doc_ref.id
        except Exception as e:
            print(f"Error creating document in {collection}: {e}")
            raise
    
    def get_document(self, collection: str, doc_id: str) -> Dict[str, Any]:
        """
        Get a document by ID
        
        Args:
            collection: Collection name
            doc_id: Document ID
            
        Returns:
            Document data as dict
        """
        try:
            doc_ref = self.db.collection(collection).document(doc_id)
            doc = doc_ref.get()
            
            if doc.exists:
                return doc.to_dict()
            else:
                return None
        except Exception as e:
            print(f"Error getting document {doc_id} from {collection}: {e}")
            raise
    
    def update_document(self, collection: str, doc_id: str, data: Dict[str, Any]) -> bool:
        """
        Update a document
        
        Args:
            collection: Collection name
            doc_id: Document ID
            data: Updated fields
            
        Returns:
            Success status
        """
        try:
            doc_ref = self.db.collection(collection).document(doc_id)
            doc_ref.update(data)
            return True
        except Exception as e:
            print(f"Error updating document {doc_id} in {collection}: {e}")
            raise
    
    def delete_document(self, collection: str, doc_id: str) -> bool:
        """
        Delete a document
        
        Args:
            collection: Collection name
            doc_id: Document ID
            
        Returns:
            Success status
        """
        try:
            doc_ref = self.db.collection(collection).document(doc_id)
            doc_ref.delete()
            return True
        except Exception as e:
            print(f"Error deleting document {doc_id} from {collection}: {e}")
            raise
    
    def get_all_documents(self, collection: str) -> List[Dict[str, Any]]:
        """
        Get all documents in a collection
        
        Args:
            collection: Collection name
            
        Returns:
            List of document data
        """
        try:
            docs = self.db.collection(collection).stream()
            return [{**doc.to_dict(), "id": doc.id} for doc in docs]
        except Exception as e:
            print(f"Error getting all documents from {collection}: {e}")
            raise
    
    def query_documents(self, collection: str, field: str, operator: str, value: Any) -> List[Dict[str, Any]]:
        """
        Query documents with a simple filter
        
        Args:
            collection: Collection name
            field: Field to filter on
            operator: Comparison operator ('==', '>', '<', '>=', '<=', 'array-contains')
            value: Value to compare against
            
        Returns:
            List of matching document data
        """
        try:
            docs = self.db.collection(collection).where(field, operator, value).stream()
            return [{**doc.to_dict(), "id": doc.id} for doc in docs]
        except Exception as e:
            print(f"Error querying documents in {collection}: {e}")
            raise

    
    # Client
    def create_client(self, client_data: Dict[str, Any], user_id: str) -> str:
        """Create a new client"""
        return self.create_document('clients', client_data, user_id)
    
    def get_client(self, client_id: str) -> Dict[str, Any]:
        """Get client by ID"""
        return self.get_document('clients', client_id)
    
    def update_client(self, client_id: str, client_data: Dict[str, Any]) -> bool:
        """Update client data"""
        return self.update_document('clients', client_id, client_data)
    
    def delete_client(self, client_id: str) -> bool:
        """Delete a client"""
        return self.delete_document('clients', client_id)
    
    # Plat
    def create_plat(self, plat_data: Dict[str, Any]) -> str:
        """Create a new menu item"""
        return self.create_document('plat', plat_data)
    
    def get_plat(self, plat_id: str) -> Dict[str, Any]:
        """Get menu item by ID"""
        return self.get_document('plat', plat_id)
    
    def update_plat(self, plat_id: str, plat_data: Dict[str, Any]) -> bool:
        """Update menu item data"""
        return self.update_document('plat', plat_id, plat_data)
    
    def delete_plat(self, plat_id: str) -> bool:
        """Delete a menu item"""
        return self.delete_document('plat', plat_id)
    
    def get_plats_by_category(self, category_id: str) -> List[Dict[str, Any]]:
        """Get all menu items in a category"""
        return self.query_documents('plat', 'idCat', '==', category_id)
    
    # Commande
    def create_commande(self, commande_data: Dict[str, Any]) -> str:
        """Create a new order"""
        return self.create_document('commandes', commande_data)
    
    def get_commande(self, commande_id: str) -> Dict[str, Any]:
        """Get order by ID"""
        return self.get_document('commandes', commande_id)
    
    def update_commande(self, commande_id: str, commande_data: Dict[str, Any]) -> bool:
        """Update order data"""
        return self.update_document('commandes', commande_id, commande_data)
    
    def delete_commande(self, commande_id: str) -> bool:
        """Delete an order"""
        return self.delete_document('commandes', commande_id)
    
    def get_client_commandes(self, client_id: str) -> List[Dict[str, Any]]:
        """Get all orders for a client"""
        return self.query_documents('commandes', 'idC', '==', client_id)
    
    def add_plat_to_commande(self, commande_id: str, plat_id: str, quantity: int) -> str:
        """Add a menu item to an order"""
        commande_plat_data = {
            'idCmd': commande_id,
            'idP': plat_id,
            'quantite': quantity
        }
        return self.create_document('commande_plat', commande_plat_data)
    
    def get_commande_plats(self, commande_id: str) -> List[Dict[str, Any]]:
        """Get all menu items in an order"""
        return self.query_documents('commande_plat', 'idCmd', '==', commande_id)
    
    # Table
    def create_table(self, table_data: Dict[str, Any], table_id: Optional[str] = None) -> str:
        """Create a new table"""
        return self.create_document('tables', table_data, table_id)
    
    def get_table(self, table_id: str) -> Dict[str, Any]:
        """Get table by ID"""
        return self.get_document('tables', table_id)
    
    def update_table(self, table_id: str, table_data: Dict[str, Any]) -> bool:
        """Update table data"""
        return self.update_document('tables', table_id, table_data)
    
    def get_available_tables(self) -> List[Dict[str, Any]]:
        """Get all available tables"""
        return self.query_documents('tables', 'etatTable', '==', 'libre')
    
    # Reservation operations
    def create_reservation(self, reservation_data: Dict[str, Any]) -> str:
        """Create a new reservation"""
        return self.create_document('reservations', reservation_data)
    
    def get_reservation(self, reservation_id: str) -> Dict[str, Any]:
        """Get reservation by ID"""
        return self.get_document('reservations', reservation_id)
    
    def update_reservation(self, reservation_id: str, reservation_data: Dict[str, Any]) -> bool:
        """Update reservation data"""
        return self.update_document('reservations', reservation_id, reservation_data)
    
    def delete_reservation(self, reservation_id: str) -> bool:
        """Delete a reservation"""
        return self.delete_document('reservations', reservation_id)
    
    def get_client_reservations(self, client_id: str) -> List[Dict[str, Any]]:
        """Get all reservations for a client"""
        return self.query_documents('reservations', 'idC', '==', client_id)

# global use
firebase_crud = FirebaseCRUD()