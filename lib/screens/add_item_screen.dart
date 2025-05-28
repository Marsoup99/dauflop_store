import 'dart:typed_data'; // Needed for Uint8List for web image preview
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker

// --- NEW: Firebase Imports ---
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item_model.dart'; // Your Item model

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
  bool _isSaving = false;
  // This variable will be used to show a loading indicator while saving
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

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return; // Form is not valid, do not proceed
    }

    setState(() {
      _isSaving = true; // Show loading indicator
    });

    String? imageUrl; // Initialize imageUrl as nullable

    try {
      // 1. Upload image to Firebase Storage (ONLY if an image is picked)
      if (_pickedImageBytes != null && _pickedImageFile != null) {
        String imageName =
            'item_images/${DateTime.now().millisecondsSinceEpoch}_${_pickedImageFile!.name}';
        firebase_storage.Reference ref =
            firebase_storage.FirebaseStorage.instance.ref().child(imageName);
        
        final metadata = firebase_storage.SettableMetadata(
            contentType: _pickedImageFile!.mimeType ?? 'image/jpeg');
        
        await ref.putData(_pickedImageBytes!, metadata);
        imageUrl = await ref.getDownloadURL(); // Get the image URL
      }

      // 2. Create an Item object (imageUrl will be null if no image was picked/uploaded)
      final item = Item(
        category: _categoryController.text.trim(),
        brand: _brandController.text.trim(),
        color: _colorController.text.trim(),
        buyInPrice: double.parse(_buyInPriceController.text),
        price: double.parse(_priceController.text),
        quantity: int.parse(_quantityController.text),
        imageUrl: imageUrl, // This will be null if no image was selected
        lastModified: Timestamp.now(),
      );

      // 3. Save the Item object to Firestore
      await FirebaseFirestore.instance.collection('items').add(item.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Item saved successfully!'),
              backgroundColor: Colors.green),
        );
        // Clear the form and image after successful save
        _formKey.currentState!.reset();
        _categoryController.clear();
        _brandController.clear();
        _colorController.clear();
        _buyInPriceController.clear();
        _priceController.clear();
        _quantityController.clear();
        setState(() {
          _pickedImageFile = null;
          _pickedImageBytes = null;
        });
      }
    } catch (e) {
      print('Error saving item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to save item: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false; // Hide loading indicator
        });
      }
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
                // --- UPDATED: Show loading or save text ---
                onPressed: _isSaving ? null : _saveItem, // Disable while saving
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0)),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Item'),
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