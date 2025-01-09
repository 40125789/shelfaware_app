import 'package:flutter/material.dart';
import 'package:shelfaware_app/models/product_details.dart';
// Make sure to import the model (if needed)

class ProductDetailsDialog extends StatelessWidget {
  final ProductDetails product; // Product passed to the bottom sheet

  const ProductDetailsDialog({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
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
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(), // Close bottom sheet without data (cancel)
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // Pass the product name when the bottom sheet is confirmed
                 Navigator.pop(context, {
                  'productName': product.productName,
                  'imageUrl': product.imageUrl
                });
              },
                
                child: const Text('Confirm'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
