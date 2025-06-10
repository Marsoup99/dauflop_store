import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:month_year_picker/month_year_picker.dart'; // <-- Import the new package
import '../theme/app_theme.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  int _totalSalesTransactions = 0;
  int _totalUnitsSold = 0;
  double _totalRevenue = 0.0;
  double _totalCogs = 0.0;
  double _totalProfit = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchSalesSummaryForMonth(_selectedDate);
  }

  Future<void> _fetchSalesSummaryForMonth(DateTime month) async {
    setState(() => _isLoading = true);
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0).add(const Duration(days: 1));

    try {
      QuerySnapshot salesSnapshot = await FirebaseFirestore.instance
          .collection('sales_transactions')
          .where('finalSaleTimestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('finalSaleTimestamp', isLessThan: Timestamp.fromDate(endOfMonth))
          .get();

      if (!mounted) return;

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
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching summary: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  // --- UPDATED: Method now uses showMonthYearPicker ---
  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showMonthYearPicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && (picked.month != _selectedDate.month || picked.year != _selectedDate.year)) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchSalesSummaryForMonth(_selectedDate);
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
            onPressed: _isLoading ? null : () => _fetchSalesSummaryForMonth(_selectedDate),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Showing results for:', style: Theme.of(context).textTheme.bodySmall),
                    Text(
                      DateFormat('MMMM yyyy').format(_selectedDate),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.darkText),
                    ),
                  ],
                ),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('Change'),
                  onPressed: () => _selectMonth(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _fetchSalesSummaryForMonth(_selectedDate),
                    child: ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                         if (_totalSalesTransactions > 0)
                          _buildSummaryCard(
                            title: 'Monthly Performance',
                            data: {
                              'Sales Transactions:': _totalSalesTransactions.toString(),
                              'Units Sold:': _totalUnitsSold.toString(),
                              'Revenue:': '\$${_totalRevenue.toStringAsFixed(2)}',
                              'Cost of Goods:': '\$${_totalCogs.toStringAsFixed(2)}',
                              'Profit:': '\$${_totalProfit.toStringAsFixed(2)}',
                            },
                            profit: _totalProfit,
                          )
                        else
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 50.0),
                              child: Text(
                                'No sales recorded for ${DateFormat('MMMM yyyy').format(_selectedDate)}.',
                                style: Theme.of(context).textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({required String title, required Map<String, String> data, double? profit}) {
    Color profitColor = Colors.grey;
    if (profit != null) {
      if (profit > 0) profitColor = Colors.green;
      if (profit < 0) profitColor = Colors.red;
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.darkText),
            ),
            const Divider(height: 24.0),
            ...data.entries.map((entry) {
              bool isProfitEntry = entry.key.toLowerCase().contains('profit');
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.lightText)),
                    Text(
                      entry.value,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: isProfitEntry ? FontWeight.bold : FontWeight.normal,
                        color: isProfitEntry ? profitColor : AppTheme.darkText,
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

