#core>urls.py
from django.urls import path
from . import views

urlpatterns = [
    # Client endpoints
  path('client/signup/step1/', views.client_signup_step1, name='client_signup_step1'),
    path('client/signup/step2/', views.client_signup_step2, name='client_signup_step2'),
    path('client/signup/step3/', views.client_signup_step3, name='client_signup_step3'),
    path('client/signup/step4/', views.client_signup_step4, name='client_signup_step4'),
     path('client/signup/step5/', views.client_signup_step5, name='client_signup_step5'),
    path('client/login/', views.client_login, name='client_login'),
    
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