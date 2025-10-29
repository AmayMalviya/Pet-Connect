class Pet {
  final String? id;
  final String name;
  final String breed;
  final int? breedId;
  final int age;
  final String? animal;
  String? ownerId;
  String? photoUrl;

  Pet({
    this.id,
    required this.name,
    required this.breed,
    this.breedId,
    required this.age,
    this.animal,
    this.ownerId,
    this.photoUrl,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id']?.toString(),
      name: json['name'],
      breed: json['breed'],
      breedId: json['breed_id'],
      age: json['age'],
      animal: json['animal'],
      ownerId: json['owner_id']?.toString(),
      photoUrl: json['photo_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'breed': breed,
      'breed_id': breedId,
      'age': age,
      'animal': animal,
      'owner_id': ownerId,
      'photo_url': photoUrl,
    };
  }
}
