// lib/presentation/screens/menu/menu_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_taste/data/models/category_models.dart';
import 'package:good_taste/logic/blocs/menu/menu_bloc.dart';
import 'package:good_taste/presentation/screens/menu/subcategory_dishes_screen.dart';

class MenuView extends StatelessWidget {
  const MenuView({super.key}); 

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MenuBloc, MenuState>(
      builder: (context, state) {
        if (state is MenuLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFBA3400)),
          );
        }
        
        return Column(
                 
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Padding(
              padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: Text(
                'Menu',
                style: TextStyle(
                  color:  Color(0xFFBA3400),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildCategoryTabs(context, state),
            const SizedBox(height: 15),
            Expanded(
              child: _buildSubCategoryList(context, state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryTabs(BuildContext context, MenuState state) {
    List<Category> categories = [];
    Category? selectedCategory;
    
    if (state is CategoriesLoaded) {
      categories = state.categories;
      selectedCategory = state.selectedCategory;
    }
    
    return SizedBox(
      height: 40,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory?.id == category.id;
          
          return GestureDetector(
            onTap: () {
              context.read<MenuBloc>().add(SelectCategory(category));
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const  Color(0xFF245536) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const  Color(0xFF245536),
                  width: 1,
                ),
              ),
              child: Text(
                category.name,
                style: TextStyle(
                  color: isSelected ? Colors.white : const  Color(0xFF245536),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubCategoryList(BuildContext context, MenuState state) {
    List<SubCategory> subCategories = [];
    String? categoryName;
    
    if (state is CategoriesLoaded && state.selectedCategory != null) {
      subCategories = state.selectedCategory!.subCategories;
      categoryName = state.selectedCategory!.name;
    }
    
    if (subCategories.isEmpty) {
      return const Center(
        child: Text(
          'Aucune sous-catégorie disponible',
          style: TextStyle(
            color: Color(0xFFBA3400),
            fontSize: 16,
          ),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: subCategories.length,
      itemBuilder: (context, index) {
        final subCategory = subCategories[index];
        
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SubcategoryDishesScreen(
                  subCategoryName: subCategory.name,
                  categoryName: categoryName ?? '',
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 15),
            height: 100, // Hauteur augmentée
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(51), 
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                fit: StackFit.expand,
                children: [
                 
                  Image.asset(
                    subCategory.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      
                      return Container(
                        color: index % 2 == 0 ? const  Color(0xFF245536) : const Color(0xFF8B4513),
                      );
                    },
                  ),
                  
                  Container(
                    color: Colors.black.withAlpha(102),  
                  ),
                  // Texte de la sous-catégorie
                  Center(
                    child: Text(
                      subCategory.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 3,
                            color: Color.fromARGB(103, 0, 0, 0),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}