from django.core.management.base import BaseCommand
from core.firebase_utils import firebase_config
import logging

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = 'Delete all documents from specified collections'

    def handle(self, *args, **options):
        db = firebase_config.get_db()
        
        # Function to delete all documents in a collection
        def delete_collection(collection_name):
            try:
                # Get all documents in the collection
                docs = db.collection(collection_name).stream()
                
                # Count of deleted documents
                deleted_count = 0
                
                # Delete each document
                for doc in docs:
                    doc.reference.delete()
                    deleted_count += 1
                
                logger.info(f"Deleted {deleted_count} documents from '{collection_name}' collection")
                self.stdout.write(self.style.SUCCESS(f"Successfully deleted {deleted_count} documents from '{collection_name}' collection"))
                return deleted_count
            except Exception as e:
                logger.error(f"Error deleting documents from '{collection_name}': {str(e)}")
                self.stdout.write(self.style.ERROR(f"Failed to delete documents from '{collection_name}': {str(e)}"))
                return 0
        
        # List of collections to empty
        collections_to_empty = [
            'categories',           # Category collection
            'sous_categories',      # Sub-category collection
            'plats',                # Dishes collection
            'clients',              # Clients collection
            'recommandations',      # Recommendations collection (using the French spelling from your setup)
            'commandes',            # Orders collection
            'commande_plat'         # Order-dish relationship collection (from your setup file)
        ]
        
        # Delete all documents from each collection
        total_deleted = 0
        for collection in collections_to_empty:
            deleted = delete_collection(collection)
            total_deleted += deleted
        
        # Summary message
        self.stdout.write(self.style.SUCCESS(f'Database cleanup completed successfully. Total documents deleted: {total_deleted}'))