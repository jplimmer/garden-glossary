import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:garden_glossary/config/api_config.dart';
import 'package:garden_glossary/utils/logger.dart';

final _logger = AppLogger.getLogger('HealthCheckService');

class HealthCheckService {
  String get _baseUrl => ApiConfig.getInstance().baseUrl;
  bool get _useMock => ApiConfig.getInstance().useMockAPI;

  Future<bool> checkHealth() async {  
    if (_useMock) {
      _logger.info('Mock health check: healthy');
      return true;
    }
    
    try {
      final response = await http
        .get(Uri.parse('$_baseUrl/health'))
        .timeout(const Duration(seconds: 7));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.info('Health check response: $data');
        return data['status'] == 'healthy';
      }
      return false;
    } on TimeoutException catch (_) {
      _logger.warning('Health check timed out');
      return false;
    } on SocketException catch (_) {
      _logger.warning('No internet connection');
      return false;
    } catch (e) {
      return false;
    }
  }
}

