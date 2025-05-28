// lib/presentation/screens/menu/dish_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:good_taste/data/models/dish_model.dart';
import 'package:good_taste/data/repositories/dish_repository.dart';
import 'package:good_taste/logic/helpers/favorites_helper.dart';

class DishDetailScreen extends StatelessWidget {
  final Dish dish;

  const DishDetailScreen({super.key, required this.dish});

  @override
  Widget build(BuildContext context) {
    final similarDishes =
        DishRepository()
            .getAllDishes()
            .where((d) => d.subCategory == dish.subCategory && d.id != dish.id)
            .take(3)
            .toList();

    return Scaffold(body: _buildDishDetailView(context, similarDishes));
  }

  Widget _buildDishDetailView(BuildContext context, List<Dish> similarDishes) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            dish.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFF245536),
                child: const Center(
                  child: Icon(
                    Icons.restaurant_menu,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
        ),

        Positioned.fill(child: Container(color: Colors.black.withAlpha(128))),

        SafeArea(
          child: Column(
            children: [
              // Barre supérieure avec le bouton retour et le bouton favoris
              _buildTopBar(context),

              // Titre, évaluation et prix
              _buildDishHeader(),

              // Description du plat
              _buildDishDescription(),

              // Plats similaires en bas
              const Spacer(),
              _buildSimilarDishes(context, similarDishes),
            ],
          ),
        ),
      ],
    );
  }

Widget _buildTopBar(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Bouton retour avec meilleure gestion
        GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),

        // Bouton favoris utilisant FavoritesHelper
        Builder(
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
                  size: 24,
                ),
              ),
            );
          },
        ),
      ],
    ),
  );
}

  Widget _buildDishHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nom du plat
          Text(
            dish.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Évaluation par étoiles
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < 4 ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 22,
              );
            }),
          ),
          const SizedBox(height: 16),

          // Prix
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(128),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${dish.price.toStringAsFixed(0)} DZD",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDishDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dish.description,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          if (dish.ingredients.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              "Ingrédients",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              dish.ingredients,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSimilarDishes(BuildContext context, List<Dish> similarDishes) {
    if (similarDishes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.black.withAlpha(179),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Similaires",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: similarDishes.length,
              itemBuilder: (context, index) {
                final similarDish = similarDishes[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => DishDetailScreen(dish: similarDish),
                      ),
                    );
                  },
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(51),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            similarDish.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFFDB9051),
                                child: const Center(
                                  child: Icon(
                                    Icons.restaurant_menu,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),

                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              color: Colors.black.withAlpha(153),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    similarDish.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    "${similarDish.price.toStringAsFixed(2)} €",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                         Positioned(
  top: 4,
  right: 4,
  child: Builder(
    builder: (context) {
      final isFavorite = FavoritesHelper.isDishFavorite(context, similarDish.id);

      return GestureDetector(
        onTap: () {
          FavoritesHelper.toggleFavorite(context, similarDish.id, similarDish.name);
        },
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.favorite,
            color: isFavorite ? Colors.red : Colors.white,
            size: 16,
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
              },
            ),
          ),
        ],
      ),
    );
  }
}