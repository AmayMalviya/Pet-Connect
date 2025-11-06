import 'package:flutter/material.dart';
import 'package:pet_connect_app/models/pet.dart';
import 'package:pet_connect_app/screens/add_edit_pet_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PetProfileScreen extends StatefulWidget {
  const PetProfileScreen({super.key, required this.pet});

  final Pet pet;

  static const String routeName = '/pet-profile';

  @override
  State<PetProfileScreen> createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> {
  Map<String, dynamic>? _petWithBreedInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPetWithBreedInfo();
  }

  Future<void> _fetchPetWithBreedInfo() async {
    try {
      final response = await Supabase.instance.client
          .from('pet_breed_info')
          .select()
          .eq('id', widget.pet.id!)
          .single();

      setState(() {
        _petWithBreedInfo = response;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch pet details: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9DF),
      appBar: AppBar(
        title: Text(widget.pet.name ?? 'Unknown Pet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddEditPetScreen(pet: widget.pet),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Delete Pet'),
                    content: const Text('Are you sure you want to delete this pet?'),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text('Delete'),
                        onPressed: () async {
                          try {
                            await Supabase.instance.client
                                .from('pets')
                                .delete()
                                .eq('id', widget.pet.id!);
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to delete pet: $e')),
                            );
                          }
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _petWithBreedInfo == null
              ? const Center(child: Text('Pet not found.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 80,
                        backgroundImage: _petWithBreedInfo!['photo_url'] != null
                            ? NetworkImage(_petWithBreedInfo!['photo_url'])
                            : const AssetImage('assets/images/logo.png') as ImageProvider,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _petWithBreedInfo!['name'] ?? 'Unknown Pet',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(_petWithBreedInfo!['breed'] ?? 'Unknown Breed', style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 20),
                      _buildBreedInfoCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildBreedInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Breed Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Breed Name', _petWithBreedInfo!['breed_name'] ?? 'N/A'),
            _buildInfoRow('Diet', _petWithBreedInfo!['diet'] ?? 'N/A'),
            _buildInfoRow('Energy Level', _petWithBreedInfo!['energy_level']?.toString() ?? 'N/A'),
            _buildInfoRow('Grooming Needs', _petWithBreedInfo!['grooming_needs'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}