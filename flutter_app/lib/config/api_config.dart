class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  // Auth endpoints
  static const String register = '/auth/register';
  static const String profile = '/auth/profile';
  static const String createRestaurant = '/auth/restaurant';
  static const String getMyRestaurant = '/auth/restaurant';
  static const String exportRestaurant = '/auth/restaurant/export';

  // Menu endpoints
  static const String getCategories = '/menu/categories';
  static const String getDishes = '/menu/dishes';
  static const String createDish = '/menu/dishes';
  static const String updateDish = '/menu/dishes';
  static const String deleteDish = '/menu/dishes';

  // Sales endpoints
  static const String createDailySales = '/sales/daily';
  static const String uploadCsv = '/sales/upload-csv';
  static const String getSalesHistory = '/sales/history';

  // Analytics endpoints
  static const String getDemandPrediction = '/analytics/demand';
  static const String getProfitAnalysis = '/analytics/profit';
  static const String getDishClassification = '/analytics/classify';
  static const String getAiSuggestions = '/analytics/suggestions';

  // AI intelligence endpoints
  static const String getSmartDashboard = '/intelligence/dashboard';
  static const String trainModels = '/intelligence/train';
  static const String refreshWeather = '/intelligence/weather/refresh';
  static const String refreshCalendar = '/intelligence/calendar/refresh';
  static const String inventoryRecipes = '/intelligence/inventory/recipes';
  static const String intelligenceChat = '/intelligence/chat';

  // Waste endpoints
  static const String logWaste = '/waste';
  static const String getWastePatterns = '/waste/patterns';
}
