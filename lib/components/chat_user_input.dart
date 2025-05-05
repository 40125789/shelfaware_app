import 'package:flutter/material.dart';

class UserInput extends StatelessWidget {
  final TextEditingController messageController;
  final VoidCallback onSend;

  UserInput({required this.messageController, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              decoration: InputDecoration(
                hintText: 'Type a message',
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : null,
                ),
                fillColor: isDarkMode ? Colors.grey[800] : null,
                filled: isDarkMode,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
              ),
              style: TextStyle(color: isDarkMode ? Colors.white : null),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: isDarkMode ? Colors.lightBlue[300] : null),
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}