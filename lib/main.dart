import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Day 41: Lock orientation strictly to portrait for agricultural outdoor field stability
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase with configured options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // [Day 27 Emulator Support] Toggle with flutter run --dart-define=USE_FIREBASE_EMULATOR=true
    if (kDebugMode && const bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false)) {
      FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
      await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
      debugPrint('[Firebase] Connected to local Emulators (Firestore: 8080, Auth: 9099)');
    }
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
      themeMode: ThemeMode.light,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
