import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelfaware_app/providers/donation_provider.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelfaware_app/models/food_category.dart';
import 'package:shelfaware_app/models/food_category_icons.dart';
import 'package:shelfaware_app/components/expiry_icon.dart';


class FoodItemCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String documentId;
  final Function(String) onEdit;
  final Function(String) onDelete;


  FoodItemCard({
    required this.data,
    required this.documentId,
    required this.onEdit,
    required this.onDelete,

  });

  @override
  _FoodItemCardState createState() => _FoodItemCardState();
}

class _FoodItemCardState extends State<FoodItemCard> {
  late DateTime expiryDate;

  @override
  void initState() {
    super.initState();
    final expiryTimestamp = widget.data['expiryDate'] as Timestamp;
    expiryDate = expiryTimestamp.toDate();
  }

  @override
  Widget build(BuildContext context) {
    final expiryTimestamp = widget.data['expiryDate'] as Timestamp;
    DateTime today = DateTime.now();
    int daysDifference = expiryDate.difference(today).inDays;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        leading: SizedBox(
          width: 40,
          height: 40,
          child: Icon(FoodCategoryIcons.getIcon(
            FoodCategory.values.firstWhere(
              (e) => e.toString().split('.').last == widget.data['category'],
              orElse: () => FoodCategory.values.first,
            ),
          )),
        ),
        title: Text(
          widget.data['productName'] ?? 'No Name',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "Quantity: ${widget.data['quantity']}\n${_formatExpiryDate(daysDifference)}",
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: ExpiryIcon(expiryTimestamp: expiryTimestamp),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert),
              onSelected: (String value) {
                if (value == 'edit') {
                  widget.onEdit(widget.documentId);
                } else if (value == 'delete') {
                  widget.onDelete(widget.documentId);
              
       
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatExpiryDate(int daysDifference) {
    if (daysDifference < 0) {
      return 'Expired';
    } else if (daysDifference == 0) {
      return 'Expires today';
    } else if (daysDifference <= 4) {
      return 'Expires in: $daysDifference day${daysDifference == 1 ? '' : 's'}';
    } else {
      return 'Expires in: $daysDifference day${daysDifference == 1 ? '' : 's'}';
    }
  }
}
