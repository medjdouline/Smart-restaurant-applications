import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:good_taste/data/models/allergies_model.dart';
import 'package:flutter/foundation.dart'; // Import for logging

class AllergiesRepository {
  static const String _allergiesKeyPrefix = 'user_allergies_';
  
  Future<List<String>> getAllergies({String userId = ''}) async {
    final prefs = await SharedPreferences.getInstance();
    final String allergiesKey = _getAllergiesKey(userId);
    final String? allergiesJson = prefs.getString(allergiesKey);
    
    if (allergiesJson == null) {
      return [];
    }
    
    try {
      final List<dynamic> decodedList = json.decode(allergiesJson);
      return decodedList.map((item) => item.toString()).toList();
    } catch (e) {
      
      debugPrint('Erreur lors de la récupération des allergies: $e');
      return [];
    }
  }
  
 
  Future<AllergiesModel> getAllergiesModel({String userId = ''}) async {
    final allergies = await getAllergies(userId: userId);
    return AllergiesModel(allergies: allergies);
  }
  

  Future<void> saveAllergies(List<String> allergies, {String userId = ''}) async {
    final prefs = await SharedPreferences.getInstance();
    final String allergiesKey = _getAllergiesKey(userId);
    final String encodedList = json.encode(allergies);
    await prefs.setString(allergiesKey, encodedList);
  }
  
  
  Future<void> saveAllergiesModel(AllergiesModel allergiesModel, {String userId = ''}) async {
    await saveAllergies(allergiesModel.allergies, userId: userId);
  }
  

  Future<List<String>> toggleAllergy(String allergy, {String userId = ''}) async {
    final allergies = await getAllergies(userId: userId);
    
    if (allergies.contains(allergy)) {
      allergies.remove(allergy);
    } else {
      allergies.add(allergy);
    }
    
    await saveAllergies(allergies, userId: userId);
    return allergies;
  }


  Future<bool> isAllergySelected(String allergy, {String userId = ''}) async {
    final allergies = await getAllergies(userId: userId);
    return allergies.contains(allergy);
  }
  
 
  String _getAllergiesKey(String userId) {
    if (userId.isEmpty) {
      return '${_allergiesKeyPrefix}default';
    }
    return '${_allergiesKeyPrefix}$userId';
  }
}