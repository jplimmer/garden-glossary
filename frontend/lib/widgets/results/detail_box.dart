import 'package:flutter/material.dart';
import 'package:garden_glossary/models/plant_details.dart';
import 'package:garden_glossary/utils/text_utils.dart';
import 'package:garden_glossary/widgets/visual_effects/streaming_text_widget.dart';

class DetailBox extends StatefulWidget {
  final bool loading;
  final TextSpan loadingText;
  final Widget detailDisplay;
  final String? source;
  final bool streaming;
  final VoidCallback? onStreamingComplete;

  const DetailBox({
    super.key,
    required this.loading,
    required this.loadingText,
    required this.detailDisplay,
    this.source,
    this.streaming = false,
    this.onStreamingComplete,
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
    } else if (_controller.isAnimating) {
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
        children: [
          if (widget.loading)
            FadeTransition(
              opacity: _animation,
              child: RichText(
                text: widget.loadingText,
              ),
            )
          else if (widget.streaming)
            StreamingTextWidget(
              fullText: widget.detailDisplay is PlantDetailsWidget
                ? (widget.detailDisplay as PlantDetailsWidget).getFullTextSpan()
                : const TextSpan(text: ''),
              streaming: widget.streaming,
              onStreamingComplete: widget.onStreamingComplete,
            )
          else ...[
            widget.detailDisplay,
            if (widget.source != null)
              Center(
                child: Text.rich(
                  TextSpan(
                    text: 'Source: ${widget.source}',
                    style: const TextStyle(
                      color: Colors.black,
                      height: 1.0,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class PlantDetailsWidget extends StatelessWidget {
  final PlantDetails details;
  
  const PlantDetailsWidget({
    super.key,
    required this.details,
  });
  
  TextSpan getFullTextSpan() {
    return TextSpan(
      style: const TextStyle(color: Colors.black, height: 1.5),
      children: [
        // Cultivation tips + pruning
        buildTextWithLink(details.cultivationTips),
        const TextSpan(text: '\n'),
        buildTextWithLink(details.pruning),
        const TextSpan(text: '\n'),
        
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
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Text.rich(getFullTextSpan());
  }
}

