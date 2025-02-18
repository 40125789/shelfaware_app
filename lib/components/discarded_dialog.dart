import 'package:flutter/material.dart';


class DiscardedDialog extends StatefulWidget {
  final int maxQuantity;
  final Function(String, int) onSubmit;

  DiscardedDialog({required this.maxQuantity, required this.onSubmit});

  @override
  _DiscardedDialogState createState() => _DiscardedDialogState();
}

class _DiscardedDialogState extends State<DiscardedDialog> {
  int _selectedQuantity = 1;
  String? _selectedReason;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Reason for Discarding", textAlign: TextAlign.center),
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
              DropdownButton<String>(
                value: _selectedReason,
                hint: Text('Select reason'),
                onChanged: (newValue) {
                  setState(() {
                    _selectedReason = newValue;
                  });
                },
                items: [
                  'Expired', 'Spoiled', 'Damaged', 'Other'
                ].map((reason) {
                  return DropdownMenuItem<String>(
                    value: reason,
                    child: Text(reason),
                  );
                }).toList(),
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
            if (_selectedQuantity > 0 && _selectedReason != null) {
              widget.onSubmit(_selectedReason!, _selectedQuantity);
              Navigator.pop(context);
            } else {
              setState(() {
                _errorMessage = 'Please provide a reason and select a quantity';
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