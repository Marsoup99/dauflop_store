import 'dart:typed_data'; // Needed for Uint8List for web image preview
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker


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
  XFile? _pickedImageFile; // To store the picked image file
  Uint8List? _pickedImageBytes; // To store image bytes for web preview
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

 Future<void> _pickImage() async {
  final ImagePicker picker = ImagePicker();

  // Aim for a height of 480px.
  // maxWidth can be set generously or null to let height constraint dominate
  // while maintaining aspect ratio.
  // imageQuality can be adjusted (0-100).
  final XFile? image = await picker.pickImage(
    source: ImageSource.gallery,
    maxHeight: 480,  // Target height of 480 pixels
    maxWidth: 1000, // Optional: constrain max width too, or set to null
                   // If null, image_picker scales based on maxHeight and original aspect ratio.
    imageQuality: 80,  // Adjust quality (0-100) for file size vs. visual quality
  );

  if (image != null) {
    final bytes = await image.readAsBytes();

    // Image is within size limits after processing
    setState(() {
      _pickedImageFile = image;
      _pickedImageBytes = bytes;
    });
  } else {
    // User canceled the picker
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected.')),
      );
    }
  }
}

  void _saveItem() {
    if (_formKey.currentState!.validate()) {
      // Form is valid, process the data
      // We'll add logic here to:
      // 1. Upload image to Firebase Storage (if selected)
      // 2. Get the image URL
      //    (if image is selected, otherwise use a placeholder or null)
      // 3. Create an Item object with data from controllers and image URL
      // 4. Save the Item object to Firestore
      print('Category: ${_categoryController.text}');
      print('Brand: ${_brandController.text}');
      print('Image selected: ${_pickedImageFile!.path}');
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
              if (_pickedImageBytes != null)
                Container(
                  height: 200,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Image.memory(
                    _pickedImageBytes!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(child: Text('Error loading image preview'));
                    },
                  ),
                )
              else
                Container(
                  height: 150,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: const Center(child: Text('No image selected')),
                ),

              // --- UPDATED: Pick Image Button ---
              ElevatedButton.icon(
                icon: const Icon(Icons.image_outlined),
                label: Text(_pickedImageFile == null ? 'Pick Image' : 'Change Image'),
                onPressed: _pickImage, // Call the _pickImage method
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveItem,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0)),
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