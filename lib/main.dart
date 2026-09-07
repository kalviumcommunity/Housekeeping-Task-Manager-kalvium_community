import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'screens/shared/firebase_setup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? initError;
  bool isInitialized = false;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    isInitialized = true;
  } catch (e) {
    initError = e.toString();
  }

  runApp(WardCleanBootstrap(
    initialError: initError,
    isInitialized: isInitialized,
  ));
}

/// Bootstraps the application. If Firebase is already configured, launches
/// the core [WardCleanApp]. If configuration is pending, displays a helpful
/// setup guide with retry capability (PRD §65).
class WardCleanBootstrap extends StatefulWidget {
  final String? initialError;
  final bool isInitialized;

  const WardCleanBootstrap({
    super.key,
    this.initialError,
    required this.isInitialized,
  });

  @override
  State<WardCleanBootstrap> createState() => _WardCleanBootstrapState();
}

class _WardCleanBootstrapState extends State<WardCleanBootstrap> {
  late bool _initialized;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialized = widget.isInitialized;
    _error = widget.initialError;
  }

  Future<void> _retry() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      setState(() {
        _initialized = true;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _initialized = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initialized) {
      return const WardCleanApp();
    }
    return MaterialApp(
      title: 'WardClean',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: FirebaseSetupScreen(
        errorMessage: _error,
        onRetry: _retry,
      ),
    );
  }
}
