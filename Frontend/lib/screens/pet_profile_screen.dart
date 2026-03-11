import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/models/pet.dart';
import 'package:pet_connect_app/screens/add_edit_pet_screen.dart';
import 'package:pet_connect_app/screens/pet_info_detail_screen.dart';
import 'package:pet_connect_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PetProfileScreen extends StatefulWidget {
  const PetProfileScreen({super.key, required this.pet});

  final Pet pet;

  static const String routeName = '/pet-profile';

  @override
  State<PetProfileScreen> createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> {
  Map<String, dynamic>? _breedInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBreedInfo();
  }

  Future<void> _fetchBreedInfo() async {
    try {
      final response = await Supabase.instance.client
          .from('pet_breed_info')
          .select()
          .eq('pet_id', widget.pet.id!)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _breedInfo = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Don't call ScaffoldMessenger inside initState async flow — set error in state
      if (mounted) {
        setState(() {
          _breedInfo = null;
          _isLoading = false;
        });
        // Show snackbar in next frame when widget tree is stable
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to fetch pet details: $e')),
            );
          }
        });
      }
    }
  }

  String _formatData(dynamic data) {
    if (data == null) return 'No information available.';
    if (data is String) return data;
    if (data is Map) return data.entries.map((e) => '${e.key}: ${e.value}').join('\n');
    return data.toString();
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    final isNetworkUrl = pet.photoUrl != null &&
        (pet.photoUrl!.startsWith('http') || pet.photoUrl!.startsWith('https'));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(pet.name ?? 'Pet Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => AddEditPetScreen(pet: widget.pet)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext ctx) {
                  return AlertDialog(
                    title: const Text('Delete Pet'),
                    content: const Text('Are you sure you want to delete this pet?'),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                      TextButton(
                        child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                        onPressed: () async {
                          try {
                            await Supabase.instance.client.from('pets').delete().eq('id', widget.pet.id!);
                            if (context.mounted) {
                              Navigator.of(context).pop(); // close dialog
                              Navigator.of(context).pop(); // go back
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to delete pet: $e')),
                              );
                            }
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _breedInfo == null
              ? const Center(child: Text('Pet info not found.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Pet avatar + name header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary.withOpacity(0.85), AppColors.primary.withOpacity(0.55)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.25),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 55,
                              backgroundColor: Colors.white,
                              backgroundImage: isNetworkUrl
                                  ? NetworkImage(pet.photoUrl!)
                                  : const AssetImage('assets/images/logo.png') as ImageProvider,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _breedInfo!['name'] ?? pet.name ?? 'Unknown Pet',
                              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Text(
                              _breedInfo!['breed'] ?? pet.breed ?? 'Mixed Breed',
                              style: GoogleFonts.poppins(fontSize: 15, color: Colors.white70),
                            ),
                            if (_breedInfo!['age'] != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                '${_breedInfo!['age']} years old',
                                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white60),
                              ),
                            ]
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Pet Statistics',
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Premium Metric Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          _buildMetricCard('Breed', _breedInfo!['breed_name'] ?? pet.breed ?? 'N/A', Icons.pets, Colors.orangeAccent),
                          _buildMetricCard('Weight', pet.weightKg != null ? '${pet.weightKg} kg' : 'N/A', Icons.scale, Colors.blueAccent),
                          _buildMetricCard('Gender', pet.gender ?? 'N/A', Icons.transgender, Colors.purpleAccent),
                          _buildMetricCard('Energy', _breedInfo!['energy_level']?.toString() ?? pet.activityLevel ?? 'N/A', Icons.bolt, Colors.amber),
                          _buildMetricCard('Diet', _breedInfo!['diet'] ?? pet.dietType ?? 'N/A', Icons.restaurant, Colors.green),
                          _buildMetricCard('Status', (pet.isNeutered == true ? 'Neutered\n' : '') + (pet.isMicrochipped == true ? 'Microchipped' : ''), Icons.health_and_safety, Colors.pinkAccent),
                        ],
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    if (value.isEmpty) value = 'N/A';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }
}