import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/models/pet.dart';
import 'package:pet_connect_app/screens/add_edit_pet_screen.dart';
import 'package:pet_connect_app/screens/health_details_screen.dart';

class ExpandablePetCard extends StatefulWidget {
  final Pet pet;
  final VoidCallback onPetUpdated;
  final Function(String) onDeletePet;
  final bool showActions;
  final bool showHealthCalendar;
  // final List<Widget>? extraActions; // Removed

  const ExpandablePetCard({
    Key? key,
    required this.pet,
    required this.onPetUpdated,
    required this.onDeletePet,
    this.showActions = true,
    this.showHealthCalendar = true,
  // this.extraActions, // Removed
  }) : super(key: key);

  @override
  _ExpandablePetCardState createState() => _ExpandablePetCardState();
}

class _ExpandablePetCardState extends State<ExpandablePetCard> {
  bool _isExpanded = false;
  // Removed image picker/upload responsibilities

  @override
  Widget build(BuildContext context) {
    bool isNetworkUrl = widget.pet.photoUrl != null &&
        (widget.pet.photoUrl!.startsWith('http://') ||
            widget.pet.photoUrl!.startsWith('https://'));

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: CircleAvatar(
                radius: 30,
                backgroundImage: isNetworkUrl
                    ? NetworkImage(widget.pet.photoUrl!)
                    : const AssetImage('assets/images/logo.png') as ImageProvider,
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 15, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              title: Text(
                widget.pet.name ?? 'Unknown Pet',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                widget.pet.breed ?? 'Unknown Breed',
                style: GoogleFonts.poppins(fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.showActions) ...[
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueAccent),
                      tooltip: 'Edit Pet',
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddEditPetScreen(pet: widget.pet),
                          ),
                        );
                        widget.onPetUpdated();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      tooltip: 'Delete Pet',
                      onPressed: () {
                        if (widget.pet.id != null) {
                          widget.onDeletePet(widget.pet.id!);
                        }
                      },
                    ),
                  ],
                  // Extra actions moved to Edit screen; removed from card
                  IconButton(
                    icon: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey[700]),
                    onPressed: () => setState(() {
                      _isExpanded = !_isExpanded;
                    }),
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    _buildDetailRow('Age', '${widget.pet.age ?? '-'} years'),
                    _buildDetailRow('Animal', widget.pet.animal ?? 'N/A'),
                    _buildDetailRow('Gender', widget.pet.gender ?? 'N/A'),
                    _buildDetailRow('Weight', '${widget.pet.weightKg ?? 'N/A'} kg'),
                    _buildDetailRow('Height', '${widget.pet.heightCm ?? 'N/A'} cm'),
                    _buildDetailRow('Diet Type', widget.pet.dietType ?? 'N/A'),
                    _buildDetailRow('Feeding Frequency',
                        '${widget.pet.feedingFrequency ?? 'N/A'} times/day'),
                    _buildDetailRow('Activity Level', widget.pet.activityLevel ?? 'N/A'),
                    _buildDetailRow('Coat Type', widget.pet.coatType ?? 'N/A'),
                    _buildDetailRow('Grooming Needs', widget.pet.groomingNeeds ?? 'N/A'),
                    _buildDetailRow('Preferred Food Type',
                        widget.pet.preferredFoodType ?? 'N/A'),
                    _buildDetailRow('Allergies',
                        widget.pet.allergies?.join(', ') ?? 'None'),
                    _buildDetailRow('Medical Conditions',
                        widget.pet.medicalConditions?.join(', ') ?? 'None'),
                    _buildDetailRow('Description', widget.pet.description ?? 'None'),
                    _buildDetailRow('Status', widget.pet.status ?? 'Unknown'),
                    _buildDetailRow('Color', widget.pet.color ?? 'N/A'),
                    const SizedBox(height: 10),
                    if (widget.showHealthCalendar)
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
                  ],
                ),
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title: ',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13.5),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
