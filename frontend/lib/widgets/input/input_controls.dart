import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:garden_glossary/models/organ.dart';

class InputControls extends StatefulWidget {
  final VoidCallback onCameraPressed;
  final VoidCallback onGalleryPressed;
  final VoidCallback onSubmitPressed;
  final Organ initialOrgan;
  final Function(Organ) onOrganChanged;
  final ThemeData theme;
  final Size screenSize;

  const InputControls({
    super.key,
    required this.onCameraPressed,
    required this.onGalleryPressed,
    required this.onSubmitPressed,
    required this.initialOrgan,
    required this.onOrganChanged,
    required this.theme,
    required this.screenSize,
  });

  @override
  InputControlsState createState() => InputControlsState();
}

class InputControlsState extends State<InputControls> {
  late Organ selectedOrgan;

  @override
  void initState() {
    super.initState();
    selectedOrgan = widget.initialOrgan;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.screenSize.height * 0.3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 1),
          _buildImageButtons(),
          const Spacer(flex: 1),
          _buildOrganPicker(),
          const Spacer(flex: 5),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildImageButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: widget.onCameraPressed,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
          ),
          child: const Text('Camera'),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: widget.onGalleryPressed,
          child: const Text('Gallery'),
        ),
      ],
    );
  }

  Widget _buildOrganPicker() {
    final initialIndex = Organ.values.indexOf(selectedOrgan);
    final FixedExtentScrollController scrollController = FixedExtentScrollController(initialItem: initialIndex);
    
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

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: widget.onSubmitPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.theme.colorScheme.primary,
        foregroundColor: widget.theme.colorScheme.onPrimary,
        minimumSize: const Size(200, 40),
      ),
      child: const Text('Submit'),
    );
  }
}

