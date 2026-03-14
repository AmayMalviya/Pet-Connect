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
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: json['price']?.toString() ?? '',
      imageUrl:
          json['image_url']?.toString() ?? json['imageUrl']?.toString() ?? '',
      productUrl: json['url']?.toString() ?? json['productUrl']?.toString(),
      tags: json['tags'] is List ? List<String>.from(json['tags']) : null,
      rating: json['rating'] != null
          ? double.tryParse(json['rating'].toString())
          : null,
      sourceWebsite:
          json['source_website']?.toString() ??
          json['sourceWebsite']?.toString(),
      category: json['category']?.toString(),
      petType: json['pet_type']?.toString() ?? json['petType']?.toString(),
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
