import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelfaware_app/models/mark_food.dart';
import 'package:shelfaware_app/services/mark_food_service.dart';
import 'package:shelfaware_app/components/consumed_dialog.dart';
import 'package:shelfaware_app/components/discarded_dialog.dart';
import 'package:shelfaware_app/utils/date_formatter.dart';

class MarkFoodDialog extends StatefulWidget {
  final String documentId;

  const MarkFoodDialog({required this.documentId, Key? key}) : super(key: key);

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final labelColor = isDarkMode ? Colors.white70 : Colors.grey[600];
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.white;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: FutureBuilder<MarkFood?>(
        future: _markFoodService.getFoodItem(widget.documentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const SizedBox(
              height: 200,
              child: Center(child: Text("No data available")),
            );
          }

          _foodItem = snapshot.data!;

          return Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with product name and image
                  if (_foodItem.productName != null && _foodItem.productName!.isNotEmpty)
                    Center(
                      child: Text(
                        _foodItem.productName!,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (_foodItem.productImage != null && _foodItem.productImage!.isNotEmpty)
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _foodItem.productImage!,
                          height: 170,
                          width: 170,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                            Container(
                              height: 170,
                              width: 170,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                            ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  
                  // Product details card
                  Card(
                    elevation: 2,
                    color: cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_foodItem.quantity > 0)
                            _buildInfoRow(Icons.confirmation_number, 'Quantity', '${_foodItem.quantity}', Colors.blue, textColor, labelColor),
                          
                          if (_foodItem.expiryDate != null)
                            _buildInfoRow(
                              Icons.calendar_today, 
                              'Expiry Date', 
                              formatExpiryDate(Timestamp.fromDate(_foodItem.expiryDate!)), 
                              Colors.orange,
                              textColor,
                              labelColor
                            ),
                          
                          if (_foodItem.storageLocation != null && _foodItem.storageLocation!.isNotEmpty)
                            _buildInfoRow(
                              Icons.location_on, 
                              'Storage', 
                              _foodItem.storageLocation!, 
                              Colors.red,
                              textColor,
                              labelColor
                            ),
                            
                          if (_foodItem.notes != null && _foodItem.notes!.isNotEmpty)
                            _buildInfoRow(Icons.note, 'Notes', _foodItem.notes!, Colors.grey, textColor, labelColor),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action section
                  Center(
                    child: Text(
                      "Take Action",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _showConsumedQuantityDialog,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                "Consumed",
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _showDiscardReasonDialog,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.delete, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                "Discarded",
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor, Color textColor, Color? labelColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: labelColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showConsumedQuantityDialog() {
    if (_foodItem.quantity == 1) {
      // If quantity is 1, consume directly without showing the dialog
      _markFoodService.markAsConsumed(_foodItem, 1).then((_) {
        setState(() {
          _foodItem.quantity = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Food item consumed'),
            backgroundColor: Colors.green,
          ),
        );

        Future.delayed(const Duration(milliseconds: 300), () {
          Navigator.pop(context);
        });
      });
    } else if (_foodItem.quantity > 1) {
      // If quantity is greater than 1, show the dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return ConsumedDialog(
            maxQuantity: _foodItem.quantity,
            onSubmit: (quantity) async {
              await _markFoodService.markAsConsumed(_foodItem, quantity);
              setState(() {
                _foodItem.quantity -= quantity;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Food item consumed'),
                  backgroundColor: Colors.green,
                ),
              );
              if (_foodItem.quantity == 0) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  Navigator.pop(context);
                });
              }
            },
          );
        },
      );
    }
  }

  void _showDiscardReasonDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DiscardedDialog(
          maxQuantity: _foodItem.quantity,
          onSubmit: (reason, quantity) async {
            await _markFoodService.markAsDiscarded(_foodItem, reason, quantity);
            setState(() {
              _foodItem.quantity -= quantity;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Item marked as discarded'),
                backgroundColor: Colors.red,
              ),
            );
            if (_foodItem.quantity == 0) {
              Future.delayed(const Duration(milliseconds: 300), () {
                Navigator.pop(context);
              });
            }
          },
        );
      },
    );
  }
}
