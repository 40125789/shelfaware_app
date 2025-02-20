import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class ScanExpiryDate extends StatelessWidget {
  final TextEditingController controller;
  final Function(DateTime) onDateDetected;

  const ScanExpiryDate({
    Key? key,
    required this.controller,
    required this.onDateDetected,
  }) : super(key: key);

  Future<void> _scanExpiryDate(BuildContext context) async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        final inputImage = InputImage.fromFilePath(image.path);
        final textDetector = GoogleMlKit.vision.textRecognizer();
        final RecognizedText recognizedText = await textDetector.processImage(inputImage);

        for (TextBlock block in recognizedText.blocks) {
          for (TextLine line in block.lines) {
            final text = line.text;
            final expiryDate = _parseExpiryDate(text);
            if (expiryDate != null) {
              onDateDetected(expiryDate);
              controller.text = _formatDate(expiryDate);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Expiry date detected and added!')),
              );
              return;
            }
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No expiry date detected.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission is required')),
      );
    }
  }

 DateTime? _parseExpiryDate(String text) {
    final dateFormats = [
 
    
    DateFormat('dd/MM/yyyy'),
      DateFormat('MM/dd/yyyy'),
      DateFormat('yyyy/MM/dd'),
      DateFormat('dd-MM-yyyy'),
      DateFormat('MM-dd-yyyy'),
      DateFormat('yyyy-MM-dd'),
      DateFormat('dd MMM yyyy'),
      DateFormat('MMM dd, yyyy'),
      DateFormat('dd.MM.yyyy'), // Added format for 21.01.2024
      DateFormat('yyyy.MM.dd'), // Added format for 2024.01.21
      DateFormat('yyyyMMdd'),   // Added format for 20240121
      DateFormat('ddMMyyyy'),   // Added format for 21012024
    ];

   for (var format in dateFormats) {
      try {
        return format.parseStrict(text);
      } catch (e) {
        print('Failed to parse date with format ${format.pattern}: $e');
      }
    }

    return null;
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.camera_alt),
      onPressed: () => _scanExpiryDate(context),
    );
  }
}