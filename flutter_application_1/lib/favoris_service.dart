import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavorisService with ChangeNotifier {
  final List<Map<String, dynamic>> _platsFavoris = [];

  List<Map<String, dynamic>> get platsFavoris => _platsFavoris;

  // Méthodes pour compatibilité avec Firebase
  Future<void> ajouterFavoriFirebase(Map<String, dynamic> plat, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('favoris')
          .doc('${userId}_${plat['id']}')
          .set({
            ...plat,
            'userId': userId,
            'timestamp': FieldValue.serverTimestamp(),
          });
          
      if (!_platsFavoris.any((p) => p['id'] == plat['id'])) {
        _platsFavoris.add({...plat, 'isFavorite': true});
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout aux favoris: $e');
    }
  }

  Future<void> supprimerFavoriFirebase(String idPlat, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('favoris')
          .doc('${userId}_$idPlat')
          .delete();
          
      _platsFavoris.removeWhere((plat) => plat['id'] == idPlat);
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la suppression des favoris: $e');
    }
  }

  // Méthodes locales pour compatibilité
  void ajouterFavori(Map<String, dynamic> plat) {
    if (!_platsFavoris.any((p) => p['id'] == plat['id'])) {
      _platsFavoris.add({...plat, 'isFavorite': true});
      notifyListeners();
    }
  }

  void supprimerFavori(String idPlat) {
    _platsFavoris.removeWhere((plat) => plat['id'] == idPlat);
    notifyListeners();
  }

  bool estFavori(String idPlat) {
    return _platsFavoris.any((plat) => plat['id'] == idPlat);
  }

  Future<void> toggleFavori(Map<String, dynamic> plat, String userId) async {
    if (estFavori(plat['id'])) {
      await supprimerFavoriFirebase(plat['id'], userId);
    } else {
      await ajouterFavoriFirebase(plat, userId);
    }
  }

  Future<void> chargerFavoris(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('favoris')
          .where('userId', isEqualTo: userId)
          .get();

      _platsFavoris.clear();
      _platsFavoris.addAll(snapshot.docs.map((doc) => doc.data()));
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors du chargement des favoris: $e');
    }
  }
}