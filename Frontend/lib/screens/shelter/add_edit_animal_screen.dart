import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_connect_app/models/animal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/theme/app_theme.dart';

class AddEditAnimalScreen extends StatefulWidget {
  static const String routeName = '/add-edit-animal';

  final Animal? animal; // Animal to edit, if any

  const AddEditAnimalScreen({super.key, this.animal});

  @override
  State<AddEditAnimalScreen> createState() => _AddEditAnimalScreenState();
}

class _AddEditAnimalScreenState extends State<AddEditAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedType;
  String? _selectedGender;
  File? _imageFile;
  String? _imageUrl; // Existing image URL for editing

  bool get _isEditing => widget.animal != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.animal!.name;
      _breedController.text = widget.animal!.breed ?? '';
      _ageController.text = widget.animal!.age?.toString() ?? '';
      _descriptionController.text = widget.animal!.description ?? '';
      _selectedType = widget.animal!.type;
      _selectedGender = widget.animal!.gender;
      _imageUrl = widget.animal!.photoUrl;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _imageUrl; // No new image, return existing URL

    final supabase = Supabase.instance.client;
    final fileName = '${supabase.auth.currentUser!.id}/${DateTime.now().millisecondsSinceEpoch}.png';
    final storagePath = 'animal_photos/$fileName';

    try {
      await supabase.storage.from('pet-pictures').upload(
            storagePath,
            _imageFile!,
            fileOptions: const FileOptions(upsert: true),
          );
      return supabase.storage.from('pet-pictures').getPublicUrl(storagePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e'), backgroundColor: Colors.red),
      );
      return null;
    }
  }

  Future<void> _saveAnimal() async {
    if (_formKey.currentState!.validate()) {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) return;

      setState(() {
        // Show loading indicator
      });

      final photoUrl = await _uploadImage();
      if (_imageFile != null && photoUrl == null) {
        // Image upload failed, don't proceed with saving animal
        return;
      }

      final data = {
        'user_id': userId,
        'name': _nameController.text,
        'type': _selectedType,
        'breed': _breedController.text.isEmpty ? null : _breedController.text,
        'age': int.tryParse(_ageController.text),
        'gender': _selectedGender,
        'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
        'photo_url': photoUrl,
        'status': 'Available', // Default status
      };

      try {
        if (_isEditing) {
          await supabase.from('animals_for_adoption').update(data).eq('id', widget.animal!.id);
        } else {
          await supabase.from('animals_for_adoption').insert(data);
        }
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving animal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Animal' : 'Add Animal', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        leading: const BackButton(),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : (_imageUrl != null ? NetworkImage(_imageUrl!) as ImageProvider : null),
                  child: _imageFile == null && _imageUrl == null
                      ? const Icon(Icons.camera_alt, size: 40)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const ['Dog', 'Cat'].map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedType = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _breedController,
                decoration: const InputDecoration(labelText: 'Breed (Optional)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age (Years, Optional)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const ['Male', 'Female', 'Unknown'].map((String gender) {
                  return DropdownMenuItem<String>(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedGender = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a gender';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description (Optional)'),
                maxLines: 5,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveAnimal,
                child: Text(_isEditing ? 'Save Changes' : 'Add Animal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
