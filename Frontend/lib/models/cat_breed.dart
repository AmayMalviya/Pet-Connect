class CatBreed {
  final String id;
  final String breedName;

  CatBreed({
    required this.id,
    required this.breedName,
  });

  factory CatBreed.fromJson(Map<String, dynamic> json) {
    return CatBreed(
      id: json['id'],
      breedName: json['breed_name'],
    );
  }
}
