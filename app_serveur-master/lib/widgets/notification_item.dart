// lib/widgets/notification_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/notifications/notification_bloc.dart';
import '../blocs/notifications/notification_event.dart';
import '../data/models/notification.dart';
import '../utils/theme.dart';

class NotificationItem extends StatelessWidget {
  final UserNotification notification;

  const NotificationItem({
    super.key, 
    required this.notification,
  });

  // Déterminer l'icône en fonction du type de notification
  IconData _getIconForType() {
    switch (notification.type) {
      case 'new_order':
        return Icons.restaurant_menu;
      case 'order_ready':
        return Icons.check_circle;
      case 'bill_request':
        return Icons.receipt_long;
      case 'order_delay':
        return Icons.access_time;
      case 'low_stock':
        return Icons.inventory;
      case 'welcome':
        return Icons.celebration;
      default:
        return Icons.notifications_active;
    }
  }

  // Déterminer la couleur en fonction de la priorité
  Color _getPriorityColor() {
    switch (notification.priority) {
      case 'high':
        return Colors.red.shade700;
      case 'normal':
        return AppTheme.accentColor;
      case 'low':
        return Colors.green;
      default:
        return AppTheme.accentColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Marquer comme lu lors du tap si pas déjà lu
        if (!notification.isRead) {
          context.read<NotificationBloc>().add(
            MarkNotificationAsRead(notificationId: notification.id),
          );
        }
        
        // Implémentation future: navigation vers détails si nécessaire
        if (notification.relatedId != null && notification.type == 'order_ready') {
          // Navigator.of(context).pushNamed('/orders/${notification.relatedId}');
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), 
        padding: const EdgeInsets.all(16), 
        decoration: BoxDecoration(
          color: notification.isRead 
              ? AppTheme.secondaryColor.withValues(alpha: 0.8) 
              : AppTheme.secondaryColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [  
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),  
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: notification.isRead 
              ? null 
              : Border.all(color: _getPriorityColor().withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getPriorityColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getIconForType(),
                color: _getPriorityColor(),
                size: 24, 
              ),
            ),
            const SizedBox(width: 12), 
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.content,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notification.getTimeAgo(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getPriorityColor(),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}