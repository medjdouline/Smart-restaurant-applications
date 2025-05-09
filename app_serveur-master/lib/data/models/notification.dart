// lib/data/models/notification.dart
class UserNotification {
  final String id;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  UserNotification({
    required this.id,
    required this.content,
    required this.createdAt,
    this.isRead = false,
  });

  // Fonction pour calculer combien de temps s'est écoulé
  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return 'il y a ${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return 'il y a ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'il y a ${difference.inMinutes}min';
    } else {
      return 'à l\'instant';
    }
  }
}