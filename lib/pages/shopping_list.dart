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
  final FoodSuggestionsService _foodSuggestionsService = FoodSuggestionsService();
  bool _hidePurchased = false;
  bool _allChecked = false;

  List<Map<String, dynamic>> _shoppingList = [];
  List<String> _foodSuggestions = [];
  String userId = FirebaseAuth.instance.currentUser!.uid;
  TextEditingController _productController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingSuggestions = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadShoppingList();
  }

  _loadShoppingList() async {
    final items = await _shoppingListService.getShoppingList();
    setState(() {
      _shoppingList = items;
      _allChecked = items.isNotEmpty && items.every((item) => item['isPurchased']);

      if (_hidePurchased) {
        _shoppingList = _shoppingList.where((item) => !item['isPurchased']).toList();
      }
    });
  }

  void _toggleAllPurchased(bool value) async {
    await _shoppingListService.toggleAllPurchased(value);
    setState(() {
      _allChecked = value;
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

  _addProduct(String productName) async {
    if (productName.isNotEmpty) {
      await _shoppingListService.addToShoppingList(productName);
      _loadShoppingList();
    }
  }

  _removeProduct(String itemId) async {
    await _shoppingListService.removeFromShoppingList(itemId);
    _loadShoppingList();
  }

  _markAsPurchased(String itemId) async {
    final item = _shoppingList.firstWhere((item) => item['id'] == itemId);
    final newStatus = !item['isPurchased'];

    await _shoppingListService.markAsPurchased(itemId, newStatus);
    _loadShoppingList();
  }

  Future<void> _updateQuantity(String productId, int newQuantity) async {
    final item = _shoppingList.firstWhere((item) => item['id'] == productId);
    final currentQty = item['quantity'] ?? 1;
    final change = (newQuantity - currentQty).toInt();
    
    await _shoppingListService.updateQuantity(productId, change);
    _loadShoppingList();
  }

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
      List<String> suggestions = await _foodSuggestionsService.fetchFoodSuggestions(query);
      // Limit the number of suggestions to prevent overflow
      suggestions = suggestions.take(5).toList();
      
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

  void _onProductNameChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.isEmpty) {
        setState(() {
          _foodSuggestions = [];
        });
      } else {
        _fetchFoodSuggestions(query);
      }
    });
  }

  Future<void> _scanBarcode() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() {
        _isLoading = true;
      });

      String? scannedBarcode = await CameraService.scanBarcode();

      if (scannedBarcode != null && scannedBarcode.isNotEmpty) {
        var product = await FoodApiService.fetchProductDetails(scannedBarcode);

        if (product != null) {
          _showProductDialog(product);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product details not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      setState(() {
        _isLoading = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera permission is required'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showProductDialog(ProductDetails product) async {
    final Map<String, dynamic>? confirmedProduct =
        await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return ProductDetailsDialog(product: product);
      },
    );

    if (confirmedProduct != null) {
      setState(() {
        _productController.text = confirmedProduct['productName'] ?? '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product confirmed!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color cardColor = theme.cardColor;
    final Color containerBgColor = isDarkMode ? theme.cardColor : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _scanBarcode,
            child: Text(
              'Scan Barcode',
              style: TextStyle(color: theme.appBarTheme.titleTextStyle?.color ?? Colors.white),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: containerBgColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(isDarkMode ? 0.1 : 0.2),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _productController,
                            decoration: InputDecoration(
                              labelText: 'Enter product name',
                              prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              filled: true,
                              fillColor: isDarkMode ? theme.inputDecorationTheme.fillColor ?? Colors.grey[800] : Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(vertical: 0),
                            ),
                            onChanged: _onProductNameChanged,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Colors.green, Colors.teal],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 22,
                            ),
                            onPressed: () {
                              _addProduct(_productController.text);
                              _productController.clear();
                            },
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Theme(
                                data: Theme.of(context).copyWith(
                                  checkboxTheme: CheckboxThemeData(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                child: Checkbox(
                                  value: _allChecked,
                                  activeColor: Colors.green,
                                  onChanged: (bool? value) {
                                    _toggleAllPurchased(value ?? false);
                                  },
                                ),
                              ),
                              Text("Tick all", style: TextStyle(color: textColor)),
                            ],
                          ),
                          Row(
                            children: [
                              Switch(
                                value: _hidePurchased,
                                activeColor: Colors.green,
                                onChanged: (bool value) {
                                  setState(() {
                                    _hidePurchased = value;
                                  });
                                  _loadShoppingList();
                                },
                              ),
                              Text("Hide Purchased", style: TextStyle(color: textColor)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (_foodSuggestions.isNotEmpty)
  Flexible(
    child: Container(
      decoration: BoxDecoration(
        color: containerBgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(isDarkMode ? 0.1 : 0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.3,  // Adjust for keyboard
      ),
      width: double.infinity,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _foodSuggestions.length,
        itemBuilder: (context, index) {
          return ListTile(
            dense: true,
            leading: const Icon(Icons.food_bank_outlined, color: Colors.green),
            title: Text(
              _foodSuggestions[index],
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(color: textColor),
            ),
            onTap: () {
              _productController.text = _foodSuggestions[index];
              setState(() {
                _foodSuggestions = [];
              });
            },
          );
        },
      ),
    ),
  ),

              Expanded(
                child: _shoppingList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 80,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Your shopping list is empty!',
                              style: TextStyle(fontSize: 18, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add items above to get started',
                              style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.grey[500] : Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _shoppingList.length,
                        itemBuilder: (context, index) {
                          final item = _shoppingList[index];
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            color: cardColor,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              leading: Checkbox(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                activeColor: Colors.green,
                                value: item['isPurchased'],
                                onChanged: (_) {
                                  _markAsPurchased(item['id']);
                                },
                              ),
                              title: Text(
                                item['productName'],
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  decoration: item['isPurchased']
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  color: item['isPurchased'] ? Colors.grey : textColor,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: item['isPurchased'] 
                                        ? (isDarkMode ? Colors.green[900] : Colors.green[50])
                                        : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      item['isPurchased'] ? 'Purchased' : 'To buy',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: item['isPurchased'] 
                                          ? (isDarkMode ? Colors.green[300] : Colors.green) 
                                          : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                    decoration: BoxDecoration(
                                      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: DropdownButton<int>(
                                      value: item['quantity'] ?? 1,
                                      underline: Container(),
                                      icon: const Icon(Icons.arrow_drop_down, color: Colors.green),
                                      dropdownColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                      items: List.generate(10, (index) => index + 1)
                                        .map((int value) {
                                          return DropdownMenuItem<int>(
                                            value: value,
                                            child: Text('$value', style: TextStyle(color: textColor)),
                                          );
                                      }).toList(),
                                      onChanged: (int? newValue) {
                                        if (newValue != null) {
                                          _updateQuantity(item['id'], newValue);
                                        }
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _removeProduct(item['id']),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
