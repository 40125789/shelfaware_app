import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelfaware_app/models/mark_food.dart';
import 'package:shelfaware_app/repositories/mark_food_respository.dart';
import 'package:shelfaware_app/services/mark_food_service.dart';
import 'package:shelfaware_app/components/consumed_dialog.dart';
import 'package:shelfaware_app/components/discarded_dialog.dart';
import 'package:shelfaware_app/utils/date_formatter.dart';



class MarkFoodDialog extends StatefulWidget {
  final String documentId;

  MarkFoodDialog({required this.documentId});

  @override
  _MarkFoodDialogState createState() => _MarkFoodDialogState();
}

class _MarkFoodDialogState extends State<MarkFoodDialog> {
  final MarkFoodService _markFoodService = MarkFoodService();
  late MarkFood _foodItem;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchFoodItemData();
  }

  Future<void> _fetchFoodItemData() async {
    final foodItem = await _markFoodService.getFoodItem(widget.documentId);
    if (foodItem != null) {
      setState(() {
        _foodItem = foodItem;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MarkFood?>(
      future: _markFoodService.getFoodItem(widget.documentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Center(child: Text("No data available"));
        }

        _foodItem = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_foodItem.productName != null &&
                  _foodItem.productName!.isNotEmpty)
                Text(
                  _foodItem.productName!,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              SizedBox(height: 16),
              if (_foodItem.productImage != null &&
                  _foodItem.productImage!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Image.network(
                    _foodItem.productImage!,
                    height: 150,
                    width: 150,
                    fit: BoxFit.contain,
                  ),
                ),
              if (_foodItem.quantity > 0)
                Row(
                  children: [
                    Icon(Icons.confirmation_number,
                        size: 24, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Quantity: ${_foodItem.quantity}',
                        style: TextStyle(fontSize: 16)),
                  ],
                ),
              if (_foodItem.expiryDate != null)
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 24, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                        'Expiry Date: ${formatExpiryDate(Timestamp.fromDate(_foodItem.expiryDate!))}',
                        style: TextStyle(fontSize: 16)),
                  ],
                ),
              if (_foodItem.notes != null && _foodItem.notes!.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.note, size: 24, color: Colors.grey),
                    SizedBox(width: 8),
                    Expanded(
                        child: Text('Notes: ${_foodItem.notes}',
                            style: TextStyle(fontSize: 16))),
                  ],
                ),
              if (_foodItem.storageLocation != null &&
                  _foodItem.storageLocation!.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.location_on, size: 24, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Storage Location: ${_foodItem.storageLocation}',
                        style: TextStyle(fontSize: 16)),
                  ],
                ),
              SizedBox(height: 24),
              Text(
                "Take action on this item",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              SizedBox(height: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _showConsumedQuantityDialog();
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.green,
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
                        Navigator.pop(context);
                        _showDiscardReasonDialog();
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red,
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

  void _showConsumedQuantityDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ConsumedDialog(
          maxQuantity: _foodItem.quantity,
          onSubmit: (quantity) async {
            await _markFoodService.markAsConsumed(_foodItem, quantity);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Food item consumed')),
            );
          },
        );
      },
    );
  }

  void _showDiscardReasonDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DiscardedDialog(
          maxQuantity: _foodItem.quantity,
          onSubmit: (reason, quantity) async {
            await _markFoodService.markAsDiscarded(_foodItem, reason, quantity);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Item marked as discarded')),
            );
          },
        );
      },
    );
  }
}
