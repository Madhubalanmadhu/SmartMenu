import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class RestaurantProvider extends ChangeNotifier {
  final ApiService _apiService;
  Restaurant? restaurant;
  bool isLoading = false;
  String? error;

  RestaurantProvider(this._apiService);

  int? get restaurantId => restaurant?.id;
  String? get restaurantName => restaurant?.name;

  Future<void> loadRestaurant() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      restaurant = await _apiService.getMyRestaurant();
    } catch (e) {
      error = 'Failed to load restaurant: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setRestaurant(Restaurant value) {
    restaurant = value;
    notifyListeners();
  }

  Future<void> updateRestaurant(
    String name,
    String type,
    String address,
    String phone,
    String email, {
    String weatherCity = '',
    String countryCode = 'IN',
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      restaurant = await _apiService.updateRestaurant(
        name,
        type,
        address,
        phone,
        email,
        weatherCity: weatherCity,
        countryCode: countryCode,
      );
    } catch (e) {
      error = 'Failed to update restaurant: $e';
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    error = null;
    notifyListeners();
  }
}
