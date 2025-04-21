from django.urls import path
from . import views

urlpatterns = [
    #Profile
    path('profile/', views.client_profile, name='client_profile'),
    path('profile/update/', views.update_profile, name='update_profile'),
    
    #historique
    path('orders/', views.order_history, name='order_history'),
    path('orders/<str:order_id>/', views.order_detail, name='order_detail'),
    
    #Favorites
    path('favorites/', views.favorites_list, name='favorites_list'),
    path('favorites/add/<str:plat_id>/', views.add_favorite, name='add_favorite'),
    path('favorites/remove/<str:plat_id>/', views.remove_favorite, name='remove_favorite'),
    
    #reservations
    path('reservations/', views.reservations_list, name='reservations_list'),
    path('reservations/create/', views.create_reservation, name='create_reservation'),
    path('reservations/<str:reservation_id>/cancel/', views.cancel_reservation, name='cancel_reservation'),
    
    #recommendations
    path('recommendations/', views.get_recommendations, name='get_recommendations'),
    
    #menu
    path('menu/', views.menu_list, name='menu_list'),
    path('menu/categories/', views.categories_list, name='categories_list'),
    path('menu/category/<str:category_id>/', views.category_detail, name='category_detail'),
    path('menu/plat/<str:plat_id>/', views.plat_detail, name='plat_detail'),
]