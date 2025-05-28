import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For FilteringTextInputFormatter

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
      final _formKey = GlobalKey<FormState>(); // For form validation

  // Controllers for text fields
  final _categoryController = TextEditingController();
  final _brandController = TextEditingController();
  final _colorController = TextEditingController();
  final _buyInPriceController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();

  // We'll add a variable here later to hold the selected image file
  // File? _selectedImage;

  @override
  void dispose() {
    // Dispose controllers when the widget is removed from the widget tree
    _categoryController.dispose();
    _brandController.dispose();
    _colorController.dispose();
    _buyInPriceController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _saveItem() {
    if (_formKey.currentState!.validate()) {
      // Form is valid, process the data
      // We'll add logic here to:
      // 1. Upload image to Firebase Storage (if selected)
      // 2. Get the image URL
      // 3. Create an Item object with data from controllers and image URL
      // 4. Save the Item object to Firestore
      print('Category: ${_categoryController.text}');
      print('Brand: ${_brandController.text}');
      // ... and so on for other fields
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item details would be saved here!')),
      );
    }
  }

  // We'll add an _pickImage function here later
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Item'),
      ),
      body: SingleChildScrollView( // Allows scrolling if content is too long
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Make children stretch
            children: <Widget>[
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(labelText: 'Brand'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a brand';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(labelText: 'Color'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a color';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _buyInPriceController,
                decoration: const InputDecoration(labelText: 'Buy-in Price'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the buy-in price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Selling Price'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the selling price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the quantity';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid integer';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Placeholder for Image Picker button
              ElevatedButton.icon(
                icon: const Icon(Icons.image_outlined),
                label: const Text('Pick Image (Coming Soon)'),
                onPressed: () {
                  // _pickImage(); // We'll implement this later
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Image picker will be here!')),
                  );
                },
              ),
              // We'll display the selected image preview here later
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveItem,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0)
                ),
                child: const Text('Save Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// This AddItemScreen widget allows users to add new items to the inventory.
// It includes a form with fields for category, brand, color, buy-in price, selling price, and quantity.  