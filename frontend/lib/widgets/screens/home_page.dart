// Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Config imports
import 'package:garden_glossary/exceptions/error_handling_mixin.dart';
import 'package:garden_glossary/exceptions/exceptions.dart';

// Model imports
import 'package:garden_glossary/models/organ.dart';

// Provider imports
import 'package:garden_glossary/providers/settings_provider.dart';
import 'package:garden_glossary/providers/ui_state_provider.dart';
import 'package:garden_glossary/providers/organ_provider.dart';
import 'package:garden_glossary/providers/image_provider.dart';
import 'package:garden_glossary/providers/plant_services_provider.dart';

// Widget imports
import 'package:garden_glossary/widgets/background_widget.dart';
import 'package:garden_glossary/widgets/settings/hamburger_menu_button.dart';
import 'package:garden_glossary/widgets/input/health_check_button.dart';
import 'package:garden_glossary/widgets/input/input_controls.dart';
import 'package:garden_glossary/widgets/input/user_image_container.dart';
import 'package:garden_glossary/widgets/results/match_image_container.dart';
import 'package:garden_glossary/widgets/results/id_box.dart';
import 'package:garden_glossary/widgets/results/detail_box.dart';

/// Main home page of the Garden Glossary app
/// 
/// This widget serves as the primary user interface. Users can take or select photos and 
/// submit them for plant identification and retrieval of cultivation details.

// class HomePage extends ConsumerStatefulWidget {
class HomePage extends ConsumerWidget with ErrorHandlingMixin {
  HomePage({super.key});

  /// Handles when the user submits an image for identification
  void _handleSubmit(WidgetRef ref) {
    final imageState = ref.read(imageProvider);

    if (imageState.image == null) {
      showErrorSnackBar(
        context: ref.context,
        errorType: ErrorType.general,
        errorMessage: 'Please select an image first');
      return;
    }

    // Get the selected organ
    final organ = ref.read(organProvider);

    // Trigger the identification process
    ref.read(uiStateProvider.notifier).setIsSubmitted(true);
    ref.read(plantServicesProvider.notifier).identifyPlant(
      imageFile: imageState.image!,
      organ: organ,
    );
  }

  void _handleReset(WidgetRef ref) {
    // Reset all providers
    ref.read(imageProvider.notifier).reset();
    ref.read(plantServicesProvider.notifier).reset();
    ref.read(uiStateProvider.notifier).reset();
  }
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch providers to rebuild when they change
    final imageState = ref.watch(imageProvider);
    final plantServicesState = ref.watch(plantServicesProvider);
    final uiState = ref.watch(uiStateProvider);
    final selectedOrgan = ref.watch(organProvider);
    final settings = ref.watch(settingsProvider);
    
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final imageSmallHeight = screenSize.width * 0.35;

    // Listen for ImagePickerService errors
    ref.listen<ImageState>(
      imageProvider,
      (previous, current) {
        // Only show error dialogs for new errors
        if (previous?.errorMessage == null &&
            current.errorMessage != null) {
          showErrorSnackBar(
            context: context,
            errorType: ErrorType.general,
            errorMessage: imageState.errorMessage);
        }
      }
    );
    
    // Listen for PlantServices errors
    ref.listen<PlantServicesState>(
      plantServicesProvider,
      (previous, current) {
        // Only show error dialogs for new errors
        if (previous?.idState != IdentificationState.error &&
            current.idState == IdentificationState.error &&
            current.idErrorMessage != null) {
          showErrorDialog(
            context: context,
            ref: ref,
            errorType: ErrorType.identification,
            errorMessage: current.idErrorMessage,
          );
        } else if (previous?.detailsState != DetailsFetchState.error &&
                   current.detailsState == DetailsFetchState.error &&
                   current.detailsErrorMessage != null) {
          showErrorDialog(
            context: context,
            ref: ref,
            errorType: ErrorType.details,
            errorMessage: current.detailsErrorMessage, 
          );
        }
      }
    );
    
