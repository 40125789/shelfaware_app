import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shelfaware_app/models/food_history.dart';
import 'package:shelfaware_app/services/history_service.dart';

class HistoryPage extends StatefulWidget {
  final String userId; // Assuming the userId is passed to this page

  HistoryPage({required this.userId});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<FoodHistory>> _foodItems;

  @override
  void initState() {
    super.initState();
    _foodItems = HistoryService()
        .getHistoryItems(widget.userId); // Fetch the user's food items
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Food Item History'),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<List<FoodHistory>>(
        future: _foodItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No food items found.'));
          }

          // Display the list of food items
          List<FoodHistory> foodItems = snapshot.data!;
          return ListView.builder(
            itemCount: foodItems.length,
            itemBuilder: (context, index) {
              final foodItem = foodItems[index];

              //format the expiry date
              final formattedExpiryDate =
                  DateFormat('dd MMM yyyy').format(foodItem.expiryDate.toDate());

                  // Icon based on status
              Icon statusIcon;
              Color iconColor;

              switch (foodItem.status) {
                case 'consumed':
                  statusIcon = Icon(Icons.check_circle, color: Colors.green);
                  iconColor = Colors.green;
                  break;
                case 'discarded':
                  statusIcon = Icon(Icons.delete, color: Colors.red);
                  iconColor = Colors.red;
                  break;
                default:
                  statusIcon = Icon(Icons.pending, color: Colors.grey);
                  iconColor = Colors.grey;
              }


              return Card(
                margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                elevation: 5,
                child: ListTile(
                  contentPadding: EdgeInsets.all(15),
                title: Text(
                  foodItem.productName,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                    // ignore: unnecessary_brace_in_string_interps
                    'Expiry: ${formattedExpiryDate}\nStatus: ${foodItem.status}',
                    style: TextStyle(color: Colors.grey[600]),
                ),
                trailing: statusIcon,
                onTap: () {
                  // Navigate to the Mark Food Dialog (or other actions as needed)
                
              
            },
            ),
                       );
                      },
                    );
                  },
                ),
              );
            }
}
          
        
      
    


