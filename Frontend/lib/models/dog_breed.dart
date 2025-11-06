class DogBreed {
  final String id;
  final String breedName;

  DogBreed({
    required this.id,
    required this.breedName,
  });

  factory DogBreed.fromJson(Map<String, dynamic> json) {
    return DogBreed(
      id: json['id'],
      breedName: json['breed_name'],
    );
  }
}
