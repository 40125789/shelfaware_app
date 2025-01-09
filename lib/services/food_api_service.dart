import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shelfaware_app/models/product_details.dart';

class FoodApiService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v0/product';

  // Fetch product details by barcode
  static Future<ProductDetails?> fetchProductDetails(String barcode) async {
    try {
      final url = '$_baseUrl/$barcode.json';
      print('Requesting URL: $url'); // Debug log for the URL

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('Response data: $jsonResponse'); // Debug log for the response data

        if (jsonResponse['product'] != null) {
          // Log the keys of the product to check if image_url exists
          final productData = jsonResponse['product'];
          print('Product Keys: ${productData.keys}'); // Log the keys

          String productName = productData['product_name'] ?? 'Unknown';
          String? imageUrl = productData['image_url'];

          // Ensure the imageUrl is valid (if it exists)
          if (imageUrl != null && imageUrl.isNotEmpty) {
            print('Image URL: $imageUrl');
          } else {
            print('No image URL found');
          }

          return ProductDetails(productName: productName, imageUrl: imageUrl);
        } else {
          print('Product not found for barcode: $barcode');
          return null;
        }
      } else {
        print('Request failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching product details: $e');
      return null;
    }
  }
}
