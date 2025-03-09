import 'package:flutter/material.dart';


class EditableBio extends StatefulWidget {
  final String initialBio;
  final Function(String) onBioChanged;

  EditableBio({required this.initialBio, required this.onBioChanged});

  @override
  _EditableBioState createState() => _EditableBioState();
}

class _EditableBioState extends State<EditableBio> {
  late TextEditingController _bioController;
  bool _isEditingBio = false;
  FocusNode _focusNode = FocusNode(); // FocusNode to manage the text field focus

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.initialBio);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(  // Wrap the entire widget in SingleChildScrollView to prevent overflow
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isEditingBio = true; // Allow user to edit when tapping the text
                });
              },
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: _isEditingBio
                      ? Border.all(color: Colors.blue, width: 2) // Show border when editing
                      : Border.all(color: Colors.transparent),
                ),
                child: _isEditingBio
                    ? TextField(
                        controller: _bioController,
                        focusNode: _focusNode,  // Attach focus node to text field
                        decoration: InputDecoration(
                          hintText: 'Add a description to your bio...',
                          border: InputBorder.none, // Remove default border
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.all(10),
                        ),
                        maxLines: 3,
                        autofocus: true, // Focus the field when editing starts
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.initialBio.isEmpty
                                ? 'No bio available.'
                                : widget.initialBio,
                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          ),
                          Icon(
                            Icons.edit, // Edit icon
                            color: Colors.blue,
                            size: 20,
                          ),
                        ],
                      ),
              ),
            ),
          ),
          if (_isEditingBio)
            IconButton(
              icon: Icon(Icons.check, color: Colors.green), // Checkmark when editing
              onPressed: () {
                setState(() {
                  widget.onBioChanged(_bioController.text); // Save the bio
                  _isEditingBio = false; // Exit editing mode
                });
                // Show snackbar with a success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Bio updated successfully!')),
                );
              },
            ),
        ],
      ),
    );
  }
}
