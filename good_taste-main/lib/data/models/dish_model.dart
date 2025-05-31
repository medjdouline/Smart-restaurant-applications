// lib/data/models/dish_model.dart
class Dish {
  final String id;
  final String name;
  final String imageUrl;
  final String description;
  final double price;
  final bool isFavorite;
  final String category;        
  final String subCategory;     
  final String ingredients;    

  Dish({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.price,
    this.isFavorite = false,
    required this.category,
    required this.subCategory,
    this.ingredients = '',
  });

  
  Dish copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? description,
    double? price,
    bool? isFavorite,
    String? category,
    String? subCategory,
    String? ingredients,
  }) {
    return Dish(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      price: price ?? this.price,
      isFavorite: isFavorite ?? this.isFavorite,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      ingredients: ingredients ?? this.ingredients,
    );
  }
  factory Dish.fromJson(Map<String, dynamic> json) {
  return Dish(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    imageUrl: json['imageUrl'] ?? 'assets/images/default_dish.jpg',
    description: json['description'] ?? '',
    price: (json['price'] ?? 0).toDouble(),
    isFavorite: json['isFavorite'] ?? false,
    category: json['category'] ?? '',
    subCategory: json['subCategory'] ?? '',
    ingredients: json['ingredients'] ?? '',
  );
}
}