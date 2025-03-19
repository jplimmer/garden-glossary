import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:garden_glossary/config/api_config.dart';
import 'package:garden_glossary/models/id_match.dart';
import 'package:garden_glossary/exceptions/exceptions.dart';
import 'package:garden_glossary/services/mock_api_services.dart';

class PlantIdentificationService {
  final Dio _dio;
  CancelToken _cancelToken = CancelToken();

  PlantIdentificationService({
    Dio? dio,
  }) : _dio = dio ?? _createConfiguredDio();

  static Dio _createConfiguredDio() {
    return Dio()
      ..options.validateStatus = (status) {
      return status != null && status >= 200 && status < 501;
    };
  }
  
  String get _baseUrl => ApiConfig.current.baseUrl;

  Future<List<IDMatch>> identifyPlant({
    required File imageFile,
    required String organ,
    required BuildContext context,
  }) async {
    // Use Mock API service if enabled
    if (ApiConfig.current.useMockAPI) {
      Map<String, dynamic> mockMatches = await MockIdentificationService().fetchData();
      return _parseMatchOptions(mockMatches);
    }
    
    // Otherwise use real API service
    try {
      // Cancel any previous request before making a new one
      cancelRequest();

      var formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last
        ),
        'organ': organ,
      });

      debugPrint(_baseUrl);
      var response = await _dio.post(
        '$_baseUrl/api/v1/identify-plant/',
        options: Options(
          headers: ApiConfig.current.defaultHeaders,
        ),
        data: formData,
        cancelToken: _cancelToken,
      );

      switch(response.statusCode) {
        case 200:
          return _parseMatchOptions(response.data);
        case 404:
          // Handle 'Species Not Found'
          throw const PlantIdentificationException(
            'Species not found - try uploading another photo or changing the selected organ.'
          );
        case 429:
          // Handle 'Too Many Requests'
          throw const PlantIdentificationException(
            'Too many requests at PlantNet - try waiting a few minutes.'
          );
        default:
          // Handle unexpected status
          throw const PlantIdentificationException(
            'PlantNet error - check PlantNet is running properly.'
          );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw PlantIdentificationException('Server error: ${e.response?.data}');
      }
      throw PlantIdentificationException('Error uploading image: ${e.message}');
    }
  }

  List<IDMatch> _parseMatchOptions(Map<String, dynamic> responseBody) {
    List<IDMatch> matchOptionsList = [];
    responseBody['matches'].forEach((key, value) {
      String commonNamesString = (value['commonNames'] as List<dynamic>).join(', ');
      List<String> imageUrlsList = (value['imageUrls'] as List<dynamic>).map((url) => url as String).toList();
      matchOptionsList.add(
        IDMatch(
          species: value['species'],
          score: value['score'],
          commonNames: commonNamesString,
          imageUrls: imageUrlsList,
        )
      );
    });
    return matchOptionsList;
  }

  void cancelRequest() {
    if (!_cancelToken.isCancelled) {
      _cancelToken.cancel('Request cancelled.');
      _cancelToken = CancelToken();
    }
  }
}

