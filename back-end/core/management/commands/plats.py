from django.core.management.base import BaseCommand
from core.firebase_utils import firebase_config
from firebase_admin import firestore
import random
from datetime import datetime, timedelta
import logging

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = 'Insert ingredients into Firebase ingredients collection'

    def get_category(self, ingredient_name):
        """Determine category based on ingredient name"""
        name_lower = ingredient_name.lower()
        
        vegetables = ['oignons', 'oignon', 'tomates', 'tomate', 'poivrons', 'poivron', 'laitue', 
                     'carottes', 'carotte', 'betteraves', 'concombre', 'epinards', 'pommes de terre',
                     'aubergines', 'aubergine', 'courgettes', 'courgette', 'navets', 'navet',
                     'celeri', 'céleri', 'radis', 'légumes']
        
        meats = ['agneau', 'agneau haché', 'viande hachée', 'viande de bœuf', 'bœuf haché',
                'poulet', 'poulet fermier', 'blanc de poulet', 'merguez', 'côtelettes d\'agneau',
                'dinde', 'bœuf']
        
        seafood = ['poisson', 'filet de poisson', 'dorade', 'filet de dorade', 'calamar',
                  'calamars', 'crevettes', 'saumon', 'thon', 'tilapia']
        
        grains = ['frik', 'frik (blé vert)', 'pois chiches', 'lentilles', 'haricots blancs',
                 'semoule', 'semoule fine', 'riz', 'riz basmati', 'boulgour', 'vermicelles',
                 'pain rassis', 'pain', 'pain arabe', 'farine', 'chapelure', 'feuille de brick', 'pâte filo']
        
        herbs_spices = ['ail', 'epices', 'épices', 'menthe fraiche', 'menthe', 'herbes',
                       'persil', 'coriandre', 'thym', 'romarin', 'cumin', 'paprika', 'piment',
                       'cannelle', 'sumac', 'aneth', 'levure', 'sel', 'poivre', 'vanille',
                       'hibiscus séché', 'arômes', 'arômes saisonniers', 'câpres']
        
        dairy_eggs = ['œuf', 'œufs', 'yaourt', 'fromage', 'fromage frais', 'lait', 'creme', 'crème', 'beurre']
        
        fruits = ['citron', 'oranges', 'orange', 'pommes', 'pomme', 'grenades', 'grenade',
                 'pasteque', 'pastèque', 'fruits', 'pruneaux', 'dattes', 'pâte de dattes', 'citron confit']
        
        nuts_seeds = ['olives', 'amandes', 'noix', 'pistaches', 'sesames', 'sésame', 'tahini']
        
        oils_liquids = ['huile dolive', 'huile d\'olive', 'huile', 'eau de rose', 'fleur doranger',
                       'eau de fleur d\'oranger', 'eau', 'eau gazeuse', 'eau minérale', 'soda']
        
        sweets = ['sucre', 'miel']
        
        beverages = ['café turc', 'café algerien', 'café algérien', 'café', 'thé vert']
        
        if name_lower in vegetables:
            return "Légumes"
        elif name_lower in meats:
            return "Viandes"
        elif name_lower in seafood:
            return "Poissons et fruits de mer"
        elif name_lower in grains:
            return "Céréales et légumineuses"
        elif name_lower in herbs_spices:
            return "Épices et herbes"
        elif name_lower in dairy_eggs:
            return "Produits laitiers et œufs"
        elif name_lower in fruits:
            return "Fruits"
        elif name_lower in nuts_seeds:
            return "Noix et graines"
        elif name_lower in oils_liquids:
            return "Huiles et liquides"
        elif name_lower in sweets:
            return "Sucrants"
        elif name_lower in beverages:
            return "Boissons"
        else:
            return "Divers"

    def get_expiration_date(self, category, ingredient_name):
        """Generate realistic expiration dates based on ingredient type"""
        base_date = datetime.now()
        name_lower = ingredient_name.lower()
        
        # Produits très périssables (1-7 jours)
        if category in ["Viandes", "Poissons et fruits de mer"] or "lait" in name_lower:
            days = random.randint(1, 7)
        # Légumes frais (3-14 jours)
        elif category == "Légumes" and any(word in name_lower for word in ["laitue", "épinards", "herbes", "persil", "coriandre", "menthe"]):
            days = random.randint(3, 14)
        # Légumes de garde (7-30 jours)
        elif category == "Légumes":
            days = random.randint(7, 30)
        # Fruits frais (3-21 jours)
        elif category == "Fruits" and "confit" not in name_lower and "pâte" not in name_lower:
            days = random.randint(3, 21)
        # Produits laitiers (5-30 jours)
        elif category == "Produits laitiers et œufs":
            days = random.randint(5, 30)
        # Pain (1-5 jours)
        elif "pain" in name_lower:
            days = random.randint(1, 5)
        # Produits secs et épices (180-720 jours)
        elif category in ["Épices et herbes", "Céréales et légumineuses", "Noix et graines"]:
            days = random.randint(180, 720)
        # Huiles et conserves (90-365 jours)
        elif category in ["Huiles et liquides", "Sucrants"]:
            days = random.randint(90, 365)
        # Boissons (30-365 jours)
        elif category == "Boissons":
            days = random.randint(30, 365)
        else:
            days = random.randint(30, 180)
        
        expiration_date = base_date + timedelta(days=days)
        return expiration_date.strftime("%Y-%m-%d")

    def get_realistic_quantity_and_threshold(self, category, unit, price):
        """Generate realistic quantities and alert thresholds"""
        
        # Produits chers ou de luxe - quantités plus faibles
        if price > 2000:  # Produits très chers
            quantity = random.randint(1, 5)
            threshold = 1
        elif price > 1000:  # Produits chers
            quantity = random.randint(2, 10)
            threshold = random.randint(1, 2)
        elif price > 500:  # Produits moyennement chers
            quantity = random.randint(5, 20)
            threshold = random.randint(2, 5)
        else:  # Produits bon marché
            quantity = random.randint(10, 50)
            threshold = random.randint(3, 10)
        
        # Ajustements par catégorie
        if category == "Viandes":
            quantity = random.randint(2, 15)
            threshold = random.randint(1, 3)
        elif category == "Poissons et fruits de mer":
            quantity = random.randint(1, 10)
            threshold = random.randint(1, 2)
        elif category == "Légumes":
            quantity = random.randint(5, 30)
            threshold = random.randint(2, 8)
        elif category == "Épices et herbes":
            quantity = random.randint(1, 5)
            threshold = 1
        elif category == "Céréales et légumineuses":
            quantity = random.randint(10, 50)
            threshold = random.randint(5, 15)
        elif unit == "unité":
            quantity = random.randint(5, 30)
            threshold = random.randint(2, 8)
        elif unit == "litre":
            quantity = random.randint(2, 20)
            threshold = random.randint(1, 5)
        
        return quantity, threshold

    def handle(self, *args, **options):
        db = firebase_config.get_db()

        # Données des ingrédients
        ingredients_data = {
            # Vegetables
            "oignons": {"price": 70, "unit": "kg"},
            "oignon": {"price": 70, "unit": "kg"},
            "tomates": {"price": 80, "unit": "kg"},
            "tomate": {"price": 80, "unit": "kg"},
            "poivrons": {"price": 130, "unit": "kg"},
            "poivron": {"price": 130, "unit": "kg"},
            "laitue": {"price": 120, "unit": "kg"},
            "carottes": {"price": 75, "unit": "kg"},
            "carotte": {"price": 75, "unit": "kg"},
            "betteraves": {"price": 150, "unit": "kg"},
            "concombre": {"price": 100, "unit": "kg"},
            "epinards": {"price": 100, "unit": "kg"},
            "pommes de terre": {"price": 80, "unit": "kg"},
            "aubergines": {"price": 120, "unit": "kg"},
            "aubergine": {"price": 120, "unit": "kg"},
            "courgettes": {"price": 75, "unit": "kg"},
            "courgette": {"price": 75, "unit": "kg"},
            "navets": {"price": 70, "unit": "kg"},
            "navet": {"price": 70, "unit": "kg"},
            "celeri": {"price": 100, "unit": "kg"},
            "céleri": {"price": 100, "unit": "kg"},
            "radis": {"price": 90, "unit": "kg"},
            "légumes": {"price": 80, "unit": "kg"},
            
            # Meats
            "agneau": {"price": 2600, "unit": "kg"},
            "agneau haché": {"price": 2800, "unit": "kg"},
            "viande hachée": {"price": 2300, "unit": "kg"},
            "viande de bœuf": {"price": 2300, "unit": "kg"},
            "bœuf haché": {"price": 2300, "unit": "kg"},
            "poulet": {"price": 400, "unit": "kg"},
            "poulet fermier": {"price": 450, "unit": "kg"},
            "blanc de poulet": {"price": 500, "unit": "kg"},
            "merguez": {"price": 1600, "unit": "kg"},
            "côtelettes d'agneau": {"price": 2200, "unit": "kg"},
            "dinde": {"price": 700, "unit": "kg"},
            "bœuf": {"price": 2300, "unit": "kg"},
            
            # Seafood
            "poisson": {"price": 1000, "unit": "kg"},
            "filet de poisson": {"price": 1200, "unit": "kg"},
            "dorade": {"price": 1200, "unit": "kg"},
            "filet de dorade": {"price": 1400, "unit": "kg"},
            "calamar": {"price": 2500, "unit": "kg"},
            "calamars": {"price": 2500, "unit": "kg"},
            "crevettes": {"price": 4000, "unit": "kg"},
            "saumon": {"price": 3500, "unit": "kg"},
            "thon": {"price": 1800, "unit": "kg"},
            "tilapia": {"price": 900, "unit": "kg"},
            
            # Grains & Legumes
            "frik": {"price": 100, "unit": "kg"},
            "frik (blé vert)": {"price": 100, "unit": "kg"},
            "pois chiches": {"price": 400, "unit": "kg"},
            "lentilles": {"price": 350, "unit": "kg"},
            "haricots blancs": {"price": 600, "unit": "kg"},
            "semoule": {"price": 120, "unit": "kg"},
            "semoule fine": {"price": 120, "unit": "kg"},
            "riz": {"price": 240, "unit": "kg"},
            "riz basmati": {"price": 400, "unit": "kg"},
            "boulgour": {"price": 300, "unit": "kg"},
            "vermicelles": {"price": 120, "unit": "kg"},
            "pain rassis": {"price": 10, "unit": "unité"},
            "pain": {"price": 20, "unit": "unité"},
            "pain arabe": {"price": 30, "unit": "unité"},
            "farine": {"price": 100, "unit": "kg"},
            "chapelure": {"price": 200, "unit": "kg"},
            "feuille de brick": {"price": 500, "unit": "kg"},
            "pâte filo": {"price": 400, "unit": "kg"},
            
            # Herbs & Spices
            "ail": {"price": 300, "unit": "kg"},
            "epices": {"price": 400, "unit": "kg"},
            "épices": {"price": 400, "unit": "kg"},
            "menthe fraiche": {"price": 200, "unit": "kg"},
            "menthe": {"price": 200, "unit": "kg"},
            "herbes": {"price": 150, "unit": "kg"},
            "persil": {"price": 150, "unit": "kg"},
            "coriandre": {"price": 150, "unit": "kg"},
            "thym": {"price": 300, "unit": "kg"},
            "romarin": {"price": 300, "unit": "kg"},
            "cumin": {"price": 400, "unit": "kg"},
            "paprika": {"price": 400, "unit": "kg"},
            "piment": {"price": 350, "unit": "kg"},
            "cannelle": {"price": 600, "unit": "kg"},
            "sumac": {"price": 800, "unit": "kg"},
            "aneth": {"price": 300, "unit": "kg"},
            "levure": {"price": 800, "unit": "kg"},
            "sel": {"price": 50, "unit": "kg"},
            "poivre": {"price": 800, "unit": "kg"},
            "vanille": {"price": 1000, "unit": "kg"},
            "hibiscus séché": {"price": 600, "unit": "kg"},
            "arômes": {"price": 400, "unit": "kg"},
            "arômes saisonniers": {"price": 400, "unit": "kg"},
            "câpres": {"price": 500, "unit": "kg"},
            
            # Dairy & Eggs
            "œuf": {"price": 20, "unit": "unité"},
            "œufs": {"price": 20, "unit": "unité"},
            "yaourt": {"price": 140, "unit": "litre"},
            "fromage": {"price": 1600, "unit": "kg"},
            "fromage frais": {"price": 1200, "unit": "kg"},
            "lait": {"price": 150, "unit": "litre"},
            "creme": {"price": 200, "unit": "litre"},
            "crème": {"price": 200, "unit": "litre"},
            "beurre": {"price": 1400, "unit": "kg"},
            
            # Fruits
            "citron": {"price": 150, "unit": "kg"},
            "oranges": {"price": 150, "unit": "kg"},
            "orange": {"price": 150, "unit": "kg"},
            "pommes": {"price": 400, "unit": "kg"},
            "pomme": {"price": 400, "unit": "kg"},
            "grenades": {"price": 350, "unit": "kg"},
            "grenade": {"price": 350, "unit": "kg"},
            "pasteque": {"price": 130, "unit": "kg"},
            "pastèque": {"price": 130, "unit": "kg"},
            "fruits": {"price": 350, "unit": "kg"},
            "pruneaux": {"price": 800, "unit": "kg"},
            "dattes": {"price": 400, "unit": "kg"},
            "pâte de dattes": {"price": 600, "unit": "kg"},
            "citron confit": {"price": 300, "unit": "kg"},
            
            # Nuts & Seeds
            "olives": {"price": 600, "unit": "kg"},
            "amandes": {"price": 1600, "unit": "kg"},
            "noix": {"price": 1600, "unit": "kg"},
            "pistaches": {"price": 2000, "unit": "kg"},
            "sesames": {"price": 600, "unit": "kg"},
            "sésame": {"price": 600, "unit": "kg"},
            "tahini": {"price": 600, "unit": "kg"},
            
            # Oils & Liquids
            "huile dolive": {"price": 1000, "unit": "litre"},
            "huile d'olive": {"price": 1000, "unit": "litre"},
            "huile": {"price": 400, "unit": "litre"},
            "eau de rose": {"price": 100, "unit": "litre"},
            "fleur doranger": {"price": 700, "unit": "litre"},
            "eau de fleur d'oranger": {"price": 700, "unit": "litre"},
            "eau": {"price": 5, "unit": "litre"},
            "eau gazeuse": {"price": 60, "unit": "litre"},
            "eau minérale": {"price": 40, "unit": "litre"},
            "soda": {"price": 100, "unit": "litre"},
            
            # Baking & Sweets
            "sucre": {"price": 100, "unit": "kg"},
            "miel": {"price": 2000, "unit": "litre"},
            
            # Beverages
            "café turc": {"price": 2000, "unit": "kg"},
            "café algerien": {"price": 1000, "unit": "kg"},
            "café algérien": {"price": 1000, "unit": "kg"},
            "café": {"price": 1500, "unit": "kg"},
            "thé vert": {"price": 800, "unit": "kg"}
        }

        self.stdout.write("Insertion des ingrédients dans la collection 'ingredients'...")

        count = 0
        for nom, data in ingredients_data.items():
            try:
                # Déterminer la catégorie
                categorie = self.get_category(nom)
                
                # Générer quantité et seuil d'alerte réalistes
                quantite, seuil_alerte = self.get_realistic_quantity_and_threshold(
                    categorie, data["unit"], data["price"]
                )
                
                # Générer date d'expiration réaliste
                date_expiration = self.get_expiration_date(categorie, nom)
                
                # Créer le document
                ingredient_data = {
                    'nom': nom,
                    'categorie': categorie,
                    'cout_par_unite': data["price"] / 100.0,  # Convertir en dinars
                    'unite': data["unit"].capitalize(),
                    'quantite': quantite,
                    'seuil_alerte': seuil_alerte,
                    'date_expiration': date_expiration,
                    'createdAt': firestore.SERVER_TIMESTAMP
                }
                
                # Générer un ID unique basé sur le nom
                doc_id = nom.lower().replace(' ', '_').replace("'", '').replace('é', 'e').replace('è', 'e').replace('ç', 'c')
                
                db.collection('ingredients').document(doc_id).set(ingredient_data)
                count += 1
                
                self.stdout.write(f"Ingrédient ajouté: {nom} ({categorie})")
                
            except Exception as e:
                self.stdout.write(self.style.ERROR(f'Erreur lors de l\'ajout de {nom}: {str(e)}'))

        self.stdout.write(self.style.SUCCESS(f'Insertion de {count} ingrédients terminée avec succès.'))