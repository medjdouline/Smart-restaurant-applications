from django.urls import path
from . import views
from core.views import manager_signup, manager_login, create_employes


urlpatterns = [
    # Authentication endpoints from core/views.py
    path('auth/signup/', manager_signup, name='manager_signup'),
    path('auth/login/', manager_login, name='manager_login'),
    path('employes/create/', create_employes, name='create_employes'),
    
    # Commandes endopints
    path('commandes/', views.get_all_commandes, name='get_all_commandes'),
    path('commandes/en-attente/', views.get_commandes_en_attente, name='get_commandes_en_attente'),
    path('commandes/lancees/', views.get_commandes_lancees, name='get_commandes_lancees'),
    path('commandes/servies/', views.get_commandes_servies, name='get_commandes_servies'),
    path('commandes/annulees/', views.get_commandes_annulees, name='get_commandes_annulees'),
    
    #Total count of orders
    path('commandes/total/', views.get_total_commandes, name='get_total_commandes'),
    
    #Get commande_plat list
    path('commande-plat/', views.get_commande_plat_list, name='get_commande_plat_list'),
    
    # Categories endpoints
    path('categories/', views.get_categories, name='get_categories'),
    path('sous-categories/', views.get_sous_categories, name='get_sous_categories'),
    
    
    # Plats endpoints
    path('plats/', views.get_all_plats, name='get_all_plats'),
    path('plats/add/', views.add_plat, name='add_plat'),
    path('plats/<str:plat_id>/', views.update_plat, name='update_plat'),
    path('plats/<str:plat_id>/delete/', views.delete_plat, name='delete_plat'),
    path('plats/<str:plat_id>/cost-details/', views.get_plat_cost_details, name='get_plat_cost_details'),
    
    #ingredients endpoints
    path('ingredients/', views.get_all_ingredients, name='get_all_ingredients'),
    path('ingredients/add/', views.add_ingredient, name='add_ingredient'),
    path('ingredients/<str:ingredient_id>/restock/', views.restock_ingredient, name='restock_ingredient'),
    
    # Reservation endpoints
    path('reservations/', views.get_all_reservations, name='get_all_reservations'),
    path('reservations/active/', views.get_active_reservations, name='get_active_reservations'),
    path('reservations/add/', views.add_reservation, name='add_reservation'),
    path('reservations/<str:reservation_id>/confirm/', views.confirm_reservation, name='confirm_reservation'),
    path('reservations/<str:reservation_id>/cancel/', views.cancel_reservation, name='cancel_reservation'),
    
    # Revenue endpoints

    path('revenue/daily/', views.get_daily_revenue, name='get_daily_revenue'),
    path('revenue/weekly/', views.get_weekly_revenue, name='get_weekly_revenue'),
    
    #employees
    path('employes/', views.get_all_employees, name='get_all_employees'),
    path('employes/<str:employee_id>/update-salary/', views.update_employee_salary, name='update_employee_salary'),


    #'au cas ou' endpoints
        #Get sous-categories by category
    path('categories/sous-categories/', views.get_sous_categories_by_category, name='get_sous_categories_by_category'),
    
    #Get plats by sous-category
    path('sous-categories/plats/', views.get_plats_by_sous_category, name='get_plats_by_sous_category'),
]
