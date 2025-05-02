import 'package:flutter/material.dart';

// Code adapted from:
// Mitch Koko. "Modern Login UI • Flutter Auth Tutorial." YouTube, 14 Oct. 2024, 
// https://www.youtube.com/watch?v=Dh-cTQJgM-Q


class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final IconButton? suffixIcon;
  final String? errorText; // Optional error text

  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.suffixIcon,
    this.errorText, required Null Function(dynamic value) onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          suffixIcon: suffixIcon,
          errorText: errorText, // Now it will work!
          border: const OutlineInputBorder(), 
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          filled: true,
          hintText: hintText,
        ),
      ),
    );
  }
}
