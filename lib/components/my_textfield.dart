import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
 final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final IconButton? suffixIcon;  // Make suffixIcon nullable

  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false, 
    this.suffixIcon,  // Mark as optional
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
        
          filled: true,
          hintText: hintText,
        ),
      ),
    );
  }
}
