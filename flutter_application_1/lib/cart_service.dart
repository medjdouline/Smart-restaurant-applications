import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:convert';
import 'order_history_service.dart';
import 'user_service.dart';
import 'services/menu_service.dart';

class CartItem {
  final String id;
  final String nom;
  final double prix;
  final String? imageUrl;
  int quantite;

  CartItem({
    required this.id,
    required this.nom,
    required this.prix,
    this.imageUrl,
    this.quantite = 1,
  });

  double get totalPrice => prix * quantite;
  String get prixFormatted => '${prix.toInt()} DA';
  String get totalPriceFormatted => '${totalPrice.toInt()} DA';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prix': prix,
      'imageUrl': imageUrl,
      'quantite': quantite,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'],
      nom: map['nom'],
      prix: map['prix'].toDouble(),
      imageUrl: map['imageUrl'],
      quantite: map['quantite'],
    );
  }
}

class CartService extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  static const String _djangoApiUrl = 'http://127.0.0.1:8000/api/table/orders/create/';

  Map<String, CartItem> get items => {..._items};
  int get itemCount => _items.length;

  double get totalAmount => _items.values.fold(0, (sum, item) => sum + item.totalPrice);
  String get totalAmountFormatted => '${totalAmount.toInt()} DA';

  void addItem({
    required String id,
    required String nom,
    required double prix,
    String? imageUrl,
  }) {
    if (_items.containsKey(id)) {
      _items.update(
        id,
        (existing) => CartItem(
          id: existing.id,
          nom: existing.nom,
          prix: existing.prix,
          imageUrl: existing.imageUrl,
          quantite: existing.quantite + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        id,
        () => CartItem(
          id: id,
          nom: nom,
          prix: prix,
          imageUrl: imageUrl,
        ),
      );
    }
    notifyListeners();
  }

  void removeItem(String id) {
    _items.remove(id);
    notifyListeners();
  }

  void removeSingleItem(String id) {
    if (!_items.containsKey(id)) return;
    if (_items[id]!.quantite > 1) {
      _items.update(
        id,
        (existing) => CartItem(
          id: existing.id,
          nom: existing.nom,
          prix: existing.prix,
          imageUrl: existing.imageUrl,
          quantite: existing.quantite - 1,
        ),
      );
    } else {
      _items.remove(id);
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  // Validate cart items against menu service
  List<Map<String, dynamic>>? validateAndPrepareOrderItems(MenuService menuService) {
    List<Map<String, dynamic>> validatedItems = [];
    
    for (var cartItem in _items.values) {
      final menuItem = menuService.findItemById(cartItem.id);
      
      if (menuItem == null) {
        debugPrint('ERROR: Item ${cartItem.id} not found in menu service');
        return null;
      }
      
      if (menuItem.prix != cartItem.prix) {
        debugPrint('WARNING: Price mismatch for item ${cartItem.id}. Menu: ${menuItem.prix}, Cart: ${cartItem.prix}');
      }
      
      validatedItems.add({
        'plat_id': cartItem.id,
        'quantity': cartItem.quantite,
      });
    }
    
    debugPrint('Validated ${validatedItems.length} items for order');
    return validatedItems;
  }

  // UPDATED CONFIRMORDER METHOD - Clean Flow
  Future<void> confirmOrder(BuildContext context, String tableId) async {
    if (_items.isEmpty) return;

    final orderHistory = Provider.of<OrderHistoryService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);
    final menuService = Provider.of<MenuService>(context, listen: false);
    
    debugPrint('=== DÉBUT CONFIRMATION COMMANDE ===');
    debugPrint('User logged in: ${userService.isLoggedIn}');
    debugPrint('Is guest: ${userService.isGuest}');
    debugPrint('Table ID: $tableId');

    try {
      // 1. Validate cart items against menu service
      final validatedItems = validateAndPrepareOrderItems(menuService);
      if (validatedItems == null) {
        _showError(context, 'Erreur: Certains articles du panier ne sont plus disponibles');
        return;
      }

      // 2. Prepare Django order data
      final djangoOrderData = _prepareDjangoOrderData(tableId, validatedItems, userService);
      
      // 3. Send to Django API first (this creates the order)
      final response = await _sendToDjangoAPI(djangoOrderData, userService);

      debugPrint('Réponse Django: ${response.statusCode}');
      debugPrint('Corps de la réponse: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        
        // 4. Save to Firestore using admin privileges (no auth required)
        await _saveOrderToFirestoreAdmin(djangoOrderData, responseData, userService);
        
        // 5. Handle successful order
        await _handleSuccessfulOrder(context, orderHistory, responseData);
      } else {
        throw http.ClientException(
          'Erreur API: ${response.statusCode} - ${response.body}',
          Uri.parse(_djangoApiUrl),
        );
      }
    } on TimeoutException catch (_) {
      debugPrint('Timeout lors de la commande');
      _showError(context, 'Timeout - Serveur non disponible');
    } on http.ClientException catch (e) {
      debugPrint('Erreur client: ${e.message}');
      _showError(context, 'Erreur réseau: ${e.message}');
    } catch (e) {
      debugPrint('Erreur inattendue: $e');
      _showError(context, 'Erreur inattendue: ${e.toString()}');
    }
  }

  // NEW METHOD: Save to Firestore using admin approach
Future<void> _saveOrderToFirestoreAdmin(
  Map<String, dynamic> orderData, 
  Map<String, dynamic> djangoResponse,
  UserService userService
) async {
  debugPrint('=== SAUVEGARDE DANS FIRESTORE (ADMIN) ===');
  
  try {
    // Get user information from UserService properly
    String userId = 'anonymous';
    String userEmail = 'anonymous@restaurant.com';
    bool isGuest = true;
    
    if (userService.isLoggedIn) {
      if (!userService.isGuest) {
        // Regular authenticated user
        userId = userService.firebaseUser?.uid ?? 'authenticated_user';
        userEmail = userService.email ?? 'user@restaurant.com';
        isGuest = false;
      } else {
        // Guest user
        userId = userService.firebaseUser?.uid ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
        userEmail = 'guest@restaurant.com';
        isGuest = true;
      }
    }
    
    debugPrint('Firestore - User ID: $userId');
    debugPrint('Firestore - User Email: $userEmail');
    debugPrint('Firestore - Is Guest: $isGuest');
    
    final firestoreData = {
      'items': _items.values.map((item) => {
        'plat_id': item.id,
        'nom': item.nom,
        'prix': item.prix,
        'quantity': item.quantite,
        'total_item': item.totalPrice,
      }).toList(),
      'table_id': orderData['table_id'],
      'total': totalAmount,
      'user_id': userId,
      'user_email': userEmail,
      'is_guest': isGuest,
      'etat': 'confirmed',
      'django_order_id': djangoResponse['order_id'],
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };

    debugPrint('Données Firestore: ${json.encode(firestoreData)}');
    
    // Save to Firestore
    final docRef = await FirebaseFirestore.instance
        .collection('commandes')
        .add(firestoreData)
        .timeout(const Duration(seconds: 10));
    
    debugPrint('Commande sauvegardée dans Firestore: ${docRef.id}');
    
  } catch (e) {
    debugPrint('Erreur Firestore (non critique): $e');
    // Don't throw - Firestore save is optional if Django is primary
  }
}

  // UPDATED: Prepare Django order data
Map<String, dynamic> _prepareDjangoOrderData(
  String tableId, 
  List<Map<String, dynamic>> validatedItems, 
  UserService userService
) {
  debugPrint('=== PREPARING DJANGO ORDER DATA ===');
  debugPrint('Preparing Django order data with ${validatedItems.length} validated items');
  
  final clientId = _getClientId(userService);
  debugPrint('Final client ID for Django: $clientId');
  
  final requestData = {
    'items': validatedItems,
    'table_id': tableId,
    'total': totalAmount,
  };
  
  // Add client information if available
  if (clientId != null) {
    requestData['client_id'] = clientId;
    
    if (userService.isLoggedIn) {
      if (!userService.isGuest) {
        // Regular user
        requestData['client_email'] = userService.email ?? 'user@restaurant.com';
        requestData['is_guest'] = false;
        debugPrint('Added regular user info - Email: ${userService.email}');
      } else {
        // Guest user
        requestData['client_email'] = 'guest@restaurant.com';
        requestData['is_guest'] = true;
        debugPrint('Added guest user info');
      }
    }
  } else {
    debugPrint('WARNING: No client ID available - order will be anonymous');
  }
  
  debugPrint('Final Django request data: $requestData');
  return requestData;
}


 Future<http.Response> _sendToDjangoAPI(
  Map<String, dynamic> orderData,
  UserService userService,
) async {
  debugPrint('=== ENVOI À DJANGO API ===');
  debugPrint('URL: $_djangoApiUrl');
  
  
  final requestBody = {
    'items': List<Map<String, dynamic>>.from(orderData['items']),
    'table_id': orderData['table_id'].toString(),
  };
  
  
  // Add client info if available - THIS IS THE KEY PART
  final clientId = _getClientId(userService);
  if (clientId != null) {
    requestBody['client_id'] = clientId;
    debugPrint('Added client_id to request: $clientId');
    
    // Also add these fields for better tracking
    requestBody['client_email'] = userService.email ?? 'guest@restaurant.com';
    requestBody['is_guest'] = userService.isGuest;
  }

  debugPrint('Corps de la requête Django: ${json.encode(requestBody)}');

  // Prepare headers
  final headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Add authentication header if user is authenticated (not guest)
  if (userService.isLoggedIn && !userService.isGuest && userService.idToken != null) {
    headers['Authorization'] = 'Bearer ${userService.idToken}';
    debugPrint('Using Django token authentication');
  } else {
    debugPrint('Using public API (guest or unauthenticated user)');
  }

  try {
    final response = await http.post(
      Uri.parse(_djangoApiUrl),
      headers: headers,
      body: json.encode(requestBody),
    ).timeout(const Duration(seconds: 15));
    
    debugPrint('Django API Response received: ${response.statusCode}');
    debugPrint('Django API Response body: ${response.body}');
    return response;
  } catch (e) {
    debugPrint('HTTP request failed: $e');
    rethrow;
  }
}

  // UPDATED: Handle successful order
  Future<void> _handleSuccessfulOrder(
    BuildContext context,
    OrderHistoryService orderHistory,
    Map<String, dynamic> responseData,
  ) async {
    debugPrint('=== COMMANDE RÉUSSIE ===');
    debugPrint('Données de réponse: $responseData');

    // Add to order history
    orderHistory.addOrder(
      items: _items.values.toList(),
      total: totalAmount,
      firebaseOrderId: '', // Not critical since Django is primary
      djangoOrderId: responseData['order_id'].toString(),
    );

    _showSuccess(context);
    clear();
    _navigateBack(context);
  }

  void _showSuccess(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Commande confirmée! Total: ${totalAmount.toInt()} DA'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    debugPrint('ERREUR: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _navigateBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'items': _items.values.map((item) => item.toMap()).toList(),
    };
  }

  void fromMap(Map<String, dynamic> map) {
    _items.clear();
    (map['items'] as List).forEach((itemMap) {
      final item = CartItem.fromMap(itemMap);
      _items[item.id] = item;
    });
    notifyListeners();
  }

  String? _getClientId(UserService userService) {
    debugPrint('=== GETTING CLIENT ID ===');
    debugPrint('User logged in: ${userService.isLoggedIn}');
    debugPrint('Is guest: ${userService.isGuest}');
    debugPrint('Firebase User UID: ${userService.firebaseUser?.uid}');
    
    if (userService.isLoggedIn) {
      String? clientId;
      
      if (!userService.isGuest) {
        // Regular authenticated user - use Firebase UID
        clientId = userService.firebaseUser?.uid;
        debugPrint('Regular user client ID: $clientId');
      } else {
        // Guest user - use Firebase UID if available, otherwise generate one
        clientId = userService.firebaseUser?.uid ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
        debugPrint('Guest user client ID: $clientId');
      }
      
      return clientId;
    }
    
    debugPrint('No user logged in - returning null');
    return null;
  }
}