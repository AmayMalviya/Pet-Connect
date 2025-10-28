import 'package:flutter/material.dart';
import 'package:pet_connect_app/models/pet.dart';
import 'package:pet_connect_app/screens/add_edit_pet_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PetProfileScreen extends StatelessWidget {
  const PetProfileScreen({super.key, required this.pet});

  final Pet pet;

  static const String routeName = '/pet-profile';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pet.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddEditPetScreen(pet: pet),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Delete Pet'),
                    content: const Text('Are you sure you want to delete this pet?'),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text('Delete'),
                        onPressed: () async {
                          try {
                            await Supabase.instance.client
                                .from('pets')
                                .delete()
                                .eq('id', pet.id!);
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to delete pet: $e')),
                            );
                          }
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(radius: 80, backgroundImage: AssetImage('assets/images/logo.png')),
            const SizedBox(height: 20),
            Text(
              pet.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(pet.breed, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}