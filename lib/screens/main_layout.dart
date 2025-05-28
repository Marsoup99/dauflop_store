import 'package:flutter/material.dart';
import 'add_item_screen.dart';
import 'inventory_screen.dart';
import 'summary_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0; // To keep track of the selected tab

  // List of the screens to be displayed
  static const List<Widget> _widgetOptions = <Widget>[
    InventoryScreen(), // Default screen (index 0)
    AddItemScreen(),   // Index 1
    SummaryScreen(),   // Index 2
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
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Add Item',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment_outlined),
            label: 'Summary',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800], // Or your preferred color
        onTap: _onItemTapped,
      ),
    );
  }
}
// This MainLayout widget serves as the main screen of the app.
// It contains a BottomNavigationBar to switch between Inventory, Add Item, and Summary screens.