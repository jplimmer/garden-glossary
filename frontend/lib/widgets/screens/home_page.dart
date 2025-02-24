import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:garden_glossary/models/id_match.dart';
import 'package:garden_glossary/widgets/plant/id_box.dart';
import 'package:garden_glossary/widgets/plant/detail_box.dart';
import 'package:garden_glossary/services/image_picker_service.dart';
import 'package:garden_glossary/services/plant_identification_service.dart';
import 'package:garden_glossary/services/plant_details_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  
  @override
  HomePageState createState() => HomePageState();
}

// Organ options
enum Organ {leaf, flower, fruit, bark, auto,}

class HomePageState extends State<HomePage>
  with PlantDetailsStateMixin {
  final ImagePickerService _imagePickerService = ImagePickerService();
  final PlantIdentificationService _plantIdService = PlantIdentificationService();
    
  // State variables to control animations
  bool _isSubmitted = false;
  bool _imageMoved = false;
  bool _idLoading = true;
  Organ selectedOrgan = Organ.flower;

  // Image to upload to backend
  File? _image;

  // Matches to display and selected match
  List<IDMatch> matchOptions = [];
  int selectedMatchIndex = 0;
  
  // Function to take photo with device camera using ImagePickerService
  Future<void> _takePhoto() async {
    final image = await _imagePickerService.takePhoto(context);
    if (image != null && mounted) {
      setState(() => _image = image);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo taken successfully.')),
      );
    }
  }

  // Function to select photo from device gallery using ImagePickerService
  Future<void> _pickFromGallery() async {
    final image = await _imagePickerService.pickFromGallery(context);
    if (image != null && mounted) {
      setState(() => _image = image);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo added successfully.')),
      );
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
    });
  }

    @override
    Widget build(BuildContext context) {
    var theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final imageSmallHeight = screenSize.width * 0.4;

    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: screenSize.width * 0.02,
                right: screenSize.width * 0.02,
                top: screenSize.height * 0.02,
              ),
              child: SingleChildScrollView(
                child: Stack(
                  children: [
                    _buildTitleImageInputContainer(theme, screenSize, imageSmallHeight),
                    if (_imageMoved)
                      Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: (imageSmallHeight) + 20,
                          ),
                          child: _buildResults(screenSize),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

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
  
  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/images/background.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.5),
            BlendMode.dstATop
          ),
        ),
      ),
    );
  }
  
  Widget _buildTitleImageInputContainer(ThemeData theme, Size screenSize, imageSmallHeight) {
    return SizedBox(
      height: screenSize.height,
      child: Center(
        child: AnimatedAlign(
          alignment: _isSubmitted
            ? Alignment.topCenter
            : const Alignment(0.0, -0.0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          onEnd: () => setState(() => _imageMoved = _isSubmitted),
          child: Column(      
            mainAxisSize: MainAxisSize.min,
            children: [
              _image != null
                ? _buildImageContainer(imageSmallHeight)
                : _buildTitle(theme, screenSize, imageSmallHeight),
              const SizedBox(height: 20),
              if (!_isSubmitted && !_imageMoved)
                _buildInputSection(theme, screenSize),
            ],
          ),
        ),
      ),
    );
  }
    
  Widget _buildImageContainer(double imageSmallHeight) {
    final imageSize = _isSubmitted ? imageSmallHeight : imageSmallHeight * 1.5;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      width: imageSize,
      height: imageSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 4),
      ),
      // onEnd: () => setState(() => _imageMoved = true),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(_image!, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildTitle(ThemeData theme, Size screenSize, double imageSmallHeight) {
    return SizedBox(
      height: imageSmallHeight * 1.5,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'Garden\nGlossary',
          style: GoogleFonts.cormorant(
            color: theme.colorScheme.primary,
            fontSize: 70,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildInputSection(ThemeData theme, Size screenSize) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: screenSize.height * 0.3) ,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 1),
          _buildImageButtons(),
          const Spacer(flex: 1),
          _buildOrganPicker(),
          const Spacer(flex: 5),
          _buildSubmitButton(theme),
        ],
      ),
    );
  }

  Widget _buildImageButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: _takePhoto,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
          ),
          child: const Text('Camera'),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: _pickFromGallery,
          child: const Text('Gallery'),
        ),
      ],
    );
  }
  
  Widget _buildOrganPicker() {
    final FixedExtentScrollController scrollController = FixedExtentScrollController(initialItem: 1);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Organ:',
          style: TextStyle(fontSize: 18),
        ),
        SizedBox(
          width: 110,
          height: 80,
          child: CupertinoPicker(
            scrollController: scrollController,
            itemExtent: 28.0,
            onSelectedItemChanged: (int index) {
              setState(() {
                selectedOrgan = Organ.values[index];
              });
            },
            children: Organ.values.map((organ) {
              return Center(child: Text(organ.toString().split('.').last));
            }).toList(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSubmitButton(ThemeData theme) {
    return ElevatedButton(
      onPressed: _submitImage,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        minimumSize: const Size(200, 40),
      ),
      child: const Text('Submit'),
    );
  }

  Widget _buildResults(Size screenSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_imageMoved)
            IDBox(
              loading: _idLoading,
              loadingText: const TextSpan(
                text: 'Identifying with PlantNet...',
                style: TextStyle(color: Colors.black),
              ),
              matches: matchOptions,
              onMatchSelected: onMatchSelected
            ),
          if (!_idLoading) ...[
            const SizedBox(height: 10),
            DetailBox(
              loading: isLoading,
              loadingText: TextSpan(
                text: loadingText,
                style: const TextStyle(color: Colors.black),
              ),
              detailDisplay: plantDetails != null
                ? PlantDetailsWidget(details: plantDetails!)
                : const SizedBox.shrink(),
            ),
          ],
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
          FloatingActionButton(
            onPressed: null,
            backgroundColor: theme.colorScheme.onPrimary,
            foregroundColor: theme.colorScheme.primary,
            mini: true,
            child: const Icon(Icons.settings),
          ),
        ],
      ),
    );
  }
}

