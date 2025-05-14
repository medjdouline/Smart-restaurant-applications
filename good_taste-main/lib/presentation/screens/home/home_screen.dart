// lib/presentation/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_taste/data/repositories/dish_repository.dart';
import 'package:good_taste/logic/blocs/home/home_bloc.dart';
import 'package:good_taste/presentation/screens/home/home_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeBloc>(
      create: (context) {
        final homeBloc = HomeBloc(
          dishRepository: DishRepository(),
        );
        
        homeBloc.add(LoadRecommendations());
        return homeBloc;
      },
      child: const HomeView(),
    );
  }
}