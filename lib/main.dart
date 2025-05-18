import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'firebase_options.dart'; // THIS IS THE FILE THAT WAS JUST GENERATED

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase using the generated options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable Firestore offline persistence
  FirebaseFirestore.instance.enablePersistence(
    const PersistenceSettings(synchronizeTabs: true),
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Added super.key for constructor

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Simple Store',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Welcome to My Store'), // Added const
        ),
        body: const Center( // Added const
          child: Text('Firebase Configured! Ready for Firestore/Storage setup.'),
        ),
      ),
    );
  }
}