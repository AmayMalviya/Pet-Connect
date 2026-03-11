import 'package:pet_connect_app/models/pet.dart';
import 'package:pet_connect_app/models/user.dart';

class AdoptionRequest {
  final int id;
  final int petId;
  final String requesterId;
  final String shelterOwnerId;
  final String status;
  final Pet pet;
  final User requester;

  AdoptionRequest({
    required this.id,
    required this.petId,
    required this.requesterId,
    required this.shelterOwnerId,
    required this.status,
    required this.pet,
    required this.requester,
  });

  factory AdoptionRequest.fromJson(Map<String, dynamic> json) {
    return AdoptionRequest(
      id: json['id'],
      petId: json['petId'],
      requesterId: json['requesterId'],
      shelterOwnerId: json['shelterOwnerId'],
      status: json['status'],
      pet: Pet.fromJson(json['pet']),
      requester: User.fromJson(json['requester']),
    );
  }
}
