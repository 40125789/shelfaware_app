import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


class EditFoodItem extends StatefulWidget {
  final String foodItemId; // ID of the food item to edit
  final Map<String, dynamic> foodItemData; // Existing food item data

  const EditFoodItem({Key? key, required this.foodItemId, required this.foodItemData, required String itemId, required Map<String, dynamic> foodData})
      : super(key: key);

  @override
  _EditFoodItemState createState() => _EditFoodItemState();
}

class _EditFoodItemState extends State<EditFoodItem> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _productNameController;
  late TextEditingController _expiryDateController;
  late TextEditingController _quantityController;
  late TextEditingController _storageLocationController;
  late TextEditingController _notesController;

  DateTime _expiryDate = DateTime.now();
  List<String> _categoryOptions = ['All'];
  String _category = 'All';

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing data
    _productNameController = TextEditingController(text: widget.foodItemData['productName']);
    _expiryDateController = TextEditingController(text: formatDate(widget.foodItemData['expiryDate'].toDate()));
    _quantityController = TextEditingController(text: widget.foodItemData['quantity'].toString());
    _storageLocationController = TextEditingController(text: widget.foodItemData['storageLocation'] ?? '');
    _notesController = TextEditingController(text: widget.foodItemData['notes'] ?? '');
    _expiryDate = widget.foodItemData['expiryDate'].toDate();
    _category = widget.foodItemData['category'] ?? 'All';

    _fetchFilterOptions();
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

  Future<void> _updateFoodItem() async {
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
      // Update data in Firestore
      await FirebaseFirestore.instance.collection('foodItems').doc(widget.foodItemId).update({
        'productName': _productNameController.text,
        'expiryDate': _expiryDate,
        'quantity': int.tryParse(_quantityController.text) ?? 1,
        'storageLocation': _storageLocationController.text,
        'notes': _notesController.text,
        'category': _category,
        'updatedOn': DateTime.now(),
      });

      // Close the loading indicator
      Navigator.pop(context);

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Food item updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context); // Go back to the previous screen
    } catch (e) {
      // Close the loading indicator
      Navigator.pop(context);

      // Show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update food item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Food Item'),
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
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _productNameController,
                    decoration: InputDecoration(
                      labelText: 'Product Name',
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
                  TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: 'Quantity',
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _updateFoodItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: const Text('Update Food Item'),
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
