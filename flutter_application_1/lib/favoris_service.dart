import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'user_service.dart';
import '../services/menu_service.dart';

class FavorisService with ChangeNotifier {
  final List<Map<String, dynamic>> _platsFavoris = [];
  final String baseUrl = 'http://127.0.0.1:8000/api/table';
  MenuService? _menuService;
  UserService? _userService; // Add this line
  bool _isLoading = false;
  DateTime? _lastFetchTime;
  final Duration _cacheDuration = const Duration(seconds: 30);

  List<Map<String, dynamic>> get platsFavoris => _platsFavoris;

  void setMenuService(MenuService menuService) {
    _menuService = menuService;
  }

  // Add this method
  void setUserService(UserService userService) {
    _userService = userService;
  }

  void ajouterFavori(Map<String, dynamic> plat) {
    ajouterFavoriAPI(plat['id']);
  }

  void supprimerFavori(String platId) {
    supprimerFavoriAPI(platId);
  }

  Future<void> chargerFavorisAPI() async {
    
    try {
      if (_userService == null) {
        debugPrint('UserService not set');
        return;
      }
      
      if (!_userService!.isLoggedIn || _userService!.isGuest) {
        debugPrint('Utilisateur non connecté ou invité - pas de favoris');
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/favorites/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_userService!.idToken}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> favoritesList = json.decode(response.body);
        _platsFavoris.clear();
        
        for (var favorite in favoritesList) {
          final enrichedFavorite = _enrichirAvecImage(favorite);
          _platsFavoris.add(enrichedFavorite);
        }
        
        notifyListeners();
      } else {
        debugPrint('Erreur lors du chargement des favoris: ${response.statusCode}');
        throw Exception('Failed to load favorites');
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des favoris: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _enrichirAvecImage(Map<String, dynamic> favori) {
    if (_menuService != null) {
      final item = _menuService!.findItemById(favori['id']);
      if (item != null) {
        return {
          ...favori,
          'image': item.image,
          'ingredients': item.ingredients,
          'isFavorite': true,
        };
      }
    }
    
    return {
      ...favori,
      'image': 'assets/placeholder.jpg',
      'ingredients': favori['ingredients'] ?? '',
      'pointsFidelite': 0,
      'isFavorite': true,
    };
  }

  Future<void> ajouterFavoriAPI(String platId) async {
    try {
      if (_userService == null) {
        throw Exception('UserService not set');
      }
      
      if (!_userService!.isLoggedIn || _userService!.isGuest) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/favorites/add/$platId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_userService!.idToken}',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await chargerFavorisAPI();
      } else {
        throw Exception('Failed to add favorite: ${response.body}');
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout du favori: $e');
      rethrow;
    }
  }

  Future<void> supprimerFavoriAPI(String platId) async {
    try {
      if (_userService == null) {
        throw Exception('UserService not set');
      }
      
      if (!_userService!.isLoggedIn || _userService!.isGuest) {
        throw Exception('User not authenticated');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/favorites/remove/$platId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_userService!.idToken}',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _platsFavoris.removeWhere((plat) => plat['id'] == platId);
        notifyListeners();
      } else {
        throw Exception('Failed to remove favorite: ${response.body}');
      }
    } catch (e) {
      debugPrint('Erreur lors de la suppression du favori: $e');
      rethrow;
    }
  }

  Future<void> toggleFavoriAPI(String platId) async {
    if (estFavori(platId)) {
      await supprimerFavoriAPI(platId);
    } else {
      await ajouterFavoriAPI(platId);
    }
  }

  bool estFavori(String idPlat) {
    return _platsFavoris.any((plat) => plat['id'] == idPlat);
  }
}