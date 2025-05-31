from django.core.management.base import BaseCommand
from core.firebase_utils import firebase_config
from firebase_admin import firestore
from datetime import datetime
import logging

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = 'Update ingredients collection: convert kg to g, boost quantities to 2500, and extend expiration dates to August minimum'

    def handle(self, *args, **options):
        db = firebase_config.get_db()

        self.stdout.write("Début de la mise à jour de la collection 'ingredients'...")

        try:
            # Récupérer tous les documents de la collection ingredients
            ingredients_ref = db.collection('ingredients')
            docs = ingredients_ref.stream()

            count_updated = 0
            count_total = 0

            for doc in docs:
                count_total += 1
                doc_data = doc.to_dict()
                doc_ref = ingredients_ref.document(doc.id)
                
                # Préparer les mises à jour
                updates = {}
                
                # 1. Convertir 'kg' en 'g'
                if doc_data.get('unite') == 'Kg':
                    updates['unite'] = 'G'
                    self.stdout.write(f"Conversion kg->g pour: {doc_data.get('nom', doc.id)}")

                # 2. Mettre toutes les quantités à 2500
                if 'quantite' in doc_data:
                    updates['quantite'] = 2500
                
                # 3. Étendre les dates d'expiration au minimum à août 2025
                if 'date_expiration' in doc_data:
                    current_exp_date = doc_data['date_expiration']
                    min_date = "2025-08-01"
                    
                    # Si la date actuelle est avant août 2025, la mettre à août
                    if current_exp_date < min_date:
                        updates['date_expiration'] = min_date
                        self.stdout.write(f"Date d'expiration étendue pour: {doc_data.get('nom', doc.id)} ({current_exp_date} -> {min_date})")
                
                # Appliquer les mises à jour s'il y en a
                if updates:
                    doc_ref.update(updates)
                    count_updated += 1
                    self.stdout.write(f"Document mis à jour: {doc_data.get('nom', doc.id)}")

        except Exception as e:
            self.stdout.write(self.style.ERROR(f'Erreur lors de la mise à jour: {str(e)}'))
            return

        self.stdout.write(
            self.style.SUCCESS(
                f'Mise à jour terminée avec succès!\n'
                f'Documents traités: {count_total}\n'
                f'Documents mis à jour: {count_updated}'
            )
        )