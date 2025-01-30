import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:garden_glossary/config/environment.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

void main() async {
  // Load environment variables for backend URL
  await dotenv.load();
  Config.setEnvironment(Environment.physical);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Garden Glossary',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
    );
  }
}


class HomePage extends StatefulWidget {
  const HomePage({super.key});
  
  @override
  HomePageState createState() => HomePageState();
}

// Organ options
enum Organ {leaf, flower, fruit, bark, auto,}

class HomePageState extends State<HomePage> {
  // Access apiUrl from config
  String apiUrl = Config.apiUrl;

  // Cancel token for cancelling requests
  CancelToken? _cancelToken;
  
  // State variables to control animations
  bool _isSubmitted = false;
  bool _imageMoved = false;
  bool _idLoading = true;
  bool _detailLoading = true;
  Organ selectedOrgan = Organ.flower;

  // Image to upload to backend
  File? _image;
  final picker = ImagePicker();

  // Matches to display and selected match
  List<IDMatch> matchOptions = [];
  int selectedMatchIndex = 0;

  // Detail result to display
  PlantDetails? plantDetails;
  
  // Function to take a photo using the device camera
  Future<void> _takePhoto() async {
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.camera);

      // Check if the widget is still mounted before updating state
      if (!mounted) return;

      // If a photo is picked, update the state with the new image
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });

        // Show SnackBar using ScaffoldMessenger of the current context
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo taken successfully')),
        );
      }
    } catch (e) {
      // Check if the widget is still mounted before showing SnackBar
      if (!mounted) return;
      
      // Handle any errors that might occur during photo capture
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to take photo: $e')),
      );
    }
  }

  // Function to select image from gallery
  Future<void> _galleryPicker() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

      // Check if the widget is still mounted before updating state
      if (!mounted) return;

      // If a photo is picked, update the state with the new image
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });

        // Show SnackBar using ScaffoldMessenger of the current context
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo added successfully')),
        );
      }

    } catch (e) {
      // Check if the widget is still mounted before showing SnackBar
      if (!mounted) return;
      
      // Handle any errors that might occur during photo capture
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add photo: $e')),
      );
    }
  }
  
  // Function to upload the image to the backend and display results (matches)
  Future<void> _uploadImage() async {
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
      String url = '$apiUrl/api/v1/identify-plant/';
      var uri = Uri.parse(url);
      
      // Create multipart request
      var request = http.MultipartRequest('POST', uri);
      
      // Add the image file to the request
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          _image!.path
        )
      );

      // Add the selected organ to the request
      request.fields['organ'] = selectedOrgan.name;

      // Send the request
      var response = await request.send();
      
      // Read and parse the response
      var responseBody = await response.stream.bytesToString();

      // Check widget still mounted
      if (!mounted) return;
      
      // Check the response - further error-handling required here?
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(responseBody);
        debugPrint('$jsonResponse');

        List <IDMatch> matchOptionsList = [];
        jsonResponse['matches'].forEach((key, value) {
          String commonNamesString = (value['commonNames'] as List<dynamic>).join(', ');
          matchOptionsList.add(
            IDMatch(
              species: value['species'],
              score: value['score'],
              commonNames: commonNamesString,
            )
          );
        });
          
        // Update idResult and loading status
        setState(() {
          _idLoading = false;
          matchOptions = matchOptionsList;
        });

        // Call _getDetails function
        _getDetails();

      } else {
        setState(() {
          _isSubmitted = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed with status ${response.statusCode}')),
        );
      }

    } catch (e) {
      setState(() {
        _isSubmitted = false;
      });
      
      debugPrint('$e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
    }
  }
  
  // Function to update selected match index
  void onMatchSelected(int index) {
    setState(() {
      selectedMatchIndex = index;
    });
    _getDetails();
  }
  
  // Function to retrieve and display details of plant from backend
  Future<void> _getDetails() async {
    setState(() {
      _detailLoading = true;
    });

    try {
      String url = '$apiUrl/api/v1/plant-details-rhs/';
      var uri = Uri.parse(url);
      
      String plant = matchOptions[selectedMatchIndex].species;

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'plant': plant})
      );

      // Check widget still mounted
      if (!mounted) return;
      
      if (response.statusCode == 200) {
        // final jsonResponse = jsonDecode(response.body);
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        debugPrint('JSON: $jsonResponse');
        
        setState(() {
          _detailLoading = false;
          plantDetails = PlantDetails.fromJson(jsonResponse);
        });

      } else {
        debugPrint('${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error received from backend: ${response.statusCode}'))
        );
      }

    } catch (e) {
      debugPrint('$e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error retrieving details: $e'),)
      );
    }
  }
  
  // Function to reset app to home page (with no image)
  void _reset() {
    setState(() {
      _image = null;
      _isSubmitted = false;
      _imageMoved = false;
      _idLoading = true;
      _detailLoading = true;
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
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: screenSize.height - MediaQuery.of(context).padding.top,
                  ),
                  child: Stack(
                    children: [
                      _buildImageorTitleContainer(theme, screenSize, imageSmallHeight),
                      const SizedBox(height: 20),
                      if (_imageMoved)
                        Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: (imageSmallHeight) + 20,
                            ),
                            child: _buildResults(screenSize),
                          ),
                        )
                      else if (!_isSubmitted)
                        Align(
                          alignment: const Alignment(0.0, 0.4),
                          child: _buildInputSection(theme, screenSize),
                        ),
                    ],
                  ),
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
  
  Widget _buildImageorTitleContainer(ThemeData theme, Size screenSize, double imageSmallHeight) {
    return AnimatedAlign(
      alignment: _isSubmitted
        ? Alignment.topCenter
        : const Alignment(0.0, -0.5),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      onEnd: () => setState(() => _imageMoved = _isSubmitted),
      child: _image != null
        ? _buildImageContainer(imageSmallHeight)
        : _buildTitle(theme, screenSize),
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
      onEnd: () => setState(() => _imageMoved = true),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(_image!, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildTitle(ThemeData theme, Size screenSize) {
    return SizedBox(
      width: screenSize.width * 0.7,
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
          onPressed: _galleryPicker,
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
      onPressed: _uploadImage,
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
              loading: _detailLoading,
              loadingText: const TextSpan(
                text: 'Finding details...',
                style: TextStyle(color: Colors.black),
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

} // HomePageState


class IDMatch extends StatelessWidget {
  final String species;
  final double score;
  final String commonNames;

  const IDMatch({
    super.key,
    required this.species,
    required this.score,
    required this.commonNames,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(color: Colors.black, height: 1.5),
        children: <TextSpan>[
          const TextSpan(
            text: 'Species: ',
            style: TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: species),
          TextSpan(
            text: ' (${(score*100).toStringAsFixed(2)}% probability)',
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
          const TextSpan(
            text: '\nCommon Names: ',
            style: TextStyle(fontWeight: FontWeight.bold)
          ),
          TextSpan(text: commonNames),
        ],
      ),
    );
  }
}

class PlantSize {
  final String height;
  final String spread;

  PlantSize({required this.height, required this.spread});

  factory PlantSize.fromJson(Map<String, dynamic> json) {
    return PlantSize(
      height: json['height'] as String,
      spread: json['spread'] as String,
    );
  }
}

class Soil {
  final List<String> types;
  final List<String> moisture;
  final List<String> phLevels;

  Soil({
    required this.types,
    required this.moisture,
    required this.phLevels,
  });

  factory Soil.fromJson(Map<String, dynamic> json) {
    return Soil(
      types: List<String>.from(json['types']),
      moisture: List<String>.from(json['moisture']),
      phLevels: List<String>.from(json['ph_levels']),
    );
  }
}

class Position {
  final String sun;
  final String aspect;
  final String exposure;

  Position({
    required this.sun,
    required this.aspect,
    required this.exposure,
  });

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      sun: json['sun'] as String,
      aspect: json['aspect'] as String,
      exposure: json['exposure'] as String,
    );
  }
}

class PlantDetails {
  final PlantSize size;
  final String hardiness;
  final Soil soil;
  final Position position;
  final String cultivationTips;
  final String pruning;

  PlantDetails({
    required this.size,
    required this.hardiness,
    required this.soil,
    required this.position,
    required this.cultivationTips,
    required this.pruning,
  });

  factory PlantDetails.fromJson(Map<String, dynamic> json) {
    final details = json['details'];
    return PlantDetails(
      size: PlantSize.fromJson(details['size']),
      hardiness: details['hardiness'] as String,
      soil: Soil.fromJson(details['soil']),
      position: Position.fromJson(details['position']),
      cultivationTips: details['cultivation_tips'] as String,
      pruning: details['pruning'] as String,
    );
  }
}

class PlantDetailsWidget extends StatelessWidget {
  final PlantDetails details;
  
  const PlantDetailsWidget({
    super.key,
    required this.details,
  });
  
  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(color: Colors.black, height: 1.5),
        children: [
          // Cultivation tips + pruning
          buildTextWithLink(details.cultivationTips),
          const TextSpan(text: '.\n'),
          TextSpan(text: '${details.pruning}.\n'),
          
          // Size
          const TextSpan(
            text: '\nPlant Size:\n',
            style: TextStyle(fontWeight: FontWeight.bold)
          ),
          TextSpan(text: 'Height: ${details.size.height}\n'),
          TextSpan(text: 'Spread: ${details.size.spread}\n'),
          
          // Growing conditions
          const TextSpan(
            text: '\nGrowing conditions:\n',
            style: TextStyle(fontWeight: FontWeight.bold)
          ),
          TextSpan(
            text: 'Soil type(s): ${details.soil.types.join(", ")}\n'
            'Moisture: ${details.soil.moisture.join(", ")}\n'
            'pH levels: ${details.soil.phLevels.join(", ")}\n'
          ),
          
          // Position
          const TextSpan(
            text: '\nPosition:\n',
            style: TextStyle(fontWeight: FontWeight.bold)
          ),
          TextSpan(
            text: 'Sunlight: ${details.position.sun}\n'
            'Aspect: ${details.position.aspect}\n'
            'Exposure: ${details.position.exposure}\n'
          ),
          
          // Hardiness
          const TextSpan(
            text: '\nHardiness: ',
            style: TextStyle(fontWeight: FontWeight.bold)
          ),
          TextSpan(text: '${details.hardiness}\n'),
        ],
      ),
    );
  }
}

