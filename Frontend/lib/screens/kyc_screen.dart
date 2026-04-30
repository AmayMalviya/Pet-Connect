import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_connect_app/screens/auth_screen.dart';
import 'package:pet_connect_app/services/storage_service.dart';

// ── navigation targets ──────────────────────────────────────────────────────
// Create these two stub screens if they don't exist yet:
//   VerificationSuccessScreen  (routeName = '/verification-success')
//   UnderReviewScreen          (routeName = '/under-review')
import 'package:pet_connect_app/screens/verification_success_screen.dart';
import 'package:pet_connect_app/screens/under_review_screen.dart';
import 'package:pet_connect_app/screens/shelter_home_screen.dart';

/// Full automated KYC flow.
/// Inputs  : Aadhaar ZIP, PAN, optional GSTIN / Darpan ID, Selfie (camera).
/// Outcome : Calls 'process-kyc' edge function → navigates by status.
class KycScreen extends StatefulWidget {
  static const routeName = '/kyc';
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _storage = StorageService();

  // controllers
  final _panCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  final _darpanCtrl = TextEditingController();
  final _shareCodeCtrl = TextEditingController();

  File? _aadhaarZip;
  File? _selfieImage;

  bool _isSubmitting = false;
  double _progress = 0; // 0-1
  Timer? _progressTimer;

  @override
  void dispose() {
    _progressTimer?.cancel();
    _panCtrl.dispose();
    _gstinCtrl.dispose();
    _darpanCtrl.dispose();
    _shareCodeCtrl.dispose();
    super.dispose();
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  void _startProgress() {
    const total = Duration(minutes: 5);
    const tick = Duration(seconds: 1);
    final steps = total.inSeconds;
    int elapsed = 0;
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(tick, (_) {
      elapsed++;
      if (mounted) setState(() => _progress = elapsed / steps);
      if (elapsed >= steps) _progressTimer?.cancel();
    });
  }

  Future<void> _pickZip() async {
    final r = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['zip']);
    if (r?.files.single.path != null) {
      setState(() => _aadhaarZip = File(r!.files.single.path!));
    }
  }

