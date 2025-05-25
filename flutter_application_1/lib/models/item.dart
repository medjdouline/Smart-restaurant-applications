import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final String id;
  final String nom;
  final String sousCategorie;
  final double prix;
  final String description;
  final String ingredients;
  final String image;
  final int pointsFidelite;

  Item({
    required this.id,
    required this.nom,
    required this.sousCategorie,
    required this.prix,
    required this.description,
    required this.ingredients,
    required this.image,
    required this.pointsFidelite,
  });

  // Depuis une Map
  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] ?? '',
      nom: map['nom'] ?? '',
      sousCategorie: map['sous_categorie'] ?? '',
      prix: (map['prix'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      ingredients: map['ingredients'] ?? '',
      image: map['image'] ?? '',
      pointsFidelite: map['pointsFidelite'] ?? 0,
    );
  }

  // Depuis un DocumentSnapshot Firestore
  factory Item.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Item(
      id: doc.id,
      nom: data['nom'] ?? '',
      sousCategorie: data['sous_categorie'] ?? '',
      prix: (data['prix'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      ingredients: data['ingredients'] ?? '',
      image: data['image'] ?? '',
      pointsFidelite: data['pointsFidelite'] ?? 0,
    );
  }

  // Convertir en Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'sous_categorie': sousCategorie,
      'prix': prix,
      'description': description,
      'ingredients': ingredients,
      'image': image,
      'pointsFidelite': pointsFidelite,
    };
  }

  // Pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'sous_categorie': sousCategorie,
      'prix': prix,
      'description': description,
      'ingredients': ingredients,
      'image': image,
      'pointsFidelite': pointsFidelite,
    };
  }
}