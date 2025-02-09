class ProductDetails {
  final String productName; // The name of the product
  final String? imageUrl; // The URL for the product image
  final String? brandName; // The brand name of the product
  final String productUrl;

  ProductDetails({
    required this.productName,
    this.imageUrl,
    this.brandName,
    required this.productUrl,
  });

  // Factory method to create an instance of ProductDetails from JSON
  factory ProductDetails.fromJson(Map<String, dynamic> json) {
    return ProductDetails(
      productName: json['product_name'] ?? 'Unknown', // Fallback if name is missing
      imageUrl: json['image_url'], // May be null if the API doesn't return an image
      brandName: json['brands'], // Extract the brand name from the JSON
      productUrl: json['url'], // Extract the product URL from the JSON
    );
  }
}
