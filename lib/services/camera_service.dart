import 'package:barcode_scan2/barcode_scan2.dart';

class CameraService {
  static Future<String?> scanBarcode() async {
    try {
      final result = await BarcodeScanner.scan();
      return result.rawContent; // The scanned barcode value
    } catch (e) {
      print('Error scanning barcode: $e');
      return null;
    }
  }
}

