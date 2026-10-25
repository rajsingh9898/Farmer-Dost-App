import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
// import 'services/firestore_verifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with fallback error handling
  try {
    await Firebase.initializeApp();
    // [Day 16 Verification] Uncomment the line below to run the console verification checks on launch:
    // await runDay16FirestoreVerification();
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }

  runApp(const FarmerDostApp());
}

class FarmerDostApp extends StatelessWidget {
  const FarmerDostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farmer Dost App',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const SplashScreen(),
    );
  }
}
