from django.core.management.base import BaseCommand
from core.firebase_utils import firebase_config
from firebase_admin import firestore
import logging

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = 'Vider les collections commandes et commande_plat'

    def handle(self, *args, **options):
        db = firebase_config.get_db()
        
        # Vider la collection 'commandes'
        commandes_ref = db.collection('commandes')
        for doc in commandes_ref.stream():
            doc.reference.delete()
            self.stdout.write(f"Document {doc.id} supprimé de 'commandes'")
        
        # Vider la collection 'commande_plat'
        commande_plat_ref = db.collection('commande_plat')
        for doc in commande_plat_ref.stream():
            doc.reference.delete()
            self.stdout.write(f"Document {doc.id} supprimé de 'commande_plat'")
        
        self.stdout.write(self.style.SUCCESS("Les collections 'commandes' et 'commande_plat' ont été vidées avec succès!"))