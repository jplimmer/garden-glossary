import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:garden_glossary/config/api_config.dart';
import 'package:garden_glossary/utils/logger.dart';
import 'package:garden_glossary/widgets/screens/home_page.dart';

// Common initialisation method for different flavours
Future<void> mainCommon(Environment environment) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    AppLogger.init(environment);
    AppLogger.info('App starting with environment "$environment"');
    
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    await ApiConfig.initialize(environment);

    runApp(MyApp(environment: environment));
  } catch (e) {
    AppLogger.error('Initialization error: $e');
    runApp(ErrorApp(error: e.toString()));
  }
}

class MyApp extends StatelessWidget {
  final Environment environment;
  const MyApp({
    super.key,
    required this.environment
  });

  @override
  Widget build(BuildContext context) {
    Color seedColor;
    String titleSuffix = '';

    // Configure UI based on environment
    switch (environment) {
      case Environment.prod:
        seedColor = Colors.green;
        break;
      case Environment.dev:
        seedColor = Colors.brown;
        titleSuffix = ' [DEV]';
        break;
      case Environment.mock:
        seedColor = Colors.deepPurple;
        titleSuffix = ' [MOCK]';
        break;
      default:
        seedColor = Colors.blueAccent;
        titleSuffix = ' [LOCAL]';
    }

    return MaterialApp(
      title: 'Garden Glossary$titleSuffix',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
    );
  }
}

// Fallback widget to show when initialisation fails
class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({
    super.key,
    required this.error
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'App Initialisation Failed',
                  style: TextStyle(fontSize: 24, fontWeight:  FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

