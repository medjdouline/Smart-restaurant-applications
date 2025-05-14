// lib/presentation/screens/main_navigation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_taste/logic/blocs/navigation/navigation_bloc.dart';
import 'package:good_taste/logic/blocs/home/home_bloc.dart';
import 'package:good_taste/data/repositories/dish_repository.dart';
import 'package:good_taste/presentation/screens/home/home_view.dart';
import 'package:good_taste/presentation/screens/menu/menu_screen.dart';
import 'package:good_taste/presentation/screens/favorites/favorites_screen.dart';
import 'package:good_taste/presentation/screens/profile/profile_screen.dart';
import 'package:good_taste/logic/blocs/menu/menu_bloc.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => NavigationBloc(),
        ),
        
        
        
        BlocProvider(
          create: (context) => HomeBloc(
            dishRepository: DishRepository(),
            
          )..add(LoadRecommendations()),
        ),
        BlocProvider(
          create: (context) => MenuBloc(
            dishRepository: DishRepository(),
           
          )..add(LoadCategories()),
        ),

      ],
      child: const MainNavigationView(),
    );
  }
}

class MainNavigationView extends StatelessWidget {
  const MainNavigationView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFE9B975),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Expanded(
                    child: IndexedStack(
                      index: state.tabIndex,
                      children: const [
                        HomeView(),
                        MenuScreen(),
                        FavoritesScreen(),
                        ProfileScreen(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildBottomNavigationBar(context, state.tabIndex),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, int currentIndex) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFBA3400),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavBarItem(context, Icons.home, 0, currentIndex),
          _buildNavBarItem(context, Icons.restaurant_menu, 1, currentIndex),
          _buildNavBarItem(context, Icons.favorite, 2, currentIndex),
          _buildNavBarItem(context, Icons.person, 3, currentIndex),
        ],
      ),
    );
  }

  Widget _buildNavBarItem(
    BuildContext context,
    IconData icon,
    int index,
    int currentIndex,
  ) {
    final bool isActive = index == currentIndex;

    return GestureDetector(
      onTap: () {
        context.read<NavigationBloc>().add(TabChanged(index));
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color:
              isActive ? const Color(0xFFBA3400) : Colors.white.withAlpha(200),
          size: 22,
        ),
      ),
    );
  }
}