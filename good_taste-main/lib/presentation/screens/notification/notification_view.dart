// lib/presentation/screens/notification/notification_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_taste/data/models/notification_model.dart'as app_notification;
import 'package:good_taste/logic/blocs/notification/notification_bloc.dart';
import 'package:intl/intl.dart';


class NotificationView extends StatelessWidget {
  const NotificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE9B975),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.brown),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notification',
          style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: const Color(0xFFE9B975),
        child: BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            if (state is NotificationLoading) {
              return const Center(
                child: CircularProgressIndicator(color:  Color(0xFFBA3400)),
              );
            } else if (state is NotificationLoaded) {
              return _buildNotificationsList(context, state.notifications);
            } else if (state is NotificationError) {
              return Center(child: Text('Erreur: ${state.message}'));
            }
            return const Center(child: Text('Aucune notification disponible'));
          },
        ),
      ),
    );
  }

  Widget _buildNotificationsList(
    BuildContext context,
    List<app_notification.Notification> notifications,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationCard(context, notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    app_notification.Notification notification,
  ) {
    
    Color backgroundColor;
    IconData iconData;
    
    // Déterminer la couleur et l'icône en fonction du type de notification
    switch (notification.type) {
      case app_notification.NotificationType.reservation:
        backgroundColor = const Color(0xFF245536); // Vert pour les réservations
        iconData = Icons.restaurant;
        break;
      case app_notification.NotificationType.late:
        backgroundColor = const Color(0xFFFFA500); // Orange pour les retards
        iconData = Icons.timer;
        break;
      case app_notification.NotificationType.canceled:
        backgroundColor = const Color(0xFFBA3400); // Rouge pour les annulations
        iconData = Icons.cancel;
        break;
      case app_notification.NotificationType.fidelity:
      default:
        backgroundColor = const Color(0xFFBA3400); // Rouge pour fidélité et autres
        iconData = Icons.card_giftcard;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Row(
                    children: [
                      Icon(iconData, color: backgroundColor),
                      const SizedBox(width: 10),
                      const Text('Détails'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notification.message),
                      const SizedBox(height: 10),
                      Text(
                        DateFormat(
                          'dd/MM/yyyy HH:mm',
                        ).format(notification.date),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                      

// Ajouter des instructions de contact pour les notifications de retard ou d'annulation
                      if (notification.type == app_notification.NotificationType.late || 
                          notification.type == app_notification.NotificationType.canceled)
                        Container(
                          margin: const EdgeInsets.only(top: 15),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: backgroundColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: backgroundColor.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Contact Restaurant:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(Icons.phone, size: 16, color: backgroundColor),
                                  const SizedBox(width: 5),
                                  const Text('+225 07 07 07 07 07'),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(Icons.email, size: 16, color: backgroundColor),
                                  const SizedBox(width: 5),
                                  const Text('contact@goodtaste.ci'),
                                ],
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Fermer'),
                    ),
                  ],
                ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(iconData, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Il y a ${_getTimeAgo(notification.date)}',
                      style: TextStyle(
                        color: Colors.white.withAlpha(
                          204,
                        ),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} h';
    } else {
      return '${difference.inMinutes} min';
    }
  }
  
  
  
  
}