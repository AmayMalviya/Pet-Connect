import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/models/pet.dart';
import 'package:pet_connect_app/screens/pet_profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GroomingDetailsScreen extends StatefulWidget {
  static const String routeName = '/grooming-details';

  const GroomingDetailsScreen({super.key});

  @override
  State<GroomingDetailsScreen> createState() => _GroomingDetailsScreenState();
}

class _GroomingDetailsScreenState extends State<GroomingDetailsScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _petCareData = [];

  @override
  void initState() {
    super.initState();
    _fetchPetCareData();
  }

  Future<void> _fetchPetCareData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final petsResponse = await Supabase.instance.client
          .from('pets')
          .select()
          .eq('owner_id', user.id);

      final List<Pet> pets = (petsResponse as List<dynamic>).map((data) => Pet.fromJson(data as Map<String, dynamic>)).toList();
      List<Map<String, dynamic>> petCareData = [];

      for (final pet in pets) {
        if (pet.breedId == null) continue;

        final tableName = pet.animal == 'Dog' ? 'dogs_pet_data' : 'cats_pet_data';
        final breedData = await Supabase.instance.client
            .from(tableName)
            .select('grooming_needs, diet, training_tips, exercise_needs')
            .eq('breed_id', pet.breedId!)
            .maybeSingle();

        petCareData.add({
          'pet': pet,
          'grooming_needs': breedData?['grooming_needs'] ?? 'No grooming information available.',
          'diet': breedData?['diet'] ?? 'No diet information available.',
          'training_tips': breedData?['training_tips'] ?? 'No training information available.',
          'exercise_needs': breedData?['exercise_needs'] ?? 'No exercise information available.',
        });
      }

      setState(() {
        _petCareData = petCareData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load pet care data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pet Care Recommendations', style: GoogleFonts.poppins()),
        leading: const BackButton(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _petCareData.isEmpty
                  ? const Center(child: Text('No pets found.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _petCareData.length,
                      itemBuilder: (context, index) {
                        final data = _petCareData[index];
                        final Pet pet = data['pet'];
                        final String groomingNeeds = data['grooming_needs'];
                        final String diet = data['diet'];
                        final String trainingTips = data['training_tips'];
                        final String exerciseNeeds = data['exercise_needs'];
                        final isNetworkUrl = pet.photoUrl != null &&
                            (pet.photoUrl!.startsWith('http://') ||
                                pet.photoUrl!.startsWith('https://'));

                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => PetProfileScreen(pet: pet),
                              ),
                            );
                          },
                          child: Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundImage: isNetworkUrl
                                            ? NetworkImage(pet.photoUrl!)
                                            : const AssetImage('assets/images/logo.png') as ImageProvider,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(pet.name, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                                            Text(pet.breed, style: GoogleFonts.poppins(color: Colors.grey)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20),
                                  _buildDetailSection('Grooming Needs', groomingNeeds),
                                  _buildDetailSection('Diet', diet),
                                  _buildDetailSection('Training Tips', trainingTips),
                                  _buildDetailSection('Exercise Needs', exerciseNeeds),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Text(content, style: GoogleFonts.poppins()),
        const SizedBox(height: 16),
      ],
    );
  }
}