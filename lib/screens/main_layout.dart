import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_item_screen.dart';
import 'inventory_screen.dart';
import 'summary_screen.dart';
import 'pending_sales_screen.dart';
import 'incoming_orders_screen.dart'; // --- NEW: Import the new screen ---
import '../localizations/app_localizations.dart';
import '../theme/app_theme.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  String _authError = '';

  @override
  void initState() {
    super.initState();
    _signIn();
  }

  Future<void> _signIn() async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _authError = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _authError = 'Đã có lỗi xảy ra khi kết nối. Vui lòng kiểm tra mạng và khởi động lại app.';
        });
      }
    }
  }

  // --- UPDATE: Add the new screen to the options ---
  static const List<Widget> _widgetOptions = <Widget>[
    IncomingOrdersScreen(), // <-- NEW: Set as the first screen
    InventoryScreen(),
    PendingSalesScreen(),
    AddItemScreen(),
    SummaryScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_authError.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              _authError,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
      );
    }

    final loc = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          // --- NEW: Tab for Incoming Orders ---
          BottomNavigationBarItem(
            icon: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('incoming_orders').snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return Badge(
                  label: Text('$count'),
                  isLabelVisible: count > 0,
                  child: const Icon(Icons.call_received),
                );
              },
            ),
            label: loc.translate('incoming_orders'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.storefront_outlined),
            label: loc.translate('inventory'),
          ),
          BottomNavigationBarItem(
            icon: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('pending_sales').snapshots(),
              builder: (context, snapshot) {
                final pendingCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                
                return Badge(
                  label: Text('$pendingCount'),
                  isLabelVisible: pendingCount > 0,
                  child: const Icon(Icons.hourglass_top_outlined),
                );
              },
            ),
            label: loc.translate('pending_sales'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.add_circle_outline),
            label: loc.translate('add_new'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.assessment_outlined),
            label: loc.translate('summary'),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppTheme.accentPink,
        unselectedItemColor: AppTheme.lightText,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }
}
