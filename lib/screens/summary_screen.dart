import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  bool _isLoading = true;
  int _totalSalesTransactions = 0;
  int _totalUnitsSold = 0;
  double _totalRevenue = 0.0;
  double _totalCogs = 0.0;
  double _totalProfit = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchSalesSummary();
  }

  Future<void> _fetchSalesSummary() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot salesSnapshot =
          await FirebaseFirestore.instance.collection('sales_transactions').get();

      if (salesSnapshot.docs.isEmpty) {
        setState(() {
          _isLoading = false;
          // Reset all values if no sales
          _totalSalesTransactions = 0;
          _totalUnitsSold = 0;
          _totalRevenue = 0.0;
          _totalCogs = 0.0;
          _totalProfit = 0.0;
        });
        return;
      }

      int transactions = salesSnapshot.docs.length;
      int unitsSold = 0;
      double revenue = 0.0;
      double cogs = 0.0;

      for (var doc in salesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        unitsSold += (data['quantitySold'] as int? ?? 0);
        revenue += ((data['sellPriceAtSale'] as num?)?.toDouble() ?? 0.0) * (data['quantitySold'] as int? ?? 0);
        cogs += ((data['buyInPriceAtSale'] as num?)?.toDouble() ?? 0.0) * (data['quantitySold'] as int? ?? 0);
      }

      setState(() {
        _totalSalesTransactions = transactions;
        _totalUnitsSold = unitsSold;
        _totalRevenue = revenue;
        _totalCogs = cogs;
        _totalProfit = revenue - cogs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching sales summary: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching summary: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Summary',
            onPressed: _isLoading ? null : _fetchSalesSummary, // Disable while loading
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: RefreshIndicator( // Allows pull-to-refresh
                onRefresh: _fetchSalesSummary,
                child: ListView( // Use ListView to allow scrolling if content grows
                  children: [
                    _buildSummaryCard(
                      title: 'Overall Performance',
                      data: {
                        'Total Sales Transactions:': _totalSalesTransactions.toString(),
                        'Total Units Sold:': _totalUnitsSold.toString(),
                        'Total Revenue:': '\$${_totalRevenue.toStringAsFixed(2)}',
                        'Total COGS:': '\$${_totalCogs.toStringAsFixed(2)}',
                        'Total Profit:': '\$${_totalProfit.toStringAsFixed(2)}',
                      },
                      profit: _totalProfit, // Pass profit to conditionally color it
                    ),
                    // You could add more cards here later, e.g., "Recent Sales List"
                    // or charts if you want to get fancy.
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh Data'),
                        onPressed: _isLoading ? null : _fetchSalesSummary,
                    )
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard({required String title, required Map<String, String> data, double? profit}) {
    Color profitColor = Colors.grey; // Default
    if (profit != null) {
      if (profit > 0) profitColor = Colors.green;
      if (profit < 0) profitColor = Colors.red;
    }

    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12.0),
            ...data.entries.map((entry) {
              bool isProfitEntry = entry.key.toLowerCase().contains('profit');
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key, style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      entry.value,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: isProfitEntry ? FontWeight.bold : FontWeight.normal,
                        color: isProfitEntry ? profitColor : null,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}