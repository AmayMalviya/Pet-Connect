class Pet {
  final String name;
  final String breed;
  final int age;
  String ownerUid;

  Pet({
    required this.name,
    required this.breed,
    required this.age,
    required this.ownerUid,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      name: json['name'],
      breed: json['breed'],
      age: json['age'],
      ownerUid: json['ownerUid'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'breed': breed,
      'age': age,
      'ownerUid': ownerUid,
    };
  }
}