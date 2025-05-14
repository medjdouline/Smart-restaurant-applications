// lib/config/app_providers.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/notifications/notification_bloc.dart';
import 'package:app_serveur/core/api/api_client.dart';
import '../data/repositories/notification_repository.dart';
import 'api_config.dart';

/// Classe utilitaire pour gérer l'injection des dépendances dans l'application
class AppProviders {
  /// Retourne tous les providers nécessaires pour l'application
  static List<BlocProvider> getProviders() {
    // Création du client API
    final apiClient = ApiClient(baseUrl: ApiConfig.baseUrl);
    
    // Création des repositories
    final notificationRepository = NotificationRepository(apiClient: apiClient);
    
    // Liste des providers de blocs
    return [
      BlocProvider<NotificationBloc>(
        create: (context) => NotificationBloc(
          notificationRepository: notificationRepository,
        ),
      ),
      // Ajoutez d'autres blocs ici au besoin
    ];
  }
  
  /// Méthode pour envelopper l'application avec tous les providers
  static Widget wrapWithProviders(Widget child) {
    return MultiBlocProvider(
      providers: getProviders(),
      child: child,
    );
  }
}