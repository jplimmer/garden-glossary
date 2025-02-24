import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:garden_glossary/config/api_config.dart';
import 'package:garden_glossary/models/plant_details.dart';

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
  
  String get baseUrl => ApiConfig.current.baseUrl;
  
  Future<PlantDetails?> _fetchDetails(String endpoint, String plant) async {
    try {
      // Cancel any previous request before making a new one
      cancelRequest();

      final response = await _dio.post(
        '$baseUrl/api/v1/$endpoint',
        options: Options(
          headers: ApiConfig.current.defaultHeaders,
        ),
        data: {'plant': plant},
        cancelToken: _cancelToken,
      );

      if (response.statusCode == 200) {
        debugPrint('$endpoint Details JSON: ${response.data}');
        return PlantDetails.fromJson(response.data);
      }
      return null;

    } catch (e) {
      debugPrint('Error fetching details from $endpoint: $e');
      return null;
    }
  }

  Future<PlantDetails?> getDetailsRhs(String plant) =>
    _fetchDetails('plant-details-rhs/', plant);

  Future<PlantDetails?> getDetailsLlm(String plant) =>
    _fetchDetails('plant-details-llm/', plant);

  void cancelRequest() {
    if (!_cancelToken.isCancelled) {
        _cancelToken.cancel('Request cancelled.');
        _cancelToken = CancelToken();
    }
  }
}

mixin PlantDetailsStateMixin<T extends StatefulWidget> on State<T> {
  bool _detailLoading = false;
  String _detailLoadingText = '';
  PlantDetails? plantDetails;

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
      _detailLoading = true;
      _detailLoadingText = 'Checking RHS for details...';
    });

    try {
      // Try RHS first
      final detailsRhs = await _detailsService.getDetailsRhs(plant);

      if (!mounted) return;

      if (detailsRhs != null) {
        setState(() {
          plantDetails = detailsRhs;
          _detailLoading = false;
        });
        return;
      }

      // Fallback to LLM
      setState(() {
        _detailLoadingText = 'Details not found on RHS.\nAsking Claude...';
      });

      final detailsLlm = await _detailsService.getDetailsLlm(plant);

      if (!mounted) return;

      if (detailsLlm != null) {
        setState(() {
          plantDetails = detailsLlm;
          _detailLoading = false;
        });
        return;
      }

      // Both services failed
      throw Exception('Unable to fetch details from either service');

    } catch (e) {
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