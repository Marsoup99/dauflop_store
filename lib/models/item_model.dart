import 'package:cloud_firestore/cloud_firestore.dart'; // Required for Timestamp

class Item {
  String? id; // Firestore document ID
  String category;
  String brand;
  String color;
  String? imageUrl; // URL from Firebase Storage
  double buyInPrice;
  double price; // Selling price
  int quantity;
  Timestamp? lastModified; // To know when it was last updated

  Item({
    this.id,
    required this.category,
    required this.brand,
    required this.color,
    this.imageUrl, // Optional, can be null
    required this.buyInPrice,
    required this.price,
    required this.quantity,
    this.lastModified,
  });

  // Method to convert an Item object into a Map to store in Firestore
  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'brand': brand,
      'color': color,
      'imageUrl': imageUrl,
      'buyInPrice': buyInPrice,
      'price': price,
      'quantity': quantity,
      'lastModified': lastModified ?? FieldValue.serverTimestamp(), // Set server timestamp if null
    };
  }

  // Factory constructor to create an Item object from a Firestore document (Map)
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
      lastModified: map['lastModified'] as Timestamp?, // Cast as Timestamp or null
    );
  }
}