import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:good_taste/data/models/regime_model.dart';

class RegimeRepository {
  static const String _regimesKeyPrefix = 'user_regimes_';
  

  Future<List<String>> getRegimes({String userId = ''}) async {
    final prefs = await SharedPreferences.getInstance();
    final String regimesKey = _getRegimesKey(userId);
    final String? regimesJson = prefs.getString(regimesKey);
    
    if (regimesJson == null) {
      return [];
    }
    
    try {
      final List<dynamic> decodedList = json.decode(regimesJson);
      return decodedList.map((item) => item.toString()).toList();
    } catch (e) {
      print('Erreur lors de la récupération des régimes: $e');
      return [];
    }
  }
  
 
  Future<RegimeModel> getRegimeModel({String userId = ''}) async {
    final regimes = await getRegimes(userId: userId);
    return RegimeModel(regimes: regimes);
  }
  
 
  Future<void> saveRegimes(List<String> regimes, {String userId = ''}) async {
    final prefs = await SharedPreferences.getInstance();
    final String regimesKey = _getRegimesKey(userId);
    final String encodedList = json.encode(regimes);
    await prefs.setString(regimesKey, encodedList);
  }
  

  Future<void> saveRegimeModel(RegimeModel regimeModel, {String userId = ''}) async {
    await saveRegimes(regimeModel.regimes, userId: userId);
  }
  
  
  Future<List<String>> toggleRegime(String regime, {String userId = ''}) async {
    final regimes = await getRegimes(userId: userId);
    
    if (regimes.contains(regime)) {
      regimes.remove(regime);
    } else {
      regimes.add(regime);
    }
    
    await saveRegimes(regimes, userId: userId);
    return regimes;
  }
  
  
  Future<bool> isRegimeSelected(String regime, {String userId = ''}) async {
    final regimes = await getRegimes(userId: userId);
    return regimes.contains(regime);
  }
  
  
  String _getRegimesKey(String userId) {
    if (userId.isEmpty) {
      return _regimesKeyPrefix + 'default';
    }
    return _regimesKeyPrefix + userId;
  }
}