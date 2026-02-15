// lib/screens/manage_pets_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pet_connect_app/models/pet.dart';
import 'package:pet_connect_app/screens/add_edit_pet_screen.dart';
import 'package:pet_connect_app/theme/app_theme.dart';
import 'package:pet_connect_app/widgets/expandable_pet_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManagePetsScreen extends StatefulWidget {
  static const routeName = '/manage-pets';
  const ManagePetsScreen({super.key});

  @override
  State<ManagePetsScreen> createState() => _ManagePetsScreenState();
}

class _ManagePetsScreenState extends State<ManagePetsScreen> {
  bool _isLoading = true;
  List<Pet> _pets = [];
  

  @override
  void initState() {
    super.initState();
    _fetchPets();
  }

  Future<void> _fetchPets() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('pets')
            .select()
            .eq('owner_id', user.id)
            .order('created_at', ascending: false);
        setState(() {
          _pets = (response as List).map((d) => Pet.fromJson(d as Map<String, dynamic>)).toList();
        });
      }
    } catch (e) {
      _showSnackBar('Failed to load pets: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePet(String petId) async {
    try {
      await Supabase.instance.client.from('pets').delete().eq('id', petId);
      await _fetchPets();
      _showSnackBar('Pet deleted successfully!');
    } catch (e) {
      _showSnackBar('Failed to delete pet: $e');
    }
  }

  void _showDeleteConfirmationDialog(String petId) {
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
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _deletePet(petId);
            },
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showPetForm(BuildContext context, Pet? pet) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddEditPetScreen(pet: pet)),
    );
    if (result == true) _fetchPets();
  }

  

  // Upload CSV (uses file_picker)
  Future<void> _uploadCSV() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.single.path;
      if (filePath == null) return;

      final csvData = await File(filePath).readAsString();
      final rows = csvData.split('\n').map((line) => line.split(',')).toList();

      if (rows.isEmpty) {
        _showSnackBar('CSV is empty.');
        return;
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final columns = rows.first.map((e) => e.toString()).toList();
      final petsData = rows.skip(1).map((row) {
        final map = <String, dynamic>{};
        for (var i = 0; i < columns.length; i++) {
          map[columns[i]] = row.length > i ? row[i] : null;
        }
        map['owner_id'] = user.id;
        return map;
      }).toList();

      // insert in batches to avoid payload issues
      const batch = 50;
      for (var i = 0; i < petsData.length; i += batch) {
        final end = (i + batch < petsData.length) ? i + batch : petsData.length;
        final chunk = petsData.sublist(i, end);
        await Supabase.instance.client.from('pets').insert(chunk);
      }

      await _fetchPets();
      _showSnackBar('CSV uploaded successfully!');
    } catch (e) {
      _showSnackBar('Error uploading CSV: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(message, style: GoogleFonts.poppins()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Pets', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        leading: const BackButton(),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        elevation: 1,
        actions: [
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'add') _showPetForm(context, null);
              if (value == 'upload_csv') _uploadCSV();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'add',
                child: Row(children: [const Icon(Icons.add), const SizedBox(width: 8), Text('Add Pet', style: GoogleFonts.poppins())]),
              ),
              PopupMenuItem(
                value: 'upload_csv',
                child: Row(children: [const Icon(Icons.upload_file), const SizedBox(width: 8), Text('Upload CSV', style: GoogleFonts.poppins())]),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPetForm(context, null),
        icon: const Icon(Icons.add),
        label: Text('Add Pet', style: GoogleFonts.poppins()),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _pets.isEmpty
                ? Center(child: Text('No pets added yet.', style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600])))
                : RefreshIndicator(
                    onRefresh: _fetchPets,
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      itemCount: _pets.length,
                      itemBuilder: (context, index) {
                        final pet = _pets[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Material(
                              elevation: 2,
                              color: Colors.white,
                              child: ExpandablePetCard(
                                pet: pet,
                                onPetUpdated: _fetchPets,
                                onDeletePet: (id) => _showDeleteConfirmationDialog(id),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
