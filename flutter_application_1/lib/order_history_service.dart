import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'cart_service.dart';
import '../services/menu_service.dart';
import 'user_service.dart';

class OrderHistoryItem {
  final String id;
  final DateTime date;
  final List<CartItem> items;
  final double total;
  final bool reductionAppliquee;
  final double montantReduction;
  final int pointsUtilises;
  final String? firebaseOrderId;
  final String? djangoOrderId;
  final String? etat; // ADD THIS - order status
  final bool? confirmation; // ADD THIS - order confirmation

  OrderHistoryItem({
    required this.id,
    required this.items,
    required this.total,
    required this.reductionAppliquee,
    required this.montantReduction,
    required this.pointsUtilises,
    this.firebaseOrderId,
    this.djangoOrderId,
    this.etat, // ADD THIS
    this.confirmation, // ADD THIS
  }) : date = DateTime.now();

  OrderHistoryItem.withDate({
    required this.id,
    required this.date,
    required this.items,
    required this.total,
    required this.reductionAppliquee,
    required this.montantReduction,
    required this.pointsUtilises,
    this.firebaseOrderId,
    this.djangoOrderId,
    this.etat, // ADD THIS
    this.confirmation, // ADD THIS
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'reductionAppliquee': reductionAppliquee,
      'montantReduction': montantReduction,
      'pointsUtilises': pointsUtilises,
      'firebaseOrderId': firebaseOrderId,
      'djangoOrderId': djangoOrderId,
      'etat': etat, // ADD THIS
      'confirmation': confirmation, // ADD THIS
    };
  }

 factory OrderHistoryItem.fromApiResponse(Map<String, dynamic> apiData, MenuService menuService) {
    List<CartItem> items = [];
    
    if (apiData['items'] != null && apiData['items'] is List) {
      for (var itemData in apiData['items']) {
        final menuItem = menuService.findItemById(itemData['id']?.toString() ?? '');
        
        // Clean the dish name
        String dishName = itemData['nom'] ?? menuItem?.nom ?? 'Plat inconnu';
        dishName = _cleanTextEncoding(dishName); // Apply encoding fix
        
        items.add(CartItem(
          id: itemData['id']?.toString() ?? '',
          nom: dishName, // Use the cleaned name
          prix: (itemData['prix'] ?? menuItem?.prix ?? 0).toDouble(),
          quantite: itemData['quantite'] ?? 1,
          imageUrl: menuItem?.image ?? 'assets/images/placeholder.jpg',
          pointsFidelite: itemData['pointsFidelite'] ?? menuItem?.pointsFidelite ?? 0,
        ));
      }
    }

    return OrderHistoryItem.withDate(
      id: apiData['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      date: _parseDate(apiData['date']),
      items: items,
      total: (apiData['montant'] ?? 0).toDouble(),
      reductionAppliquee: apiData['reductionAppliquee'] ?? false,
      montantReduction: (apiData['montantReduction'] ?? 0).toDouble(),
      pointsUtilises: apiData['pointsUtilises'] ?? 0,
      firebaseOrderId: apiData['firebaseOrderId'],
      djangoOrderId: apiData['id']?.toString(),
      etat: apiData['etat'],
      confirmation: apiData['confirmation'],
    );
  }

  // Make the helper method static so it can be used in the factory
  static String _cleanTextEncoding(String text) {
    if (text.isEmpty) return text;
    
    final Map<String, String> replacements = {
      'â': "'",
      'Ã¢': "'",
      'â€™': "'",
      'Ã©': 'é',
      'Ã¨': 'è',
      'Ã ': 'à',
      'Ã§': 'ç',
      'â€œ': '"',
      'â€': '"',
      'â€"': '—',
      'â€"': '–',
      'dâ': "d'",
      'lâ': "l'",
      'câ': "c'",
      'mâ': "m'",
      'nâ': "n'",
      'sâ': "s'",
      'tâ': "t'",
      'jâ': "j'",
    };
    
    String cleanedText = text;
    replacements.forEach((corrupted, correct) {
      cleanedText = cleanedText.replaceAll(corrupted, correct);
    });
    
    return cleanedText;
  }


  static DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    }
    
    return DateTime.now();
  }

  factory OrderHistoryItem.fromMap(Map<String, dynamic> map) {
    return OrderHistoryItem.withDate(
      id: map['id'],
      date: DateTime.parse(map['date']),
      items: (map['items'] as List).map((item) => CartItem.fromMap(item)).toList(),
      total: map['total'],
      reductionAppliquee: map['reductionAppliquee'] ?? false,
      montantReduction: map['montantReduction'] ?? 0,
      pointsUtilises: map['pointsUtilises'] ?? 0,
      firebaseOrderId: map['firebaseOrderId'],
      djangoOrderId: map['djangoOrderId'],
      etat: map['etat'], // ADD THIS
      confirmation: map['confirmation'], // ADD THIS
    );
  }
}

class OrderHistoryService extends ChangeNotifier {
  List<OrderHistoryItem> _orders = [];
  MenuService? _menuService;
  UserService? _userService;
  bool _isLoading = false;
  String? _errorMessage;

  List<OrderHistoryItem> get orders => [..._orders];
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;



  void setMenuService(MenuService menuService) {
    _menuService = menuService;
  }

