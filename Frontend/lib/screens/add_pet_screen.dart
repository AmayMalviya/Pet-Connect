
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

  final Map<String, List<String>> _breeds = {
    'Dog': ['Golden Retriever', 'Labrador', 'German Shepherd', 'Poodle'],
    'Cat': ['Siamese', 'Persian', 'Maine Coon', 'Bengal'],
  };

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newPet = Pet(
        name: _name,
        breed: '$_selectedAnimal - $_selectedBreed',
        imageUrl: 'assets/images/logo.png', // Placeholder image
      );
      Navigator.of(context).pop(newPet);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a New Pet'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Pet Name'),
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
              DropdownButtonFormField<String>(
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
                DropdownButtonFormField<String>(
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
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveForm,
                child: const Text('Save Pet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
