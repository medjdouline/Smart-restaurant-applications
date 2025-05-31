from django.urls import path
from core.views import client_signup_step1, client_signup_step2, client_signup_step3, client_signup_step4, client_signup_step5, client_login, guest_login, logout
from . import views


urlpatterns = [
    # Authentication endpoints (already implemented)
    path('auth/client/signup/step1/', client_signup_step1, name='client_signup_step1'),#deja fait
    path('auth/client/signup/step2/', client_signup_step2, name='client_signup_step2'),
    path('auth/client/signup/step3/', client_signup_step3, name='client_signup_step3'),
    path('auth/client/signup/step4/', client_signup_step4, name='client_signup_step4'),
    path('auth/client/signup/step5/', client_signup_step5, name='client_signup_step5'),
    path('auth/client/login/', client_login, name='client_login'),
    path('auth/guest/login/', guest_login, name='guest_login'),
    path('logout/', logout, name='logout'),#deja fait
        path('assistance/create/', views.create_assistance_request, name='create_assistance_request'),

    # Profile endpoints
    path('profile/', views.view_client_profile, name='view_client_profile'), #deja fait
    path('profile/update/', views.update_client_profile, name='update_client_profile'), #deja fait
    path('plats/nouveautes/', views.get_new_plats, name='get_new_plats'),

    
    # Orders endpoints
       
    path('orders/create/', views.create_order, name='create_order'), #creer une commande
    path('orders/', views.get_orders_history, name='get_orders_history'), #historique commandes
    path('orders/<str:order_id>/', views.get_order_details, name='get_order_details'), #details d'une commande dans l'historique
    path('orders/<str:order_id>/delete/', views.delete_order_history, name='delete_order_history'), #marakch dayrha
    # Favorites endpoints
    path('temp/favorites/', views.get_favorites, name='get_favorites'), #get (recevoir) favoris
    path('favorites/add/<str:plat_id>/', views.add_favorite, name='add_favorite'), #ajouter aux favoris
    path('favorites/remove/<str:plat_id>/', views.remove_favorite, name='remove_favorite'), #supprimer des favoris
    
    
    # Menu endpoints

 #specifie categorie et renvoie les sous categories
    path('plats/<str:plat_id>/', views.get_plat_details, name='get_plat_details'), #renvoie des detils d'un plat
    path('plats/<str:plat_id>/similar/', views.get_similar_dishes, name='get_similar_dishes'), #marakch dayrha
    path('orders/<str:order_id>/cancel/', views.cancel_order, name='cancel_order'), # Annuler une commande
    path('cancellation-requests/', views.get_cancellation_requests, name='get_cancellation_requests'), # Voir les demandes d'annulation

   
    
    # Preferences endpoints
    path('preferences/', views.get_preferences, name='get_preferences'),#moi
    path('preferences/update/', views.update_preferences, name='update_preferences'),
    path('allergies/', views.get_allergies, name='get_allergies'),
    path('allergies/update/', views.update_allergies, name='update_allergies'),
    path('restrictions/', views.get_restrictions, name='get_restrictions'),
    path('restrictions/update/', views.update_restrictions, name='update_restrictions'),#moi
    
    # Recommendations endpoints
    path('recommendations/', views.get_recommendations, name='get_recommendations'),
    path('recommendations/<str:recommendation_id>/', views.get_recommendation_details, name='get_recommendation_details'),
    
    # Notifications endpoints
    path('notifications/', views.get_notifications, name='get_notifications'),
    path('notifications/<str:notification_id>/read/', views.mark_notification_as_read, name='mark_notification_as_read'),
    path('notifications/mark-all-read/', views.mark_all_notifications_as_read, name='mark_all_notifications_as_read'),
    path('notifications/<str:notification_id>/', views.delete_notification, name='delete_notification'),
    path('notifications/<str:notification_id>/', views.get_notification_details, name='get_notification_details'),#moi


     # Assistance endpoints

    
    
    # Fidelity endpoints
    path('fidelity/points/', views.get_fidelity_points, name='get_fidelity_points'), #points de fidelite
    

]