import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/models/recommended_product.dart';
import 'package:pet_connect_app/services/recommendation_service.dart';
import 'package:pet_connect_app/theme/app_theme.dart';

class RecommendedShopScreen extends StatefulWidget {
  static const routeName = '/recommended-shop';

  final String petId;
  final String petName;

  const RecommendedShopScreen({super.key, required this.petId, required this.petName});

  @override
  State<RecommendedShopScreen> createState() => _RecommendedShopScreenState();
}

class _RecommendedShopScreenState extends State<RecommendedShopScreen> {
  late Future<List<RecommendedProduct>> _recommendedProductsFuture;
  final RecommendationService _recommendationService = RecommendationService();

  @override
  void initState() {
    super.initState();
    _recommendedProductsFuture = _recommendationService.getRecommendedProducts(widget.petId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recommended for ${widget.petName}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        leading: const BackButton(),
      ),
      body: FutureBuilder<List<RecommendedProduct>>(
        future: _recommendedProductsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No recommendations found for your pet.'));
          }

          final products = snapshot.data!;
          final groupedProducts = _groupProductsByCategory(products);

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: groupedProducts.keys.length,
            itemBuilder: (context, index) {
              final category = groupedProducts.keys.elementAt(index);
              final categoryProducts = groupedProducts[category]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      category,
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: categoryProducts.length,
                    itemBuilder: (context, productIndex) {
                      final product = categoryProducts[productIndex];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              if (product.imageUrl != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.network(
                                    product.imageUrl!,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 80),
                                  ),
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(product.productName, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                                    if (product.price != null)
                                      Text(product.price != null ? '\$${product.price!.toStringAsFixed(2)}' : '',style: GoogleFonts.poppins(fontSize: 14, color: AppColors.primary)),
                                    if (product.matchReason != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          'Why Recommended: ${product.matchReason!}',
                                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.green[700]),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Map<String, List<RecommendedProduct>> _groupProductsByCategory(List<RecommendedProduct> products) {
    final Map<String, List<RecommendedProduct>> grouped = {};
    for (final product in products) {
      if (grouped.containsKey(product.category)) {
        grouped[product.category]!.add(product);
      } else {
        grouped[product.category] = [product];
      }
    }
    return grouped;
  }
}