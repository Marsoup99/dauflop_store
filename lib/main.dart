import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/main_layout.dart'; // Your MainLayout screen
import 'theme/app_theme.dart';     // Import the new theme file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // FIX: Added try-catch to prevent crash on hot restart
  try {
    FirebaseFirestore.instance.enablePersistence(
      const PersistenceSettings(synchronizeTabs: true),
    );
  } catch (e) {
    // This error is expected on hot restart, so we can ignore it.
    print('Persistence already enabled: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DauFlop Store',
      debugShowCheckedModeBanner: false, // Hides the debug banner
      theme: AppTheme.theme, // Use the new theme
      home: const MainLayout(), // Set MainLayout as the home screen
    );
  }
}