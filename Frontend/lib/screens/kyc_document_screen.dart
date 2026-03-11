import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_connect_app/screens/kyc_personal_screen.dart';
import 'package:pet_connect_app/services/storage_service.dart';
import 'package:pet_connect_app/theme/app_theme.dart';

class KycDocumentScreen extends StatefulWidget {
  static const routeName = '/kyc-document';
  const KycDocumentScreen({super.key});

  @override
  State<KycDocumentScreen> createState() => _KycDocumentScreenState();
}

class _KycDocumentScreenState extends State<KycDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _storage = StorageService();

  File? _aadhaarImage;
  File? _selfieImage;
  String _aadhaarNumber = '';
  bool _isSubmitting = false;

  /// Flip selfie image horizontally to remove mirror effect
  Future<File> _fixSelfieImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image != null) {
        // Flip image horizontally
        final flipped = img.flipHorizontal(image);
        
        // Save flipped image back
        final flippedBytes = img.encodePng(flipped);
        await imageFile.writeAsBytes(flippedBytes);
      }
    } catch (e) {
      debugPrint('Error flipping selfie image: $e');
      // If flipping fails, just use the original
    }
    return imageFile;
  }

  /// Manual crop image - custom UI for user to adjust crop area
  Future<void> _cropImageManually(File imageFile, bool isAadhaar) async {
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.all(20),
        child: ManualCropScreen(
          imageFile: imageFile,
          isAadhaar: isAadhaar,
          onCropComplete: (croppedFile) {
            setState(() {
              if (isAadhaar) {
                _aadhaarImage = croppedFile;
              } else {
                _selfieImage = croppedFile;
              }
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isAadhaar ? 'Aadhaar cropped successfully' : 'Selfie cropped successfully'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }

  Future<void> _pickImage(bool isAadhaar) async {
    try {
      final picked = await _picker.pickImage(
        source: isAadhaar ? ImageSource.gallery : ImageSource.camera,
        imageQuality: 90,
        preferredCameraDevice: isAadhaar 
          ? CameraDevice.rear  // Gallery for Aadhaar
          : CameraDevice.front, // Front camera for selfie
      );
      
      if (picked != null) {
        final imageFile = File(picked.path);
        
        if (!mounted) return;
        // Show crop/confirm dialog for both images
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            insetPadding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isAadhaar ? Colors.blue[50] : Colors.green[50],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(isAadhaar ? Icons.credit_card : Icons.camera_alt, 
                          color: isAadhaar ? Colors.blue : Colors.green, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isAadhaar ? 'Review Aadhaar' : 'Review Selfie',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Image Preview with proper constraints
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: MediaQuery.of(context).size.height * 0.35,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(imageFile, 
                                  width: double.infinity,
                                  fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isAadhaar ? Colors.blue[50] : Colors.green[50],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isAadhaar
                                  ? "✓ Entire card visible • Text readable"
                                  : "✓ Face centered • Good lighting",
                                style: GoogleFonts.poppins(fontSize: 9, height: 1.3),
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        // Keep/Confirm Button - Bigger and Primary
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (!isAadhaar) {
                                // Fix mirror effect for selfie
                                final fixedImage = await _fixSelfieImage(imageFile);
                                setState(() {
                                  _selfieImage = fixedImage;
                                });
                              } else {
                                setState(() {
                                  _aadhaarImage = imageFile;
                                });
                              }
                              if (mounted) Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              "✓ Keep This Photo",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        
                        // Retake & Crop Buttons Row
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _pickImage(isAadhaar);
                                  },
                                  icon: const Icon(Icons.refresh, size: 14),
                                  label: const Text("Retake", style: TextStyle(fontSize: 11)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange[100],
                                    foregroundColor: Colors.orange[900],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _cropImageManually(imageFile, isAadhaar);
                                  },
                                  icon: const Icon(Icons.crop, size: 14),
                                  label: const Text("Crop", style: TextStyle(fontSize: 11)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[200],
                                    foregroundColor: Colors.grey[800],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _submitKyc() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_aadhaarImage == null || _selfieImage == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please upload all images.")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Upload both images in parallel to reduce wall-clock time
      final uploadFutures = [
        _storage.uploadKycFile(user.id, _aadhaarImage!, purpose: 'aadhaar'),
        _storage.uploadKycFile(user.id, _selfieImage!, purpose: 'selfie'),
      ];

      final results = await Future.wait(uploadFutures);
      final aadhaarUrl = results[0];
      final selfieUrl = results[1];

      if (aadhaarUrl == null || selfieUrl == null) {
        throw Exception('One or more uploads failed.');
      }

      await Supabase.instance.client.from('kyc_documents').insert({
        'user_id': user.id,
        'aadhaar_number': _aadhaarNumber,
        'aadhaar_image_url': aadhaarUrl,
        'selfie_image_url': selfieUrl,
        'status': 'pending',
      });

      if (mounted) _showSuccessDialog();
    } catch (e) {
      final err = e.toString();
      if (mounted) {
        // If the error looks like a Supabase policy/permission issue, show helpful guidance
        if (err.contains('Supabase policy error') || err.contains('row-level security') || err.contains('403')) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Upload Permission Error'),
              content: const Text('Upload failed due to Supabase permission/policy settings.\n\nCheck that the storage bucket `kyc_bucket` exists and allows authenticated uploads, or adjust row-level security policies for `kyc_documents`. If you are running locally, ensure the user is signed in.'),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Documents Submitted"),
        content: const Text(
            "Your KYC documents have been submitted for review. Please continue with your personal verification."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.pushReplacementNamed(
                  context, KycPersonalScreen.routeName);
            },
            child: const Text("Continue"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9DF),
      appBar: AppBar(
        title: Text("Level 1: Document Verification",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Why we need this:",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "We verify your identity to ensure a safe and trustworthy community. Your documents are encrypted and securely stored.",
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Aadhaar Section
              Text(
                "Step 1: Aadhaar Document",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "📋 Upload Guidelines:",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "• Take a clear, well-lit photo\n• Ensure all text is readable\n• No glare or shadows\n• Entire card should be visible\n• You can retake the photo if needed",
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[800]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Aadhaar Number Field
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Aadhaar Number (12 digits)",
                  hintText: "e.g., 1234 5678 9012",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return "Aadhaar number is required";
                  final digits = v.replaceAll(' ', '');
                  return digits.length != 12 ? "Enter valid 12-digit Aadhaar" : null;
                },
                onSaved: (v) => _aadhaarNumber = v!.replaceAll(' ', ''),
              ),
              const SizedBox(height: 16),

              // Aadhaar Image Preview & Upload
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[50],
                ),
                child: Column(
                  children: [
                    if (_aadhaarImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_aadhaarImage!, height: 200, fit: BoxFit.cover),
                      )
                    else
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(Icons.image_outlined, size: 60, color: Colors.grey),
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => _pickImage(true),
                        icon: const Icon(Icons.upload_file, size: 20),
                        label: Text(
                          _aadhaarImage == null ? "Upload Aadhaar" : "Change Photo",
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Selfie Section
              Text(
                "Step 2: Selfie for Verification",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "🤳 Selfie Guidelines:",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "• Face clearly visible and centered\n• Remove sunglasses, caps, and hats\n• Good lighting (natural light works best)\n• Face must match your Aadhaar photo\n• Neutral expression recommended\n• Photo taken naturally (no mirror effect)",
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[800]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Selfie Image Preview & Capture
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[50],
                ),
                child: Column(
                  children: [
                    if (_selfieImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_selfieImage!, height: 200, fit: BoxFit.cover),
                      )
                    else
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(Icons.camera_alt_outlined, size: 60, color: Colors.grey),
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => _pickImage(false),
                        icon: const Icon(Icons.camera_alt, size: 20),
                        label: Text(
                          _selfieImage == null ? "Take Selfie" : "Retake Photo",
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: _isSubmitting
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : ElevatedButton(
                        onPressed: _submitKyc,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Submit Documents",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom manual crop widget with grid for cropping images
class ManualCropScreen extends StatefulWidget {
  final File imageFile;
  final bool isAadhaar;
  final Function(File) onCropComplete;

  const ManualCropScreen({
    super.key,
    required this.imageFile,
    required this.isAadhaar,
    required this.onCropComplete,
  });

  @override
  State<ManualCropScreen> createState() => _ManualCropScreenState();
}

class _ManualCropScreenState extends State<ManualCropScreen> {
  late img.Image? _image;
  double _cropLeft = 0.1;
  double _cropTop = 0.1;
  double _cropRight = 0.9;
  double _cropBottom = 0.9;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  void _loadImage() async {
    try {
      final bytes = await widget.imageFile.readAsBytes();
      _image = img.decodeImage(bytes);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading image: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCroppedImage() async {
    if (_image == null) return;

    try {
      // Calculate actual pixel coordinates from normalized values
      final x = (_cropLeft * _image!.width).toInt();
      final y = (_cropTop * _image!.height).toInt();
      final width = ((_cropRight - _cropLeft) * _image!.width).toInt();
      final height = ((_cropBottom - _cropTop) * _image!.height).toInt();

      // Ensure valid dimensions
      if (width > 0 && height > 0 && x >= 0 && y >= 0) {
        final cropped = img.copyCrop(
          _image!,
          x: x,
          y: y,
          width: width,
          height: height,
        );

        final bytes = img.encodePng(cropped);
        final tempDir = Directory.systemTemp;
        final croppedFile = File(
          '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await croppedFile.writeAsBytes(bytes);
        widget.onCropComplete(croppedFile);
      }
    } catch (e) {
      debugPrint('Error cropping: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cropping image: $e')),
        );
      }
    }
  }

  void _updateCropArea(DragUpdateDetails details, String handle) {
    setState(() {
      const step = 0.02;
      final dx = details.delta.dx * step;
      final dy = details.delta.dy * step;

      if (handle == 'topLeft') {
        _cropLeft = (_cropLeft + dx).clamp(0.0, _cropRight - 0.1);
        _cropTop = (_cropTop + dy).clamp(0.0, _cropBottom - 0.1);
      } else if (handle == 'topRight') {
        _cropRight = (_cropRight + dx).clamp(_cropLeft + 0.1, 1.0);
        _cropTop = (_cropTop + dy).clamp(0.0, _cropBottom - 0.1);
      } else if (handle == 'bottomLeft') {
        _cropLeft = (_cropLeft + dx).clamp(0.0, _cropRight - 0.1);
        _cropBottom = (_cropBottom + dy).clamp(_cropTop + 0.1, 1.0);
      } else if (handle == 'bottomRight') {
        _cropRight = (_cropRight + dx).clamp(_cropLeft + 0.1, 1.0);
        _cropBottom = (_cropBottom + dy).clamp(_cropTop + 0.1, 1.0);
      } else if (handle == 'move') {
        final newLeft = _cropLeft + dx;
        final newRight = _cropRight + dx;
        final newTop = _cropTop + dy;
        final newBottom = _cropBottom + dy;

        if (newLeft >= 0 && newRight <= 1) {
          _cropLeft = newLeft;
          _cropRight = newRight;
        }
        if (newTop >= 0 && newBottom <= 1) {
          _cropTop = newTop;
          _cropBottom = newBottom;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isAadhaar ? Colors.blue[50] : Colors.green[50],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.isAadhaar ? Icons.credit_card : Icons.camera_alt,
                color: widget.isAadhaar ? Colors.blue : Colors.green,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Adjust Crop Area - Drag corners',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Image with crop grid overlay
        Expanded(
          child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Container(
              color: Colors.grey[200],
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Base image
                  Image.file(widget.imageFile, fit: BoxFit.contain),

                  // Custom paint for overlay and grid
                  CustomPaint(
                    painter: CropOverlayPainter(
                      cropLeft: _cropLeft,
                      cropTop: _cropTop,
                      cropRight: _cropRight,
                      cropBottom: _cropBottom,
                    ),
                  ),

                  // Crop area with interactive handles
                  GestureDetector(
                    onPanUpdate: (details) => _updateCropArea(details, 'move'),
                    child: Container(
                      margin: EdgeInsets.fromLTRB(
                        _cropLeft * 100 + 10,
                        _cropTop * 100 + 10,
                        _cropRight * 100,
                        _cropBottom * 100,
                      ),
                      color: Colors.transparent,
                    ),
                  ),

                  // Corner handles
                  _buildHandle(_cropLeft, _cropTop, 'topLeft'),
                  _buildHandle(_cropRight, _cropTop, 'topRight'),
                  _buildHandle(_cropLeft, _cropBottom, 'bottomLeft'),
                  _buildHandle(_cropRight, _cropBottom, 'bottomRight'),
                ],
              ),
            ),
        ),

        // Action Buttons
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                    ),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.black87, fontSize: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _saveCroppedImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      "Crop & Save",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHandle(double normalizedX, double normalizedY, String handleType) {
    return Positioned(
      left: normalizedX * (MediaQuery.of(context).size.width - 40),
      top: normalizedY * (MediaQuery.of(context).size.height - 300),
      child: GestureDetector(
        onPanUpdate: (details) => _updateCropArea(details, handleType),
        child: MouseRegion(
          cursor: SystemMouseCursors.move,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.green,
              border: Border.all(color: Colors.white, width: 2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for crop overlay (darkens outside crop area)
class CropOverlayPainter extends CustomPainter {
  final double cropLeft;
  final double cropTop;
  final double cropRight;
  final double cropBottom;

  CropOverlayPainter({
    required this.cropLeft,
    required this.cropTop,
    required this.cropRight,
    required this.cropBottom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dark overlay paint
    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    // Crop border paint
    final borderPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Grid paint
    final gridPaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.7)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final cropRect = Rect.fromLTRB(
      cropLeft * size.width,
      cropTop * size.height,
      cropRight * size.width,
      cropBottom * size.height,
    );

    // Draw dark overlay outside crop area
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(cropRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, overlayPaint);

    // Draw crop border
    canvas.drawRect(cropRect, borderPaint);

    // Draw grid lines (3x3)
    final cropWidth = cropRect.width;
    final cropHeight = cropRect.height;

    for (int i = 1; i < 3; i++) {
      // Vertical lines
      final x = cropRect.left + (cropWidth / 3) * i;
      canvas.drawLine(
        Offset(x, cropRect.top),
        Offset(x, cropRect.bottom),
        gridPaint,
      );

      // Horizontal lines
      final y = cropRect.top + (cropHeight / 3) * i;
      canvas.drawLine(
        Offset(cropRect.left, y),
        Offset(cropRect.right, y),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CropOverlayPainter oldDelegate) {
    return oldDelegate.cropLeft != cropLeft ||
        oldDelegate.cropTop != cropTop ||
        oldDelegate.cropRight != cropRight ||
        oldDelegate.cropBottom != cropBottom;
  }
}

