import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/item_model.dart';
import '../theme/app_theme.dart';

class AddItemScreen extends StatefulWidget {
  // --- NEW: Add optional item for editing ---
  final Item? itemToEdit;

  const AddItemScreen({super.key, this.itemToEdit});

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

  List<String> _categoryOptions = [];
  String? _selectedCategory;
  bool _isLoadingCategories = true;
  final String _addNewCategoryValue = 'ADD_NEW_CATEGORY_VALUE';

  // --- NEW: State for Stocking Date ---
  DateTime? _selectedStockingDate;
  String? _existingImageUrl;

  XFile? _pickedImageFile;
  Uint8List? _pickedImageBytes;
  final int _maxImageSizeBytes = 1 * 1024 * 1024; // 1MB
  bool _isSaving = false;

  bool get _isEditMode => widget.itemToEdit != null;

  @override
  void initState() {
    super.initState();
    _fetchCategories().then((_) {
      // Once categories are fetched, populate fields if in edit mode
      if (_isEditMode) {
        _populateFieldsForEdit();
      }
    });

    if (!_isEditMode) {
      _selectedStockingDate = DateTime.now();
    }
  }

  // --- NEW: Method to pre-fill form fields ---
  void _populateFieldsForEdit() {
    final item = widget.itemToEdit!;
    _brandController.text = item.brand;
    _colorController.text = item.color;
    _buyInPriceController.text = item.buyInPrice.toString();
    _priceController.text = item.price.toString();
    _quantityController.text = item.quantity.toString();
    _selectedStockingDate = item.stockingDate?.toDate();
    _existingImageUrl = item.imageUrl;

    // Ensure the category exists in the options before setting it
    if (_categoryOptions.any((c) => c.toLowerCase() == item.category.toLowerCase())) {
       _selectedCategory = _categoryOptions.firstWhere((c) => c.toLowerCase() == item.category.toLowerCase());
    } else if (item.category.isNotEmpty) {
      // If category from item doesn't exist in options, add it
      _categoryOptions.add(item.category);
       _selectedCategory = item.category;
    }
    setState(() {}); // Update UI with populated data
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

  Future<void> _presentDatePicker() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 5, now.month, now.day); // Allow picking dates up to 5 years ago
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedStockingDate ?? now,
      firstDate: firstDate,
      lastDate: now, // Do not allow picking future dates
    );
    if (pickedDate != null) {
      setState(() {
        _selectedStockingDate = pickedDate;
      });
    }
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
    if (!_formKey.currentState!.validate() || _selectedCategory == null || _selectedStockingDate == null) {
      // ... (Validation logic remains the same) ...
      return;
    }

    setState(() => _isSaving = true);

    String? imageUrl = _existingImageUrl; // Start with the existing image URL

    try {
      // If a new image was picked, upload it and get the new URL
      if (_pickedImageBytes != null && _pickedImageFile != null) {
        String imageName = 'item_images/${DateTime.now().millisecondsSinceEpoch}_${_pickedImageFile!.name}';
        firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance.ref().child(imageName);
        final metadata = firebase_storage.SettableMetadata(contentType: _pickedImageFile!.mimeType ?? 'image/jpeg');
        await ref.putData(_pickedImageBytes!, metadata);
        imageUrl = await ref.getDownloadURL();
      }

      // Prepare data map for Firestore
      final itemData = {
        'category': _selectedCategory!,
        'brand': _brandController.text.trim(),
        'color': _colorController.text.trim(),
        'buyInPrice': double.parse(_buyInPriceController.text),
        'price': double.parse(_priceController.text),
        'quantity': int.parse(_quantityController.text),
        'imageUrl': imageUrl,
        'stockingDate': Timestamp.fromDate(_selectedStockingDate!),
        'lastModified': FieldValue.serverTimestamp(),
      };
      
      if (_isEditMode) {
        // --- UPDATE existing item ---
        await FirebaseFirestore.instance.collection('items').doc(widget.itemToEdit!.id).update(itemData);
      } else {
        // --- ADD new item ---
        await FirebaseFirestore.instance.collection('items').add(itemData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item ${_isEditMode ? 'updated' : 'saved'} successfully!'), backgroundColor: Colors.green),
        );
        if (_isEditMode) {
          Navigator.of(context).pop(); // Go back to inventory screen after editing
        } else {
           _formKey.currentState!.reset(); // Reset form for new entry
           // ... (clear controllers and state as before)
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save item: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget imagePreview;
    if (_pickedImageBytes != null) {
      imagePreview = Image.memory(_pickedImageBytes!, fit: BoxFit.contain);
    } else if (_existingImageUrl != null) {
      imagePreview = Image.network(_existingImageUrl!, fit: BoxFit.contain);
    } else {
      imagePreview = const Center(child: Text('No image', style: TextStyle(color: AppTheme.lightText)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Item' : 'Add New Item'),
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
                    }),
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

              const SizedBox(height: 12),

              // --- NEW: Date Picker UI ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12.0),
                  color: Colors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Stocking Date', style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          _selectedStockingDate == null
                              ? 'No date chosen'
                              : DateFormat.yMMMd().format(_selectedStockingDate!), // Example format: Jun 10, 2025
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_month, color: AppTheme.primaryPink),
                      onPressed: _presentDatePicker,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              
              Container(
                height: 200,
                margin: const EdgeInsets.only(bottom: 16.0),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12.0)),
                child: ClipRRect(borderRadius: BorderRadius.circular(11.0), child: imagePreview),
              ),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image_outlined),
                label: Text(_isEditMode && _pickedImageFile == null ? 'Change Image' : 'Pick Image'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.darkText, side: BorderSide(color: Colors.grey[300]!)),
              ),
              
              const SizedBox(height: 24),

              // --- UPDATED: Save Button ---
              ElevatedButton(
                onPressed: _isSaving ? null : _saveItem,
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_isEditMode ? 'Update Item' : 'Save Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
