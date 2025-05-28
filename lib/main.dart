import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/main_layout.dart'; // Import your MainLayout

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.enablePersistence(
    const PersistenceSettings(synchronizeTabs: true),
  );
  runApp(const MyApp()); // Added const
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DauFlop Store', // You can change your app title here
      theme: ThemeData( // Optional: Add a basic theme
        primarySwatch: Colors.blue,
        useMaterial3: true, // Recommended for modern look
      ),
      home: const MainLayout(), // Set MainLayout as the home screen
    );
  }
}