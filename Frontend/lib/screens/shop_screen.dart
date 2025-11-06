import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/models/pet.dart';
import 'package:pet_connect_app/models/recommended_product.dart';
import 'package:pet_connect_app/services/recommendation_service.dart';
import 'package:pet_connect_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShopScreen extends StatefulWidget {
  static const routeName = '/shop';
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with AutomaticKeepAliveClientMixin {
  final RecommendationService _recommendationService = RecommendationService();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _petSectionKeys = {};

  late Future<_ShopData> _dataFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    print('DEBUG: ShopScreen initState called');
    _dataFuture = _loadAll();
  }

  Future<_ShopData> _loadAll() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }

    final petsResp = await Supabase.instance.client
        .from('pets')
        .select('id, name, animal, breed, photo_url')
        .eq('owner_id', user.id);

    final List<Pet> allPets = (petsResp as List).map((j) => Pet.fromJson(j as Map<String, dynamic>)).toList();
    
    // Debug: log all pets and their IDs
    print('DEBUG: Loaded ${allPets.length} pets from Supabase');
    for (final p in allPets) {
      print('DEBUG: Pet - name: ${p.name}, id: ${p.id}, animal: ${p.animal}');
    }

    // Filter to pets with valid non-empty IDs
    final List<Pet> pets = allPets.where((p) => (p.id?.isNotEmpty ?? false)).toList();
    print('DEBUG: Filtered to ${pets.length} pets with valid IDs');

    if (pets.isEmpty) {
      print('DEBUG: No pets with valid IDs found');
      return _ShopData(pets: [], recsByPet: {});
    }

    // Fetch recommendations per pet in parallel
    final Map<String, List<RecommendedProduct>> recsByPet = {};
    await Future.wait(pets.map((pet) async {
      final petId = pet.id!; // Safe because we filtered above
      print('DEBUG: Fetching recommendations for pet: $petId');
      final list = await _recommendationService.getRecommendedProducts(petId);
      recsByPet[petId] = list;
      print('DEBUG: Got ${list.length} recommendations for pet: $petId');
    }));

    // Init keys for scroll-to-section
    for (final p in pets) {
      final petId = p.id!; // Safe because we filtered above
      _petSectionKeys[petId] = GlobalKey();
    }

    return _ShopData(pets: pets, recsByPet: recsByPet);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<_ShopData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('No data'));
        }

        final data = snapshot.data!;
        final pets = data.pets;
        final recsByPet = data.recsByPet;

        if (pets.isEmpty) {
          return const Center(child: Text('No pets found. Add a pet to see recommendations.'));
        }

        return ListView(
          controller: _scrollController,
          children: [
            _buildPetHeader(pets, onTap: (petId) => _scrollToPetSection(petId)),
            const SizedBox(height: 8),
            ...pets.map((pet) {
              final petId = pet.id?.toString() ?? '';
              final recs = recsByPet[petId] ?? [];
              return Container(
                key: _petSectionKeys[petId],
                child: _buildPetSection(context, pet, recs),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  void _scrollToPetSection(String petId) {
    final key = _petSectionKeys[petId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
    }
  }

  Widget _buildPetHeader(List<Pet> pets, {void Function(String petId)? onTap}) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: pets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final pet = pets[index];
          return GestureDetector(
            onTap: onTap != null ? () => onTap(pet.id?.toString() ?? '') : null,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: pet.photoUrl != null ? NetworkImage(pet.photoUrl!) : null,
                  child: pet.photoUrl == null ? const Icon(Icons.pets, size: 28) : null,
                ),
                const SizedBox(height: 2),
                SizedBox(
                  width: 80,
                  child: Text(
                    pet.name ?? 'Pet',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  (pet.animal ?? '').toUpperCase(),
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPetSection(BuildContext context, Pet pet, List<RecommendedProduct> products) {
    final grouped = _groupProductsByCategory(products);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommended for ${pet.name ?? 'your pet'}',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (products.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'No recommendations yet for ${pet.name ?? 'this pet'}.',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          ...grouped.entries.map((entry) {
            final category = entry.key;
            final items = entry.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  category,
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 6),
                ...items.map((product) => _buildProductCard(context, product)).toList(),
              ],
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, RecommendedProduct product) {
    final priceText = (product.price != null && product.price!.isNotEmpty)
        ? '\$${double.tryParse(product.price!)?.toStringAsFixed(2) ?? product.price!}'
        : '';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: product.imageUrl != null
                  ? Image.network(
                      product.imageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 48),
                    )
                  : const SizedBox(
                      width: 80,
                      height: 80,
                      child: Icon(Icons.image_not_supported, size: 48),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.productName, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                  if (priceText.isNotEmpty)
                    Text(priceText, style: GoogleFonts.poppins(fontSize: 14, color: AppColors.primary)),
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
  }

  Map<String, List<RecommendedProduct>> _groupProductsByCategory(List<RecommendedProduct> products) {
    final Map<String, List<RecommendedProduct>> grouped = {};
    for (final p in products) {
      (grouped[p.category] ??= []).add(p);
    }
    return grouped;
  }
}

class _ShopData {
  final List<Pet> pets;
  final Map<String, List<RecommendedProduct>> recsByPet;
  _ShopData({required this.pets, required this.recsByPet});
}
