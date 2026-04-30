class Product {
  final String id;
  final String name;
  final String price;
  final String imageUrl;
  final String? productUrl;
  final double? rating;
  final String? category;
  final String? petType;
  final List<String>? tags;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl = '',
    this.productUrl,
    this.rating,
    this.category,
    this.petType,
    this.tags,
  });

  /// Flexible parser that accepts different key naming conventions
  factory Product.fromMap(Map<String, dynamic> map) {
    String id = (map['id'] ?? map['product_id'] ?? '')?.toString() ?? '';
    String name = (map['name'] ?? map['title'] ?? '')?.toString() ?? '';
    String price = (map['price'] ?? map['amount'] ?? '')?.toString() ?? '';

    String imageUrl = '';
    if (map.containsKey('image_url')) imageUrl = (map['image_url'] ?? '')?.toString() ?? '';
    else if (map.containsKey('image')) imageUrl = (map['image'] ?? '')?.toString() ?? '';
    else if (map.containsKey('imageUrl')) imageUrl = (map['imageUrl'] ?? '')?.toString() ?? '';

    String? productUrl;
    if (map.containsKey('product_url')) productUrl = (map['product_url'] ?? '')?.toString();
    else if (map.containsKey('url')) productUrl = (map['url'] ?? '')?.toString();
    else if (map.containsKey('productUrl')) productUrl = (map['productUrl'] ?? '')?.toString();

    double? rating;
    final rawRating = map['rating'] ?? map['rating_score'];
    if (rawRating != null) {
      try {
        rating = rawRating is num ? rawRating.toDouble() : double.parse(rawRating.toString());
      } catch (_) {
        rating = null;
      }
    }

    final category = (map['category'] ?? map['cat'] ?? map['type'])?.toString();
    final petType = (map['pet_type'] ?? map['petType'] ?? map['pet'])?.toString();

    List<String>? tags;
    if (map['tags'] != null) {
      try {
        if (map['tags'] is List) tags = List<String>.from(map['tags']);
        else if (map['tags'] is String) tags = (map['tags'] as String).split(',').map((s) => s.trim()).toList();
      } catch (_) {
        tags = null;
      }
    }

    return Product(
      id: id,
      name: name,
      price: price,
      imageUrl: imageUrl,
      productUrl: productUrl,
      rating: rating,
      category: category,
      petType: petType,
      tags: tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'image_url': imageUrl,
      'product_url': productUrl,
      'rating': rating,
      'category': category,
      'pet_type': petType,
      'tags': tags,
    };
  }

  // Static helper returning categories available per pet type
  static Map<String, List<String>> getPetCategories() {
    return {
      'dog': ['food', 'treat', 'toy', 'leash', 'bed', 'grooming'],
      'cat': ['food', 'treat', 'toy', 'litter', 'bed', 'grooming'],
      'bird': ['cage', 'food', 'toys'],
      'general': ['accessories', 'health']
    };
  }

  static List<String> getCategoriesForPet(String pet) {
    final map = getPetCategories();
    final key = pet.toLowerCase();
    return map[key] ?? [];
  }
}