import 'package:good_taste/data/api/api_client.dart';
import 'package:good_taste/data/models/dish_model.dart';
import 'package:good_taste/data/repositories/dish_repository.dart';

class DishApiService {
  final ApiClient _apiClient;

  DishApiService({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  Future<List<Dish>> getRecommendedDishes() async {
    try {
      final response = await _apiClient.get(
        'client-mobile/recommendations/',
        requiresAuth: true,
      );

      if (!response.success) {
        throw Exception(response.error ?? 'Failed to get recommendations');
      }

      final dishIds = List<String>.from(response.data['dish_ids'] ?? []);
      final dishRepository = DishRepository();
      final allDishes = dishRepository.getAllDishes();

      // Filter dishes based on the IDs from the API
      final recommendedDishes = allDishes.where((dish) => dishIds.contains(dish.id)).toList();

      // If we don't have enough matches, fill with fallback dishes
      if (recommendedDishes.length < dishIds.length) {
        final missingCount = dishIds.length - recommendedDishes.length;
        final fallbackDishes = dishRepository.getRecommendedDishes().take(missingCount).toList();
        recommendedDishes.addAll(fallbackDishes);
      }

      return recommendedDishes;
    } catch (e) {
      // Fallback to local recommendations if API fails
      return DishRepository().getRecommendedDishes();
    }
  }
}