  void setUserService(UserService userService) {
    _userService = userService;
  }
   String _cleanTextEncoding(String text) {
    if (text.isEmpty) return text;
    
    // Common encoding fixes
    final Map<String, String> replacements = {
      'â': "'",           // Most common apostrophe corruption
      'Ã¢': "'",          // UTF-8 double encoding
      'â€™': "'",         // Smart quote corruption
      'Ã©': 'é',          // e with accent
      'Ã¨': 'è',          // e with grave accent
      'Ã ': 'à',          // a with grave accent
      'Ã§': 'ç',          // c with cedilla
      'â€œ': '"',         // Opening quote
      'â€': '"',          // Closing quote
      'â€"': '—',         // Em dash
      'â€"': '–',         // En dash
      'dâ': "d'",         // Specific fix for "d'Agneau"
      'lâ': "l'",         // Fix for "l'..."
      'câ': "c'",         // Fix for "c'..."
      'mâ': "m'",         // Fix for "m'..."
      'nâ': "n'",         // Fix for "n'..."
      'sâ': "s'",         // Fix for "s'..."
      'tâ': "t'",         // Fix for "t'..."
      'jâ': "j'",         // Fix for "j'..."
    };
    
    String cleanedText = text;
    replacements.forEach((corrupted, correct) {
      cleanedText = cleanedText.replaceAll(corrupted, correct);
    });
    
    return cleanedText;
  }

  Future<void> loadOrderHistory() async {
    if (_menuService == null) {
      debugPrint('❌ MenuService not initialized');
      return;
    }

    if (_userService == null) {
      debugPrint('❌ UserService not initialized');
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Enhanced debugging for authentication status
      debugPrint('🔍 UserService Debug Info:');
      debugPrint('  - isAuthenticated: ${_userService!.isAuthenticated}');
      debugPrint('  - isGuest: ${_userService!.isGuest}');
      debugPrint('  - isLoggedIn: ${_userService!.isLoggedIn}');
      debugPrint('  - nomUtilisateur: ${_userService!.nomUtilisateur}');
      debugPrint('  - email: ${_userService!.email}');

      if (!_userService!.isAuthenticated || _userService!.isGuest) {
        _errorMessage = 'Utilisateur non connecté ou invité';
        debugPrint('❌ User not authenticated or is guest');
        _isLoading = false;
        notifyListeners();
        return;
      }

      final token = _userService!.idToken;
      
      debugPrint('🔑 Token Debug:');
      debugPrint('  - Token exists: ${token != null}');
      debugPrint('  - Token length: ${token?.length ?? 0}');
      debugPrint('  - Token preview: ${token?.substring(0, token.length > 20 ? 20 : token.length) ?? 'null'}...');
      
      if (token == null) {
        _errorMessage = 'Token d\'authentification manquant';
        debugPrint('❌ No authentication token available');
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // CHANGED: Update the endpoint to match your Django backend
      debugPrint('🌐 Making API request to: http://127.0.0.1:8000/api/table/orders/');
      debugPrint('📤 Request headers:');
      debugPrint('  - Authorization: Bearer ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      debugPrint('  - Content-Type: application/json');
      
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/table/orders/'), // CHANGED: from kitchen to table
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      debugPrint('📥 Response received:');
      debugPrint('  - Status Code: ${response.statusCode}');
      debugPrint('  - Headers: ${response.headers}');
      debugPrint('  - Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = response.body;
        if (responseBody.isEmpty) {
          debugPrint('⚠️ Empty response body');
          _orders = [];
        } else {
          try {
            final List<dynamic> ordersData = json.decode(responseBody);
            debugPrint('✅ Successfully parsed JSON, found ${ordersData.length} orders');
            
            _orders = ordersData
                .map((orderData) {
                  debugPrint('Processing order: ${orderData['id']}');
                  return OrderHistoryItem.fromApiResponse(orderData, _menuService!);
                })
                .toList();
                
            _orders.sort((a, b) => b.date.compareTo(a.date));
            debugPrint('✅ Successfully loaded ${_orders.length} orders');
          } catch (jsonError) {
            debugPrint('❌ JSON Parse Error: $jsonError');
            _errorMessage = 'Erreur de format des données: $jsonError';
          }
        }
      } else if (response.statusCode == 403) {
        debugPrint('❌ 403 Forbidden - Token might be invalid or expired');
        debugPrint('Response body: ${response.body}');
        
        // Try to parse error response
        try {
          final errorData = json.decode(response.body);
          _errorMessage = 'Accès refusé: ${errorData['detail'] ?? errorData['error'] ?? 'Token invalide'}';
        } catch (e) {
          _errorMessage = 'Accès refusé - Veuillez vous reconnecter';
        }
        
        // Suggest user to re-login
        debugPrint('💡 Suggestion: User should try logging out and back in');
      } else if (response.statusCode == 401) {
        debugPrint('❌ 401 Unauthorized - Authentication failed');
        _errorMessage = 'Session expirée - Veuillez vous reconnecter';
      } else {
        _errorMessage = 'Erreur serveur: ${response.statusCode}';
        debugPrint('❌ Server error: ${response.statusCode}');
        debugPrint('Error response: ${response.body}');
      }
    } catch (e) {
      _errorMessage = 'Erreur réseau: $e';
      debugPrint('❌ Network error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addOrder({
    required List<CartItem> items,
    required double total,
    bool reductionAppliquee = false,
    double montantReduction = 0,
    int pointsUtilises = 0,
    String? firebaseOrderId,
    String? djangoOrderId,
    String? etat, // ADD THIS
    bool? confirmation, // ADD THIS
  }) {
    _orders.insert(0, OrderHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      items: List.from(items),
      total: total,
      reductionAppliquee: reductionAppliquee,
      montantReduction: montantReduction,
      pointsUtilises: pointsUtilises,
      firebaseOrderId: firebaseOrderId,
      djangoOrderId: djangoOrderId,
      etat: etat, // ADD THIS
      confirmation: confirmation, // ADD THIS
    ));
    notifyListeners();
  }

  void clearHistory() {
    _orders.clear();
    notifyListeners();
  }
}