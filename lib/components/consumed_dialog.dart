import 'package:flutter/material.dart';

class ConsumedDialog extends StatefulWidget {
  final int maxQuantity;
  final Function(int) onSubmit;

  const ConsumedDialog({
    Key? key,
    required this.maxQuantity,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _ConsumedDialogState createState() => _ConsumedDialogState();
}

class _ConsumedDialogState extends State<ConsumedDialog> {
  int _selectedQuantity = 1;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        "Consumed Quantity",
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: _selectedQuantity,
                    onChanged: (newValue) {
                      setState(() {
                        _selectedQuantity = newValue!;
                        _errorMessage = null;
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
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[700],
          ),
          child: const Text("Cancel"),
        ),
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
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).primaryColor,
          ),
          child: const Text("Submit"),
        ),
      ],
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
