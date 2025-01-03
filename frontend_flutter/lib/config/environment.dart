import 'package:flutter_dotenv/flutter_dotenv.dart';

enum Environment {
  emulator,
  physical,
  production,
}

class Config {
  static Map<Environment, String> apiUrls = {
    Environment.emulator: 'http://10.0.2.2:8000',
    Environment.physical: dotenv.env['LOCAL_IP'] ?? 'http://10.0.2.2:8000',
  };

  static Environment environment = Environment.physical;
  static String get apiUrl => apiUrls[environment]!;

  static void setEnvironment(Environment env) {
    environment = env;
  }
}