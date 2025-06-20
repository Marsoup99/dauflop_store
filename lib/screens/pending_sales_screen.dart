import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../localizations/app_localizations.dart';
import '../models/pending_sale_model.dart';
import '../widgets/pending_sale_item_tile.dart';
import 'package:intl/intl.dart';

class PendingSalesScreen extends StatefulWidget {
  // --- FIX: The constructor should not require any parameters ---
  const PendingSalesScreen({super.key});

  @override
  State<PendingSalesScreen> createState() => _PendingSalesScreenState();
}

class _PendingSalesScreenState extends State<PendingSalesScreen> {

  Future<void> _confirmPendingSale(PendingSale pendingSale) async {
    final loc = AppLocalizations.of(context);
    try {
      final profit = (pendingSale.sellPriceAtPending - pendingSale.buyInPriceAtPending) * pendingSale.quantityPending;
      
      // --- NEW: Create the saleMonth key ---
      final now = DateTime.now();
      final String saleMonthKey = DateFormat('yyyy-MM').format(now); // e.g., "2025-06"

      final transactionData = {
        'itemId': pendingSale.itemId,
        'itemName': pendingSale.itemName,
        'itemColor': pendingSale.itemColor,
        'imageUrl': pendingSale.imageUrl,
        'quantitySold': pendingSale.quantityPending,
        'buyInPriceAtSale': pendingSale.buyInPriceAtPending,
        'sellPriceAtSale': pendingSale.sellPriceAtPending,
        'profitOnSale': profit,
        'finalSaleTimestamp': Timestamp.fromDate(now), // Use the timestamp from the 'now' variable
        'saleMonth': saleMonthKey, // <-- ADDED THIS FIELD FOR FAST QUERYING
      };
      
      WriteBatch batch = FirebaseFirestore.instance.batch();
      batch.set(FirebaseFirestore.instance.collection('sales_transactions').doc(), transactionData);
      batch.delete(FirebaseFirestore.instance.collection('pending_sales').doc(pendingSale.id));
      batch.update(FirebaseFirestore.instance.collection('items').doc(pendingSale.itemId), {'lastModified': Timestamp.now()});
      await batch.commit();

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.translate('sale_confirmed_message')), backgroundColor: Colors.green));
    } catch(e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.translate('sale_confirm_fail', params: {'error': e.toString()})), backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _cancelPendingSale(PendingSale pendingSale) async {
    final loc = AppLocalizations.of(context);
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      batch.update(FirebaseFirestore.instance.collection('items').doc(pendingSale.itemId), {'quantity': FieldValue.increment(pendingSale.quantityPending), 'lastModified': Timestamp.now()});
      batch.delete(FirebaseFirestore.instance.collection('pending_sales').doc(pendingSale.id));
      await batch.commit();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.translate('sale_cancelled_message')), backgroundColor: Colors.orange));
    } catch(e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.translate('sale_cancel_fail', params: {'error': e.toString()})), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('pending_sales_title')),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('pending_sales').orderBy('pendingTimestamp', descending: true).snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) return Center(child: Text('Ui, có lỗi rùi: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.data == null || snapshot.data!.docs.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(24.0), child: Text(loc.translate('no_pending_sales'), textAlign: TextAlign.center)));

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
