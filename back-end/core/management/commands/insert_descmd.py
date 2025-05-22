from django.core.management.base import BaseCommand
from core.firebase_utils import firebase_config
from firebase_admin import firestore
import logging
import random
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = 'Insert commands and command-plate relationships'

    def handle(self, *args, **options):
        db = firebase_config.get_db()
        
        # Client IDs
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
        
        # Plat IDs (from 101 to 123)
        plat_ids = [f'plat_{i}' for i in range(101, 124)]
        
        # Table IDs
        table_ids = [f'table{i}' for i in range(1, 8)]
        
        # Command statuses
        command_statuses = ['en_attente', 'en_preparation', 'pret', 'annulee', 'servi']
        
        # Employee ID for serveur_commande
        employe_id = 'employe1'
        
        # Create 4 commands for each status
        commands_created = 0
        command_plate_created = 0
        serveur_command_created = 0
        
        for status in command_statuses:
            for i in range(4):
                # Generate a unique command ID
                command_id = f'cmd_{status}_{i+1}'
                
                # Randomly select client, table
                client_id = random.choice(client_ids)
                table_id = random.choice(table_ids)
                
                # Calculate date (recent dates for active statuses, older dates for completed ones)
                if status in ['en_attente', 'en_preparation', 'pret']:
                    date_creation = datetime.now() - timedelta(hours=random.randint(1, 24))
                else:
                    date_creation = datetime.now() - timedelta(days=random.randint(1, 30))
                
                # Calculate random amount between 15 and 150
                amount = round(random.uniform(15, 150), 2)
                
                # Create command
                db.collection('commandes').document(command_id).set({
                    'montant': amount,
                    'dateCreation': date_creation,
                    'etat': status,
                    'confirmation': status != 'annulee',  # False if cancelled, True otherwise
                    'idC': client_id,  # Client foreign key
                    'idTable': table_id  # Table foreign key
                })
                commands_created += 1
                
                # Create between 1 and 4 command-plate relationships for this command
                num_plates = random.randint(1, 4)
                selected_plats = random.sample(plat_ids, num_plates)
                
                for j, plat_id in enumerate(selected_plats):
                    cp_id = f'cp_{command_id}_{j+1}'
                    quantity = random.randint(1, 3)
                    
                    db.collection('commande_plat').document(cp_id).set({
                        'idCmd': command_id,  # Command foreign key
                        'idP': plat_id,      # Plate foreign key
                        'quantité': quantity
                    })
                    command_plate_created += 1
                
                # Create serveur_commande relationship
                sc_id = f'sc_{command_id}'
                db.collection('serveur_commande').document(sc_id).set({
                    'idE': employe_id,   # Employee foreign key
                    'idCmd': command_id  # Command foreign key
                })
                serveur_command_created += 1
        
        logger.info(f"Created {commands_created} commands")
        logger.info(f"Created {command_plate_created} command-plate relationships")
        logger.info(f"Created {serveur_command_created} server-command relationships")
        
        self.stdout.write(self.style.SUCCESS(f'Successfully inserted {commands_created} commands with related records'))