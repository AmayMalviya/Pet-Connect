import 'package:pet_connect_app/screens/adoption_pet_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/models/pet.dart';
import 'package:pet_connect_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdoptionScreen extends StatefulWidget {
  static const routeName = '/adoption-screen';
  const AdoptionScreen({Key? key}) : super(key: key);

  @override
  State<AdoptionScreen> createState() => _AdoptionScreenState();
}

class _AdoptionScreenState extends State<AdoptionScreen> {
  List<Pet> _pets = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _userCity;
  String? _userState;

  @override
  void initState() {
    super.initState();
    _loadUserLocationAndFetchPets();
  }

  Future<void> _loadUserLocationAndFetchPets() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'Please login to view adoptable pets.';
        _isLoading = false;
      });
      return;
    }

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('city, state')
          .eq('user_id', user.id)
          .maybeSingle();

      setState(() {
        _userCity = profile?['city'] as String?;
        _userState = profile?['state'] as String?;
      });

      await _fetchPetsForAdoption();
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load location: $e');
    }
  }

  Future<void> _fetchPetsForAdoption() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final petsQuery = Supabase.instance.client
          .from('pets')
          .select('*, profiles!inner(city, state, role)')
          .eq('status', 'Available for Adoption')
          .eq('profiles.role', 'Shelter');
      if (_userCity != null && _userState != null) {
        petsQuery
          ..eq('profiles.city', _userCity!)
          ..eq('profiles.state', _userState!);
      } else if (_userState != null) {
        petsQuery.eq('profiles.state', _userState!);
      } else if (_userCity != null) {
        petsQuery.eq('profiles.city', _userCity!);
      }

      final response = await petsQuery.order('created_at', ascending: false);

      _pets = (response as List)
          .map((json) => Pet.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      setState(() => _errorMessage = 'Error fetching pets: ${e.message}');
    } catch (e) {
      setState(() => _errorMessage = 'Error fetching pets: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showPetModal(Pet pet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PetProfileModal(pet: pet),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Adopt a Pet',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: GoogleFonts.poppins(color: Colors.red)))
              : _pets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pets, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'No pets available in your area.',
                            style: GoogleFonts.poppins(
                                fontSize: 16, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchPetsForAdoption,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _pets.length,
                        itemBuilder: (context, index) {
                          final pet = _pets[index];
                          final isNetworkUrl = pet.photoUrl != null &&
                              (pet.photoUrl!.startsWith('http://') ||
                                  pet.photoUrl!.startsWith('https://'));

                          return GestureDetector(
                            onTap: () => _showPetModal(pet),
                            child: Card(
                              elevation: 3,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                leading: CircleAvatar(
                                  radius: 30,
                                  backgroundImage: isNetworkUrl
                                      ? NetworkImage(pet.photoUrl!)
                                      : const AssetImage(
                                              'assets/images/logo.png')
                                          as ImageProvider,
                                ),
                                title: Text(
                                  pet.name ?? 'Unknown Pet',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        pet.breed ?? pet.animal ?? 'Unknown',
                                        style:
                                            GoogleFonts.poppins(fontSize: 13)),
                                    if (pet.age != null)
                                      Text('${pet.age} years old',
                                          style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey[600])),
                                  ],
                                ),
                                trailing: Icon(Icons.chevron_right,
                                    color: AppColors.primary),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

/// Scrollable pet profile bottom sheet modal
class _PetProfileModal extends StatelessWidget {
  final Pet pet;
  const _PetProfileModal({required this.pet});

  Widget _infoRow(String label, String? value) {
    if (value == null || value.trim().isEmpty || value == 'null') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text('$label:',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.grey[700])),
          ),
          Expanded(
              child: Text(value, style: GoogleFonts.poppins(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _badge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNetworkUrl = pet.photoUrl != null &&
        (pet.photoUrl!.startsWith('http://') ||
            pet.photoUrl!.startsWith('https://'));

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pet photo
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: isNetworkUrl
                            ? Image.network(
                                pet.photoUrl!,
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                'assets/images/logo.png',
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        pet.name ?? 'Unknown Pet',
                        style: GoogleFonts.poppins(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      if (pet.breed != null)
                        Text(pet.breed!,
                            style: GoogleFonts.poppins(
                                fontSize: 15, color: Colors.grey[600])),
                      const SizedBox(height: 12),
                      // Chip badges
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (pet.animal != null) _badge(pet.animal!, Icons.pets),
                          if (pet.gender != null) _badge(pet.gender!, Icons.wc),
                          if (pet.age != null) _badge('${pet.age} yrs', Icons.cake_outlined),
                          if (pet.color != null) _badge(pet.color!, Icons.palette_outlined),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text('Details',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      _infoRow('Weight',
                          pet.weightKg != null ? '${pet.weightKg} kg' : null),
                      _infoRow('Height',
                          pet.heightCm != null ? '${pet.heightCm} cm' : null),
                      _infoRow('Diet Type', pet.dietType),
                      _infoRow(
                          'Feeding Frequency',
                          pet.feedingFrequency != null
                              ? '${pet.feedingFrequency} times/day'
                              : null),
                      _infoRow('Activity Level', pet.activityLevel),
                      _infoRow('Coat Type', pet.coatType),
                      _infoRow('Grooming Needs', pet.groomingNeeds),
                      _infoRow('Preferred Food', pet.preferredFoodType),
                      _infoRow('Allergies', pet.allergies?.join(', ')),
                      _infoRow('Medical Conditions',
                          pet.medicalConditions?.join(', ')),
                      if (pet.description != null &&
                          pet.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text('About',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(pet.description!,
                            style: GoogleFonts.poppins(
                                fontSize: 14, color: Colors.grey[800])),
                      ],
                      const SizedBox(height: 28),
                      // I'm Interested button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.favorite_border),
                          label: Text("I'm Interested",
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600, fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AdoptionPetDetailsScreen(pet: pet),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
