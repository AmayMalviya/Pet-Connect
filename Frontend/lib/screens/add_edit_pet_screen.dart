import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/models/cat_breed.dart';
import 'package:pet_connect_app/models/dog_breed.dart';
import 'package:pet_connect_app/models/pet.dart';
import 'package:pet_connect_app/services/breed_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddEditPetScreen extends StatefulWidget {
  static const routeName = '/add-edit-pet';
  final Pet? pet;

  const AddEditPetScreen({super.key, this.pet});

  @override
  State<AddEditPetScreen> createState() => _AddEditPetScreenState();
}

class _AddEditPetScreenState extends State<AddEditPetScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String? _selectedBreed;
  String? _selectedAgeRange;

  bool _isLoadingBreeds = true;
  List<DogBreed> _dogBreeds = [];
  List<CatBreed> _catBreeds = [];

  final List<String> _ageRanges = [
    '0-6 months (puppy phase)',
    '6-12 months (adolescence)',
    '1-2 years (adulthood)',
    '2+ years',
    '7/8+ years (senior)',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pet?.name);
    _selectedBreed = widget.pet?.breed;
    _selectedAgeRange = _ageRanges.firstWhere(
        (age) => _convertAgeRangeToYears(age) == widget.pet?.age,
        orElse: () => _ageRanges.isNotEmpty ? _ageRanges[0] : '');
    _fetchBreeds();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _fetchBreeds() async {
    try {
      final dogBreeds = await BreedService.getDogBreeds();
      final catBreeds = await BreedService.getCatBreeds();

      if (mounted) {
        setState(() {
          _dogBreeds = dogBreeds..sort((a, b) => a.breedName.compareTo(b.breedName));
          _catBreeds = catBreeds..sort((a, b) => a.breedName.compareTo(b.breedName));
          _isLoadingBreeds = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingBreeds = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load breeds: ${e.toString()}')),
        );
      }
    }
  }

  int _convertAgeRangeToYears(String ageRange) {
    if (ageRange == '0-6 months (puppy phase)') return 0;
    if (ageRange == '6-12 months (adolescence)') return 1;
    if (ageRange == '1-2 years (adulthood)') return 1;
    if (ageRange == '2+ years') return 2;
    if (ageRange == '7/8+ years (senior)') return 7;
    return 0;
  }

  Future<void> _savePet() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You must be logged in to save a pet.')),
          );
          return;
        }

        final petData = {
          'name': _nameController.text,
          'breed': _selectedBreed,
          'age': _convertAgeRangeToYears(_selectedAgeRange!),
        };

        if (widget.pet == null) {
          petData['owner_id'] = user.id;
          await Supabase.instance.client.from('pets').insert(petData);
        } else {
          await Supabase.instance.client
              .from('pets')
              .update(petData)
              .eq('id', widget.pet!.id!);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet saved successfully!')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save pet: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pet == null ? 'Add Pet' : 'Edit Pet',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Pet Details',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a name' : null,
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingBreeds)
                    const Center(child: CircularProgressIndicator())
                  else
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Breed',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                      value: _selectedBreed,
                      items: widget.pet?.animal == 'Dog'
                          ? _dogBreeds
                              .map((b) => DropdownMenuItem<String>(
                                    value: b.breedName,
                                    child: Text(b.breedName),
                                  ))
                              .toList()
                          : _catBreeds
                              .map((b) => DropdownMenuItem<String>(
                                    value: b.breedName,
                                    child: Text(b.breedName),
                                  ))
                              .toList(),
                      onChanged: (v) => setState(() => _selectedBreed = v),
                      validator: (v) => v == null ? 'Please select a breed' : null,
                    ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Age',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    value: _selectedAgeRange,
                    items: _ageRanges
                        .map((age) => DropdownMenuItem<String>(
                              value: age,
                              child: Text(age),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedAgeRange = v),
                    validator: (v) => v == null ? 'Please select an age' : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _savePet,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save Pet'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}