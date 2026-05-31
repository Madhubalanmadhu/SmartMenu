class Category {
  final int id;
  final int restaurantId;
  final String name;
  final String type;

  Category({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.type,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      restaurantId: json['restaurant_id'],
      name: json['name'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'name': name,
      'type': type,
    };
  }
}

class Dish {
  final int id;
  final int restaurantId;
  final int categoryId;
  final String name;
  final double ingredientCost;
  final double sellingPrice;
  final int servingsPerBatch;
  final bool isActive;

  Dish({
    required this.id,
    required this.restaurantId,
    required this.categoryId,
    required this.name,
    required this.ingredientCost,
    required this.sellingPrice,
    required this.servingsPerBatch,
    required this.isActive,
  });

  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      id: json['id'],
      restaurantId: json['restaurant_id'],
      categoryId: json['category_id'],
      name: json['name'],
      ingredientCost: (json['ingredient_cost'] as num).toDouble(),
      sellingPrice: (json['selling_price'] as num).toDouble(),
      servingsPerBatch: (json['servings_per_batch'] as num?)?.toInt() ?? 1,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'category_id': categoryId,
      'name': name,
      'ingredient_cost': ingredientCost,
      'selling_price': sellingPrice,
      'servings_per_batch': servingsPerBatch,
      'is_active': isActive,
    };
  }

  double get unitIngredientCost =>
      ingredientCost / (servingsPerBatch <= 0 ? 1 : servingsPerBatch);
}
