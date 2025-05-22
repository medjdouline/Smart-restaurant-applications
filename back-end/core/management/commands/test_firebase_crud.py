from django.core.management.base import BaseCommand
from core.firebase_crud import firebase_crud
from firebase_admin import firestore

class Command(BaseCommand):
    help = 'Test Firebase CRUD operations'

    def handle(self, *args, **options):
        self.stdout.write('Testing Firebase CRUD operations...')
        
        try:
            # Test client operations
            client_id = 'test_client_id'
            client_data = {
                'username': 'test_user',
                'email': 'test@example.com',
                'motDePasse': 'test_password',
                'isGuest': False
            }
            
            # Create client
            firebase_crud.create_client(client_data, client_id)
            self.stdout.write(self.style.SUCCESS('Created client'))
            
            # Get client
            client = firebase_crud.get_client(client_id)
            self.stdout.write(self.style.SUCCESS(f'Retrieved client: {client}'))
            
            # Update client
            firebase_crud.update_client(client_id, {'username': 'updated_user'})
            updated_client = firebase_crud.get_client(client_id)
            self.stdout.write(self.style.SUCCESS(f'Updated client: {updated_client}'))
            
            # Test menu item operations
            plat_data = {
                'description': 'Test dish',
                'note': 4.5,
                'estimation': 15,
                'ingredients': 'Test ingredients',
                'quantite': 10,
                'idCat': 'example_categorie'
            }
            
            plat_id = firebase_crud.create_plat(plat_data)
            self.stdout.write(self.style.SUCCESS(f'Created plat with ID: {plat_id}'))
            
            plat = firebase_crud.get_plat(plat_id)
            self.stdout.write(self.style.SUCCESS(f'Retrieved plat: {plat}'))
            
            # Test table operations
            table_data = {
                'nbrPersonne': 4,
                'etatTable': 'libre'
            }
            
            table_id = firebase_crud.create_table(table_data)
            self.stdout.write(self.style.SUCCESS(f'Created table with ID: {table_id}'))
            
            # Test order operations
            commande_data = {
                'montant': 25.50,
                'dateCreation': firestore.SERVER_TIMESTAMP,
                'etat': 'en attente',
                'confirmation': False,
                'idC': client_id
            }
            
            commande_id = firebase_crud.create_commande(commande_data)
            self.stdout.write(self.style.SUCCESS(f'Created commande with ID: {commande_id}'))
            
            # Add item to order
            firebase_crud.add_plat_to_commande(commande_id, plat_id, 2)
            self.stdout.write(self.style.SUCCESS('Added plat to commande'))
            
            # Get commande items
            commande_plats = firebase_crud.get_commande_plats(commande_id)
            self.stdout.write(self.style.SUCCESS(f'Commande plats: {commande_plats}'))
            
            # Cleanup - delete test data
            firebase_crud.delete_client(client_id)
            firebase_crud.delete_plat(plat_id)
            firebase_crud.delete_commande(commande_id)
            
            self.stdout.write(self.style.SUCCESS('All CRUD tests passed!'))
            
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'Error during CRUD test: {e}'))