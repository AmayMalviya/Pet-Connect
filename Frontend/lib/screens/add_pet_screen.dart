import 'package:flutter/material.dart';
import 'package:pet_connect_app/models/pet.dart';

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
  String? _furColor;
  String? _eyeColor;

  final Map<String, List<String>> _breeds = {
    'Dog': ['Golden Retriever', 'Labrador', 'German Shepherd', 'Poodle'],
    'Cat': ['Siamese', 'Persian', 'Maine Coon', 'Bengal'],
  };

  final List<String> _ageRanges = [
    '0-6 months (puppy phase)',
    '6-12 months (adolescence)',
    '1-2 years (adulthood)',
    '2+ years',
    '7/8+ years (senior)',
  ];

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
        breed: '$_selectedAnimal - $_selectedBreed',
        age: _convertAgeRangeToYears(_selectedAgeRange!),
        ownerUid: '', // This will be set in ProfileScreen
        // You might want to add furColor and eyeColor to the Pet model
      );
      Navigator.of(context).pop(newPet);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a New Pet'),
        leading: const BackButton(), // Added back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
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
                initialValue: _selectedAnimal,
                hint: const Text('Select Animal'),
                items: _breeds.keys.map((String animal) {
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
                validator: (value) => value == null ? 'Please select an animal' : null,
              ),
              if (_selectedAnimal != null)
                const SizedBox(height: 16),
              if (_selectedAnimal != null)
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Select Breed',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  initialValue: _selectedBreed,
                  hint: const Text('Select Breed'),
                  items: _breeds[_selectedAnimal!]!.map((String breed) {
                    return DropdownMenuItem<String>(
                      value: breed,
                      child: Text(breed),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedBreed = newValue;
                    });
                  },
                  validator: (value) => value == null ? 'Please select a breed' : null,
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Age Range',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                initialValue: _selectedAgeRange,
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
                validator: (value) => value == null ? 'Please select an age range.' : null,
              ),
              if (_selectedAnimal == 'Cat')
                Column(
                  children: [
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Fur Color',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onSaved: (value) {
                        _furColor = value;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Eye Color',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onSaved: (value) {
                        _eyeColor = value;
                      },
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveForm,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text('Save Pet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}