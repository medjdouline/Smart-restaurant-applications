# restaurant_system/core/views.py
from django.http import JsonResponse
from django.views.decorators.http import require_http_methods
from core.firebase_utils import firebase_config
from firebase_admin import firestore

def test_firebase_connection(request):
    try:
        # Get Firestore database client
        db = firebase_config.get_db()
        
        # Create a test collection
        test_collection = db.collection('django_connection_test')
        
        # Create a test document
        test_doc = test_collection.document('view_test_connection')
        test_doc.set({
            'test_message': 'Connection from Django view',
            'timestamp': firestore.SERVER_TIMESTAMP
        })
        
        return JsonResponse({
            'status': 'success',
            'message': 'Firebase connection verified'
        })
    
    except Exception as e:
        return JsonResponse({
            'status': 'error',
            'message': str(e)
        }, status=500)