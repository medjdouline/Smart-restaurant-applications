import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:good_taste/data/models/preferences_model.dart';

class PreferencesRepository {
  static const String _preferencesKeyPrefix = 'user_preferences_';
  
 
  Future<List<String>> getPreferences({String userId = ''}) async {
    final prefs = await SharedPreferences.getInstance();
    final String preferencesKey = _getPreferencesKey(userId);
    final String? preferencesJson = prefs.getString(preferencesKey);
    
    if (preferencesJson == null) {
      return [];
    }
    
    try {
      final List<dynamic> decodedList = json.decode(preferencesJson);
      return decodedList.map((item) => item.toString()).toList();
    } catch (e) {
      print('Erreur lors de la récupération des préférences: $e');
      return [];
    }
  }
  
 
  Future<PreferencesModel> getPreferencesModel({String userId = ''}) async {
    final preferences = await getPreferences(userId: userId);
    return PreferencesModel(preferences: preferences);
  }
  
 
  Future<void> savePreferences(List<String> preferences, {String userId = ''}) async {
    final prefs = await SharedPreferences.getInstance();
    final String preferencesKey = _getPreferencesKey(userId);
    final String encodedList = json.encode(preferences);
    await prefs.setString(preferencesKey, encodedList);
  }
  
 
  Future<void> savePreferencesModel(PreferencesModel preferencesModel, {String userId = ''}) async {
    await savePreferences(preferencesModel.preferences, userId: userId);
  }
  
 
  Future<List<String>> togglePreference(String preference, {String userId = ''}) async {
    final preferences = await getPreferences(userId: userId);
    
    if (preferences.contains(preference)) {
      preferences.remove(preference);
    } else {
      preferences.add(preference);
    }
    
    await savePreferences(preferences, userId: userId);
    return preferences;
  }
  
 
  Future<bool> isPreferenceSelected(String preference, {String userId = ''}) async {
    final preferences = await getPreferences(userId: userId);
    return preferences.contains(preference);
  }
  
  String _getPreferencesKey(String userId) {
    if (userId.isEmpty) {
      return _preferencesKeyPrefix + 'default';
    }
    return _preferencesKeyPrefix + userId;
  }
}