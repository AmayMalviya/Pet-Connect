import 'package:flutter/material.dart';

class PetTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isPassword;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  const PetTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.isPassword = false,
    this.suffixIcon,
    this.keyboardType,
  });

  @override
  State<PetTextField> createState() => _PetTextFieldState();
}

class _PetTextFieldState extends State<PetTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: widget.isPassword ? _obscureText : false,
      keyboardType: widget.keyboardType,
      decoration: InputDecoration(
        hintText: widget.hintText,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () => setState(() => _obscureText = !_obscureText),
              )
            : widget.suffixIcon,
      ),
      textInputAction: TextInputAction.next,
    );
  }
}
