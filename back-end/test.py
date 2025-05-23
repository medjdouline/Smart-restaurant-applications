import os
from dotenv import load_dotenv

load_dotenv()
firebase_path = os.path.abspath(os.getenv('FIREBASE_CREDENTIALS_PATH'))
print(f"Chemin Firebase: {firebase_path}")
print(f"Fichier existe: {os.path.exists(firebase_path)}")