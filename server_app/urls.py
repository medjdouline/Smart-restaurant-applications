from django.urls import path
from . import views
from core.views import staff_login

urlpatterns = [
    path('staff/login/', staff_login, name='staff_login'),
   

    # Server profile
    path('profile/', views.get_server_profile, name='get_server_profile'),
    path('profile/update-password/', views.update_password, name='update_password'),
    
    # Orders endpoints
    path('orders/', views.get_all_orders, name='get_all_orders_view'),
    path('orders/pending/', views.get_pending_orders_view, name='get_pending_orders_view'),
    path('orders/preparing/', views.get_preparing_orders_view, name='get_preparing_orders_view'),
    path('orders/ready/', views.get_ready_orders_view, name='get_ready_orders_view'),
    path('orders/served/', views.get_served_orders_view, name='get_served_orders_view'),
    path('orders/cancelled/', views.get_cancelled_orders_view, name='get_cancelled_orders_view'),
    path('orders/<str:order_id>/status/', views.update_order_status, name='update_order_status'),
 
    path('orders/<str:order_id>/cancel/', views.cancel_order, name='cancel_order'),
    path('orders/<str:order_id>/request-cancel/', views.request_cancel_order, name='request_cancel_order'),
    path('orders/<str:order_id>/', views.get_order_details, name='get_order_details'),
    
    # Assistance requests
    path('assistance/', views.get_assistance_requests, name='get_assistance_requests'),
    path('assistance/<str:request_id>/complete/', views.complete_assistance_request, name='complete_assistance_request'),
    
    # Dashboard
    path('dashboard/', views.get_dashboard, name='get_dashboard'),
    
    # Tables
    path('tables/', views.get_all_tables, name='get_all_tables'),
    path('tables/<str:table_id>/status/', views.update_table_status, name='update_table_status'),
    path('tables/<str:table_id>/orders/', views.get_table_orders, name='get_table_orders'),
    path('tables/<str:table_id>/confirm-reservation/', views.confirm_reservation, name='confirm_reservation'),

    
    # Notifications
    path('notifications/', views.get_notifications, name='get_notifications'),
    path('notifications/<str:notification_id>/', views.get_notification_details, name='get_notification_details'),
    path('notifications/mark-all-read/', views.mark_all_notifications_read, name='mark_all_notifications_read'),
]