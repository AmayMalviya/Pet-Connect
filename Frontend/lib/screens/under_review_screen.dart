import 'package:flutter/material.dart';

class UnderReviewScreen extends StatelessWidget {
  static const routeName = '/under-review';
  const UnderReviewScreen({super.key});

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
                Icon(Icons.hourglass_top_rounded,
                    size: 96, color: theme.colorScheme.secondary),
                const SizedBox(height: 24),
                Text('Under Review',
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(
                  'Your documents are being reviewed by our team. We will notify you shortly.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
