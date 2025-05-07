import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garden_glossary/models/organ.dart';
import 'package:garden_glossary/models/id_match.dart';
import 'package:garden_glossary/models/plant_details.dart';
import 'package:garden_glossary/services/plant_identification_service.dart';
import 'package:garden_glossary/services/plant_details_service.dart';
import 'package:garden_glossary/exceptions/exceptions.dart';
import 'package:garden_glossary/utils/logger.dart';

final _logger = AppLogger.getLogger('PlantServiceProvider');

/// States for the plant identification process
enum IdentificationState { initial, loading, success, error }

/// States for the plant details fetching process
enum DetailsFetchState { initial, loading, success, error }

/// Data class for the states of both plant identification and details services
class PlantServicesState {
  final IdentificationState idState;
  final List<IDMatch> matches;
  final int selectedMatchIndex;
  final ErrorType? idErrorType;
  final String? idErrorMessage;

  final DetailsFetchState detailsState;
  final PlantDetails? details;
  final String? detailsSource;
  final String detailsLoadingText;
  final ErrorType? detailsErrorType;
  final String? detailsErrorMessage;

  const PlantServicesState({
    required this.idState,
    this.matches = const [],
    this.selectedMatchIndex = 0,
    this.idErrorType,
    this.idErrorMessage,
    required this.detailsState,
    this.details,
    this.detailsSource,
    this.detailsLoadingText = 'Fetching plant details...',
    this.detailsErrorType,
    this.detailsErrorMessage,
  });

  PlantServicesState copyWith({
    IdentificationState? idState,
    List<IDMatch>? matches,
    int? selectedMatchIndex,
    ErrorType? idErrorType,
    String? idErrorMessage,
    DetailsFetchState? detailsState,
    PlantDetails? details,
    String? detailsSource,
    ErrorType? detailsErrorType,
    String? detailsErrorMessage,
    String? detailsLoadingText,
  }) {
    return PlantServicesState(
      idState: idState ?? this.idState,
      matches: matches ?? this.matches,
      selectedMatchIndex: selectedMatchIndex ?? this.selectedMatchIndex,
      idErrorType: idErrorType ?? this.idErrorType,
      idErrorMessage: idErrorMessage ?? this.idErrorMessage,
      detailsState: detailsState ?? this.detailsState,
      details: details ?? this.details,
      detailsSource: detailsSource ?? this.detailsSource,
      detailsLoadingText: detailsLoadingText ?? this.detailsLoadingText,
      detailsErrorType: detailsErrorType ?? detailsErrorType,
      detailsErrorMessage: detailsErrorMessage ?? this.detailsErrorMessage,
    );
  }
}

/// Provider for the PlantIdentificationService
final plantIdServiceProvider = Provider<PlantIdentificationService>((ref) {
  return PlantIdentificationService();
});

/// Provider for the PlantDetailsService
final plantDetailsServiceProvider = Provider<PlantDetailsService>((ref) {
  return PlantDetailsService();
});

/// Combined Notifier for plant identification and details services
class PlantServicesNotifier extends StateNotifier<PlantServicesState> {
  final PlantIdentificationService _plantIdService;
  final PlantDetailsService _detailsService;

  PlantServicesNotifier(this._plantIdService, this._detailsService)
    : super(const PlantServicesState(
        idState: IdentificationState.initial,
        detailsState: DetailsFetchState.initial,
      ));

  /// Submit an image for plant identification
  Future<void> identifyPlant({
    required File imageFile,
    required Organ organ,
  }) async {
    // Set loading state
    state = state.copyWith(
      idState: IdentificationState.loading,
    );

    try {
      // Call identification service
      final matches = await _plantIdService.identifyPlant(
        imageFile: imageFile,
        organ: organ.name,
      );

      // Update state with results
      state = state.copyWith(
        idState: IdentificationState.success,
        matches: matches,
        selectedMatchIndex: 0,
      );

      // Automatically fetch details for the first match upon successful ID
      if (matches.isNotEmpty) {
        fetchDetails(matches.first.species);
      }
    } catch (e) {
      _logger.error('Plant identification error: $e');
      final (errorType, errorMessage) = _getErrorTypeAndMessage(e);
      
      // Update state with error
      state = state.copyWith(
        idState: IdentificationState.error,
        idErrorType: errorType,
        idErrorMessage: errorMessage,
      );
    }
  }

  /// Select a different match and fetch its details
  void selectMatch(int index) {
    if (index >= 0 && index < state.matches.length) {
      state = state.copyWith(selectedMatchIndex: index);
      // Fetch details for the newly selected match
      fetchDetails(state.matches[index].species);
    }
  }

  /// Fetch details for a specific plant species
  Future<void> fetchDetails(String species) async {
    // Early return if already loading
    if (state.detailsState == DetailsFetchState.loading) return;
  
    // Set initial loading state
    state = state.copyWith(
      detailsState: DetailsFetchState.loading,
      detailsLoadingText: 'Checking RHS for details...',
    );
  
    try {
      // Try RHS first
      _logger.info('Checking RHS for details');
      final detailsRhs = await _detailsService.getDetailsRhs(species);

      if (detailsRhs != null) {
        // Update state with success and source
        state = state.copyWith(
          detailsState: DetailsFetchState.success,
          details: detailsRhs,
          detailsSource: 'RHS',
        );
        return;
      }
      
      // Fallback to LLM
      _logger.info('Details not found on RHS - falling back to LLM...');
      state = state.copyWith(
        detailsLoadingText: 'Details not found on RHS.\nAsking Claude...'
      );
      final detailsLlm = await _detailsService.getDetailsLlm(species);

      if (detailsLlm != null) {
        // Update state with success and source
        state = state.copyWith(
          detailsState: DetailsFetchState.success,
          details: detailsLlm,
          detailsSource: 'Claude',
        );
        return;
      }

      // Both services failed
      _logger.warning('Details not found from Claude');
      // Update state with error
      state = state.copyWith(
        detailsState: DetailsFetchState.error,
        detailsErrorType: ErrorType.details,
        detailsErrorMessage: 'No details found',
      );
                    
    } catch (e) {
      _logger.error('Plant details error: $e');
      final (errorType, errorMessage) = _getErrorTypeAndMessage(e);

      // Update state with error
      state = state.copyWith(
        detailsState: DetailsFetchState.error,
        detailsErrorType: errorType,
        detailsErrorMessage: errorMessage,
      );
    }
  }

  /// Determine error type and message
  (ErrorType?, String?) _getErrorTypeAndMessage(dynamic e) {
    if (e is SocketException) {
      return (ErrorType.network, null);
    } else if (e is PlantIdentificationException) {
      return(ErrorType.identification, e.toString());
    } else if (e is PlantDetailsException) {
      return(ErrorType.details, e.toString());
    } else {
      return(ErrorType.general, 'Failed to identify plant. Please try again.');
    }
  }

  /// Reset the entire state
  void reset() {
    _plantIdService.cancelRequest();
    _detailsService.cancelRequest();
    state = const PlantServicesState(
      idState: IdentificationState.initial,
      detailsState: DetailsFetchState.initial,
    );
  }
}

/// Combined provider for plant identification and details services
final plantServicesProvider = StateNotifierProvider<PlantServicesNotifier, PlantServicesState>((ref) {
  final plantIdService = ref.watch(plantIdServiceProvider);
  final plantDetailsService = ref.watch(plantDetailsServiceProvider);
  return PlantServicesNotifier(plantIdService, plantDetailsService);
});