TextSpan buildTextWithLink(String htmlText) {
  // Handle case with no link in text
  if (!htmlText.contains('<a href="')) {
    return TextSpan(text: htmlText);
  }
  
  // Split text into parts
  final beforeLink = htmlText.split('<a href="')[0];
  final remaining = htmlText.split('<a href="')[1];
  final url = remaining.split('">')[0];
  final linkText = remaining.split('">')[1].split('</a>')[0];
  final afterLink = remaining.split('</a>')[1];

  return TextSpan(
    style: const TextStyle(color: Colors.black, height: 1.5),
    children: [
      TextSpan(text: beforeLink),
      TextSpan(
        text: linkText,
        style: const TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
          decorationColor: Colors.blue,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          },
      ),
      TextSpan(text: afterLink),
    ]
  );
}

class IDBox extends StatefulWidget {
  final bool loading;
  final TextSpan loadingText;
  final List<IDMatch> matches;
  final int initialSelectedIndex;
  final Function(int) onMatchSelected;

  const IDBox({
    super.key,
    required this.loading,
    required this.loadingText,
    required this.matches,
    required this.onMatchSelected,
    this.initialSelectedIndex = 0,
  });

  @override
  State<IDBox> createState() => _IDBoxState();
}

class _IDBoxState extends State<IDBox> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late int _selectedIndex;
  late AnimationController _controller;
  late Animation<double> _animation;
  

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialSelectedIndex;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  _selectOption(int index) {
    setState(() {
      _selectedIndex = index;
      _isExpanded = false;
    });
    widget.onMatchSelected(index);
  }

  @override
  void didUpdateWidget(covariant IDBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.loading) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller.stop();
      _controller.value = 1;
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.loading ? null: _toggleExpanded,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          color: Colors.lightGreen[50],
          border: Border.all(color: Colors.black, width: 1.0),
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: widget.loading
                    ? FadeTransition(
                      opacity: _animation,
                      child: RichText(text: widget.loadingText)
                    )
                    : widget.matches[_selectedIndex]
                  ),
                if (!widget.loading)
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
              ],
            ),
            if (!widget.loading && _isExpanded) ...[
              const SizedBox(height: 8),
              const Divider(),
              ... widget.matches.asMap().entries.map((entry) {
                final index = entry.key;
                final match = entry.value;
                if (index == _selectedIndex) return const SizedBox.shrink();

                return InkWell(
                  onTap: () => _selectOption(index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: match,
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class DetailBox extends StatefulWidget {
  final bool loading;
  final TextSpan loadingText;
  final Widget detailDisplay;

  const DetailBox({
    super.key,
    required this.loading,
    required this.loadingText,
    required this.detailDisplay,
  });

  @override
  State<DetailBox> createState() => _DetailBoxState();
}

class _DetailBoxState extends State<DetailBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation; 
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant DetailBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.loading) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller.stop();
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: Colors.lightGreen[50],
        border: Border.all(color: Colors.black, width: 1.0),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [widget.loading
          ? FadeTransition(
            opacity: _animation,
            child: RichText(
              text: widget.loadingText,
            ),
          )
          : widget.detailDisplay,
        ],
      ),
    );
  }
}

