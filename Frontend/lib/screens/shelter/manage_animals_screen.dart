import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_connect_app/models/animal.dart';
import 'package:pet_connect_app/screens/shelter/add_edit_animal_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/theme/app_theme.dart';

class ManageAnimalsScreen extends StatefulWidget {
  static const String routeName = '/manage-animals';

  const ManageAnimalsScreen({super.key});

  @override
  State<ManageAnimalsScreen> createState() => _ManageAnimalsScreenState();
}

class _ManageAnimalsScreenState extends State<ManageAnimalsScreen> {
  late final Stream<List<Animal>> _animalsStream;

  @override
  void initState() {
    super.initState();
    _animalsStream = _getAnimalsStream();
  }

  Stream<List<Animal>> _getAnimalsStream() {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      return Stream.value([]);
    }

    return supabase
        .from('animals_for_adoption')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((maps) => maps.map((map) => Animal.fromJson(map)).toList());
  }

  void _deleteAnimal(String animalId) async {
    try {
      await Supabase.instance.client.from('animals_for_adoption').delete().eq('id', animalId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Animal deleted successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting animal: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showDeleteConfirmationDialog(Animal animal) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Animal'),
          content: Text('Are you sure you want to delete ${animal.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteAnimal(animal.id);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Animals for Adoption', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        elevation: 1,
      ),
      body: StreamBuilder<List<Animal>>(
        stream: _animalsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No animals listed for adoption yet.'));
          }

          final animals = snapshot.data!;

          return ListView.builder(
            itemCount: animals.length,
            itemBuilder: (context, index) {
              final animal = animals[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ListTile(
                  leading: animal.photoUrl != null
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(animal.photoUrl!),
                        )
                      : const CircleAvatar(child: Icon(Icons.pets)),
                  title: Text(animal.name),
                  subtitle: Text('${animal.type} - ${animal.breed ?? 'Unknown'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AddEditAnimalScreen.routeName,
                            arguments: animal,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _showDeleteConfirmationDialog(animal);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AddEditAnimalScreen.routeName);
        },
        label: const Text('Add Animal'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
