import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:garden_glossary/config/api_config.dart';
import 'package:garden_glossary/exceptions/exceptions.dart';
import 'package:garden_glossary/utils/logger.dart';
import 'package:garden_glossary/models/plant_details.dart';
import 'package:garden_glossary/services/mock_api_services.dart';

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
    AppLogger.info('[$requestId] Starting plant details request');
    
    // Use Mock API service if enabled
    if (_useMock) {
      AppLogger.info('[$requestId] Using mock details service');
      try {
        Map<String, dynamic> mockDetails = await MockDetailsService().fetchData();
        return PlantDetails.fromJson(mockDetails);
      } catch (e, stackTrace) {
        AppLogger.error('[$requestId] Mock details service failed', e , stackTrace);
        throw PlantServiceException('Failed to retrieve plant details: ${e.toString()}');
      }
    }

    // Otherwise use real API service
    try {
      // Cancel any previous request before making a new one
      cancelRequest();
 
      AppLogger.info('[$requestId] Sending POST request for "$plant" details to $_baseUrl/api/v1/$endpoint');
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
        AppLogger.info('[$requestId] $endpoint details JSON: ${response.data}');
        return PlantDetails.fromJson(response.data);
      }
      AppLogger.info('[$requestId] Failed to fetch details from $endpoint: ${response.data}');
      return null;

    } on DioException catch (e, stackTrace) {     
      AppLogger.error('[$requestId] Error fetching details from $endpoint: $e', e, stackTrace);
      return null;
    }
  }

  Future<PlantDetails?> getDetailsRhs(String plant) =>
    _fetchDetails('plant-details-rhs/', plant);

  Future<PlantDetails?> getDetailsLlm(String plant) =>
    _fetchDetails('plant-details-llm/', plant);

  void cancelRequest() {
    if (!_cancelToken.isCancelled) {
      AppLogger.debug('Cancelling active request.');
      _cancelToken.cancel('Request cancelled.');
      _cancelToken = CancelToken();
    }
  }
}

mixin PlantDetailsStateMixin<T extends StatefulWidget> on State<T> {
  bool _detailLoading = false;
  String _detailLoadingText = '';
  PlantDetails? plantDetails;
  String? source;

  bool get isLoading => _detailLoading;
  String get loadingText => _detailLoadingText;

  late final PlantDetailsService _detailsService;

  @override
  void initState() {
    super.initState();
    _detailsService = PlantDetailsService(dio: Dio()
      ..options.validateStatus = (status) {
        return status != null && status >=200 && status < 501;
      }
      );
  }

  @override
  void dispose() {
    _detailsService.cancelRequest();
    super.dispose();
  }
  
  Future<void> getDetails(String plant) async {
    if (!mounted) return;

    setState(() {
      plantDetails = null;
      source = null;
      _detailLoading = true;
      _detailLoadingText = 'Checking RHS for details...';
    });

    try {
      // Try RHS first
      AppLogger.info('Checking RHS for details...');
      final detailsRhs = await _detailsService.getDetailsRhs(plant);

      if (!mounted) return;

      if (detailsRhs != null) {
        setState(() {
          plantDetails = detailsRhs;
          source = 'RHS';
          _detailLoading = false;
        });
        return;
      }

      // Fallback to LLM
      AppLogger.info('Details not found on RHS.');
      setState(() {
        _detailLoadingText = 'Details not found on RHS.\nAsking Claude...';
      });

      final detailsLlm = await _detailsService.getDetailsLlm(plant);

      if (!mounted) return;

      if (detailsLlm != null) {
        setState(() {
          plantDetails = detailsLlm;
          source = 'Claude';
          _detailLoading = false;
        });
        return;
      }

      // Both services failed
      AppLogger.warning('Details not found from Claude');
      throw Exception('Unable to fetch details from either service');

    } catch (e) {
      AppLogger.error('Error retrieving details: $e');
      if (!mounted) return;

      setState(() {
        _detailLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error retrieving details: $e'))
      );
    }
  }
}

