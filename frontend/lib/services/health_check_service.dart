import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:garden_glossary/config/api_config.dart';

class HealthCheckService {
  String get _baseUrl => ApiConfig.current.baseUrl;

  Future<bool> checkHealth() async {  
    try {
      final response = await http.get(Uri.parse('$_baseUrl/health'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'healthy';
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

