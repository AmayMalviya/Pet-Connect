import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/models/product.dart';
import 'package:pet_connect_app/models/pet.dart';
import 'package:pet_connect_app/services/supabase_service.dart';
import 'package:pet_connect_app/services/product_service.dart';
import 'package:pet_connect_app/services/ai_service.dart';
import 'package:pet_connect_app/theme/app_theme.dart' show AppColors;
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});
  static const String routeName = '/shop';

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final ProductService _productService = ProductService();
  final AIService _aiService = AIService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _aiQueryController = TextEditingController();

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<Pet> _userPets = [];
  List<Map<String, dynamic>> _aiSuggestedProducts = [];
  List<Map<String, dynamic>> _filteredAISuggestions = [];

  Pet? _selectedPet;
  String? _selectedCategory;
  String? _aiFilterCategory;
  bool _isLoading = true;
  bool _aiLoading = false;
  int _page = 0;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(_applyFilters);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        _hasMore &&
        !_isLoadingMore) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final moreProducts = await _supabaseService.getProducts(
        limit: 20,
        offset: _page * 20,
      );

      if (mounted) {
        setState(() {
          _products.addAll(moreProducts);
          _filteredProducts = _productService.filterProducts(
            products: _products,
            petType: _selectedPet?.animal,
            category: _selectedCategory,
            species: _selectedPet != null ? [_selectedPet!.animal!] : null,
            breedCompatibility: _selectedPet != null
                ? [_selectedPet!.breed!]
                : null,
            ageRange: _selectedPet?.age != null
                ? '${_selectedPet!.age} years'
                : null,
            weightRange: _selectedPet?.weightKg != null
                ? '${_selectedPet!.weightKg} kg'
                : null,
            medicalRestrictions: _selectedPet?.medicalConditions,
            allergyWarnings: _selectedPet?.allergies,
          );
          _page++;
          _hasMore = moreProducts.length == 20;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
      debugPrint('Error loading more products: $e');
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _page = 0;
      _products = [];
      _hasMore = true;
    });

    try {
      await _productService.initialize();
      await _aiService.initialize();

      final products = await _supabaseService.getProducts(limit: 20, offset: 0);

      final user = Supabase.instance.client.auth.currentUser;
      List<Pet> pets = [];
      if (user != null) {
        final response = await Supabase.instance.client
            .from('pets')
            .select()
            .eq('owner_id', user.id);
        pets = response
            .map((p) => Pet.fromJson(p as Map<String, dynamic>))
            .toList();
      }

      if (mounted) {
        setState(() {
          _products = products;
          _filteredProducts = products;
          _userPets = pets;
          _selectedPet = null;
          _page = 1;
          _hasMore = products.length == 20;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error loading shop data: $e');
    }
  }

  void _applyFilters() {
    var filtered = _productService.filterProducts(
      products: _products,
      petType: _selectedPet?.animal,
      category: _selectedCategory,
      species: _selectedPet != null ? [_selectedPet!.animal!] : null,
      breedCompatibility: _selectedPet != null ? [_selectedPet!.breed!] : null,
      ageRange: _selectedPet?.age != null ? '${_selectedPet!.age} years' : null,
      weightRange: _selectedPet?.weightKg != null
          ? '${_selectedPet!.weightKg} kg'
          : null,
      medicalRestrictions: _selectedPet?.medicalConditions,
      allergyWarnings: _selectedPet?.allergies,
    );

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where((p) => p.name.toLowerCase().contains(query))
          .toList();
    }
    setState(() => _filteredProducts = filtered);
  }

  Future<void> _getPersonalizedRecommendations() async {
    if (_selectedPet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pet first')),
      );
      return;
    }

    setState(() => _aiLoading = true);

    try {
      final response = await _aiService.sendMessage(
        message: 'Get personalized product recommendations for my pet',
        mode: 'shopping',
        pet: _selectedPet,
      );

      if (mounted) {
        setState(() {
          if (response.structuredData != null &&
              response.structuredData!['parsed'] == true) {
            _aiSuggestedProducts = List<Map<String, dynamic>>.from(
              response.structuredData!['products'] ?? [],
            );
            _applyAIFilters();
          } else {
            _aiSuggestedProducts = [];
            _filteredAISuggestions = [];
          }
          _aiLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiSuggestedProducts = [];
          _filteredAISuggestions = [];
          _aiLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting recommendations: $e')),
        );
      }
    }
  }

  Future<void> _getAISuggestions() async {
    if (_selectedPet == null || _aiQueryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pet and enter a query')),
      );
      return;
    }

    setState(() => _aiLoading = true);

    try {
      final response = await _aiService.sendMessage(
        message: _aiQueryController.text.trim(),
        mode: 'shopping',
        pet: _selectedPet,
        query: _selectedCategory,
      );

      if (mounted) {
        setState(() {
          if (response.structuredData != null &&
              response.structuredData!['parsed'] == true) {
            _aiSuggestedProducts = List<Map<String, dynamic>>.from(
              response.structuredData!['products'] ?? [],
            );
            _applyAIFilters();
          } else {
            _aiSuggestedProducts = [];
            _filteredAISuggestions = [];
          }
          _aiLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiSuggestedProducts = [];
          _filteredAISuggestions = [];
          _aiLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting AI suggestions: $e')),
        );
      }
    }
  }

  Future<void> _showAISuggestionsDialog() async {
    if (_selectedPet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pet first')),
      );
      return;
    }

    final TextEditingController dialogController = TextEditingController();
    String? selectedCategory;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.blue[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Product Suggestions',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Get recommendations for ${_selectedPet!.name}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What are you looking for?',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: dialogController,
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g., "best toys for puppies" or "healthy treats"',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[400],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Category (optional):',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children:
                    [
                      'All',
                      ...Product.getCategoriesForPet(
                        _selectedPet!.animal ?? 'dog',
                      ),
                    ].map((cat) {
                      final isSelected =
                          selectedCategory == (cat == 'All' ? null : cat);
                      return GestureDetector(
                        onTap: () => setState(
                          () => selectedCategory = isSelected
                              ? null
                              : (cat == 'All' ? null : cat),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue[100]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            cat,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isSelected
                                  ? Colors.blue[700]
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton.icon(
              onPressed: dialogController.text.trim().isEmpty
                  ? null
                  : () async {
                      Navigator.of(context).pop();
                      await _getAISuggestionsFromDialog(
                        dialogController.text.trim(),
                        selectedCategory,
                      );
                    },
              icon: const Icon(Icons.search, size: 16),
              label: Text(
                'Get Suggestions',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getAISuggestionsFromDialog(
    String query,
    String? category,
  ) async {
    setState(() => _aiLoading = true);

    try {
      final response = await _aiService.sendMessage(
        message: query,
        mode: 'shopping',
        pet: _selectedPet,
        query: category,
      );

      if (mounted) {
        setState(() {
          if (response.structuredData != null &&
              response.structuredData!['parsed'] == true) {
            _aiSuggestedProducts = List<Map<String, dynamic>>.from(
              response.structuredData!['products'] ?? [],
            );
            _applyAIFilters();
          } else {
            _aiSuggestedProducts = [];
            _filteredAISuggestions = [];
          }
          _aiLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiSuggestedProducts = [];
          _filteredAISuggestions = [];
          _aiLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting AI suggestions: $e')),
        );
      }
    }
  }

  void _applyAIFilters() {
    var filtered = _aiSuggestedProducts;

    if (_aiFilterCategory != null && _aiFilterCategory!.isNotEmpty) {
      filtered = filtered.where((product) {
        final category = product['category']?.toString().toLowerCase() ?? '';
        return category.contains(_aiFilterCategory!.toLowerCase());
      }).toList();
    }

    _filteredAISuggestions = filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _aiQueryController.dispose();
    super.dispose();
  }

  List<String> _getUniqueCategories() {
    final categories = <String>{};
    for (final product in _aiSuggestedProducts) {
      final category = product['category']?.toString();
      if (category != null && category.isNotEmpty) {
        categories.add(category);
      }
    }
    return categories.toList()..sort();
  }

  Widget _buildAIFilterChip(String category, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _aiFilterCategory = isSelected ? null : category;
          _applyAIFilters();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[100] : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.blue[300]! : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          category,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.blue[800] : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      "Food",
      "Toys",
      "Beds",
      "Grooming",
      "Health",
      "Accessories",
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(elevation: 0, backgroundColor: AppColors.primary),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // ── Filter panel ──────────────────────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_userPets.isNotEmpty) ...[
                        Text(
                          'Shop for:',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 36,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _userPets.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return _buildPetChip(
                                  'All Pets',
                                  _selectedPet == null,
                                  () {
                                    setState(() {
                                      _selectedPet = null;
                                      _selectedCategory = null;
                                      _applyFilters();
                                    });
                                  },
                                );
                              }
                              final pet = _userPets[index - 1];
                              return _buildPetChip(
                                pet.name ?? 'Pet $index',
                                pet.id == _selectedPet?.id,
                                () {
                                  setState(() {
                                    _selectedPet = pet;
                                    _selectedCategory = null;
                                    _applyFilters();
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        'Categories:',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: categories.map((cat) {
                          final sel = cat == _selectedCategory;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _selectedCategory = sel ? null : cat;
                              _applyFilters();
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: sel
                                    ? Colors.orange.withOpacity(0.12)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: sel
                                      ? Colors.orange
                                      : Colors.transparent,
                                  width: 1.2,
                                ),
                              ),
                              child: Text(
                                cat,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: sel
                                      ? Colors.orange[800]
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      // AI Button
                      if (_selectedPet != null) ...[
                        GestureDetector(
                          onTap: _aiLoading ? null : _showAISuggestionsDialog,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _aiLoading
                                  ? Colors.blue[50]
                                  : Colors.blue.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _aiLoading
                                    ? Colors.blue[200]!
                                    : Colors.blue,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_aiLoading)
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.blue,
                                      ),
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.smart_toy_rounded,
                                    size: 14,
                                    color: Colors.blue[700],
                                  ),
                                const SizedBox(width: 6),
                                Text(
                                  'AI Suggestions',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Search
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search products...',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[400],
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              size: 20,
                              color: Colors.grey[400],
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: Colors.grey[400],
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _applyFilters();
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // AI Results Section
                if (_aiSuggestedProducts.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // AI Results Header
                        Row(
                          children: [
                            Text(
                              'AI Suggestions',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () {
                                setState(() => _aiSuggestedProducts = []);
                              },
                              icon: const Icon(Icons.close, size: 16),
                              label: Text(
                                'Clear',
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // AI Product Grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 8),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.7,
                              ),
                          itemCount: _filteredAISuggestions.length,
                          itemBuilder: (context, index) {
                            final product = _filteredAISuggestions[index];
                            return ProductCard(
                              product: Product.fromMap(product),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],

                // Result count
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Row(
                    children: [
                      Text(
                        '${_filteredProducts.length} products',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Product grid
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 30,
                                  color: Colors.grey[300],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No products found',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.64,
                              ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) =>
                              ProductCard(product: _filteredProducts[index]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildPetChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

// ── Product Card ──────────────────────────────────────────────────────────────

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  Future<void> _launchUrl(BuildContext context) async {
    final urlString = product.productUrl;
    if (urlString == null || urlString.isEmpty) return;

    // Track the click
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && product.id.isNotEmpty) {
      await Supabase.instance.client.from('product_clicks').insert({
        'product_id': product.id,
        'user_id': user.id,
        'clicked_at': DateTime.now().toIso8601String(),
      });
    }

    try {
      await launchUrl(
        Uri.parse(urlString),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Could not launch URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                product.imageUrl.isNotEmpty
                    ? Image.network(
                        product.imageUrl,
                        width: double.infinity,
                        height: 128,
                        fit: BoxFit.cover,
                        errorBuilder: (c, _, __) => _fallback(),
                      )
                    : _fallback(),
                if (product.rating != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 11,
                            color: Colors.amber[400],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${product.rating}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.sourceWebsite != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      product.sourceWebsite!,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[400],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        product.price,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      GestureDetector(
                        onTap: product.productUrl != null
                            ? () => _launchUrl(context)
                            : null,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: product.productUrl != null
                                ? AppColors.primary
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.open_in_new_rounded,
                            size: 14,
                            color: product.productUrl != null
                                ? Colors.white
                                : Colors.grey[400],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() => Container(
    width: double.infinity,
    height: 128,
    color: Colors.grey[100],
    child: Icon(Icons.shopping_bag_outlined, size: 34, color: Colors.grey[300]),
  );
}
