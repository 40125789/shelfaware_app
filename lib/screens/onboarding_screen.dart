import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';


class OnboardingPage extends StatefulWidget {
  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  bool isLastPage = false;
  int _currentPage = 0;
  bool _isLoading = true;

  final Color primaryGreen = Color(0xFF4CAF50);
  final Color secondaryGreen = Color(0xFFE8F5E9);

  @override
  void initState() {
    super.initState();
    // Check first launch immediately to avoid flash
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
    
    // If not first launch, immediately navigate to auth page
    if (!isFirstLaunch && mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLaunch', false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: primaryGreen),
        ),
      );
    }
    
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, secondaryGreen.withOpacity(0.3)],
                ),
              ),
              child: PageView(
                controller: _pageController,
                onPageChanged: (int index) {
                  setState(() {
                    _currentPage = index;
                    isLastPage = index == 3;
                  });
                },
                children: [
                  OnboardingScreen(
                    title: 'Track Your Food',
                    description: 'Keep track of your food items and their expiry dates easily',
                    lottieUrl: 'https://lottie.host/f5897c2a-c807-4ac7-bb12-3deb8c11d3cf/rHv6KI31HZ.json',
                  ),
                  OnboardingScreen(
                    title: 'Discover Recipes',
                    description: 'Find recipes based on the ingredients you have at home',
                    lottieUrl: 'https://lottie.host/848e56b0-1545-4f6b-b37c-7c817048a664/1a4xHL8VL7.json',
                  ),
                  OnboardingScreen(
                    title: 'Share with the Local Community',
                    description: 'Connect with your community to share surplus food',
                    lottieUrl: 'https://lottie.host/4bd1d1bd-8f01-402b-bfb4-4b8e3b1d5223/ArWChMDOaN.json',
                  ),
                  OnboardingScreen(
                    title: 'View Food Waste Stats',
                    description: 'Monitor your food waste reduction journey',
                    lottieUrl: 'https://lottie.host/c42a1ab4-872d-42bd-bc55-07ee5706e866/PHwQ5KGzHF.json',
                  ),
                ],
              ),
            ),
            Positioned(
              top: 24,
              right: 24,
              child: TextButton(
                onPressed: () async {
                  await _completeOnboarding();
                  Navigator.pushReplacementNamed(context, '/home');
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.7),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text('Skip', style: TextStyle(color: primaryGreen, fontSize: 16, fontWeight: FontWeight.w500)),
              ),
            ),
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      4,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? primaryGreen : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: _currentPage == index ? [
                            BoxShadow(
                              color: primaryGreen.withOpacity(0.3),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ] : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (!isLastPage)
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: primaryGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryGreen.withOpacity(0.3),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_forward, color: Colors.white, size: 28),
                        onPressed: () {
                          _pageController.nextPage(
                            duration: Duration(milliseconds: 600),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: ElevatedButton(
                        onPressed: () async {
                          await _completeOnboarding();
                          Navigator.pushReplacementNamed(context, '/home');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 6,
                          shadowColor: primaryGreen.withOpacity(0.5),
                        ),
                        child: const Text(
                          'Get Started',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  final String title;
  final String description;
  final String lottieUrl;
  
  const OnboardingScreen({
    Key? key,
    required this.title,
    required this.description,
    required this.lottieUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 80, 32, 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.network(
            lottieUrl,
            height: MediaQuery.of(context).size.height * 0.38,
            fit: BoxFit.contain,
            repeat: true,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.38,
                child: Center(
                  child: Icon(Icons.error_outline, size: 50, color: Colors.grey),
                ),
              );
            },
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.black.withOpacity(0.85),
              height: 1.2,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.black.withOpacity(0.6),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 140), // Space for bottom navigation
        ],
      ),
    );
  }
}
