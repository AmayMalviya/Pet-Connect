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

  @override
  void initState() {
    super.initState();
    _fetchPetsForAdoption();
  }

  Future<void> _fetchPetsForAdoption() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await Supabase.instance.client
          .from('pets')
          .select('*')
          .eq('status', 'Available for Adoption'); // Filter for adoptable pets

      if (response != null) {
        _pets = (response as List).map((json) => Pet.fromJson(json)).toList();
      } else {
        _pets = [];
      }
    } on PostgrestException catch (e) {
      _errorMessage = 'Error fetching pets: ${e.message}';
      print('Supabase error: ${e.message}');
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
      print('General error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Adopt a Pet',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.poppins(color: Colors.red),
                  ),
                )
              : _pets.isEmpty
                  ? Center(
                      child: Text(
                        'No pets available for adoption at the moment.',
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _pets.length,
                      itemBuilder: (context, index) {
                        final pet = _pets[index];
                        return ExpandablePetCard(
                          pet: pet,
                          onPetUpdated: _fetchPetsForAdoption, // Refresh list on update
                          onDeletePet: (petId) {
                            // Adoption screen doesn't allow deleting pets
                            // This callback is required by ExpandablePetCard, so provide a no-op
                          },
                        );
                      },
                    ),
    );
  }
}
