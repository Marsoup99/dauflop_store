import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  String? id;
  String category;
  String brand;
  String color;
  String? imageUrl;
  double buyInPrice;
  double price; // Current default selling price
  int quantity; // Total physical quantity currently in stock
  Timestamp? lastModified;
  Timestamp? stockingDate; // <-- NEW FIELD for "Ngày nhập hàng"

  Item({
    this.id,
    required this.category,
    required this.brand,
    required this.color,
    this.imageUrl,
    required this.buyInPrice,
    required this.price,
    required this.quantity,
    this.lastModified,
    this.stockingDate, // <-- Added to constructor
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'brand': brand,
      'color': color,
      'imageUrl': imageUrl,
      'buyInPrice': buyInPrice,
      'price': price,
      'quantity': quantity,
      'lastModified': lastModified ?? FieldValue.serverTimestamp(),
      'stockingDate': stockingDate, // <-- Added to map
    };
  }

  factory Item.fromMap(Map<String, dynamic> map, String documentId) {
    return Item(
      id: documentId,
      category: map['category'] ?? '',
      brand: map['brand'] ?? '',
      color: map['color'] ?? '',
      imageUrl: map['imageUrl'],
      buyInPrice: (map['buyInPrice'] ?? 0.0).toDouble(),
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 0,
      lastModified: map['lastModified'] as Timestamp?,
      stockingDate: map['stockingDate'] as Timestamp?, // <-- Read from map
    );
  }
}
