import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../localizations/app_localizations.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      await FirebaseAuth.instance.signInWithRedirect(googleProvider);

    } catch (e) {
      print("Google Sign-In failed: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Đã có lỗi xảy ra khi đăng nhập. Vui lòng thử lại.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightPinkBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            // --- CHANGE HERE: Changed from stretch to center ---
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/images/my_logo.png', height: 120),
              
              const SizedBox(height: 20),
              const Text(
                'Chào mừng đến với\nDauFlop Store',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: AppTheme.darkText,
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min, // Make row only as wide as its children
                        children: [
                           // Assumes you have a google logo asset
                           Image.asset('assets/images/google_logo.png', height: 22.0),
                           const SizedBox(width: 12),
                           const Text('Đăng nhập với Google'),
                        ],
                      ),
                    ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
