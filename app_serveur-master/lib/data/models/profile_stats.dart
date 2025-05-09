// lib/data/models/profile_stats.dart
class ProfileStats {
  final int handledOrders;
  final Map<String, dynamic> profileData;
  
  ProfileStats({
    required this.handledOrders,
    required this.profileData,
  });
  
  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    // Extract employee data from the profile field
    final profileData = json['profile'] ?? {};
    
    // Get orders count from the response or default to 0
    int ordersCount = 0;
    if (json.containsKey('commandes_count')) {
      ordersCount = json['commandes_count'] ?? 0;
    }
    
    return ProfileStats(
      handledOrders: ordersCount,
      profileData: profileData,
    );
  }
  
  // Helper getters for common profile fields
  String? get nom => profileData['nomE'] as String?;
  String? get prenom => profileData['prenomE'] as String?;
  String? get email => profileData['emailE'] as String?;
  String? get phone => profileData['telephoneE'] as String?;
  String? get position => profileData['posteE'] as String?;
  String? get address => profileData['adresseE'] as String?;
  
  @override
  String toString() => 'ProfileStats{handledOrders: $handledOrders, profile: $profileData}';
}