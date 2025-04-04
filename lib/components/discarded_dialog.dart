import 'package:flutter/material.dart';

class DiscardedDialog extends StatefulWidget {
  final int maxQuantity;
  final Function(String, int) onSubmit;

  const DiscardedDialog({
    Key? key,
    required this.maxQuantity,
    required this.onSubmit,
  }) : super(key: key);

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
      title: const Text(
        "Reason for Discarding",
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Quantity to discard:"),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
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
                  ),
                ),
                const SizedBox(height: 16),
                const Text("Reason:"),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedReason,
                      hint: Text('Select reason'),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedReason = newValue;
                          _errorMessage = null;
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
                  ),
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("Cancel"),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey.shade700,
          ),
        ),
        ElevatedButton(
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
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}