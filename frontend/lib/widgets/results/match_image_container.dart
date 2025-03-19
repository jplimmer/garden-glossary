import 'package:flutter/material.dart';
import 'package:garden_glossary/widgets/image_container.dart';
import 'package:garden_glossary/widgets/visual_effects/shimmer_effect.dart';

class MatchImageContainer extends StatefulWidget {
  final bool loading;
  final List<String> imageUrls;
  final int initialIndex;
  final Duration duration;
  final double baseHeight;

  const MatchImageContainer({
    super.key,
    required this.loading,
    required this.imageUrls,
    this.initialIndex = 0,
    this.duration = const Duration(milliseconds: 500),
    required this.baseHeight,
  });

  @override
  State<MatchImageContainer> createState() => _MatchImageContainerState();
}

class _MatchImageContainerState extends State<MatchImageContainer> {
  bool _isExpanded = false;
  late int _currentIndex;
  late double _imageSize;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.imageUrls.isEmpty ? 0 : widget.initialIndex;
    _imageSize = _isExpanded ? widget.baseHeight * 2 : widget.baseHeight;
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      _imageSize = _isExpanded ? widget.baseHeight * 2 : widget.baseHeight;
    });
  }

  void _nextImage() {
    if (widget.imageUrls.isEmpty) return;
    
    setState(() {
      if (_currentIndex == widget.imageUrls.length - 1) {
        _currentIndex = 0;
      } else {
        _currentIndex += 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _toggleExpanded,
      onTap: widget.imageUrls.isEmpty ? null : _nextImage,
      child: AnimatedAlign(
        alignment: _isExpanded
          ? Alignment.bottomCenter
          : Alignment.topRight,
        duration: widget.duration,
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: widget.duration,
          curve: Curves.easeInOut,
          height: _imageSize,
          width: _imageSize,
          child: widget.loading
            ? ShimmerEffect(
                child: ImageContainer.file(
                  file: null,
                  size: _imageSize,
                  placeholder: ImagePlaceholder(size: _imageSize),
                ),
              )
            : ImageContainer.network(
                url: widget.imageUrls.isNotEmpty ? widget.imageUrls[_currentIndex] : null,
                size: _imageSize,
                placeholder: ShimmerEffect(
                  child: ImagePlaceholder(size: _imageSize),
                ),
            ),
        ),
      ),
    );
  }
}

