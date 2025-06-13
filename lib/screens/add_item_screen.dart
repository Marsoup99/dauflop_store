import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../localizations/app_localizations.dart';
import '../models/item_model.dart';
import '../theme/app_theme.dart';

class AddItemScreen extends StatefulWidget {
  final Item? itemToEdit;

  const AddItemScreen({super.key, this.itemToEdit});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _colorController = TextEditingController();
  final _buyInPriceController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _newCategoryController = TextEditingController();
  final _newBrandController = TextEditingController();

  List<String> _categoryOptions = [];
  String? _selectedCategory;
  bool _isLoadingCategories = true;
  final String _addNewCategoryValue = 'ADD_NEW_CATEGORY_VALUE';

  List<String> _brandOptions = [];
  String? _selectedBrand;
  bool _isLoadingBrands = true;
  final String _addNewBrandValue = 'ADD_NEW_BRAND_VALUE';
  
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
    _fetchInitialData();
  }

  void _populateFieldsForEdit() {
    final item = widget.itemToEdit!;
    _colorController.text = item.color;
    _buyInPriceController.text = item.buyInPrice.toString();
    _priceController.text = item.price.toString();
    _quantityController.text = item.quantity.toString();
    _selectedStockingDate = item.stockingDate?.toDate();
    _existingImageUrl = item.imageUrl;

    if (_categoryOptions.any((c) => c.toLowerCase() == item.category.toLowerCase())) {
       _selectedCategory = _categoryOptions.firstWhere((c) => c.toLowerCase() == item.category.toLowerCase());
    } else if (item.category.isNotEmpty) {
      _categoryOptions.add(item.category);
      _selectedCategory = item.category;
    }

    if (_brandOptions.any((b) => b.toLowerCase() == item.brand.toLowerCase())) {
       _selectedBrand = _brandOptions.firstWhere((b) => b.toLowerCase() == item.brand.toLowerCase());
    } else if (item.brand.isNotEmpty) {
      _brandOptions.add(item.brand);
      _selectedBrand = item.brand;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _colorController.dispose();
    _buyInPriceController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _newCategoryController.dispose();
    _newBrandController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    setState(() { _isLoadingCategories = true; _isLoadingBrands = true; });
    try {
      final snapshot = await FirebaseFirestore.instance.collection('items').get();
      final categories = snapshot.docs.map((doc) => (doc.data()['category'] as String?)?.trim() ?? '').where((c) => c.isNotEmpty).toSet().toList()..sort((a,b) => a.toLowerCase().compareTo(b.toLowerCase()));
      final brands = snapshot.docs.map((doc) => (doc.data()['brand'] as String?)?.trim() ?? '').where((b) => b.isNotEmpty).toSet().toList()..sort((a,b) => a.toLowerCase().compareTo(b.toLowerCase()));
      
      if (mounted) {
        setState(() {
          _categoryOptions = categories;
          _brandOptions = brands;
          _isLoadingCategories = false;
          _isLoadingBrands = false;
        });
        if (_isEditMode) {
          _populateFieldsForEdit();
        } else {
          _selectedStockingDate = DateTime.now();
        }
      }
    } catch (e) {
      if (mounted) setState(() { _isLoadingCategories = false; _isLoadingBrands = false; });
      print("Error fetching initial data: $e");
    }
  }

  Future<void> _showAddNewDialog({required String title, required TextEditingController controller, required List<String> options, required Function(String) onAdd}) async {
    final loc = AppLocalizations.of(context);
    controller.clear();
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(controller: controller, autofocus: true, decoration: InputDecoration(hintText: loc.translate('dialog_enter_name_hint'))),
          actions: <Widget>[
            TextButton(child: Text(loc.translate('dialog_cancel_button')), onPressed: () => Navigator.of(context).pop()),
            ElevatedButton(
              child: Text(loc.translate('dialog_add_button')),
              onPressed: () {
                final newValue = controller.text.trim();
                if (newValue.isNotEmpty && !options.any((opt) => opt.toLowerCase() == newValue.toLowerCase())) {
                  onAdd(newValue);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(newValue.isEmpty ? loc.translate('error_name_empty') : loc.translate('error_name_exists')),
                    backgroundColor: Colors.redAccent,
                  ));
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
    final firstDate = DateTime(now.year - 5, now.month, now.day);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedStockingDate ?? now,
      firstDate: firstDate,
      lastDate: now,
      locale: const Locale('vi', 'VN'),
    );
    if (pickedDate != null) {
      setState(() { _selectedStockingDate = pickedDate; });
    }
  }

  Future<void> _pickImage() async {
    final loc = AppLocalizations.of(context);
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxHeight: 480, imageQuality: 80);

    if (image != null) {
      final bytes = await image.readAsBytes();
      final int imageSizeInBytes = bytes.length;
      final double imageSizeInMB = imageSizeInBytes / (1024 * 1024);

      if (imageSizeInBytes > _maxImageSizeBytes) {
        setState(() { _pickedImageFile = null; _pickedImageBytes = null; });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.translate('image_too_large_message', params: {'size': imageSizeInMB.toStringAsFixed(2)})),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }
      setState(() { _pickedImageFile = image; _pickedImageBytes = bytes; });
    }
  }

  Future<void> _saveItem() async {
    final loc = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate() || _selectedCategory == null || _selectedBrand == null || _selectedStockingDate == null) {
       if ((_selectedCategory == null || _selectedBrand == null) && mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.translate('validation_enter_category')), backgroundColor: Colors.orange));
      }
      return;
    }

    setState(() => _isSaving = true);

    String? imageUrl = _existingImageUrl;
    try {
      if (_pickedImageBytes != null && _pickedImageFile != null) {
        String imageName = 'item_images/${DateTime.now().millisecondsSinceEpoch}_${_pickedImageFile!.name}';
        firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance.ref().child(imageName);
        final metadata = firebase_storage.SettableMetadata(contentType: _pickedImageFile!.mimeType ?? 'image/jpeg');
        await ref.putData(_pickedImageBytes!, metadata);
        imageUrl = await ref.getDownloadURL();
      }

      final itemData = {
        'category': _selectedCategory!, 'brand': _selectedBrand!, 'color': _colorController.text.trim(),
        'buyInPrice': double.parse(_buyInPriceController.text), 'price': double.parse(_priceController.text),
        'quantity': int.parse(_quantityController.text), 'imageUrl': imageUrl,
        'stockingDate': Timestamp.fromDate(_selectedStockingDate!), 'lastModified': FieldValue.serverTimestamp(),
      };
      
      if (_isEditMode) {
        await FirebaseFirestore.instance.collection('items').doc(widget.itemToEdit!.id).update(itemData);
      } else {
        await FirebaseFirestore.instance.collection('items').add(itemData);
      }

      if (mounted) {
        final action = _isEditMode ? loc.translate('action_updated') : loc.translate('action_saved');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.translate('save_success_message', params: {'action': action})), backgroundColor: Colors.green));
        if (_isEditMode) {
          Navigator.of(context).pop();
        } else {
           _formKey.currentState!.reset();
           _colorController.clear();
           _buyInPriceController.clear();
           _priceController.clear();
           _quantityController.clear();
           setState(() {
             _pickedImageFile = null;
             _pickedImageBytes = null;
             _selectedCategory = null;
             _selectedBrand = null;
             _selectedStockingDate = DateTime.now();
           });
           _fetchInitialData();
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.translate('save_fail_message', params: {'error': e.toString()})), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    Widget imagePreview;
    if (_pickedImageBytes != null) {
      imagePreview = Image.memory(_pickedImageBytes!, fit: BoxFit.contain);
    } else if (_existingImageUrl != null) {
      imagePreview = Image.network(_existingImageUrl!, fit: BoxFit.contain);
    } else {
      imagePreview = Center(child: Text(loc.translate('no_image_selected'), style: const TextStyle(color: AppTheme.lightText)));
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? loc.translate('edit_item_title') : loc.translate('add_item_title'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _isLoadingCategories
                ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24.0), child: CircularProgressIndicator()))
                : DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: loc.translate('category')),
                    value: _selectedCategory,
                    hint: Text(loc.translate('select_category_hint')),
                    items: [
                      ..._categoryOptions.map((v) => DropdownMenuItem(value: v, child: Text(v))),
                      DropdownMenuItem(value: _addNewCategoryValue, child: Row(children: [const Icon(Icons.add, color: AppTheme.primaryPink), const SizedBox(width: 8), Text(loc.translate('add_new_category'), style: const TextStyle(color: AppTheme.primaryPink, fontWeight: FontWeight.bold))])),
                    ],
                    onChanged: (v) {
                      if (v == _addNewCategoryValue) {
                        _showAddNewDialog(title: loc.translate('add_new_category_dialog_title'), controller: _newCategoryController, options: _categoryOptions, onAdd: (newVal) {
                           setState(() { _categoryOptions.add(newVal); _categoryOptions.sort((a,b) => a.toLowerCase().compareTo(b.toLowerCase())); _selectedCategory = newVal; });
                        });
                      } else {
                        setState(() => _selectedCategory = v);
                      }
                    },
                    validator: (v) => v == null ? loc.translate('validation_enter_category') : null,
                  ),
              const SizedBox(height: 12),

              _isLoadingBrands
                ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24.0), child: CircularProgressIndicator()))
                : DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: loc.translate('brand')),
                    value: _selectedBrand,
                    hint: Text(loc.translate('select_brand_hint')),
                    items: [
                      ..._brandOptions.map((v) => DropdownMenuItem(value: v, child: Text(v))),
                      DropdownMenuItem(value: _addNewBrandValue, child: Row(children: [const Icon(Icons.add, color: AppTheme.primaryPink), const SizedBox(width: 8), Text(loc.translate('add_new_brand'), style: const TextStyle(color: AppTheme.primaryPink, fontWeight: FontWeight.bold))])),
                    ],
                    onChanged: (v) {
                      if (v == _addNewBrandValue) {
                        _showAddNewDialog(title: loc.translate('add_new_brand_dialog_title'), controller: _newBrandController, options: _brandOptions, onAdd: (newVal) {
                          setState(() { _brandOptions.add(newVal); _brandOptions.sort((a,b) => a.toLowerCase().compareTo(b.toLowerCase())); _selectedBrand = newVal; });
                        });
                      } else {
                        setState(() => _selectedBrand = v);
                      }
                    },
                    validator: (v) => v == null ? loc.translate('validation_enter_brand') : null,
                  ),
              const SizedBox(height: 12),
              
              TextFormField(controller: _colorController, decoration: InputDecoration(labelText: loc.translate('color_variant')), validator: (v) => (v == null || v.isEmpty) ? loc.translate('validation_enter_color') : null),
              const SizedBox(height: 12),
              TextFormField(controller: _buyInPriceController, decoration: InputDecoration(labelText: loc.translate('buy_in_price')), keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))], validator: (v) => (v == null || v.isEmpty || double.tryParse(v) == null) ? loc.translate('error_invalid_number') : null),
              const SizedBox(height: 12),
              TextFormField(controller: _priceController, decoration: InputDecoration(labelText: loc.translate('sell_price')), keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))], validator: (v) => (v == null || v.isEmpty || double.tryParse(v) == null) ? loc.translate('error_invalid_number') : null),
              const SizedBox(height: 12),
              TextFormField(controller: _quantityController, decoration: InputDecoration(labelText: loc.translate('quantity')), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => (v == null || v.isEmpty || int.tryParse(v) == null) ? loc.translate('error_must_be_integer') : null),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12.0), color: Colors.white),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.translate('stocking_date'), style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          _selectedStockingDate == null ? 'Chưa chọn ngày' : DateFormat.yMMMd('vi_VN').format(_selectedStockingDate!),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.calendar_month, color: AppTheme.primaryPink), onPressed: _presentDatePicker),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              
              Container(
                height: 200, margin: const EdgeInsets.only(bottom: 16.0),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12.0)),
                child: ClipRRect(borderRadius: BorderRadius.circular(11.0), child: imagePreview),
              ),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image_outlined),
                label: Text(_isEditMode && _pickedImageFile == null ? loc.translate('change_image_button') : loc.translate('pick_image_button')),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.darkText, side: BorderSide(color: Colors.grey[300]!)),
              ),
              
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isSaving ? null : _saveItem,
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_isEditMode ? loc.translate('update_button') : loc.translate('save_button')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
