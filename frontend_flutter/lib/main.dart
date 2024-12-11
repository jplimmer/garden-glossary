import 'dart:io';
import 'package:flutter/material.dart';
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


class HomePageState extends State<HomePage> {
  // State variable to control animation
  bool _isSubmitted = false;
  // Image to upload to backend
  File? _image;
  final picker = ImagePicker();
  // Results from backend
  String? _genus; 
  double? _score;

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

        // Ensure the layout is recalculated immediately after state change
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Force a layout rebuild
          setState(() {});
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

        // Ensure the layout is recalculated immediately after state change
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Force a layout rebuild
          setState(() {});
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
    return;
    
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
  void _reset() async {
    setState(() {
      _image = null;
      _isSubmitted = false;
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
               Positioned(
                 bottom: screenHeight / 2 + 5,
                 left: 0,
                 right: 0,
                 child: _image != null
                  ? AnimatedPositioned(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    top: _isSubmitted ? 50 : screenHeight / 2 - 300,
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
            
                  : const Center(
                      child: FractionallySizedBox(
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
               ), 
          
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
                          
                          const SizedBox(width: 10),
          
                          // Button to upload photo
                          ElevatedButton(
                            onPressed: _galleryPicker,
                            child: const Text('Gallery'),
                          ),
                        ],
                      ),
          
                      const SizedBox(height: 20),
          
                      // Button to upload photo
                      ElevatedButton(
                        onPressed: _uploadImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                        child: const Text('Submit'),
                      ),
                    ],
                  ),
               ),
                
              // Display results if available
              if (_isSubmitted && _genus != null)
                Positioned(
                  top: MediaQuery.of(context).size.height / 2 + 200,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          'Genus: $_genus',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_score != null)
                          Text(
                            'Probability: ${_score!*100}%',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                      ],
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
            ],
          ),
        ),
      ),
    );
  }
}

