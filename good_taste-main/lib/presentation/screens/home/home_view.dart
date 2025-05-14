// lib/presentation/screens/home/home_view.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_taste/data/models/dish_model.dart';
import 'package:good_taste/logic/blocs/auth/auth_bloc.dart';
import 'package:good_taste/logic/blocs/home/home_bloc.dart';
import 'package:good_taste/presentation/screens/reservation/reservation_screen.dart';
import 'package:good_taste/presentation/screens/notification/notification_screen.dart';
import 'package:good_taste/presentation/screens/menu/dish_detail_screen.dart';
import 'package:good_taste/logic/helpers/favorites_helper.dart';


class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _buildHeader(context), 
        const SizedBox(height: 20),

        _buildRecommendationTitle(),
        const SizedBox(height: 10),
        SizedBox(height: 240, child: _buildRecommendationContent(screenWidth)),
        const SizedBox(height: 25),

        _buildReservationSection(context),
        const Spacer(),
      ],
    );
  }

 Widget _buildHeader(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final userName =
        authState.user.name.isNotEmpty ? authState.user.name : 'Utilisateur';
    final userProfileImage = authState.user.profileImage;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFBA3400),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            radius: 18,
            child:
                userProfileImage != null && userProfileImage.isNotEmpty
                    ? ClipOval(
                      child: userProfileImage.startsWith('assets/')
                        ? Image.asset(
                            userProfileImage,
                            fit: BoxFit.cover,
                            width: 36,
                            height: 36,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint("Erreur de chargement d'image asset: $error");
                              return const Icon(
                                Icons.person,
                                color: Color(0xFFBA3400),
                              );
                            },
                          )
                        : Image.file(
                            File(userProfileImage),
                            fit: BoxFit.cover,
                            width: 36,
                            height: 36,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint("Erreur de chargement d'image file: $error, path: $userProfileImage");
                              return const Icon(
                                Icons.person,
                                color: Color(0xFFBA3400),
                              );
                            },
                          ),
                    )
                    : const Icon(Icons.person, color: Color(0xFFBA3400)),
                    ),
          
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bonjour',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationTitle() {
    return const Text(
      'Recommandation',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFFBA3400),
      ),
    );
  }

 
Widget _buildRecommendationContent(double screenWidth) {
  return BlocBuilder<HomeBloc, HomeState>(
    builder: (context, state) {
      debugPrint("HomeView: Current state is $state");
      
      if (state is HomeInitial) {
        debugPrint("HomeView: HomeInitial state");
        return const Center(
          child: Text('Chargement initial...'),
        );
      }
      
      if (state is HomeLoading) {
        debugPrint("HomeView: HomeLoading state");
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFFBA3400)),
        );
      } 
      
      if (state is HomeLoaded) {
        debugPrint("HomeView: HomeLoaded state with ${state.recommendedDishes.length} dishes");
        
        if (state.recommendedDishes.isEmpty) {
          return const Center(child: Text('Aucun plat recommandé disponible'));
        }
        
        return ListView.builder(
          itemCount: state.recommendedDishes.length,
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            final dish = state.recommendedDishes[index];
            debugPrint("HomeView: Building dish card for ${dish.name}");
            return _buildDishCard(context, dish, screenWidth);
          },
        );
      } 
      
      if (state is HomeError) {
        debugPrint("HomeView: HomeError state: ${state.message}");
        return Center(child: Text('Erreur: ${state.message}'));
      }
      
      debugPrint("HomeView: Unknown state, showing default message");
      return const Center(child: Text('Aucune recommandation disponible'));
    },
  );
}
  Widget _buildDishCard(BuildContext context, Dish dish, double screenWidth) {
    final cardWidth = screenWidth * 0.75;

    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DishDetailScreen(dish: dish),
            ),
          );
        },
        child: Container(
          width: cardWidth,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: SizedBox(
                  width: cardWidth,
                  height: 220,
                  child: Image.asset(
                    dish.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint("Erreur de chargement d'image: $error");

                      return Container(
                        height: 220,
                        color: const Color(0xFFDB9051),
                        child: const Center(
                          child: Icon(
                            Icons.restaurant,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              Positioned(
                bottom: 20,
                left: 15,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dish.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 3,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dish.price.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 3,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Positioned(
                top: 15,
                right: 15,
                child: GestureDetector(
                  onTap: () {
                    FavoritesHelper.toggleFavorite(context, dish.id, dish.name);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(0, 255, 255, 255),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.favorite,
                      color: FavoritesHelper.isDishFavorite(context, dish.id) ? Colors.red : Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReservationSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.food_bank, color: Color(0xFFBA3400), size: 28),
              SizedBox(width: 10),
              Text(
                "Prêt à réserver ?",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFBA3400),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            "Réservez une table dans notre restaurant et profitez d'une expérience culinaire inoubliable.",
            style: TextStyle(fontSize: 16, color: Color(0xFF245536)),
          ),
          const SizedBox(height: 15),
          _buildReservationButton(context),
        ],
      ),
    );
  }

  Widget _buildReservationButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF245536),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF245536).withAlpha(100),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ReservationScreen(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(50),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.table_restaurant,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Text(
                      'Réserver une table',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}