from django.core.management.base import BaseCommand
from core.firebase_utils import firebase_config
from firebase_admin import firestore
import logging
from datetime import datetime

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = 'Initialize Firestore'

    def handle(self, *args, **options):
        db = firebase_config.get_db()

        # Clients
        client_id = 'client_exemple'
        db.collection('clients').document(client_id).set({
            'username': 'client_test',
            'email': 'client@exemple.com',
            'motDePasse': 'hashed_password',
            'isGuest': False,
            'birthdate': '1990-01-01',
            'gender': 'homme',  # New field
            'phoneNumber': '+33612345678',  # New field
            'fidelityPoints': 100,
            'preferences': ['Soupes et Potages', 'Viandes', 'Pâtisseries'],  # New field - minimum 3 choices
            'allergies': ['Gluten', 'Arachides'],  # New field - optional
            'restrictions': ['Sans gluten']  # New field - optional
        })

        # Categories
        cat1_id, cat2_id = 'cat1', 'cat2'
        db.collection('categories').document(cat1_id).set({'nomCat': 'Entrées'})
        db.collection('categories').document(cat2_id).set({'nomCat': 'Plats principaux'})

        # Sous-categories
        sous_cat1_id = 'sous_cat1'
        sous_cat2_id = 'sous_cat2'
        db.collection('sous_categories').document(sous_cat1_id).set({
            'nomSousCat': 'Soupes et Potages',
            'idCat': cat1_id  # Foreign key to parent category
        })
        db.collection('sous_categories').document(sous_cat2_id).set({
            'nomSousCat': 'Salades et Crudités',
            'idCat': cat1_id  # Foreign key to parent category
        })

       # Ingredients
        ing1_id = 'ing1'
        db.collection('ingredients').document(ing1_id).set({
    'nom': 'Boeuf',
    'categorie': 'Viandes',  # ou cat2_id si tu veux référencer une catégorie existante
    'quantite': 10,
    'unite': 'Kilogramme (kg)',
    'date_expiration': '2025-06-30',
    'seuil_alerte': 3,
    'cout_par_unite': 12.5  # exemple de coût
        })



        # Plats 
        plat1_id = 'plat1'
        db.collection('plats').document(plat1_id).set({
            'nom': 'Steak frites',
            'estimation': 15,
            'note': 4.5,
            'description': 'Steak de boeuf grillé avec frites maison',
            'ingrédients': ['boeuf', 'pommes de terre', 'huile', 'sel'],
            'quantité': 100,
            'idCat': cat2_id,
            'prix': 24.99  # Add this field
        })
        
        # Tables
        table1_id = 'table1'
        db.collection('tables').document(table1_id).set({
            'nbrPersonne': 4,
            'etatTable': 'libre'
        })

        # Employes
        employe1_id = 'employe1'
        db.collection('employes').document(employe1_id).set({
            'nomE': 'Dupont',
            'prenomE': 'Jean',
            'usernameE': 'jdupont',
            'adresseE': '15 rue de la Paix, Paris',
            'emailE': 'jdupont@example.com',  
            'numeroE': '+33612345678',  
            'motDePasseE': 'hashed_password',
            'role': 'serveur',
            'salaire': 2500.00,  
            'firebase_uid': 'employee_firebase_uid_example'  
        })

        # Commandes 
        commande_id = 'commande_exemple'
        db.collection('commandes').document(commande_id).set({
            'montant': 45.50,
            'dateCreation': firestore.SERVER_TIMESTAMP,
            'etat': 'en_attente',
            'confirmation': False,
            'idC': client_id  # Foreign key kept
        })

        # Menus
        menu1_id = 'menu1'
        db.collection('menus').document(menu1_id).set({'nomMenu': 'Menu du jour'})

        # Stocks
        db.collection('stocks').document('stock1').set({
            'capaciteS': 100,
            'SeuilAlerte': 20,
            'idIng': ing1_id  # Foreign key kept
        })

        # Commande_plat
        db.collection('commande_plat').document('cp1').set({
            'idCmd': commande_id,  # Foreign key
            'idP': plat1_id,      # Foreign key
            'quantité': 2
        })

        # Serveur_commande
        db.collection('serveur_commande').document('sc1').set({
            'idE': employe1_id,   # Foreign key
            'idCmd': commande_id  # Foreign key
        })

        # Cuisiniers
        db.collection('cuisiniers').document('cuisinier1').set({
            'idE': employe1_id,      # Foreign key
            'dateEmbauche': '2023-01-15'
        })

        # Fidelite
        db.collection('fidelite').document('fidele1').set({
            'pointsFidelite': 150,
            'SeuilVIP': 500,
            'idC': client_id  # Foreign key
        })

         # Reservations
        reservation_id = 'reservation1'
        db.collection('reservations').document(reservation_id).set({
            'client_id': client_id,
            'table_id': table1_id,
            'date_time': '2025-04-30T19:30',
            'party_size': 2,
            'status': 'confirmed',
            'created_at': firestore.SERVER_TIMESTAMP
        })

        # Recommandations
        reco_id = 'reco1'
        db.collection('recommandations').document(reco_id).set({
            'date_generation': firestore.SERVER_TIMESTAMP,  
            'idC': client_id
        })

        # Recommandation_plat
        db.collection('recommandation_plat').document('rp1').set({
            'idR': reco_id,    # Foreign key
            'idP': plat1_id   # Foreign key
        })

        # Managers
        db.collection('managers').document('manager1').set({
            'idE': employe1_id,     # Foreign key
            'idRapport': 'rapport1'
        })

        # Rapport_financier
        db.collection('rapport_financier').document('rapport1').set({
            'dateRapport': '2023-12-31',
            'beneficeNet': 15000.50,
            'idMontant': 'montant1',  # Foreign key
            'idDep': 'depense1'       # Foreign key
        })

        # Montant_encaisse
        db.collection('montant_encaisse').document('montant1').set({
            'dateMontant': '2023-12-31',
            'totalEncaissé': 45000.75
        })

        # Depenses
        db.collection('depenses').document('depense1').set({
            'dateDep': '2023-12-31',
            'totaleDep': 30000.25
        })

        # Cuisinier_menu
        db.collection('cuisinier_menu').document('cm1').set({
            'idE': employe1_id,  # Foreign key
            'idM': menu1_id,     # Foreign key
            'datecreation': '2023-05-10',
            'derniereMAJ': '2023-07-20'
        })

        # Menu_plat
        db.collection('menu_plat').document('mp1').set({
            'idM': menu1_id,  # Foreign key
            'idP': plat1_id   
        })

        # Serveurs (updated to match schema)
        db.collection('serveurs').document('serveur1').set({
            'idE': employe1_id,  
            'dateEmbauche': '2023-01-15'
})
        message_id = 'msg1'
        db.collection('messages').document(message_id).set({
    'sender': 'employe1',  # Could be employee ID or client ID
    'recipient': 'client_exemple',
    'content': 'Votre réservation pour demain a été confirmée',
    'timestamp': firestore.SERVER_TIMESTAMP,
    'read': False,
    'createdAt': firestore.SERVER_TIMESTAMP
})

       
        db.collection('stats').document('dashboard_stats').set({
    'totalOrders': 42,
    'weeklyRevenue': 1250.75,
    'popularItems': ['plat1', 'plat_101', 'plat_102'], 
    'updatedAt': firestore.SERVER_TIMESTAMP
})
        
        notification1_id = 'notification1'
        db.collection('notifications').document(notification1_id).set({
    'recipient_id': client_id,  
    'recipient_type': 'client', 
    'title': 'Welcome to our restaurant!',
    'message': 'Thank you for joining us. Enjoy special offers and personalized recommendations.',
    'created_at': firestore.SERVER_TIMESTAMP,
    'read': False,
    'type': 'welcome',
    'priority': 'normal'  
})


        notification2_id = 'notification2'
        db.collection('notifications').document(notification2_id).set({
    'recipient_id': employe1_id,  
    'recipient_type': 'cuisinier',
    'title': 'Nouvelle commande à préparer',
    'message': 'Une commande de Steak frites vient d\'être passée.',
    'created_at': firestore.SERVER_TIMESTAMP,
    'read': False,
    'type': 'new_order',
    'priority': 'high',
    'related_id': commande_id  
})


        notification3_id = 'notification3'
        db.collection('notifications').document(notification3_id).set({
    'recipient_id': employe1_id,  
    'recipient_type': 'serveur',
    'title': 'Commande prête',
    'message': 'La commande pour la table 1 est prête à être servie.',
    'created_at': firestore.SERVER_TIMESTAMP,
    'read': False,
    'type': 'order_ready',
    'priority': 'high',
    'related_id': commande_id  
})


        notification4_id = 'notification4'
        db.collection('notifications').document(notification4_id).set({
    'recipient_id': employe1_id, 
    'recipient_type': 'manager',
    'title': 'Stock faible',
    'message': 'Le stock de Boeuf est en dessous du seuil d\'alerte.',
    'created_at': firestore.SERVER_TIMESTAMP,
    'read': False,
    'type': 'low_stock',
    'priority': 'normal',
    'related_id': ing1_id  
})
        db.collection('stats').document('dashboard_stats').set({
    'totalOrders': 42,
    'weeklyRevenue': 1250.75,
    'popularItems': ['plat1', 'plat2', 'plat3'],  # Array of popular item IDs
    'updatedAt': firestore.SERVER_TIMESTAMP
})
        db.collection('SalesBySubcategory').document('sales_subcat1').set({         
    'souscat_id': sous_cat1_id ,
    'Sales': 5000.00,
        })
        assistance1_id = 'assistance1'


        demande_annulation_id = 'demande_annulation1'
        db.collection('DemandeAnnulation').document(demande_annulation_id).set({
    'idClient': client_id,
    'idServeur': employe1_id,
    'idCommande': commande_id,
    'statut': 'en_attente',
    'createdAt': firestore.SERVER_TIMESTAMP
})

