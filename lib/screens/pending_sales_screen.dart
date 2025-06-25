import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../localizations/app_localizations.dart';
import '../models/pending_sale_model.dart';
import '../widgets/pending_sale_item_tile.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class PendingSalesScreen extends StatefulWidget {
  const PendingSalesScreen({super.key});

  @override
  State<PendingSalesScreen> createState() => _PendingSalesScreenState();
}

class _PendingSalesScreenState extends State<PendingSalesScreen> {

  Future<void> _confirmPendingSale(PendingSale pendingSale) async {
    final loc = AppLocalizations.of(context);
    final firestore = FirebaseFirestore.instance;
    final itemRef = firestore.collection('items').doc(pendingSale.itemId);
    final pendingSaleRef = firestore.collection('pending_sales').doc(pendingSale.id);
    final salesTransactionRef = firestore.collection('sales_transactions').doc();

    try {
      // --- UPDATE: Use a transaction for atomic operations ---
      await firestore.runTransaction((transaction) async {
        // 1. Read the current item document
        final itemSnapshot = await transaction.get(itemRef);

        if (!itemSnapshot.exists) {
          // If the item doesn't exist, we can't check its quantity,
          // but we can still record the sale and delete the pending entry.
          print('Warning: Item with ID ${pendingSale.itemId} not found, but confirming sale anyway.');
        }

        // The item's quantity was already decremented when it was moved to pending.
        // So the current quantity is the final quantity after this sale.
        final currentQuantity = itemSnapshot.exists
            ? (itemSnapshot.data() as Map<String, dynamic>)['quantity'] as int? ?? 0
            : 0;

        // 2. Prepare sales transaction data
        final profit = (pendingSale.sellPriceAtPending - pendingSale.buyInPriceAtPending) * pendingSale.quantityPending;
        final now = DateTime.now();
        final String saleMonthKey = DateFormat('yyyy-MM').format(now);
        final transactionData = {
          'itemId': pendingSale.itemId,
          'itemName': pendingSale.itemName,
          'itemColor': pendingSale.itemColor,
          'imageUrl': pendingSale.imageUrl,
          'quantitySold': pendingSale.quantityPending,
          'buyInPriceAtSale': pendingSale.buyInPriceAtPending,
          'sellPriceAtSale': pendingSale.sellPriceAtPending,
          'profitOnSale': profit,
          'finalSaleTimestamp': Timestamp.fromDate(now),
          'saleMonth': saleMonthKey,
        };

        // 3. Perform database writes
        transaction.set(salesTransactionRef, transactionData);
        transaction.delete(pendingSaleRef);

        // 4. If this was the last item, delete the item document. Otherwise, update it.
        if (currentQuantity == 0 && itemSnapshot.exists) {
          transaction.delete(itemRef);
        } else if (itemSnapshot.exists) {
          transaction.update(itemRef, {'lastModified': Timestamp.now()});
        }
      });

      // --- AFTER TRANSACTION SUCCEEDS ---
      // 5. Check if the item was deleted and if it has an image to delete from storage.
      final itemDocAfterSale = await itemRef.get();
      if (!itemDocAfterSale.exists) { // This confirms the transaction deleted the item
        if (pendingSale.imageUrl != null && pendingSale.imageUrl!.isNotEmpty) {
          try {
            await firebase_storage.FirebaseStorage.instance.refFromURL(pendingSale.imageUrl!).delete();
            print("Successfully deleted sold-out item image from storage.");
          } catch (e) {
            print("Failed to delete item image from storage. It may be an orphan. Error: $e");
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(loc.translate('sale_confirmed_message')),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(loc.translate('sale_confirm_fail', params: {'error': e.toString()})),
          backgroundColor: Colors.redAccent,
        ));
      }
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
