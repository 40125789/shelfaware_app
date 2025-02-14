import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MarkFoodDialog extends StatefulWidget {
  final String documentId;

  const MarkFoodDialog({Key? key, required this.documentId}) : super(key: key);

  @override
  _MarkFoodDialogState createState() => _MarkFoodDialogState();
}

class _MarkFoodDialogState extends State<MarkFoodDialog> {
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _consumedQuantityController = TextEditingController();
  late Map<String, dynamic> _foodItemData;
  int _selectedConsumedQuantity = 1; // Default value for consumed quantity

  @override
  void initState() {
    super.initState();
    _fetchFoodItemData();
  }

  // Fetch food item details from Firestore
  Future<void> _fetchFoodItemData() async {
    final foodItemRef = FirebaseFirestore.instance
        .collection('foodItems')
        .doc(widget.documentId);
    final foodItemSnapshot = await foodItemRef.get();
    if (foodItemSnapshot.exists) {
      setState(() {
        _foodItemData = foodItemSnapshot.data()!;
        _selectedConsumedQuantity = _foodItemData['quantity'] ?? 1; // Set initial consumed quantity
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('foodItems').doc(widget.documentId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Center(child: Text("No data available"));
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display the food item name first
              if (_foodItemData['productName'] != null && _foodItemData['productName'].isNotEmpty)
                Text(
                  _foodItemData['productName'],
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              SizedBox(height: 16),

              // Display the food item image
              if (_foodItemData['productImage'] != null && _foodItemData['productImage'].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Image.network(
                    _foodItemData['productImage'],
                    height: 150,
                    width: 150,
                    fit: BoxFit.contain,
                  ),
                ),

              // Display Food Item Fields with Icons and improved font sizes
              if (_foodItemData['quantity'] != null && _foodItemData['quantity'] > 0)
                Row(
                  children: [
                    Icon(Icons.confirmation_number, size: 24, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Quantity: ${_foodItemData['quantity']}', style: TextStyle(fontSize: 16)),
                  ],
                ),
              if (_foodItemData['expiryDate'] != null)
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 24, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Expiry Date: ${_formatExpiryDate(_foodItemData['expiryDate'])}', style: TextStyle(fontSize: 16)),
                  ],
                ),
              if (_foodItemData['notes'] != null && _foodItemData['notes'].isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.note, size: 24, color: Colors.grey),
                    SizedBox(width: 8),
                    Expanded(child: Text('Notes: ${_foodItemData['notes']}', style: TextStyle(fontSize: 16))),
                  ],
                ),
              if (_foodItemData['storageLocation'] != null && _foodItemData['storageLocation'].isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.location_on, size: 24, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Storage Location: ${_foodItemData['storageLocation']}', style: TextStyle(fontSize: 16)),
                  ],
                ),

              SizedBox(height: 24),

              // Add Text Above Buttons
              Text(
                "Take action on this item",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              SizedBox(height: 8),

              // Buttons for Marking as Consumed or Discarded
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _showConsumedQuantityDialog();
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Colors.green,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          const Text("Consumed"),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);  // Close the dialog
                        _showDiscardReasonDialog();
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Colors.red,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.white),
                          SizedBox(width: 8),
                          const Text("Discarded"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Show reason dialog for discarding
  void _showDiscardReasonDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Reason for Discarding"),
          content: TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: "Reason",
              hintText: "E.g., expired, spoiled, etc.",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                String reason = _reasonController.text.trim();
                if (reason.isNotEmpty) {
                  _markAsDiscarded(reason);
                } else {
                  // Ensure context is valid before showing a snack bar
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please provide a reason')),
                    );
                  }
                }
                Navigator.pop(context);
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
      },
    );
  }

  // Show consumed quantity dialog with dropdown
  void _showConsumedQuantityDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Quantity Consumed"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<int>(
                value: _selectedConsumedQuantity,
                onChanged: (newValue) {
                  setState(() {
                    _selectedConsumedQuantity = newValue!;
                  });
                },
                items: List.generate(_foodItemData['quantity'], (index) {
                  return DropdownMenuItem(
                    value: index + 1,
                    child: Text('${index + 1}'),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_selectedConsumedQuantity > 0) {
                  _markAsConsumed(_selectedConsumedQuantity);
                } else {
                  // Ensure context is valid before showing a snack bar
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a valid quantity')),
                    );
                  }
                }
                Navigator.pop(context);
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
      },
    );
  }

  // Mark item as discarded
  Future<void> _markAsDiscarded(String reason) async {
    final foodItemRef = FirebaseFirestore.instance
        .collection('foodItems')
        .doc(widget.documentId);
    final foodItemSnapshot = await foodItemRef.get();

    if (foodItemSnapshot.exists) {
      await FirebaseFirestore.instance.collection('history').add({
        ...foodItemSnapshot.data()!,
        'reason': reason,
        'status': 'discarded',
        'updatedOn': Timestamp.now(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
      });

      await foodItemRef.delete();

      // Ensure the widget is still mounted before showing the SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Food item marked as discarded')),
        );
      }
    }
  }

  // Mark item as consumed
Future<void> _markAsConsumed(int quantity) async {
  final foodItemRef = FirebaseFirestore.instance
      .collection('foodItems')
      .doc(widget.documentId);
  final foodItemSnapshot = await foodItemRef.get();

  if (foodItemSnapshot.exists) {
    Map<String, dynamic> foodItemData = foodItemSnapshot.data()!;
    int remainingQuantity = foodItemData['quantity'] - quantity;

    // Update history collection with consumed quantity
    await FirebaseFirestore.instance.collection('history').add({
      ...foodItemData,
      'status': 'consumed',
      'consumedQuantity': quantity,
      'updatedOn': Timestamp.now(),
      'userId': FirebaseAuth.instance.currentUser?.uid,
    });

    // If remaining quantity is 0, delete the food item from the inventory
    if (remainingQuantity == 0) {
      await foodItemRef.delete();

      // Show the snack bar and close the dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Food item consumed and removed from inventory')),
        );
      }
    } else {
      // Otherwise, just update the remaining quantity
      await foodItemRef.update({'quantity': remainingQuantity});

      // Show the snack bar and close the dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Food item consumed')),
        );
      }
    }

    // Close the dialog and return to the previous page
    Navigator.pop(context);
  }
}



  // Format expiry date
  String _formatExpiryDate(Timestamp expiryTimestamp) {
    DateTime expiryDate = expiryTimestamp.toDate();
    return "${expiryDate.day}/${expiryDate.month}/${expiryDate.year}";
  }
}