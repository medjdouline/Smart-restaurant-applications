import 'package:good_taste/data/models/allergies_model.dart';
import 'package:good_taste/data/models/regime_model.dart';
import 'package:good_taste/data/models/preferences_model.dart';

class User {
  final String id;
  final String email;
  final String name;
  final String? profileImage;
  final String? phoneNumber;
  final String? gender;
  final DateTime? dateOfBirth;
  final AllergiesModel allergies;
  final RegimeModel regimes; 
  final PreferencesModel preferences;
  final String? idToken;
  final int loyaltyPoints; 

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.profileImage,
    this.phoneNumber,
    this.gender,
    this.dateOfBirth,
    this.allergies = const AllergiesModel(),
    this.regimes = const RegimeModel(), 
    this.preferences = const PreferencesModel(),
    this.idToken,
    this.loyaltyPoints = 0, // AJOUTÉ
  });
  
  static const empty = User(
    id: '',
    email: '',
    name: '',
    profileImage: null,
    phoneNumber: null,
    gender: null,
    dateOfBirth: null,
    allergies: AllergiesModel(),
    regimes: RegimeModel(), 
    preferences: PreferencesModel(),
    loyaltyPoints: 0, // AJOUTÉ
  );
  
  bool get isEmpty => this == User.empty;
  bool get isNotEmpty => this != User.empty;
  

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? profileImage,
    String? phoneNumber,
    String? gender,
    DateTime? dateOfBirth,
    AllergiesModel? allergies,
    RegimeModel? regimes, 
    PreferencesModel? preferences,
    int? loyaltyPoints, // AJOUTÉ
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      allergies: allergies ?? this.allergies,
      regimes: regimes ?? this.regimes, 
      preferences: preferences ?? this.preferences,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && 
           other.id == id && 
           other.email == email && 
           other.name == name &&
           other.profileImage == profileImage &&
           other.phoneNumber == phoneNumber &&
           other.gender == gender &&
           other.dateOfBirth == dateOfBirth &&
           other.allergies == allergies &&
           other.regimes == regimes && 
           other.preferences == preferences &&
           other.loyaltyPoints == loyaltyPoints;
  }
  
  @override
  int get hashCode => id.hashCode ^ 
                     email.hashCode ^ 
                     name.hashCode ^ 
                     (profileImage?.hashCode ?? 0) ^ 
                     (phoneNumber?.hashCode ?? 0) ^
                     (gender?.hashCode ?? 0) ^
                     (dateOfBirth?.hashCode ?? 0) ^
                     allergies.hashCode ^
                     regimes.hashCode^ 
                     preferences.hashCode ^
                     loyaltyPoints.hashCode; 
}