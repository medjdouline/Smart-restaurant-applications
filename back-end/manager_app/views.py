import logging
from firebase_admin import firestore
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from core.firebase_utils import firebase_config
from core.orders_utils import get_all_orders, get_orders_by_status, get_order_details
from core.permissions import IsManager, IsManager, IsServer, IsManagerOrServer, IsStaff, IsManagerOrChef
from django.http import JsonResponse
from django.views.decorators.http import require_http_methods
from datetime import datetime, timedelta
from core.firebase_crud import firebase_crud

import uuid
from datetime import datetime

logger = logging.getLogger(__name__)
db = firebase_config.get_db()

# Orders (Commandes) endpoints
@api_view(['GET'])
@permission_classes([IsManager])
def get_all_commandes(request):
    """Get all orders regardless of status"""
    try:
        logger.info("Fetching all commandes")
        commandes = get_all_orders(db)
        logger.info(f"Retrieved {len(commandes)} commandes")
        return Response(commandes, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error fetching commandes: {str(e)}", exc_info=True)
        return Response(
            {'error': f"Failed to get commandes: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
@permission_classes([IsManager])
def get_commandes_en_attente(request):
    """Get orders with 'en_attente' status"""
    try:
        logger.info("Fetching commandes with status: en_attente")
        # Handle all waiting status variants
        status_values = ['en_attente', 'en attente', 'pending']
        commandes = get_orders_by_status(status_values, db)
        logger.info(f"Retrieved {len(commandes)} commandes with status en_attente")
        return Response(commandes, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error fetching en_attente commandes: {str(e)}", exc_info=True)
        return Response(
            {'error': f"Failed to get commandes: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
@permission_classes([IsManager])
def get_commandes_lancees(request):
    """Get orders with 'en_preparation' or 'prete' status"""
    try:
        logger.info("Fetching commandes with status: en_preparation or prete")
        # Get both 'preparing' and 'ready' status variants
        status_values = ['en_preparation', 'en preparation', 'preparing', 'pret', 'prete', 'ready']
        commandes = get_orders_by_status(status_values, db)
        logger.info(f"Retrieved {len(commandes)} commandes with status en_preparation or prete")
        return Response(commandes, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error fetching lancees commandes: {str(e)}", exc_info=True)
        return Response(
            {'error': f"Failed to get commandes: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
@permission_classes([IsManager])
def get_commandes_servies(request):
    """Get orders with 'servie' status"""
    try:
        logger.info("Fetching commandes with status: servie")
        # Handle all served status variants
        status_values = ['servi', 'servie', 'en_service', 'served']
        commandes = get_orders_by_status(status_values, db)
        logger.info(f"Retrieved {len(commandes)} commandes with status servie")
        return Response(commandes, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error fetching servie commandes: {str(e)}", exc_info=True)
        return Response(
            {'error': f"Failed to get commandes: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
@permission_classes([IsManager])
def get_commandes_annulees(request):
    """Get orders with 'annulee' status"""
    try:
        logger.info("Fetching commandes with status: annulee")
        # Handle all cancelled status variants
        status_values = ['annule', 'annulee', 'cancelled']
        commandes = get_orders_by_status(status_values, db)
        logger.info(f"Retrieved {len(commandes)} commandes with status annulee")
        return Response(commandes, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error fetching annulee commandes: {str(e)}", exc_info=True)
        return Response(
            {'error': f"Failed to get commandes: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

# Categories endpoints
@api_view(['GET'])
@permission_classes([IsManager])
def get_categories(request):
    """Get all categories"""
    try:
        logger.info("Fetching all categories")
        categories_ref = db.collection('categories')
        categories = []
        
        for doc in categories_ref.stream():
            category = doc.to_dict()
            category['id'] = doc.id
            categories.append(category)
            
        logger.info(f"Retrieved {len(categories)} categories")
        return Response(categories, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error fetching categories: {str(e)}", exc_info=True)
        return Response(
            {'error': f"Failed to get categories: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
@permission_classes([IsManager])
def get_sous_categories(request):
    """Get all sous-categories with their parent category"""
    try:
        logger.info("Fetching all sous-categories")
        sous_categories_ref = db.collection('sous_categories')
        sous_categories = []
        
        for doc in sous_categories_ref.stream():
            sous_cat = doc.to_dict()
            sous_cat['id'] = doc.id
            
            # Get parent category
            if 'idCat' in sous_cat:
                cat_ref = db.collection('categories').document(sous_cat['idCat'])
                cat_doc = cat_ref.get()
                if cat_doc.exists:
                    sous_cat['category_name'] = cat_doc.to_dict().get('nomCat', 'Unknown')
                    
            sous_categories.append(sous_cat)
            
        logger.info(f"Retrieved {len(sous_categories)} sous-categories")
        return Response(sous_categories, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error fetching sous-categories: {str(e)}", exc_info=True)
        return Response(
            {'error': f"Failed to get sous-categories: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

# Plats (Dishes) endpoints
@api_view(['GET'])
@permission_classes([IsManager])
def get_all_plats(request):
    """Get all dishes"""
    try:
        logger.info("Fetching all plats")
        plats_ref = db.collection('plats')
        plats = []
        
        for doc in plats_ref.stream():
            plat = doc.to_dict()
            plat['id'] = doc.id
            
            # Get category information
            if 'idCat' in plat:
                cat_ref = db.collection('categories').document(plat['idCat'])
                cat_doc = cat_ref.get()
                if cat_doc.exists:
                    plat['category_name'] = cat_doc.to_dict().get('nomCat', 'Unknown')
                    
            plats.append(plat)
            
        logger.info(f"Retrieved {len(plats)} plats")
        return Response(plats, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error fetching plats: {str(e)}", exc_info=True)
        return Response(
            {'error': f"Failed to get plats: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['POST'])
@permission_classes([IsManager])
def add_plat(request):
    """Add a new dish"""
    try:
        logger.info(f"Adding new plat with data: {request.data}")
        
        # Validate required fields
        required_fields = ['nom', 'description', 'prix', 'idCat', 'ingrédients']
        for field in required_fields:
            if field not in request.data:
                return Response(
                    {'error': f'Missing required field: {field}'},
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        # Create plat document
        plat_data = {
            'nom': request.data['nom'],
            'description': request.data['description'],
            'prix': float(request.data['prix']),
            'idCat': request.data['idCat'],
            'ingrédients': request.data['ingrédients'],
            'estimation': request.data.get('estimation', 15),
            'note': request.data.get('note', 0),
            'quantité': request.data.get('quantité', 0)
        }
        
        # Add to Firestore
        plat_ref = db.collection('plats').document()
        plat_ref.set(plat_data)
        
        logger.info(f"Plat created with ID: {plat_ref.id}")
        
        # Return success with new plat data
        response_data = plat_data.copy()
        response_data['id'] = plat_ref.id
        
        return Response(response_data, status=status.HTTP_201_CREATED)
    except Exception as e:
        logger.error(f"Error adding plat: {str(e)}", exc_info=True)
        return Response(
            {'error': f"Failed to add plat: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['PUT'])
@permission_classes([IsManager])
def update_plat(request, plat_id):
    """Update an existing dish"""
    try:
        logger.info(f"Updating plat {plat_id} with data: {request.data}")
        
        # Check if plat exists
        plat_ref = db.collection('plats').document(plat_id)
        plat_doc = plat_ref.get()
        
        if not plat_doc.exists:
            return Response(
                {'error': f'Plat with ID {plat_id} not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Update fields
        update_data = {}
        allowed_fields = ['nom', 'description', 'prix', 'idCat', 'ingrédients', 'estimation', 'note', 'quantité']
        
        for field in allowed_fields:
            if field in request.data:
                # Convert price to float
                if field == 'prix':
                    update_data[field] = float(request.data[field])
                else:
                    update_data[field] = request.data[field]
        
        # Update in Firestore
        plat_ref.update(update_data)
        
        logger.info(f"Plat {plat_id} updated successfully")
        
        # Get updated plat
        updated_plat = plat_ref.get().to_dict()
        updated_plat['id'] = plat_id
        
        return Response(updated_plat, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error updating plat {plat_id}: {str(e)}", exc_info=True)
        return Response(
            {'error': f"Failed to update plat: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['DELETE'])
@permission_classes([IsManager])
def delete_plat(request, plat_id):
    """Delete a dish"""
    try:
        logger.info(f"Deleting plat with ID: {plat_id}")
        
        # Check if plat exists
        plat_ref = db.collection('plats').document(plat_id)
        plat_doc = plat_ref.get()
        
        if not plat_doc.exists:
            return Response(
                {'error': f'Plat with ID {plat_id} not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Delete from Firestore
        plat_ref.delete()
        

        menu_plat_refs = db.collection('menu_plat').where('idP', '==', plat_id)
        for doc in menu_plat_refs.stream():
            doc.reference.delete()
            logger.info(f"Deleted menu_plat reference: {doc.id}")
        
        logger.info(f"Plat {plat_id} deleted successfully")
        
        return Response(
            {'message': f'Plat with ID {plat_id} deleted successfully'},
            status=status.HTTP_200_OK
        )
    except Exception as e:
        logger.error(f"Error deleting plat {plat_id}: {str(e)}", exc_info=True)
        return Response(
            {'error': f"Failed to delete plat: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
@permission_classes([IsManager])
def get_plat_cost_details(request, plat_id):
    """Get detailed cost breakdown of a dish"""
    try:
        logger.info(f"Fetching cost details for plat {plat_id}")
        
        # Get plat info
        plat_ref = db.collection('plats').document(plat_id)
        plat_doc = plat_ref.get()
        
        if not plat_doc.exists:
            return Response(
                {'error': f'Plat with ID {plat_id} not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        plat_data = plat_doc.to_dict()
        

        ingredients = plat_data.get('ingrédients', [])

        ingredient_costs = []
        total_cost = 0
        

        for ingredient in ingredients:
            #random data rien de concret since c du front
            cost = round(float(0.35 + (hash(ingredient) % 100) / 100), 2)  # Random cost between 0.35 and 1.35
            quantity = round((hash(ingredient) % 10) / 10 + 0.05, 2)  # Random quantity
            unit = "kg" if hash(ingredient) % 2 == 0 else "l"
            
            ingredient_costs.append({
                "name": ingredient,
                "quantity": quantity,
                "unit": unit,
                "cost": cost
            })
            total_cost += cost
        
        # Round to 2 decimal places
        total_cost = round(total_cost, 2)
        selling_price = float(plat_data.get('prix', 0))
        margin = round(selling_price - total_cost, 2)
        margin_percentage = round((margin / selling_price) * 100, 1) if selling_price > 0 else 0
        
        cost_details = {
            "plat_id": plat_id,
            "nom": plat_data.get('nom', 'Unknown'),
            "prix_de_vente": selling_price,
            "cout_total": total_cost,
            "marge": margin,
            "marge_percentage": margin_percentage,
            "ingredients": ingredient_costs
        }
        
        logger.info(f"Retrieved cost details for plat {plat_id}")
        return Response(cost_details, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error fetching cost details for plat {plat_id}: {str(e)}", exc_info=True)
        return Response(
            {'error': f"Failed to get plat cost details: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
        
@api_view(['GET'])
@permission_classes([IsManagerOrChef])
def get_all_ingredients(request):
    """
    Get all ingredients in the inventory.
    """
    try:
        ingredients = firebase_crud.get_all_docs('ingredients')
        return Response({'ingredients': ingredients}, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([IsManagerOrChef])
def add_ingredient(request):
    """
    Add a new ingredient to the inventory.
    Required fields: nom, categorie, quantite, unite, date_expiration, seuil_alerte, cout_par_unite
    """
    try:
        data = request.data
        
        # Validate required fields
        required_fields = ['nom', 'categorie', 'quantite', 'unite', 'date_expiration', 'seuil_alerte', 'cout_par_unite']
        for field in required_fields:
            if field not in data:
                return Response({'error': f"Le champ '{field}' est requis"}, status=status.HTTP_400_BAD_REQUEST)
        
        # Create ingredient document
        ingredient_data = {
            'nom': data['nom'],
            'categorie': data['categorie'],
            'quantite': float(data['quantite']),
            'unite': data['unite'],
            'date_expiration': data['date_expiration'],
            'seuil_alerte': float(data['seuil_alerte']),
            'cout_par_unite': float(data['cout_par_unite']),
            'createdAt': firestore.SERVER_TIMESTAMP
        }
        
        # Generate a unique ID or use provided one
        ingredient_id = str(uuid.uuid4()) if 'id' not in data else data['id']

        # Add to Firestore - FIXED ORDER OF PARAMETERS
        firebase_crud.create_doc('ingredients', ingredient_data, ingredient_id)
        
        # Create corresponding stock entry
        stock_data = {
            'capaciteS': float(data['quantite']),
            'SeuilAlerte': float(data['seuil_alerte']),
            'idIng': ingredient_id,
            'updatedAt': firestore.SERVER_TIMESTAMP
        }
        
        stock_id = f"stock_{ingredient_id}"
        firebase_crud.create_doc('stocks', stock_data, stock_id)  # ALSO FIXED HERE
        
        return Response({
            'success': True,
            'message': 'Ingrédient ajouté avec succès',
            'ingredient_id': ingredient_id
        }, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
# 3. Restock an ingredient
@api_view(['POST'])
@permission_classes([IsManagerOrChef])
def restock_ingredient(request, ingredient_id):
    """
    Update inventory stock level for an ingredient.
    Required field: quantite (amount to add to current stock)
    """
    try:
        data = request.data
        
        # Validate required field
        if 'quantite' not in data:
            return Response({'error': "Le champ 'quantite' est requis"}, status=status.HTTP_400_BAD_REQUEST)
            
        # Get current ingredient and stock info
        ingredient = firebase_crud.get_doc('ingredients', ingredient_id)
        if not ingredient:
            return Response({'error': "Ingrédient non trouvé"}, status=status.HTTP_404_NOT_FOUND)
            
        stock_id = f"stock_{ingredient_id}"
        stock = firebase_crud.get_doc('stocks', stock_id)
        
        if not stock:
            # Create stock if it doesn't exist
            stock = {
                'capaciteS': 0,
                'SeuilAlerte': ingredient.get('nbrMin', 0),
                'idIng': ingredient_id
            }
        
        # Update the stock quantity (add new quantity to existing)
        new_quantity = stock.get('capaciteS', 0) + float(data['quantite'])
        
        # Update stock document
        firebase_crud.update_doc('stocks', stock_id, {
            'capaciteS': new_quantity,
            'updatedAt': firestore.SERVER_TIMESTAMP
        })
        
        # Optionally log this restock operation in a new collection
        restock_log = {
            'idIng': ingredient_id,
            'quantite': float(data['quantite']),
            'date_reapprovisionnement': firestore.SERVER_TIMESTAMP,
            'user_id': request.user.uid if hasattr(request.user, 'uid') else None
        }
        firebase_crud.create_doc('reapprovisionnements', restock_log)
        
        return Response({
            'success': True,
            'message': 'Stock mis à jour avec succès',
            'nouvelle_quantite': new_quantity
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
@api_view(['GET'])
@permission_classes([IsManagerOrServer])
def get_all_reservations(request):
    """
    Get all reservations with optional filters.
    Query params:
    - date: Filter by date (YYYY-MM-DD)
    - status: Filter by status (confirmed, pending, cancelled)
    """
    try:
        
        date_filter = request.query_params.get('date', None)
        status_filter = request.query_params.get('status', None)
        
        
        reservations = firebase_crud.get_all_docs('reservations')
        
        
        if date_filter:
            
            reservations = [r for r in reservations if r.get('date_time', '').startswith(date_filter)]
            
        if status_filter:
           
            reservations = [r for r in reservations if r.get('status') == status_filter]
            
        
        reservations.sort(key=lambda x: x.get('date_time', ''))
        
        return Response({'reservations': reservations}, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['PATCH'])
@permission_classes([IsManagerOrServer])
def confirm_reservation(request, reservation_id):
    """
    Change a reservation status to confirmed.
    """
    try:
        
        reservation = firebase_crud.get_doc('reservations', reservation_id)
        if not reservation:
            return Response({'error': 'Réservation non trouvée'}, status=status.HTTP_404_NOT_FOUND)
            
       
        firebase_crud.update_doc('reservations', reservation_id, {
            'status': 'confirmed',
            'updated_at': firestore.SERVER_TIMESTAMP
        })
        
        
        if 'client_id' in reservation:
            notification_data = {
                'recipient_id': reservation['client_id'],
                'recipient_type': 'client',
                'title': 'Réservation confirmée',
                'message': f"Votre réservation pour {reservation.get('date_time', 'la date indiquée')} a été confirmée.",
                'created_at': firestore.SERVER_TIMESTAMP,
                'read': False,
                'type': 'reservation_confirmation',
                'priority': 'normal',
                'related_id': reservation_id
            }
            firebase_crud.add_doc('notifications', notification_data)
        
        return Response({
            'success': True,
            'message': 'Statut de réservation mis à jour: confirmée'
        }, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['PATCH'])
@permission_classes([IsManagerOrServer])
def cancel_reservation(request, reservation_id):
    """
    Change a reservation status to cancelled.
    """
    try:
       
        reservation = firebase_crud.get_doc('reservations', reservation_id)
        if not reservation:
            return Response({'error': 'Réservation non trouvée'}, status=status.HTTP_404_NOT_FOUND)
            
       
        firebase_crud.update_doc('reservations', reservation_id, {
            'status': 'cancelled',
            'updated_at': firestore.SERVER_TIMESTAMP
        })
        
        
        if 'client_id' in reservation:
            notification_data = {
                'recipient_id': reservation['client_id'],
                'recipient_type': 'client',
                'title': 'Réservation annulée',
                'message': f"Votre réservation pour {reservation.get('date_time', 'la date indiquée')} a été annulée.",
                'created_at': firestore.SERVER_TIMESTAMP,
                'read': False,
                'type': 'reservation_cancellation',
                'priority': 'normal',
                'related_id': reservation_id
            }
            firebase_crud.add_doc('notifications', notification_data)
        
        return Response({
            'success': True,
            'message': 'Statut de réservation mis à jour: annulée'
        }, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsManagerOrServer])
def add_reservation(request):
    """
    Add a new reservation.
    Required fields: nom_client, telephone, nombre_personnes, date, heure, notes (optional)
    """
    try:
        data = request.data
        
        
        required_fields = ['nom_client', 'telephone', 'nombre_personnes', 'date', 'heure']
        for field in required_fields:
            if field not in data:
                return Response({'error': f"Le champ '{field}' est requis"}, status=status.HTTP_400_BAD_REQUEST)
                
        
        date_time = f"{data['date']}T{data['heure']}"
        
       
        reservation_id = str(uuid.uuid4())

        tables = firebase_crud.query_collection(
            'tables', 
            'nbrPersonne', 
            '>=', 
            int(data['nombre_personnes'])
        )
        
        # Filter for available tables
        available_tables = [t for t in tables if t.get('etatTable') == 'libre']
        
        # If no available tables
        if not available_tables:
            return Response({
                'error': 'Pas de table disponible pour ce nombre de personnes'
            }, status=status.HTTP_400_BAD_REQUEST)
            
        
        selected_table = min(available_tables, key=lambda t: t.get('nbrPersonne', 0))
        table_id = selected_table.get('id')
        
        
        reservation_data = {
            'client_name': data['nom_client'],  
            'telephone': data['telephone'],
            'party_size': int(data['nombre_personnes']),
            'date_time': date_time,
            'notes': data.get('notes', ''),
            'status': 'pending',  
            'table_id': table_id,
            'created_at': firestore.SERVER_TIMESTAMP
        }
        
        
        firebase_crud.create_doc('reservations', reservation_data, reservation_id)
        
        
        firebase_crud.update_doc('tables', table_id, {
            'etatTable': 'reservee',
            'updatedAt': firestore.SERVER_TIMESTAMP
        })
        
        return Response({
            'success': True,
            'message': 'Réservation ajoutée avec succès',
            'reservation_id': reservation_id
        }, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsManager])
def get_all_employees(request):
    """
    Get all employees that are not managers (only chefs and servers).
    """
    try:
        
        all_employees = firebase_crud.get_all_docs('employes')
        
        
        non_managers = [emp for emp in all_employees if emp.get('role') != 'manager']
        
        
        non_managers.sort(key=lambda x: (x.get('role', ''), x.get('nomE', '')))
        
        return Response({'employees': non_managers}, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['PATCH'])
@permission_classes([IsManager])
def update_employee_salary(request, employee_id):
    """
    Update an employee's salary.
    Required field: nouveau_salaire
    """
    try:
        data = request.data
        
        
        if 'nouveau_salaire' not in data:
            return Response({'error': "Le champ 'nouveau_salaire' est requis"}, status=status.HTTP_400_BAD_REQUEST)
            
        
        employee = firebase_crud.get_doc('employes', employee_id)
        if not employee:
            return Response({'error': 'Employé non trouvé'}, status=status.HTTP_404_NOT_FOUND)
            
        
        new_salary = float(data['nouveau_salaire'])
        firebase_crud.update_doc('employes', employee_id, {
            'salaire': new_salary,
            'updated_at': firestore.SERVER_TIMESTAMP
        })
        
        
        salary_log = {
            'employee_id': employee_id,
            'old_salary': employee.get('salaire', 0),
            'new_salary': new_salary,
            'changed_by': request.user.uid if hasattr(request.user, 'uid') else None,
            'changed_at': firestore.SERVER_TIMESTAMP
        }
        firebase_crud.create_doc('salary_changes', salary_log)
        
        return Response({
            'success': True,
            'message': 'Salaire mis à jour avec succès',
            'employee_id': employee_id,
            'new_salary': new_salary
        }, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
@require_http_methods(["GET"])
def get_total_commandes(request):
    try:
        # Count all documents in the commandes collection
        commandes_ref = db.collection('commandes')
        commandes_count = len(list(commandes_ref.stream()))
        
        return JsonResponse({
            'success': True,
            'total_commandes': commandes_count
        })
    except Exception as e:
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=500)

# 2. Get active reservations (pending or confirmed)
@require_http_methods(["GET"])
def get_active_reservations(request):
    try:
        # Query reservations where status is either 'confirmed' or 'pending'
        reservations_ref = db.collection('reservations')
        active_reservations = reservations_ref.where('status', 'in', ['confirmed', 'pending']).stream()
        
        reservations_list = []
        for reservation in active_reservations:
            reservation_data = reservation.to_dict()
            reservation_data['id'] = reservation.id
            reservations_list.append(reservation_data)
        
        return JsonResponse({
            'success': True,
            'active_reservations': reservations_list
        })
    except Exception as e:
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=500)

# 3. Get daily revenue
@require_http_methods(["GET"])
def get_daily_revenue(request):
    try:
        # Get the date from request parameters, or use today's date if not provided
        date_str = request.GET.get('date', datetime.now().strftime('%Y-%m-%d'))
        date_obj = datetime.strptime(date_str, '%Y-%m-%d')
        
        # Create start and end timestamps for the day
        start_of_day = datetime.combine(date_obj, datetime.min.time())
        end_of_day = datetime.combine(date_obj, datetime.max.time())
        
        # Query commandes within the date range
        commandes_ref = db.collection('commandes')
        commandes = commandes_ref.where('dateCreation', '>=', start_of_day).where('dateCreation', '<=', end_of_day).stream()
        
        total_revenue = 0
        orders_count = 0
        
        for commande in commandes:
            commande_data = commande.to_dict()
            if 'montant' in commande_data:
                total_revenue += commande_data['montant']
                orders_count += 1
        
        return JsonResponse({
            'success': True,
            'date': date_str,
            'daily_revenue': total_revenue,
            'orders_count': orders_count
        })
    except Exception as e:
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=500)

# 4. Get weekly revenue
@require_http_methods(["GET"])
def get_weekly_revenue(request):
    try:
        # Get the week start date from request parameters, or use the current week if not provided
        week_start_str = request.GET.get('week_start')
        
        if week_start_str:
            week_start = datetime.strptime(week_start_str, '%Y-%m-%d')
        else:
            # Calculate the start of the current week (Monday)
            today = datetime.now()
            week_start = today - timedelta(days=today.weekday())
            week_start = datetime.combine(week_start, datetime.min.time())
        
        # Calculate the end of the week (Sunday)
        week_end = week_start + timedelta(days=6)
        week_end = datetime.combine(week_end, datetime.max.time())
        
        # Query commandes within the week
        commandes_ref = db.collection('commandes')
        commandes = commandes_ref.where('dateCreation', '>=', week_start).where('dateCreation', '<=', week_end).stream()
        
        # Initialize dict to store daily revenue
        daily_revenue = {(week_start + timedelta(days=i)).strftime('%Y-%m-%d'): 0 for i in range(7)}
        total_weekly_revenue = 0
        orders_count = 0
        
        for commande in commandes:
            commande_data = commande.to_dict()
            if 'montant' in commande_data and 'dateCreation' in commande_data:
                order_date = commande_data['dateCreation'].strftime('%Y-%m-%d')
                daily_revenue[order_date] = daily_revenue.get(order_date, 0) + commande_data['montant']
                total_weekly_revenue += commande_data['montant']
                orders_count += 1
        
        return JsonResponse({
            'success': True,
            'week_start': week_start.strftime('%Y-%m-%d'),
            'week_end': week_end.strftime('%Y-%m-%d'),
            'daily_breakdown': daily_revenue,
            'total_weekly_revenue': total_weekly_revenue,
            'orders_count': orders_count
        })
    except Exception as e:
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=500)

# 5. Get commande_plat list
@require_http_methods(["GET"])
def get_commande_plat_list(request):
    try:
        # Get optional filter parameters
        commande_id = request.GET.get('commande_id')
        plat_id = request.GET.get('plat_id')
        
        # Start with the base query
        commande_plat_ref = db.collection('commande_plat')
        
        # Apply filters if they exist
        if commande_id:
            commande_plat_ref = commande_plat_ref.where('idCmd', '==', commande_id)
        if plat_id:
            commande_plat_ref = commande_plat_ref.where('idP', '==', plat_id)
        
        # Execute the query
        commande_plat_docs = commande_plat_ref.stream()
        
        # Process the results
        commande_plat_list = []
        for doc in commande_plat_docs:
            item_data = doc.to_dict()
            item_data['id'] = doc.id
            commande_plat_list.append(item_data)
        
        return JsonResponse({
            'success': True,
            'commande_plat': commande_plat_list
        })
    except Exception as e:
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=500)

# 6. Get sous_categories for each category
@require_http_methods(["GET"])
def get_sous_categories_by_category(request):
    try:
        # Get optional category ID parameter
        cat_id = request.GET.get('cat_id')
        
        # If cat_id is provided, filter sous_categories by that category
        if cat_id:
            sous_categories_ref = db.collection('sous_categories').where('idCat', '==', cat_id)
            sous_categories = sous_categories_ref.stream()
            
            sous_categories_list = []
            for sous_cat in sous_categories:
                sous_cat_data = sous_cat.to_dict()
                sous_cat_data['id'] = sous_cat.id
                sous_categories_list.append(sous_cat_data)
            
            return JsonResponse({
                'success': True,
                'category_id': cat_id,
                'sous_categories': sous_categories_list
            })
        else:
            # Get all categories first
            categories_ref = db.collection('categories')
            categories = categories_ref.stream()
            
            result = {}
            for category in categories:
                cat_data = category.to_dict()
                cat_id = category.id
                cat_name = cat_data.get('nomCat', 'Unknown')
                
                # Get sous-categories for this category
                sous_categories_ref = db.collection('sous_categories').where('idCat', '==', cat_id)
                sous_categories = sous_categories_ref.stream()
                
                sous_categories_list = []
                for sous_cat in sous_categories:
                    sous_cat_data = sous_cat.to_dict()
                    sous_cat_data['id'] = sous_cat.id
                    sous_categories_list.append(sous_cat_data)
                
                result[cat_id] = {
                    'name': cat_name,
                    'sous_categories': sous_categories_list
                }
            
            return JsonResponse({
                'success': True,
                'categories': result
            })
    except Exception as e:
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=500)

# 7. Get plats for each sous_category
@require_http_methods(["GET"])
def get_plats_by_sous_category(request):
    try:
        # Get optional sous-category ID parameter
        sous_cat_id = request.GET.get('sous_cat_id')
        
        # If sous_cat_id is provided, filter plats by that sous-category
        if sous_cat_id:
            plats_ref = db.collection('plats').where('idSousCat', '==', sous_cat_id)
            plats = plats_ref.stream()
            
            plats_list = []
            for plat in plats:
                plat_data = plat.to_dict()
                plat_data['id'] = plat.id
                plats_list.append(plat_data)
            
            return JsonResponse({
                'success': True,
                'sous_category_id': sous_cat_id,
                'plats': plats_list
            })
        else:
            # Get all sous-categories first
            sous_categories_ref = db.collection('sous_categories')
            sous_categories = sous_categories_ref.stream()
            
            result = {}
            for sous_cat in sous_categories:
                sous_cat_data = sous_cat.to_dict()
                sous_cat_id = sous_cat.id
                sous_cat_name = sous_cat_data.get('nomSousCat', 'Unknown')
                
                # Get plats for this sous-category
                plats_ref = db.collection('plats').where('idSousCat', '==', sous_cat_id)
                plats = plats_ref.stream()
                
                plats_list = []
                for plat in plats:
                    plat_data = plat.to_dict()
                    plat_data['id'] = plat.id
                    plats_list.append(plat_data)
                
                result[sous_cat_id] = {
                    'name': sous_cat_name,
                    'plats': plats_list
                }
            
            return JsonResponse({
                'success': True,
                'sous_categories': result
            })
    except Exception as e:
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=500)