import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shelfaware_app/components/expiry_date_scanner.dart';
import 'package:shelfaware_app/models/food_history.dart';
import 'package:shelfaware_app/services/food_item_service.dart';
import 'package:shelfaware_app/models/product_details.dart';
import 'package:shelfaware_app/components/product_detail_dialogue.dart';
import 'package:shelfaware_app/services/camera_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shelfaware_app/services/food_suggestions_service.dart';
import 'dart:async';
import 'package:shelfaware_app/services/open_food_facts_api.dart';


class FoodItemForm extends StatefulWidget {
  final List<dynamic> foodItems; // Accept a list of food items
  final bool isRecreated;
  final dynamic foodItem;
  final String? productImage;
  final Function onSave;

  FoodItemForm({
    required this.isRecreated,
    required this.foodItems,
    this.foodItem,
    this.productImage,
    required this.onSave,
  });

  @override
  _FoodItemFormState createState() => _FoodItemFormState();
}

class _FoodItemFormState extends State<FoodItemForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _storageLocationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final FoodSuggestionsService _foodSuggestionsService = FoodSuggestionsService();
  DateTime? _expiryDate;
  Timer? _debounce;

  List<String> _categoryOptions = ['All'];
  List<String> _foodSuggestions = [];
  String _category = 'All';
  String? _productImage;
  int _quantity = 1;
  bool _isLoadingSuggestions = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.isRecreated || widget.foodItem != null) {
      if (widget.foodItem is Map) {
        _productNameController.text = widget.foodItem['productName'] ?? '';
        _expiryDate = widget.foodItem['expiryDate'].toDate();
        _expiryDateController.text = formatDate(_expiryDate!);
        _quantity = widget.foodItem['quantity'] ?? 1;
        _quantityController.text = _quantity.toString();
        _storageLocationController.text = widget.foodItem['storageLocation'] ?? '';
        _notesController.text = widget.foodItem['notes'] ?? '';
        _productImage = widget.productImage;
        _category = widget.foodItem['category'] ?? 'All';
      } else if (widget.foodItem is FoodHistory) {
        _productNameController.text = widget.foodItem.productName;
        _expiryDate = widget.foodItem.expiryDate.toDate();
        _expiryDateController.text = formatDate(_expiryDate!);
        _quantity = widget.foodItem.quantity;
        _quantityController.text = _quantity.toString();
        _storageLocationController.text = widget.foodItem.storageLocation;
        _notesController.text = widget.foodItem.notes;
        _productImage = widget.productImage;
        _category = widget.foodItem.category;
      }
    }

    _fetchFilterOptions();
    _quantityController.text = _quantity.toString();
  }

  Future<void> _fetchFilterOptions() async {
    try {
      List<String> categories = await FoodItemService().fetchFoodCategories();
      setState(() {
        _categoryOptions = categories.toSet().toList(); // Remove duplicates
        if (!_categoryOptions.contains(_category)) {
          _category = _categoryOptions.first;
        }
      });
    } catch (e) {
      print('Error fetching filter options: $e');
    }
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
      print('Fetching food suggestions for query: $query'); // Log the query
      List<String> suggestions = await _foodSuggestionsService.fetchFoodSuggestions(query);
      print('Food suggestions: $suggestions'); // Log the suggestions
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
          _foodSuggestions = []; // Clear suggestions if the field is cleared
        });
      } else {
        _fetchFoodSuggestions(query);
      }
    });
  }

  String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
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
            const SnackBar(content: Text('Product details not found')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission is required')),
      );
    }
  }

  void _showProductDialog(ProductDetails product) async {
    final Map<String, dynamic>? confirmedProduct = await showModalBottomSheet<Map<String, dynamic>>(
    context: context,
  isScrollControlled: true, // This allows the bottom sheet to resize based on content
  builder: (BuildContext context) {
    return ProductDetailsDialog(product: product); // Pass your product here
  },
);

    if (confirmedProduct != null) {
      setState(() {
        _productNameController.text = confirmedProduct['productName'] ?? '';
        _productImage = confirmedProduct['imageUrl'] ?? '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product confirmed!')),
      );
    }
  }

  void _incrementQuantity() {
    setState(() {
      _quantity++;
      _quantityController.text = _quantity.toString();
    });
  }

  void _decrementQuantity() {
    setState(() {
      if (_quantity > 1) {
        _quantity--;
        _quantityController.text = _quantity.toString();
      }
    });
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _expiryDateController.dispose();
    _quantityController.dispose();
    _storageLocationController.dispose();
    _notesController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 15),
          if (_productImage != null)
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return Dialog(
                      child: Container(
                        color: Colors.transparent,
                        child: Center(
                          child: Image.network(
                            _productImage!,
                            fit: BoxFit.contain,
                            height: MediaQuery.of(context).size.height * 0.8,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.network(
                      _productImage!,
                      height: MediaQuery.of(context).size.height * 0.1,
                      width: MediaQuery.of(context).size.width * 0.5,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Icon(
                        Icons.zoom_in,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _productNameController,
                  decoration: InputDecoration(
                    labelText: 'Product Name',
                    hintText: 'Enter product name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a product name';
                    }
                    return null;
                  },
                  onChanged: _onProductNameChanged,
                ),
              ),
              IconButton(
                icon: Icon(Icons.camera_alt),
                onPressed: _scanBarcode,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_foodSuggestions.isNotEmpty)
            Container(
              height: 100,
              child: ListView.builder(
                itemCount: _foodSuggestions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_foodSuggestions[index]),
                    onTap: () {
                      setState(() {
                        _productNameController.text = _foodSuggestions[index];
                        _foodSuggestions = [];
                      });
                    },
                  );
                },
              ),
            ),
       
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    // Ensure initial date is not before firstDate (DateTime.now())
                    DateTime initialDate = (_expiryDate != null && _expiryDate!.isBefore(DateTime.now()))
                        ? DateTime.now()
                        : _expiryDate ?? DateTime.now();

                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: initialDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null && pickedDate != _expiryDate) {
                      setState(() {
                        _expiryDate = pickedDate;
                        _expiryDateController.text = formatDate(_expiryDate!);
                      });
                    }
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _expiryDateController,
                      decoration: InputDecoration(
                        labelText: 'Expiry Date',
                        hintText: 'Select expiry date',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      validator: (value) {
                        if (_expiryDate == null) {
                          return 'Please select an expiry date';
                        }
                        return null;
                      },
                      readOnly: true,
                    ),
                  ),
                ),
              ),
              ScanExpiryDate(
                controller: _expiryDateController,
                onDateDetected: (DateTime date) {
                  setState(() {
                    _expiryDate = date;
                    _expiryDateController.text = formatDate(_expiryDate!);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _categoryOptions.contains(_category) ? _category : 'All',
            items: _categoryOptions
                .map((category) => DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    ))
                .toList(),
            onChanged: (String? newCategory) {
              setState(() {
                _category = newCategory ?? 'All';
              });
            },
            decoration: InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: _decrementQuantity,
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _incrementQuantity,
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _storageLocationController,
            decoration: InputDecoration(
              labelText: 'Storage Location',
              hintText: 'Enter storage location',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Notes (Optional)',
              hintText: 'Enter any notes',  
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  widget.onSave(
                    _productNameController.text,
                    _expiryDate!,
                    _quantity,
                    _storageLocationController.text,
                    _notesController.text,
                    _category,
                    _productImage,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: const Text(
                'Save Food Item',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
