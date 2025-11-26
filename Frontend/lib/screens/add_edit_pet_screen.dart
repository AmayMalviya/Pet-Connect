import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/models/cat_breed.dart';
import 'package:pet_connect_app/models/dog_breed.dart';
import 'package:pet_connect_app/models/pet.dart';
import 'package:pet_connect_app/services/breed_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
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
  String? _selectedAnimal;
  String? _selectedBreed;
  String? _selectedBreedRefId;
  String? _breedTable;
  String? _selectedAgeRange;
  String? _selectedGender;
  late TextEditingController _allergiesController;
  late TextEditingController _medicalConditionsController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _dietTypeController;
  late TextEditingController _feedingFrequencyController;
  late TextEditingController _activityLevelController;
  late TextEditingController _coatTypeController;
  late TextEditingController _groomingNeedsController;
  late TextEditingController _preferredFoodTypeController;
  String? _photoUrl;
  final ImagePicker _picker = ImagePicker();
  // status not currently used; remove to avoid unused-field lint

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

  String? capitalize(String? s) {
    if (s == null || s.isEmpty) {
      return s;
    }
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pet?.name);
    _selectedAnimal = capitalize(widget.pet?.animal);
    _selectedBreed = widget.pet?.breed;
    _selectedBreedRefId = widget.pet?.breedRefId;
    _breedTable = widget.pet?.breedTable;
    final index = _ageRanges.indexWhere((age) => _convertAgeRangeToYears(age) == widget.pet?.age);
    _selectedAgeRange = index != -1 ? _ageRanges[index] : null;
    _allergiesController = TextEditingController(text: widget.pet?.allergies?.join(', '));
    _medicalConditionsController = TextEditingController(text: widget.pet?.medicalConditions?.join(', '));
    _weightController = TextEditingController(text: widget.pet?.weightKg?.toString());
    _heightController = TextEditingController(text: widget.pet?.heightCm?.toString());
    _selectedGender = widget.pet?.gender;
    _dietTypeController = TextEditingController(text: widget.pet?.dietType);
    _feedingFrequencyController = TextEditingController(text: widget.pet?.feedingFrequency?.toString());
    _activityLevelController = TextEditingController(text: widget.pet?.activityLevel);
    _coatTypeController = TextEditingController(text: widget.pet?.coatType);
    _groomingNeedsController = TextEditingController(text: widget.pet?.groomingNeeds);
    _preferredFoodTypeController = TextEditingController(text: widget.pet?.preferredFoodType);
  _photoUrl = widget.pet?.photoUrl;
  // status not used currently
    _fetchBreeds();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _allergiesController.dispose();
    _medicalConditionsController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _dietTypeController.dispose();
    _feedingFrequencyController.dispose();
    _activityLevelController.dispose();
    _coatTypeController.dispose();
    _groomingNeedsController.dispose();
    _preferredFoodTypeController.dispose();
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
          'animal': _selectedAnimal,
          'breed': _selectedBreed,
          'breed_ref_id': _selectedBreedRefId,
          'breed_table': _breedTable,
          'age': _convertAgeRangeToYears(_selectedAgeRange ?? _ageRanges[0]),
          'allergies': _allergiesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
          'medical_conditions': _medicalConditionsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
          'weight_kg': double.tryParse(_weightController.text),
          'height_cm': double.tryParse(_heightController.text),
          'gender': _selectedGender,
          'diet_type': _dietTypeController.text.isNotEmpty ? _dietTypeController.text : null,
          'feeding_frequency': int.tryParse(_feedingFrequencyController.text),
          'activity_level': _activityLevelController.text.isNotEmpty ? _activityLevelController.text : null,
          'coat_type': _coatTypeController.text.isNotEmpty ? _coatTypeController.text : null,
          'grooming_needs': _groomingNeedsController.text.isNotEmpty ? _groomingNeedsController.text : null,
          'preferred_food_type': _preferredFoodTypeController.text.isNotEmpty ? _preferredFoodTypeController.text : null,
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
        Navigator.of(context).pop(true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save pet: $e')),
        );
      }
    }
  }

  Future<void> _uploadPetPhoto() async {
    if (widget.pet?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Save the pet first, then upload a photo.')),
      );
      return;
    }

    try {
      final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image == null) return;

      final ext = p.extension(image.path);
      final petId = widget.pet!.id!;
      final fileName = '$petId$ext';
      final fileBytes = await image.readAsBytes();
      final storagePath = 'pet_photos/$fileName';

      await Supabase.instance.client.storage
          .from('pets_bucket')
          .uploadBinary(storagePath, fileBytes, fileOptions: const FileOptions(upsert: true));

      final publicUrl = Supabase.instance.client.storage.from('pets_bucket').getPublicUrl(storagePath);
      await Supabase.instance.client.from('pets').update({'photo_url': publicUrl}).eq('id', petId);

      setState(() {
        _photoUrl = publicUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo uploaded successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading photo: $e')),
      );
    }
  }

  Future<void> _deletePetPhoto() async {
    if (widget.pet?.id == null || _photoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No photo to delete.')),
      );
      return;
    }

    try {
      final petId = widget.pet!.id!;
      // try to extract filename after 'pet_photos/'
      String? storagePath;
      final url = _photoUrl!;
      final idx = url.indexOf('pet_photos/');
      if (idx != -1) {
        final filename = url.substring(idx + 'pet_photos/'.length);
        storagePath = 'pet_photos/$filename';
      }

      if (storagePath != null) {
        await Supabase.instance.client.storage.from('pets_bucket').remove([storagePath]);
      }

      await Supabase.instance.client.from('pets').update({'photo_url': null}).eq('id', petId);

      setState(() => _photoUrl = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo deleted successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting photo: $e')),
      );
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
                                      // Photo upload / delete moved to Edit screen
                                      if (widget.pet?.id != null)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 12.0),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 30,
                                                backgroundImage: _photoUrl != null && (_photoUrl!.startsWith('http') || _photoUrl!.startsWith('https'))
                                                    ? NetworkImage(_photoUrl!) as ImageProvider
                                                    : const AssetImage('assets/images/logo.png') as ImageProvider,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    ElevatedButton.icon(
                                                      onPressed: _uploadPetPhoto,
                                                      icon: const Icon(Icons.photo_camera_outlined),
                                                      label: Text('Upload Photo', style: GoogleFonts.poppins()),
                                                    ),
                                                    if (_photoUrl != null)
                                                      TextButton.icon(
                                                        onPressed: _deletePetPhoto,
                                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                                        label: Text('Delete Photo', style: GoogleFonts.poppins(color: Colors.redAccent)),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 12.0),
                                          child: Text('Save the pet first to upload a photo.', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700])),
                                        ),
                                      // Pet Name
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
                                      // Animal Type
                                      DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        decoration: InputDecoration(
                                          labelText: 'Animal',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[200],
                                        ),
                                        value: _selectedAnimal,
                                        items: ['Dog', 'Cat']
                                            .map((animal) => DropdownMenuItem<String>(
                                                  value: animal,
                                                  child: Text(
                                                    animal,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: GoogleFonts.poppins(),
                                                  ),
                                                ))
                                            .toList(),
                                        onChanged: (v) => setState(() {
                                          _selectedAnimal = v;
                                          _selectedBreed = null;
                                          _selectedBreedRefId = null;
                                          if (v == 'Dog') {
                                            _breedTable = 'dogs_pet_data';
                                          } else if (v == 'Cat') {
                                            _breedTable = 'cats_pet_data';
                                          } else {
                                            _breedTable = null;
                                          }
                                        }),
                                        validator: (v) => v == null ? 'Please select an animal' : null,
                                      ),
                                      const SizedBox(height: 16),
                                      // Breed
                                      if (_isLoadingBreeds)
                                        const Center(child: CircularProgressIndicator())
                                      else
                                        DropdownButtonFormField<String>(
                                          isExpanded: true,
                                          decoration: InputDecoration(
                                            labelText: 'Breed',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[200],
                                          ),
                                          value: _selectedBreedRefId,
                                          items: _selectedAnimal == 'Dog'
                                              ? _dogBreeds
                                                  .map((b) => DropdownMenuItem<String>(
                                                        value: b.id,
                                                        child: Text(b.breedName, overflow: TextOverflow.ellipsis),
                                                      ))
                                                  .toList()
                                              : _catBreeds
                                                  .map((b) => DropdownMenuItem<String>(
                                                        value: b.id,
                                                        child: Text(b.breedName, overflow: TextOverflow.ellipsis),
                                                      ))
                                                  .toList(),
                                          onChanged: (v) => setState(() {
                                            _selectedBreedRefId = v;
                                            if (v != null) {
                                              if (_selectedAnimal == 'Dog') {
                                                _selectedBreed = _dogBreeds.firstWhere((b) => b.id == v).breedName;
                                              } else {
                                                _selectedBreed = _catBreeds.firstWhere((b) => b.id == v).breedName;
                                              }
                                            } else {
                                              _selectedBreed = null;
                                            }
                                          }),
                                          validator: (v) => v == null ? 'Please select a breed' : null,
                                        ),
                                      const SizedBox(height: 16),
                                      // Age
                                      DropdownButtonFormField<String>(
                                        isExpanded: true,
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
                                                  child: Text(age, overflow: TextOverflow.ellipsis),
                                                ))
                                            .toList(),
                                        onChanged: (v) => setState(() => _selectedAgeRange = v),
                                        validator: (v) => v == null ? 'Please select an age' : null,
                                      ),
                                      const SizedBox(height: 16),
                                      // Allergies
                                      TextFormField(
                                        controller: _allergiesController,
                                        decoration: InputDecoration(
                                          labelText: 'Allergies (comma-separated)',
                                          hintText: 'e.g., chicken, grain, pollen',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[200],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Medical Conditions
                                      TextFormField(
                                        controller: _medicalConditionsController,
                                        decoration: InputDecoration(
                                          labelText: 'Medical Conditions (comma-separated)',
                                          hintText: 'e.g., diabetes, arthritis, heart disease',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[200],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Weight
                                      TextFormField(
                                        controller: _weightController,
                                        decoration: InputDecoration(
                                          labelText: 'Weight (kg)',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[200],
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                                            return 'Please enter a valid number';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      // Height
                                      TextFormField(
                                        controller: _heightController,
                                        decoration: InputDecoration(
                                          labelText: 'Height (cm)',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[200],
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                                            return 'Please enter a valid number';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      // Gender
                                      DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        decoration: InputDecoration(
                                          labelText: 'Gender',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[200],
                                        ),
                                        value: _selectedGender,
                                        items: ['Male', 'Female']
                                            .map((g) => DropdownMenuItem<String>(
                                                  value: g,
                                                  child: Text(g, style: GoogleFonts.poppins()),
                                                ))
                                            .toList(),
                                        onChanged: (v) => setState(() => _selectedGender = v),
                                        validator: (v) => v == null ? 'Please select a gender' : null,
                                      ),
                                      const SizedBox(height: 16),
                                      // Diet Type
                                      TextFormField(
                                        controller: _dietTypeController,
                                        decoration: InputDecoration(
                                          labelText: 'Diet Type',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[200],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Feeding Frequency
                                      TextFormField(
                                        controller: _feedingFrequencyController,
                                        decoration: InputDecoration(
                                          labelText: 'Feeding Frequency (per day)',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[200],
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                      const SizedBox(height: 16),
                                      // Activity Level
                                      TextFormField(
                                        controller: _activityLevelController,
                                        decoration: InputDecoration(
                                          labelText: 'Activity Level',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[200],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Coat Type
                                      TextFormField(
                                        controller: _coatTypeController,
                                        decoration: InputDecoration(
                                          labelText: 'Coat Type',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[200],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Grooming Needs
                                      TextFormField(
                                        controller: _groomingNeedsController,
                                        decoration: InputDecoration(
                                          labelText: 'Grooming Needs',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[200],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Preferred Food Type
                                      TextFormField(
                                        controller: _preferredFoodTypeController,
                                        decoration: InputDecoration(
                                          labelText: 'Preferred Food Type',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[200],
                                        ),
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