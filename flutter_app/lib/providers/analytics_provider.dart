import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  late final ApiService _apiService;

  Map<String, dynamic>? demandData;
  Map<String, dynamic>? profitData;
  Map<String, dynamic>? classificationData;
  Map<String, dynamic>? suggestionsData;
  Map<String, dynamic>? smartDashboardData;
  Map<String, dynamic>? trainingData;

  bool isLoading = false;
  String? error;
  bool isChatLoading = false;
  bool isTraining = false;

  AnalyticsProvider(this._apiService);

  Future<void> loadAnalytics(int restaurantId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    final failures = <String>[];

    demandData = await _loadSection(
      'demand',
      failures,
      () => _apiService.getDemandPrediction(restaurantId),
    );
    profitData = await _loadSection(
      'profit',
      failures,
      () => _apiService.getProfitAnalysis(restaurantId),
    );
    classificationData = await _loadSection(
      'classification',
      failures,
      () => _apiService.getDishClassification(restaurantId),
    );
    suggestionsData =
        await _loadSection(
          'suggestions',
          failures,
          () => _apiService.getAiSuggestions(restaurantId),
        ) ??
        {'suggestions': []};
    smartDashboardData = await _loadSection(
      'smart dashboard',
      failures,
      () => _apiService.getSmartDashboard(restaurantId),
    );
    _applySmartDashboardFallbacks();

    final loadedAny =
        demandData != null ||
        profitData != null ||
        classificationData != null ||
        smartDashboardData != null;
    if (!loadedAny) {
      error = 'Failed to load analytics: ${failures.join(', ')}';
    }

    isLoading = false;
    notifyListeners();
  }

  void _applySmartDashboardFallbacks() {
    final dashboard = smartDashboardData;
    if (dashboard == null) return;

    final forecasts = (dashboard['dish_forecasts'] as List? ?? [])
        .whereType<Map>()
        .toList();
    if (forecasts.isEmpty) return;

    demandData ??= {
      'predictions': {
        for (final row in forecasts)
          if (row['dish_id'] != null)
            row['dish_id'].toString(): {
              'name': row['name']?.toString() ?? 'Dish',
              'next_day': (row['expected_quantity'] as num?)?.toInt() ?? 0,
              'next_week':
                  (row['next_week_quantity'] as num?)?.toInt() ??
                  (row['expected_quantity'] as num?)?.toInt() ??
                  0,
              'confidence': row['confidence']?.toString() ?? 'smart_dashboard',
              'method': row['model']?.toString() ?? 'smart_dashboard',
            },
      },
    };

    profitData ??= {
      'analysis': forecasts.map((row) {
        final marginPercent = (row['margin'] as num?)?.toDouble();
        final margin = marginPercent == null ? null : marginPercent / 100;
        final revenue = (row['expected_sales'] as num?)?.toDouble() ?? 0;
        final profit = margin == null ? null : revenue * margin;
        return {
          'dish_id': row['dish_id'],
          'name': row['name']?.toString() ?? 'Dish',
          'total_sold': (row['expected_quantity'] as num?)?.toInt() ?? 0,
          'total_revenue': revenue,
          'profit': profit,
          'total_profit': profit,
          'margin': margin,
          'menu_margin': margin,
        };
      }).toList(),
    };

    classificationData ??= {
      'classifications': {
        for (final row in forecasts)
          if (row['dish_id'] != null)
            row['dish_id'].toString(): {
              'name': row['name']?.toString() ?? 'Dish',
              'total_sold': (row['expected_quantity'] as num?)?.toInt() ?? 0,
              'margin': (row['margin'] as num?) == null
                  ? null
                  : (row['margin'] as num).toDouble() / 100,
              'demand_level': _demandLevelFromForecast(row),
            },
      },
    };
  }

  String _demandLevelFromForecast(Map<dynamic, dynamic> row) {
    final quantity = (row['expected_quantity'] as num?)?.toInt() ?? 0;
    final risk = row['waste_risk']?.toString();
    if (risk == 'high') return 'watch';
    if (quantity >= 40) return 'high';
    if (quantity >= 15) return 'medium';
    if (quantity > 0) return 'low';
    return 'new';
  }

  Future<Map<String, dynamic>?> _loadSection(
    String label,
    List<String> failures,
    Future<Map<String, dynamic>> Function() loader,
  ) async {
    try {
      return await loader();
    } catch (e) {
      failures.add('$label: $e');
      return null;
    }
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  Future<void> refreshWeather(int restaurantId, String city) async {
    try {
      await _apiService.refreshWeather(restaurantId, city);
      smartDashboardData = await _apiService.getSmartDashboard(restaurantId);
      _applySmartDashboardFallbacks();
      notifyListeners();
    } catch (e) {
      error = 'Failed to refresh weather: $e';
      notifyListeners();
    }
  }

  Future<void> refreshCalendar(int restaurantId) async {
    try {
      await _apiService.refreshCalendar();
      smartDashboardData = await _apiService.getSmartDashboard(restaurantId);
      _applySmartDashboardFallbacks();
      notifyListeners();
    } catch (e) {
      error = 'Failed to refresh calendar: $e';
      notifyListeners();
    }
  }

  Future<void> trainModels(int restaurantId) async {
    isTraining = true;
    error = null;
    notifyListeners();

    try {
      trainingData = await _apiService.trainModels(restaurantId);
      await loadAnalytics(restaurantId);
    } catch (e) {
      error = 'Failed to train models: $e';
      notifyListeners();
    } finally {
      isTraining = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> chat(
    int restaurantId,
    String message, {
    int? dishId,
  }) async {
    isChatLoading = true;
    notifyListeners();
    try {
      return await _apiService.intelligenceChat(
        restaurantId,
        message,
        dishId: dishId,
      );
    } finally {
      isChatLoading = false;
      notifyListeners();
    }
  }
}
