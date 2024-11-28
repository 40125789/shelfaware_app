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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Mark Food Item"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("What would you like to do with this item?"),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _markAsConsumed();
              Navigator.pop(context);
            },
            child: const Text("Consumed"),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showDiscardReasonDialog();
            },
            child: const Text("Discarded"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("Cancel"),
        ),
      ],
    );
  }

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

  Future<void> _markAsConsumed() async {
    final foodItemRef = FirebaseFirestore.instance
        .collection('foodItems')
        .doc(widget.documentId);
    final foodItemSnapshot = await foodItemRef.get();

    if (foodItemSnapshot.exists) {
      await FirebaseFirestore.instance.collection('history').add({
        ...foodItemSnapshot.data()!,
        'status': 'consumed',
        'updatedOn': Timestamp.now(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
      });

      await foodItemRef.delete();

      // Ensure the widget is still mounted before showing the SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Food item marked as consumed')),
        );
      }
    }
  }
}
