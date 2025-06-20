import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/login_screen.dart';
import '../screens/main_layout.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // A future that will complete once we know the initial auth state.
  late final Future<User?> _initialAuthCheck;

  @override
  void initState() {
    super.initState();
    _initialAuthCheck = _getInitialUser();
  }

  /// This function robustly checks for a user on app startup.
  Future<User?> _getInitialUser() async {
    // First, check if a user is already signed in from a previous session.
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      print("DEBUG: Found current user in session: ${currentUser.uid}");
      return currentUser;
    }

    // If no user, check if we are returning from a redirect.
    // This is the most important step for the redirect loop.
    try {
      final UserCredential? userCredential = await FirebaseAuth.instance.getRedirectResult();
      if (userCredential?.user != null) {
        print("DEBUG: Got user from redirect result: ${userCredential!.user!.uid}");
        return userCredential.user;
      }
    } catch (e) {
      print("DEBUG: Error checking redirect result: $e");
    }

    // If still no user, wait for the first result from the auth state stream.
    // This handles cases where the session is being restored but not immediately available.
    print("DEBUG: No user yet, waiting for the first authStateChanges event...");
    return await FirebaseAuth.instance.authStateChanges().first;
  }

  @override
  Widget build(BuildContext context) {
    // Use a FutureBuilder to wait for our initial user check to complete.
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
        // We start the stream with the data we just found from our initial check.
        return StreamBuilder<User?>(
          initialData: initialUserSnapshot.data,
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authStateSnapshot) {
            // If the stream has a user, they are logged in.
            if (authStateSnapshot.hasData) {
              print("DEBUG: Stream has data. Showing MainLayout.");
              return const MainLayout();
            } 
            // Otherwise, they are logged out.
            else {
              print("DEBUG: Stream has no data. Showing LoginScreen.");
              return const LoginScreen();
            }
          },
        );
      },
    );
  }
}
