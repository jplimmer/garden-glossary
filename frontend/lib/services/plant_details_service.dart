import 'package:dio/dio.dart';
import 'package:garden_glossary/config/api_config.dart';
import 'package:garden_glossary/exceptions/exceptions.dart';
import 'package:garden_glossary/utils/logger.dart';
import 'package:garden_glossary/models/plant_details.dart';
import 'package:garden_glossary/services/mock_api_services.dart';

final _logger = AppLogger.getLogger('PlantDetailsService');

class PlantDetailsService {
  final Dio _dio;
  CancelToken _cancelToken = CancelToken();

  PlantDetailsService({
    Dio? dio,
  }) : _dio = dio ?? _createConfiguredDio();

  static Dio _createConfiguredDio() {
    return Dio()
      ..options.validateStatus = (status) {
      return status != null && status >= 200 && status < 501;
    };
  }
  
  String get _baseUrl => ApiConfig.getInstance().baseUrl;
  bool get _useMock => ApiConfig.getInstance().useMockAPI;
  
  Future<PlantDetails?> _fetchDetails(String endpoint, String plant) async {
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    _logger.info('[$requestId] Starting plant details request');
    
    // Use Mock API service if enabled
    if (_useMock) {
      _logger.info('[$requestId] Using mock details service');
      try {
        Map<String, dynamic> mockDetails = await MockDetailsService().fetchData();
        return PlantDetails.fromJson(mockDetails);
      } catch (e, stackTrace) {
        _logger.error('[$requestId] Mock details service failed', e , stackTrace);
        throw PlantDetailsException('Failed to retrieve plant details: ${e.toString()}');
      }
    }

    // Otherwise use real API service
    try {
      // Cancel any previous request before making a new one
      cancelRequest();
 
      _logger.info('[$requestId] Sending POST request for "$plant" details to $_baseUrl/api/v1/$endpoint');
      final response = await _dio.post(
        '$_baseUrl/api/v1/$endpoint',
        options: Options(
          headers: ApiConfig.getInstance().defaultHeaders,
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 30),
        ),
        data: {'plant': plant},
        cancelToken: _cancelToken,
      );

      int statusCode = response.statusCode ?? 0;
      if (statusCode == 200) {
        _logger.info('[$requestId] $endpoint details JSON: ${response.data}');
        return PlantDetails.fromJson(response.data);
      }
      _logger.info('[$requestId] Failed to fetch details from $endpoint: ${response.data}');
      return null;

    } on DioException catch (e, stackTrace) {     
      _logger.error('[$requestId] Error fetching details from $endpoint: $e', e, stackTrace);
      return null;
    }
  }

  Future<PlantDetails?> getDetailsRhs(String plant) =>
    _fetchDetails('plant-details-rhs/', plant);

  Future<PlantDetails?> getDetailsLlm(String plant) =>
    _fetchDetails('plant-details-llm/', plant);
   
  void cancelRequest() {
    if (!_cancelToken.isCancelled) {
      _logger.debug('Cancelling active request.');
      _cancelToken.cancel('Request cancelled by user.');
      _cancelToken = CancelToken();
    }
  }
}

