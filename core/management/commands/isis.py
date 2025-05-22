from django.core.management.base import BaseCommand
from core.firebase_utils import firebase_config
from firebase_admin import firestore
import random
from datetime import datetime
import logging

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = 'Reset and populate commandes and commandes_plat collections'

    def handle(self, *args, **options):
        db = firebase_config.get_db()

        # Liste des clients disponibles
        client_ids = [
            '007e76bf-8d2d-4384-88cd-257a1eb8187b',
            '07dc07d8-79c2-4a9a-ae11-315299733762',
            '0ac93c7f-04a6-44a4-bd3b-48285246e745',
            '1d502184-7fc0-4d26-9887-0ec638f61f0b',
            '1f4754c1-a70f-47ce-9f33-4d261daaeac1',
            '2a53a97d-7d81-443a-804d-9a6d6d4dac81',
            '35ffa434-d66d-4a3d-a609-f5b73275e183',
            '3ef6ad51-71f4-4ea2-9be4-fad1f87a02dc',
            '4836473a-8f6b-4fe8-a4f5-8273c9daab54',
            '4be22026-d3cb-4802-8abe-ed34bbae144d',
            '54200700-b198-446c-a06a-730b43d9b163',
            '626bd8c1-2247-4a4a-b150-fc9a07771a23',
            '65482f86-32d6-4411-b8c2-c7bec9177335'
        ]

        # Liste des tables disponibles
        table_ids = [f'table{i}' for i in range(1, 8)]

        # Liste des plats disponibles (IDs de 101 à 123)
        plat_ids = [str(i) for i in range(101, 124)]

        # États des commandes
        etats = ['en_attente', 'en_preparation', 'pret', 'servi', 'annulee']

        # 1. Vider les collections
        self.stdout.write("Vidage des collections 'commandes' et 'commandes_plat'...")
        
        # Vider commandes_plat en premier (car elle référence commandes)
        batch = db.batch()
        docs = db.collection('commandes_plat').stream()
        for doc in docs:
            batch.delete(doc.reference)
        batch.commit()

        # Vider commandes
        batch = db.batch()
        docs = db.collection('commandes').stream()
        for doc in docs:
            batch.delete(doc.reference)
        batch.commit()

        self.stdout.write("Collections vidées avec succès.")

        # 2. Créer les nouvelles commandes
        self.stdout.write("Création des nouvelles commandes...")

        for etat in etats:
            for i in range(1, 5):  # 4 commandes par état
                # Générer un ID unique pour la commande
                commande_id = f'cmd_{etat}_{i}_{datetime.now().strftime("%Y%m%d%H%M%S")}'
                
                # Choisir aléatoirement un client et une table
                client_id = random.choice(client_ids)
                table_id = random.choice(table_ids)
                
                # Créer la commande
                commande_data = {
                    'montant': round(random.uniform(20.0, 100.0), 2),
                    'dateCreation': firestore.SERVER_TIMESTAMP,
                    'etat': etat,
                    'confirmation': etat != 'annulee',
                    'idC': client_id,
                    'idTable': table_id
                }
                db.collection('commandes').document(commande_id).set(commande_data)

                # Créer les commandes_plat associées (1 à 3 plats par commande)
                nb_plats = random.randint(1, 3)
                for j in range(nb_plats):
                    plat_id = random.choice(plat_ids)
                    commande_plat_id = f'cp_{commande_id}_{j}'
                    
                    commande_plat_data = {
                        'idCmd': commande_id,
                        'idP': plat_id,
                        'quantité': random.randint(1, 3)
                    }
                    db.collection('commandes_plat').document(commande_plat_id).set(commande_plat_data)

        self.stdout.write(self.style.SUCCESS(f'Création de {len(etats)*4} commandes terminée avec succès.'))