import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
// import 'services/firestore_verifier.dart';
// import 'services/auth_verifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with configured options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // [Day 16 Verification] Uncomment to run the Firestore console structure checks:
    // await runDay16FirestoreVerification();
    // [Day 17 Verification] Uncomment to run Auth sign-in, UID, and users/{uid} checks:
    // await runDay17AuthVerification();
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
