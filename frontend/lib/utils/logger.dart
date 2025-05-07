import 'package:flutter/foundation.dart';
import 'package:garden_glossary/config/api_config.dart';
import 'package:logging/logging.dart';

class AppLogger {
  static final Map<String, Logger> _loggers = {};
  static bool _initialized = false;
  static const Environment _defaultEnvironment = Environment.dev;

  /// Gets or creates a named logger for a specific class/file
  ///
  /// Example: 
  /// ```dart
  /// final _logger = AppLogger.getLogger('UserRepository');
  /// _logger.info('User data fetched');
  /// ```
  static Logger getLogger(String name) {
    // Creates logger with default environment if environment not yet initialised
    return _loggers.putIfAbsent(name, () => Logger(name));
  }
  
  /// Initialises the logging system based on environment
  static void init(Environment environment) {
    if (_initialized && environment == _defaultEnvironment) return;

    // Set up logging level based on environment
    switch(environment) {
      case Environment.prod:
        Logger.root.level = Level.WARNING;
        break;
      case Environment.dev:
        Logger.root.level = Level.FINE;
        break;
      case Environment.local:
      case Environment.mock:
        Logger.root.level = Level.ALL;
        break;
    }

    // Configure logging output
    Logger.root.onRecord.listen((record) {
      // Include source name in the log output
      final loggerName = record.loggerName;
      
      // In debug mode, debugPrint to console
      if (!kReleaseMode) {
        debugPrint('${record.time}: $loggerName: ${record.level.name}: ${record.message}');
        if (record.error != null) {
          debugPrint('Error: ${record.error}');
        }
        if (record.stackTrace != null) {
          debugPrint('Stack trace: ${record.stackTrace}');
        }
      } else if (record.level >= Level.WARNING) {
        // In release mode, only debugPrint warnings and errors
        debugPrint('${record.time}: $loggerName: ${record.level.name}: ${record.message}');
      }
    });

    _initialized = true;

    final systemLogger = getLogger('AppLogger');
    systemLogger.info('Logging system initialised with environment "$environment"');
  }
}

// Extension methods for easier logging with named loggers
extension LoggerExtensions on Logger {
  /// Logs a verbose message (maps to fine level)
  void verbose(String message) {
    fine(message);
  }
  /// Logs a debug message (maps to fine level)
  void debug(String message) {
    fine(message);
  }
  /// Logs and info message
  void info(String message) {
    info(message);
  }
  /// Logs a warning message with optional error object and stack trace
  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    warning(message, error, stackTrace);
  }
  /// Logs an error message with optional error object and stack trace
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    severe(message, error, stackTrace);
  }
}