  Future<void> _takeSelfie() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 90,
    );
    if (picked == null) return;
    final file = File(picked.path);
    // flip mirror effect
    try {
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        await file.writeAsBytes(img.encodePng(img.flipHorizontal(decoded)));
      }
    } catch (_) {}
    if (mounted) setState(() => _selfieImage = file);
  }

  // ── submit ───────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_aadhaarZip == null) {
      _snack('Upload Aadhaar ZIP first.');
      return;
    }
    if (_selfieImage == null) {
      _snack('Take selfie first.');
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _isSubmitting = true;
      _progress = 0;
    });
    _startProgress();

    try {
      // 1. Upload ZIP + selfie
      final zipPath = await _storage.uploadKycFile(
        user.id, _aadhaarZip!,
        purpose: 'aadhaar_zip',
        customFileName: 'aadhaar.zip',
      );
      final selfiePath = await _storage.uploadKycFile(
        user.id, _selfieImage!,
        purpose: 'selfie',
      );
      if (zipPath == null || selfiePath == null) throw Exception('Upload failed.');

      // 2. Call edge function
      final res = await Supabase.instance.client.functions.invoke(
        'process-kyc',
        body: {
          'userId': user.id,
          'zipPath': zipPath,
          'selfiePath': selfiePath,
          'pan': _panCtrl.text.trim().toUpperCase(),
          'shareCode': _shareCodeCtrl.text.trim(),
          if (_gstinCtrl.text.trim().isNotEmpty) 'gstin': _gstinCtrl.text.trim().toUpperCase(),
          if (_darpanCtrl.text.trim().isNotEmpty) 'darpanId': _darpanCtrl.text.trim(),
        },
      );

      final status = (res.data as Map<String, dynamic>?)?['status'] as String?;

      if (!mounted) return;

      if (status == 'completed') {
        Navigator.pushReplacementNamed(context, VerificationSuccessScreen.routeName);
      } else if (status == 'pending_review') {
        Navigator.pushReplacementNamed(context, UnderReviewScreen.routeName);
      } else {
        _snack('KYC rejected. Reason: ${(res.data)?['reason'] ?? 'Low trust score'}');
      }
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      _progressTimer?.cancel();
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ── info bottom-sheet ────────────────────────────────────────────────────
  static void _showInfo(BuildContext ctx, {required String title, required String body, String? steps}) {
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 20),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700))),
              ],
            ),
            const SizedBox(height: 12),
            Text(body, style: const TextStyle(fontSize: 13, height: 1.6)),
            if (steps != null) ...[
              const SizedBox(height: 10),
              Text(steps,
                  style: const TextStyle(
                      fontSize: 12, height: 1.65, color: Color(0xFF555555))),
            ],
          ],
        ),
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text('KYC Verification', style: theme.textTheme.titleLarge),
            backgroundColor: theme.appBarTheme.backgroundColor,
            foregroundColor: theme.appBarTheme.foregroundColor,
            elevation: 0,
            actions: [
              IconButton(
                tooltip: 'Logout',
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, AuthScreen.routeName);
                  }
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Tip banner ─────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.bolt_rounded, color: cs.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'More information you provide, the faster the verification.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Aadhaar ZIP ────────────────────────────────────────
                  _LabelRow(
                    label: '1. Aadhaar (Offline E-Aadhaar ZIP)',
                    onInfo: () => _showInfo(context,
                      title: 'How to get your E-Aadhaar ZIP',
                      body: 'The offline Aadhaar XML (ZIP) is a digitally signed file issued by UIDAI. It contains your name, DOB, address and a verifiable UIDAI signature — far more reliable than a photo.',
                      steps: 'Steps:\n1. Go to myaadhaar.uidai.gov.in\n2. Sign in with your Aadhaar number + OTP\n3. Click "Offline e-KYC" → "Download XML"\n4. Set a 4-digit share code when prompted\n5. Save the .zip file and upload it here.',
                    ),
                    theme: theme,
                  ),
                  const SizedBox(height: 8),
                  _aadhaarZip == null
                      ? _OutlineBtn(
                          label: 'Select Aadhaar .zip',
                          icon: Icons.folder_zip_outlined,
                          onTap: _pickZip,
                          color: cs.primary,
                        )
                      : ListTile(
                          leading: Icon(Icons.check_circle, color: cs.primary),
                          title: Text(_aadhaarZip!.path.split('/').last,
                              style: theme.textTheme.bodyMedium),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _aadhaarZip = null),
                          ),
                          tileColor: cs.primaryContainer.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                  const SizedBox(height: 20),

                  _LabelRow(
                    label: '1b. Aadhaar Share Code (4 digits)',
                    onInfo: () => _showInfo(context,
                      title: 'What is the Aadhaar Share Code?',
                      body: 'When you download the Offline E-Aadhaar ZIP from UIDAI, you are asked to set a 4-digit numeric password to protect the file. This share code is needed to open (decrypt) the ZIP and verify your Aadhaar data.',
                      steps: 'Where to find it:\n• You chose this 4-digit code yourself during the UIDAI download\n• It is NOT your Aadhaar OTP or PIN\n• If you forgot it, re-download the ZIP from myaadhaar.uidai.gov.in and set a new code',
                    ),
                    theme: theme,
                  ),
                  const SizedBox(height: 8),
                  _KycField(
                    controller: _shareCodeCtrl,
                    label: '4-digit share code',
                    maxLen: 4,
                    caps: false,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (_aadhaarZip == null) return null; // only required if zip attached
                      if (v == null || v.isEmpty) return 'Share code required with Aadhaar ZIP';
                      if (!RegExp(r'^\d{4}$').hasMatch(v)) return 'Must be exactly 4 digits';
                      return null;
                    },
                    theme: theme,
                  ),
                  const SizedBox(height: 20),

                  // ── PAN ────────────────────────────────────────────────
                  _LabelRow(
                    label: '2. PAN Card Number',
                    onInfo: () => _showInfo(context,
                      title: 'What is a PAN card?',
                      body: 'PAN (Permanent Account Number) is a 10-character alphanumeric code issued by the Income Tax Department of India. It is mandatory for all financial and tax transactions.',
                      steps: 'Where to find it:\n• Printed on the front of your physical PAN card\n• Format: AAAAA9999A  (5 letters · 4 digits · 1 letter)\n• 4th character: P = Individual,  C = Company / Trust',
                    ),
                    theme: theme,
                  ),
                  const SizedBox(height: 8),
                  _KycField(
                    controller: _panCtrl,
                    label: 'PAN (e.g. ABCDE1234F)',
                    maxLen: 10,
                    caps: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'PAN required';
                      final upper = v.toUpperCase();
                      if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(upper)) {
                        return 'Invalid PAN format';
                      }
                      final fourth = upper[3];
                      if (fourth != 'P' && fourth != 'C') {
                        return '4th char must be P (individual) or C (company)';
                      }
                      return null;
                    },
                    theme: theme,
                  ),
                  const SizedBox(height: 20),

                  // ── GSTIN (optional) ───────────────────────────────────
                  _LabelRow(
                    label: '3. GSTIN (optional)',
                    onInfo: () => _showInfo(context,
                      title: 'What is GSTIN?',
                      body: 'GSTIN (Goods & Services Tax Identification Number) is a 15-digit number assigned to every GST-registered business in India. Providing it boosts your trust score.',
                      steps: 'Where to find it:\n• GST registration certificate\n• Any GST invoice issued to / by your shelter\n• GST portal: gst.gov.in → Login → My Profile\n• Format: 22AAAAA0000A1Z5',
                    ),
                    theme: theme,
                  ),
                  const SizedBox(height: 8),
                  _KycField(
                    controller: _gstinCtrl,
                    label: 'GSTIN (15 chars)',
                    maxLen: 15,
                    caps: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return null; // optional
                      if (!RegExp(r'^\d{2}[A-Z]{5}\d{4}[A-Z]{1}\d[Z]{1}[A-Z\d]{1}$')
                          .hasMatch(v.toUpperCase())) {
                        return 'Invalid GSTIN format';
                      }
                      return null;
                    },
                    theme: theme,
                  ),
                  const SizedBox(height: 20),

                  // ── Darpan ID (optional) ───────────────────────────────
                  _LabelRow(
                    label: '4. Darpan ID (optional, NGO shelters)',
                    onInfo: () => _showInfo(context,
                      title: 'What is a Darpan ID?',
                      body: 'Darpan is a government portal (darpan.gov.in) that registers NGOs. A Darpan ID proves your shelter is a registered non-profit, significantly increasing your trust score.',
                      steps: 'Where to find it:\n• NGO registration certificate from niti.gov.in/darpan\n• Visible after login at darpan.gov.in → My Profile\n• Format: GJ/2019/0223456  (State / Year / Number)',
                    ),
                    theme: theme,
                  ),
                  const SizedBox(height: 8),
                  _KycField(
                    controller: _darpanCtrl,
                    label: 'Darpan Registration ID',
                    caps: false,
                    theme: theme,
                  ),
                  const SizedBox(height: 20),

                  // ── Selfie ─────────────────────────────────────────────
                  _LabelRow(
                    label: '5. Selfie (front camera)',
                    onInfo: () => _showInfo(context,
                      title: 'Taking a good selfie',
                      body: 'Your selfie is used to cross-verify your identity against the Aadhaar photo. A clear selfie speeds up manual review.',
                      steps: 'Tips:\n• Face must be centered and fully visible\n• Remove sunglasses, caps, or masks\n• Use natural lighting — avoid backlighting\n• Neutral expression works best\n• The app automatically corrects the mirror effect',
                    ),
                    theme: theme,
                  ),
                  const SizedBox(height: 8),
                  _selfieImage == null
                      ? _OutlineBtn(
                          label: 'Open Camera',
                          icon: Icons.camera_alt_outlined,
                          onTap: _takeSelfie,
                          color: cs.secondary,
                        )
                      : Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(_selfieImage!,
                                  height: 220,
                                  width: double.infinity,
                                  fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: _takeSelfie,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(Icons.refresh,
                                      color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(height: 32),

                  // ── Submit ─────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Submit KYC',
                        style: theme.textTheme.labelLarge
                            ?.copyWith(color: cs.onPrimary, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Skip ───────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  title: const Text('Skip Verification?'),
                                  content: const Text(
                                    'You can explore the app, but all shelter features will be locked until you complete KYC.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Go Back'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        Navigator.pushReplacementNamed(
                                          context,
                                          ShelterHomeScreen.routeName,
                                        );
                                      },
                                      child: const Text('Skip for now'),
                                    ),
                                  ],
                                ),
                              );
                            },
                      child: Text(
                        'Skip for now',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),

        // ── Loading overlay ───────────────────────────────────────────────
        if (_isSubmitting) _LoadingOverlay(progress: _progress),
      ],
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

