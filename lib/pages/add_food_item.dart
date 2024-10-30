import 'package:flutter/material.dart';
import 'package:shelfaware_app/services/camera_service.dart';
import 'package:shelfaware_app/components/filter_dropdown.dart'; // Import the FilterDropdown widget
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';

final user = FirebaseAuth.instance.currentUser;

//import 'camera_service.dart'; // Make sure this file exists and has the scanBarcode method.

class AddFoodItem extends StatefulWidget {
  const AddFoodItem({Key? key}) : super(key: key);

  @override
  _AddFoodItemState createState() => _AddFoodItemState();
}

class _AddFoodItemState extends State<AddFoodItem> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _storageLocationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime _expiryDate = DateTime.now();

  List<String> _categoryOptions = ['All'];
  String _category = 'All';

  @override
  void initState() {
    super.initState();
    _expiryDateController.text = formatDate(_expiryDate);
    _fetchFilterOptions();
  }

  Future<void> _fetchFilterOptions() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('categories').get();
      List<String> categories = snapshot.docs.map((doc) => doc['Food Type'].toString()).toList();
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
      // Save data to Firestore
      await FirebaseFirestore.instance.collection('foodItems').add({
        'productName': _productNameController.text,
        'expiryDate': _expiryDate,
        'quantity': int.tryParse(_quantityController.text) ?? 1,
        'userId': user!.uid,  // Add this line
        'storageLocation': _storageLocationController.text,
        'notes': _notesController.text,
        'category': _category,
        'addedOn': DateTime.now(),
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
      _quantityController.clear();  // Clear quantity field
      _storageLocationController.clear();
      _notesController.clear();
      setState(() {
        _category = 'All';
        _expiryDate = DateTime.now();
        _expiryDateController.text = formatDate(_expiryDate);
      });
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
    // Check camera permission
    var status = await Permission.camera.status;
    if (status.isDenied) {
      // Request permission
      if (await Permission.camera.request().isGranted) {
        // If the permission is granted, proceed to scan the barcode
        String? barcode = await CameraService.scanBarcode();
        if (barcode != null) {
          // Handle the scanned barcode (e.g., fetch product details)
          print('Scanned barcode: $barcode');
        }
      } else {
        // Show a message if permission is denied
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required to scan the barcode.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // If permission is already granted, proceed to scan the barcode
      String? barcode = await CameraService.scanBarcode();
      if (barcode != null) {
        // Handle the scanned barcode (e.g., fetch product details)
        print('Scanned barcode: $barcode');
      }
    }
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 15),

                  // Camera Button
             SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    onPressed: _scanBarcode,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
      padding: const EdgeInsets.symmetric(vertical: 16),
      textStyle: const TextStyle(fontSize: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0), // Rounded rectangle
      ),
    ),
    icon: const Icon(Icons.camera_alt, color: Colors.white),
    label: const Text(
      'Scan Barcode',
      style: TextStyle(color: Colors.white),
    ),
  ),
),
                  const SizedBox(height: 20),

                  // Product Name Field
                  TextFormField(
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
                  ),
                  const SizedBox(height: 20),

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

                  // Quantity Field
                  TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      hintText: 'Enter quantity',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a quantity';
                      }
                      if (int.tryParse(value) == null || int.parse(value) <= 0) {
                        return 'Please enter a valid positive number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Storage Location Field
                  TextField(
                    controller: _storageLocationController,
                    decoration: InputDecoration(
                      labelText: 'Storage Location (Optional)',
                      hintText: 'Enter storage location',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: _category,
                    items: _categoryOptions.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _category = newValue!;
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

                  // Notes Field
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes (Optional)',
                      hintText: 'Enter any additional notes',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save Food Item Button
                  // Save Food Item Button
SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: _saveFoodItem,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16), // Adjusted padding
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // Adjusted font size, weight, and color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // Set to zero for rectangular shape
      ),
    ),
    child: const Text('Save Food Item'),
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
}

