// lib/data/repositories/auth_repository.dart
import 'dart:async';
import '../models/user.dart';

class AuthRepository {
  // Pour la démo, nous utiliserons un mock de données
  Future<User> login(String email, String password) async {  
    // Simuler un délai réseau
    await Future.delayed(const Duration(seconds: 1));
    
    // Pour la démo, nous retournons un utilisateur simulé
    if (email == 'demo@example.com' && password == 'password') { 
      return const User(
        id: '1',
        username: 'demo',
        email: 'demo@example.com',
        role: 'serveur',
        firstName: 'Demo',
        lastName: 'User',
      );
    } else {
      throw Exception('Identifiants invalides');
    }
  }

  Future<void> logout() async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 500));
    return;
  }
  
  // Nouvelle méthode pour changer le mot de passe
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Dans un vrai scénario, on vérifierait le mot de passe actuel contre la base de données
    // Pour la démo, on vérifie simplement si le mot de passe actuel est 'password'
    if (currentPassword == 'password') {
      // Simuler la mise à jour du mot de passe
      // Dans une vraie application, vous mettriez à jour le mot de passe dans votre base de données
      return true;
    } else {
      throw Exception('Mot de passe actuel incorrect');
    }
  }
}