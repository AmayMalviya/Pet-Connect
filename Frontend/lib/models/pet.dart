class Pet {
  final String? id;
  final String name;
  final String breed;
  final int age;
  final String? type;
  String? ownerId;
  String? photoUrl;

  Pet({
    this.id,
    required this.name,
    required this.breed,
    required this.age,
    this.type,
    this.ownerId,
    this.photoUrl,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id']?.toString(),
      name: json['name'],
      breed: json['breed'],
      age: json['age'],
      type: json['type'],
      ownerId: json['owner_id']?.toString(),
      photoUrl: json['photo_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'breed': breed,
      'age': age,
      'type': type,
      'owner_id': ownerId,
      'photo_url': photoUrl,
    };
  }
}