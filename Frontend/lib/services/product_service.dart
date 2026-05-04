import 'package:pet_connect_app/models/product.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductService {
  late SharedPreferences _prefs;
  final Map<String, List<Product>> _filteredProductsCache = {};

  /// Initialize the ProductService
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get product categories for a specific pet type
  List<String> getCategoriesForPet(String petType) {
    return Product.getCategoriesForPet(petType);
  }

  /// Filter products by pet type
  List<Product> filterProductsByPetType(
    List<Product> products,
    String petType,
  ) {
    return products.where((product) {
      // 1. Check if the product explicitly defines the petType
      if (product.petType?.toLowerCase() == petType.toLowerCase()) {
        return true;
      }
      
      // 2. Check if the species list contains the petType
      if (product.species != null && 
          product.species!.any((s) => s.toLowerCase() == petType.toLowerCase())) {
        return true;
      }

      // 3. Fallback: Check if category loosely matches a category for the pet
      // (Only use fallback if product has no explicit pet_type assigned)
      if (product.petType == null && (product.species == null || product.species!.isEmpty)) {
        final categories = Product.getCategoriesForPet(petType);
        final productCategory = product.category?.toLowerCase() ?? '';
        return categories.any(
          (cat) => productCategory.contains(cat.toLowerCase()),
        );
      }
      
      return false;
    }).toList();
  }

  /// Filter products by category
  List<Product> filterProductsByCategory(
    List<Product> products,
    String category,
  ) {
    return products.where((product) {
      final productCategory = product.category?.toLowerCase() ?? '';
      return productCategory.contains(category.toLowerCase());
    }).toList();
  }

  /// Filter products by multiple criteria
  List<Product> filterProducts({
    required List<Product> products,
    String? petType,
    String? category,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    List<String>? species,
    List<String>? breedCompatibility,
    String? ageRange,
    String? weightRange,
    List<String>? medicalRestrictions,
    List<String>? allergyWarnings,
    List<String>? tags,
  }) {
    var filtered = products;

    // Filter by pet type
    if (petType != null && petType.isNotEmpty) {
      filtered = filterProductsByPetType(filtered, petType);
    }

    // Filter by category
    if (category != null && category.isNotEmpty) {
      filtered = filterProductsByCategory(filtered, category);
    }

    // Filter by price range
    if (minPrice != null || maxPrice != null) {
      filtered = filtered.where((product) {
        final price = _extractPrice(product.price);
        if (minPrice != null && price < minPrice) return false;
        if (maxPrice != null && price > maxPrice) return false;
        return true;
      }).toList();
    }

    // Filter by rating
    if (minRating != null) {
      filtered = filtered
          .where((product) => (product.rating ?? 0) >= minRating)
          .toList();
    }

    // Filter by species
    if (species != null && species.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.species?.any((s) => species.contains(s)) ?? false;
      }).toList();
    }

    // Filter by breed compatibility
    if (breedCompatibility != null && breedCompatibility.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.breedCompatibility?.any((b) => breedCompatibility.contains(b)) ?? false;
      }).toList();
    }

    // Filter by age range
    if (ageRange != null && ageRange.isNotEmpty) {
      filtered = filtered.where((product) {
        return _isAgeInRange(product.ageRange, ageRange);
      }).toList();
    }

    // Filter by weight range
    if (weightRange != null && weightRange.isNotEmpty) {
      filtered = filtered.where((product) {
        // This is a simplified example. You might need a more robust implementation
        // to handle different weight units and ranges.
        return product.weightRange?.toLowerCase().contains(weightRange.toLowerCase()) ?? false;
      }).toList();
    }

    // Filter by medical restrictions
    if (medicalRestrictions != null && medicalRestrictions.isNotEmpty) {
      filtered = filtered.where((product) {
        return !(product.medicalRestrictions?.any((r) => medicalRestrictions.contains(r)) ?? false);
      }).toList();
    }

    // Filter by allergy warnings
    if (allergyWarnings != null && allergyWarnings.isNotEmpty) {
      filtered = filtered.where((product) {
        return !(product.allergyWarnings?.any((w) => allergyWarnings.contains(w)) ?? false);
      }).toList();
    }

    // Filter by tags
    if (tags != null && tags.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.tags?.any((t) => tags.contains(t)) ?? false;
      }).toList();
    }

    return filtered;
  }

  bool _isAgeInRange(String? productAgeRange, String petAgeRange) {
    if (productAgeRange == null) return true;
    // This is a simplified example. You might need a more robust implementation
    // to handle different age range formats.
    return productAgeRange.toLowerCase() == petAgeRange.toLowerCase();
  }

  /// Extract numeric price from price string
  double _extractPrice(String priceString) {
    final cleanPrice = priceString.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleanPrice) ?? 0.0;
  }

  /// Sort products by various criteria
  List<Product> sortProducts(List<Product> products, String sortBy) {
    final sorted = List<Product>.from(products);

    switch (sortBy.toLowerCase()) {
      case 'price_low_high':
        sorted.sort(
          (a, b) => _extractPrice(a.price).compareTo(_extractPrice(b.price)),
        );
        break;
      case 'price_high_low':
        sorted.sort(
          (b, a) => _extractPrice(a.price).compareTo(_extractPrice(b.price)),
        );
        break;
      case 'rating':
        sorted.sort((b, a) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      case 'name':
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    return sorted;
  }

  /// Get recommended products based on AI suggestions
  /// This parses the AI response and returns structured product recommendations
  List<Map<String, dynamic>> parseAIProductRecommendations(String aiResponse) {
    final recommendations = <Map<String, dynamic>>[];

    // Simple parsing logic - can be enhanced
    // Expected format: Product name, category, reason, price range
    final lines = aiResponse.split('\n');

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      // Try to extract product information
      final parts = line.split('|');
      if (parts.length >= 2) {
        recommendations.add({
          'name': parts[0].trim(),
          'category': parts.length > 1 ? parts[1].trim() : 'General',
          'reason': parts.length > 2 ? parts[2].trim() : '',
          'priceRange': parts.length > 3 ? parts[3].trim() : 'Varies',
        });
      }
    }

    return recommendations;
  }

  /// Cache filtered products
  Future<void> cacheFilteredProducts(
    String cacheKey,
    List<Product> products,
  ) async {
    _filteredProductsCache[cacheKey] = products;
  }

  /// Get cached products
  List<Product>? getCachedProducts(String cacheKey) {
    return _filteredProductsCache[cacheKey];
  }

  /// Clear product cache
  void clearCache() {
    _filteredProductsCache.clear();
  }

  /// Get trending products (mock implementation)
  List<Product> getTrendingProducts(List<Product> allProducts) {
    // Sort by rating and return top products
    final sorted = List<Product>.from(allProducts);
    sorted.sort((b, a) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    return sorted.take(10).toList();
  }

  /// Get recommended products for a specific pet type and age
  List<Product> getRecommendedProductsForPet({
    required List<Product> allProducts,
    required String petType,
    required int? age,
  }) {
    var filtered = filterProductsByPetType(allProducts, petType);

    // Age-based filtering logic
    if (age != null) {
      if (age < 2) {
        // Young pets - focus on toys, training supplies
        filtered = filtered.where((p) {
          final category = p.category?.toLowerCase() ?? '';
          return category.contains('toy') || category.contains('training');
        }).toList();
      } else if (age > 7) {
        // Senior pets - focus on comfort, health
        filtered = filtered.where((p) {
          final category = p.category?.toLowerCase() ?? '';
          return category.contains('bed') ||
              category.contains('comfort') ||
              category.contains('supplement') ||
              category.contains('food');
        }).toList();
      }
    }

    // Return sorted by rating
    return sortProducts(filtered, 'rating');
  }

  /// Generate search query for AI product finder
  String generateProductSearchQuery({
    required String petType,
    required int? petAge,
    required String userQuery,
  }) {
    return '''Find products suitable for a ${petAge != null ? '$petAge-year-old' : ''} $petType that matches: $userQuery''';
  }

  /// Check if two products are similar (for deduplication)
  bool areSimilarProducts(Product p1, Product p2) {
    return p1.name.toLowerCase() == p2.name.toLowerCase() &&
        (p1.sourceWebsite == null ||
            p2.sourceWebsite == null ||
            p1.sourceWebsite == p2.sourceWebsite);
  }

  /// Deduplicate products list
  List<Product> deduplicateProducts(List<Product> products) {
    final seen = <String>{};
    return products.where((product) {
      final key = '${product.name.toLowerCase()}|${product.sourceWebsite}';
      if (seen.contains(key)) {
        return false;
      }
      seen.add(key);
      return true;
    }).toList();
  }
}
