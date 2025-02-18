import 'package:flutter/material.dart';

class ConsumedDialog extends StatefulWidget {
  final int maxQuantity;
  final Function(int) onSubmit;

  ConsumedDialog({required this.maxQuantity, required this.onSubmit});

  @override
  _ConsumedDialogState createState() => _ConsumedDialogState();
}

class _ConsumedDialogState extends State<ConsumedDialog> {
  int _selectedQuantity = 1;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Consumed Quantity", textAlign: TextAlign.center),
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<int>(
                value: _selectedQuantity,
                onChanged: (newValue) {
                  setState(() {
                    _selectedQuantity = newValue!;
                  });
                },
                items: List.generate(widget.maxQuantity, (index) {
                  return DropdownMenuItem(
                    value: index + 1,
                    child: Text('${index + 1}'),
                  );
                }),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (_selectedQuantity > 0) {
              widget.onSubmit(_selectedQuantity);
              Navigator.pop(context);
            } else {
              setState(() {
                _errorMessage = 'Please select a quantity';
              });
            }
          },
          child: const Text("Submit"),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("Cancel"),
        ),
      ],
    );
  }
}