// lib/widgets/notifications/notification_item.dart
import 'package:flutter/material.dart';
import '../../data/models/notification.dart';
import '../../utils/theme.dart';

class NotificationItem extends StatelessWidget {
  final UserNotification notification;

  const NotificationItem({
    super.key, 
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16), 
      padding: const EdgeInsets.all(14), 
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [  
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),  
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          const Icon(
            Icons.notifications_active,
            color: AppTheme.primaryColor,
            size: 26, 
          ),
          const SizedBox(width: 12), 
          
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,  
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  notification.getTimeAgo(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}