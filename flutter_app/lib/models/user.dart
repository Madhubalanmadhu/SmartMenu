class User {
  final int id;
  final String firebaseUid;
  final String email;
  final String name;

  User({
    required this.id,
    required this.firebaseUid,
    required this.email,
    required this.name,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firebaseUid: json['firebase_uid'],
      email: json['email'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebase_uid': firebaseUid,
      'email': email,
      'name': name,
    };
  }
}

class Restaurant {
  final int id;
  final int userId;
  final String name;
  final String type;
  final String address;
  final String phone;
  final String email;
  final String weatherCity;
  final String countryCode;

  Restaurant({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.address,
    required this.phone,
    required this.email,
    required this.weatherCity,
    required this.countryCode,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      type: json['type'],
      address: json['address'],
      phone: json['phone'],
      email: json['email'] ?? '',
      weatherCity: json['weather_city'] ?? '',
      countryCode: json['country_code'] ?? 'IN',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'type': type,
      'address': address,
      'phone': phone,
      'email': email,
      'weather_city': weatherCity,
      'country_code': countryCode,
    };
  }
}
