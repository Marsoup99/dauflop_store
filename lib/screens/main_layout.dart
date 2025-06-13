import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_item_screen.dart';
import 'inventory_screen.dart';
import 'summary_screen.dart';
import 'pending_sales_screen.dart';
import '../theme/app_theme.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
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
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            label: 'Kho Hàng',
          ),
          BottomNavigationBarItem(
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
            label: 'Chờ Xử Lý',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Thêm Mới',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.assessment_outlined),
            label: 'Báo Cáo',
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
