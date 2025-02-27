import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:shelfaware_app/models/product_details.dart';
import 'package:shelfaware_app/services/open_food_facts_api.dart'; // Adjust the import path as necessary

// Ensure your FoodApiService and ProductDetails are imported

class BarcodeScannerWidget extends StatefulWidget {
  final Function(String) onBarcodeScanned;

  const BarcodeScannerWidget({Key? key, required this.onBarcodeScanned})
      : super(key: key);

  @override
  _BarcodeScannerWidgetState createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget> {
  final ImagePicker _picker = ImagePicker();
  String? scannedBarcode;
  ProductDetails? foodInfo; // Holds product details after fetching
  bool isLoading = false;

  Future<void> scanBarcode() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    final inputImage = InputImage.fromFilePath(image.path);
    final barcodeScanner = GoogleMlKit.vision.barcodeScanner();

    setState(() {
      isLoading = true; // Start loading while processing barcode
    });

    final List<Barcode> barcodes = await barcodeScanner.processImage(inputImage);
    await barcodeScanner.close();

    if (barcodes.isNotEmpty) {
      setState(() {
        scannedBarcode = barcodes.first.displayValue;
      });

      // Fetch food info using the barcode
      final product = await FoodApiService.fetchProductDetails(scannedBarcode!);

      setState(() {
        foodInfo = product; // Set the fetched product details
        isLoading = false; // Stop loading after the product details are fetched
      });

      if (product == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch product details.')),
        );
      } else {
        widget.onBarcodeScanned(scannedBarcode!); // Pass barcode to parent widget
      }
    } else {
      setState(() {
        isLoading = false; // Stop loading if no barcode was found
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No barcode found. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: scanBarcode,
            child: const Text('Scan Barcode'),
          ),
          if (isLoading)
            const CircularProgressIndicator(), // Show loading indicator when scanning or fetching
          if (scannedBarcode != null) Text('Scanned Barcode: $scannedBarcode'),
          if (foodInfo != null)
            Text('Last Scanned: ${foodInfo!.productName}'), // Display last scanned product name
        ],
      ),
    );
  }
}
