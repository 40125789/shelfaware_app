import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:shelfaware_app/services/food_api_service.dart'; // Adjust the import path as necessary

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
  ProductDetails? foodInfo; // Updated to hold product details after fetching
  bool isLoading = false;

  Future<void> scanBarcode() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    final inputImage = InputImage.fromFilePath(image.path);
    final barcodeScanner = GoogleMlKit.vision.barcodeScanner();

    final List<Barcode> barcodes =
        await barcodeScanner.processImage(inputImage);
    await barcodeScanner.close();

    if (barcodes.isNotEmpty) {
      setState(() {
        scannedBarcode = barcodes.first.displayValue;
        isLoading = true; // Start loading
      });

      // Fetch food info using the barcode
      final product = await FoodApiService.fetchProductDetails(scannedBarcode!);
      setState(() {
        foodInfo = product; // Set the fetched product details
        isLoading = false; // Stop loading
      });

      if (product == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch product details.')),
        );
      } else {
        widget.onBarcodeScanned(scannedBarcode!);
      }
    } else {
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
          if (isLoading) CircularProgressIndicator(),
          if (scannedBarcode != null) Text('Scanned Barcode: $scannedBarcode'),
          if (foodInfo != null)
            Text('Food Name: ${foodInfo!.productName}'), // Display product name
        ],
      ),
    );
  }
}