import 'package:flutter/material.dart';
import 'package:pet_connect_app/models/cat_breed.dart';
import 'package:pet_connect_app/models/dog_breed.dart';
import 'package:pet_connect_app/services/breed_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  static const String routeName = '/add-pet';

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String? _selectedAnimal;
  int? _selectedBreedId;
  String? _selectedBreedName;
  String? _selectedAgeRange;

  bool _isLoadingBreeds = true;
  List<DogBreed> _dogBreeds = [];
  List<CatBreed> _catBreeds = [];
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      try {
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to add a pet')),
          );
          return;
        }

        final petData = {
          'name': _name,
          'breed': _selectedBreedName,
          'breed_id': _selectedBreedId,
          'age': _convertAgeRangeToYears(_selectedAgeRange!),
          'owner_id': currentUser.id,
          'animal': _selectedAnimal,
        };

        await Supabase.instance.client.from('pets').insert(petData);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet added successfully!'))
        );
        Navigator.of(context).pop(true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add pet: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a New Pet'),
        leading: const BackButton(),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Colors.blue.shade50,
              ],
            ),
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Pet Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Pet Name',
                          hintText: 'Enter your pet\'s name',
                          prefixIcon: const Icon(Icons.pets),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter a name.';
                          return null;
                        },
                        onSaved: (value) => _name = value!,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Type of Pet',
                          hintText: 'Select your pet type',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                        value: _selectedAnimal,
                        hint: const Text('Select Animal'),
                        isExpanded: true,
                        items: ['Dog', 'Cat'].map((animal) => DropdownMenuItem<String>(
                          value: animal,
                          child: Text(animal),
                        )).toList(),
                        onChanged: (newValue) => setState(() {
                          _selectedAnimal = newValue;
                          _selectedBreedId = null;
                          _selectedBreedName = null;
                        }),
                        validator: (value) => value == null ? 'Please select a pet type' : null,
                      ),
                      if (_selectedAnimal != null) const SizedBox(height: 16),
                      if (_selectedAnimal != null)
                        _isLoadingBreeds
                            ? const Center(child: CircularProgressIndicator())
                            : DropdownButtonFormField<int>(
                                decoration: InputDecoration(
                                  labelText: 'Breed',
                                  hintText: 'Select your pet\'s breed',
                                  prefixIcon: const Icon(Icons.pets_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                ),
                                value: _selectedBreedId,
                                hint: const Text('Select Breed'),
                                isExpanded: true,
                                items: _selectedAnimal == 'Dog'
                                    ? _dogBreeds.map((b) => DropdownMenuItem<int>(
                                        value: b.breedId,
                                        child: Text(b.breedName),
                                      )).toList()
                                    : _catBreeds.map((b) => DropdownMenuItem<int>(
                                        value: b.breedId,
                                        child: Text(b.breedName),
                                      )).toList(),
                                onChanged: (v) => setState(() {
                                  _selectedBreedId = v;
                                  if (v != null) {
                                    if (_selectedAnimal == 'Dog') {
                                      _selectedBreedName = _dogBreeds.firstWhere((b) => b.breedId == v).breedName;
                                    } else {
                                      _selectedBreedName = _catBreeds.firstWhere((b) => b.breedId == v).breedName;
                                    }
                                  }
                                }),
                                validator: (v) => v == null ? 'Please select a breed' : null,
                              ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Age Range',
                          hintText: 'Select your pet\'s age range',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                        value: _selectedAgeRange,
                        hint: const Text('Select Age Range'),
                        isExpanded: true,
                        items: _ageRanges.map((age) => DropdownMenuItem<String>(
                          value: age,
                          child: Text(
                            age,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )).toList(),
                        onChanged: (v) => setState(() => _selectedAgeRange = v),
                        validator: (v) => v == null ? 'Please select an age range' : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saveForm,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 15,
                            ),
                            elevation: 2,
                          ),
                          icon: const Icon(Icons.pets),
                          label: const Text(
                            'Add Pet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
