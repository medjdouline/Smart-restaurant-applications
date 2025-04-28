from django.urls import path
from . import views
from core.views import guest_login

urlpatterns = [
    
    # Table
    path('tables/<str:table_id>/', views.get_table_info, name='get_table_info'),
    path('tables/<str:table_id>/request-assistance/', views.request_assistance, name='request_assistance'),
    
    # Profile
    path('profile/', views.client_profile, name='client_table_profile'),
    #update profile
    
    # Orders
    path('tables/<str:table_id>/orders/create/', views.create_order, name='create_order'),
    path('orders/<str:order_id>/status/', views.check_order_status, name='check_order_status'),
    
    # Menu
    path('menu/', views.menu_list, name='menu_list'),
    path('menu/categories/', views.categories_list, name='categories_list'),
    path('menu/category/<str:category_id>/', views.category_detail, name='category_detail'),
    path('menu/plat/<str:plat_id>/', views.plat_detail, name='plat_detail'),
    
    
    path('favorites/', views.favorites_list, name='favorites_list'),
    path('favorites/add/<str:plat_id>/', views.add_favorite, name='add_favorite'),
    path('favorites/remove/<str:plat_id>/', views.remove_favorite, name='remove_favorite'),
    path('orders/', views.order_history, name='order_history'),
    
    # Recommendations
    path('recommendations/', views.get_recommendations, name='get_recommendations'),
]