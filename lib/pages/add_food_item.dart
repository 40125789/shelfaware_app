import 'package:flutter/material.dart';
import 'package:shelfaware_app/components/product_detail_dialogue.dart';
import 'package:shelfaware_app/models/food_history.dart';
import 'package:shelfaware_app/models/product_details.dart';
import 'package:shelfaware_app/services/camera_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shelfaware_app/services/food_api_service.dart';
import 'package:shelfaware_app/services/food_suggestions_service.dart'; // Import the fetchProductDetails method

final user = FirebaseAuth.instance.currentUser;

class AddFoodItem extends StatefulWidget {
  final FoodHistory? foodItem;
  final String? productImage;
  AddFoodItem(
      {Key? key,
      required List<FoodHistory> foodItems,
      this.foodItem,
      this.isRecreated = false,
      this.productImage})
      : super(key: key);
  final bool isRecreated;

  @override
  _AddFoodItemState createState() => _AddFoodItemState();
}

class _AddFoodItemState extends State<AddFoodItem> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _storageLocationController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime _expiryDate = DateTime.now();

  List<String> _categoryOptions = ['All'];
  List<String> _filterOptions = [];
  String _category = 'All';
  String? _productImage;

  int _quantity = 1; // Default quantity set to 1

  // State variables for food suggestions
  List<String> _foodSuggestions = [];
  bool _isLoadingSuggestions = false;
  bool _isLoading = false; // Add this line to define _isLoading

  @override
  void initState() {
    super.initState();

    // Prepopulate the fields with data if the item is being recreated
    if (widget.isRecreated && widget.foodItem != null) {
      _productNameController.text = widget.foodItem!.productName;
      _expiryDateController.text = formatDate(_expiryDate);
      _quantity = widget.foodItem!.quantity;
      _quantityController.text = _quantity.toString();
      _storageLocationController.text = widget.foodItem!.storageLocation;
      _notesController.text = widget.foodItem!.notes;
      _productImage = widget.productImage;

      // Set the category properly, default to 'All' if null
      _category = widget.foodItem!.category;

      // Set the expiry date properly 
    } else {
      // If it's a new item, set default values
      _expiryDateController.text = formatDate(_expiryDate);
    }

    _fetchFilterOptions();
    _quantityController.text =
        _quantity.toString(); // Initialize quantity field
  }

  // Fetch food suggestions from Firebase
  Future<void> _fetchFoodSuggestions(String query) async {
    setState(() {
      _isLoadingSuggestions = true;
    });

    try {
      List<String> suggestions = await fetchFoodSuggestions(
          query); // Call the service to fetch suggestions

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

  Future<void> _fetchFilterOptions() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('categories').get();
      List<String> categories =
          snapshot.docs.map((doc) => doc['Food Type'].toString()).toList();
      setState(() {
        _categoryOptions = ['All', ...categories];
      });
    } catch (e) {
      print('Error fetching filter options: $e');
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _expiryDateController.dispose();
    _quantityController.dispose();
    _storageLocationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  Future<void> _saveFoodItem() async {
    if (!_formKey.currentState!.validate()) return;

    // Display loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      // Ensure to get the current logged-in user's UID dynamically
      User? currentUser = FirebaseAuth.instance.currentUser;

      // Check if there's a valid user
      if (currentUser == null) {
        // Show error message if no user is logged in
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No user is logged in. Please log in first.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context); // Close loading indicator
        return;
      }

      // Save data to Firestore with current user UID
      await FirebaseFirestore.instance.collection('foodItems').add({
        'productName': _productNameController.text,
        'expiryDate': _expiryDate,
        'quantity': _quantity, // Use the _quantity variable
        'userId': currentUser.uid, // Use the dynamically fetched UID
        'storageLocation': _storageLocationController.text,
        'notes': _notesController.text,
        'category': _category,
        'addedOn': DateTime.now(),
        'productImage': _productImage,
      });

      // Close the loading indicator
      Navigator.pop(context);

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Food item saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear the form
      _formKey.currentState?.reset();
      _productNameController.clear();
      _expiryDateController.clear();
      _quantityController.clear();
      _storageLocationController.clear();
      _notesController.clear();
      setState(() {
        _category = 'All';
        _expiryDate = DateTime.now();
        _expiryDateController.text = formatDate(_expiryDate);
        _quantity = 1; // Reset quantity to 1
        _quantityController.text = _quantity.toString();
      });

      // Navigate back to the home screen
      Navigator.pop(
          context); // This will return to the previous screen (home screen)
    } catch (e) {
      // Close the loading indicator
      Navigator.pop(context);

      // Show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save food item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

 Future<void> _scanBarcode() async {
  // Check for camera permission
  var status = await Permission.camera.request();
  if (status.isGranted) {
    // Display loading indicator while scanning and fetching product details
    setState(() {
      _isLoading = true;  // Track loading state
    });

    // Directly use CameraService to scan barcode
    String? scannedBarcode = await CameraService.scanBarcode();

    if (scannedBarcode != null && scannedBarcode.isNotEmpty) {
      // Fetch product details from FoodApiService
      var product = await FoodApiService.fetchProductDetails(scannedBarcode);

      if (product != null) {
        // Show the confirmation dialog first
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
  // Show the dialog and wait for the result (confirmation)
  final Map<String, dynamic>? confirmedProduct = await showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    builder: (BuildContext context) {
      return ProductDetailsDialog(product: product); // Show the dialog
    },
  );

  // If a product map was returned (i.e., the user confirmed)
  if (confirmedProduct != null) {
    // Only update the text field and show the snackbar after confirmation
    setState(() {
      // Set product name in the controller after confirmation
      _productNameController.text = confirmedProduct['productName'] ?? '';
      // Handle imageUrl as well
      _productImage = confirmedProduct['imageUrl'] ?? '';  // Set your image URL here
    });

    // Show the Snackbar only after confirmation
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Food Item'),
        backgroundColor: Colors.green,
       
        
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 15),

  // Display the product image with a magnifying glass icon to indicate tapability
if (_productImage != null)
  GestureDetector(
    onTap: () {
      // Show the full-size image in a dialog when tapped
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: Image.network(
                  _productImage!,
                  fit: BoxFit.contain, // Ensures the image fits in the dialog without stretching
                  height: MediaQuery.of(context).size.height * 0.8, // 80% of screen height
                ),
              ),
            ),
          );
        },
      );
    },
    child: Center(
      child: Stack(
        alignment: Alignment.center, // Align the icon in the center of the image
        children: [
          // Image preview (smaller version)
          Image.network(
            _productImage!,
            height: MediaQuery.of(context).size.height * 0.1, // 10% of screen height
            width: MediaQuery.of(context).size.width * 0.5,   // 50% of screen width
            fit: BoxFit.cover,
          ),
          // Magnifying glass or plus icon overlay
          Positioned(
            right: 10,
            bottom: 10,
            child: Icon(
              Icons.zoom_in, // Magnifying glass icon
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    ),
  ),

              
              const SizedBox(height: 15),

                  // Product Name Field with Scan Barcode Button inside
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _productNameController,
                          decoration: InputDecoration(
                            labelText: 'Product Name',
                            hintText: 'Enter product name',
                            filled: true,
                            fillColor: Colors.white,
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
                          onChanged: (query) {
                            _fetchFoodSuggestions(
                                query); // Fetch suggestions when text changes
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.barcode_reader),
                        onPressed: _scanBarcode,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Food Suggestions
                  if (_foodSuggestions.isNotEmpty)
                    Container(
                      height: 100,
                      color: Colors.white,
                      child: ListView.builder(
                        itemCount: _foodSuggestions.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_foodSuggestions[index]),
                            onTap: () {
                              setState(() {
                                _productNameController.text =
                                    _foodSuggestions[index];
                                _foodSuggestions = [];
                              });
                            },
                          );
                        },
                      ),
                    ),

                  // Expiry Date Field
                  GestureDetector(
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _expiryDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null && pickedDate != _expiryDate) {
                        setState(() {
                          _expiryDate = pickedDate;
                          _expiryDateController.text = formatDate(_expiryDate);
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _expiryDateController,
                        decoration: InputDecoration(
                          labelText: 'Expiry Date',
                          hintText: 'Select expiry date',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        readOnly: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                 // Category Dropdown
DropdownButtonFormField<String>(
  value: _categoryOptions.contains(_category) ? _category : 'All', // Ensure the category is valid
  items: _categoryOptions
      .map((category) => DropdownMenuItem<String>(
            value: category,
            child: Text(category),
          ))
      .toList(),
  onChanged: (String? newCategory) {
    setState(() {
      _category = newCategory ?? 'All'; // Default to 'All' if null
    });
  },
  decoration: InputDecoration(
    labelText: 'Category',
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
  ),
),
const SizedBox(height: 20),


                  // Quantity Field with Increment and Decrement Buttons
                  Row(
                    children: [
                      // Quantity Field
                      Expanded(
                        child: TextField(
                          controller: _quantityController,
                          decoration: InputDecoration(
                            labelText: 'Quantity',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          readOnly: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Increment and Decrement Buttons
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

                  // Storage Location Field
                  TextField(
                    controller: _storageLocationController,
                    decoration: InputDecoration(
                      labelText: 'Storage Location',
                      hintText: 'Enter storage location',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Notes Field
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes (Optional)',
                      hintText: 'Enter any notes',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveFoodItem,
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
                          fontSize: 18, // Font size to make it readable
                          fontWeight: FontWeight.bold, // Bold text for emphasis
                          color: Colors.white, // White text color
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _takePhoto() {}
}
