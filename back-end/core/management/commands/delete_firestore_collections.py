from django.core.management.base import BaseCommand
from core.firebase_utils import firebase_config
import logging

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = 'Delete all collections in Firestore database'

    def handle(self, *args, **options):
        db = firebase_config.get_db()
        
        
        collections = db.collections()
        
        for collection in collections:
            self.delete_collection(collection)
            self.stdout.write(f"Collection '{collection.id}' supprimée avec succès")
        
        self.stdout.write(self.style.SUCCESS('Toutes les collections ont été supprimées de la base de données Firestore'))
    
    def delete_collection(self, collection_ref, batch_size=500):
        """Supprime récursivement les documents dans une collection."""
        docs = collection_ref.limit(batch_size).stream()
        deleted = 0
        
        for doc in docs:
            
            for subcol in doc.reference.collections():
                self.delete_collection(subcol)
            
            
            doc.reference.delete()
            deleted += 1
        
        if deleted >= batch_size:
            
            return self.delete_collection(collection_ref, batch_size)
        
        return deleted