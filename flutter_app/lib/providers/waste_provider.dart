import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/dish.dart';

class WasteProvider extends ChangeNotifier {
  final ApiService _apiService;

  Map<String, dynamic>? wastePatterns;
  List<Dish> dishes = [];
  bool isLoading = false;
  String? error;
  String? message;

  WasteProvider(this._apiService);

  Future<void> loadDishes(int restaurantId) async {
    try {
      dishes = await _apiService.getDishes(restaurantId);
      notifyListeners();
    } catch (e) {
      error = 'Failed to load dishes: $e';
      notifyListeners();
    }
  }

  Future<void> loadWaste(int restaurantId) async {
    isLoading = true;
    error = null;
    message = null;
    notifyListeners();

    try {
      wastePatterns = await _apiService.getWastePatterns(restaurantId);
      await loadDishes(restaurantId);
    } catch (e) {
      error = 'Failed to load waste patterns: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logWaste(
    int restaurantId,
    int dishId,
    int quantityWasted,
    String reason,
    String wasteDate,
  ) async {
    isLoading = true;
    error = null;
    message = null;
    notifyListeners();

    try {
      await _apiService.logWaste(
        restaurantId,
        dishId,
        quantityWasted,
        reason,
        wasteDate,
      );
      message = 'Waste logged successfully';
      await loadWaste(restaurantId);
    } catch (e) {
      error = 'Failed to log waste: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    error = null;
    message = null;
    notifyListeners();
  }
}
