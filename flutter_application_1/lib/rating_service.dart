import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RatingService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, Map<String, double>> _userRatings = {};

  // Add this method to get a stream of rating data
  Stream<DocumentSnapshot> getRatingStream(String itemId) {
    return _firestore.collection('ratings').doc(itemId).snapshots();
  }

  // Existing methods...
  Stream<Map<String, dynamic>> getRatingData(String itemId) {
    return Stream.value({
      'averageRating': getAverageRating(itemId),
      'ratingCount': getRatingCount(itemId),
    });
  }

  Future<void> addRating(String itemId, double rating, [String? userId]) async {
    try {
      final user = userId ?? 'anonymous';
      _userRatings.putIfAbsent(itemId, () => {})[user] = rating;
      
      await _firestore.collection('ratings').doc(itemId).set({
        'ratings': FieldValue.arrayUnion([rating]),
        'userIds': FieldValue.arrayUnion([user]),
        'averageRating': getAverageRating(itemId),
        'ratingCount': getRatingCount(itemId),
      }, SetOptions(merge: true));
      
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout de la note: $e');
    }
  }

  double getAverageRating(String itemId) {
    if (!_userRatings.containsKey(itemId)) {
      return 0.0;
    }
    
    final ratings = _userRatings[itemId]!.values;
    if (ratings.isEmpty) {
      return 0.0;
    }
    
    final sum = ratings.reduce((a, b) => a + b);
    return sum / ratings.length;
  }

  int getRatingCount(String itemId) {
    return _userRatings[itemId]?.length ?? 0;
  }

  double getUserRating(String itemId, {String userId = 'current_user'}) {
    return _userRatings[itemId]?[userId] ?? 0.0;
  }
}