import 'package:pet_connect_app/screens/adoption_pet_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/models/pet.dart';
import 'package:pet_connect_app/widgets/expandable_pet_card.dart';
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
      // Fetch user profile location
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
        .eq('profiles.role', 'Shelter'); // ✅ only shelter pets
      // Apply filters safely (Supabase .eq requires non-null values)
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

      if (response != null) {
        _pets = (response as List)
            .map((json) => Pet.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        _pets = [];
      }
    } on PostgrestException catch (e) {
      setState(() => _errorMessage = 'Error fetching pets: ${e.message}');
    } catch (e) {
      setState(() => _errorMessage = 'Error fetching pets: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Adopt a Pet',
          style:
              GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20),
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
                      child: Text('No pets available in your area.',
                          style: GoogleFonts.poppins(fontSize: 16)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _pets.length,
                      itemBuilder: (context, index) {
                        final pet = _pets[index];
                        return Column(
                          children: [
                            ExpandablePetCard(
                              pet: pet,
                              onPetUpdated: _fetchPetsForAdoption,
                              onDeletePet: (_) {},
                              showActions: false,
                              showHealthCalendar: false,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.favorite_border),
                              label: const Text('I’m Interested'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(45),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AdoptionPetDetailsScreen(pet: pet),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 30),
                          ],
                        );
                      },
                    ),
    );
  }
}
