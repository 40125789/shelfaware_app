import 'dart:convert';
import 'package:http/http.dart' as http;

class FoodApiService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v0/product';

  // Fetch product details by barcode
  static Future<ProductDetails?> fetchProductDetails(String barcode) async {
    try {
      final url = '$_baseUrl/$barcode.json';
      print('Requesting URL: $url');  // Log the URL being requested

      final response = await http.get(Uri.parse(url));

      // Check if the request was successful
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('Response data: $jsonResponse');  // Log response data

        // Check if the product field exists in the response
        if (jsonResponse['product'] != null) {
          return ProductDetails.fromJson(jsonResponse['product']);
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

// Model for product details
class ProductDetails {
  final String productName; // Product name field

  ProductDetails({required this.productName});

  factory ProductDetails.fromJson(Map<String, dynamic> json) {
    return ProductDetails(
      productName: json['product_name'] ?? 'Unknown', // Fallback for product name
    );
  }
}
