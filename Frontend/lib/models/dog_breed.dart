class DogBreed {
  final int breedId;
  final String breedName;

  DogBreed({
    required this.breedId,
    required this.breedName,
  });

  factory DogBreed.fromJson(Map<String, dynamic> json) {
    return DogBreed(
      breedId: json['breed_id'],
      breedName: json['breed_name'],
    );
  }
}
