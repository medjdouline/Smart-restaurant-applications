// lib/widgets/custom_input_field.dart
import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class CustomInputField extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final String? errorText;
  final TextInputType keyboardType;  // Type de clavier (normal, email, etc.)

  const CustomInputField({
    super.key,  // Changed to super parameter
    required this.hintText,
    this.obscureText = false,
    this.controller,
    this.onChanged,
    this.errorText,
    this.keyboardType = TextInputType.text,  // Par défaut, clavier normal
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.inputBgColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        obscureText: obscureText,
        keyboardType: keyboardType,  // Utilisation du type de clavier
        style: const TextStyle(
          color: AppTheme.accentColor,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppTheme.accentColor.withAlpha(178),  // Changed from withOpacity(0.7) to withAlpha(178)
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          border: InputBorder.none,
          errorText: errorText,
          errorStyle: const TextStyle(
            color: Colors.red,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}