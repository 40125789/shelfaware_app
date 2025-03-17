import 'package:flutter/material.dart';

class FavouriteButton extends StatefulWidget {
  final bool isFavourite;
  final VoidCallback onPressed;

  const FavouriteButton({
    Key? key,
    required this.isFavourite,
    required this.onPressed,
  }) : super(key: key);

  @override
  _FavouriteButtonState createState() => _FavouriteButtonState();
}

class _FavouriteButtonState extends State<FavouriteButton> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize the controller with a duration of 200ms
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    // Define the scale range from 1.0 to 1.2 (20% increase in size)
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    // Trigger the animation forward and reverse
    _controller.forward().then((_) => _controller.reverse());
    // Execute the passed callback function
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Scale the button based on the animation value
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: IconButton(
            icon: Icon(
              widget.isFavourite ? Icons.favorite : Icons.favorite_border,
              color: widget.isFavourite ? Colors.red : Colors.grey,
            ),
            onPressed: _handleTap,
          ),
        );
      },
    );
  }
}
