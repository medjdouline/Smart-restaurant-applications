from django.core.management.base import BaseCommand
from core.firebase_utils import firebase_config
import logging
import csv
import os

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = 'Recreate plats collection with proper ID field naming'

    def handle(self, *args, **options):
        db = firebase_config.get_db()
        
        # 1. First delete all existing plats
        self.stdout.write("Deleting existing plats...")
        batch = db.batch()
        plats_ref = db.collection('plats')
        
        for plat in plats_ref.stream():
            batch.delete(plat.reference)
        
        batch.commit()
        self.stdout.write("All existing plats deleted.")
        
        # 2. Get the path to menu.txt in the same directory as this script
        script_dir = os.path.dirname(os.path.abspath(__file__))
        menu_path = os.path.join(script_dir, 'menu.txt')
        
        # 3. Read the menu data
        try:
            with open(menu_path, mode='r', encoding='utf-8') as file:
                reader = csv.DictReader(file)
                data = [row for row in reader]
        except FileNotFoundError:
            self.stdout.write(self.style.ERROR(
                f"Could not find menu.txt at: {menu_path}\n"
                "Please ensure the file exists in the same directory as this command."
            ))
            return
        except Exception as e:
            self.stdout.write(self.style.ERROR(
                f"Error reading menu file: {str(e)}"
            ))
            return
        
        # 4. Get categories and sous-categories mapping
        cat_map = {cat.to_dict()['nomCat']: cat.id for cat in db.collection('categories').stream()}
        sous_cat_map = {sous_cat.to_dict()['nomSousCat']: sous_cat.id for sous_cat in db.collection('sous_categories').stream()}
        
        # 5. Recreate all plat documents with proper field names
        count = 0
        for item in data:
            plat_id = item['id_article']  # Using the original ID from CSV
            
            try:
                db.collection('plats').document(plat_id).set({
                    'id': plat_id,  # Stored as 'id' to match API expectations
                    'nom': item['nom_article'],
                    'description': item['description'],
                    'prix': int(item['prix']),
                    'idCat': cat_map[item['catégorie']],
                    'idSousCat': sous_cat_map[item['sous_catégorie']],
                    'estimation': 15,  # Default value
                    'note': 4.0,       # Default value
                    'quantité': 100,   # Default value
                    'ingrédients': [x.strip() for x in item['ingrédients'].split(',')]  # Added ingredients
                })
                
                count += 1
                if count % 10 == 0:
                    self.stdout.write(f"Processing... {count} plats created")
                    
            except Exception as e:
                self.stdout.write(self.style.ERROR(
                    f"Error creating plat {item['nom_article']} (ID: {plat_id}): {str(e)}"
                ))
        
        self.stdout.write(self.style.SUCCESS(
            f"Plats collection recreated successfully! {count} plats created with proper field naming."
        ))