import 'dart:io';
// import 'package:path/path.dart' as path;
// import 'package:mime/mime.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garden_glossary/models/image_source.dart';
import 'package:garden_glossary/services/image_picker_service.dart';
import 'package:garden_glossary/providers/settings_provider.dart';
import 'package:garden_glossary/utils/logger.dart';

final _logger = AppLogger.getLogger('ImageProvider');

/// Data class for the image state
class ImageState {
  final File? image;
  final ImageSource? source;
  final bool isProcessing;
  final String? errorMessage;

  const ImageState({
    this.image,
    this.source,
    this.isProcessing = false,
    this.errorMessage,
  });

  /// Create a copy of this state with some fields replaced
  ImageState copyWith({
    File? image,
    ImageSource? source,
    bool? isProcessing,
    String? errorMessage,
  }) {
    return ImageState(
      image: image ?? this.image,
      source: source ?? this.source,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Create a reset state
  ImageState reset() {
    return const ImageState();
  }
}

/// Provider for the ImagePickerService
final imagePickerServiceProvider = Provider<ImagePickerService>((ref) {
  return ImagePickerService();
});

/// StateNotifier for image handling
class ImageNotifier extends StateNotifier<ImageState> {
  final ImagePickerService _imagePickerService;
  final Ref _ref;

  ImageNotifier(this._imagePickerService, this._ref)
    : super(const ImageState());

  /// Take a photo with the device camera
  Future<void> takePhoto() async {
    state = state.copyWith(isProcessing: true);

    try {
      final image = await _imagePickerService.takePhoto();

      if (image != null) {
        // Save image if settings require it
        final settings = _ref.read(settingsProvider);
        if (settings.saveImages) {
          _logger.info('Save Image function would be called here');
          // _saveImagePermanently(image);
        }

        state = state.copyWith(
          image: image,
          source: ImageSource.camera,
          isProcessing: false,
        );
      } else {
        // User cancelled
        state = state.copyWith(isProcessing: false);
      }
    } catch (e) {
      _logger.error('Error taking photo: $e');
      state = state.copyWith(
        errorMessage: 'Failed to capture photo: ${e.toString()}',
        isProcessing: false,
      );
    }
  }

  /// Pick image from gallery
  Future<void> pickFromGallery() async {
    state = state.copyWith(isProcessing: true);

    try {
      final image = await _imagePickerService.pickFromGallery();

      if (image != null) {
        state = state.copyWith(
          image: image,
          source: ImageSource.gallery,
          isProcessing: false,
        );
      } else {
        // User cancelled
        state = state.copyWith(isProcessing: false);
      }
    } catch (e) {
      _logger.error('Error picking from gallery: $e');
      state = state.copyWith(
        errorMessage: 'Failed to select image: ${e.toString()}',
        isProcessing: false,
      );
    }
  }

  /// Reset image state
  void reset() {
    state = state.reset();
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Save image permanently to device storage
//   Future<void> _saveImagePermanently(File image) async {
//     try {
//       _logger.debug('Saving image to device...');
//       // final imagesDirPath = _ref.read(imageSavePathProvider);

//       // final bool storagePermission = await settings._requestStoragePermission();
      
//       // if (!storagePermission) return;

//       // Generate filename with timestamp
//       final String originalFileName = path.basename(image.path);
//       final String fileExtension = path.extension(originalFileName);
//       final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
//       final String newFileName = 'image_$timestamp$fileExtension';

//       final FlutterMediaStore mediaStore = FlutterMediaStore();

//       final List<int> imageBytes = await image.readAsBytes();
//       final String? mimeType = lookupMimeType(image.path);

//       if (mimeType == null) {
//         _logger.error('Could not determine MIME type for ${image.path}. Image not saved locally.');
//         return;
//       }

//       // Default folder
//       String rootFolderName = 'Pictures';
//       String folderName = 'Garden_Glossary';

//       await mediaStore.saveFile(
//         fileData: imageBytes,
//         mimeType: mimeType,
//         rootFolderName: rootFolderName,
//         folderName: folderName, 
//         fileName: newFileName, 
//         onSuccess: (String path, String name) {
//           _logger.info('Image saved to Gallery as: $name');
//           _logger.debug('Image saved to path: $path');
//         }, 
//         onError: (dynamic e) {
//           _logger.error('Error saving image to Gallery: $e');
//         }
//       );
     
//       return;
//     } catch (e) {
//       _logger.error('Error saving image: $e');
//     }
//   }
}

/// Provider for the image state
final imageProvider = StateNotifierProvider<ImageNotifier, ImageState>((ref) {
  final service = ref.watch(imagePickerServiceProvider);
  return ImageNotifier(service, ref);
});

