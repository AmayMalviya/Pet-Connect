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
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _fetchPetCareData();
  }

  String _formatPetCareData(dynamic data) {
    if (data == null) {
      return 'No information available.';
    }
    if (data is String) {
      return data;
    }
    if (data is Map) {
      return data.entries.map((e) => '${e.key}: ${e.value}').join('\n');
    }
    return data.toString();
  }

  Future<void> _fetchPetCareData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final response = await Supabase.instance.client
          .from('pet_breed_info')
          .select()
          .eq('owner_id', user.id);

      final List<Map<String, dynamic>> petCareData = (response as List<dynamic>).map((data) {
        final pet = Pet.fromJson(data as Map<String, dynamic>);
        return {
          'pet': pet,
          'grooming_needs': _formatPetCareData(data['grooming_needs']),
          'diet': _formatPetCareData(data['diet']),
          'training_tips': _formatPetCareData(data['training_tips']),
          'exercise_needs': _formatPetCareData(data['exercise_needs']),
        };
      }).toList();

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
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: ExpansionPanelList(
                        elevation: 0,
                        dividerColor: Colors.transparent,
                        expansionCallback: (int index, bool isExpanded) {
                          setState(() {
                            _expandedIndex = _expandedIndex == index ? null : index;
                          });
                        },
                        children: _petCareData.map<ExpansionPanel>((data) {
                          final Pet pet = data['pet'];
                          final String groomingNeeds = data['grooming_needs'];
                          final String diet = data['diet'];
                          final String trainingTips = data['training_tips'];
                          final String exerciseNeeds = data['exercise_needs'];
                          final isNetworkUrl = pet.photoUrl != null &&
                              (pet.photoUrl!.startsWith('http://') ||
                                  pet.photoUrl!.startsWith('https://'));

                          return ExpansionPanel(
                            canTapOnHeader: true,
                            headerBuilder: (BuildContext context, bool isExpanded) {
                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 30,
                                  backgroundImage: isNetworkUrl
                                      ? NetworkImage(pet.photoUrl!)
                                      : const AssetImage('assets/images/logo.png') as ImageProvider,
                                ),
                                title: Text(pet.name ?? 'Unknown Pet', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                                subtitle: Text(pet.breed ?? 'Unknown Breed', style: GoogleFonts.poppins(color: Colors.grey)),
                              );
                            },
                            body: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDetailSection('Grooming Needs', groomingNeeds),
                                  _buildDetailSection('Diet', diet),
                                  _buildDetailSection('Training Tips', trainingTips),
                                  _buildDetailSection('Exercise Needs', exerciseNeeds),
                                ],
                              ),
                            ),
                            isExpanded: _expandedIndex == _petCareData.indexOf(data),
                          );
                        }).toList(),
                      ),
                    ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).primaryColor)),
            const SizedBox(height: 8),
            Text(content, style: GoogleFonts.poppins(fontSize: 16, height: 1.5)),
          ],
        ),
      ),
    );
  }
}