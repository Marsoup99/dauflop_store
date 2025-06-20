import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:month_year_picker/month_year_picker.dart';
// Note: We no longer import the generated firebase_options.dart file
import 'localizations/app_localizations.dart';
import 'widgets/auth_wrapper.dart';
import 'screens/public_store_screen.dart';
import 'theme/app_theme.dart';

// This variable will be set by our build command.
const flavor = String.fromEnvironment('APP_FLAVOR');

// --- Manually define Firebase options for each site ---

// **IMPORTANT**: These are the settings for your ADMIN site.
const FirebaseOptions adminFirebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyCGcAI_s-RJhdZjsZ4mmbv2T1qyrjsuLMk",
  authDomain: "dauflop-admin.web.app", // Must be the main project's auth domain
  projectId: "dauflop-store",
  storageBucket: "dauflop-store.appspot.com",
  messagingSenderId: "80413761686",
  appId: "1:80413761686:web:34a29e332eb229fa3622b7", // Your admin web app's ID
);

// These are the settings for your PUBLIC site.
const FirebaseOptions publicFirebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyCGcAI_s-RJhdZjsZ4mmbv2T1qyrjsuLMk", // Often the same API key
  authDomain: "dauflop-store.firebaseapp.com",
  projectId: "dauflop-store",
  storageBucket: "dauflop-store.appspot.com",
  messagingSenderId: "80413761686",
  appId: "1:80413761686:web:c82bc51d872ad9d73622b7", // Your public web app's ID
);


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- UPDATED: Explicitly choose which options to use ---
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
