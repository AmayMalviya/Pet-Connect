import 'package:pet_connect_app/models/user.dart';

class Shelter {
  final String id;
  final String phone;
  final String address;
  final String capacity;
  final String website;
  final User user;

  Shelter({
    required this.id,
    required this.phone,
    required this.address,
    required this.capacity,
    required this.website,
    required this.user,
  });

  factory Shelter.fromJson(Map<String, dynamic> json) {
    return Shelter(
      id: json['id'],
      phone: json['phone'],
      address: json['address'],
      capacity: json['capacity'],
      website: json['website'],
      user: User.fromJson(json['user']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'address': address,
      'capacity': capacity,
      'website': website,
      'user': user.toJson(),
    };
  }
}
