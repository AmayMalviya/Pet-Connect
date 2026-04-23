class Pet {
  final String? id;
  final String? name;
  final String? breed;
  final String? breedRefId;
  final String? breedTable;
  final int? age;
  final String? animal;
  String? ownerId;
  String? photoUrl;
  final double? weightKg;
  final double? heightCm;
  final String? gender;
  final String? dietType;
  final int? feedingFrequency;
  final List<String>? allergies;
  final List<String>? medicalConditions;
  final String? activityLevel;
  final String? coatType;
  final String? groomingNeeds;
  final String? preferredFoodType;
  final String? description;
  final String? status;
  final String? healthStatus;
  final String? color;
  final bool? isVaccinated;
  final bool? isNeutered;
  final bool? isMicrochipped;
  final bool? goodWithKids;
  final bool? goodWithOtherPets;
  final String? specialNeeds;

  Pet({
    this.id,
    this.name,
    this.breed,
    this.breedRefId,
    this.breedTable,
    this.age,
    this.animal,
    this.ownerId,
    this.photoUrl,
    this.weightKg,
    this.heightCm,
    this.gender,
    this.dietType,
    this.feedingFrequency,
    this.allergies,
    this.medicalConditions,
    this.activityLevel,
    this.coatType,
    this.groomingNeeds,
    this.preferredFoodType,
    this.description,
    this.status,
    this.healthStatus,
    this.color,
    this.isVaccinated,
    this.isNeutered,
    this.isMicrochipped,
    this.goodWithKids,
    this.goodWithOtherPets,
    this.specialNeeds,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id']?.toString(),
      name: json['pet_name'] ?? json['name'] ?? 'Unknown',
      breed: json['breed'] ?? 'Unknown',
      breedRefId: json['breed_ref_id'],
      breedTable: json['breed_table'],
      age: json['age'] ?? 0,
      animal: json['animal'],
      ownerId: json['owner_id']?.toString(),
      photoUrl: json['photo_url'],
      weightKg: json['weight_kg']?.toDouble(),
      heightCm: json['height_cm']?.toDouble(),
      gender: json['gender'],
      dietType: json['diet_type'],
      feedingFrequency: json['feeding_frequency'],
      allergies: json['allergies'] != null ? List<String>.from(json['allergies']) : null,
      medicalConditions: json['medical_conditions'] != null ? List<String>.from(json['medical_conditions']) : null,
      activityLevel: json['activity_level'],
      coatType: json['coat_type'],
      groomingNeeds: json['grooming_needs'],
      preferredFoodType: json['preferred_food_type'],
      description: json['description'],
      status: json['status'],
      healthStatus: json['health_status'],
      color: json['color'],
      isVaccinated: json['is_vaccinated'],
      isNeutered: json['is_neutered'],
      isMicrochipped: json['is_microchipped'],
      goodWithKids: json['good_with_kids'],
      goodWithOtherPets: json['good_with_other_pets'],
      specialNeeds: json['special_needs'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'breed': breed,
      'breed_ref_id': breedRefId,
      'breed_table': breedTable,
      'age': age,
      'animal': animal,
      'owner_id': ownerId,
      'photo_url': photoUrl,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'gender': gender,
      'diet_type': dietType,
      'feeding_frequency': feedingFrequency,
      'allergies': allergies,
      'medical_conditions': medicalConditions,
      'activity_level': activityLevel,
      'coat_type': coatType,
      'grooming_needs': groomingNeeds,
      'preferred_food_type': preferredFoodType,
      'description': description,
      'status': status,
      'health_status': healthStatus,
      'color': color,
      'is_vaccinated': isVaccinated,
      'is_neutered': isNeutered,
      'is_microchipped': isMicrochipped,
      'good_with_kids': goodWithKids,
      'good_with_other_pets': goodWithOtherPets,
      'special_needs': specialNeeds,
    };
  }
}