import 'package:flutter/material.dart';
import 'package:pet_connect_app/models/animal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnimalDetailsScreen extends StatefulWidget {
  static const String routeName = '/animal-details';

  final Animal animal;

  const AnimalDetailsScreen({super.key, required this.animal});

  @override
  State<AnimalDetailsScreen> createState() => _AnimalDetailsScreenState();
}

class _AnimalDetailsScreenState extends State<AnimalDetailsScreen> {
  String? _shelterName;

  @override
  void initState() {
    super.initState();
    _fetchShelterDetails();
  }

  Future<void> _fetchShelterDetails() async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('user_id', widget.animal.shelterId)
          .single();
      setState(() {
        _shelterName = response['full_name'] as String;
      });
    } catch (e) {
      print('Error fetching shelter details: $e');
      setState(() {
        _shelterName = 'Unknown Shelter';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.animal.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.animal.photoUrl != null)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    widget.animal.photoUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              widget.animal.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Type: ${widget.animal.type}',
              style: const TextStyle(fontSize: 18),
            ),
            if (widget.animal.breed != null)
              Text(
                'Breed: ${widget.animal.breed}',
                style: const TextStyle(fontSize: 18),
              ),
            if (widget.animal.age != null)
              Text(
                'Age: ${widget.animal.age} years',
                style: const TextStyle(fontSize: 18),
              ),
            if (widget.animal.gender != null)
              Text(
                'Gender: ${widget.animal.gender}',
                style: const TextStyle(fontSize: 18),
              ),
            const SizedBox(height: 20),
            const Text(
              'Description:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              widget.animal.description ?? 'No description provided.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'Shelter Information:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            if (_shelterName != null)
              Text(
                'Name: $_shelterName',
                style: const TextStyle(fontSize: 16),
              )
            else
              const Text(
                'Name: Loading...',
                style: TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement contact shelter functionality (e.g., call, email, chat)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contact Shelter functionality not yet implemented.')),
                  );
                },
                child: const Text('Contact Shelter'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
