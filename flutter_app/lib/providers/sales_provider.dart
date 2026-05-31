import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/dish.dart';

class SalesProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<dynamic> salesHistory = [];
  List<Dish> dishes = [];
  Set<String> recentlyUploadedDates = {};
  bool isLoading = false;
  String? error;
  String? message;

  SalesProvider(this._apiService);

  Future<void> loadDishes(int restaurantId) async {
    try {
      dishes = await _apiService.getDishes(restaurantId);
      notifyListeners();
    } catch (e) {
      error = 'Failed to load dishes: $e';
      notifyListeners();
    }
  }

  Future<void> loadSales(int restaurantId, {bool clearStatus = true}) async {
    isLoading = true;
    error = null;
    if (clearStatus) {
      message = null;
      recentlyUploadedDates = {};
    }
    notifyListeners();

    try {
      salesHistory = await _apiService.getSalesHistory(restaurantId);
      await loadDishes(restaurantId);
    } catch (e) {
      error = 'Failed to load sales history: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createSale(
    int restaurantId,
    String saleDate,
    double totalRevenue,
    List<Map<String, dynamic>> salesItems, {
    List<Map<String, dynamic>>? wasteItems,
  }) async {
    isLoading = true;
    error = null;
    message = null;
    notifyListeners();

    try {
      await _apiService.createDailySales(
        restaurantId,
        saleDate,
        totalRevenue,
        salesItems,
      );

      // If waste items provided, log them
      if (wasteItems != null && wasteItems.isNotEmpty) {
        for (var waste in wasteItems) {
          await _apiService.logWaste(
            restaurantId,
            waste['dish_id'] as int,
            waste['quantity_wasted'] as int,
            waste['reason'] as String,
            saleDate,
          );
        }
      }

      message = 'Sale recorded successfully';
      await loadSales(restaurantId);
    } catch (e) {
      error = 'Failed to create sale: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadSalesCsv(String filePath, int restaurantId) async {
    isLoading = true;
    error = null;
    message = null;
    notifyListeners();

    try {
      final result = await _apiService.uploadSalesCsv(filePath, restaurantId);
      await loadSales(restaurantId, clearStatus: false);
      _setUploadResult(result);
    } catch (e) {
      error = _cleanUploadError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadSalesCsvBytes(
    Uint8List fileBytes,
    String filename,
    int restaurantId,
  ) async {
    isLoading = true;
    error = null;
    message = null;
    notifyListeners();

    try {
      final result = await _apiService.uploadSalesCsvBytes(
        fileBytes,
        filename,
        restaurantId,
      );
      await loadSales(restaurantId, clearStatus: false);
      _setUploadResult(result);
    } catch (e) {
      error = _cleanUploadError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    error = null;
    message = null;
    recentlyUploadedDates = {};
    notifyListeners();
  }

  void _setUploadResult(Map<String, dynamic> result) {
    message =
        result['message']?.toString() ?? 'Sales file uploaded successfully';
    final dates = result['touched_dates'];
    recentlyUploadedDates = dates is List
        ? dates.map((date) => date.toString()).toSet()
        : {};
  }

  String _cleanUploadError(Object error) {
    var message = error.toString();
    message = message.replaceFirst('Exception: ', '');
    message = message.replaceFirst('Failed to upload CSV: ', '');
    return message;
  }
}
