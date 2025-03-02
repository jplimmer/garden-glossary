import 'package:flutter_dotenv/flutter_dotenv.dart';

enum Environment {
  local,
  container,
  production,
}

class ApiConfig {
  static final Map<Environment, String> _apiUrls = {
    Environment.local: dotenv.env['LOCAL_IP'] ?? 'http://10.0.2.2:8000',
    Environment.container: 'http://127.0.0.1:8000',
    Environment.production: _getProductionUrl(),
  };

  static String _getProductionUrl() {
    final url = dotenv.env['PROD_IP'];
    if (url == null || url.isEmpty) {
      throw Exception("Missing or invalid PROD_IP environment variable.");
    }
    return url;
  }

  static Environment _environment = Environment.local;

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

