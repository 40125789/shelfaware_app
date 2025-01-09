import 'package:flutter/material.dart';
import 'package:shelfaware_app/models/product_details.dart';
// Make sure to import the model (if needed)

class ProductDetailsDialog extends StatelessWidget {
  final ProductDetails product; // Product passed to the dialog

  const ProductDetailsDialog({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog( 
      title: const Text('Is this the correct item?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
            Image.network(
              product.imageUrl!,
              height: 150,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, size: 100),
            ),
          const SizedBox(height: 10),
          Text('Name: ${product.productName}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // Close dialog without data (cancel)
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            // Pass the product name when the dialog is confirmed
            Navigator.of(context).pop(
              product.productName); 
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
