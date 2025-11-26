import 'package:flutter/material.dart';
import 'package:pet_connect_app/models/pet.dart';
import 'package:pet_connect_app/screens/health_details_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class AdoptionPetDetailsScreen extends StatefulWidget {
  static const String routeName = '/adoption-pet-details';

  final Pet pet;

  const AdoptionPetDetailsScreen({super.key, required this.pet});

  @override
  State<AdoptionPetDetailsScreen> createState() => _AdoptionPetDetailsScreenState();
}

class _AdoptionPetDetailsScreenState extends State<AdoptionPetDetailsScreen> {
  String? _shelterName;
  String? _shelterAddress;
  String? _shelterPhone;

  @override
  void initState() {
    super.initState();
    if (widget.pet.ownerId != null) {
      _fetchShelterDetails();
    }
  }

  Future<void> _fetchShelterDetails() async {
    if (widget.pet.ownerId == null) return;
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('full_name, address, phone')
          .eq('user_id', widget.pet.ownerId!)
          .single();
      if (mounted) {
        setState(() {
          _shelterName = response['full_name'] as String?;
          _shelterAddress = response['address'] as String?;
          _shelterPhone = response['phone'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Error fetching shelter details: $e');
      if (mounted) {
        setState(() {
          _shelterName = 'Unknown Shelter';
        });
      }
    }
  }

  Future<void> _sendAdoptionRequest() async {
    if (widget.pet.id == null || widget.pet.ownerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot send request: Missing pet or owner information.')),
      );
      return;
    }
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client.from('adoption_requests').insert({
        'pet_id': widget.pet.id,
        'requester_id': userId,
        'shelter_owner_id': widget.pet.ownerId,
        'status': 'Pending',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Adoption request sent successfully!')),
        );
      }
    } catch (e) {
      debugPrint('Error sending adoption request: $e');
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
                Text('Pet Name: ${widget.pet.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Breed: ${widget.pet.breed ?? 'N/A'}'),
                Text('Age: ${widget.pet.age ?? 'N/A'} years'),
                const Divider(height: 20),
                const Text('Shelter Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Name: ${_shelterName ?? 'Loading...'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Address: ${_shelterAddress ?? 'N/A'}'),
                Text('Phone: ${_shelterPhone ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Divider(height: 20),
                const Text('A notification will be sent to the shelter to review your request.'),
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
        title: Text(widget.pet.name ?? 'Unknown Pet'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.pet.photoUrl != null)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    widget.pet.photoUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              widget.pet.name ?? 'Unknown Pet',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Type: ${widget.pet.animal}',
              style: const TextStyle(fontSize: 18),
            ),
            if (widget.pet.breed != null)
              Text(
                'Breed: ${widget.pet.breed}',
                style: const TextStyle(fontSize: 18),
              ),
            if (widget.pet.age != null)
              Text(
                'Age: ${widget.pet.age} years',
                style: const TextStyle(fontSize: 18),
              ),
            if (widget.pet.gender != null)
              Text(
                'Gender: ${widget.pet.gender}',
                style: const TextStyle(fontSize: 18),
              ),
            const SizedBox(height: 20),
            const Text(
              'Description:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              widget.pet.description ?? 'No description provided.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text('Health Calendar',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 1,
              ),
              onPressed: () {
                if (widget.pet.id != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          HealthDetailsScreen(petId: widget.pet.id!),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Shelter Information:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            if (_shelterName != null)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.store, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            _shelterName ?? 'Loading...',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_shelterAddress != null)
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _shelterAddress!,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      if (_shelterPhone != null)
                        Row(
                          children: [
                            Icon(Icons.phone, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              _shelterPhone!,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              )
            else
              const Center(child: CircularProgressIndicator()),
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
