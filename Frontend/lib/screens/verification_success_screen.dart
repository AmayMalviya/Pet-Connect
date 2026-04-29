import 'package:flutter/material.dart';

class VerificationSuccessScreen extends StatelessWidget {
  static const routeName = '/verification-success';
  const VerificationSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_rounded,
                    size: 96, color: theme.colorScheme.primary),
                const SizedBox(height: 24),
                Text('Verified!',
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(
                  'Your KYC is complete. You can now access all shelter features.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/shelter-home'),
                  child: const Text('Go to Dashboard'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
