import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item_model.dart';
import '../theme/app_theme.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _colorController = TextEditingController();
  final _buyInPriceController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _newCategoryController = TextEditingController();

  // --- State for Category Dropdown ---
  List<String> _categoryOptions = [];
  String? _selectedCategory;
  bool _isLoadingCategories = true;
  final String _addNewCategoryValue = 'ADD_NEW_CATEGORY_VALUE';

  XFile? _pickedImageFile;
  Uint8List? _pickedImageBytes;
  final int _maxImageSizeBytes = 1 * 1024 * 1024; // 1MB
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _brandController.dispose();
    _colorController.dispose();
    _buyInPriceController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('items').get();
      // Use a Set to get unique category names, then convert to a sorted List
      final categories = snapshot.docs
          .map((doc) => (doc.data()['category'] as String?)?.trim() ?? '')
          .where((category) => category.isNotEmpty)
          .toSet()
          .toList()..sort((a,b) => a.toLowerCase().compareTo(b.toLowerCase()));
      
      if (mounted) {
        setState(() {
          _categoryOptions = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCategories = false);
      print("Error fetching categories: $e");
    }
  }

  Future<void> _showAddNewCategoryDialog() async {
    _newCategoryController.clear();
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Category'),
          content: TextField(
            controller: _newCategoryController,
            autofocus: true,
            decoration: const InputDecoration(hintText: "Enter category name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Add'),
              onPressed: () {
                final newCategory = _newCategoryController.text.trim();
                if (newCategory.isNotEmpty && !_categoryOptions.any((c) => c.toLowerCase() == newCategory.toLowerCase())) {
                  setState(() {
                    _categoryOptions.add(newCategory);
                    _categoryOptions.sort((a,b) => a.toLowerCase().compareTo(b.toLowerCase()));
                    _selectedCategory = newCategory;
                  });
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(newCategory.isEmpty ? 'Category cannot be empty.' : 'Category already exists.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxHeight: 480,
      imageQuality: 80,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      final int imageSizeInBytes = bytes.length;
      final double imageSizeInMB = imageSizeInBytes / (1024 * 1024);

      if (imageSizeInBytes > _maxImageSizeBytes) {
        setState(() {
          _pickedImageFile = null;
          _pickedImageBytes = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Processed image is too large (${imageSizeInMB.toStringAsFixed(2)} MB). Max 1 MB.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }
      setState(() {
        _pickedImageFile = image;
        _pickedImageBytes = bytes;
      });
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      if (_selectedCategory == null && mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category.'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    String? imageUrl;
    try {
      if (_pickedImageBytes != null && _pickedImageFile != null) {
        String imageName = 'item_images/${DateTime.now().millisecondsSinceEpoch}_${_pickedImageFile!.name}';
        firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance.ref().child(imageName);
        final metadata = firebase_storage.SettableMetadata(contentType: _pickedImageFile!.mimeType ?? 'image/jpeg');
        await ref.putData(_pickedImageBytes!, metadata);
        imageUrl = await ref.getDownloadURL();
      }

      final item = Item(
        category: _selectedCategory!, // We know it's not null here because of the validation check
        brand: _brandController.text.trim(),
        color: _colorController.text.trim(),
        buyInPrice: double.parse(_buyInPriceController.text),
        price: double.parse(_priceController.text),
        quantity: int.parse(_quantityController.text),
        imageUrl: imageUrl,
        lastModified: Timestamp.now(),
      );

      await FirebaseFirestore.instance.collection('items').add(item.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item saved successfully!'), backgroundColor: Colors.green),
        );
        _formKey.currentState!.reset();
        _brandController.clear();
        _colorController.clear();
        _buyInPriceController.clear();
        _priceController.clear();
        _quantityController.clear();
        setState(() {
          _pickedImageFile = null;
          _pickedImageBytes = null;
          _selectedCategory = null;
        });
        _fetchCategories(); // Refresh categories in case a new one was added implicitly
      }
    } catch (e) {
      print('Error saving item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save item: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_isLoadingCategories)
                const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
              else
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Category'),
                  value: _selectedCategory,
                  hint: const Text('Select a category'),
                  isExpanded: true,
                  items: [
                    ..._categoryOptions.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    DropdownMenuItem<String>(
                      value: _addNewCategoryValue,
                      child: Row(
                        children: [
                          const Icon(Icons.add, color: AppTheme.primaryPink),
                          const SizedBox(width: 8),
                          const Text('Add New Category...', style: TextStyle(color: AppTheme.primaryPink, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue == _addNewCategoryValue) {
                      _showAddNewCategoryDialog();
                    } else {
                      setState(() => _selectedCategory = newValue);
                    }
                  },
                  validator: (value) => value == null ? 'Please select a category' : null,
                ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(labelText: 'Brand'),
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter a brand' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(labelText: 'Color'),
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter a color' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _buyInPriceController,
                decoration: const InputDecoration(labelText: 'Buy-in Price'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter the buy-in price';
                  if (double.tryParse(value) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Selling Price'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter the selling price';
                  if (double.tryParse(value) == null) return 'Please enter a valid number';
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
                  if (value == null || value.isEmpty) return 'Please enter the quantity';
                  if (int.tryParse(value) == null) return 'Please enter a valid integer';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              if (_pickedImageBytes != null)
                Container(
                  height: 200,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(12.0)),
                  child: ClipRRect(borderRadius: BorderRadius.circular(11.0), child: Image.memory(_pickedImageBytes!, fit: BoxFit.contain)),
                )
              else
                Container(
                  height: 150,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12.0)),
                  child: const Center(child: Text('No image selected', style: TextStyle(color: AppTheme.lightText))),
                ),
              ElevatedButton.icon(
                icon: const Icon(Icons.image_outlined),
                label: Text(_pickedImageFile == null ? 'Pick Image' : 'Change Image'),
                onPressed: _pickImage,
                 style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.darkText,
                  side: BorderSide(color: Colors.grey[300]!)
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isSaving ? null : _saveItem,
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
