import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum Environment {
  local,
  dev,
  prod,
  mock,
}

class ApiConfig {
  // Private constructor
  ApiConfig._({
    required this.environment,
    required this.baseUrl,
    required this.defaultHeaders,
    int? customPayloadLimit,
  }) : payloadLimit = customPayloadLimit ??
        int.tryParse(dotenv.env['PAYLOAD_LIMIT_KB'] ?? '') ??
        _defaultPayloadLimit;

  // Singleton instance
  static ApiConfig? _instance;

  // Environment and configuration values
  final Environment environment;
  final String baseUrl;
  final Map<String, String> defaultHeaders;
  final int payloadLimit;

  // Constants
  static const int _defaultPayloadLimit = 5000;

  // Getters
  bool get isProduction => environment == Environment.prod;
  bool get useMockAPI => environment == Environment.mock;

  // Factory constructor that returns singelton instance
  factory ApiConfig.getInstance() {
    if (_instance == null) {
      throw StateError('ApiConfig not initialized. Call ApiConfig.initialize() first.');
    }
    return _instance!;
  }
  
  // Initalise the configuration for a specific environment
  static Future<void> initialize(Environment env) async {
    // Load .env file based on environment
    String envFileName;
    switch (env) {
      case Environment.local:
        envFileName = '.env.local';
        break;
      case Environment.dev:
        envFileName = '.env.dev';
        break;
      case Environment.prod:
        envFileName = '.env.prod';
        break;
      case Environment.mock:
        envFileName = '.env.mock';
        break;
    }

    // Load environment variables
    try {
      await dotenv.load(fileName: envFileName);
    } catch (e) {
      if (kReleaseMode) {
        // In release mode, try fallback to default .env file
        try {
          await dotenv.load(fileName: '.env');
        } catch (fallbackError) {
          throw Exception('Failed to load environment configuration: $fallbackError');
        }
      } else {
        rethrow;
      }
    }

    // Create configuration instance
    _instance = ApiConfig._(
      environment: env,
      baseUrl: _getBaseUrl(env),
      defaultHeaders: _getDefaultHeaders(env),
    );
  }

  static String _getBaseUrl(Environment env) {
    const configKey = 'API_URL';
    final url = dotenv.env[configKey];

    if (url == null || url.isEmpty) {
      switch (env) {
        case Environment.local:
          return 'http://10.0.2.2:8000';
        case Environment.mock:
          return 'mock://api.example.com';
        default:
          throw Exception('Missing or invalid $configKey environment variable');
      }
    }

    return url;
  }

  static Map<String, String> _getDefaultHeaders(Environment env) {
    return {
      'Content-Type': 'application/json',
      'X-Api-Version': dotenv.env['API_VERSION'] ?? '1.0',
      'X-App-Environment': env.toString().split('.').last,
    };
  }

  // Reset instance (for testing)
  @visibleForTesting
  static void reset() {
    _instance = null;
  }
}

