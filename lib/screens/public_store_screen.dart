import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item_model.dart';
import '../widgets/public_item_card.dart';
import '../theme/app_theme.dart';

class PublicStoreScreen extends StatelessWidget {
  const PublicStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DauFlop Store'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // This stream fetches only items that are in stock
        stream: FirebaseFirestore.instance
            .collection('items')
            .where('quantity', isGreaterThan: 0)
            .orderBy('quantity')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Đã có lỗi xảy ra: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Cửa hàng đang cập nhật sản phẩm. Vui lòng quay lại sau!'));
          }

          final items = snapshot.data!.docs.map((doc) {
            return Item.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              spacing: 12.0, // Horizontal space
              runSpacing: 12.0, // Vertical space
              alignment: WrapAlignment.center,
              children: items.map((item) {
                return SizedBox(
                  width: 180,
                  child: PublicItemCard(item: item),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
