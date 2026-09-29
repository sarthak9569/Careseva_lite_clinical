import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/compounder_dashboard_screen.dart';
import 'services/clinic_store.dart';
import 'services/queue_store.dart';
import 'theme/clinical_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global exception handlers for production resilience
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[CareSeva Clinical Error] ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('[CareSeva Clinical Platform Error] $error\n$stack');
    return true;
  };

  // Graceful Firebase Initialization
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('[CareSeva Clinical] Firebase initialization notice: $e (Operating in hybrid/demo mode)');
  }

  // Custom UI Error Widget fallback
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return const Material(
      color: Color(0xFFF1F5F9),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 48),
              SizedBox(height: 12),
              Text(
                'Something went wrong',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              SizedBox(height: 6),
              Text(
                'An unexpected error occurred in the Clinical portal. Please try again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ),
    );
  };

  runApp(const CareSevaClinicalApp());
}

class CareSevaClinicalApp extends StatelessWidget {
  const CareSevaClinicalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ClinicStore()),
        ChangeNotifierProvider(create: (_) => QueueStore()),
      ],
      child: MaterialApp(
        title: 'CareSeva Clinical Portal',
        debugShowCheckedModeBanner: false,
        theme: ClinicalTheme.lightTheme,
        home: const CompounderDashboardScreen(),
      ),
    );
  }
}
