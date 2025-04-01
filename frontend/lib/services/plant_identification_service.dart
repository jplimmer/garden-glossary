import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:mime/mime.dart';
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

      late File postImage;
      // Compress image
      final compressedImage = await compressImage(imageFile);

      if (compressedImage != null) {
        postImage = File(compressedImage.path);
      } else {
        postImage = imageFile;
      }

      debugPrint(imageFile.path);
      debugPrint(postImage.path);
      debugPrint('${lookupMimeType(postImage.path)}');
      
      // Create POST request
      var formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          postImage.path,
          filename: postImage.path.split('/').last
        ),
        'organ': organ,
      });

      var payloadSize = _checkPayloadSize(formData);
      debugPrint('Payload size: ${payloadSize.toStringAsFixed(2)} KB');

      var contentLength = formData.length;
      debugPrint('Dio payload size: $contentLength bytes (${(contentLength/1024).toStringAsFixed(2)} KB)');

      debugPrint(_baseUrl);
      var response = await _dio.post(
        '$_baseUrl/api/v1/identify-plant/',
        options: Options(
          headers: ApiConfig.current.defaultHeaders,
        ),
        data: formData,
        cancelToken: _cancelToken,
      );

      debugPrint('identify-plant response code: ${response.statusCode}');
      debugPrint('identify-plant response: $response');
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
          debugPrint('Server error (case): ${response.statusMessage}');
          throw PlantIdentificationException('Server error: ${response.data}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        debugPrint('Server error (Dio): ${e.message}');
        throw PlantIdentificationException('Server error: ${e.response?.data}');
      }
      throw PlantIdentificationException('Error uploading image: ${e.message}');
    }
  }
 
  Future<XFile?> compressImage(File file) async {
    try {
      final dir = Directory.systemTemp;
      final targetPath = '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 80,
        format: CompressFormat.jpeg
      );

      if (compressedFile != null) {
          final bytes = await compressedFile.readAsBytes();
          final image = await decodeImageFromList(bytes);

          debugPrint('Compressed image -');
          debugPrint('Path: ${compressedFile.path}');
          debugPrint('Size: ${bytes.length} bytes');
          debugPrint('Dimensions: ${image.width}x${image.height}');
      }
      return compressedFile;
    } catch (e) {
      debugPrint('Image compression error: $e');
      return null;
    }
  }
  
  double _checkPayloadSize(FormData formData) {
    int totalSize = 0;
    
    for (var file in formData.files) {
      totalSize += file.value.length;
    }

    for (var field in formData.fields) {
      totalSize += field.key.length + field.value.length;
    }

    return totalSize / 1024;
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

