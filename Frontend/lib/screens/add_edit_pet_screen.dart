
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddEditPetScreen extends StatefulWidget {
  static const routeName = '/add-edit-pet';
  final DocumentSnapshot? pet;

  const AddEditPetScreen({super.key, this.pet});

  @override
  State<AddEditPetScreen> createState() => _AddEditPetScreenState();
}

class _AddEditPetScreenState extends State<AddEditPetScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _breedController;
  late TextEditingController _ageController;
  late TextEditingController _descriptionController;
  String _status = 'Available';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pet?['name']);
    _breedController = TextEditingController(text: widget.pet?['breed']);
    _ageController = TextEditingController(text: widget.pet?['age'].toString());
    _descriptionController = TextEditingController(text: widget.pet?['description']);
    if (widget.pet != null) {
      _status = widget.pet!['status'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _savePet() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final petData = {
            'name': _nameController.text,
            'breed': _breedController.text,
            'age': int.parse(_ageController.text),
            'description': _descriptionController.text,
            'status': _status,
          };

          if (widget.pet == null) {
            // Add new pet
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('pets')
                .add(petData);
          } else {
            // Update existing pet
            await widget.pet!.reference.update(petData);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pet saved successfully!')),
          );
          Navigator.of(context).pop();
        }
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
        title: Text(widget.pet == null ? 'Add Pet' : 'Edit Pet', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _breedController,
                decoration: const InputDecoration(labelText: 'Breed'),
                validator: (value) => value!.isEmpty ? 'Please enter a breed' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Please enter an age' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: ['Available', 'Pending Adoption', 'Adopted']
                    .map((label) => DropdownMenuItem(
                          child: Text(label),
                          value: label,
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _status = value!;
                  });
                },
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _savePet,
                child: const Text('Save Pet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
