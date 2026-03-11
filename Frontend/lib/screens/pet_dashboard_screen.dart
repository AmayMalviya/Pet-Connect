import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/models/pet.dart';
import 'package:pet_connect_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_connect_app/screens/pet_info_detail_screen.dart';

class PetDashboardScreen extends StatefulWidget {
  final Pet pet;

  const PetDashboardScreen({super.key, required this.pet});

  @override
  State<PetDashboardScreen> createState() => _PetDashboardScreenState();
}

class _PetDashboardScreenState extends State<PetDashboardScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _breedInfo = {};

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
          _breedInfo = response ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load info: $e';
          _isLoading = false;
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
        title: Text('${pet.name}\'s Dashboard', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: isNetworkUrl
                                  ? NetworkImage(pet.photoUrl!)
                                  : const AssetImage('assets/images/logo.png') as ImageProvider,
                              backgroundColor: Colors.white,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              pet.name ?? 'Unknown Pet',
                              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                            Text(
                              pet.breed ?? 'Mixed Breed',
                              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Care Requirements',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.9,
                        children: [
                          _CareCategoryCard(
                            title: 'Grooming Tools & Needs',
                            icon: Icons.cut,
                            color: const Color(0xFFFFB4A2), // Soft pastel coral
                            onTap: () => _openDetail('Grooming', _formatData(_breedInfo['grooming_needs'])),
                          ),
                          _CareCategoryCard(
                            title: 'Diet & Nutrition',
                            icon: Icons.restaurant,
                            color: const Color(0xFFB5EAD7), // Soft pastel green
                            onTap: () => _openDetail('Diet & Nutrition', _formatData(_breedInfo['diet'])),
                          ),
                          _CareCategoryCard(
                            title: 'Training Tips',
                            icon: Icons.school,
                            color: const Color(0xFFC7CEEA), // Soft pastel blue
                            onTap: () => _openDetail('Training Tips', _formatData(_breedInfo['training_tips'])),
                          ),
                          _CareCategoryCard(
                            title: 'Exercise Needs',
                            icon: Icons.directions_run,
                            color: const Color(0xFFFFE1A8), // Soft pastel yellow
                            onTap: () => _openDetail('Exercise Needs', _formatData(_breedInfo['exercise_needs'])),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  void _openDetail(String title, String content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetInfoDetailScreen(title: title, content: content),
      ),
    );
  }
}

class _CareCategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CareCategoryCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color,
              child: Icon(icon, size: 30, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
