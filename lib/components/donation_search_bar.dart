import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController searchController;
  final Function(String) onChanged;

  SearchBarWidget({required this.searchController, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: searchController,
        style: TextStyle(color: Colors.grey), // Set text color to grey
        decoration: InputDecoration(
          hintText: 'What are you looking for?',
          hintStyle: TextStyle(color: Colors.grey), // Set hint text color to grey
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
