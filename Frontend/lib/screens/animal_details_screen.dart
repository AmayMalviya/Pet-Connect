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
  String? _shelterAddress;
  String? _shelterPhone;

  @override
  void initState() {
    super.initState();
    _fetchShelterDetails();
  }

  Future<void> _fetchShelterDetails() async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('full_name, address, phone')
          .eq('user_id', widget.animal.userId)
          .single();
      if (mounted) {
        setState(() {
          _shelterName = response['full_name'] as String?;
          _shelterAddress = response['address'] as String?;
          _shelterPhone = response['phone'] as String?;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _shelterName = 'Unknown Shelter';
        });
      }
    }
  }

  Future<void> _sendAdoptionRequest() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client.from('adoption_requests').insert({
        'pet_id': widget.animal.id,
        'user_id': userId,
        'shelter_id': widget.animal.userId,
        'status': 'pending',
        'message': 'Request !',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Adoption request sent successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send adoption request.')),
        );
      }
    }
  }

  void _showAdoptionInterestDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Adoption Interest'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('You are expressing interest in adopting:'),
                const SizedBox(height: 10),
                Text('Pet Name: ${widget.animal.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Breed: ${widget.animal.breed ?? 'N/A'}'),
                Text('Age: ${widget.animal.age ?? 'N/A'} years'),
                const Divider(height: 20),
                const Text('Shelter Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Name: ${_shelterName ?? 'Loading...'}'),
                Text('Address: ${_shelterAddress ?? 'N/A'}'),
                Text('Phone: ${_shelterPhone ?? 'N/A'}'),
                const Divider(height: 20),
                const Text('A "Request !" notification will be sent to the shelter.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop();
                _sendAdoptionRequest();
              },
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Name: $_shelterName',
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (_shelterAddress != null)
                    Text(
                      'Address: $_shelterAddress',
                      style: const TextStyle(fontSize: 16),
                    ),
                  if (_shelterPhone != null)
                    Text(
                      'Phone: $_shelterPhone',
                      style: const TextStyle(fontSize: 16),
                    ),
                ],
              )
            else
              const Text(
                'Name: Loading...',
                style: TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _showAdoptionInterestDialog,
                child: const Text('I am interested'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
