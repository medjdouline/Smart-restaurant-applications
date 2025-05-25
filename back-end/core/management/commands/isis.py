from django.core.management.base import BaseCommand
from core.firebase_utils import firebase_config
from google.cloud.firestore import Increment

class Command(BaseCommand):
    help = 'Augmente la quantité de tous les ingrédients de 100 unités'

    def handle(self, *args, **options):
        db = firebase_config.get_db()
        ingredients_ref = db.collection('ingredients')
        
        docs = ingredients_ref.stream()
        batch = db.batch()
        updated_count = 0
        
        for doc in docs:
            batch.update(doc.reference, {
                'quantite': Increment(100)
            })
            updated_count += 1
            
            if updated_count % 500 == 0:
                batch.commit()
                batch = db.batch()
                self.stdout.write(f"{updated_count} ingrédients mis à jour...")
        
        batch.commit()
        self.stdout.write(
            self.style.SUCCESS(f"Opération terminée! {updated_count} ingrédients mis à jour.")
        )