# Create this as debug_firebase.py in your project root
import json
import os
from dotenv import load_dotenv

load_dotenv()

# Check service account key
cred_path = os.getenv('FIREBASE_CREDENTIALS_PATH')
print(f"Credentials path: {cred_path}")
print(f"File exists: {os.path.exists(cred_path)}")

if os.path.exists(cred_path):
    with open(cred_path, 'r') as f:
        cred_data = json.load(f)
    
    print(f"Service Account Project ID: {cred_data.get('project_id')}")
    print(f"Service Account Client Email: {cred_data.get('client_email')}")
    print(f"Service Account Type: {cred_data.get('type')}")

# Check environment
env_project_id = os.getenv('FIREBASE_PROJECT_ID')
print(f"Environment Project ID: {env_project_id}")

# Check if they match
if os.path.exists(cred_path):
    with open(cred_path, 'r') as f:
        cred_data = json.load(f)
    
    if cred_data.get('project_id') == env_project_id:
        print("✅ Project IDs MATCH")
    else:
        print("❌ Project IDs DON'T MATCH - THIS IS THE PROBLEM!")
        print(f"Fix: Update FIREBASE_PROJECT_ID to '{cred_data.get('project_id')}'")