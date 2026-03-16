import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';
import 'package:pet_connect_app/screens/kyc_pending_screen.dart';
import 'dart:async';
import 'package:pet_connect_app/services/storage_service.dart';
import 'package:pet_connect_app/theme/app_theme.dart';
import 'package:pet_connect_app/utils/aadhaar_validator.dart';
import 'package:file_picker/file_picker.dart';

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
  File? _aadhaarZip;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _shareCodeController = TextEditingController();
  bool _isSubmitting = false;
  bool _useZip = false;
  String? _rejectionReason;

  // OTP Verification State
  final _auth = FirebaseAuth.instance;
  bool _otpSent = false;
  bool _phoneVerified = false;
  String _verificationId = '';
  int? _forceResendingToken;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  int _resendCountdown = 0;
  Timer? _resendTimer;
  final _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkPreviousSubmission();
    _initFirebase();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _aadhaarController.dispose();
    _shareCodeController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } catch (_) {}
  }

  void _startResendTimer() {
    setState(() => _resendCountdown = 30);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendCountdown > 0) {
            _resendCountdown--;
          } else {
            _resendTimer?.cancel();
          }
        });
      }
    });
  }

  Future<void> _sendOtp({bool isResend = false}) async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter phone number first")));
      return;
    }

    setState(() => _isSendingOtp = true);
    String formattedPhone = phone;
    if (!formattedPhone.startsWith('+')) formattedPhone = '+91$formattedPhone';

    await _auth.verifyPhoneNumber(
      phoneNumber: formattedPhone,
      forceResendingToken: isResend ? _forceResendingToken : null,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        if (mounted) {
          setState(() => _phoneVerified = true);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone auto-verified ✅')));
        }
      },
      verificationFailed: (e) {
        if (mounted) {
          setState(() => _isSendingOtp = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${e.message}')));
        }
      },
      codeSent: (String vid, int? resendToken) {
        if (mounted) {
          setState(() {
            _otpSent = true;
            _verificationId = vid;
            _forceResendingToken = resendToken;
            _isSendingOtp = false;
          });
          _startResendTimer();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP Sent!')));
        }
      },
      codeAutoRetrievalTimeout: (vid) {
        if (mounted) setState(() => _verificationId = vid);
      },
    );
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) return;
    setState(() => _isVerifyingOtp = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text.trim(),
      );
      await _auth.signInWithCredential(credential);
      if (mounted) {
        setState(() {
          _phoneVerified = true;
          _isVerifyingOtp = false;
        });
        _resendTimer?.cancel();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVerifyingOtp = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid OTP ❌")));
      }
    }
  }

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

  Future<void> _pickZipFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      
      if (result != null && result.files.single.path != null) {
        setState(() {
          _aadhaarZip = File(result.files.single.path!);
          _useZip = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking ZIP: $e')),
        );
      }
    }
  }

  Future<void> _submitKyc() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_aadhaarImage == null || _selfieImage == null || !_phoneVerified) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_phoneVerified ? "Aadhaar image and selfie are required." : "Please verify your phone number via OTP first.")));
      return;
    }

    if (_useZip && (_aadhaarZip == null || _shareCodeController.text.length != 4)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Aadhaar ZIP and 4-digit share code are required for offline verification.")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Upload files
      final uploadFutures = [
        _storage.uploadKycFile(user.id, _aadhaarImage!, purpose: 'aadhaar_image'),
        _storage.uploadKycFile(user.id, _selfieImage!, purpose: 'selfie'),
      ];
      
      if (_useZip && _aadhaarZip != null) {
        uploadFutures.add(_storage.uploadKycFile(user.id, _aadhaarZip!, purpose: 'aadhaar_offline', customFileName: 'aadhaar_offline.zip'));
      }

      final results = await Future.wait(uploadFutures);
      final aadhaarPath = results[0];
      final selfiePath = results[1];
      final zipPath = results.length > 2 ? results[2] : null;

      if (aadhaarPath == null || selfiePath == null || (_useZip && zipPath == null)) {
        throw Exception('File upload failed.');
      }

      // 2. Insert into shelter_kyc (new entry to maintain history)
      final maskedAadhaar = AadhaarValidator.mask(_aadhaarController.text);
      
      await Supabase.instance.client.from('shelter_kyc').insert({
        'user_id': user.id,
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'aadhaar_number': maskedAadhaar,
        'aadhaar_image_url': aadhaarPath,
        'selfie_image_url': selfiePath,
        'status': 'pending',
      });

      // 3. Update profile
      await Supabase.instance.client.from('profiles').update({
        'kyc_submitted': true,
        'kyc_status': 'pending',
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
      }).eq('user_id', user.id);

      // 4. Call Edge Function if ZIP provided
      if (_useZip) {
        try {
          await Supabase.instance.client.functions.invoke(
            'verify-aadhaar-kyc',
            body: {
              'userId': user.id,
              'shareCode': _shareCodeController.text,
              'zipPath': zipPath,
            },
          );
        } catch (e) {
          debugPrint('Edge function error (continuing anyway): $e');
        }
      }

      if (mounted) _showSuccessDialog();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("KYC Submitted"),
        content: const Text(
            "Your verification details have been submitted. An admin will review them soon."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.pushReplacementNamed(context, KycPendingScreen.routeName);
            },
            child: const Text("Finish"),
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
              if (_rejectionReason != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Previous KYC Rejected",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[900],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Reason: $_rejectionReason",
                        style: GoogleFonts.poppins(
                          color: Colors.red[800],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Please correct the information below and resubmit.",
                        style: GoogleFonts.poppins(
                          color: Colors.red[800],
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Personal Information Section
              Text(
                "Personal Information",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: "First Name",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (v) => (v == null || v.isEmpty) ? "First name is required" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: "Last Name",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (v) => (v == null || v.isEmpty) ? "Last name is required" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  hintText: "e.g., 9876543210",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  suffixIcon: _phoneVerified 
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : (!_otpSent && !_isSendingOtp) 
                        ? TextButton(onPressed: _sendOtp, child: const Text("Verify"))
                        : null,
                ),
                keyboardType: TextInputType.phone,
                readOnly: _otpSent || _phoneVerified,
                validator: (v) => (v == null || v.isEmpty) ? "Phone number is required" : null,
              ),
              if (_otpSent && !_phoneVerified) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _otpController,
                  decoration: InputDecoration(
                    labelText: "Enter 6-digit OTP",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: _isVerifyingOtp 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : TextButton(onPressed: _verifyOtp, child: const Text("Confirm")),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  onChanged: (v) {
                    if (v.length == 6) _verifyOtp();
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_resendCountdown > 0)
                      Text('Resend in $_resendCountdown s  ', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    TextButton(
                      onPressed: _resendCountdown > 0 ? null : () => _sendOtp(isResend: true),
                      child: const Text("Resend OTP", style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
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
                controller: _aadhaarController,
                decoration: InputDecoration(
                  labelText: "Aadhaar Number (12 digits)",
                  hintText: "e.g., 1234 5678 9012",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  suffixIcon: _aadhaarController.text.length == 12 && AadhaarValidator.validate(_aadhaarController.text) 
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => setState(() {}),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Aadhaar number is required";
                  if (!AadhaarValidator.validate(v)) return "Invalid Aadhaar number (checksum failed)";
                  return null;
                },
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

              // Offline verification Section
              Row(
                children: [
                  Text(
                    "Optional: Offline Verification (E-Aadhaar ZIP)",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const Spacer(),
                  Switch(
                    value: _useZip,
                    onChanged: (v) => setState(() => _useZip = v),
                    activeColor: Colors.purple,
                  ),
                ],
              ),
              if (_useZip) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple[100]!),
                  ),
                  child: Column(
                    children: [
                      if (_aadhaarZip != null)
                        ListTile(
                          leading: const Icon(Icons.folder_zip, color: Colors.purple),
                          title: Text(_aadhaarZip!.path.split('/').last, style: const TextStyle(fontSize: 12)),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() => _aadhaarZip = null),
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _pickZipFile,
                            icon: const Icon(Icons.file_upload),
                            label: const Text("Select .zip file"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.purple,
                              side: const BorderSide(color: Colors.purple),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _shareCodeController,
                        decoration: const InputDecoration(
                          labelText: "4-digit Share Code",
                          hintText: "e.g., 1234",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        validator: (v) {
                          if (_useZip && (v == null || v.length != 4)) return "Enter 4-digit code";
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
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

