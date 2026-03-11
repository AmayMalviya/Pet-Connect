import 'package:flutter/material.dart';
import 'package:pet_connect_app/models/pet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
          .select('first_name, last_name, phone, city, state, country')
          .eq('user_id', widget.pet.ownerId!)
          .single();
      if (mounted) {
        setState(() {
          final firstName = response['first_name'] as String?;
          final lastName = response['last_name'] as String?;
          _shelterName = [firstName, lastName].where((n) => n != null).join(' ');
          final city = response['city'] as String?;
          final state = response['state'] as String?;
          final country = response['country'] as String?;
          _shelterAddress = [city, state, country].where((a) => a != null && a.isNotEmpty).join(', ');
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

  Future<void> _sendAdoptionRequest(String message) async {
    if (widget.pet.id == null || widget.pet.ownerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot send request: Missing pet or owner information.')),
      );
      return;
    }
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // Fetch the requester's name for the notification
      final requesterProfile = await Supabase.instance.client
          .from('profiles')
          .select('first_name, last_name')
          .eq('user_id', userId)
          .maybeSingle();
      final requesterName = [
        requesterProfile?['first_name'] as String?,
        requesterProfile?['last_name'] as String?,
      ].where((n) => n != null && n.isNotEmpty).join(' ');

      await Supabase.instance.client.from('adoption_requests').insert({
        'pet_id': widget.pet.id,
        'requester_id': userId,
        'shelter_owner_id': widget.pet.ownerId,
        'status': 'Pending',
        'message': message.isNotEmpty ? message : null, // Save the custom message
      });

      // Insert into notifications table
      try {
        await Supabase.instance.client.from('notifications').insert({
          'recipient_id': widget.pet.ownerId,
          'title': 'New Adoption Interest',
          'body': '${requesterName.isNotEmpty ? requesterName : 'Someone'} is interested in adopting ${widget.pet.name ?? 'your pet'}.',
          'type': 'adoption',
        });
      } catch (dbErr) {
        debugPrint('Error inserting notification to DB: $dbErr');
      }

      // Notify shelter via FCM (non-fatal)
      try {
        final shelterProfile = await Supabase.instance.client
            .from('profiles')
            .select('fcm_token')
            .eq('user_id', widget.pet.ownerId!)
            .maybeSingle();
        final shelterToken = shelterProfile?['fcm_token'] as String?;
        if (shelterToken != null && shelterToken.isNotEmpty) {
          await Supabase.instance.client.functions.invoke(
            'send_fcm',
            body: {
              'token': shelterToken,
              'title': '🐾 New Adoption Interest!',
              'body': '${requesterName.isNotEmpty ? requesterName : 'Someone'} is interested in adopting ${widget.pet.name ?? 'your pet'}.'
            },
          );
        }
      } catch (fcmErr) {
        debugPrint('FCM notification error (non-fatal): $fcmErr');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Adoption request sent! The shelter has been notified.')),
        );
        Navigator.of(context).pop();
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
    final TextEditingController messageController = TextEditingController();

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
                const Text('Message to Shelter (Optional):', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Tell the shelter why you\'d be a great match...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                const Text('A notification will be sent to the shelter to review your request.', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                _sendAdoptionRequest(messageController.text.trim());
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
                      if (_shelterAddress != null && _shelterAddress!.isNotEmpty)
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
