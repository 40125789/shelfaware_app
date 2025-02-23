import 'package:flutter/material.dart';

class FavouriteButton extends StatelessWidget {
  final bool isFavourite;
  final VoidCallback onPressed;

  const FavouriteButton({
    Key? key,
    required this.isFavourite,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        isFavourite ? Icons.favorite : Icons.favorite_border,
        color: isFavourite ? Colors.red : Colors.red,
      ),
      onPressed: onPressed,
    );
  }
}