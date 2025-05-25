import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:convert';
import 'order_history_service.dart';

class CartItem {
  final String id;
  final String nom;
  final double prix;
  final String? imageUrl;
  final int pointsFidelite;
  int quantite;

  CartItem({
    required this.id,
    required this.nom,
    required this.prix,
    this.imageUrl,
    required this.pointsFidelite,
    this.quantite = 1,
  });

  double get totalPrice => prix * quantite;
  int get totalPoints => pointsFidelite * quantite;
  String get prixFormatted => '${prix.toInt()} DA';
  String get totalPriceFormatted => '${totalPrice.toInt()} DA';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prix': prix,
      'imageUrl': imageUrl,
      'quantite': quantite,
      'pointsFidelite': pointsFidelite,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'],
      nom: map['nom'],
      prix: map['prix'].toDouble(),
      imageUrl: map['imageUrl'],
      quantite: map['quantite'],
      pointsFidelite: map['pointsFidelite'] ?? 0,
    );
  }
}

class CartService extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  static const int SEUIL_REDUCTION = 10;
  static const double POURCENTAGE_REDUCTION = 0.50;
  static const String _djangoApiUrl = 'https://api.votredomaine.com/api/orders/create/';

  Map<String, CartItem> get items => {..._items};
  int get itemCount => _items.length;
  
  int get totalPointsFidelite {
    return _items.values.fold(0, (sum, item) => sum + item.totalPoints);
  }
  
  bool get reductionDisponible => totalPointsFidelite >= SEUIL_REDUCTION;
  bool get reductionActive => reductionDisponible;

  double get montantAvantReduction => _items.values.fold(0, (sum, item) => sum + item.totalPrice);
  double get montantReduction => reductionActive ? (montantAvantReduction * POURCENTAGE_REDUCTION) : 0;
  double get totalAmount => montantAvantReduction - montantReduction;
  String get totalAmountFormatted => '${totalAmount.toInt()} DA';

  // Méthodes inchangées
  void addItem({
    required String id,
    required String nom,
    required double prix,
    String? imageUrl,
    required int pointsFidelite,
  }) {
    if (_items.containsKey(id)) {
      _items.update(
        id,
        (existing) => CartItem(
          id: existing.id,
          nom: existing.nom,
          prix: existing.prix,
          imageUrl: existing.imageUrl,
          pointsFidelite: existing.pointsFidelite,
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
          pointsFidelite: pointsFidelite,
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
          pointsFidelite: existing.pointsFidelite,
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

  // Méthode confirmOrder corrigée
  Future<void> confirmOrder(BuildContext context) async {
    if (_items.isEmpty) return;

    final orderHistory = Provider.of<OrderHistoryService>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      _showError(context, 'Vous devez être connecté pour commander');
      return;
    }

    try {
      final orderData = _prepareOrderData(user.uid);
      final orderRef = await _saveOrderToFirestore(orderData);
      final response = await _sendToDjangoAPI(orderData, orderRef.id);

      if (response.statusCode == 201) {
        await _handleSuccessfulOrder(
          context,
          orderHistory,
          orderRef,
          json.decode(response.body),
        );
      } else {
        throw http.ClientException(
          'Erreur API: ${response.statusCode}',
          Uri.parse(_djangoApiUrl),
        );
      }
    } on TimeoutException catch (_) {
      _showError(context, 'Timeout - Serveur non disponible');
    } on http.ClientException catch (e) {
      _showError(context, 'Erreur réseau: ${e.message}');
    } catch (e) {
      _showError(context, 'Erreur inattendue: ${e.toString()}');
    }
  }

  // Méthodes helpers
  Map<String, dynamic> _prepareOrderData(String userId) {
    return {
      'items': _items.values.map((item) => item.toMap()).toList(),
      'total': totalAmount,
      'reduction_appliquee': reductionActive,
      'montant_reduction': montantReduction,
      'points_utilises': totalPointsFidelite,
      'user_id': userId,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  Future<DocumentReference> _saveOrderToFirestore(Map<String, dynamic> orderData) {
    return FirebaseFirestore.instance.collection('commandes').add(orderData);
  }

  Future<http.Response> _sendToDjangoAPI(
    Map<String, dynamic> orderData,
    String firebaseOrderId,
  ) async {
    return await http.post(
      Uri.parse(_djangoApiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await FirebaseAuth.instance.currentUser!.getIdToken()}',
      },
      body: json.encode({
        ...orderData,
        'firebase_order_id': firebaseOrderId,
      }),
    ).timeout(const Duration(seconds: 10));
  }

  Future<void> _handleSuccessfulOrder(
    BuildContext context,
    OrderHistoryService orderHistory,
    DocumentReference orderRef,
    Map<String, dynamic> responseData,
  ) async {
    await orderRef.update({
      'django_order_id': responseData['id'],
      'status': 'confirmed',
    });

    orderHistory.addOrder(
      items: _items.values.toList(),
      total: totalAmount,
      reductionAppliquee: reductionActive,
      montantReduction: montantReduction,
      pointsUtilises: totalPointsFidelite,
      firebaseOrderId: orderRef.id,
      djangoOrderId: responseData['id'].toString(),
    );

    await _updateUserPoints();
    _showSuccess(context);
    clear();
    _navigateBack(context);
  }

  Future<void> _updateUserPoints() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({
      'pointsFidelite': FieldValue.increment(-totalPointsFidelite),
    });
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
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
}