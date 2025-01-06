import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:garden_glossary/config/environment.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert';

void main() async {
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
enum Organ {flower, leaf, fruit, bark, auto,}
Organ selectedOrgan = Organ.flower;

class HomePageState extends State<HomePage> {
  // Access apiUrl from config
  String apiUrl = Config.apiUrl;
  
  // State variables to control animations
  bool _isSubmitted = false;
  bool _imageMoved = false;
  bool _idLoading = true;
  bool _detailLoading = true;

  // Widget key/height mapping
  Map<GlobalKey, double?> resultBoxHeights = {};
  GlobalKey idResultBox = GlobalKey();
  GlobalKey detailResultBox = GlobalKey();

  // Image to upload to backend
  File? _image;
  final picker = ImagePicker();
  
  // Text to display
  TextSpan _detailResult = const TextSpan(text: "Finding details...",
                                          style: TextStyle(color: Colors.black)
                                          );

  // Matches to display
  List<IDMatch> matchOptions = [];

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
  
  // Function to upload the image to the backend
  Future<void> _uploadImage() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    setState(() {
      _isSubmitted = true;
    });
    
    try {
      String url = '$apiUrl/identify-image/';
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

        List <IDMatch> matchOptionsList = [];
        jsonResponse['matches'].forEach((key, value) {
          String commonNamesString = (value['commonNames'] as List<dynamic>).join(', ');
          matchOptionsList.add(
            IDMatch(
              genus: value['genus'],
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

        // Once rendered, measure height of idResultBox to position detailResultBox
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _measureHeight(idResultBox);
        });

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
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
    }
  }

  // Function to measure ResultBox height
  void _measureHeight(GlobalKey key) {
    final RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final h = renderBox.size.height;
      setState(() {
        resultBoxHeights[key] = h;
      });
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
      _detailResult = const TextSpan(
        text: "Finding details...",
        style: TextStyle(color: Colors.black));
    });
  }


  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/background.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.dstATop,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            alignment: Alignment.center,
            children: [             
               _image != null
                ? AnimatedPositioned(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    top: _isSubmitted ? 52 : screenHeight / 2 - 300,
                    left: screenWidth / 2 - (_isSubmitted ? 100 : 150),
                    child:
                        AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                            height: _isSubmitted ? 200 : 300,
                            width: _isSubmitted ? 200 : 300,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white,
                                width: 4.0,
                              ),
                            ),
                            onEnd: () {
                              setState(() {
                                _imageMoved = true;
                              });
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                _image!,
                                height: 300,
                                width: 300,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                  )
                           
                : Positioned(
                    bottom: screenHeight / 2 + 5,
                    left: 0,
                    right: 0,
                    child: const FractionallySizedBox(
                        alignment: Alignment.center,
                        widthFactor: 0.9,
                        child: Text(
                          'Garden Glossary',
                          style: TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          softWrap: true,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                  ), 


              // Display buttons before submission
              if (!_isSubmitted)
                Positioned(
                  top: screenHeight / 2 + 5, 
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [                 
                      const SizedBox(height: 20),
          
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Button to take a photo
                          ElevatedButton(
                            onPressed: _takePhoto,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                            child: const Text('Camera'),
                          ),
                          
                          const SizedBox(width: 20),
          
                          // Button to upload photo
                          ElevatedButton(
                            onPressed: _galleryPicker,
                            child: const Text('Gallery'),
                          ),
                        ],
                      ),
          
                      const SizedBox(height: 20),
          
                      // Selector for organ
                      Row(
                        children: [
                          const Text(
                            "Organ:",
                            style: TextStyle(
                              fontSize: 20,
                            )),
                          SizedBox(
                            width: 120,
                            child: CupertinoPicker(
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
                      ),

                      const SizedBox(height: 100),
          
                      // Button to upload photo
                      ElevatedButton(
                        onPressed: _uploadImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          minimumSize: const Size(200, 40),
                        ),
                        child: const Text('Submit'),
                      ),
                    ],
                  ),
               ),
                

              // Display identification results
              if (_isSubmitted && _imageMoved)
                Positioned(
                  top: 270,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: IDBox(
                      key: idResultBox,
                      loading: _idLoading,
                      loadingText: const TextSpan(text: 'Identifying with PlantNet...',
                                                  style: TextStyle(color: Colors.black)
                                                  ),
                      matches: matchOptions,
                      onMatchSelected: (index) {
                        debugPrint('Selected match: $index');
                      },
                      ),
                  ),
                ),

              // Display detail results
              // if (_isSubmitted && !_idLoading)
              //   Positioned(
              //     top: 270 + (resultBoxHeights[idResultBox] ?? 0) + 10,
              //     left: 0,
              //     right: 0,
              //     child: Padding(
              //       padding: const EdgeInsets.symmetric(horizontal: 20.0),
              //       child: DetailBox(
              //         key: detailResultBox,
              //         loading: _detailLoading,
              //         resultText: _detailResult, 
              //       ),
              //     ),
              //   ),

              
              // Positioned reset button
              Positioned(
                bottom: 16.0,
                left: 16.0,
                child: FloatingActionButton(
                  onPressed: _reset,
                  backgroundColor: theme.colorScheme.onPrimary,
                  foregroundColor: theme.colorScheme.primary, 
                  mini: true, // Makes the button smaller
                  child: const Icon(Icons.refresh), 
                ),
              ),

              // Positioned settings button
              Positioned(
                bottom: 16.0,
                right: 16.0,
                child: FloatingActionButton(
                  onPressed: null,
                  backgroundColor: theme.colorScheme.onPrimary,
                  foregroundColor: theme.colorScheme.primary, 
                  mini: true, // Makes the button smaller
                  child: const Icon(Icons.settings), 
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class IDMatch extends StatelessWidget {
  final String genus;
  final double score;
  final String commonNames;

  const IDMatch({
    super.key,
    required this.genus,
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
            text: 'Genus: ',
            style: TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: genus),
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
      _controller.forward();
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
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: Colors.lightGreen[50],
          border: Border.all(color: Colors.black, width: 1.0),
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
  final TextSpan resultText;

  const DetailBox({
    super.key,
    required this.loading,
    required this.resultText,
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
      _controller.forward();
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
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.lightGreen[50],
        border: Border.all(color: Colors.black, width: 1.0),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: FadeTransition(
        opacity: _animation,
        child: RichText(
          text: widget.resultText,
        ),
      ),
    );
  }
}

