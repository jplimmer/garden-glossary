import 'package:flutter_dotenv/flutter_dotenv.dart';

enum Environment {
  emulator,
  physical,
  production,
}

class ApiConfig {
  static final Map<Environment, String> _apiUrls = {
    Environment.emulator: 'http://10.0.2.2:8000',
    Environment.physical: dotenv.env['LOCAL_IP'] ?? 'http://10.0.2.2:8000',
  };

  static Environment _environment = Environment.physical;

  final String baseUrl;
  final Map<String, String> defaultHeaders;

  ApiConfig._({
    required this.baseUrl,
    this.defaultHeaders = const {'Content-Type': 'application/json'},
  });

  static ApiConfig get current => ApiConfig._(
    baseUrl: _apiUrls[_environment]!,
    defaultHeaders: const {'Content-Type': 'application/json'},
  );

  static void setEnvironment(Environment env) {
    _environment = env;
  }
}