/// Row with section label + individual ⓘ info button
class _LabelRow extends StatelessWidget {
  const _LabelRow({
    required this.label,
    required this.onInfo,
    required this.theme,
  });
  final String label;
  final VoidCallback onInfo;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        GestureDetector(
          onTap: onInfo,
          child: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: theme.colorScheme.primary.withValues(alpha: 0.75),
            ),
          ),
        ),
      ],
    );
  }
}

class _KycField extends StatelessWidget {
  const _KycField({
    required this.controller,
    required this.label,
    required this.theme,
    this.maxLen,
    this.caps = false,
    this.validator,
    this.keyboardType,
  });
  final TextEditingController controller;
  final String label;
  final int? maxLen;
  final bool caps;
  final String? Function(String?)? validator;
  final ThemeData theme;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLength: maxLen,
      keyboardType: keyboardType,
      textCapitalization:
          caps ? TextCapitalization.characters : TextCapitalization.none,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        counterText: '',
      ),
      validator: validator,
      style: theme.textTheme.bodyMedium,
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn(
      {required this.label,
      required this.icon,
      required this.onTap,
      required this.color});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: color),
        label: Text(label, style: TextStyle(color: color)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

/// Full-screen loading overlay with a 5-minute progress timer.
class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = Duration(
        seconds: ((1 - progress) * 300).round()); // 5 min = 300 s
    final mm = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                value: progress == 0 ? null : progress,
                strokeWidth: 6,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text('Verifying…',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                'Est. time remaining: $mm:$ss',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(4),
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
