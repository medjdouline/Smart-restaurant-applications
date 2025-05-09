from django.core.management.base import BaseCommand
from core.firebase_utils import firebase_config
from firebase_admin import firestore
import logging
import random
from datetime import datetime, timedelta
import uuid

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = 'Insert random test documents into Firestore'

    def handle(self, *args, **options):
        db = firebase_config.get_db()
        
        # Reference data
        client_ids = ['client_exemple']
        # Create additional clients
        for i in range(1, 5):
            client_id = f'client_{i}'
            client_ids.append(client_id)
            db.collection('clients').document(client_id).set({
                'username': f'client_test_{i}',
                'email': f'client{i}@example.com',
                'motDePasse': f'hashed_password_{i}',
                'isGuest': False,
                'birthdate': f'199{i}-01-01',
                'gender': random.choice(['homme', 'femme']),
                'phoneNumber': f'+3361234567{i}',
                'fidelityPoints': random.randint(0, 500),
                'preferences': random.sample(['Soupes et Potages', 'Viandes', 'Pâtisseries', 'Salades', 'Poissons'], 3),
                'allergies': random.sample(['Gluten', 'Arachides', 'Lactose', 'Fruits de mer'], 
                                          random.randint(0, 2)),
                'restrictions': random.sample(['Sans gluten', 'Végétarien', 'Sans lactose'], 
                                             random.randint(0, 1))
            })
        
        # Existing plats and add more
        plat_ids = ['plat1']
        plat_names = ['Steak frites']
        plat_prices = [24.99]
        
        # Create additional plats
        for i in range(2, 10):
            plat_id = f'plat{i}'
            
            # Generate different types of dishes
            if i % 3 == 0:
                name = f'Salade Composée #{i}'
                price = 14.99
                category = 'cat1'  # Entrées
                ingredients = ['laitue', 'tomates', 'concombres', 'oignons']
            elif i % 3 == 1:
                name = f'Pasta #{i}'
                price = 19.99
                category = 'cat2'  # Plats principaux
                ingredients = ['pâtes', 'sauce tomate', 'parmesan', 'basilic']
            else:
                name = f'Dessert #{i}'
                price = 9.99
                category = 'cat3'  # Let's assume cat3 is Desserts
                ingredients = ['sucre', 'farine', 'oeufs', 'lait']
                
                # Create category if it doesn't exist
                db.collection('categories').document('cat3').set({'nomCat': 'Desserts'})
            
            plat_ids.append(plat_id)
            plat_names.append(name)
            plat_prices.append(price)
            
            db.collection('plats').document(plat_id).set({
                'nom': name,
                'estimation': random.randint(10, 30),
                'note': round(random.uniform(3.0, 5.0), 1),
                'description': f'Description pour {name}',
                'ingrédients': ingredients,
                'quantité': random.randint(50, 200),
                'idCat': category,
                'prix': price
            })
        
        # Get employee IDs
        employee_ids = ['employe1']
        
        # Create some additional employees
        for i in range(2, 5):
            employee_id = f'employe{i}'
            employee_ids.append(employee_id)
            
            role = random.choice(['serveur', 'cuisinier', 'manager'])
            
            db.collection('employes').document(employee_id).set({
                'nomE': f'Nom{i}',
                'prenomE': f'Prenom{i}',
                'usernameE': f'user{i}',
                'adresseE': f'{i} rue de la Paix, Paris',
                'emailE': f'employe{i}@example.com',
                'numeroE': f'+336987654{i}',
                'motDePasseE': f'hashed_password_{i}',
                'role': role,
                'salaire': 2000.00 + (i * 100),
                'firebase_uid': f'employee_firebase_uid_{i}'
            })
            
            # Add role-specific entries
            if role == 'serveur':
                db.collection('serveurs').document(f'serveur{i}').set({
                    'idE': employee_id,
                    'dateEmbauche': f'2023-0{i}-15'
                })
            elif role == 'cuisinier':
                db.collection('cuisiniers').document(f'cuisinier{i}').set({
                    'idE': employee_id,
                    'dateEmbauche': f'2023-0{i}-15'
                })
            elif role == 'manager':
                db.collection('managers').document(f'manager{i}').set({
                    'idE': employee_id,
                    'idRapport': f'rapport{i}'
                })
        
        # Table IDs
        table_ids = ['table1']
        
        # Create additional tables
        for i in range(2, 8):
            table_id = f'table{i}'
            table_ids.append(table_id)
            
            db.collection('tables').document(table_id).set({
                'nbrPersonne': random.randint(2, 8),
                'etatTable': random.choice(['libre', 'occupée', 'réservée'])
            })
        
        # Create orders with different statuses
        order_statuses = ['en_attente', 'en_preparation', 'pret', 'en_service', 'termine', 'annulee']
        
        # For each status, create 7 orders
        for status in order_statuses:
            for i in range(1, 8):
                # Generate unique command ID
                commande_id = f'commande_{status}_{i}'
                
                # Pick random client and create date
                client_id = random.choice(client_ids)
                
                # Create a timestamp between 1 day and 30 days ago
                days_ago = random.randint(1, 30)
                creation_date = datetime.now() - timedelta(days=days_ago)
                
                # Create random order amount
                num_items = random.randint(1, 4)
                total_amount = 0
                
                # Create the command
                db.collection('commandes').document(commande_id).set({
                    'montant': 0,  # Will update after adding items
                    'dateCreation': creation_date,
                    'etat': status,
                    'confirmation': status != 'en_attente',
                    'idC': client_id
                })
                
                # Add items to the order
                for j in range(num_items):
                    # Select random plat
                    plat_index = random.randint(0, len(plat_ids) - 1)
                    plat_id = plat_ids[plat_index]
                    quantity = random.randint(1, 3)
                    
                    # Calculate item price
                    item_price = plat_prices[plat_index] * quantity
                    total_amount += item_price
                    
                    # Create command-plat relationship
                    cp_id = f'cp_{commande_id}_{j}'
                    db.collection('commande_plat').document(cp_id).set({
                        'idCmd': commande_id,
                        'idP': plat_id,
                        'quantité': quantity
                    })
                
                # Update the order with the total amount
                db.collection('commandes').document(commande_id).update({
                    'montant': round(total_amount, 2)
                })
                
                # Assign a server to the order
                serveur_id = random.choice(employee_ids)
                sc_id = f'sc_{commande_id}'
                db.collection('serveur_commande').document(sc_id).set({
                    'idE': serveur_id,
                    'idCmd': commande_id
                })
        
        # Create assistance requests if the collection exists
        # Let's assume the collection name is 'demandes_assistance'
        assistance_types = ['question', 'probleme', 'reclamation', 'suggestion']
        assistance_statuses = ['ouverte', 'en_traitement', 'resolue', 'fermee']
        
        for i in range(1, 8):
            for status in assistance_statuses:
                assistance_id = f'assistance_{status}_{i}'
                
                db.collection('demandes_assistance').document(assistance_id).set({
                    'client_id': random.choice(client_ids),
                    'employee_id': random.choice(employee_ids) if status != 'ouverte' else None,
                    'type': random.choice(assistance_types),
                    'description': f'Demande d\'assistance de type {random.choice(assistance_types)} #{i}',
                    'status': status,
                    'created_at': firestore.SERVER_TIMESTAMP,
                    'updated_at': firestore.SERVER_TIMESTAMP,
                    'priority': random.choice(['basse', 'normale', 'haute'])
                })
        
        # Update dashboard stats
        total_orders = len(order_statuses) * 7
        weekly_revenue = round(random.uniform(1000, 5000), 2)
        popular_items = random.sample(plat_ids, min(3, len(plat_ids)))
        
        db.collection('stats').document('dashboard_stats').set({
            'totalOrders': total_orders,
            'weeklyRevenue': weekly_revenue,
            'popularItems': popular_items,
            'updatedAt': firestore.SERVER_TIMESTAMP
        })
        
        logger.info(f"Created {total_orders} orders with {len(order_statuses)} different statuses!")
        logger.info(f"Created {len(assistance_statuses) * 7} assistance requests!")
        self.stdout.write(self.style.SUCCESS('Test documents inserted successfully'))