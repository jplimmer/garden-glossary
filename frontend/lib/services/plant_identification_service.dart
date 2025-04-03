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
    // Use Mock API service if enabled
    if (_useMock) {
      Map<String, dynamic> mockMatches = await MockIdentificationService().fetchData();
      return _parseMatchOptions(mockMatches);
    }
    
    // Otherwise use real API service
    try {
      late File postImage;

      // Cancel any previous request before making a new one
      cancelRequest();

      // Check image size & compress image if needed
      int imageFileSize = await imageFile.length();      
      double scaleFactor = ApiConfig.getInstance().payloadLimit / (imageFileSize / 1024);
      AppLogger.info('Payload limit is $scaleFactor x image size');

      if (scaleFactor < 1) {
        scaleFactor = (scaleFactor * 100).floorToDouble() / 100;
        postImage = await compressImage(imageFile, scaleFactor);
      } else {
        postImage = imageFile;
      }

      AppLogger.debug('File type: ${lookupMimeType(postImage.path)}');
      
      // Create POST request
      var formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          postImage.path,
          filename: postImage.path.split('/').last
        ),
        'organ': organ,
      });

      AppLogger.info('Connecting to $_baseUrl ...');
      var response = await _dio.post(
        '$_baseUrl/api/v1/identify-plant/',
        options: Options(
          headers: ApiConfig.getInstance().defaultHeaders,
        ),
        data: formData,
        cancelToken: _cancelToken,
      );

      if (postImage.path != imageFile.path) {
        cleanupTempFiles(postImage);
      }

      AppLogger.debug('identify-plant response code: ${response.statusCode}');
      AppLogger.debug('identify-plant response: $response');
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
          AppLogger.error('Server error (case): ${response.statusMessage}');
          throw PlantIdentificationException('Server error: ${response.data}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        AppLogger.error('Server error (Dio): ${e.message}');
        throw PlantIdentificationException('Server error: ${e.response?.data}');
      }
      AppLogger.error('Error uploading image: ${e.message}');
      throw PlantIdentificationException('Error uploading image: ${e.message}');
    }
  }
 
  Future<File> compressImage(File file, double scaleFactor) async {
    try {
      final dir = Directory.systemTemp;
      final targetPath = '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

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

      return File(compressedFile.path);
    } catch (e) {
      AppLogger.error('Image compression error: $e');
      return file;
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
      _cancelToken.cancel('Request cancelled.');
      _cancelToken = CancelToken();
    }
  }
}

