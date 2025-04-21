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
            'fidelityPoints': 100
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
            'nomIng': 'Boeuf',
            'nbrMax': 50,
            'nbrMin': 10
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
            'idCat': cat2_id  
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
            'motDePasseE': 'hashed_password',
            'role': 'serveur'
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

        # Recommandations
        reco_id = 'reco1'
        db.collection('recommandations').document(reco_id).set({
            'date_generation': firestore.SERVER_TIMESTAMP,
            'idC': client_id  # Foreign key
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
            'idP': plat1_id   # Foreign key
        })

        logger.info("Created !")
        self.stdout.write(self.style.SUCCESS('Firestore initialized successfully'))
        