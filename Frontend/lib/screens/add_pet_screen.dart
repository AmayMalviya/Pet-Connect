import 'package:flutter/material.dart';
import 'package:pet_connect_app/models/cat_breed.dart';
import 'package:pet_connect_app/models/dog_breed.dart';
import 'package:pet_connect_app/models/pet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  static const String routeName = '/add-pet';

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String? _selectedAnimal;
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
    _fetchBreeds();
  }

  Future<void> _fetchBreeds() async {
    try {
      final supabase = Supabase.instance.client;
      final dogBreedsResponse = await supabase.from('dog_breeds').select();
      final catBreedsResponse = await supabase.from('cat_breeds').select();

      final List<DogBreed> dogBreeds = (dogBreedsResponse as List)
          .map((data) => DogBreed.fromJson(data))
          .toList();
      final List<CatBreed> catBreeds = (catBreedsResponse as List)
          .map((data) => CatBreed.fromJson(data))
          .toList();

      setState(() {
        _dogBreeds = dogBreeds;
        _catBreeds = catBreeds;
        _isLoadingBreeds = false;
      });
    } catch (e) {
      // Handle error, maybe show a snackbar
      setState(() {
        _isLoadingBreeds = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load breeds: ${e.toString()}')),
      );
    }
  }

  int _convertAgeRangeToYears(String ageRange) {
    if (ageRange == '0-6 months (puppy phase)') return 0;
    if (ageRange == '6-12 months (adolescence)') return 1;
    if (ageRange == '1-2 years (adulthood)') return 1;
    if (ageRange == '2+ years') return 2;
    if (ageRange == '7/8+ years (senior)') return 7;
    return 0; // Default or error case
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newPet = Pet(
        name: _name,
        breed: _selectedBreed!,
        age: _convertAgeRangeToYears(_selectedAgeRange!),
      );
      Navigator.of(context).pop(newPet);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a New Pet'),
        leading: const BackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Pet Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name.';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _name = value!;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Select Animal',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  value: _selectedAnimal,
                  hint: const Text('Select Animal'),
                  items: ['Dog', 'Cat'].map((String animal) {
                    return DropdownMenuItem<String>(
                      value: animal,
                      child: Text(animal),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedAnimal = newValue;
                      _selectedBreed = null;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select an animal' : null,
                ),
                if (_selectedAnimal != null)
                  const SizedBox(height: 16),
                if (_selectedAnimal != null)
                  _isLoadingBreeds
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Select Breed',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          value: _selectedBreed,
                          hint: const Text('Select Breed'),
                          items: _selectedAnimal == 'Dog'
                              ? _dogBreeds.map((DogBreed breed) {
                                  return DropdownMenuItem<String>(
                                    value: breed.breedName,
                                    child: Text(breed.breedName),
                                  );
                                }).toList()
                              : _catBreeds.map((CatBreed breed) {
                                  return DropdownMenuItem<String>(
                                    value: breed.breedName,
                                    child: Text(breed.breedName),
                                  );
                                }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedBreed = newValue;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Please select a breed' : null,
                        ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Age Range',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  value: _selectedAgeRange,
                  hint: const Text('Select Age Range'),
                  items: _ageRanges.map((String age) {
                    return DropdownMenuItem<String>(
                      value: age,
                      child: Text(age),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedAgeRange = newValue;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select an age range.' : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveForm,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                  ),
                  child: const Text('Save Pet'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}