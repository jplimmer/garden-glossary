import 'dart:io';
import 'package:flutter/material.dart';
import 'package:garden_glossary/widgets/image_container.dart';
import 'package:garden_glossary/widgets/visual_effects/shimmer_effect.dart';

class UserImageContainer extends StatelessWidget {
  final File? image;
  final Duration duration;
  final double baseHeight;
  final VoidCallback? onAnimationEnd;
  final bool isSubmitted;
  final String appTitle;
  final bool isLoading;
  final ThemeData? theme;
  final Size? screenSize;

  const UserImageContainer({
    super.key,
    required this.image,
    this.duration = const Duration(milliseconds: 500),
    required this.baseHeight,
    this.onAnimationEnd,
    required this.isSubmitted,
    this.appTitle = "Garden\nGlossary",
    this.isLoading = false,
    this.theme,
    this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = this.theme ?? Theme.of(context);

    return SizedBox(
      height: screenSize?.height != null ? screenSize!.height / 2 : 300,
      child: AnimatedAlign(
        alignment: isSubmitted 
          ? Alignment.topLeft
          : Alignment.bottomCenter,
        duration: duration,
        curve: Curves.easeInOut,
        onEnd: onAnimationEnd,
        child: image != null
          ? _buildImageView()
          : _buildTitleView(theme)
      ),
    );
  }

  Widget _buildImageView() {
    final imageSize = isSubmitted ? baseHeight : baseHeight * 1.5;

    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeInOut,
      width: imageSize,
      height: imageSize,
      child: isLoading
        ? ShimmerEffect(
            child: ImageContainer.file(
              file: null,
              size: imageSize,
              placeholder: ImagePlaceholder(size: imageSize),
            ),
          )
        : ImageContainer.file(
            file: image,
            size: imageSize,
          ),
    );
  }

  Widget _buildTitleView(ThemeData theme) {
    return SizedBox(
      height: baseHeight * 1.5,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          appTitle,
          style: TextStyle(
            fontFamily: 'Cormorant',
            color: theme.colorScheme.primary,
            fontSize: 70,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

