import 'package:flutter/material.dart';
import 'package:shelfaware_app/models/product_details.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailsDialog extends StatelessWidget {
  final ProductDetails product; // Product passed to the bottom sheet

  const ProductDetailsDialog({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product.imageUrl!,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 16), // Reduced height slightly
              Text(
                product.productName,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Brand: ${product.brandName}',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                textAlign: TextAlign.center,
              ),
            // Reduced height slightly
              TextButton(
                onPressed: () async {
                   final url = product.productUrl;
                  launchUrl(Uri.parse(url)).onError((error, stackTrace) {
                    print('Error launching URL: $error');
                    return false;
                  });
                },
                child: const Text(
                  'View on Open Food Facts',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            // Reduced height slightly
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context, {
                        'productName': product.productName,
                        'imageUrl': product.imageUrl,
                        'brandName': product.brandName,
                        'productUrl': product.productUrl, // Include productUrl
                      });
                    },
                    child: const Text(
                      'Confirm',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}