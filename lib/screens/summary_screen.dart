import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:month_year_picker/month_year_picker.dart';
import '../localizations/app_localizations.dart';
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
  double _totalRevenue = 0.0;
  double _totalCogs = 0.0;
  double _totalProfit = 0.0;
  
  List<QueryDocumentSnapshot> _salesDocs = [];

  @override
  void initState() {
    super.initState();
    _fetchSalesSummaryForMonth(_selectedDate);
  }

  // --- UPDATED: This method now uses a much faster query ---
    Future<void> _fetchSalesSummaryForMonth(DateTime month) async {
    setState(() => _isLoading = true);
    final String saleMonthKey = DateFormat('yyyy-MM').format(month);

    try {
      QuerySnapshot salesSnapshot = await FirebaseFirestore.instance
          .collection('sales_transactions')
          .where('saleMonth', isEqualTo: saleMonthKey)
          .orderBy('finalSaleTimestamp', descending: true)
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
        _totalRevenue = revenue;
        _totalCogs = cogs;
        _totalProfit = revenue - cogs;
        _salesDocs = salesSnapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // --- UPDATED: Better Error Handling ---
        // Check if this is the specific Firestore "missing index" error
        if (e.toString().contains('FAILED_PRECONDITION')) {
          _showIndexCreationDialog(e.toString());
        } else {
          // Show a generic error for other issues
          _showIndexCreationDialog(e.toString());
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải báo cáo: $e'), backgroundColor: Colors.redAccent));
        }
      }
    }
  }
  
  // --- NEW: Method to show the specific Firestore index error dialog ---
  void _showIndexCreationDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yêu Cầu Cấu Hình Database'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Firestore cần một chỉ mục (index) mới để thực hiện truy vấn này. Đây là một thao tác bình thường và chỉ cần làm một lần.'),
              const SizedBox(height: 16),
              const Text('Vui lòng nhấp vào liên kết trong thông báo lỗi bên dưới để tạo chỉ mục:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey[200],
                child: SelectableText(errorMessage), // Makes the URL selectable
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showMonthYearPicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('vi'),
    );
    if (picked != null && (picked.month != _selectedDate.month || picked.year != _selectedDate.year)) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchSalesSummaryForMonth(_selectedDate);
    }
  }

  Future<void> _deleteSaleTransaction(String saleId, String itemName) async {
    final loc = AppLocalizations.of(context);
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.translate('delete_transaction_confirm_title')),
        content: Text(loc.translate('delete_transaction_confirm_content', params: {'item_name': itemName})),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(loc.translate('dialog_cancel_button'))),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red[100]),
            child: Text(loc.translate('delete_button'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;
    try {
      await FirebaseFirestore.instance.collection('sales_transactions').doc(saleId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.translate('transaction_deleted_success')), backgroundColor: Colors.green));
        _fetchSalesSummaryForMonth(_selectedDate);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.translate('transaction_deleted_fail', params: {'error': e.toString()})), backgroundColor: Colors.redAccent));
      }
    }
  }
  
  Future<void> _editSaleTransaction(String saleId, Map<String, dynamic> saleData) async {
    final loc = AppLocalizations.of(context);
    final buyInPriceController = TextEditingController(text: (saleData['buyInPriceAtSale'] as num?)?.toStringAsFixed(2) ?? '0.00');
    final sellPriceController = TextEditingController(text: (saleData['sellPriceAtSale'] as num?)?.toStringAsFixed(2) ?? '0.00');
    final formKey = GlobalKey<FormState>();
    final bool? shouldUpdate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.translate('edit_prices_dialog_title', params: {'item_name': saleData['itemName']})),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: buyInPriceController, decoration: InputDecoration(labelText: loc.translate('buy_in_price'), prefixText: '\$ '), keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))], validator: (v) => (v == null || v.isEmpty || double.tryParse(v) == null) ? loc.translate('error_invalid_number') : null),
              const SizedBox(height: 8),
              TextFormField(controller: sellPriceController, decoration: InputDecoration(labelText: loc.translate('sell_price'), prefixText: '\$ '), keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))], validator: (v) => (v == null || v.isEmpty || double.tryParse(v) == null) ? loc.translate('error_invalid_number') : null),
            ],
          )
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(loc.translate('dialog_cancel_button'))),
          ElevatedButton(onPressed: () { if(formKey.currentState!.validate()){ Navigator.of(context).pop(true); } }, child: Text(loc.translate('update_button'))),
        ],
      )
    );
    if (shouldUpdate != true) return;
    try {
      final double newBuyPrice = double.parse(buyInPriceController.text);
      final double newSellPrice = double.parse(sellPriceController.text);
      final int quantity = saleData['quantitySold'] as int? ?? 1;
      final double newProfit = (newSellPrice - newBuyPrice) * quantity;
      await FirebaseFirestore.instance.collection('sales_transactions').doc(saleId).update({
        'buyInPriceAtSale': newBuyPrice, 'sellPriceAtSale': newSellPrice, 'profitOnSale': newProfit,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.translate('update_prices_success')), backgroundColor: Colors.green));
        _fetchSalesSummaryForMonth(_selectedDate);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.translate('update_prices_fail', params: {'error': e.toString()})), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('summary_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: loc.translate('refresh_tooltip'),
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
                    Text(loc.translate('showing_results_for'), style: Theme.of(context).textTheme.bodySmall),
                    Text(
                      DateFormat('MMMM, yyyy', 'vi_VN').format(_selectedDate),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.darkText),
                    ),
                  ],
                ),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(loc.translate('change_month_button')),
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
                         _buildSummaryCard(
                            title: loc.translate('monthly_performance_title'),
                            data: {
                              loc.translate('sales_transactions_label'): _totalSalesTransactions.toString(),
                              loc.translate('revenue_label'): '\$${_totalRevenue.toStringAsFixed(2)}',
                              loc.translate('cogs_label'): '\$${_totalCogs.toStringAsFixed(2)}',
                              loc.translate('profit_label'): '\$${_totalProfit.toStringAsFixed(2)}',
                            },
                            profit: _totalProfit,
                          ),
                          const SizedBox(height: 24),
                          if (_salesDocs.isNotEmpty)
                            _buildSalesHistoryList()
                          else
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 24.0),
                                child: Text(
                                  loc.translate('no_sales_for_month', params: {'month': DateFormat('MMMM, yyyy', 'vi_VN').format(_selectedDate)}),
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
    final loc = AppLocalizations.of(context);
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
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.darkText)),
            const Divider(height: 24.0),
            ...data.entries.map((entry) {
              bool isProfitEntry = entry.key == loc.translate('profit_label');
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.lightText)),
                    Text(
                      entry.value,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: isProfitEntry ? FontWeight.bold : FontWeight.normal, color: isProfitEntry ? profitColor : AppTheme.darkText),
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
  
  Widget _buildSalesHistoryList() {
    final loc = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.translate('sales_history_title'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.darkText)),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _salesDocs.length,
          itemBuilder: (context, index) {
            final doc = _salesDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            final itemName = data['itemName'] as String? ?? 'Bé iu vô danh';
            final buyPrice = (data['buyInPriceAtSale'] as num?)?.toDouble() ?? 0.0;
            final sellPrice = (data['sellPriceAtSale'] as num?)?.toDouble() ?? 0.0;
            final timestamp = (data['finalSaleTimestamp'] as Timestamp?)?.toDate();

            return Card(
              elevation: 1,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text(itemName),
                subtitle: Text('${loc.translate('sold_on_label')} ${timestamp != null ? DateFormat.yMd('vi_VN').add_jm().format(timestamp) : '...'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('\$${sellPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        Text('${loc.translate('cost_label')} \$${buyPrice.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.lightText))
                      ],
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') { _deleteSaleTransaction(doc.id, itemName); } 
                        else if (value == 'edit') { _editSaleTransaction(doc.id, data); }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(value: 'edit', child: Text(loc.translate('edit_prices_menu'))),
                        PopupMenuItem<String>(value: 'delete', child: Text(loc.translate('delete_transaction_menu'), style: const TextStyle(color: Colors.red))),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
