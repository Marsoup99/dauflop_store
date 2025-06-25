import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // Import this for kDebugMode
import '../screens/login_screen.dart';
import '../screens/main_layout.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // A future that will complete once we know the initial auth state for RELEASE mode.
  late final Future<User?> _initialAuthCheck;

  @override
  void initState() {
    super.initState();
    // This check is only needed for release mode now.
    if (!kDebugMode) {
      _initialAuthCheck = _getInitialUser();
    }
  }

  /// This function robustly checks for a user on app startup in RELEASE mode.
  Future<User?> _getInitialUser() async {
    // First, check if a user is already signed in from a previous session.
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      print("RELEASE: Found current user in session: ${currentUser.uid}");
      return currentUser;
    }

    // If no user, check if we are returning from a redirect.
    try {
      final UserCredential? userCredential = await FirebaseAuth.instance.getRedirectResult();
      if (userCredential?.user != null) {
        print("RELEASE: Got user from redirect result: ${userCredential!.user!.uid}");
        return userCredential.user;
      }
    } catch (e) {
      print("RELEASE: Error checking redirect result: $e");
    }

    // If still no user, wait for the first result from the auth state stream.
    print("RELEASE: No user yet, waiting for the first authStateChanges event...");
    return await FirebaseAuth.instance.authStateChanges().first;
  }

  /// --- NEW: A dedicated sign-in function for DEBUG mode ---
  /// This ensures we have a valid (anonymous) user for the debug session.
  Future<User?> _signInForDebug() async {
    // If a user already exists (e.g., from a hot restart), just return it.
    if (FirebaseAuth.instance.currentUser != null) {
      return FirebaseAuth.instance.currentUser;
    }
    // Otherwise, sign in anonymously.
    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      print("DEBUG: Signed in anonymously for debug session: ${userCredential.user?.uid}");
      return userCredential.user;
    } catch (e) {
      print("DEBUG: Anonymous sign-in for debug failed: $e");
      // Return null to indicate failure, which we can handle in the UI.
      return null;
    }
  }


  @override
  Widget build(BuildContext context) {
    // --- UPDATED LOGIC: Handle debug mode separately and robustly ---
    if (kDebugMode) {
      print("DEBUG: In debug mode, ensuring an anonymous user session exists.");
      // Use a FutureBuilder to handle the anonymous sign-in for the debug session.
      return FutureBuilder<User?>(
        future: _signInForDebug(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          // If we have a user, we can proceed.
          if (snapshot.hasData && snapshot.data != null) {
            return const MainLayout();
          }
          // If sign-in failed, show an error message.
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Failed to sign in for debug mode. Please check your Firebase setup (API key restrictions) and network connection.\n\nError: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          );
        },
      );
    }
    // --- END UPDATED LOGIC ---

    // The original logic below will now only run for profile or release builds.
    return FutureBuilder<User?>(
      future: _initialAuthCheck,
      builder: (context, initialUserSnapshot) {
        // While we wait for the initial user check, show a loading spinner.
        if (initialUserSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Now that the initial check is done, we can rely on the real-time stream.
        return StreamBuilder<User?>(
          initialData: initialUserSnapshot.data,
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authStateSnapshot) {
            // If the stream has a user, they are logged in.
            if (authStateSnapshot.hasData) {
              print("RELEASE: Stream has data. Showing MainLayout.");
              return const MainLayout();
            }
            // Otherwise, they are logged out.
            else {
              print("RELEASE: Stream has no data. Showing LoginScreen.");
              return const LoginScreen();
            }
          },
        );
      },
    );
  }
}
