import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'cart_service.dart';
import '../services/menu_service.dart';
import 'user_service.dart';

class CancellationRequest {
  final String id;
  final String orderId;
  final String motif;
  final String statut;
  final DateTime createdAt;
  final double orderAmount;
  final String orderStatus;

  CancellationRequest({
    required this.id,
    required this.orderId,
    required this.motif,
    required this.statut,
    required this.createdAt,
    required this.orderAmount,
    required this.orderStatus,
  });

  factory CancellationRequest.fromApiResponse(Map<String, dynamic> apiData) {
    return CancellationRequest(
      id: apiData['id']?.toString() ?? '',
      orderId: apiData['order_id']?.toString() ?? '',
      motif: apiData['motif'] ?? '',
      statut: apiData['statut'] ?? '',
      createdAt: _parseDate(apiData['created_at']),
      orderAmount: (apiData['order_amount'] ?? 0).toDouble(),
      orderStatus: apiData['order_status'] ?? '',
    );
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
}

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
  final String? etat;
  final bool? confirmation;

  OrderHistoryItem({
    required this.id,
    required this.items,
    required this.total,
    required this.reductionAppliquee,
    required this.montantReduction,
    required this.pointsUtilises,
    this.firebaseOrderId,
    this.djangoOrderId,
    this.etat,
    this.confirmation,
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
    this.etat,
    this.confirmation,
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
      'etat': etat,
      'confirmation': confirmation,
    };
  }

  factory OrderHistoryItem.fromApiResponse(Map<String, dynamic> apiData, MenuService menuService) {
    List<CartItem> items = [];
    
    if (apiData['items'] != null && apiData['items'] is List) {
      for (var itemData in apiData['items']) {
        final menuItem = menuService.findItemById(itemData['id']?.toString() ?? '');
        
        String dishName = itemData['nom'] ?? menuItem?.nom ?? 'Plat inconnu';
        dishName = _cleanTextEncoding(dishName);
        
        items.add(CartItem(
          id: itemData['id']?.toString() ?? '',
          nom: dishName,
          prix: (itemData['prix'] ?? menuItem?.prix ?? 0).toDouble(),
          quantite: itemData['quantite'] ?? 1,
          imageUrl: menuItem?.image ?? 'assets/images/placeholder.jpg',
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
      etat: map['etat'],
      confirmation: map['confirmation'],
    );
  }
}

class OrderHistoryService extends ChangeNotifier {
  List<OrderHistoryItem> _orders = [];
  List<CancellationRequest> _cancellationRequests = [];
  MenuService? _menuService;
  UserService? _userService;
  bool _isLoading = false;
  bool _isLoadingCancellations = false;
  String? _errorMessage;

  // Getters
  List<OrderHistoryItem> get orders => [..._orders];
  List<CancellationRequest> get cancellationRequests => [..._cancellationRequests];
  bool get isLoading => _isLoading;
  bool get isLoadingCancellations => _isLoadingCancellations;
  String? get errorMessage => _errorMessage;

  void setMenuService(MenuService menuService) {
    _menuService = menuService;
  }

  void setUserService(UserService userService) {
    _userService = userService;
  }

  String _cleanTextEncoding(String text) {
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
      debugPrint('🔍 UserService Debug Info:');
      debugPrint('  - isAuthenticated: ${_userService!.isAuthenticated}');
      debugPrint('  - isGuest: ${_userService!.isGuest}');
      debugPrint('  - isLoggedIn: ${_userService!.isLoggedIn}');

      if (!_userService!.isAuthenticated || _userService!.isGuest) {
        _errorMessage = 'Utilisateur non connecté ou invité';
        debugPrint('❌ User not authenticated or is guest');
        _isLoading = false;
        notifyListeners();
        return;
      }

      final token = _userService!.idToken;
      
      if (token == null) {
        _errorMessage = 'Token d\'authentification manquant';
        debugPrint('❌ No authentication token available');
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      debugPrint('🌐 Making API request to: http://127.0.0.1:8000/api/table/orders/');
      
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/table/orders/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      debugPrint('📥 Response received:');
      debugPrint('  - Status Code: ${response.statusCode}');
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
        try {
          final errorData = json.decode(response.body);
          _errorMessage = 'Accès refusé: ${errorData['detail'] ?? errorData['error'] ?? 'Token invalide'}';
        } catch (e) {
          _errorMessage = 'Accès refusé - Veuillez vous reconnecter';
        }
      } else if (response.statusCode == 401) {
        debugPrint('❌ 401 Unauthorized - Authentication failed');
        _errorMessage = 'Session expirée - Veuillez vous reconnecter';
      } else {
        _errorMessage = 'Erreur serveur: ${response.statusCode}';
        debugPrint('❌ Server error: ${response.statusCode}');
      }
    } catch (e) {
      _errorMessage = 'Erreur réseau: $e';
      debugPrint('❌ Network error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // Load cancellation requests
    if (!_userService!.isGuest && _userService!.isAuthenticated) {
      await loadCancellationRequests();
    }
  }

  Future<bool> cancelOrder(String orderId, {String? motif}) async {
    if (_userService == null || !_userService!.isAuthenticated) {
      debugPrint('❌ User not authenticated');
      return false;
    }

    try {
      final token = _userService!.idToken;
      if (token == null) {
        debugPrint('❌ No authentication token');
        return false;
      }

      debugPrint('🚫 Cancelling order: $orderId');
      
      final response = await http.patch(
        Uri.parse('http://127.0.0.1:8000/api/table/orders/$orderId/cancel/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'motif': motif ?? 'Annulation demandée par le client'
        }),
      );

      debugPrint('📥 Cancel response: ${response.statusCode}');
      debugPrint('📥 Cancel body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint('✅ Order cancellation successful: ${responseData['message']}');
        
        // Refresh the order history to get updated status
        await loadOrderHistory();
        return true;
      } else {
        debugPrint('❌ Cancel failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Cancel error: $e');
      return false;
    }
  }

  Future<void> loadCancellationRequests() async {
    if (_userService == null || !_userService!.isAuthenticated) {
      debugPrint('❌ User not authenticated for cancellation requests');
      return;
    }

    _isLoadingCancellations = true;
    notifyListeners();

    try {
      final token = _userService!.idToken;
      if (token == null) {
        debugPrint('❌ No token for cancellation requests');
        _isLoadingCancellations = false;
        notifyListeners();
        return;
      }

      debugPrint('🔍 Loading cancellation requests...');
      
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/table/cancellation-requests/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      debugPrint('📥 Cancellation requests response: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> requestsData = json.decode(response.body);
        debugPrint('✅ Found ${requestsData.length} cancellation requests');
        
        _cancellationRequests = requestsData
            .map((requestData) => CancellationRequest.fromApiResponse(requestData))
            .toList();
            
        _cancellationRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
      } else {
        debugPrint('❌ Failed to load cancellation requests: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error loading cancellation requests: $e');
    } finally {
      _isLoadingCancellations = false;
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
    String? etat,
    bool? confirmation,
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
      etat: etat,
      confirmation: confirmation,
    ));
    notifyListeners();
  }

  void clearHistory() {
    _orders.clear();
    _cancellationRequests.clear();
    notifyListeners();
  }
}