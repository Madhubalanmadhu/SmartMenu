import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/dish.dart';

class MenuProvider extends ChangeNotifier {
  late final ApiService _apiService;

  List<Dish> dishes = [];
  List<Category> categories = [];
  bool isLoading = false;
  String? error;

  MenuProvider(this._apiService);

  Future<void> loadDishes(int restaurantId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final loadedDishes = await _apiService.getDishes(restaurantId);
      final loadedCategories = await _apiService.getCategories(restaurantId);
      dishes = loadedDishes;
      categories = loadedCategories;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = 'Failed to load dishes: $e';
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addDish(
    int restaurantId,
    int categoryId,
    String name,
    double cost,
    double price,
    int servingsPerBatch,
  ) async {
    error = null;
    try {
      final newDish = await _apiService.createDish(
        restaurantId,
        categoryId,
        name,
        cost,
        price,
        servingsPerBatch,
      );
      dishes.add(newDish);
      notifyListeners();
    } catch (e) {
      error = 'Failed to add dish: $e';
      notifyListeners();
    }
  }

  Future<void> updateDish(
    int dishId,
    int restaurantId,
    int categoryId,
    String name,
    double cost,
    double price,
    int servingsPerBatch,
  ) async {
    error = null;
    try {
      final updatedDish = await _apiService.updateDish(
        dishId,
        restaurantId,
        categoryId,
        name,
        cost,
        price,
        servingsPerBatch,
      );
      final index = dishes.indexWhere((dish) => dish.id == dishId);
      if (index == -1) {
        dishes.add(updatedDish);
      } else {
        dishes[index] = updatedDish;
      }
      notifyListeners();
    } catch (e) {
      error = 'Failed to update dish: $e';
      notifyListeners();
    }
  }

  Future<void> deleteDish(int dishId) async {
    error = null;
    try {
      await _apiService.deleteDish(dishId);
      dishes.removeWhere((dish) => dish.id == dishId);
      notifyListeners();
    } catch (e) {
      error = 'Failed to delete dish: $e';
      notifyListeners();
    }
  }

  void clearError() {
    error = null;
    notifyListeners();
  }
}
