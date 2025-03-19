import 'package:flutter/material.dart';
import 'package:garden_glossary/models/id_match.dart';
import 'package:garden_glossary/models/plant_details.dart';
import 'package:garden_glossary/widgets/results/id_box.dart';
import 'package:garden_glossary/widgets/results/detail_box.dart';

class ResultsDisplay extends StatefulWidget {
  final bool idLoading;
  final List<IDMatch> matchOptions;
  final Function(int) onMatchSelected;
  final bool detailsLoading;
  final String loadingText;
  final PlantDetails? plantDetails;
  final bool enableStreaming;
  
  const ResultsDisplay({
    super.key,
    required this.idLoading,
    required this.matchOptions,
    required this.onMatchSelected,
    required this.detailsLoading,
    required this.loadingText,
    this.plantDetails,
    this.enableStreaming = true,
  });

  @override
  State<ResultsDisplay> createState() => _ResultsDisplayState();
}

class _ResultsDisplayState extends State<ResultsDisplay> {
  bool _isStreaming = false;

  @override
  void didUpdateWidget(ResultsDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Start streaming when details are loaded or when details change
    if (!widget.detailsLoading &&
        (oldWidget.detailsLoading || widget.plantDetails != oldWidget.plantDetails) &&
        widget.plantDetails != null &&
        widget.enableStreaming) {
      setState(() {
        _isStreaming = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IDBox(
          loading: widget.idLoading,
          loadingText: const TextSpan(
            text: 'Identifying with PlantNet...',
            style: TextStyle(color: Colors.black),
          ),
          matches: widget.matchOptions,
          onMatchSelected: widget.onMatchSelected
        ),
        if (!widget.idLoading) ...[
          const SizedBox(height: 10),
          DetailBox(
            loading: widget.detailsLoading,
            loadingText: TextSpan(
              text: widget.loadingText,
              style: const TextStyle(color: Colors.black),
            ),
            detailDisplay: widget.plantDetails != null
              ? PlantDetailsWidget(details: widget.plantDetails!)
              : const SizedBox.shrink(),
            streaming: _isStreaming, //&& widget.enableStreaming && !widget.detailsLoading && widget.plantDetails != null,
            onStreamingComplete: () {
              setState(() {
                _isStreaming = false;
              });
            },
          ),
        ],
      ],
    );
  }
} 