# Ajout d'exemples supplémentaires
        demande_annulation_examples = [
    {
        'idClient': client_id,
        'idServeur': employe1_id,
        'idCommande': commande_id,
        'statut': 'approuvée',
        'createdAt': firestore.SERVER_TIMESTAMP
    },
    {
        'idClient': client_id,
        'idServeur': employe1_id,
        'idCommande': commande_id,
        'statut': 'refusée',
        'createdAt': firestore.SERVER_TIMESTAMP
    }
]


        for i, exemple in enumerate(demande_annulation_examples, 2):
         db.collection('DemandeAnnulation').document(f'demande_annulation{i}').set(exemple)


        db.collection('demandeAssistance').document(assistance1_id).set({
    'idC': client_id,
    'idTable': 'table1',
    'etat': 'non traitee',
    'createdAt': firestore.SERVER_TIMESTAMP
})
# 10 exemples de documents pour la collection demandeAssistance
        assistance_examples = [
    {
        'idC': client_id,
        'idTable': 'table2',
        'etat': 'traitee',
        'createdAt': firestore.SERVER_TIMESTAMP
    },
    {
        'idC': client_id,
        'idTable': 'table3',
        'etat': 'non traitee',
        'createdAt': firestore.SERVER_TIMESTAMP
    },
    {
        'idC': client_id,
        'idTable': 'table4',
        'etat': 'traitee',
        'createdAt': firestore.SERVER_TIMESTAMP
    },
    {
        'idC': client_id,
        'idTable': 'table1',
        'etat': 'non traitee',
        'createdAt': firestore.SERVER_TIMESTAMP
    },
    {
        'idC': client_id,
        'idTable': 'table5',
        'etat': 'traitee',
        'createdAt': firestore.SERVER_TIMESTAMP
    },
    {
        'idC': client_id,
        'idTable': 'table6',
        'etat': 'non traitee',
        'createdAt': firestore.SERVER_TIMESTAMP
    },
    {
        'idC': client_id,
        'idTable': 'table7',
        'etat': 'traitee',
        'createdAt': firestore.SERVER_TIMESTAMP
    },
    {
        'idC': client_id,
        'idTable': 'table2',
        'etat': 'non traitee',
        'createdAt': firestore.SERVER_TIMESTAMP
    },
    {
        'idC': client_id,
        'idTable': 'table3',
        'etat': 'traitee',
        'createdAt': firestore.SERVER_TIMESTAMP
    },
    {
        'idC': client_id,
        'idTable': 'table4',
        'etat': 'non traitee',
        'createdAt': firestore.SERVER_TIMESTAMP
    }
]

# Ajout des exemples à la collection
        for i, exemple in enumerate(assistance_examples, 2):
         db.collection('demandeAssistance').document(f'assistance{i}').set(exemple)
        
         logger.info("Created !")
         self.stdout.write(self.style.SUCCESS('Firestore initialized successfully'))
        