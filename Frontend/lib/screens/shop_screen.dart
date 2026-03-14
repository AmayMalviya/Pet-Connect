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

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<Pet> _userPets = [];

  Pet? _selectedPet;
  String? _selectedCategory;
  bool _isLoading = true;
  bool _showAIPanel = false;
  String? _aiSuggestion;
  bool _aiLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(_applyFilters);
  }

  Future<void> _loadInitialData() async {
    try {
      await _productService.initialize();
      await _aiService.initialize();

      // Load products
      final products = await _supabaseService.getProducts();

      // Load user's pets
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
          _selectedPet = null; // Default to "All Pets"
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Error loading shop data: $e');
    }
  }

  void _applyFilters() {
    var filtered = _products;

    // Filter by pet type
    if (_selectedPet != null) {
      filtered = _productService.filterProductsByPetType(
        filtered,
        _selectedPet!.animal ?? 'dog',
      );
    }

    // Filter by category
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filtered = _productService.filterProductsByCategory(
        filtered,
        _selectedCategory!,
      );
    }

    // Filter by search
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where((product) => product.name.toLowerCase().contains(query))
          .toList();
    }

    setState(() {
      _filteredProducts = filtered;
    });
  }

  Future<void> _getAISuggestions() async {
    if (_selectedPet == null) return;

    setState(() => _aiLoading = true);

    try {
      final query = _searchController.text.isNotEmpty
          ? _searchController.text
          : 'recommend products for my pet';

      final response = await _aiService.sendMessage(
        message: query,
        mode: 'shopping',
        pet: _selectedPet,
      );

      if (mounted) {
        setState(() {
          _aiSuggestion = response.content;
          _showAIPanel = true;
          _aiLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiSuggestion = 'Error getting suggestions: $e';
          _showAIPanel = true;
          _aiLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final petCategories = _selectedPet != null
        ? Product.getCategoriesForPet(_selectedPet!.animal ?? 'dog')
        : <String>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Shop'),
        elevation: 0,
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Pet selector
                if (_userPets.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shop for:',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _userPets.length + 1, // Add 1 for "All"
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                // "All Pets" chip
                                final isSelected = _selectedPet == null;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: const Text('All Pets'),
                                    selected: isSelected,
                                    onSelected: (_) {
                                      setState(() {
                                        _selectedPet = null;
                                        _selectedCategory = null;
                                        _showAIPanel = false;
                                        _applyFilters();
                                      });
                                    },
                                    backgroundColor: Colors.grey[200],
                                    selectedColor: AppColors.primary,
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                );
                              }

                              final petIndex = index - 1;
                              final pet = _userPets[petIndex];
                              final isSelected = pet.id == _selectedPet?.id;

                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label:
                                      Text(pet.name ?? 'Pet ${petIndex + 1}'),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedPet = pet;
                                      _selectedCategory = null;
                                      _showAIPanel = false;
                                      _applyFilters();
                                    });
                                  },
                                  backgroundColor: Colors.grey[200],
                                  selectedColor: AppColors.primary,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                // Category filter
                if (petCategories.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Categories:',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: petCategories.length,
                            itemBuilder: (context, index) {
                              final category = petCategories[index];
                              final isSelected = category == _selectedCategory;

                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(category),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedCategory = isSelected
                                          ? null
                                          : category;
                                      _applyFilters();
                                    });
                                  },
                                  backgroundColor: Colors.grey[200],
                                  selectedColor: Colors.orange[100],
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.orange
                                        : Colors.black,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                // Search and AI button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search products...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton.small(
                        heroTag: 'shop_screen_fab',
                        onPressed: _selectedPet == null
                            ? null
                            : _aiLoading
                            ? null
                            : _getAISuggestions,
                        backgroundColor: AppColors.primary,
                        disabledElevation: 0,
                        child: Icon(
                          Icons.auto_awesome,
                          color: _selectedPet == null || _aiLoading
                              ? Colors.grey
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // AI Suggestion Panel
                if (_showAIPanel && _aiSuggestion != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        border: Border.all(color: Colors.blue[200]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.auto_awesome, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(
                                    'AI Suggestions',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _showAIPanel = false),
                                child: const Icon(Icons.close),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _aiSuggestion!,
                            style: GoogleFonts.poppins(fontSize: 12),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),

                // Products
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_bag,
                                size: 48,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No products found',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            return ProductCard(
                              product: _filteredProducts[index],
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  Future<void> _launchUrl() async {
    final urlString = product.productUrl;
    if (urlString == null || urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product.imageUrl.isNotEmpty
                  ? Image.network(
                      product.imageUrl,
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (c, _, __) => Container(
                        width: double.infinity,
                        height: 150,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      height: 150,
                      color: Colors.grey[300],
                      child: const Icon(Icons.shopping_bag),
                    ),
            ),
            const SizedBox(height: 12),

            // Product Info
            Text(
              product.name,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),

            // Price
            Text(
              product.price,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),

            // Rating
            if (product.rating != null)
              Row(
                children: [
                  Icon(Icons.star, size: 14, color: Colors.amber[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${product.rating}',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ],
              ),

            // Source
            if (product.sourceWebsite != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'From: ${product.sourceWebsite}',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            const SizedBox(height: 12),

            // View Product Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: product.productUrl != null ? _launchUrl : null,
                icon: const Icon(Icons.open_in_new),
                label: const Text('View Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: Colors.grey[300],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
