from django.core.management.base import BaseCommand
from core.firebase_utils import firebase_config
from firebase_admin import firestore
import logging
import random
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = 'Insert random orders into Firestore'

    def handle(self, *args, **options):
        db = firebase_config.get_db()
        
        # Client IDs
        client_ids = [
            '04fc6d82-7d15-4385-92fb-e43b99546eb4',
            '06e745f9-88bc-439c-9f4c-3b79fb10987f',
            '0b19f88e-9d77-445e-b206-c26938b77c07',
            '0c0fd195-c17a-408a-9745-d6d87e570ddf',
            '14822f53-8201-4c62-b5f5-9b220e8fa8e0',
            '14a0bccb-8a47-4a87-a49d-681d51d87c64',
            '18c26797-6142-4a7d-97be-31111a2a73ed',
            '1b19d8b8-d830-4081-afcc-57dd168fae12',
            '1efa2197-7394-488f-847f-d9b4e64d1bcb',
            '204e178c-10d0-4d11-a5f9-34bf9bb96155'
        ]
        
        # Table IDs
        table_ids = ['table1', 'table2', 'table3', 'table4', 'table5', 'table6', 'table7']
        
        # Order states
        order_states = ['pret', 'en_attente', 'en_preparation', 'servi', 'annulee']
        
        # Plats (selected from the database structure)
        plats = [
            {'id': 'plat_101', 'nom': 'Soupe à l\'Oignon', 'prix': 7.50},
            {'id': 'plat_111', 'nom': 'Salade Niçoise', 'prix': 9.00},
            {'id': 'plat_121', 'nom': 'Quiche Lorraine', 'prix': 8.50},
            {'id': 'plat_131', 'nom': 'Carpaccio de Bœuf', 'prix': 14.00},
            {'id': 'plat_201', 'nom': 'Burger Bistrot', 'prix': 15.00},
            {'id': 'plat_211', 'nom': 'Coq au Vin', 'prix': 16.00},
            {'id': 'plat_221', 'nom': 'Daurade Grillée', 'prix': 18.00},
            {'id': 'plat_231', 'nom': 'Blanquette de Veau', 'prix': 19.00},
            {'id': 'plat_241', 'nom': 'Gratin de Légumes', 'prix': 12.00},
            {'id': 'plat_301', 'nom': 'Frites Maison', 'prix': 5.00},
            {'id': 'plat_311', 'nom': 'Petits Pois Carottes', 'prix': 4.50},
            {'id': 'plat_401', 'nom': 'Café Allongé', 'prix': 3.00},
            {'id': 'plat_411', 'nom': 'Jus d\'Orange Pressé', 'prix': 5.00},
            {'id': 'plat_501', 'nom': 'Crème Brûlée', 'prix': 6.50},
            {'id': 'plat_511', 'nom': 'Salade de Fruits Frais', 'prix': 5.50},
            {'id': 'plat1', 'nom': 'Steak frites', 'prix': 24.99}
        ]
        
        # Employee IDs for servers
        employee_id = 'employe1'
        
        # Generate 30 random orders
        for i in range(1, 31):
            # Generate a random order ID
            commande_id = f'commande_{i}'
            
            # Select random client, table and state
            client_id = random.choice(client_ids)
            table_id = random.choice(table_ids)
            etat = random.choice(order_states)
            
            # Generate a random date within the last 30 days
            days_ago = random.randint(0, 30)
            date_creation = datetime.now() - timedelta(days=days_ago)
            
            # Select random dishes (between 1 and 4 items)
            num_plats = random.randint(1, 4)
            selected_plats = random.sample(plats, num_plats)
            
            # Calculate total order amount
            montant = sum(plat['prix'] * random.randint(1, 2) for plat in selected_plats)
            montant = round(montant, 2)
            
            # Set confirmation based on state
            confirmation = etat not in ['en_attente', 'annulee']
            
            # Create the order document
            db.collection('commandes').document(commande_id).set({
                'montant': montant,
                'dateCreation': date_creation,
                'etat': etat,
                'confirmation': confirmation,
                'idC': client_id,
                'idTable': table_id
            })
            
            # Create commande_plat entries for each selected dish
            for j, plat in enumerate(selected_plats):
                plat_id = plat['id']
                quantite = random.randint(1, 2)  # 1 or 2 of each dish
                
                db.collection('commande_plat').document(f'cp_{commande_id}_{j}').set({
                    'idCmd': commande_id,
                    'idP': plat_id,
                    'quantité': quantite
                })
            
            # Create serveur_commande entry
            db.collection('serveur_commande').document(f'sc_{commande_id}').set({
                'idE': employee_id,
                'idCmd': commande_id
            })
            
            self.stdout.write(f"Created order {commande_id} for client {client_id} at table {table_id}, status: {etat}")
        
        self.stdout.write(self.style.SUCCESS('Successfully created 30 random orders in Firestore.'))