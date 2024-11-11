import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shelfaware_app/controllers/expiring_items_controller.dart';
import 'package:shelfaware_app/models/food_item.dart'; // Import your controller
import 'package:shelfaware_app/services/data_fetcher.dart';
import 'package:shelfaware_app/components/expired_items_tab.dart';
import 'package:shelfaware_app/components/expiring_items_tab.dart';

// 

class ExpiringItemsScreen extends StatelessWidget {
  const ExpiringItemsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Fetching the food items when the screen is loaded
    context.read<ExpiringItemsController>().fetchFoodItems();

    return DefaultTabController(
      length: 3,  // Three tabs
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green,
          title: Text("Notifications"),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Expiring Soon'),
              Tab(text: 'Expired Items'),
              Tab(text: 'Messages'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
          ),
        ),
        body: Consumer<ExpiringItemsController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return Center(child: CircularProgressIndicator()); // Show loading spinner
            }

            return TabBarView(
              children: [
                ExpiringItemsTab(expiringItems: controller.expiringSoonItems),
                ExpiredItemsTab(expiredItems: controller.expiredItems),
                
              ],
            );
          },
        ),
      ),
    );
  }
}
