// lib/utils/constants.dart
class AppConstants {
  // Images
  static const String logoPath = 'assets/images/logo.png';
  
  // Textes - Auth
  static const String appName = 'Good serve !';
  static const String loginTitle = 'Connectez vous';
  static const String usernameHint = 'Nom d\'utilisateur';
  static const String emailHint = 'Email';  
  static const String passwordHint = 'Mot de passe';
  static const String loginButton = 'Se connecter';

  // Textes - Home
  static const String newOrdersTitle = 'Nouvelles commandes';
  static const String readyOrdersTitle = 'Commandes prêtes';
  static const String tablesTitle = 'Table';
  static const String seeMore = 'voir plus';
  static const String serveButton = 'Servir';
  static const String preparingButton = 'En Préparation';
  static const String detailsButton = 'Détails';
  static const String greetingPrefix = 'Salut!';
  
  // Textes - Notifications
  static const String notificationsTitle = 'Notification';
  static const String noNotifications = 'Aucune notification';
  
  // Textes - Messages
  static const String messagesTitle = 'Messages';
  static const String noMessages = 'Aucun message';
  static const String messageHint = 'Votre message';
  
  // Textes - Profil
  static const String profileTitle = 'Profil';
  static const String logoutButton = 'Déconnexion';
  static const String ordersHandled = 'Commandes gérées';
  static const String ordersHandledDetail = 'Commandes traitées depuis ton inscription';

  // Routes
  static const String loginRoute = '/login';
  static const String homeRoute = '/home';
  static const String ordersRoute = '/orders'; // Nouvelle route
  static const String tableDetailsRoute = '/table-details';
  static const String orderListRoute = '/order-list';
  static const String notificationsRoute = '/notifications';
  static const String messagesRoute = '/messages';
  static const String profileRoute = '/profile'; 
  static const String tablesRoute = '/tables'; // Nouvelle route pour les tables
}