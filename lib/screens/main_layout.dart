import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_item_screen.dart';
import 'inventory_screen.dart';
import 'summary_screen.dart';
import 'pending_sales_screen.dart'; // <-- Import the new screen
import '../theme/app_theme.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // --- UPDATED: Screens list now includes PendingSalesScreen ---
  static const List<Widget> _widgetOptions = <Widget>[
    InventoryScreen(),    // Index 0
    PendingSalesScreen(), // Index 1
    AddItemScreen(),      // Index 2
    SummaryScreen(),      // Index 3
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Good for 4+ items
        // --- UPDATED: Navigation bar items ---
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            // --- BADGE MOVED HERE ---
            icon: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('pending_sales').snapshots(),
              builder: (context, snapshot) {
                final pendingCount = snapshot.data?.docs.length ?? 0;
                return Badge(
                  label: Text('$pendingCount'),
                  isLabelVisible: pendingCount > 0,
                  child: const Icon(Icons.hourglass_top_outlined),
                );
              },
            ),
            label: 'Pending',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Add Item',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.assessment_outlined),
            label: 'Summary',
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
