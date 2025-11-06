import 'package:uuid/uuid.dart';

class Animal {
  final String id;
  final String shelterId;
  final String name;
  final String type;
  final String? breed;
  final int? age;
  final String? gender;
  final String? description;
  final String? photoUrl;
  final String status;
  final DateTime createdAt;

  Animal({
    required this.id,
    required this.shelterId,
    required this.name,
    required this.type,
    this.breed,
    this.age,
    this.gender,
    this.description,
    this.photoUrl,
    required this.status,
    required this.createdAt,
  });

  factory Animal.fromJson(Map<String, dynamic> json) {
    return Animal(
      id: json['id'] as String,
      shelterId: json['shelter_id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      breed: json['breed'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      description: json['description'] as String?,
      photoUrl: json['photo_url'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shelter_id': shelterId,
      'name': name,
      'type': type,
      'breed': breed,
      'age': age,
      'gender': gender,
      'description': description,
      'photo_url': photoUrl,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
