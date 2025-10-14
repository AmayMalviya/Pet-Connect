import 'package:pet_connect_app/models/user.dart';

class Vet {
  final String id;
  final String phone;
  final String address;
  final String specialization;
  final int yearsOfExperience;
  final User user;

  Vet({
    required this.id,
    required this.phone,
    required this.address,
    required this.specialization,
    required this.yearsOfExperience,
    required this.user,
  });

  factory Vet.fromJson(Map<String, dynamic> json) {
    return Vet(
      id: json['id'],
      phone: json['phone'],
      address: json['address'],
      specialization: json['specialization'],
      yearsOfExperience: json['yearsOfExperience'],
      user: User.fromJson(json['user']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'address': address,
      'specialization': specialization,
      'yearsOfExperience': yearsOfExperience,
      'user': user.toJson(),
    };
  }
}
