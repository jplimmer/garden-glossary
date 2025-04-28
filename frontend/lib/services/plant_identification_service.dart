import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:mime/mime.dart';
import 'package:dio/dio.dart';

import 'package:garden_glossary/config/api_config.dart';
import 'package:garden_glossary/utils/logger.dart';
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
  
  String get _baseUrl => ApiConfig.getInstance().baseUrl;
  bool get _useMock => ApiConfig.getInstance().useMockAPI;

  Future<List<IDMatch>> identifyPlant({
    required File imageFile,
    required String organ,
    required BuildContext context,
  }) async {
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    AppLogger.info('[$requestId] Starting plant identification with organ: $organ');

    // Use Mock API service if enabled
    if (_useMock) {
      AppLogger.info('[$requestId] Using mock identification service');
      try {
        Map<String, dynamic> mockMatches = await MockIdentificationService().fetchData();
        final results = _parseMatchOptions(mockMatches);
        AppLogger.info('[$requestId] Identified ${results.length} potential matches');
        return results;
      } catch (e, stackTrace) {
        AppLogger.error('[$requestId] Mock identification failed', e, stackTrace);
        throw PlantServiceException('Failed to identify plant: ${e.toString()}');
      }
    }
    
    // Cancel any previous request before making a new one
    cancelRequest();
    AppLogger.debug('[$requestId] Cancelled previous requests');

    // Check file exists
    if (!imageFile.existsSync()) {
      AppLogger.error('[$requestId] Image file does not exist: ${imageFile.path}');
      throw const PlantServiceException('Image file not found');
    }

    File? postImage;
    try {
      // Check image size & compress image if needed
      int imageFileSize = await imageFile.length();
      AppLogger.debug('[$requestId] Original image size: ${imageFileSize / 1024} KB');

      int payloadLimit = ApiConfig.getInstance().payloadLimit;
      double scaleFactor = payloadLimit / (imageFileSize / 1024);
      AppLogger.info('[$requestId] Payload limit of $payloadLimit KB is $scaleFactor * image size');

      postImage = imageFile;
      if (scaleFactor < 1) {
        scaleFactor = (scaleFactor * 100).floorToDouble() / 100;
        AppLogger.info('[$requestId] Compressing image by factor: $scaleFactor');
        postImage = await compressImage(imageFile, scaleFactor);

        // Log compression results
        int compressedSize = await postImage.length();
        AppLogger.debug('[$requestId] Compressed image size: ${compressedSize / 1024} KB');
      }

      String? mimeType = lookupMimeType(postImage.path);
      AppLogger.debug('[$requestId] Uploading file: ${postImage.path}, MIME: $mimeType');
      
      // Create and send POST request
      var formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          postImage.path,
          filename: postImage.path.split('/').last
        ),
        'organ': organ,
      });

      AppLogger.info('[$requestId] Sending POST request to $_baseUrl/api/v1/identify-plant/');
      var response = await _dio.post(
        '$_baseUrl/api/v1/identify-plant/',
        options: Options(
          headers: ApiConfig.getInstance().defaultHeaders,
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
        ),
        data: formData,
        cancelToken: _cancelToken,
      );

      // Clean up temporary files
      if (postImage.path != imageFile.path) {
        cleanupTempFiles(postImage);
      }

      // Process response
      int statusCode = response.statusCode ?? 0;     
      AppLogger.debug('[$requestId] Response Status: $statusCode');

      switch(statusCode) {
        case 200:
          final results = _parseMatchOptions(response.data);
          AppLogger.info('[$requestId] Identified ${results.length} potential matches');
          return results;
        case 404:
          // Handle 'Species Not Found'
          AppLogger.warning('[$requestId] Species not found (404)');
          throw const PlantServiceException(
            'Species not found - try uploading another photo or changing the selected organ.'
          );
        case 429:
          // Handle 'Too Many Requests'
          AppLogger.warning('[$requestId] Rate limit exceeded (429)');
          throw const PlantServiceException(
            'Too many requests at PlantNet - try waiting a few minutes.'
          );
        default:
          // Handle unexpected status
          AppLogger.error('[$requestId] Unexpected response: $statusCode - ${response.data}');
          throw PlantServiceException('Server error: ${response.statusMessage}');
      }
    } on DioException catch (e, stackTrace) {
      if (postImage != null && postImage.path != imageFile.path) {
        cleanupTempFiles(postImage);
      }

      if (e.response != null) {
        AppLogger.error(
          '[$requestId] API error: ${e.response?.statusCode} - ${e.message}',
          e,
          stackTrace
        );
        throw PlantServiceException('Server error: ${e.message}');
      }

      AppLogger.error('[$requestId] Network error: ${e.message}', e, stackTrace);
      throw PlantServiceException('Error uploading image: ${e.message}');
    }
  }
 
  Future<File> compressImage(File file, double scaleFactor) async {
    try {
      final dir = Directory.systemTemp;
      final targetPath = '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      AppLogger.info('Attempting to compress file...');
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: (scaleFactor * 100).toInt(),
        format: CompressFormat.jpeg
      );

      if (compressedFile == null) {
        AppLogger.warning('Compression returned null, using original file');
        return file;
      }

      AppLogger.info('File compressed.');
      return File(compressedFile.path);
    } catch (e) {
      AppLogger.warning('Image compression error: $e');
      AppLogger.warning('Returning original file after compression failure');
      return file;
    }
  }
  
  List<IDMatch> _parseMatchOptions(Map<String, dynamic> responseBody) {
    if (!responseBody.containsKey('matches')) {
      AppLogger.error('Response missing "matches" field: $responseBody');
      throw const PlantServiceException('Invalid server response format');
    }
    
    AppLogger.debug('Parsing match options...');
    List<IDMatch> matchOptionsList = [];
    try {
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
    } catch (e, stackTrace) {
      AppLogger.error('Error parsing match options', e, stackTrace);
      throw const PlantServiceException('Invalid response received from PlantNet');
    }
  }

  void cleanupTempFiles(File file) {
    if (file.path.contains('compressed_') && file.existsSync()) {
      try {
        file.deleteSync();
        AppLogger.debug('Deleted temporary file: ${file.path}');
      } catch (e) {
        AppLogger.error('Error deleting temporary file: $e');
      }
    }
  }
  
  void cancelRequest() {
    if (!_cancelToken.isCancelled) {
      AppLogger.debug('Cancelling active request.');
      _cancelToken.cancel('Request cancelled by user.');
      _cancelToken = CancelToken();
    }
  }
}

