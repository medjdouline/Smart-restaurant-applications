import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Méthodes d'authentification
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  Future<UserCredential?> registerWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Erreur d\'inscription: $e');
    }
  }

  // Méthodes pour les commandes
  Future<void> saveOrder(Map<String, dynamic> orderData) async {
    try {
      await _firestore.collection('orders').add(orderData);
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde: $e');
    }
  }

  Stream<QuerySnapshot> getOrderHistory(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Autres méthodes utiles
  User? get currentUser => _auth.currentUser;
}