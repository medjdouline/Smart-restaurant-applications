// lib/data/models/category_models.dart
import 'package:equatable/equatable.dart'; 

class Category extends Equatable {
  final String id;
  final String name;
  final List<SubCategory> subCategories;

  const Category({
    required this.id,
    required this.name,
    required this.subCategories,
    
  });

  @override
  List<Object> get props => [id, name, subCategories];
}

class SubCategory extends Equatable {
  final String id;
  final String name;
  final String imageUrl; 

  const SubCategory({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  @override
  List<Object> get props => [id, name, imageUrl];
}