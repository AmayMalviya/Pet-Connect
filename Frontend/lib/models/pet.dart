class Pet {
  final int? id;
  final String name;
  final String breed;
  final int age;
  String? ownerId;
  String? status;

  Pet({
    this.id,
    required this.name,
    required this.breed,
    required this.age,
    this.ownerId,
    this.status,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'],
      name: json['name'],
      breed: json['breed'],
      age: json['age'],
      ownerId: json['owner_id'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'breed': breed,
      'age': age,
      'owner_id': ownerId,
      'status': status,
    };
  }
}