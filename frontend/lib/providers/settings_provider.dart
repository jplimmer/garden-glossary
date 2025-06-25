import 'dart:io';
// import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:garden_glossary/utils/logger.dart';

final _logger = AppLogger.getLogger('SettingsProvider');

/// Represents the application settings state
class SettingsState {
  final bool saveImages;
  final bool textStreamingEffect;
  final bool saveLogsOption;
  final String imageSaveAlbum;

  const SettingsState({
    required this.saveImages,
    required this.textStreamingEffect,
    required this.saveLogsOption,
    required this.imageSaveAlbum,
  });

  /// Creates a copy of the current state with specified fields replaced
  SettingsState copyWith({
    bool? saveImages,
    bool? textStreamingEffect,
    bool? saveLogsOption,
    String? imageSaveAlbum,
  }) {
    return SettingsState(
      saveImages: saveImages ?? this.saveImages,
      textStreamingEffect: textStreamingEffect ?? this.textStreamingEffect,
      saveLogsOption: saveLogsOption ?? this.saveLogsOption,
      imageSaveAlbum: imageSaveAlbum ?? this.imageSaveAlbum,
    );
  }

  /// Converts settings to a JSON map for debug purposes
  Map<String, dynamic> toJson() {
    return {
      'saveImages': saveImages,
      'textStreamingEffect': textStreamingEffect,
      'saveLogsOption': saveLogsOption,
      'imageSaveAlbum': imageSaveAlbum,
    };
  }  
}

/// Keys used for storing settings in SharedPreferences
class SettingsKeys {
  static const String saveImages = 'saveImages';
  static const String textStreamingEffect = 'textStreamingEffect';
  static const String saveLogsOption = 'saveLogsOption';
  static const String imageSaveAlbum = 'imageSaveAlbum';
}

/// Notifier that manages the settings state
class SettingsNotifier extends StateNotifier<SettingsState> {
  late final SharedPreferences _prefs;
  bool _isInitialised = false;

  /// Creates a SettingsNotifier with default values
  SettingsNotifier() : super(const SettingsState(
    saveImages: false,
    textStreamingEffect: true,
    saveLogsOption: false,
    imageSaveAlbum: '',
  ));
  
  /// Initialises the settings from SharedPreferences
  Future<void> initialise() async {
    if (_isInitialised) return;

    _prefs = await SharedPreferences.getInstance();
    await loadSettings();
    _isInitialised = true;
  }

  /// Loads all settings from SharedPreferences
  Future<void> loadSettings() async {
    // // Get default path for images
    // String defaultPath = '';
    // try {
    //   final directory = await getApplicationDocumentsDirectory();
    //   defaultPath = path.join(directory.path, 'images');

    //   // Create directory if it doesn't exist
    //   ensureDirectoryExists(defaultPath);
    // } catch (e) {
    //   _logger.warning('Failed to get default image path');
    //   throw Exception('Failed to save image.');
    // }
    
    String defaultAlbum = 'Garden-Glossary';

    state = SettingsState(
      saveImages: _prefs.getBool(SettingsKeys.saveImages) ?? false,
      textStreamingEffect: _prefs.getBool(SettingsKeys.textStreamingEffect) ?? true,
      saveLogsOption: _prefs.getBool(SettingsKeys.saveLogsOption) ?? false,
      imageSaveAlbum: _prefs.getString(SettingsKeys.imageSaveAlbum) ?? defaultAlbum,
    );
  }

  /// Request storage permission
  // Future<bool> _requestStoragePermission() async {
  //   final PermissionStatus status = await Permission.storage.request();
  //   return status.isGranted;
  // }

  /// Updates the save images setting
  Future<void> setSaveImages(bool value) async {
    state = state.copyWith(saveImages: value);
    await _prefs.setBool(SettingsKeys.saveImages, value);
  }

  /// Updates the text streaming effect setting
  Future<void> setTextStreamingEffect(bool value) async {
    state = state.copyWith(textStreamingEffect: value);
    await _prefs.setBool(SettingsKeys.textStreamingEffect, value);
  }

  /// Updates the save logs option setting
  Future<void> setSaveLogsOption(bool value) async {
    state = state.copyWith(saveLogsOption: value);
    await _prefs.setBool(SettingsKeys.saveLogsOption, value);
  }

  /// Updates the image save path setting
  Future<void> setImageSaveAlbum(String albumName) async {
    // Validate the path is usable
    try {
      ensureDirectoryExists(albumName);

      state = state.copyWith(imageSaveAlbum: albumName);
      await _prefs.setString(SettingsKeys.imageSaveAlbum, albumName);
    } catch (e) {
      _logger.warning('Failed to set image save path: $e');
    }

    String rootFolderName = 'Pictures';
    String folderName = '';

    if (albumName.contains(rootFolderName)) {
        final List<String> parts = albumName.split(path.separator);
        final int picturesIndex = parts.indexOf(rootFolderName);
        if (picturesIndex != -1 && picturesIndex < parts.length - 1) {
          folderName = parts.sublist(picturesIndex + 1).join(path.separator);
        }
      } else {
        // If the user's path doesn't contain 'Pictures', save directly there
        folderName = albumName;
        rootFolderName = 'Pictures';
      }

      // Ensure folderName is a relative path
      if (path.isAbsolute(folderName)) {
        final List<String> parts = folderName.split(path.separator);
        folderName = parts.last;
      }

  }

  /// Resets all settings to default values
  Future<void> resetToDefaults() async {
    final directory = await getApplicationDocumentsDirectory();
    final defaultPath = path.join(directory.path, 'images');

    state = SettingsState(
      saveImages: false,
      textStreamingEffect: true,
      saveLogsOption: false,
      imageSaveAlbum: defaultPath,
    );

    await _prefs.setBool(SettingsKeys.saveImages, false);
    await _prefs.setBool(SettingsKeys.textStreamingEffect, true);
    await _prefs.setBool(SettingsKeys.saveLogsOption, false);
    await _prefs.setString(SettingsKeys.imageSaveAlbum, defaultPath);    
  }
}

/// Provider that exposes the settings state
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final notifier = SettingsNotifier();
  notifier.initialise();
  return notifier;
});

/// Provider that exposes only the imageSaveAlbum
final imageSaveAlbumProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).imageSaveAlbum;
});

/// Helper function to ensure a directory exists
Future<void> ensureDirectoryExists(String directoryPath) async {
  final directory = Directory(directoryPath);
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
}

