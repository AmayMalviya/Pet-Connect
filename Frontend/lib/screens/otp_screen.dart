import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/pet_text_field.dart';
import '../widgets/primary_button.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class OtpScreen extends StatefulWidget {
  static const routeName = '/otp';
  
  final String email;
  final bool isPasswordReset;

  const OtpScreen({
    super.key,
    required this.email,
    this.isPasswordReset = false,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final otpController = TextEditingController();
  final newPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    otpController.dispose();
    newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final otp = otpController.text.trim();
    if (otp.isEmpty || otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP')),
      );
      return;
    }

    if (widget.isPasswordReset && newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a new password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.isPasswordReset) {
        // Verify OTP for password recovery
        final response = await Supabase.instance.client.auth.verifyOTP(
          type: OtpType.recovery,
          token: otp,
          email: widget.email,
        );
        
        if (response.session != null) {
          // Update password
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(password: newPasswordController.text),
          );
          
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password reset successful! Please login.')),
          );
          
          // Sign out so they have to login with the new password
          await Supabase.instance.client.auth.signOut();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } else {
        // Verify OTP for signup
        final response = await Supabase.instance.client.auth.verifyOTP(
          type: OtpType.signup,
          token: otp,
          email: widget.email,
        );
        
        if (response.session != null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification successful! You are now logged in.')),
          );
          // Return to main flow which handles auth state changes natively
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isLoading = true);
    try {
      if (widget.isPasswordReset) {
        await Supabase.instance.client.auth.resetPasswordForEmail(widget.email);
      } else {
        await Supabase.instance.client.auth.resend(
          type: OtpType.signup,
          email: widget.email,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP resent! Check your email.')),
      );
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.primary,
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Icon(Icons.mark_email_read_rounded, size: 80, color: AppColors.primary),
              const SizedBox(height: 24),
              Text(
                'Verify your email',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We sent a 6-digit code to\n${widget.email}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              PetTextField(
                controller: otpController,
                hintText: 'Enter 6-digit OTP',
                keyboardType: TextInputType.number,
              ),
              if (widget.isPasswordReset) ...[
                const SizedBox(height: 16),
                PetTextField(
                  controller: newPasswordController,
                  hintText: 'Enter new password',
                  isPassword: true,
                ),
              ],
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(
                      onPressed: _verifyOtp,
                      child: Text(
                        widget.isPasswordReset ? 'Reset Password' : 'Verify Account',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Didn't receive code?", style: GoogleFonts.poppins()),
                  TextButton(
                    onPressed: _isLoading ? null : _resendOtp,
                    child: Text(
                      'Resend',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
