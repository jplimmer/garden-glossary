import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garden_glossary/providers/settings_provider.dart';
import 'package:garden_glossary/providers/ui_state_provider.dart';
import 'package:garden_glossary/exceptions/exceptions.dart';

/// A mixin that provides standardised error-handling methods for Riverpod-based state management
mixin ErrorHandlingMixin {
  /// Shows an error dialog with appropriate title and message
  /// 
  /// [context] - The build context
  /// [ref] - The WidgetRef to access providers
  /// [errorType] - The type of error to display 
  /// [errorMessage] - Optional custom error message (uses default if not provided)
  /// [onSaveLogs] - Optional callback to save error logs

  void showErrorDialog({
    required BuildContext context,
    required WidgetRef ref,
    required ErrorType errorType,
    String? errorMessage,
    VoidCallback? onSaveLogs
  }) {
    final settings = ref.watch(settingsProvider);
    final title = _getErrorTitle(errorType);
    final message = errorMessage ?? _getDefaultErrorMessage(errorType);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            if (settings.saveLogsOption)// && onSaveLogs != null)
              TextButton(
                onPressed: onSaveLogs,
                child: const Text('Save logs'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref.read(uiStateProvider.notifier).reset();
                },
                child: const Text('OK'),
              ),
          ],
        );
      },
    );
  }

  /// Shows an error snackbar for less critical errors
  /// 
  /// [context] - The build context
  /// [errorMessage] - Optional custom error message (uses default if not provided)
  void showErrorSnackBar({
    required BuildContext context,
    required ErrorType errorType,
    String? errorMessage,
  }) {
    final message = errorMessage ?? _getDefaultErrorMessage(errorType);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.black,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {}
        ),
      ),
    );
  }

  /// Returns the appropriate title based on the error type when no specific message is provided
  String _getErrorTitle(ErrorType errorType) {
    switch (errorType) {
      case ErrorType.identification:
        return 'Identification Error';
      case ErrorType.details:
        return 'Plant Details Error';
      case ErrorType.network:
        return 'Network Error';
      case ErrorType.general:
        return 'Error'; 
    }
  }

  /// Returns the appropriate message based on the error type
  String _getDefaultErrorMessage(ErrorType errorType) {
    switch (errorType) {
      case ErrorType.identification:
        return 'Unable to identify this plant. Please try with a clearer image.';
      case ErrorType.details:
        return 'Unable to retrieve plant details at this time. Please try again later.';
      case ErrorType.network:
        return 'Internet connection issue. Please check your network and try again.';
      case ErrorType.general:
        return 'Something went wrong! Please try again.';
    }
  }
}

