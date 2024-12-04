import 'package:flutter/material.dart';
import 'package:shelfaware_app/components/my_stats_tab.dart';

class AdditionalStatsWidget extends StatelessWidget {
  final String userId;

  const AdditionalStatsWidget({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: fetchAdditionalStats(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text("No stats available"));
        }

        var data = snapshot.data!;
        String highestSavedMonth = data["highestSavedMonth"];
        String mostDiscardedCategory = data["mostDiscardedCategory"];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green,
                child: const Icon(Icons.calendar_today, color: Colors.white),
              ),
              title: Text("Month with Highest Food Saved"),
              subtitle: Text(highestSavedMonth),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.red,
                child: const Icon(Icons.food_bank, color: Colors.white),
              ),
              title: Text("Most Discarded Food Category"),
              subtitle: Text(mostDiscardedCategory),
            ),
          ],
        );
      },
    );
  }
  
  fetchAdditionalStats(String userId) {}
}
