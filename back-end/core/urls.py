#cpre>urls.py
from django.urls import path
from . import views

urlpatterns = [
    # Client endpoints
    path('client/login/', views.client_login, name='client_login'),
    path('client/signup/', views.client_signup, name='client_signup'),
    
    # Guest endpoint
    path('guest/login/', views.guest_login, name='guest_login'),
    
    # Staff endpoints
    path('staff/login/', views.staff_login, name='staff_login'),
    
    # Manager endpoints
    path('manager/signup/', views.manager_signup, name='manager_signup'),
    path('manager/login/', views.manager_login, name='manager_login'),  
    path('manager/employes/create/', views.create_employes, name='create_employes'),                                             
    
    # Common endpoints
    path('user/', views.get_current_user, name='get_current_user'),
    path('logout/', views.logout, name='logout'),
]