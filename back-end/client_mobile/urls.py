from django.urls import path
from core.views import client_signup_step1, client_signup_step2, client_signup_step3, client_signup_step4, client_signup_step5, client_login
from . import views


urlpatterns = [
    # Authentication endpoints (already implemented)
    path('auth/client/signup/step1/', client_signup_step1, name='client_signup_step1'),
    path('auth/client/signup/step2/', client_signup_step2, name='client_signup_step2'),
    path('auth/client/signup/step3/', client_signup_step3, name='client_signup_step3'),
    path('auth/client/signup/step4/', client_signup_step4, name='client_signup_step4'),
    path('auth/client/signup/step5/', client_signup_step5, name='client_signup_step5'),
    path('auth/client/login/', client_login, name='client_login'),

    # Profile endpoints
    path('profile/', views.view_client_profile, name='view_client_profile'),
    path('profile/update/', views.update_client_profile, name='update_client_profile'),
    
    # Orders endpoints
    path('orders/', views.get_orders_history, name='get_orders_history'),
    path('orders/<str:order_id>/', views.get_order_details, name='get_order_details'),
    path('orders/<str:order_id>/delete/', views.delete_order_history, name='delete_order_history'),
    
    # Favorites endpoints
    path('favorites/', views.get_favorites, name='get_favorites'),
    path('favorites/add/<str:plat_id>/', views.add_favorite, name='add_favorite'),
    path('favorites/remove/<str:plat_id>/', views.remove_favorite, name='remove_favorite'),
    
    # Reservations endpoints
    path('reservations/', views.get_reservations, name='get_reservations'),
    path('reservations/create/', views.create_reservation, name='create_reservation'),
    path('reservations/<str:reservation_id>/', views.get_reservation_details, name='get_reservation_details'),
    path('reservations/<str:reservation_id>/cancel/', views.cancel_reservation, name='cancel_reservation'),
    path('tables/available/', views.get_available_tables, name='get_available_tables'),
    
    # Menu endpoints
    path('menus/', views.get_menus, name='get_menus'),
    path('categories/', views.get_categories, name='get_categories'),
    path('categories/<str:category_id>/sub-categories/', views.get_subcategories, name='get_subcategories'),
    path('plats/<str:plat_id>/', views.get_plat_details, name='get_plat_details'),
    path('plats/<str:plat_id>/similar/', views.get_similar_dishes, name='get_similar_dishes'),
   
    
    # Preferences endpoints
    path('preferences/', views.get_preferences, name='get_preferences'),
    path('preferences/update/', views.update_preferences, name='update_preferences'),
    path('allergies/', views.get_allergies, name='get_allergies'),
    path('allergies/update/', views.update_allergies, name='update_allergies'),
    path('restrictions/', views.get_restrictions, name='get_restrictions'),
    path('restrictions/update/', views.update_restrictions, name='update_restrictions'),
    
    # Recommendations endpoints
    path('recommendations/', views.get_recommendations, name='get_recommendations'),
    path('recommendations/<str:recommendation_id>/', views.get_recommendation_details, name='get_recommendation_details'),
    
    # Notifications endpoints
    path('notifications/', views.get_notifications, name='get_notifications'),
    path('notifications/<str:notification_id>/', views.get_notification_details, name='get_notification_details'),
    
    # Dashboard endpoint
    path('dashboard/', views.get_dashboard, name='get_dashboard'),
]