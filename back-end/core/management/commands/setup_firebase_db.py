from django.core.management.base import BaseCommand
from core.firebase_utils import firebase_config
from firebase_admin import firestore
import datetime

class Command(BaseCommand):
    help = 'Set up Firebase database structure'

    def handle(self, *args, **options):
        
        db = firebase_config.get_db()
        
        if not db:
            self.stdout.write(self.style.ERROR('Failed to connect to Firebase database'))
            return
            
       
        # 1. clients
        db.collection('clients').document('example_client').set({
            'username': 'client_test',
            'email': 'client@example.com',
            'motDePasse': 'hashed_password_example',
            'isGuest': False
        })
        
        # 2. tables
        db.collection('tables').document('1').set({
            'nbrPersonne': 4,
            'etatTable': 'libre'
        })
        
        # 3. reservations
        db.collection('reservations').document('example_reservation').set({
            'date': firestore.SERVER_TIMESTAMP,
            'heure': '19:30',
            'idT': '1',  # Reference to table id
            'idC': 'example_client'  # Reference to client id
        })
        
        # 4. fidelite
        db.collection('fidelite').document('example_fidelite').set({
            'pointsFidelite': 100,
            'SeuilVIP': 500,
            'idC': 'example_client'  # Reference to client id
        })
        
        # 5. commandes
        db.collection('commandes').document('example_commande').set({
            'montant': 45.50,
            'dateCreation': firestore.SERVER_TIMESTAMP,
            'etat': 'en attente',
            'confirmation': False,
            'idC': 'example_client'  # Reference to client id
        })
        
        # 6. categorie (needed for plat)
        db.collection('categorie').document('example_categorie').set({
            'nomCat': 'Plats principaux'
        })
        
        # 7. plat
        db.collection('plat').document('example_plat').set({
            'estimation': 15,  # minutes for preparation
            'note': 4.5,
            'description': 'Délicieux steak frites',
            'ingredients': 'Boeuf, pommes de terre, huile, sel, poivre',
            'quantite': 100,
            'idCat': 'example_categorie'  # Reference to categorie id
        })
        
        # 8. commande_plat (junction table)
        db.collection('commande_plat').document('example_cmd_plat').set({
            'idCmd': 'example_commande',
            'idP': 'example_plat',
            'quantite': 2
        })
        
        # 9. menu
        db.collection('menu').document('example_menu').set({
            'nomMenu': 'Menu du jour'
        })
        
        # 10. menu_plat (junction table)
        db.collection('menu_plat').document('example_menu_plat').set({
            'idM': 'example_menu',
            'idP': 'example_plat'
        })
        
        # 11. employe - base employee
        db.collection('employe').document('example_employe_serveur').set({
            'nomE': 'Dupont',
            'prenomE': 'Jean',
            'usernameE': 'jean_dupont',
            'adresseE': '123 rue de Paris',
            'motDePasseE': 'hashed_password_example',
            'role': 'serveur'
        })
        
        db.collection('employe').document('example_employe_cuisinier').set({
            'nomE': 'Martin',
            'prenomE': 'Pierre',
            'usernameE': 'pierre_martin',
            'adresseE': '45 avenue de Lyon',
            'motDePasseE': 'hashed_password_example',
            'role': 'cuisinier'
        })
        
        db.collection('employe').document('example_employe_manager').set({
            'nomE': 'Dubois',
            'prenomE': 'Marie',
            'usernameE': 'marie_dubois',
            'adresseE': '8 boulevard des Fleurs',
            'motDePasseE': 'hashed_password_example',
            'role': 'manager'
        })
        
        # 12. cuisinier
        db.collection('cuisinier').document('example_cuisinier').set({
            'idE': 'example_employe_cuisinier',  # Reference to employe
            'dateEmbauche': firestore.SERVER_TIMESTAMP,
            'niveauExperience': 'Chef'
        })
        
        # 13. cuisinier_menu (junction table)
        db.collection('cuisinier_menu').document('example_cuisinier_menu').set({
            'idE': 'example_employe_cuisinier',  # Reference to employe (cuisinier)
            'idM': 'example_menu',  # Reference to menu
            'datecreation': firestore.SERVER_TIMESTAMP,
            'derniereMAJ': firestore.SERVER_TIMESTAMP
        })
        
        # 14. ingredient
        db.collection('ingredient').document('example_ingredient').set({
            'nomIng': 'Pommes de terre',
            'nbrMax': 100,
            'nbrMin': 20
        })
        
        # 15. stock
        db.collection('stock').document('example_stock').set({
            'capaciteS': 100,
            'SeuilAlerte': 20,
            'idIng': 'example_ingredient'  # Reference to ingredient
        })
        
        # 16. manager
        db.collection('manager').document('example_manager').set({
            'idE': 'example_employe_manager',  # Reference to employe
            'idRapport': 'example_rapport'  # Reference to rapport_financier
        })
        
        # 17. serveur
        db.collection('serveur').document('example_serveur').set({
            'idE': 'example_employe_serveur',  # Reference to employe
            'dateEmbauche': firestore.SERVER_TIMESTAMP,
            'zoneAffectation': 'Zone A'
        })
        
        # 18. serveur_commande (junction table)
        db.collection('serveur_commande').document('example_serveur_commande').set({
            'idE': 'example_employe_serveur',  # Reference to employe (serveur)
            'idCmd': 'example_commande'  # Reference to commande
        })
        
        # 19. montantencaisse
        db.collection('montantencaisse').document('example_montant').set({
            'dateMontant': firestore.SERVER_TIMESTAMP,
            'totalEncaisse': 1250.75
        })
        
        # 20. depenses
        db.collection('depenses').document('example_depense').set({
            'dateDep': firestore.SERVER_TIMESTAMP,
            'totaleDep': 450.25
        })
        
        # 21. rapport_financier
        db.collection('rapport_financier').document('example_rapport').set({
            'dateRapport': firestore.SERVER_TIMESTAMP,
            'beneficeNet': 800.50,
            'idMontant': 'example_montant',  # Reference to montantencaisse
            'idDep': 'example_depense'  # Reference to depenses
        })
        
        # 22. recommandation
        db.collection('recommandation').document('example_recommandation').set({
            'date_generation': firestore.SERVER_TIMESTAMP,
            'idC': 'example_client'  # Reference to client
        })
        
        # 23. recommandation_plat (junction table)
        db.collection('recommandation_plat').document('example_recommandation_plat').set({
            'idR': 'example_recommandation',  # Reference to recommandation
            'idP': 'example_plat'  # Reference to plat
        })
        
        self.stdout.write(self.style.SUCCESS('Successfully created Firebase database'))