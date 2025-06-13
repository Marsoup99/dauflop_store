import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'firebase_options.dart';
import 'localizations/app_localizations.dart';
import 'screens/main_layout.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
      title: 'DauFlop Store',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const MainLayout(),
      // --- UPDATED: Localization Setup ---
      supportedLocales: const [
        Locale('vi', 'VN'), // Vietnamese
        // Locale('en', 'US'), // English (can be added later)
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate, // Your custom translations
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        MonthYearPickerLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        // Choose the first supported locale if the device locale is not supported
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

