import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  Future<void> _pickImage(bool isAadhaar) async {
    final picked = await _picker.pickImage(
        source: isAadhaar ? ImageSource.gallery : ImageSource.camera,
        imageQuality: 80);
    if (picked != null) {
      setState(() {
        if (isAadhaar) {
          _aadhaarImage = File(picked.path);
        } else {
          _selfieImage = File(picked.path);
        }
      });
    }
  }

  Future<void> _submitKyc() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_aadhaarImage == null || _selfieImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please upload all images.")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final aadhaarUrl = await _storage.uploadKycFile(user.id, _aadhaarImage!,
          purpose: 'aadhaar');
      final selfieUrl =
          await _storage.uploadKycFile(user.id, _selfieImage!, purpose: 'selfie');

      await Supabase.instance.client.from('kyc_documents').insert({
        'user_id': user.id,
        'aadhaar_number': _aadhaarNumber,
        'aadhaar_image_url': aadhaarUrl,
        'selfie_image_url': selfieUrl,
        'status': 'pending',
      });

      _showSuccessDialog();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isSubmitting = false);
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
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Aadhaar Number",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.length != 12 ? "Enter valid Aadhaar" : null,
                onSaved: (v) => _aadhaarNumber = v!,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(children: [
                    _aadhaarImage == null
                        ? const Icon(Icons.upload_file, size: 60)
                        : Image.file(_aadhaarImage!, height: 100),
                    TextButton(
                        onPressed: () => _pickImage(true),
                        child: const Text("Upload Aadhaar"))
                  ]),
                  Column(children: [
                    _selfieImage == null
                        ? const Icon(Icons.camera_alt, size: 60)
                        : Image.file(_selfieImage!, height: 100),
                    TextButton(
                        onPressed: () => _pickImage(false),
                        child: const Text("Take Selfie"))
                  ]),
                ],
              ),
              const SizedBox(height: 30),
              _isSubmitting
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitKyc,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: const Text("Submit Documents"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
