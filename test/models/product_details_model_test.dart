import 'package:flutter_test/flutter_test.dart';
import 'package:shelfaware_app/models/product_details.dart';

void main() {
  group('ProductDetails', () {
    test('should create an instance from JSON', () {
      final json = {
        'product_name': 'Test Product',
        'image_url': 'http://example.com/image.png',
        'brands': 'Test Brand',
        'url': 'http://example.com/product'
      };

      final productDetails = ProductDetails.fromJson(json);

      expect(productDetails.productName, 'Test Product');
      expect(productDetails.imageUrl, 'http://example.com/image.png');
      expect(productDetails.brandName, 'Test Brand');
      expect(productDetails.productUrl, 'http://example.com/product');
    });

    test('should handle missing optional fields in JSON', () {
      final json = {
        'product_name': 'Test Product',
        'url': 'http://example.com/product'
      };

      final productDetails = ProductDetails.fromJson(json);

      expect(productDetails.productName, 'Test Product');
      expect(productDetails.imageUrl, isNull);
      expect(productDetails.brandName, isNull);
      expect(productDetails.productUrl, 'http://example.com/product');
    });

    test('should fallback to "Unknown" if product_name is missing', () {
      final json = {
        'url': 'http://example.com/product'
      };

      final productDetails = ProductDetails.fromJson(json);

      expect(productDetails.productName, 'Unknown');
      expect(productDetails.imageUrl, isNull);
      expect(productDetails.brandName, isNull);
      expect(productDetails.productUrl, 'http://example.com/product');
    });
  });
}