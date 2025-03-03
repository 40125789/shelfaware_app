import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:shelfaware_app/models/product_details.dart';
import 'package:shelfaware_app/services/open_food_facts_api.dart'; // Adjust the import path as necessary

// Ensure your FoodApiService and ProductDetails are imported

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:camera/camera.dart'; // Import camera package for live feed
 // Your existing API service
import 'package:shelfaware_app/models/product_details.dart'; // Your product model

class BarcodeScannerWidget extends StatefulWidget {
  final Function(String) onBarcodeScanned;

  const BarcodeScannerWidget({Key? key, required this.onBarcodeScanned}) : super(key: key);

  @override
  _BarcodeScannerWidgetState createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget> {
  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String? _scannedBarcode;

  late final BarcodeScanner _barcodeScanner;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _barcodeScanner = GoogleMlKit.vision.barcodeScanner();
  }

  // Initialize the camera
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first;

    _cameraController = CameraController(camera, ResolutionPreset.high);
    await _cameraController.initialize();
    setState(() {
      _isCameraInitialized = true;
    });
  }

  // Process the camera stream for barcode scanning
  Future<void> _processCameraStream() async {
    if (_isProcessing) return;

    _isProcessing = true;
    final image = await _cameraController.takePicture();
    final inputImage = InputImage.fromFilePath(image.path);

    final List<Barcode> barcodes = await _barcodeScanner.processImage(inputImage);

    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first.displayValue;
      if (barcode != null) {
        setState(() {
          _scannedBarcode = barcode;
        });
        widget.onBarcodeScanned(barcode); // Send the scanned barcode back to the parent widget
        // Stop scanning after one barcode is detected
      }
    }

    _isProcessing = false;
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: Text('Scan Barcode')),
      body: Stack(
        children: [
          // Display the live camera feed
          CameraPreview(_cameraController),
          Positioned(
            top: 20,
            left: 20,
            child: ElevatedButton(
              onPressed: () async {
                await _processCameraStream(); // Start processing the camera feed when the button is pressed
              },
              child: Text('Scan Barcode'),
            ),
          ),
          if (_scannedBarcode != null)
            Positioned(
              bottom: 20,
              left: 20,
              child: Text(
                'Scanned Barcode: $_scannedBarcode',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
