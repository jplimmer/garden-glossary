import 'package:flutter/foundation.dart';
import 'package:garden_glossary/config/api_config.dart';
import 'package:logging/logging.dart';

class AppLogger {
  static final Logger _logger = Logger('AppLogger');
  static bool _initialized = false;

  // Initialise logger based on environment
  static void init(Environment environment) {
    if (_initialized) return;

    // Set up logging level based on environment
    switch(environment) {
      case Environment.prod:
        Logger.root.level = Level.WARNING;
        break;
      case Environment.dev:
        Logger.root.level = Level.INFO;
        break;
      case Environment.local:
      case Environment.mock:
        Logger.root.level = Level.ALL;
        break;
    }

    // Configure logging output
    Logger.root.onRecord.listen((record) {
      // In debug mode, debugPrint to console
      if (!kReleaseMode) {
        debugPrint('${record.level.name}: ${record.time}: ${record.message}');
        if (record.error != null) {
          debugPrint('Error: ${record.error}');
        }
        if (record.stackTrace != null) {
          debugPrint('Stack trace: ${record.stackTrace}');
        }
      } else if (record.level >= Level.WARNING) {
        // In release mode, only debugPrint warnings and errors
        debugPrint('${record.level.name}: ${record.message}');
      }
    });

    _initialized = true;
  }

  // Logging methods
  static void verbose(String message) {
    _logger.fine(message);
  }

  static void debug(String message) {
    _logger.fine(message);
  }

  static void info(String message) {
    _logger.info(message);
  }

  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.warning(message, error, stackTrace);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.severe(message, error, stackTrace);
  }
}

