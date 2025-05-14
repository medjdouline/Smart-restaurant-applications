from django.core.management.base import BaseCommand
from core.firebase_utils import firebase_config
from firebase_admin import firestore
import logging
import random
import uuid

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = 'Insert sample commands into Firestore with table IDs'

    def handle(self, *args, **options):
        db = firebase_config.get_db()
        
        # Liste des IDs clients
        client_ids = [
            '04fc6d82-7d15-4385-92fb-e43b99546eb4',
            '14a0bccb-8a47-4a87-a49d-681d51d87c64',
            '204e178c-10d0-4d11-a5f9-34bf9bb96155',
            '29a3b2e9-5d65-4441-9588-42dea2bc372f',
            '2cfa55b0-6e3f-483a-bf3c-51407f54a511',
            '2ef91276-6c00-4f61-a3e2-fcb472d8567d',
            '35ebd32d-9ad6-40ab-8821-2ddb45b89cd9',
            '4991ab9b-ebc2-426f-af34-cf65a193c4b2',
            '3873e57f-0ba0-48e8-8ef4-92c1aac93316'
        ]
        
        # Types d'états de commande
        etats = ['annulee', 'en_preparation', 'en_attente', 'pret', 'servi']
        
        # IDs de tables disponibles
        table_ids = [f'table{i}' for i in range(1, 8)]
        
        # Vérifier si les tables existent déjà dans la base de données
        # et les créer si nécessaire
        for table_id in table_ids:
            table_ref = db.collection('tables').document(table_id)
            table_doc = table_ref.get()
            if not table_doc.exists:
                # Créer la table si elle n'existe pas
                table_ref.set({
                    'nbrPersonne': random.randint(2, 8),
                    'etatTable': 'libre'
                })
                self.stdout.write(f"Created table with ID: {table_id}")
        
        # Récupération de quelques IDs de plats depuis la collection plats
        plats_refs = db.collection('plats').stream()
        plat_ids = [plat.id for plat in plats_refs]
            
        if not plat_ids:
            plat_ids = [f'plat_{i}' for i in range(101, 151)] + ['plat1']
        
        # Création de 4 commandes pour chaque état
        count = 0
        for etat in etats:
            for i in range(4):  # Augmenté de 2 à 4
                # Générer un ID de commande aléatoire
                commande_id = f'commande_{uuid.uuid4().hex[:8]}'
                
                # Sélectionner un client aléatoire
                client_id = random.choice(client_ids)
                
                # Sélectionner une table aléatoire par son ID
                table_id = random.choice(table_ids)
                
                # Déterminer si la commande est confirmée
                confirmation = etat not in ['annulee', 'en_attente']
                
                # Générer un montant aléatoire entre 15 et 200 euros
                montant = round(random.uniform(15.0, 200.0), 2)
                
                # Créer la commande avec l'ID de table
                db.collection('commandes').document(commande_id).set({
                    'montant': montant,
                    'dateCreation': firestore.SERVER_TIMESTAMP,
                    'etat': etat,
                    'confirmation': confirmation,
                    'idC': client_id,
                    'idTable': table_id  # Utilisation de l'ID de table au lieu d'un simple numéro
                })
                
                # Générer entre 1 et 3 plats pour cette commande
                num_plats = random.randint(1, 3)
                selected_plats = random.sample(plat_ids, min(num_plats, len(plat_ids)))
                
                # Créer les documents commande_plat correspondants
                for plat_id in selected_plats:
                    # Déterminer une quantité aléatoire entre 1 et 3
                    quantite = random.randint(1, 3)
                    
                    # Générer un ID aléatoire pour le document commande_plat
                    cp_id = f'cp_{uuid.uuid4().hex[:8]}'
                    
                    # Créer le document commande_plat
                    db.collection('commande_plat').document(cp_id).set({
                        'idCmd': commande_id,
                        'idP': plat_id,
                        'quantité': quantite
                    })
                
                count += 1
                self.stdout.write(f"Commande {commande_id} créée avec l'état '{etat}', table {table_id}, {len(selected_plats)} plats")
        
        self.stdout.write(self.style.SUCCESS(f"{count} commandes ont été créées avec succès!"))