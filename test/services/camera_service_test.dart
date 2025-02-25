import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:shelfaware_app/services/camera_service.dart';


class MockBarcodeScanner extends Mock implements BarcodeScanner {
  Future<ScanResult> scan() async {
    return ScanResult(rawContent: '');
  }
}

void main() {
  group('CameraService', () {
    test('scanBarcode returns scanned barcode value', () async {
      final mockBarcodeScanner = MockBarcodeScanner();
      when(mockBarcodeScanner.scan()).thenAnswer((_) async => ScanResult(rawContent: '1234567890'));

      final result = await CameraService.scanBarcode();
      expect(result, '1234567890');
    });

    test('scanBarcode returns null on error', () async {
      final mockBarcodeScanner = MockBarcodeScanner();
      when(mockBarcodeScanner.scan()).thenThrow(Exception('Scanning error'));

      final result = await CameraService.scanBarcode();
      expect(result, isNull);
    });
  });
}
