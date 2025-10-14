class Pet {
  final String name;
  final String breed;
  final int age;
  String owner_id;

  Pet({
    required this.name,
    required this.breed,
    required this.age,
    required this.owner_id,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      name: json['name'],
      breed: json['breed'],
      age: json['age'],
      owner_id: json['owner_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'breed': breed,
      'age': age,
      'owner_id': owner_id,
    };
  }
}