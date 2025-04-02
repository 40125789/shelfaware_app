import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shelfaware_app/services/trends_service.dart';
import 'package:shelfaware_app/repositories/trends_repository.dart';

class TrendsTab extends StatefulWidget {
  final String userId;

  TrendsTab({required this.userId});

  @override
  _TrendsTabState createState() => _TrendsTabState();
}

class _TrendsTabState extends State<TrendsTab> with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> trendsFuture;
  late Future<String> joinDurationFuture;
  late TrendsService trendsService;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    TrendsRepository trendsRepository = TrendsRepository(auth: FirebaseAuth.instance, firestore: FirebaseFirestore.instance);
    trendsService = TrendsService(trendsRepository);
    trendsFuture = trendsService.fetchTrends(widget.userId);
    joinDurationFuture = trendsService.fetchJoinDuration(widget.userId);
    
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500), // slightly longer for smoother transitions
    );
    
    // Delay animation start to allow UI to build first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.green.shade300 : Colors.green.shade700;
    final cardBgGradient = isDark 
      ? [Colors.grey.shade800, Colors.grey.shade900] 
      : [Colors.white, Colors.green.shade50];
    final cardTextColor = isDark ? Colors.white : Colors.green.shade800;
    final shadowColor = isDark ? Colors.black54 : Colors.black12;

    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: trendsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error: ${snapshot.error}', 
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.containsKey("error")) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 48, color: Colors.amber),
                  SizedBox(height: 16),
                  Text(snapshot.data?["error"] ?? 'No insights available yet.',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          var foodInsights = snapshot.data!["foodInsights"];
          var donationStats = snapshot.data!["donationStats"];

          int totalDonations = donationStats["givenDonations"] +
              donationStats["receivedDonations"];

          return FutureBuilder<String>(
            future: joinDurationFuture,
            builder: (context, joinSnapshot) {
              if (joinSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              String joinDuration = joinSnapshot.data ?? "Unknown duration";

                return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _animationController,
                        curve: Interval(0.0, 0.3, curve: Curves.easeInOut),
                      ),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(0, -0.2),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(0.0, 0.3, curve: Curves.easeOutCubic),
                        )),
                        child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                          colors: [Colors.green.shade300, Colors.green.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                          BoxShadow(
                            color: shadowColor,
                            offset: Offset(0, 3),
                            blurRadius: 6,
                          ),
                          ],
                        ),
                        child: Column(
                          children: [
                          Icon(Icons.celebration, color: Colors.white, size: 24),
                          SizedBox(height: 8),
                          Text(
                            "$joinDuration",
                            style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            ),
                          ),
                          Text(
                            "since you've joined!",
                            style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            ),
                          ),
                          ],
                        ),
                        ),
                      ),
                    ),
                      SizedBox(height: 30),
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(0.2, 0.4, curve: Curves.easeInOut),
                        ),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(-0.2, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(0.2, 0.4, curve: Curves.easeOutCubic),
                          )),
                          child: _buildSectionHeader('Food Trends', Icons.restaurant, primaryColor),
                        ),
                      ),
                      SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        children: [
                          _buildAnimatedCard('Top Wasted Item',
                              foodInsights["mostWastedFoodItem"], '🚯', cardBgGradient, cardTextColor, shadowColor, 0.3, 0.1),
                          _buildAnimatedCard('Top Wasted Category',
                              foodInsights["mostWastedFoodCategory"], '🔖', cardBgGradient, cardTextColor, shadowColor, 0.35, 0.1),
                          _buildAnimatedCard('Top Discard Reason',
                              foodInsights["mostCommonDiscardReason"], '🚮', cardBgGradient, cardTextColor, shadowColor, 0.4, 0.1),
                          _buildAnimatedCard(
                              'Average Discard Rate',
                              foodInsights["averageTimeBetweenAddingAndDiscarding"],
                              '⏰', cardBgGradient, cardTextColor, shadowColor, 0.45, 0.1),
                        ],
                      ),
                      SizedBox(height: 30),
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(0.5, 0.7, curve: Curves.easeInOut),
                        ),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(-0.2, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(0.5, 0.7, curve: Curves.easeOutCubic),
                          )),
                          child: _buildSectionHeader('Donation Trends', Icons.volunteer_activism, primaryColor),
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildAnimatedProgressBar(
                          'Donations Given',
                          donationStats["givenDonations"],
                          totalDonations,
                          isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                          isDark, 0.6, 0.1),
                      SizedBox(height: 16),
                      _buildAnimatedProgressBar(
                          'Donations Received',
                          donationStats["receivedDonations"],
                          totalDonations,
                          isDark ? Colors.green.shade300 : Colors.green.shade700,
                          isDark, 0.7, 0.1),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 22, 
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedCard(String title, String value, String emoji, List<Color> gradientColors, 
      Color textColor, Color shadowColor, double intervalStart, double intervalDuration) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _animationController,
        curve: Interval(intervalStart, intervalStart + intervalDuration, curve: Curves.easeInOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Interval(intervalStart, intervalStart + intervalDuration, curve: Curves.easeOutCubic),
        )),
        child: _buildCard(title, value, emoji, gradientColors, textColor, shadowColor),
      ),
    );
  }

  Widget _buildCard(String title, String value, String emoji, List<Color> gradientColors, Color textColor, Color shadowColor) {
    return Card(
      elevation: 6, // reduced from 8
      shadowColor: shadowColor.withOpacity(0.5), // reduced opacity
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withOpacity(0.2), // reduced opacity
              blurRadius: 8,
              spreadRadius: 1,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: TextStyle(fontSize: 30),
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Flexible(
              child: Text(
                value,
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedProgressBar(String title, int value, int total, Color color, bool isDark, double intervalStart, double intervalDuration) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _animationController,
        curve: Interval(intervalStart, intervalStart + intervalDuration, curve: Curves.easeInOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0.2, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Interval(intervalStart, intervalStart + intervalDuration, curve: Curves.easeOutCubic),
        )),
        child: _buildProgressBar(title, value, total, color, isDark),
      ),
    );
  }

  Widget _buildProgressBar(String title, int value, int total, Color color, bool isDark) {
    double percentage = total > 0 ? (value / total) * 100 : 0;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title, 
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.w600
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: total > 0 ? value / total : 0),
              duration: Duration(milliseconds: 1000), // reduced from 1500
              curve: Curves.easeOutQuart, // smoother curve
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor: color.withOpacity(0.2),
                  color: color,
                  minHeight: 20,
                );
              },
            ),
          ),
          SizedBox(height: 8),
          Text(
            '$value donation${value != 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}