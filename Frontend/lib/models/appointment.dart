import 'package:pet_connect_app/models/pet.dart';
import 'package:pet_connect_app/models/user.dart';

class Appointment {
  final int id;
  final int petId;
  final String ownerId;
  final String vetId;
  final DateTime time;
  final String status;
  final Pet pet;
  final User owner;

  Appointment({
    required this.id,
    required this.petId,
    required this.ownerId,
    required this.vetId,
    required this.time,
    required this.status,
    required this.pet,
    required this.owner,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      petId: json['petId'],
      ownerId: json['ownerId'],
      vetId: json['vetId'],
      time: DateTime.parse(json['time']),
      status: json['status'],
      pet: Pet.fromJson(json['pet']),
      owner: User.fromJson(json['owner']),
    );
  }
}
