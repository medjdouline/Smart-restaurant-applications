from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from core.permissions import IsClient, IsGuest
from core.firebase_crud import firebase_crud
from firebase_admin import firestore
import logging

logger = logging.getLogger(__name__)



# Table specific
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_table_info(request, table_id):
    """Get information about the current table"""
    try:
        table = firebase_crud.get_doc('tables', table_id)
        
        if not table:
            return Response({'error': 'Table not found'}, status=status.HTTP_404_NOT_FOUND)
        
        return Response(table, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error retrieving table info: {str(e)}")
        return Response({'error': 'Failed to retrieve table info'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def request_assistance(request, table_id):
    """Request server assistance for the table"""
    try:
        table = firebase_crud.get_doc('tables', table_id)
        
        if not table:
            return Response({'error': 'Table not found'}, status=status.HTTP_404_NOT_FOUND)
        
        assistance_data = {
            'table_id': table_id,
            'status': 'pending',
            'created_at': firestore.SERVER_TIMESTAMP,
            'type': request.data.get('type', 'general'),  
            'note': request.data.get('note', '')
        }
        
        assistance_id = firebase_crud.create_doc('assistance_requests', assistance_data)
        
        
        firebase_crud.update_doc('tables', table_id, {'assistance_needed': True})
        
        return Response({
            'id': assistance_id,
            'message': 'Assistance request sent successfully'
        }, status=status.HTTP_201_CREATED)
    except Exception as e:
        logger.error(f"Error requesting assistance: {str(e)}")
        return Response({'error': 'Failed to request assistance'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# Profile
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def client_profile(request):
    """Get the client profile information, works for both authenticated and guest users"""
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

# Ordering
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_order(request, table_id):
    """Create a new order from the table"""
    try:
        client_id = request.user.uid
        
        
        table = firebase_crud.get_doc('tables', table_id)
        if not table:
            return Response({'error': 'Table not found'}, status=status.HTTP_404_NOT_FOUND)
        
        
        if not request.data.get('items') or not isinstance(request.data.get('items'), list):
            return Response({'error': 'Order must contain items'}, status=status.HTTP_400_BAD_REQUEST)
        
        
        items = request.data.get('items', [])
        total = 0
        order_items = []
        
        for item in items:
            plat_id = item.get('id')
            quantity = item.get('quantity', 1)
            
            
            plat = firebase_crud.get_doc('plats', plat_id)
            if not plat:
                return Response({'error': f'Dish with ID {plat_id} not found'}, status=status.HTTP_400_BAD_REQUEST)
            
            price = plat.get('prix', 0)
            total += price * quantity
            
            order_items.append({
                'idP': plat_id,
                'quantité': quantity
            })
        
        
        order_data = {
            'idC': client_id,
            'idT': table_id,
            'montant': total,
            'dateCreation': firestore.SERVER_TIMESTAMP,
            'etat': 'pending',
            'confirmation': False,
            'notes': request.data.get('notes', '')
        }
        
        order_id = firebase_crud.create_doc('commandes', order_data)
        
        
        for item in order_items:
            item_data = {
                'idCmd': order_id,
                'idP': item['idP'],
                'quantité': item['quantité']
            }
            firebase_crud.create_doc('commande_plat', item_data)
        
        
        client = firebase_crud.get_doc('clients', client_id)
        if client and client.get('isGuest', True) == False:
            history = client.get('history', [])
            history.append(order_id)
            firebase_crud.update_doc('clients', client_id, {'history': history})
            
            
            current_points = client.get('fidelityPoints', 0)
            new_points = current_points + int(total / 10)  
            firebase_crud.update_doc('clients', client_id, {'fidelityPoints': new_points})
        
        return Response({
            'id': order_id,
            'message': 'Order created successfully',
            'total': total
        }, status=status.HTTP_201_CREATED)
    except Exception as e:
        logger.error(f"Error creating order: {str(e)}")
        return Response({'error': 'Failed to create order'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def check_order_status(request, order_id):
    """Check the status of an order"""
    try:
        client_id = request.user.uid
        
        order = firebase_crud.get_doc('commandes', order_id)
        
        if not order:
            return Response({'error': 'Order not found'}, status=status.HTTP_404_NOT_FOUND)
        
        
        if order.get('idC') != client_id and not hasattr(request.user, 'claims') and request.user.claims.get('role') not in ['server', 'chef', 'manager']:
            return Response({'error': 'Access denied'}, status=status.HTTP_403_FORBIDDEN)
        
        
        order_items = firebase_crud.query_collection(
            'commande_plat',
            'idCmd',
            '==',
            order_id
        )
        
        detailed_items = []
        for item in order_items:
            plat = firebase_crud.get_doc('plats', item.get('idP'))
            if plat:
                detailed_items.append({
                    'dish': plat,
                    'quantity': item.get('quantité', 1)
                })
        
        
        order_response = {
            **order,
            'items': detailed_items
        }
        
        return Response(order_response, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error checking order status: {str(e)}")
        return Response({'error': 'Failed to check order status'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# Menu EVERYONE
@api_view(['GET'])
def menu_list(request):
    """Get all available menus - public access for non-authenticated users too"""
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
def categories_list(request):
    """Get all dish categories - public access"""
    try:
        categories = firebase_crud.get_all_docs('categories')
        return Response(categories, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error retrieving categories: {str(e)}")
        return Response({'error': 'Failed to retrieve categories'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
def category_detail(request, category_id):
    """Get dishes in a category - public access"""
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
def plat_detail(request, plat_id):
    """Get detailed information about a dish - public access"""
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

#AUTHENTICATED ONLY
@api_view(['GET'])
@permission_classes([IsClient])
def favorites_list(request):
    """Get client's favorite dishes - authenticated clients only"""
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
    """Add a dish to favorites - authenticated clients only"""
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
    """Remove a dish from favorites - authenticated clients only"""
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

@api_view(['GET'])
@permission_classes([IsClient])
def order_history(request):
    """Get client's order history - authenticated clients only"""
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
@permission_classes([IsAuthenticated])
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
        
        # si pas de recommendations
        if not recommended_dishes:
            plats = firebase_crud.get_all_docs('plats')
            plats.sort(key=lambda x: x.get('note', 0), reverse=True)
            recommended_dishes = plats[:5]  
        
        return Response(recommended_dishes, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error retrieving recommendations: {str(e)}")
        return Response({'error': 'Failed to retrieve recommendations'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)