import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/models/pet.dart';
import 'package:pet_connect_app/widgets/expandable_pet_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdoptionScreen extends StatefulWidget {
  static const routeName = '/adoption-screen';
  const AdoptionScreen({Key? key}) : super(key: key);

  @override
  State<AdoptionScreen> createState() => _AdoptionScreenState();
}

class _AdoptionScreenState extends State<AdoptionScreen> {
  List<Pet> _pets = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _userCity;
  String? _userState;

  @override
  void initState() {
    super.initState();
    _loadUserLocationAndFetchPets();
  }

  Future<void> _loadUserLocationAndFetchPets() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'Please login to view adoptable pets.';
        _isLoading = false;
      });
      return;
    }

    try {
      // Fetch user profile location
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('city, state')
          .eq('user_id', user.id)
          .maybeSingle();

      setState(() {
        _userCity = profile?['city'] as String?;
        _userState = profile?['state'] as String?;
      });

      await _fetchPetsForAdoption();
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load location: $e');
    }
  }

  Future<void> _fetchPetsForAdoption() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
        final petsQuery = Supabase.instance.client
        .from('pets')
        .select('*, profiles!inner(city, state, role)')
        .eq('status', 'Available for Adoption')
        .eq('profiles.role', 'Shelter'); // ✅ only shelter pets
      // Apply filters safely (Supabase .eq requires non-null values)
      if (_userCity != null && _userState != null) {
        petsQuery
          ..eq('profiles.city', _userCity!)
          ..eq('profiles.state', _userState!);
      } else if (_userState != null) {
        petsQuery.eq('profiles.state', _userState!);
      } else if (_userCity != null) {
        petsQuery.eq('profiles.city', _userCity!);
      }

      final response = await petsQuery.order('created_at', ascending: false);

      if (response != null) {
        _pets = (response as List)
            .map((json) => Pet.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        _pets = [];
      }
    } on PostgrestException catch (e) {
      setState(() => _errorMessage = 'Error fetching pets: ${e.message}');
    } catch (e) {
      setState(() => _errorMessage = 'Error fetching pets: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendAdoptionRequest(Pet pet) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to send requests.')));
      return;
    }

    if (pet.id == null || pet.ownerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Invalid pet or shelter information.')));
      return;
    }

    try {
      // 1️⃣ Insert into adoption_requests
      await Supabase.instance.client.from('adoption_requests').insert({
    'pet_id': pet.id,
    'requester_id': user.id,
    'shelter_owner_id': pet.ownerId,
    'status': 'Pending',
    });

      // 2️⃣ Insert in notifications table
      try {
        await Supabase.instance.client.from('notifications').insert({
          'recipient_id': pet.ownerId,
          'title': 'New Adoption Request',
          'body':
              'Someone is interested in adopting ${pet.name ?? 'your pet'}.',
          'type': 'adoption_request',
          'metadata': {'pet_id': pet.id, 'requester_id': user.id},
        });
      } catch (e) {
        debugPrint('Optional: failed to insert notification: $e');
      }

      // 3️⃣ Fetch shelter FCM token
      final shelterProfile = await Supabase.instance.client
          .from('profiles')
          .select('fcm_token')
          .eq('user_id', pet.ownerId!)
          .maybeSingle();

      final fcmToken = shelterProfile?['fcm_token'] as String?;
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await _sendPushNotification(
          token: fcmToken,
          title: '🐾 New Adoption Request',
          body: 'Someone wants to adopt ${pet.name ?? 'your pet'}!',
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adoption request sent successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to send request: $e')));
    }
  }

  /// ✅ Send push notification securely using Supabase Edge Function
  Future<void> _sendPushNotification({
    required String token,
    required String title,
    required String body,
  }) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'send_fcm',
        body: {
          'token': token,
          'title': title,
          'body': body,
          'data': {'type': 'adoption_request'},
        },
      );

      final data = response.data;
      if (data != null && data['success'] == true) {
        debugPrint('✅ Push notification sent successfully!');
      } else {
        debugPrint('⚠️ Failed to send push: $data');
      }
    } catch (e) {
      debugPrint('❌ Error invoking send_fcm function: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Adopt a Pet',
          style:
              GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: GoogleFonts.poppins(color: Colors.red)))
              : _pets.isEmpty
                  ? Center(
                      child: Text('No pets available in your area.',
                          style: GoogleFonts.poppins(fontSize: 16)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _pets.length,
                      itemBuilder: (context, index) {
                        final pet = _pets[index];
                        return Column(
                          children: [
                            ExpandablePetCard(
                              pet: pet,
                              onPetUpdated: _fetchPetsForAdoption,
                              onDeletePet: (_) {},
                              showActions: false,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.favorite_border),
                              label: const Text('I’m Interested'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(45),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => _sendAdoptionRequest(pet),
                            ),
                            const Divider(height: 30),
                          ],
                        );
                      },
                    ),
    );
  }
}
