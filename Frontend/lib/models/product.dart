class Product {
  final String name;
  final String price;
  final String imageUrl;
  final String? productUrl;
  final List<String>? tags;

  Product({
    required this.name,
    required this.price,
    required this.imageUrl,
    this.productUrl,
    this.tags,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['name']?.toString() ?? '',
      price: json['price']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      productUrl: json['url']?.toString(),
      tags: json['tags'] is List ? List<String>.from(json['tags']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'image_url': imageUrl,
      'url': productUrl,
      'tags': tags,
    };
  }
}
