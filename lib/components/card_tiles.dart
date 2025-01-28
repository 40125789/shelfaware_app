import 'package:flutter/material.dart';

class CardTiles extends StatelessWidget {
  final bool isWeekly;
  final Map<String, dynamic> highestFoodWaste;
  final Map<String, dynamic> highestFoodSaved;

  // Constructor to accept the data
  CardTiles({
    required this.isWeekly,
    required this.highestFoodWaste,
    required this.highestFoodSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Card for Food Waste
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          color: Colors.red, // Entire card is red for food waste
          elevation: 5,
          child: ExpansionTile(
            leading: Icon(
              Icons.delete,
              color: Colors.white, // White icon for visibility on red background
            ),
            title: Text(
              isWeekly ? "Week with Highest Food Waste" : "Month with Highest Food Waste",
              style: TextStyle(
                color: Colors.white, // White text for the title
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              "${highestFoodWaste['period']} - ${highestFoodWaste['value'].toInt()} items wasted",  // Convert to int to remove decimals
              style: TextStyle(
                color: Colors.white, // White text for the subtitle
                fontSize: 16,
                fontWeight: FontWeight.bold, // Bold the text
              ),
            ),
            children: <Widget>[
              // List of food waste items, using 'productName'
              ListView.builder(
                shrinkWrap: true, // To prevent scrolling issues in the expanded view
                physics: NeverScrollableScrollPhysics(),
                itemCount: highestFoodWaste['foodItems']?.length ?? 0,
                itemBuilder: (context, index) {
                  // Assuming 'foodItems' is a list of maps with 'productName'
                  return ListTile(
                    title: Text(
                      highestFoodWaste['foodItems'][index]['productName'],  // Accessing 'productName'
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        SizedBox(height: 15), // Adding space between cards

        // Card for Food Saved
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          color: Colors.green, // Entire card is green for food saved
          elevation: 5,
          child: ExpansionTile(
            leading: Icon(
              Icons.check_circle,
              color: Colors.white, // White icon for visibility on green background
            ),
            title: Text(
              isWeekly ? "Week with Highest Food Saved" : "Month with Highest Food Saved",
              style: TextStyle(
                color: Colors.white, // White text for the title
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              "${highestFoodSaved['period']} - ${highestFoodSaved['value'].toInt()} items saved", // Convert to int to remove decimals
              style: TextStyle(
                color: Colors.white, // White text for the subtitle
                fontSize: 16,
                fontWeight: FontWeight.bold, // Bold the text
              ),
            ),
            children: <Widget>[
              // List of food saved items, using 'productName'
              ListView.builder(
                shrinkWrap: true, // To prevent scrolling issues in the expanded view
                physics: NeverScrollableScrollPhysics(),
                itemCount: highestFoodSaved['foodItems']?.length ?? 0,
                itemBuilder: (context, index) {
                  // Assuming 'foodItems' is a list of maps with 'productName'
                  return ListTile(
                    title: Text(
                      highestFoodSaved['foodItems'][index]['productName'],  // Accessing 'productName'
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
