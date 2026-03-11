import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/models/cat_breed.dart';
import 'package:pet_connect_app/models/dog_breed.dart';
import 'package:pet_connect_app/models/pet.dart';
import 'package:pet_connect_app/services/breed_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_connect_app/theme/app_theme.dart';

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

  Future<void> _deletePet() async {
    try {
      if (widget.pet?.id != null) {
        await Supabase.instance.client.from('pets').delete().eq('id', widget.pet!.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet deleted successfully!')),
        );
        Navigator.of(context).pop(true); // Return back simulating an update loop trigger
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete pet: $e')),
      );
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Confirm Deletion', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Do you want to permanently delete this pet?', style: GoogleFonts.poppins()),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[700])),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _deletePet();
            },
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
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

  Widget _buildTextField(TextEditingController controller, String label, String hint, {TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        validator: label == 'Name' ? (v) => v!.isEmpty ? 'Please enter a name' : null : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          fillColor: Colors.grey[50], // Soft fill
          filled: true,
          labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
          hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required String label,
    required void Function(T?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<T>(
        isExpanded: true,
        value: value,
        items: items,
        onChanged: onChanged,
        validator: (v) => v == null ? 'Please select $label' : null,
        decoration: InputDecoration(
          labelText: label,
          fillColor: Colors.grey[50], 
          filled: true,
          labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHead(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.pet == null ? 'Add Pet' : 'Edit Pet',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo Upload Centerpiece
              Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).primaryColor.withOpacity(0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ],
                            image: DecorationImage(
                              image: _photoUrl != null &&
                                      (_photoUrl!.startsWith('http') ||
                                          _photoUrl!.startsWith('https'))
                                  ? NetworkImage(_photoUrl!) as ImageProvider
                                  : const AssetImage('assets/images/logo.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _uploadPetPhoto,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              child: const Icon(Icons.camera_alt,
                                  size: 20, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (widget.pet == null)
                      Text('Save the pet first to upload a photo.',
                          style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 13))
                    else if (_photoUrl != null)
                      TextButton.icon(
                        onPressed: _deletePetPhoto,
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: Text('Remove Photo', style: GoogleFonts.poppins()),
                        style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                      ),
                  ],
                ),
              ),

              // Basic Information Section
              _buildCard(
                children: [
                  _buildSectionHead('Core Details'),
                  _buildTextField(_nameController, 'Name', 'Enter pet\'s name'),
                  _buildDropdown<String>(
                    label: 'Animal',
                    value: _selectedAnimal,
                    items: ['Dog', 'Cat'].map((animal) => DropdownMenuItem<String>(
                      value: animal,
                      child: Text(animal, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins()),
                    )).toList(),
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
                  ),
                  if (_isLoadingBreeds)
                    const Center(child: Padding(
                      padding: EdgeInsets.only(bottom: 16.0),
                      child: CircularProgressIndicator(),
                    ))
                  else
                    _buildDropdown<String>(
                      label: 'Breed',
                      value: _selectedBreedRefId,
                      items: _selectedAnimal == 'Dog'
                          ? _dogBreeds.map((b) => DropdownMenuItem<String>(
                                value: b.id,
                                child: Text(b.breedName, overflow: TextOverflow.ellipsis),
                              )).toList()
                          : _catBreeds.map((b) => DropdownMenuItem<String>(
                                value: b.id,
                                child: Text(b.breedName, overflow: TextOverflow.ellipsis),
                              )).toList(),
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
                    ),
                  _buildDropdown<String>(
                    label: 'Age',
                    value: _selectedAgeRange,
                    items: _ageRanges.map((age) => DropdownMenuItem<String>(
                      value: age,
                      child: Text(age, overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedAgeRange = v),
                  ),
                  _buildDropdown<String>(
                    label: 'Gender',
                    value: _selectedGender,
                    items: ['Male', 'Female'].map((g) => DropdownMenuItem<String>(
                      value: g,
                      child: Text(g, style: GoogleFonts.poppins()),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedGender = v),
                  ),
                ],
              ),

              // Health & Physical Profile
              _buildCard(
                children: [
                  _buildSectionHead('Health & Medical'),
                  _buildTextField(_weightController, 'Weight (kg)', 'e.g. 15', type: TextInputType.number),
                  _buildTextField(_heightController, 'Height (cm)', 'e.g. 40', type: TextInputType.number),
                  _buildTextField(_allergiesController, 'Allergies', 'e.g. pollen, chicken (comma-separated)'),
                  _buildTextField(_medicalConditionsController, 'Medical Conditions', 'e.g. arthritis (comma-separated)'),
                ],
              ),

              // Diet & Lifestyle
              _buildCard(
                children: [
                  _buildSectionHead('Daily Needs'),
                  _buildTextField(_activityLevelController, 'Activity Level', 'e.g. High, Moderate'),
                  _buildTextField(_dietTypeController, 'Diet Type', 'e.g. Dry kibble, Raw'),
                  _buildTextField(_feedingFrequencyController, 'Feeding Frequency (per day)', 'e.g. 2', type: TextInputType.number),
                  _buildTextField(_preferredFoodTypeController, 'Preferred Food', 'e.g. Chicken based'),
                  _buildTextField(_coatTypeController, 'Coat Type', 'e.g. Short, Curly'),
                  _buildTextField(_groomingNeedsController, 'Grooming Needs', 'e.g. Weekly brushing'),
                ],
              ),

              const SizedBox(height: 12),
              
              ElevatedButton(
                onPressed: _savePet,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text('Save Pet Profile', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              
              if (widget.pet != null) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _showDeleteConfirmationDialog,
                  icon: const Icon(Icons.delete_forever),
                  label: Text('Delete Pet', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}