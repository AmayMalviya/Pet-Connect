import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;

  const PrimaryButton({
    super.key,
    required this.child,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom().merge(
          Theme.of(context).elevatedButtonTheme.style,
        ),
        onPressed: onPressed,
        child: child,
      ),
    );
  }
}
