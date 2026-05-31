import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../models/dish.dart';

class ApiService {
  late Dio _dio;
  String? _token;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  void setToken(String token) {
    _token = token;
  }

  // Auth endpoints
  Future<User> registerUser(
    String email,
    String name,
    String firebaseUid,
  ) async {
    try {
      final response = await _dio.post(
        ApiConfig.register,
        data: {'firebase_uid': firebaseUid, 'email': email, 'name': name},
      );
      return User.fromJson(response.data);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  Future<User> getProfile(String token) async {
    try {
      setToken(token);
      final response = await _dio.get(ApiConfig.profile);
      return User.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }

  Future<Restaurant> createRestaurant(
    String token,
    String name,
    String type,
    String address,
    String phone,
    String email, {
    String weatherCity = '',
    String countryCode = 'IN',
  }) async {
    try {
      setToken(token);
      final response = await _dio.post(
        ApiConfig.createRestaurant,
        data: {
          'name': name,
          'type': type,
          'address': address,
          'phone': phone,
          'email': email,
          'weather_city': weatherCity,
          'country_code': countryCode,
        },
      );
      return Restaurant.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create restaurant: $e');
    }
  }

  Future<Restaurant> getMyRestaurant() async {
    try {
      if (_token == null) {
        throw Exception('Missing authentication token');
      }
      final response = await _dio.get(ApiConfig.getMyRestaurant);
      return Restaurant.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch restaurant: $e');
    }
  }

  Future<Map<String, dynamic>> exportRestaurantData() async {
    try {
      if (_token == null) {
        throw Exception('Missing authentication token');
      }
      final response = await _dio.get(ApiConfig.exportRestaurant);
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Failed to export restaurant data: $e');
    }
  }

  Future<Restaurant> updateRestaurant(
    String name,
    String type,
    String address,
    String phone,
    String email, {
    String weatherCity = '',
    String countryCode = 'IN',
  }) async {
    try {
      if (_token == null) {
        throw Exception('Missing authentication token');
      }
      final response = await _dio.put(
        ApiConfig.getMyRestaurant,
        data: {
          'name': name,
          'type': type,
          'address': address,
          'phone': phone,
          'email': email,
          'weather_city': weatherCity,
          'country_code': countryCode,
        },
      );
      return Restaurant.fromJson(response.data);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final serverMessage = e.response?.data ?? e.message;
      if (statusCode == 405) {
        throw Exception(
          'Backend update route is not active yet. Restart the FastAPI server and try again.',
        );
      }
      throw Exception('Failed to update restaurant: $serverMessage');
    } catch (e) {
      throw Exception('Failed to update restaurant: $e');
    }
  }

  // Menu endpoints
  Future<List<Category>> getCategories(int restaurantId) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/menu/categories/$restaurantId',
      );
      List<dynamic> data = response.data;
      return data.map((item) => Category.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  Future<List<Dish>> getDishes(int restaurantId) async {
    try {
      final response = await _dio.get('${ApiConfig.getDishes}/$restaurantId');
      List<dynamic> data = response.data;
      return data.map((item) => Dish.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to fetch dishes: $e');
    }
  }

  Future<Dish> createDish(
    int restaurantId,
    int categoryId,
    String name,
    double ingredientCost,
    double sellingPrice,
    int servingsPerBatch,
  ) async {
    try {
      final response = await _dio.post(
        ApiConfig.createDish,
        data: {
          'restaurant_id': restaurantId,
          'category_id': categoryId,
          'name': name,
          'ingredient_cost': ingredientCost,
          'selling_price': sellingPrice,
          'servings_per_batch': servingsPerBatch,
          'is_active': true,
        },
      );
      return Dish.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create dish: $e');
    }
  }

  Future<Dish> updateDish(
    int dishId,
    int restaurantId,
    int categoryId,
    String name,
    double ingredientCost,
    double sellingPrice,
    int servingsPerBatch,
  ) async {
    try {
      final response = await _dio.put(
        '${ApiConfig.updateDish}/$dishId',
        data: {
          'restaurant_id': restaurantId,
          'category_id': categoryId,
          'name': name,
          'ingredient_cost': ingredientCost,
          'selling_price': sellingPrice,
          'servings_per_batch': servingsPerBatch,
          'is_active': true,
        },
      );
      return Dish.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update dish: $e');
    }
  }

  Future<void> deleteDish(int dishId) async {
    try {
      await _dio.delete('${ApiConfig.deleteDish}/$dishId');
    } catch (e) {
      throw Exception('Failed to delete dish: $e');
    }
  }

  // Sales endpoints
  Future<Map<String, dynamic>> createDailySales(
    int restaurantId,
    String saleDate,
    double totalRevenue,
    List<Map<String, dynamic>> salesItems,
  ) async {
    try {
      final response = await _dio.post(
        ApiConfig.createDailySales,
        data: {
          'restaurant_id': restaurantId,
          'sale_date': saleDate,
          'total_revenue': totalRevenue,
          'sales_items': salesItems,
        },
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Failed to create daily sales: $e');
    }
  }

  Future<Map<String, dynamic>> uploadSalesCsv(
    String filePath,
    int restaurantId,
  ) async {
    try {
      final filename = filePath.split(RegExp(r'[\\/]+')).last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: filename,
          contentType: _salesUploadContentType(filename),
        ),
      });
      final response = await _dio.post(
        ApiConfig.uploadCsv,
        data: formData,
        queryParameters: {'restaurant_id': restaurantId},
        options: _uploadOptions(),
      );
      return _uploadResult(response.data);
    } on DioException catch (e) {
      final serverMessage = _dioErrorMessage(e);
      throw Exception('Failed to upload CSV: $serverMessage');
    } catch (e) {
      throw Exception('Failed to upload CSV: $e');
    }
  }

  Future<Map<String, dynamic>> uploadSalesCsvBytes(
    Uint8List fileBytes,
    String filename,
    int restaurantId,
  ) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          fileBytes,
          filename: filename,
          contentType: _salesUploadContentType(filename),
        ),
      });
      final response = await _dio.post(
        ApiConfig.uploadCsv,
        data: formData,
        queryParameters: {'restaurant_id': restaurantId},
        options: _uploadOptions(),
      );
      return _uploadResult(response.data);
    } on DioException catch (e) {
      final serverMessage = _dioErrorMessage(e);
      throw Exception('Failed to upload CSV: $serverMessage');
    } catch (e) {
      throw Exception('Failed to upload CSV: $e');
    }
  }

  Options _uploadOptions() {
    return Options(
      sendTimeout: const Duration(seconds: 120),
      receiveTimeout: const Duration(seconds: 120),
    );
  }

  MediaType _salesUploadContentType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.xlsx')) {
      return MediaType.parse(
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    }
    if (lower.endsWith('.xls')) {
      return MediaType.parse('application/vnd.ms-excel');
    }
    return MediaType.parse('text/csv');
  }

  Map<String, dynamic> _uploadResult(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {'message': 'Sales file uploaded successfully'};
  }

  String _dioErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['detail'] != null) {
      return data['detail'].toString();
    }
    if (data != null) return data.toString();
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'The upload took too long. Try a smaller file or check that the backend is running.';
    }
    return e.message ?? 'Upload failed';
  }

  Future<List<dynamic>> getSalesHistory(int restaurantId) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.getSalesHistory}/$restaurantId',
      );
      return response.data as List<dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch sales history: $e');
    }
  }

  // Analytics endpoints
  Future<Map<String, dynamic>> getDemandPrediction(int restaurantId) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.getDemandPrediction}/$restaurantId',
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch demand prediction: $e');
    }
  }

  Future<Map<String, dynamic>> getProfitAnalysis(int restaurantId) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.getProfitAnalysis}/$restaurantId',
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch profit analysis: $e');
    }
  }

  Future<Map<String, dynamic>> getDishClassification(int restaurantId) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.getDishClassification}/$restaurantId',
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch dish classification: $e');
    }
  }

  Future<Map<String, dynamic>> getAiSuggestions(int restaurantId) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.getAiSuggestions}/$restaurantId',
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch AI suggestions: $e');
    }
  }

  Future<Map<String, dynamic>> getSmartDashboard(int restaurantId) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.getSmartDashboard}/$restaurantId',
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Failed to fetch smart dashboard: $e');
    }
  }

  Future<Map<String, dynamic>> trainModels(int restaurantId) async {
    try {
      final response = await _dio.get('${ApiConfig.trainModels}/$restaurantId');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Failed to train models: $e');
    }
  }

  Future<Map<String, dynamic>> refreshWeather(
    int restaurantId,
    String city,
  ) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.refreshWeather}/$restaurantId',
        queryParameters: {'city': city},
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Failed to refresh weather: $e');
    }
  }

  Future<Map<String, dynamic>> refreshCalendar({
    String countryCode = 'IN',
    int? year,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.refreshCalendar,
        queryParameters: {'country_code': countryCode, 'year': ?year},
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Failed to refresh calendar: $e');
    }
  }

  Future<Map<String, dynamic>> intelligenceChat(
    int restaurantId,
    String message, {
    int? dishId,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.intelligenceChat,
        data: {
          'restaurant_id': restaurantId,
          'message': message,
          'dish_id': ?dishId,
        },
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Failed to chat with AI: $e');
    }
  }

  // Waste endpoints
  Future<Map<String, dynamic>> logWaste(
    int restaurantId,
    int dishId,
    int quantityWasted,
    String reason,
    String wasteDate,
  ) async {
    try {
      final response = await _dio.post(
        ApiConfig.logWaste,
        data: {
          'restaurant_id': restaurantId,
          'dish_id': dishId,
          'waste_date': wasteDate,
          'quantity_wasted': quantityWasted,
          'reason': reason,
        },
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Failed to log waste: $e');
    }
  }

  Future<Map<String, dynamic>> getWastePatterns(int restaurantId) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.getWastePatterns}/$restaurantId',
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch waste patterns: $e');
    }
  }
}
