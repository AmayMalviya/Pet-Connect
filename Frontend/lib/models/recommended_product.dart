class RecommendedProduct {
  final String productId;        // bigint in DB, will come as numeric or string from Supabase
  final String productName;
  final String category;
  final String? price;           // text in DB
  final String? imageUrl;
  final String? productUrl;
  final List<String>? tags;
  final String? matchReason;

  RecommendedProduct({
    required this.productId,
    required this.productName,
    required this.category,
    this.price,
    this.imageUrl,
    this.productUrl,
    this.tags,
    this.matchReason,
  });

  factory RecommendedProduct.fromJson(Map<String, dynamic> json) {
    return RecommendedProduct(
      productId: json['product_id'].toString(),       // ensure string
      productName: json['product_name'] as String,
      category: json['category'] as String,
      price: json['price']?.toString(),               // keep as string
      imageUrl: json['image_url'] as String?,
      productUrl: json['product_url'] as String?,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      matchReason: json['match_reason'] as String?,
    );
  }
}