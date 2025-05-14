// lib/presentation/screens/menu/menu_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_taste/data/repositories/dish_repository.dart';
import 'package:good_taste/logic/blocs/menu/menu_bloc.dart';
import 'package:good_taste/presentation/screens/menu/menu_view.dart';


class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    
    
    
    return BlocProvider(
      create: (context) => MenuBloc(
        dishRepository: DishRepository(),
        
      )..add(LoadCategories()),
      child: const MenuView(),
    );
  }
}