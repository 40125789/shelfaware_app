import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shelfaware_app/components/product_detail_dialogue.dart';
import 'package:shelfaware_app/models/product_details.dart';
import 'package:shelfaware_app/services/camera_service.dart';
import 'package:shelfaware_app/services/food_suggestions_service.dart';
import 'package:shelfaware_app/services/open_food_facts_api.dart';
import 'package:shelfaware_app/services/shopping_list_service.dart'; // Barcode scanning package
import 'package:permission_handler/permission_handler.dart'; // To request camera permission

class ShoppingListScreen extends StatefulWidget {
  @override
  _ShoppingListScreenState createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final ShoppingListService _shoppingListService = ShoppingListService();
  final FoodSuggestionsService _foodSuggestionsService =
      FoodSuggestionsService();
  bool _hidePurchased = false; // Toggles hiding purchased items
  bool _allChecked = false; // Tracks if all items are checked

  List<Map<String, dynamic>> _shoppingList = [];
  List<String> _foodSuggestions = []; // Holds the suggestions
  String userId = FirebaseAuth.instance.currentUser!.uid;
  TextEditingController _productController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingSuggestions = false; // Track loading state for suggestions
  Timer? _debounce; // Add this line to define the _debounce variable

  @override
  void initState() {
    super.initState();
    _loadShoppingList();
  }

  // Load shopping list from Firestore
  _loadShoppingList() async {
    final items = await _shoppingListService.getShoppingList();
    setState(() {
      _shoppingList = items;
      _allChecked =
          items.isNotEmpty && items.every((item) => item['isPurchased']);

      if (_hidePurchased) {
        _shoppingList =
            _shoppingList.where((item) => !item['isPurchased']).toList();
      }
    });
  }

  void _toggleAllPurchased(bool value) async {
    await _shoppingListService.toggleAllPurchased(value);
    setState(() {
      _allChecked = value; // Update the toggle state
      for (var item in _shoppingList) {
        item['isPurchased'] = value;
      }
    });
  }

  void _toggleHidePurchased(bool value) {
    setState(() {
      _hidePurchased = value;
    });
    _loadShoppingList();
  }

  // Add a product to the shopping list
  _addProduct(String productName) async {
    if (productName.isNotEmpty) {
      await _shoppingListService
          .addToShoppingList(productName); // Adding with product name
      _loadShoppingList(); // Refresh the list
    }
  }

  // Remove a product from the shopping list
  _removeProduct(String itemId) async {
    await _shoppingListService.removeFromShoppingList(itemId);
    _loadShoppingList(); // Refresh the list
  }

  // Mark item as purchased (update Firestore)
  // Mark individual item as purchased or not
  _markAsPurchased(String itemId) async {
    final item = _shoppingList.firstWhere((item) => item['id'] == itemId);
    final newStatus = !item['isPurchased']; // Toggle the current status

    await _shoppingListService.markAsPurchased(
        itemId, newStatus); // Update in Firestore
    _loadShoppingList(); // Refresh the list to update the UI
  }

  // Fetch food suggestions based on the input query
  Future<void> _fetchFoodSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _foodSuggestions = [];
      });
      return;
    }

    setState(() {
      _isLoadingSuggestions = true;
    });

    try {
      print('Fetching food suggestions for query: $query');
      List<String> suggestions =
          await _foodSuggestionsService.fetchFoodSuggestions(query);
      setState(() {
        _foodSuggestions = suggestions;
        _isLoadingSuggestions = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSuggestions = false;
      });
      print('Error fetching food suggestions: $e');
    }
  }

  // Handle changes in the product name field
  void _onProductNameChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.isEmpty) {
        setState(() {
          _foodSuggestions = []; // Clear suggestions if the field is cleared
        });
      } else {
        _fetchFoodSuggestions(query);
      }
    });
  }

  // Scan barcode and add product to the shopping list
  Future<void> _scanBarcode() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() {
        _isLoading = true; // Set loading to true while scanning
      });

      // Scan barcode using the camera service
      String? scannedBarcode = await CameraService.scanBarcode();

      if (scannedBarcode != null && scannedBarcode.isNotEmpty) {
        // Fetch product details from OpenFoodFacts API
        var product = await FoodApiService.fetchProductDetails(scannedBarcode);

        if (product != null) {
          // Show the product details in a modal bottom sheet
          _showProductDialog(product);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product details not found')),
          );
        }
      }
      setState(() {
        _isLoading = false; // Reset loading state after scanning
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission is required')),
      );
    }
  }

  // Show product details in a bottom sheet dialog
  void _showProductDialog(ProductDetails product) async {
    final Map<String, dynamic>? confirmedProduct =
        await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled:
          true, // This allows the bottom sheet to resize based on content
      builder: (BuildContext context) {
        return ProductDetailsDialog(product: product); // Pass your product here
      },
    );

    if (confirmedProduct != null) {
      setState(() {
        _productController.text = confirmedProduct['productName'] ?? '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product confirmed!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shopping List'),
        actions: [
          IconButton(
            icon: Icon(Icons.camera_alt), // Camera icon for barcode scanner
            onPressed: _scanBarcode, // Trigger barcode scan
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: TextField(
                          controller: _productController,
                          decoration: InputDecoration(
                            labelText: 'Enter product name',
                            border: OutlineInputBorder(),
                          ),
                          onChanged:
                              _onProductNameChanged, // Listen for changes
                        ),
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          _addProduct(
                              _productController.text); // Add entered product
                          _productController.clear(); // Clear input
                        },
                      ),
                    ),
                  ],
                ),

                // Add a toggle to hide purchased items
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _allChecked,
                            onChanged: (bool? value) {
                              _toggleAllPurchased(value ?? false);
                            },
                          ),
                          Text("Tick all"),
                        ],
                      ),
                      Row(
                        children: [
                          Switch(
                            value: _hidePurchased,
                            onChanged: (bool value) {
                              setState(() {
                                _hidePurchased = value;
                              });
                              _loadShoppingList();
                            },
                          ),
                          Text("Hide Purchased"),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_foodSuggestions.isNotEmpty) ...[
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: _foodSuggestions.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_foodSuggestions[index]),
                        onTap: () {
                          _productController.text = _foodSuggestions[
                              index]; // Set selected suggestion
                          setState(() {
                            _foodSuggestions =
                                []; // Clear suggestions after selection
                          });
                        },
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _shoppingList.length,
              itemBuilder: (context, index) {
                final item = _shoppingList[index];
                return ListTile(
                  leading: IconButton(
                    icon: Icon(
                      item['isPurchased']
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: item['isPurchased'] ? Colors.green : Colors.black,
                    ),
                    onPressed: () {
                      _markAsPurchased(
                          item['id']); // Mark item as purchased/unpurchased
                    },
                  ),
                  title: Text(
                    item['productName'],
                    style: TextStyle(
                      decoration: item['isPurchased']
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  subtitle:
                      Text(item['isPurchased'] ? 'Purchased' : 'Not Purchased'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () =>
                        _removeProduct(item['id']), // Remove item from list
                  ),
                );
              },
            ),
          ),
          if (_isLoading) Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
