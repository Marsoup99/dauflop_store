import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'localizations/app_localizations.dart';
import 'widgets/auth_wrapper.dart';
import 'screens/public_store_screen.dart';
import 'theme/app_theme.dart';

// This variable will be set by our build command.
const flavor = String.fromEnvironment('APP_FLAVOR');

// --- RENAMED VARIABLES TO AVOID CONFLICT ---
const kApiKey = String.fromEnvironment('ADMIN_API_KEY');

// Now use the variables to build your options
final FirebaseOptions adminFirebaseOptions = FirebaseOptions(
  apiKey: kApiKey, // Use the renamed variable
  authDomain: "dauflop-admin.web.app",
  projectId: "dauflop-store",
  storageBucket: "dauflop-store.firebasestorage.app",
  messagingSenderId: "80413761686",
  appId: "1:80413761686:web:34a29e332eb229fa3622b7",
);

final FirebaseOptions publicFirebaseOptions = FirebaseOptions(
  apiKey: kApiKey, // Use the renamed variable
  authDomain: "dauflop-store.firebaseapp.com",
  projectId: "dauflop-store",
  storageBucket: "dauflop-store.firebasestorage.app",
  messagingSenderId: "80413761686",
  appId: "1:80413761686:web:c82bc51d872ad9d73622b7",
);


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Add a check to ensure keys were provided
  if ((flavor == 'admin' && kApiKey.isEmpty)) {
    print("FATAL ERROR: API Key for flavor '$flavor' was not provided in the build command.");
    // You might want to show an error screen instead of just printing
  }

  await Firebase.initializeApp(
    options: flavor == 'admin' ? adminFirebaseOptions : publicFirebaseOptions,
  );
  
  try {
    FirebaseFirestore.instance.enablePersistence(const PersistenceSettings(synchronizeTabs: true));
  } catch (e) {
    print('Persistence already enabled: $e');
  }

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: flavor == 'admin' ? 'DauFlop Store Admin' : 'DauFlop Store',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: flavor == 'admin' ? const AuthWrapper() : const PublicStoreScreen(),
      supportedLocales: const [ Locale('vi', 'VN'), ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        MonthYearPickerLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first;
      },
    );
  }
}
