// lib/presentation/screens/favorites/favorites_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_taste/data/models/dish_model.dart';
import 'package:good_taste/logic/blocs/favorites/favorites_bloc.dart';
import 'package:good_taste/logic/helpers/favorites_helper.dart';
import 'package:good_taste/presentation/screens/menu/dish_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9B975),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE9B975),
        elevation: 0,
        title: const Text(
          'Favoris',
          style: TextStyle(
            color: Color(0xFFBA3400),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: BlocBuilder<FavoritesBloc, FavoritesState>(
        builder: (context, state) {
          if (state is FavoritesLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFBA3400)),
            );
          } else if (state is FavoritesLoaded) {
            if (state.favoriteDishes.isEmpty) {
              return _buildEmptyState();
            }
            return _buildFavoritesList(state.favoriteDishes, context);
          } else if (state is FavoritesError) {
            return Center(
              child: Text(
                'Erreur: ${state.message}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          return const Center(
            child: Text('Chargement des favoris...'),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: const Color(0xFFBA3400).withAlpha(179), 
          ),
          const SizedBox(height: 16),
          const Text(
            'Vous n\'avez pas encore ajouté de favoris',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF245536),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Explorez le menu et ajoutez des plats\nà vos favoris',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF245536),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList(List<Dish> dishes, BuildContext context) {
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
        return _buildFavoriteCard(dish, context);
      },
    );
  }

  Widget _buildFavoriteCard(Dish dish, BuildContext context) {
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
              // Image du plat
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
              
              // Overlay de texte
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
                        '${dish.price.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Icône de favoris
              Positioned(
                top: 8,
                right: 8,
                child: Builder(
                  builder: (context) {
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
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.red,
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