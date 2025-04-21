from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from core.permissions import IsClient
from core.firebase_crud import firebase_crud
from firebase_admin import firestore
import logging

logger = logging.getLogger(__name__)

#profile//infos perso

@api_view(['GET'])
@permission_classes([IsClient])
def client_profile(request):
    """Get the client profile information"""
    try:
        client_id = request.user.uid
        client_data = firebase_crud.get_doc('clients', client_id)
        
        if not client_data:
            return Response({'error': 'Client profile not found'}, status=status.HTTP_404_NOT_FOUND)
        
        
        client_data.pop('motDePasse', None)
        client_data.pop('password', None)
            
        return Response(client_data, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error retrieving client profile: {str(e)}")
        return Response({'error': 'Failed to retrieve profile'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['PUT'])
@permission_classes([IsClient])
def update_profile(request):
    """Update client profile information"""
    try:
        client_id = request.user.uid
        
        
        allowed_fields = ['birthdate', 'email', 'address']
        updates = {k: v for k, v in request.data.items() if k in allowed_fields}
        
        if not updates:
            return Response({'error': 'No valid fields to update'}, status=status.HTTP_400_BAD_REQUEST)
        
        firebase_crud.update_doc('clients', client_id, updates)
        return Response({'message': 'Profile updated successfully'}, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error updating client profile: {str(e)}")
        return Response({'error': 'Failed to update profile'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

#historique

@api_view(['GET'])
@permission_classes([IsClient])
def order_history(request):
    """Get client's order history"""
    try:
        client_id = request.user.uid
        
        
        orders = firebase_crud.query_collection(
            'commandes',
            'idC',
            '==',
            client_id
        )
        
        if not orders:
            return Response([], status=status.HTTP_200_OK)
            
        
        orders.sort(key=lambda x: x.get('dateCreation', 0), reverse=True)
        
        return Response(orders, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error retrieving order history: {str(e)}")
        return Response({'error': 'Failed to retrieve order history'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsClient])
def order_detail(request, order_id):
    """Get detailed information about a specific order"""
    try:
        client_id = request.user.uid
        
        
        order = firebase_crud.get_doc('commandes', order_id)
        
        if not order:
            return Response({'error': 'Order not found'}, status=status.HTTP_404_NOT_FOUND)
            
        
        if order.get('idC') != client_id:
            return Response({'error': 'Access denied'}, status=status.HTTP_403_FORBIDDEN)
        
        
        order_items = firebase_crud.query_collection(
            'commande_plat',
            'idCmd',
            '==',
            order_id
        )
        
        
        enhanced_items = []
        for item in order_items:
            plat = firebase_crud.get_doc('plats', item.get('idP'))
            if plat:
                enhanced_items.append({
                    'plat': plat,
                    'quantité': item.get('quantité', 1)
                })
        
        
        order['items'] = enhanced_items
        
        return Response(order, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error retrieving order detail: {str(e)}")
        return Response({'error': 'Failed to retrieve order detail'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

#favoris

@api_view(['GET'])
@permission_classes([IsClient])
def favorites_list(request):
    """Get client's favorite dishes"""
    try:
        client_id = request.user.uid
        client_data = firebase_crud.get_doc('clients', client_id)
        
        favorites = client_data.get('favorites', [])
        
        
        favorite_dishes = []
        for plat_id in favorites:
            plat = firebase_crud.get_doc('plats', plat_id)
            if plat:
                favorite_dishes.append(plat)
        
        return Response(favorite_dishes, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error retrieving favorites: {str(e)}")
        return Response({'error': 'Failed to retrieve favorites'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([IsClient])
def add_favorite(request, plat_id):
    """Add a dish to favorites"""
    try:
        client_id = request.user.uid
        
        
        plat = firebase_crud.get_doc('plats', plat_id)
        if not plat:
            return Response({'error': 'Dish not found'}, status=status.HTTP_404_NOT_FOUND)
        
        
        client_data = firebase_crud.get_doc('clients', client_id)
        favorites = set(client_data.get('favorites', []))
        
        
        if plat_id not in favorites:
            favorites.add(plat_id)
            firebase_crud.update_doc('clients', client_id, {'favorites': list(favorites)})
        
        return Response({'message': 'Added to favorites'}, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error adding favorite: {str(e)}")
        return Response({'error': 'Failed to add favorite'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['DELETE'])
@permission_classes([IsClient])
def remove_favorite(request, plat_id):
    """Remove a dish from favorites"""
    try:
        client_id = request.user.uid
        
        
        client_data = firebase_crud.get_doc('clients', client_id)
        favorites = set(client_data.get('favorites', []))
        
        
        if plat_id in favorites:
            favorites.remove(plat_id)
            firebase_crud.update_doc('clients', client_id, {'favorites': list(favorites)})
        
        return Response({'message': 'Removed from favorites'}, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error removing favorite: {str(e)}")
        return Response({'error': 'Failed to remove favorite'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

#reserver une table

@api_view(['GET'])
@permission_classes([IsClient])
def reservations_list(request):
    """Get client's reservations"""
    try:
        client_id = request.user.uid
        
        
        reservations = firebase_crud.query_collection(
            'reservation',
            'idC',
            '==',
            client_id
        )
        
        
        reservations.sort(key=lambda x: x.get('date', ''), reverse=True)
        
        
        enhanced_reservations = []
        for res in reservations:
            table = firebase_crud.get_doc('tables', res.get('idT'))
            if table:
                res['table'] = table
                enhanced_reservations.append(res)
        
        return Response(enhanced_reservations, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error retrieving reservations: {str(e)}")
        return Response({'error': 'Failed to retrieve reservations'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([IsClient])
def create_reservation(request):
    """Create a new table reservation"""
    try:
        client_id = request.user.uid
        
        required_fields = ['date', 'heure', 'idT', 'nbrPersonne']
        if not all(field in request.data for field in required_fields):
            return Response({'error': 'Missing required fields'}, status=status.HTTP_400_BAD_REQUEST)
        
        
        table_id = request.data['idT']
        table = firebase_crud.get_doc('tables', table_id)
        
        if not table:
            return Response({'error': 'Table not found'}, status=status.HTTP_404_NOT_FOUND)
        
        if table.get('etatTable') != 'libre':
            return Response({'error': 'Table is not available'}, status=status.HTTP_400_BAD_REQUEST)
        
        
        nbr_personne = int(request.data['nbrPersonne'])
        if nbr_personne > table.get('nbrPersonne', 0):
            return Response({'error': 'Table capacity insufficient'}, status=status.HTTP_400_BAD_REQUEST)
        
        
        reservation_data = {
            'date': request.data['date'],
            'heure': request.data['heure'],
            'idT': table_id,
            'idC': client_id,
            'nbrPersonne': nbr_personne,
            'status': 'confirmed',
            'createdAt': firestore.SERVER_TIMESTAMP
        }
        
        reservation_id = firebase_crud.create_doc('reservation', reservation_data)
        
        
        firebase_crud.update_doc('tables', table_id, {'etatTable': 'réservé'})
        
        return Response({'id': reservation_id, 'message': 'Reservation created'}, status=status.HTTP_201_CREATED)
    except Exception as e:
        logger.error(f"Error creating reservation: {str(e)}")
        return Response({'error': 'Failed to create reservation'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['DELETE'])
@permission_classes([IsClient])
def cancel_reservation(request, reservation_id):
    """Cancel an existing reservation"""
    try:
        client_id = request.user.uid
        
        
        reservation = firebase_crud.get_doc('reservation', reservation_id)
        
        if not reservation:
            return Response({'error': 'Reservation not found'}, status=status.HTTP_404_NOT_FOUND)
        
       
        if reservation.get('idC') != client_id:
            return Response({'error': 'Access denied'}, status=status.HTTP_403_FORBIDDEN)
        
        
        table_id = reservation.get('idT')
        
        
        firebase_crud.update_doc('reservation', reservation_id, {'status': 'cancelled'})
        
        
        table = firebase_crud.get_doc('tables', table_id)
        if table and table.get('etatTable') == 'réservé':
            firebase_crud.update_doc('tables', table_id, {'etatTable': 'libre'})
        
        return Response({'message': 'Reservation cancelled'}, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error cancelling reservation: {str(e)}")
        return Response({'error': 'Failed to cancel reservation'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

#recomm
#might change everything depending on how the interface hykono

@api_view(['GET'])
@permission_classes([IsClient])
def get_recommendations(request):
    """Get personalized dish recommendations for the client"""
    try:
        client_id = request.user.uid
        
       
        recommendations = firebase_crud.query_collection(
            'recommandations',
            'idC',
            '==',
            client_id
        )
        
        recommended_dishes = []
        
        if recommendations:
            
            recommendations.sort(key=lambda x: x.get('date_generation', 0), reverse=True)
            recent_reco = recommendations[0]
            
            
            reco_plats = firebase_crud.query_collection(
                'recommandation_plat',
                'idR',
                '==',
                recent_reco.get('id', '')
            )
            
            
            for rp in reco_plats:
                plat = firebase_crud.get_doc('plats', rp.get('idP', ''))
                if plat:
                    recommended_dishes.append(plat)
        
        #si il n'a pas de recommendations, mettre en avance les plats les mieux notes ou alors plat du jour ida on le laisse
        if not recommended_dishes:
            
            plats = firebase_crud.get_all_docs('plats')
            plats.sort(key=lambda x: x.get('note', 0), reverse=True)
            recommended_dishes = plats[:5]  # Top 5 dishes
        
        return Response(recommended_dishes, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error retrieving recommendations: {str(e)}")
        return Response({'error': 'Failed to retrieve recommendations'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

#menu browsig

@api_view(['GET'])
@permission_classes([IsClient])
def menu_list(request):
    """Get all available menus"""
    try:
        menus = firebase_crud.get_all_docs('menus')
        
        
        enhanced_menus = []
        for menu in menus:
            menu_plats = firebase_crud.query_collection(
                'menu_plat',
                'idM',
                '==',
                menu.get('id', '')
            )
            
            dishes = []
            for mp in menu_plats:
                plat = firebase_crud.get_doc('plats', mp.get('idP', ''))
                if plat:
                    dishes.append(plat)
            
            menu['dishes'] = dishes
            enhanced_menus.append(menu)
        
        return Response(enhanced_menus, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error retrieving menus: {str(e)}")
        return Response({'error': 'Failed to retrieve menus'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsClient])
def categories_list(request):
    """Get all dish categories"""
    try:
        categories = firebase_crud.get_all_docs('categories')
        return Response(categories, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error retrieving categories: {str(e)}")
        return Response({'error': 'Failed to retrieve categories'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsClient])
def category_detail(request, category_id):
    """Get dishes in a category"""
    try:
        category = firebase_crud.get_doc('categories', category_id)
        
        if not category:
            return Response({'error': 'Category not found'}, status=status.HTTP_404_NOT_FOUND)
        
        
        dishes = firebase_crud.query_collection(
            'plats',
            'idCat',
            '==',
            category_id
        )
        
        return Response({
            'category': category,
            'dishes': dishes
        }, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error retrieving category dishes: {str(e)}")
        return Response({'error': 'Failed to retrieve category dishes'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsClient])
def plat_detail(request, plat_id):
    """Get detailed information about a dish"""
    try:
        plat = firebase_crud.get_doc('plats', plat_id)
        
        if not plat:
            return Response({'error': 'Dish not found'}, status=status.HTTP_404_NOT_FOUND)
        
        
        category_id = plat.get('idCat')
        category = None
        if category_id:
            category = firebase_crud.get_doc('categories', category_id)
        
        
        plat['category'] = category
        
        return Response(plat, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error retrieving dish details: {str(e)}")
        return Response({'error': 'Failed to retrieve dish details'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)