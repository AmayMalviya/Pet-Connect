class Product {
  final String id;
  final String name;
  final String price;
  final String imageUrl;
  final String? productUrl;
  final List<String>? tags;
  final double? rating;
  final String? sourceWebsite;
  final String? category; // For pet-based filtering
  final String? petType; // 'dog', 'cat', 'bird', etc.
  final List<String>? species;
  final List<String>? breedCompatibility;
  final String? ageRange;
  final String? weightRange;
  final List<String>? medicalRestrictions;
  final List<String>? allergyWarnings;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.productUrl,
    this.tags,
    this.rating,
    this.sourceWebsite,
    this.category,
    this.petType,
    this.species,
    this.breedCompatibility,
    this.ageRange,
    this.weightRange,
    this.medicalRestrictions,
    this.allergyWarnings,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      price: map['price']?.toString() ?? '',
      imageUrl:
          map['image_url']?.toString() ?? map['imageUrl']?.toString() ?? '',
      productUrl: map['product_url']?.toString() ?? map['url']?.toString() ?? map['productUrl']?.toString(),
      tags: map['tags'] is List ? List<String>.from(map['tags']) : null,
      rating: map['rating'] != null
          ? double.tryParse(map['rating'].toString())
          : null,
      sourceWebsite:
          map['source_website']?.toString() ??
          map['sourceWebsite']?.toString(),
      category: map['category']?.toString(),
      petType: map['pet_type']?.toString() ?? map['petType']?.toString(),
      species: map['species'] is List ? List<String>.from(map['species']) : null,
      breedCompatibility: map['breed_compatibility'] is List ? List<String>.from(map['breed_compatibility']) : null,
      ageRange: map['age_range']?.toString(),
      weightRange: map['weight_range']?.toString(),
      medicalRestrictions: map['medical_restrictions'] is List ? List<String>.from(map['medical_restrictions']) : null,
      allergyWarnings: map['allergy_warnings'] is List ? List<String>.from(map['allergy_warnings']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'image_url': imageUrl,
      'url': productUrl,
      'tags': tags,
      'rating': rating,
      'source_website': sourceWebsite,
      'category': category,
      'pet_type': petType,
      'species': species,
      'breed_compatibility': breedCompatibility,
      'age_range': ageRange,
      'weight_range': weightRange,
      'medical_restrictions': medicalRestrictions,
      'allergy_warnings': allergyWarnings,
    };
  }

  /// Get relevant categories based on pet type
  static Map<String, List<String>> getPetCategories() {
    return {
      'dog': [
        'food',
        'toys',
        'leash',
        'grooming kit',
        'beds',
        'treats',
        'bowls',
        'collars',
      ],
      'cat': [
        'food',
        'litter',
        'scratchers',
        'toys',
        'beds',
        'treats',
        'bowls',
        'litter box',
      ],
      'bird': [
        'food',
        'cage',
        'toys',
        'perches',
        'treats',
        'sand bath',
        'mirrors',
      ],
      'rabbit': [
        'food',
        'hay',
        'toys',
        'bedding',
        'tunnels',
        'treats',
        'bowls',
      ],
      'hamster': [
        'food',
        'bedding',
        'wheel',
        'toys',
        'treats',
        'hidehouse',
        'bowls',
      ],
    };
  }

  /// Get default categories for a pet type
  static List<String> getCategoriesForPet(String petType) {
    return getPetCategories()[petType.toLowerCase()] ?? [];
  }
}
