import 'package:flutter/material.dart';
import 'package:shelfaware_app/controllers/bottom_nav_controller.dart';
import 'package:shelfaware_app/screens/add_food_item.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class BottomNavigationBarComponent extends ConsumerStatefulWidget {
  final PageController pageController;

  const BottomNavigationBarComponent({Key? key, required this.pageController})
      : super(key: key);

  @override
  ConsumerState<BottomNavigationBarComponent> createState() =>
      _BottomNavigationBarComponentState();
}

class _BottomNavigationBarComponentState
    extends ConsumerState<BottomNavigationBarComponent> {
  bool _isPressed = false;

  void _onFabTap() {
    setState(() => _isPressed = true);

    Future.delayed(const Duration(milliseconds: 150), () {
      setState(() => _isPressed = false);
    });

    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: AddFoodItem(foodItems: []),
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    ref.read(bottomNavControllerProvider.notifier).navigateTo(index);
    widget.pageController.jumpToPage(index);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.pageController.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(bottomNavControllerProvider);
    final width = MediaQuery.of(context).size.width;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          iconSize: 25,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Recipes'),
            BottomNavigationBarItem(
                icon: Icon(Icons.food_bank), label: 'Donations'),
            BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart), label: 'Statistics'),
          ],
        ),
        Positioned(
          left: width * 0.5 - 30,
          bottom: 30,
          child: Semantics(
            label: 'Add food item',
            button: true,
            child: GestureDetector(
              onTap: _onFabTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOut,
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _isPressed ? Colors.green[800] : Colors.green,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.transparent,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    transitionBuilder: (child, animation) => 
                      FadeTransition(opacity: animation, child: child),
                    child: Icon(
                      Icons.add,
                      key: ValueKey<bool>(_isPressed),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
