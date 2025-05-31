from django.core.management.base import BaseCommand
from core.firebase_utils import firebase_config
from firebase_admin import firestore
import logging

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = 'Clear all documents from the notifications collection'

    def handle(self, *args, **options):
        db = firebase_config.get_db()

        self.stdout.write("Début de la suppression de tous les documents de la collection 'notifications'...")

        try:
            # Récupérer tous les documents de la collection notifications
            notifications_ref = db.collection('notifications')
            docs = notifications_ref.stream()

            count_deleted = 0
            
            # Supprimer chaque document
            for doc in docs:
                doc.reference.delete()
                count_deleted += 1
                self.stdout.write(f"Document supprimé: {doc.id}")

        except Exception as e:
            self.stdout.write(self.style.ERROR(f'Erreur lors de la suppression: {str(e)}'))
            return

        self.stdout.write(
            self.style.SUCCESS(
                f'Suppression terminée avec succès!\n'
                f'Documents supprimés: {count_deleted}'
            )
        )