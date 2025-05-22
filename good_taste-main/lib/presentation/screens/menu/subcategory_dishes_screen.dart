// lib/presentation/screens/menu/subcategory_dishes_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_taste/data/models/dish_model.dart';
import 'package:good_taste/data/repositories/dish_repository.dart';
import 'package:good_taste/logic/blocs/menu/menu_bloc.dart';
import 'package:good_taste/presentation/screens/menu/dish_detail_screen.dart';
import 'package:good_taste/logic/helpers/favorites_helper.dart';

class SubcategoryDishesScreen extends StatelessWidget {
  final String subCategoryName;
  final String categoryName;

  const SubcategoryDishesScreen({
    super.key,
    required this.subCategoryName,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    
    return BlocProvider(
      create: (context) {
        final menuBloc = MenuBloc(
          dishRepository: DishRepository(),
          
        );
       menuBloc.add(LoadSubcategoryDishes(subCategoryName));
        return menuBloc;
      },
      child: _SubcategoryDishesView(
        subCategoryName: subCategoryName,
        categoryName: categoryName,
      ),
    );
  }
}

class _SubcategoryDishesView extends StatelessWidget {
  final String subCategoryName;
  final String categoryName;

  const _SubcategoryDishesView({
    required this.subCategoryName,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9B975),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE9B975),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          categoryName,
          style: const TextStyle(
            color: Color(0xFF245536),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: BlocBuilder<MenuBloc, MenuState>(
          builder: (context, state) {
            if (state is MenuLoading) {
              return const Center(
                child: CircularProgressIndicator(color:  Color(0xFFBA3400)),
              );
            } else if (state is SubcategoryDishesLoaded) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                    child: Text(
                      subCategoryName,
                      style: const TextStyle(
                        color: Color(0xFF245536),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildDishGrid(state.dishes, context),
                  ),
                ],
              );
            } else if (state is MenuError) {
              return Center(
                child: Text(
                  'Erreur: ${state.message}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            return const Center(
              child: Text('Chargement des plats...'),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDishGrid(List<Dish> dishes, BuildContext context) {
    if (dishes.isEmpty) {
      return const Center(
        child: Text(
          'Aucun plat disponible dans cette catÃ©gorie',
          style: TextStyle(
            color: Color(0xFF245536),
            fontSize: 16,
          ),
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8, 
      ),
      itemCount: dishes.length,
      itemBuilder: (context, index) {
        final dish = dishes[index];
        return _buildDishCard(dish, context);
      },
    );
  }

  Widget _buildDishCard(Dish dish, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DishDetailScreen(dish: dish),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              
              Positioned.fill(
                child: Image.asset(
                  dish.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFDB9051),
                      child: const Center(
                        child: Icon(Icons.restaurant_menu, size: 40, color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
             
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(120),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dish.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${dish.price.toStringAsFixed(0)} DZD',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              
              Positioned(
                top: 8,
                right: 8,
                child: Builder(
                  builder: (context) {
                    final isFavorite = FavoritesHelper.isDishFavorite(context, dish.id);
                    
                    return GestureDetector(
                      onTap: () {
                       FavoritesHelper.toggleFavorite(context, dish.id, dish.name);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                         Icons.favorite,
                 color: isFavorite ? Colors.red : Colors.white,
                size: 24
                        ),
                      ),
                    );
                  }
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}