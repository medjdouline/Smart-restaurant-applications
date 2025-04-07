from django.core.management.base import BaseCommand
from core.firebase_utils import firebase_config
from firebase_admin import firestore

class Command(BaseCommand):
    help = 'Test Firebase connection'

    def handle(self, *args, **kwargs):
        try:
            # Get database connection
            db = firebase_config.get_db()
            
            # Create a test collection
            test_collection = db.collection('django_connection_test')
            
            # Create a test document
            test_doc = test_collection.document('test_connection')
            test_doc.set({
                'message': 'Connection successful!',
                'timestamp': firestore.SERVER_TIMESTAMP
            })
            
            # Print success message
            self.stdout.write(self.style.SUCCESS('Firebase connection successful!'))
        
        except Exception as e:
            # Print error if connection fails
            self.stdout.write(self.style.ERROR(f'Firebase connection failed: {e}'))