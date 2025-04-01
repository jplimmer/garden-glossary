// Flutter imports
import 'dart:io';
import 'package:flutter/material.dart';

// Model imports
import 'package:garden_glossary/models/organ.dart';
import 'package:garden_glossary/models/id_match.dart';

// 'Input' imports
import 'package:garden_glossary/widgets/background_widget.dart';
import 'package:garden_glossary/widgets/input/user_image_container.dart';
import 'package:garden_glossary/widgets/input/input_controls.dart';
import 'package:garden_glossary/services/image_picker_service.dart';
import 'package:garden_glossary/widgets/input/health_check_button.dart';
import 'package:garden_glossary/services/health_check_service.dart';

// 'Result' imports
import 'package:garden_glossary/services/plant_identification_service.dart';
import 'package:garden_glossary/services/plant_details_service.dart';
import 'package:garden_glossary/widgets/results/match_image_container.dart';
import 'package:garden_glossary/widgets/results/results_display.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});
  
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage>
  with PlantDetailsStateMixin {
  final ImagePickerService _imagePickerService = ImagePickerService();
  final PlantIdentificationService _plantIdService = PlantIdentificationService();
  final HealthCheckService _healthCheckService = HealthCheckService();
    
  // State variables to control animations
  Organ selectedOrgan = Organ.flower;
  bool _isSubmitted = false;
  bool _imageMoved = false;
  bool _idLoading = true;
  int displayedImageIndex= 0;

  // Image to upload to backend
  File? _image;

  // Matches to display and selected match
  List<IDMatch> matchOptions = [];
  int selectedMatchIndex = 0;
  
  // Function to update selected organ index
  void _onOrganChanged (Organ organ) {
    setState(() {
      selectedOrgan = organ;
    });
  }

  // Function to handle image container animation end
  void _onImageContainerAnimationEnd() {
    setState(() => _imageMoved = _isSubmitted);
  }
  
  // Function to take photo with device camera using ImagePickerService
  Future<void> _takePhoto() async {
    final image = await _imagePickerService.takePhoto(context);
    if (image != null && mounted) {
      setState(() => _image = image);
    }
  }

  // Function to select photo from device gallery using ImagePickerService
  Future<void> _pickFromGallery() async {
    final image = await _imagePickerService.pickFromGallery(context);
    if (image != null && mounted) {
      setState(() => _image = image);
    }
  }

  // Function to submit selected photo to backend using PlantIdentificationService
  Future<void> _submitImage() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return; 
    }

    setState(() {
      _isSubmitted = true;
      _idLoading = true;
    });

    try {
      final matches = await _plantIdService.identifyPlant(
        imageFile: _image!,
        organ: selectedOrgan.name,
        context: context,
      );

      if (mounted) {
        setState(() {
          matchOptions = matches;
          _idLoading = false;
        });
        _loadPlantDetails();
      }
    } catch (e) {
      if (mounted) {
        _reset(resetImage: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }
  
  // Function to update selected match index
  void onMatchSelected(int index) {
    setState(() {
      selectedMatchIndex = index;
    });
    _loadPlantDetails();
  }
   
  // Function to retrieve details using PlantDetailsService
  Future<void> _loadPlantDetails() async {
    final plant = matchOptions[selectedMatchIndex].species;
    await getDetails(plant);
  }

  // Function to reset app to home page (image reset is optional)
  void _reset({bool resetImage = true}) {
    _plantIdService.cancelRequest();

    setState(() {
      if (resetImage) {
        _image = null;
      }
      _isSubmitted = false;
      _imageMoved = false;
      _idLoading = true;
      matchOptions = [];
      selectedMatchIndex = 0;
      plantDetails = null;
      source = null;
    });
  }

    @override
    Widget build(BuildContext context) {
    var theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final imageSmallHeight = screenSize.width * 0.35;

    return Scaffold(
      body: Stack(
        children: [
          const BackgroundWidget(),
          SafeArea(
            child: Padding(
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
                        image: _image,
                        isSubmitted: _isSubmitted,
                        baseHeight: imageSmallHeight,
                        onAnimationEnd: _onImageContainerAnimationEnd,
                        theme: theme,
                        screenSize: screenSize,
                      ),
                    ),

                    // Input Controls if 'Submit' not yet pressed
                    if (!_isSubmitted)
                      Padding(
                        padding: EdgeInsets.only(
                          top: (screenSize.height / 2) + 10
                        ),
                        child: InputControls(
                          onCameraPressed: _takePhoto,
                          onGalleryPressed: _pickFromGallery,
                          onSubmitPressed: _submitImage,
                          initialOrgan: selectedOrgan,
                          onOrganChanged: _onOrganChanged,
                          theme: theme,
                          screenSize: screenSize,
                        ),
                      ),

                    // 'Results' sections (after 'Submit' pressed)
                    if (_imageMoved) ...[
                      // Results (IDBox & DetailBox)
                      Padding(
                        padding: EdgeInsets.only(
                          top: (imageSmallHeight) + 20,
                        ),
                        child: ResultsDisplay(
                          matchOptions: matchOptions,
                          idLoading: _idLoading,
                          onMatchSelected: onMatchSelected,
                          detailsLoading: isLoading,
                          loadingText: loadingText,
                          plantDetails: plantDetails,
                          source: source,
                          enableStreaming: true,
                        ),
                      ),
                      // PlantNet image container (displayed on top of Results when expanded)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: MatchImageContainer(
                          loading: _idLoading,
                          imageUrls: matchOptions.isNotEmpty ? matchOptions[selectedMatchIndex].imageUrls : [],
                          baseHeight: imageSmallHeight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Reset and HealthCheck buttons
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildActionButtons(theme),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons(ThemeData theme) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FloatingActionButton(
            onPressed: _reset,
            backgroundColor: theme.colorScheme.onPrimary,
            foregroundColor: theme.colorScheme.primary,
            mini: true,
            child: const Icon(Icons.refresh),
          ),
          HealthCheckButton(healthCheckService: _healthCheckService),
        ],
      ),
    );
  }
}