    return Scaffold(
      body: Stack(
        children: [
          const BackgroundWidget(),
          SafeArea(
            // Input and results sections
            child: _buildMainContent(
              ref,
              theme,
              screenSize,
              imageSmallHeight,
              settings,
              imageState,
              plantServicesState,
              uiState,
              selectedOrgan,
            ),
          ),
          // Hamburger menu button
          const Positioned(
            right: 10,
            top: 5,
            child: SafeArea(
              child: HamburgerMenuButton()
            ),
          ),
          // Reset and HealthCheck buttons
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: _buildActionButtons(ref, theme)
            ),
          ),
        ],
      ),
    );
  }
  
  /// Builds the main scrollable content of the page
  Widget _buildMainContent(
    WidgetRef ref, 
    ThemeData theme,
    Size screenSize,
    double imageSmallHeight,
    dynamic settings,
    ImageState imageState,
    PlantServicesState plantServicesState,
    UIState uiState,
    Organ selectedOrgan,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        left: screenSize.width * 0.05,
        right: screenSize.width * 0.05,
        top: screenSize.height * 0.02,
      ),
      child: SingleChildScrollView(
        child: Stack(
          children: [
            // Title or user-selected image container
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: UserImageContainer(
                image: imageState.image,
                isSubmitted: uiState.isSubmitted,
                baseHeight: imageSmallHeight,
                onAnimationEnd: () {
                  if (uiState.isSubmitted) {
                    ref.read(uiStateProvider.notifier).setImageMoved(true);
                  }
                },
                theme: theme,
                screenSize: screenSize,
              ),
            ),

            // Input Controls if 'Submit' not yet pressed
            if (!uiState.isSubmitted)
              _buildInputControls(ref ,screenSize, theme, imageSmallHeight, selectedOrgan),

            // 'Results' sections (after 'Submit' pressed)
            if (uiState.isImageMoved)
              _buildResultsSection(ref, imageSmallHeight, settings, plantServicesState),
          ],
        ),
      ),
    );
  }
  
  /// Builds the input controls for selecting and submitting images
  Widget _buildInputControls(
    WidgetRef ref,
    Size screenSize,
    ThemeData theme,
    double imageHeight,
    Organ selectedOrgan,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        top: (screenSize.height / 2) + 10
      ),
      child: InputControls(
        onCameraPressed: () {
          ref.read(imageProvider.notifier).takePhoto();
        },
        onGalleryPressed: () {
          ref.read(imageProvider.notifier).pickFromGallery();
        },
        onSubmitPressed: () {
          _handleSubmit(ref);
        },
        initialOrgan: selectedOrgan,
        onOrganChanged: (organ) {
          ref.read(organProvider.notifier).state = organ;
        },
        theme: theme,
        screenSize: screenSize,
      ),
    );
  }
  
  /// Builds the results section showing identification matches and cultivation details
  Widget _buildResultsSection(
    WidgetRef ref,
    double imageSmallHeight,
    dynamic settings,
    PlantServicesState plantServicesState,
  ) {
    bool idLoaded = plantServicesState.idState == IdentificationState.success;
    final selectedIndex = plantServicesState.selectedMatchIndex;

    return Stack(
      children: [
        // Results (IDBox & DetailBox)
        Padding(
          padding: EdgeInsets.only(
            top: (imageSmallHeight) + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const IDBox(),
              if (idLoaded) ...[
                const SizedBox(height: 10),
                const DetailBox()
              ]
            ],
          ),
        ),
        // PlantNet image container (displayed on top of Results when expanded)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: MatchImageContainer(
            loading: plantServicesState.idState == IdentificationState.loading,
            imageUrls: plantServicesState.matches.isNotEmpty && selectedIndex < plantServicesState.matches.length
              ? plantServicesState.matches[selectedIndex].imageUrls
              : [],
            baseHeight: imageSmallHeight,
          ),
        ),
      ],
    );
  }
  
  /// Builds the action buttons at the bottom of the screen
  Widget _buildActionButtons(WidgetRef ref, ThemeData theme) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FloatingActionButton(
            onPressed: () => _handleReset(ref),
            backgroundColor: theme.colorScheme.onPrimary,
            foregroundColor: theme.colorScheme.primary,
            mini: true,
            child: const Icon(Icons.refresh),
          ),
          const HealthCheckButton(),
        ],
      ),
    );
  }
}

