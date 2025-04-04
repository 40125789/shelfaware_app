import 'package:flutter/material.dart';

class WatchlistToggleButton extends StatefulWidget {
  final bool isInWatchlist;
  final VoidCallback onToggle;

  const WatchlistToggleButton({
    Key? key,
    required this.isInWatchlist,
    required this.onToggle,
  }) : super(key: key);

  @override
  State<WatchlistToggleButton> createState() => _WatchlistToggleButtonState();
}

class _WatchlistToggleButtonState extends State<WatchlistToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(parent: _controller, curve: Curves.elasticInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode 
        ? Colors.grey[800]
        : Colors.white.withOpacity(0.9);
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black54 : Colors.black12, 
            blurRadius: 4, 
            offset: const Offset(0, 2)
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            _controller.forward(from: 0.0);
            widget.onToggle();
          },
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    widget.isInWatchlist ? Icons.star : Icons.star_border,
                    color: widget.isInWatchlist 
                        ? Colors.amber 
                        : isDarkMode ? Colors.grey[400] : Colors.grey,
                    size: 24,
                    key: ValueKey<bool>(widget.isInWatchlist),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
