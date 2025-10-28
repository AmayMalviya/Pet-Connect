class Pet {
  final String? id; // Changed to String since it's a UUID
  final String name;
  final String breed;
  final int age;
  String? ownerId;

  Pet({
    this.id,
    required this.name,
    required this.breed,
    required this.age,
    this.ownerId,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id']?.toString(), // Convert UUID to String
      name: json['name'],
      breed: json['breed'],
      age: json['age'],
      ownerId: json['owner_id']?.toString(), // Convert UUID to String
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'breed': breed,
      'age': age,
      'owner_id': ownerId,
    };
  }
}