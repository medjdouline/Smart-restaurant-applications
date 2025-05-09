// lib/blocs/notifications/notification_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/models/notification.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository notificationRepository;

  NotificationBloc({required this.notificationRepository}) 
      : super(NotificationState()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<MarkNotificationAsRead>(_onMarkNotificationAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllNotificationsAsRead);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(status: NotificationStatus.loading));
    try {
      final notifications = await notificationRepository.getNotifications();
      emit(state.copyWith(
        status: NotificationStatus.loaded,
        notifications: notifications,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NotificationStatus.error,
        errorMessage: 'Impossible de charger les notifications',
      ));
    }
  }

  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await notificationRepository.markAsRead(event.notificationId);
      
      // Mettre à jour l'état local sans appel API supplémentaire
      final updatedNotifications = state.notifications.map((notification) {
        if (notification.id == event.notificationId) {
          return UserNotification(
            id: notification.id,
            content: notification.content,
            createdAt: notification.createdAt,
            isRead: true,
          );
        }
        return notification;
      }).toList();
      
      emit(state.copyWith(notifications: updatedNotifications));
    } catch (e) {
      emit(state.copyWith(
        status: NotificationStatus.error,
        errorMessage: 'Impossible de marquer la notification comme lue',
      ));
    }
  }

  Future<void> _onMarkAllNotificationsAsRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await notificationRepository.markAllAsRead();
      
      // Mettre à jour l'état local sans appel API supplémentaire
      final updatedNotifications = state.notifications.map((notification) {
        return UserNotification(
          id: notification.id,
          content: notification.content,
          createdAt: notification.createdAt,
          isRead: true,
        );
      }).toList();
      
      emit(state.copyWith(notifications: updatedNotifications));
    } catch (e) {
      emit(state.copyWith(
        status: NotificationStatus.error,
        errorMessage: 'Impossible de marquer toutes les notifications comme lues',
      ));
    }
  }
}