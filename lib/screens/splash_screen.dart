import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  StreamSubscription? _authSub;

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // 2-second splash screen preview
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      final user = AuthService().currentUser;
      if (user != null) {
        _navigateToHome();
      } else {
        _authSub = AuthService().authStateChanges.listen((user) {
          if (!mounted) return;
          if (user != null) {
            _navigateToHome();
          } else {
            _navigateToLogin();
          }
        }, onError: (err) {
          _navigateToLogin();
        });
      }
    } catch (e) {
      _navigateToLogin();
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo: Green Shield icon with checkmark
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              // App Title: "Farmer Dost" (22px Medium)
              const Text(
                "Farmer Dost",
                style: TextStyle(
                  color: Color(0xFF1A1C1E),
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              // Tagline: "Scan. Verify. Trust."
              const Text(
                "Scan. Verify. Trust.",
                style: TextStyle(
                  color: Color(0xFF74777F),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
