
from django.urls import path
from . import views
from core.views import staff_login

urlpatterns = [
    path('staff/login/', staff_login, name='staff_login'),
    # 1. Ingredients management
    path('ingredients/low-stock/', views.get_low_stock_ingredients, name='get_low_stock_ingredients'),
    # 2. Active orders (en_attente + en_preparation)
    path('orders/active/', views.get_active_orders, name='get_active_orders'),
    # 3. All order views (chef-specific)
    path('orders/', views.get_all_orders_view, name='get_all_orders'),
    path('orders/pending/', views.get_pending_orders_view, name='get_pending_orders'),
    path('orders/preparing/', views.get_preparing_orders_view, name='get_preparing_orders'),
    path('orders/ready/', views.get_ready_orders_view, name='get_ready_orders'),
    path('orders/served/', views.get_served_orders_view, name='get_served_orders'),
    path('orders/cancelled/', views.get_cancelled_orders_view, name='get_cancelled_orders'),
    # 4. Profile management
    path('profile/', views.get_chef_profile, name='get_chef_profile'),
    path('orders/<str:order_id>/', views.get_order_details, name='get_order_details'),
    # 5. Password management
    path('profile/update-password/', views.update_password, name='update_password'),
    # 6. Notifications
    path('notifications/', views.get_chef_notifications, name='get_chef_notifications'),
    path('notifications/<str:notification_id>/read/', views.mark_notification_read, name='mark_notification_read'),

    #plats
    path('plats/', views.get_all_plats, name='get_all_plats'),
]