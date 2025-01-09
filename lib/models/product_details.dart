class ProductDetails {
  final String productName; // The name of the product
  final String? imageUrl; 
  
    // The URL for the product image

  ProductDetails({required this.productName, this.imageUrl});

  // Factory method to create an instance of ProductDetails from JSON
  factory ProductDetails.fromJson(Map<String, dynamic> json) {
    return ProductDetails(
      productName: json['product_name'] ?? 'Unknown', // Fallback if name is missing
      imageUrl: json['image_url'], // May be null if the API doesn't return an image
    );
  }
}
