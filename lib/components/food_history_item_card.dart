import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shelfaware_app/models/food_history.dart';

class FoodHistoryItemCard extends StatelessWidget {
  final FoodHistory foodItem;
  final bool isRecreateMode;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;

  FoodHistoryItemCard({
    required this.foodItem,
    required this.isRecreateMode,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      elevation: 3,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: foodItem.status == 'consumed' ? Colors.green : Colors.red,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(15),
        title: Text(
          '${foodItem.productName} x ${foodItem.quantity}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Text(
              foodItem.status == 'consumed' ? 'Consumed' : 'Discarded',
              style: TextStyle(
                color:
                    foodItem.status == 'consumed' ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              ' on ${DateFormat('dd MMM yyyy').format(foodItem.updatedOn.toDate())}',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.normal,
              ),
            ),
            Spacer(),
            Icon(
              foodItem.status == 'consumed' ? Icons.check : Icons.delete,
              color: foodItem.status == 'consumed' ? Colors.green : Colors.red,
            ),
          ],
        ),
        leading: isRecreateMode
            ? Checkbox(
                value: isSelected,
                onChanged: onChanged,
              )
            : null,
      ),
    );
  }
}
