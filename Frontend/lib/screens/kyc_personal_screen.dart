import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_connect_app/screens/shelter_home_screen.dart';

class KycPersonalScreen extends StatefulWidget {
  static const routeName = '/kyc-personal';
  const KycPersonalScreen({super.key});

  @override
  State<KycPersonalScreen> createState() => _KycPersonalScreenState();
}

class _KycPersonalScreenState extends State<KycPersonalScreen> {
  final _formKey = GlobalKey<FormState>();
  String _fullName = '';
  String _phone = '';
  String _otp = '';
  bool _otpSent = false;
  bool _verified = false;
  String _generatedOtp = '';

  Future<void> _sendOtp() async {
    setState(() {
      _generatedOtp = '123456'; // Mock OTP (later integrate SMS)
      _otpSent = true;
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("OTP Sent"),
        content: const Text("Your OTP is 123456 (demo only)."),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("OK")),
        ],
      ),
    );
  }

  Future<void> _verifyOtp() async {
    if (_otp == _generatedOtp) {
      setState(() => _verified = true);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Phone number verified ✅")));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Invalid OTP ❌")));
    }
  }

  Future<void> _submitKyc() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    await Supabase.instance.client.from('kyc_personal').insert({
      'user_id': user.id,
      'full_name': _fullName,
      'phone': _phone,
      'is_otp_verified': _verified,
      'status': _verified ? 'pending' : 'unverified',
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Verification Complete"),
        content: const Text(
            "Your KYC details have been sent for review. Once approved, you'll access your dashboard."),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.pushReplacementNamed(
                    context, ShelterHomeScreen.routeName);
              },
              child: const Text("OK"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9DF),
      appBar: AppBar(
        title: Text("Level 2: Personal Verification",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? "Enter your name" : null,
                onSaved: (v) => _fullName = v!,
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                onSaved: (v) => _phone = v!,
                validator: (v) =>
                    v == null || v.length < 10 ? "Enter valid number" : null,
              ),
              const SizedBox(height: 20),
              if (!_otpSent)
                ElevatedButton(
                  onPressed: _sendOtp,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text("Send OTP"),
                )
              else ...[
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Enter OTP",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => _otp = v,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _verifyOtp,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text("Verify OTP"),
                ),
              ],
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submitKyc,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text("Submit Verification"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
