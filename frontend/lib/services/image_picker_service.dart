import 'dart:io';
import 'package:garden_glossary/utils/logger.dart';
import 'package:image_picker/image_picker.dart';

final _logger = AppLogger.getLogger('ImagePickerService');

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> takePhoto() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        _logger.debug('Image taken by camera: ${pickedFile.path}');
        return File(pickedFile.path);
      }
      _logger.debug('No image taken by camera.');
      return null;
    } catch (e) {
      _logger.error('Error taking photo with camera: $e');
      return null;
    }
  }

  Future<File?> pickFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        _logger.debug('Image selected from gallery: ${pickedFile.path}');
        return File(pickedFile.path);
      }
      _logger.debug('No image selected from gallery.');
      return null;
    } catch (e) {
      _logger.error('Error selecting photo from gallery: $e');      
      return null;
    }
  }
}

