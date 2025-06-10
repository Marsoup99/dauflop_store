import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pending_sale_model.dart';
import 'widgets/pending_sale_item_tile.dart';

class PendingSalesScreen extends StatefulWidget {
  const PendingSalesScreen({super.key});

  @override
  State<PendingSalesScreen> createState() => _PendingSalesScreenState();
}

class _PendingSalesScreenState extends State<PendingSalesScreen> {
  // This screen will now manage the state for its own actions
  // Note: The logic methods are copied from the old inventory_screen.dart

  Future<void> _confirmPendingSale(PendingSale pendingSale) async {
    try {
      final profit = (pendingSale.sellPriceAtPending - pendingSale.buyInPriceAtPending) * pendingSale.quantityPending;
      final transactionData = {
        'itemId': pendingSale.itemId,
        'itemName': pendingSale.itemName,
        'itemColor': pendingSale.itemColor,
        'imageUrl': pendingSale.imageUrl,
        'quantitySold': pendingSale.quantityPending,
        'buyInPriceAtSale': pendingSale.buyInPriceAtPending,
        'sellPriceAtSale': pendingSale.sellPriceAtPending,
        'profitOnSale': profit,
        'finalSaleTimestamp': Timestamp.now()
      };
      
      WriteBatch batch = FirebaseFirestore.instance.batch();
      batch.set(FirebaseFirestore.instance.collection('sales_transactions').doc(), transactionData);
      batch.delete(FirebaseFirestore.instance.collection('pending_sales').doc(pendingSale.id));
      batch.update(FirebaseFirestore.instance.collection('items').doc(pendingSale.itemId), {'lastModified': Timestamp.now()});
      await batch.commit();

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale confirmed!'), backgroundColor: Colors.green));
    } catch(e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to confirm sale: $e'), backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _cancelPendingSale(PendingSale pendingSale) async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      batch.update(FirebaseFirestore.instance.collection('items').doc(pendingSale.itemId), {'quantity': FieldValue.increment(pendingSale.quantityPending), 'lastModified': Timestamp.now()});
      batch.delete(FirebaseFirestore.instance.collection('pending_sales').doc(pendingSale.id));
      await batch.commit();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pending sale cancelled.'), backgroundColor: Colors.orange));
    } catch(e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to cancel sale: $e'), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Sales'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('pending_sales').orderBy('pendingTimestamp', descending: true).snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) return Center(child: Text('Something went wrong: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.data == null || snapshot.data!.docs.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(24.0), child: Text('No sales are currently pending confirmation.', textAlign: TextAlign.center)));

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            itemBuilder: (context, index) {
              DocumentSnapshot document = snapshot.data!.docs[index];
              PendingSale pendingSale = PendingSale.fromMap(document.data()! as Map<String, dynamic>, document.id);
              return PendingSaleItemTile(
                key: ValueKey(pendingSale.id),
                pendingSale: pendingSale,
                onConfirm: _confirmPendingSale,
                onCancel: _cancelPendingSale,
              );
            },
          );
        },
      ),
    );
  }
}
