import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:http/http.dart' as http; 
// import 'dart:convert';

void main() {
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
  // State variables to control animations
  bool _isSubmitted = false;
  bool _imageMoved = false;
  bool _identificationLoading = true;
  
  // Image to upload to backend
  File? _image;
  final picker = ImagePicker();
  
  // Results from backend
  // String? _genus; 
  // double? _score;
  // String? _commonNames;

  // Text to display
  String _identificationResult = 'Identifying with PlantNet...';
  // String _detailResult = "Finding details...";

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
    debugPrint('_uploadImage function entered');
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    setState(() {
      _isSubmitted = true;
    });
    
    // _genus = "Genus goes here";
    // _score = 0.96;
    // _commonNames = "Common names go here";
    
    // try {
    //   // Replace with FastAPI backend URL (use environment config?)
    //   // var uri = Uri.parse('http://10.0.2.2:8000/process-image/'); // uri for Android emulator
    //   var uri = Uri.parse('http://192.168.86.120:8000/process-image/'); // uri for physical Android device (home)
      
    //   // Create multipart request
    //   var request = http.MultipartRequest('POST', uri);
      
    //   // Add the file to the request
    //   request.files.add(
    //     await http.MultipartFile.fromPath(
    //       'file',  // This must match the parameter name in FastAPI
    //       _image!.path
    //     )
    //   );

    //   // Send the request
    //   var response = await request.send();

    //   // Read and parse the response
    //   var responseBody = await response.stream.bytesToString();

    //   // Check the response
    //   if (!mounted) return;
      
    //   if (response.statusCode == 200) {
    //     var jsonResponse = json.decode(responseBody);

    //     setState(() {
    //       _genus = jsonResponse['genus'];
    //       _score = jsonResponse['score'];
    //     });

    //   } else {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(content: Text('Upload failed with status ${response.statusCode}')),
    //     );
    //   }
    // } catch (e) {
    //   setState(() {
    //     _isSubmitted = false;
    //   });
      
    //   debugPrint('Error uploading image: $e');
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Error uploading image: $e')),
    //   );
    // }
  }

  // Function to reset app to home page (with no image)
  void _reset() {
    setState(() {
      _image = null;
      _isSubmitted = false;
      _imageMoved = false;
      _identificationLoading = true;
      _identificationResult = "Identifying with PlantNet...";
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
                  top: 280,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: ResultsBox(
                      loading: _identificationLoading,
                      resultText: _identificationResult,
                      ),
                  ),
                ),
              
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


class ResultsBox extends StatefulWidget {
  const ResultsBox({
    super.key,
    required this.loading,
    required this.resultText,
  });

  final bool loading;
  final String resultText;

  @override
  State<ResultsBox> createState() => _ResultsBoxState();
}

class _ResultsBoxState extends State<ResultsBox> with SingleTickerProviderStateMixin {
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
  void didUpdateWidget(covariant ResultsBox oldWidget) {
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
        child: Text(
          widget.resultText
          ),
      ),
    );
  }
}

