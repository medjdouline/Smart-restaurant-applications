// lib/logic/blocs/menu/menu_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:good_taste/data/models/dish_model.dart';
import 'package:good_taste/data/models/category_models.dart';
import 'package:good_taste/data/repositories/dish_repository.dart';



part 'menu_event.dart';
part 'menu_state.dart';

class MenuBloc extends Bloc<MenuEvent, MenuState> {
  final DishRepository dishRepository;

 

  MenuBloc({
    required this.dishRepository,
  
  }) : super(MenuInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<SelectCategory>(_onSelectCategory);
    on<ResetSelection>(_onResetSelection);
   on<LoadSubcategoryDishes>(_onLoadSubcategoryDishes);
    
    
    
     
    
  }

  void _onLoadCategories(
    LoadCategories event,
    Emitter<MenuState> emit,
  ) {
    emit(MenuLoading());
    try {
      final categories = dishRepository.getCategories();
      
      emit(CategoriesLoaded(
        categories: categories,
        selectedCategory: categories.isNotEmpty ? categories[0] : null,
        dishes: [], 
      ));
    } catch (e) {
      emit(MenuError(message: e.toString()));
    }
  }

  void _onSelectCategory(
    SelectCategory event,
    Emitter<MenuState> emit,
  ) {
    if (state is CategoriesLoaded) {
      final currentState = state as CategoriesLoaded;
      final selectedCategory = event.category;
      
      emit(CategoriesLoaded(
        categories: currentState.categories,
        selectedCategory: selectedCategory,
        dishes: [], 
      ));
    }
  }

  void _onResetSelection(
    ResetSelection event,
    Emitter<MenuState> emit,
  ) {
    if (state is CategoriesLoaded) {
      final currentState = state as CategoriesLoaded;
      
      emit(CategoriesLoaded(
        categories: currentState.categories,
        selectedCategory: null,
        dishes: [],
      ));
    }
  }


  void _onLoadSubcategoryDishes(
    LoadSubcategoryDishes event,
    Emitter<MenuState> emit,
  ) {
    emit(MenuLoading());
    try {
      final dishes = dishRepository.getDishesBySubCategory(event.subCategoryName);
      emit(SubcategoryDishesLoaded(
        subCategoryName: event.subCategoryName,
        dishes: dishes,
      ));
    } catch (e) {
      emit(MenuError(message: e.toString()));
    }
  }
}

