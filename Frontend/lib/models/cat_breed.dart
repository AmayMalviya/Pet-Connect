class CatBreed {
  final int breedId;
  final String breedName;

  CatBreed({
    required this.breedId,
    required this.breedName,
  });

  factory CatBreed.fromJson(Map<String, dynamic> json) {
    return CatBreed(
      breedId: json['breed_id'],
      breedName: json['breed_name'],
    );
  }
}
